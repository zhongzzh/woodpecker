"""
edgetaper - 沿图像边缘的锥形不连续性

J = edgetaper(I,PSF)
"""
const _EDGETAPER_ALLOWED_TYPES = (UInt8, UInt16, Int16, Float64, Float32)

function edgetaper(I::AbstractArray{<:Real}, PSF::AbstractArray{<:Real})
    I, PSF, sizeI, classI, sizePSF, numNSdim = edgetaper_parse_inputs(I, PSF)

    beta = Vector{Vector{Float64}}(undef, length(numNSdim))
    for (k, dim) in pairs(numNSdim)
        PSFproj = edgetaper_psf_projection(PSF, dim)
        beta[k] = edgetaper_autocorrelation_beta(PSFproj, sizeI[dim])
    end

    spectrum = FFTW.fft(edgetaper_float64_input(I))
    spectrum .*= edgetaper_psf2otf(PSF, sizeI, sizePSF)
    blurredI = FFTW.ifft!(spectrum)

    J = Array{Float64}(undef, size(I))
    minI, maxI = extrema(Float64, I)
    edgetaper_blend!(J, I, blurredI, beta, numNSdim, minI, maxI)

    if classI <: Integer || classI == Float32
        J = images_internal_changeClass(classI, J)
    end

    return J
end

edgetaper_float64_input(I::AbstractArray{Float64}) = I
edgetaper_float64_input(I::AbstractArray) = Float64.(I)

function edgetaper_psf_projection(PSF::AbstractArray, dim::Int)
    PSFproj = zeros(Float64, size(PSF, dim))
    @inbounds for idx in CartesianIndices(PSF)
        PSFproj[idx[dim]] += Float64(PSF[idx])
    end
    return PSFproj
end

function edgetaper_autocorrelation_beta(PSFproj::Vector{Float64}, out_length::Int)
    fft_length = out_length - 1
    padded = zeros(Float64, fft_length)
    copyto!(padded, 1, PSFproj, 1, length(PSFproj))

    spectrum = FFTW.fft(padded)
    @inbounds for k in eachindex(spectrum)
        spectrum[k] = abs2(spectrum[k])
    end
    z = FFTW.ifft!(spectrum)

    maxz = 0.0
    @inbounds for k in eachindex(z)
        maxz = max(maxz, real(z[k]))
    end

    beta = Vector{Float64}(undef, out_length)
    inv_maxz = inv(maxz)
    @inbounds for k in 1:fft_length
        beta[k] = real(z[k]) * inv_maxz
    end
    beta[out_length] = beta[1]
    return beta
end

function edgetaper_psf2otf(PSF::AbstractArray, outSize::Vector{Int}, psfSize::Vector{Int})
    if length(outSize) == 2
        return edgetaper_psf2otf_2d(PSF, outSize, psfSize)
    elseif length(outSize) == 3
        return edgetaper_psf2otf_3d(PSF, outSize, psfSize)
    else
        return edgetaper_psf2otf_nd(PSF, outSize, psfSize)
    end
end

function edgetaper_psf2otf_2d(
    PSF::AbstractArray, outSize::Vector{Int}, psfSize::Vector{Int}
)
    npsf = zeros(Float64, outSize[1], outSize[2])
    @inbounds for j in 1:psfSize[2], i in 1:psfSize[1]
        npsf[i, j] = Float64(PSF[i, j])
    end
    return FFTW.fft(circshift(npsf, (-fld(psfSize[1], 2), -fld(psfSize[2], 2))))
end

function edgetaper_psf2otf_3d(
    PSF::AbstractArray, outSize::Vector{Int}, psfSize::Vector{Int}
)
    npsf = zeros(Float64, outSize[1], outSize[2], outSize[3])
    @inbounds for k in 1:psfSize[3], j in 1:psfSize[2], i in 1:psfSize[1]
        npsf[i, j, k] = Float64(PSF[i, j, k])
    end
    shifts = (-fld(psfSize[1], 2), -fld(psfSize[2], 2), -fld(psfSize[3], 2))
    return FFTW.fft(circshift(npsf, shifts))
end

function edgetaper_psf2otf_nd(
    PSF::AbstractArray, outSize::Vector{Int}, psfSize::Vector{Int}
)
    npsf = zeros(Float64, Tuple(outSize))
    out_ndims = length(outSize)
    psf_ndims = ndims(PSF)
    @inbounds for idx in CartesianIndices(PSF)
        out_idx = ntuple(d -> d <= psf_ndims ? idx[d] : 1, out_ndims)
        npsf[out_idx...] = Float64(PSF[idx])
    end
    shifts = ntuple(d -> -fld(psfSize[d], 2), out_ndims)
    return FFTW.fft(circshift(npsf, shifts))
end

