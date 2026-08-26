"""
gradientweight - 基于图像梯度计算图像像素的权重

W = gradientweight(I)

W = gradientweight(I,sigma)

W = gradientweight(___;Name,Value)
"""
function gradientweight(
    I::AbstractArray,
    sigma::Union{Real,AbstractArray}=1.5;
    RolloffFactor::Real=3,
    WeightCutoff::Real=0.25,
)
    I, sigma, rolloffFactor, weightCutoff = gradientweight_parse_inputs(
        I, sigma, RolloffFactor, WeightCutoff
    )

    if eltype(I) <: Integer
        I = Float64.(I)
    end
    isempty(I) && return I

    minI, maxI = extrema(I)
    if (maxI - eps(maxI) * 1000) <= minI
        return ones(eltype(I), size(I))
    end

    W = if ndims(I) == 2
        images_internal_imgradientdog(I, sigma)
    else
        images_internal_imgradientdog3(I, sigma)
    end

    return gradientweight_scale!(W, rolloffFactor, weightCutoff)
end

function gradientweight_parse_inputs(I, sigma, RolloffFactor, WeightCutoff)
    if eltype(I) ∉ [UInt8, Int8, UInt16, Int16, UInt32, Int32, Float32, Float64]
        error(
            _msg(
                @tr(
                    "Invalid value for 'I'. First input, I, must be one of the following types:\n\nUInt8, Int8, UInt16, Int16, UInt32, Int32, Float32, Float64\n\nbut its type was %{1}.",
                    eltype(I)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if ndims(I) > 3
        error(
            _msg(
                @tr("Invalid value for 'I'. First input, I, must be three-dimensional."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if any(sigma .<= 0)
        error(
            _msg(
                @tr("Invalid value for 'sigma'. Second input, sigma, must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite.(sigma))
        error(
            _msg(
                @tr("Invalid value for 'sigma'. Second input, sigma, must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if RolloffFactor <= 0
        error(
            _msg(
                @tr("Invalid value for 'RolloffFactor'. RolloffFactor must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isfinite(RolloffFactor)
        error(
            _msg(
                @tr("Invalid value for 'RolloffFactor'. RolloffFactor must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isnan(WeightCutoff)
        error(
            _msg(
                @tr("Invalid value for 'WeightCutoff'. WeightCutoff must be non-NaN."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if WeightCutoff < 1e-3
        error(
            _msg(
                @tr(
                    "Invalid value for 'WeightCutoff'. WeightCutoff must be a scalar with value >= 0.001."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if WeightCutoff > 1
        error(
            _msg(
                @tr(
                    "Invalid value for 'WeightCutoff'. WeightCutoff must be a scalar with value <= 1."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    rolloffFactor = Float64(RolloffFactor)
    weightCutoff = Float64(WeightCutoff)
    sigma = Float64.(sigma)

    nDimsI = ndims(I)
    numelSigma = length(sigma)

    if numelSigma > nDimsI
        error(_msg(@tr("Invalid sigma length."), splitext(basename(@__FILE__))[1]))
    end

    if nDimsI == 2
        if (numelSigma == 1)
            sigma = [sigma sigma]
        elseif (numelSigma == 2)
            sigma = sigma
        end
    elseif nDimsI == 3
        if (numelSigma == 1)
            sigma = [sigma sigma sigma]
        elseif (numelSigma == 2)
            error(_msg(@tr("Invalid sigma length."), splitext(basename(@__FILE__))[1]))
        elseif (numelSigma == 3)
            sigma = sigma
        end
    end

    return I, sigma, rolloffFactor, weightCutoff
end

function gradientweight_scale!(W, rolloffFactor, weightCutoff)
    minW, maxW = extrema(W)
    if ((maxW - minW) <= eps(maxW))
        fill!(W, one(eltype(W)))
        return W
    end

    floorOfW = eltype(W)(1e-3)
    invRange = inv(maxW - minW)
    invRolloff = inv(eltype(W)(rolloffFactor))
    cutoff = eltype(W)(weightCutoff)
    @inbounds for idx in eachindex(W)
        v = ((W[idx] - minW) * invRange)^invRolloff
        w = (one(v) - v) / (one(v) + v)
        W[idx] = w < cutoff ? floorOfW : w
    end
    return W
end

function gradientweight_dog_kernel(sigma::T) where {T<:AbstractFloat}
    filtRadius = ceil(Int, 2 * sigma)
    h = Vector{T}(undef, 2 * filtRadius + 1)
    denom = 2 * sigma * sigma
    @inbounds for idx in eachindex(h)
        x = T(idx - filtRadius - 1)
        h[idx] = -x * exp(-(x * x) / denom)
    end

    normalizationFactor = zero(T)
    @inbounds for idx in 1:filtRadius
        normalizationFactor += h[idx]
    end
    h ./= normalizationFactor

    maxAbs = zero(T)
    @inbounds for v in h
        maxAbs = max(maxAbs, abs(v))
    end
    cutoff = eps(T) * maxAbs
    @inbounds for idx in eachindex(h)
        abs(h[idx]) < cutoff && (h[idx] = zero(T))
    end
    return h
end

function images_internal_imgradientdog(I::AbstractMatrix{T}, sigma) where {T}
    if any(sigma .<= 0)
        error(_msg(@tr("sigma must be positive."), splitext(basename(@__FILE__))[1]))
    end

    FT = T <: Float32 ? Float32 : Float64
    hx = gradientweight_dog_kernel(FT(sigma[1]))
    hy = gradientweight_dog_kernel(FT(sigma[2]))
    rx = length(hx) >>> 1
    ry = length(hy) >>> 1
    m, n = size(I)
    Gmag = Matrix{FT}(undef, m, n)

    @inbounds for j in 1:n, i in 1:m
        gx = zero(FT)
        for kk in (-rx):rx
            jj = clamp(j + kk, 1, n)
            gx += FT(I[i, jj]) * hx[kk + rx + 1]
        end

        gy = zero(FT)
        for kk in (-ry):ry
            ii = clamp(i + kk, 1, m)
            gy += FT(I[ii, j]) * hy[kk + ry + 1]
        end

        Gmag[i, j] = hypot(gx, gy)
    end
    return Gmag
end

function images_internal_imgradientdog3(I::AbstractArray{T,3}, sigma) where {T}
    if any(sigma .<= 0)
        error(_msg(@tr("sigma must be positive."), splitext(basename(@__FILE__))[1]))
    end

    if length(sigma) != 3
        error(
            _msg(
                @tr("Esigma must be a 3-element vector."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    FT = T <: Float32 ? Float32 : Float64
    hx = gradientweight_dog_kernel(FT(sigma[1]))
    hy = gradientweight_dog_kernel(FT(sigma[2]))
    hz = gradientweight_dog_kernel(FT(sigma[3]))
    rx = length(hx) >>> 1
    ry = length(hy) >>> 1
    rz = length(hz) >>> 1
    m, n, p = size(I)
    Gmag = Array{FT,3}(undef, m, n, p)

    @inbounds for k in 1:p, j in 1:n, i in 1:m
        gx = zero(FT)
        for kk in (-rx):rx
            jj = clamp(j + kk, 1, n)
            gx += FT(I[i, jj, k]) * hx[kk + rx + 1]
        end

        gy = zero(FT)
        for kk in (-ry):ry
            ii = clamp(i + kk, 1, m)
            gy += FT(I[ii, j, k]) * hy[kk + ry + 1]
        end

        gz = zero(FT)
        for kk in (-rz):rz
            zz = clamp(k + kk, 1, p)
            gz += FT(I[i, j, zz]) * hz[kk + rz + 1]
        end

        Gmag[i, j, k] = sqrt(gx * gx + gy * gy + gz * gz)
    end
    return Gmag
end

precompile(gradientweight, (Matrix{UInt8},))
precompile(gradientweight, (Matrix{Float32}, Float64))
precompile(
    Tuple{
        typeof(Core.kwcall),
        NamedTuple{(:RolloffFactor, :WeightCutoff),Tuple{Int64,Float64}},
        typeof(gradientweight),
        Matrix{UInt8},
        Float64,
    },
)
