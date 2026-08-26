"""
illumpca - 使用主成分分析（PCA）估计光源

illuminant = illumpca(A)

illuminant = illumpca(A,percentage)

illuminant = illumpca(___;Mask=mask)
"""
function illumpca(
    A::AbstractArray{<:Real}, percentage::Real=3.5; Mask::AbstractArray{<:Real}=[true;;]
)
    A, p, mask = illumpca_parseInputs(A, percentage, Mask)
    return _illumpca_impl(A, p, mask)
end

function _illumpca_impl(A::AbstractArray{T,3}, p::Float64, mask) where {T}
    W = _illumpca_work_type(T)
    pixelCount, meanColor = _illumpca_mean_color(A, mask, W)
    if pixelCount == 0
        error(
            _msg(
                @tr(
                    "Input image has no pixels available for computation.\nMask is expected to have at least one nonzero value.",
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    normMeanSquared =
        meanColor[1] * meanColor[1] +
        meanColor[2] * meanColor[2] +
        meanColor[3] * meanColor[3]
    if isnan(normMeanSquared)
        error(
            _msg(@tr("First input, A, must be non-NaN."), splitext(basename(@__FILE__))[1])
        )
    end
    if !isfinite(normMeanSquared)
        error(
            _msg(@tr("First input, A, must be finite."), splitext(basename(@__FILE__))[1])
        )
    end

    if (p >= 50) || (pixelCount == 1)
        selectedCount, selectedSum, gram = _illumpca_all_moments(A, mask, W)
    else
        selectedPerSide = max(1, floor(Int, p / 100 * pixelCount))
        if iszero(normMeanSquared)
            selectedCount, selectedSum, gram = _illumpca_ordinal_extreme_moments(
                A, mask, W, pixelCount, selectedPerSide
            )
        else
            projections = Vector{W}(undef, pixelCount)
            _illumpca_fill_projections!(projections, A, mask, meanColor, normMeanSquared, W)
            lowThreshold = partialsort!(projections, selectedPerSide)
            highThreshold = partialsort!(projections, pixelCount - selectedPerSide + 1)

            lowStrictCount = 0
            highStrictCount = 0
            highEqualCount = 0
            @inbounds for value in projections
                lowStrictCount += value < lowThreshold
                highStrictCount += value > highThreshold
                highEqualCount += value == highThreshold
            end

            lowTieLimit = selectedPerSide - lowStrictCount
            highTieSkip = highEqualCount - (selectedPerSide - highStrictCount)
            selectedCount, selectedSum, gram = _illumpca_threshold_moments(
                A,
                mask,
                W,
                meanColor,
                normMeanSquared,
                lowThreshold,
                highThreshold,
                lowTieLimit,
                highTieSkip,
            )
        end
    end

    return _illumpca_from_moments(selectedCount, selectedSum, gram)
end

_illumpca_work_type(::Type{Float64}) = Float64
_illumpca_work_type(::Type) = Float32

@inline _illumpca_value(value::Float64) = value
@inline _illumpca_value(value::Float32) = value
@inline _illumpca_value(value::UInt8) = Float32(value) / 255.0f0
@inline _illumpca_value(value::UInt16) = Float32(value) / 65535.0f0

@inline _illumpca_mask_includes(::Nothing, index::Int) = true
@inline function _illumpca_mask_includes(mask::AbstractArray, index::Int)
    @inbounds(mask[index] != 0)
end

function _illumpca_mean_color(
    A::AbstractArray{T,3}, mask, ::Type{W}
) where {T,W<:AbstractFloat}
    planeLength = size(A, 1) * size(A, 2)
    sumR = zero(W)
    sumG = zero(W)
    sumB = zero(W)
    count = 0

    @inbounds for index in 1:planeLength
        if _illumpca_mask_includes(mask, index)
            sumR += _illumpca_value(A[index])
            sumG += _illumpca_value(A[index + planeLength])
            sumB += _illumpca_value(A[index + 2 * planeLength])
            count += 1
        end
    end

    if count == 0
        return 0, (zero(W), zero(W), zero(W))
    end
    scale = one(W) / W(count)
    return count, (sumR * scale, sumG * scale, sumB * scale)
end

function _illumpca_fill_projections!(
    projections::Vector{W},
    A::AbstractArray{T,3},
    mask,
    meanColor,
    normMeanSquared::W,
    ::Type{W},
) where {T,W<:AbstractFloat}
    planeLength = size(A, 1) * size(A, 2)
    position = 1
    @inbounds for index in 1:planeLength
        if _illumpca_mask_includes(mask, index)
            r = _illumpca_value(A[index])
            g = _illumpca_value(A[index + planeLength])
            b = _illumpca_value(A[index + 2 * planeLength])
            projections[position] =
                (r * meanColor[1] + g * meanColor[2] + b * meanColor[3]) / normMeanSquared
            position += 1
        end
    end
    return projections
end

function _illumpca_all_moments(
    A::AbstractArray{T,3}, mask, ::Type{W}
) where {T,W<:AbstractFloat}
    planeLength = size(A, 1) * size(A, 2)
    count = 0
    sumR = zero(W)
    sumG = zero(W)
    sumB = zero(W)
    rr = zero(W)
    rg = zero(W)
    rb = zero(W)
    gg = zero(W)
    gb = zero(W)
    bb = zero(W)

    @inbounds for index in 1:planeLength
        if _illumpca_mask_includes(mask, index)
            r = _illumpca_value(A[index])
            g = _illumpca_value(A[index + planeLength])
            b = _illumpca_value(A[index + 2 * planeLength])
            count += 1
            sumR += r
            sumG += g
            sumB += b
            rr += r * r
            rg += r * g
            rb += r * b
            gg += g * g
            gb += g * b
            bb += b * b
        end
    end

    return count, (sumR, sumG, sumB), _illumpca_gram(rr, rg, rb, gg, gb, bb)
end

function _illumpca_ordinal_extreme_moments(
    A::AbstractArray{T,3}, mask, ::Type{W}, pixelCount::Int, selectedPerSide::Int
) where {T,W<:AbstractFloat}
    planeLength = size(A, 1) * size(A, 2)
    ordinal = 0
    count = 0
    sumR = zero(W)
    sumG = zero(W)
    sumB = zero(W)
    rr = zero(W)
    rg = zero(W)
    rb = zero(W)
    gg = zero(W)
    gb = zero(W)
    bb = zero(W)

    @inbounds for index in 1:planeLength
        if _illumpca_mask_includes(mask, index)
            ordinal += 1
            if (ordinal <= selectedPerSide) || (ordinal > pixelCount - selectedPerSide)
                r = _illumpca_value(A[index])
                g = _illumpca_value(A[index + planeLength])
                b = _illumpca_value(A[index + 2 * planeLength])
                count += 1
                sumR += r
                sumG += g
                sumB += b
                rr += r * r
                rg += r * g
                rb += r * b
                gg += g * g
                gb += g * b
                bb += b * b
            end
        end
    end

    return count, (sumR, sumG, sumB), _illumpca_gram(rr, rg, rb, gg, gb, bb)
end

function _illumpca_threshold_moments(
    A::AbstractArray{T,3},
    mask,
    ::Type{W},
    meanColor,
    normMeanSquared::W,
    lowThreshold::W,
    highThreshold::W,
    lowTieLimit::Int,
    highTieSkip::Int,
) where {T,W<:AbstractFloat}
    planeLength = size(A, 1) * size(A, 2)
    lowEqualSeen = 0
    highEqualSeen = 0
    count = 0
    sumR = zero(W)
    sumG = zero(W)
    sumB = zero(W)
    rr = zero(W)
    rg = zero(W)
    rb = zero(W)
    gg = zero(W)
    gb = zero(W)
    bb = zero(W)

    @inbounds for index in 1:planeLength
        if _illumpca_mask_includes(mask, index)
            r = _illumpca_value(A[index])
            g = _illumpca_value(A[index + planeLength])
            b = _illumpca_value(A[index + 2 * planeLength])
            projection =
                (r * meanColor[1] + g * meanColor[2] + b * meanColor[3]) / normMeanSquared

            selected = projection < lowThreshold || projection > highThreshold
            if projection == lowThreshold
                lowEqualSeen += 1
                selected |= lowEqualSeen <= lowTieLimit
            end
            if projection == highThreshold
                highEqualSeen += 1
                selected |= highEqualSeen > highTieSkip
            end

            if selected
                count += 1
                sumR += r
                sumG += g
                sumB += b
                rr += r * r
                rg += r * g
                rb += r * b
                gg += g * g
                gb += g * b
                bb += b * b
            end
        end
    end

    return count, (sumR, sumG, sumB), _illumpca_gram(rr, rg, rb, gg, gb, bb)
end

function _illumpca_gram(rr, rg, rb, gg, gb, bb)
    return [
        rr rg rb
        rg gg gb
        rb gb bb
    ]
end

function _illumpca_from_moments(selectedCount::Int, selectedSum, gram::Matrix{W}) where {W}
    meanIlluminant = reshape(
        Float64[
            selectedSum[1] / selectedCount,
            selectedSum[2] / selectedCount,
            selectedSum[3] / selectedCount,
        ],
        1,
        3,
    )
    if selectedCount < 2
        return meanIlluminant
    end

    decomposition = LinearAlgebra.eigen(LinearAlgebra.Symmetric(gram))
    singularValues = sqrt.(max.(decomposition.values, zero(W)))
    vectors = decomposition.vectors[:, end:-1:1]
    singularValues = singularValues[end:-1:1]

    epsilon = 10 * eps(W)
    standardBasis = true
    @inbounds for column in 1:3
        for row in 1:3
            expected = row == column ? one(W) : zero(W)
            standardBasis &= vectors[row, column] == expected
        end
    end

    if standardBasis || (
        (singularValues[1] - singularValues[2] <= epsilon) &&
        (singularValues[1] - singularValues[3] <= epsilon)
    )
        return meanIlluminant
    end

    illuminant = zeros(1, 3)
    @inbounds for channel in 1:3
        illuminant[channel] = abs(Float64(vectors[channel, 1]))
    end
    return illuminant
end

function _illumpca_any_nan(mask::AbstractArray)
    return any(value -> value isa AbstractFloat && isnan(value), mask)
end

function _illumpca_is_default_mask(mask::AbstractArray)
    return ndims(mask) == 2 &&
           size(mask, 1) == 1 &&
           size(mask, 2) == 1 &&
           first(mask) == true
end

function illumpca_parseInputs(A, percentage, mask)
    if eltype(A) ∉ [Float32, Float64, UInt8, UInt16]
        error(
            _msg(
                @tr(
                    "Invalid value for 'A'. First input, A, must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    "Float32, Float64, UInt8, UInt16",
                    eltype(A),
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(A)
        error(
            _msg(
                @tr("Invalid value for 'A'. First input, A, must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isnan(percentage)
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentage'. Second input, percentage, must be non-NaN."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if percentage <= 0
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentage'. Second input, percentage, must be positive."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if percentage > 50
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentage'. Second input, percentage, must be a scalar with value <= 50."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isempty(mask)
        error(
            _msg(
                @tr("Invalid value for 'Mask'. Mask must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if ndims(mask) != 2
        error(
            _msg(
                @tr("Invalid value for 'Mask'. Mask must be two-dimensional."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if _illumpca_any_nan(mask)
        error(
            _msg(
                @tr("Invalid value for 'Mask'. Mask must be non-NaN."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    validColorImage = (ndims(A) == 3) && (size(A, 3) == 3)
    if !validColorImage
        error(_msg(@tr("A is not a valid RGB image."), splitext(basename(@__FILE__))[1]))
    end

    defaultMask = _illumpca_is_default_mask(mask)
    if !defaultMask && ((size(A, 1) != size(mask, 1)) || (size(A, 2) != size(mask, 2)))
        error(
            _msg(
                @tr("A and Mask must have the same number of rows and columns."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return A, Float64(percentage), defaultMask ? nothing : mask
end

precompile(illumpca, (Array{Float64,3},))
precompile(illumpca, (Array{Float64,3}, Float64))
precompile(illumpca, (Array{UInt8,3}, Float64))
precompile(_illumpca_impl, (Array{Float64,3}, Float64, Nothing))
precompile(_illumpca_impl, (Array{Float32,3}, Float64, Nothing))
precompile(_illumpca_impl, (Array{UInt8,3}, Float64, Nothing))
precompile(_illumpca_impl, (Array{UInt16,3}, Float64, Nothing))
precompile(_illumpca_impl, (Array{Float64,3}, Float64, BitMatrix))