function edgetaper_blend!(
    J::Array{Float64},
    I::AbstractArray,
    blurredI::AbstractArray,
    beta::Vector{Vector{Float64}},
    numNSdim::Vector{Int},
    minI::Float64,
    maxI::Float64,
)
    if length(numNSdim) == 2 && numNSdim[1] == 1 && numNSdim[2] == 2 && ndims(J) <= 3
        edgetaper_blend_12!(J, I, blurredI, beta[1], beta[2], minI, maxI)
    else
        edgetaper_blend_generic!(J, I, blurredI, beta, numNSdim, minI, maxI)
    end
    return J
end

function edgetaper_blend_12!(
    J::Array{Float64},
    I::AbstractArray,
    blurredI::AbstractArray,
    beta1::Vector{Float64},
    beta2::Vector{Float64},
    minI::Float64,
    maxI::Float64,
)
    if ndims(J) == 2
        @inbounds for j in axes(J, 2)
            a2 = 1.0 - beta2[j]
            for i in axes(J, 1)
                alpha = (1.0 - beta1[i]) * a2
                value = alpha * Float64(I[i, j]) + (1.0 - alpha) * real(blurredI[i, j])
                J[i, j] = clamp(value, minI, maxI)
            end
        end
    else
        @inbounds for k in axes(J, 3), j in axes(J, 2)
            a2 = 1.0 - beta2[j]
            for i in axes(J, 1)
                alpha = (1.0 - beta1[i]) * a2
                value =
                    alpha * Float64(I[i, j, k]) + (1.0 - alpha) * real(blurredI[i, j, k])
                J[i, j, k] = clamp(value, minI, maxI)
            end
        end
    end
    return J
end

function edgetaper_blend_generic!(
    J::Array{Float64},
    I::AbstractArray,
    blurredI::AbstractArray,
    beta::Vector{Vector{Float64}},
    numNSdim::Vector{Int},
    minI::Float64,
    maxI::Float64,
)
    @inbounds for idx in CartesianIndices(J)
        alpha = 1.0
        for k in eachindex(numNSdim)
            alpha *= 1.0 - beta[k][idx[numNSdim[k]]]
        end
        value = alpha * Float64(I[idx]) + (1.0 - alpha) * real(blurredI[idx])
        J[idx] = clamp(value, minI, maxI)
    end
    return J
end

function edgetaper_parse_inputs(I, PSF)
    classI = eltype(I)
    if classI ∉ _EDGETAPER_ALLOWED_TYPES
        error(
            _msg(
                @tr(
                    "First input, I, must be one of the following types:\n\nUInt8, UInt16, Int16, Float64, Float32\n\nbut its type was %{1}.",
                    classI
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite, I)
        error(
            _msg(@tr("First input, I, must be finite."), splitext(basename(@__FILE__))[1])
        )
    end

    if classI <: Integer
        I = im2single(I)
    end

    sizeI = size(I)
    if prod(sizeI) < 2
        error(
            _msg(
                @tr("EDGETAPER: Input image must have at least two elements."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    classPSF = eltype(PSF)
    if classPSF ∉ _EDGETAPER_ALLOWED_TYPES
        error(
            _msg(
                @tr(
                    "Second input, PSF, must be one of the following types:\n\nUInt8, UInt16, Int16, Float64, Float32\n\nbut its type was %{1}.",
                    classPSF
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite, PSF)
        error(
            _msg(
                @tr("Second input, PSF, must be finite."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    if all(iszero, PSF)
        error(
            _msg(
                @tr("EDGETAPER: PSF must contain at least one nonzero element."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if length(PSF) < 2
        error(
            _msg(
                @tr("EDGETAPER: PSF must contain at least two elements."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if classPSF <: Integer
        PSF = im2single(PSF)
    end

    if all(x -> x >= zero(x), PSF)
        PSF = PSF ./ sum(PSF)
    end

    sizeI, sizePSF = edgetaper_padlength(sizeI, size(PSF))

    numNSdim = findall(!=(1), sizePSF)
    if any(dim -> sizeI[dim] <= 2 * sizePSF[dim], numNSdim)
        error(
            _msg(
                @tr(
                    "EDGETAPER: Each non-singleton dimension of PSF must be smaller than the corresponding image dimension."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return I, PSF, sizeI, classI, sizePSF, numNSdim
end

function edgetaper_padlength(sz1::Tuple, sz2::Tuple)
    numDims = max(length(sz1), length(sz2))
    out1 = ones(Int, numDims)
    out2 = ones(Int, numDims)
    for k in eachindex(sz1)
        out1[k] = sz1[k]
    end
    for k in eachindex(sz2)
        out2[k] = sz2[k]
    end
    return out1, out2
end

precompile(edgetaper, (Matrix{UInt8}, Matrix{Float64}))
precompile(edgetaper, (Matrix{Float32}, Matrix{Float64}))
