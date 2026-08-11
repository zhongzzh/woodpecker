"""
edgetaper - 沿图像边缘的锥形不连续性

J = edgetaper(I,PSF)
"""
function edgetaper(I::AbstractArray{<:Real}, PSF::AbstractArray{<:Real})
    I, PSF, sizeI, classI, sizePSF, numNSdim = edgetaper_parse_inputs(I, PSF)

    idx0 = Matrix{Union{Real,Colon}}(undef, 1, maximum(size(sizePSF)))
    idx0[:] .= Base.:(:)
    lenNSdim = maximum(size(numNSdim))
    beta = Matrix{AbstractArray}(undef, 1, lenNSdim)
    for n in 1:lenNSdim
        PSFproj = zeros(1, size(PSF, numNSdim[n]))
        for m in 1:size(PSF, numNSdim[n])
            sliceidx = copy(idx0)
            sliceidx[numNSdim[n]] = m
            slice = PSF[sliceidx[:]...]
            PSFproj[m] = sum(slice[:])
        end

        z = real(ty_ifftn(abs.(ty_fftn(PSFproj, Int[1, sizeI[numNSdim[n]] - 1])) .^ 2))
        z = [z[1:end]; z[1]] / maximum(z[:])
        z = reshape(z, 1, length(z))
        beta[n] = z
    end

    n = lenNSdim
    if n == 1
        alpha = 1 - beta[1]
    elseif n == 2
        alpha = (1 .- beta[1][:]) * (1 .- beta[2])
    else
        beta[:] = ndgrid(beta[:])
        alpha = 1 - beta[1]
        for k in 2:n
            alpha = alpha .* (1 - beta[k])
        end
    end

    idx1 = Matrix{Union{Real,Colon}}(undef, 1, maximum(size(sizePSF)))
    idx1[:] .= [1]
    i = Matrix{Union{Real,Colon}}(undef, 1, n)
    i .= Base.:(:)

    idx1[numNSdim] = i
    alpha_xtnd = rand(size(alpha)...)
    alpha_xtnd[idx1[:]...] = alpha
    idx2 = copy(sizeI)
    idx2[numNSdim] .= 1
    alpha = repeat(alpha_xtnd, Int.(idx2)...)

    otf = psf2otf(PSF, Int.(sizeI))
    blurredI = real(ty_ifftn(ty_fftn(I) .* otf))
    J = alpha .* I + (1 .- alpha) .* blurredI

    mami = [maximum(I[:]) minimum(I[:])]
    J[J .> mami[1]] .= mami[1]
    J[J .< mami[2]] .= mami[2]

    if classI <: Integer
        J = images_internal_changeClass(classI, J)
    end

    return J
end

function edgetaper_parse_inputs(I, PSF)
    classI = eltype(I)
    if classI ∉ [UInt8, UInt16, Int16, Float64, Float32]
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
    if !all(isfinite.(I))
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
                "EDGETAPER: Input image must have at least two elements.",
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if eltype(PSF) ∉ [UInt8, UInt16, Int16, Float64, Float32]
        error(
            _msg(
                @tr(
                    "Second input, PSF, must be one of the following types:\n\nUInt8, UInt16, Int16, Float64, Float32\n\nbut its type was %{1}.",
                    eltype(PSF)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite.(I))
        error(
            _msg(
                @tr("Second input, PSF, must be finite."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    if all(PSF .== 0)
        error(
            _msg(
                @tr("EDGETAPER: PSF must contain at least one nonzero element."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if (length(PSF) < 2)
        error(
            _msg(
                @tr("EDGETAPER: PSF must contain at least two elements."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if eltype(PSF) <: Integer
        PSF = im2single(PSF)
    end

    if all(PSF .>= 0)
        PSF = PSF / sum(PSF[:])
    end

    sizeI, sizePSF = padlength(
        reshape(collect(sizeI), 1, length(sizeI)),
        reshape(collect(size(PSF)), 1, length(size(PSF)));
        nargout=2,
    )

    numNSdim = find(sizePSF .!= 1)
    if any(sizeI[numNSdim] .<= 2 * sizePSF[numNSdim])
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

function padlength(In...; nargout)
    varargin = In
    nargin = length(varargin)
    numDims = zeros(nargin, 1)
    for k in 1:nargin
        numDims[k] = maximum(size(varargin[k]))
    end
    numDims = maximum(numDims)

    limit = max(1, nargout)
    varargout = Matrix{AbstractArray}(undef, 1, limit)
    for k in 1:limit
        varargout[k] = [varargin[k] ones(1, Int(numDims - maximum(size(varargin[k]))))]
    end

    return varargout
end
