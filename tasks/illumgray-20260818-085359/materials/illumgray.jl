"""
illumgray - 使用灰度世界算法估计光源

illuminant = illumgray(A)

illuminant = illumgray(A, percentile)

illuminant = illumgray(___; Name=Value)
"""
function illumgray(
    A::AbstractArray{<:Real},
    percentile::Union{Real,AbstractVecOrMat{<:Real}}=1;
    Mask::AbstractArray{<:Real}=[true;;],
    Norm::Real=1,
)
    A, percentiles, mask, exponent = illumgray_parseInputs(A, percentile, Mask, Norm)
    return _illumgray_impl(A, percentiles[1], percentiles[2], mask, exponent)
end

@inline _illumgray_num_bins(::Type{UInt8}) = 256
@inline _illumgray_num_bins(::Type{T}) where {T<:Union{UInt16,Float32,Float64}} = 65536

@inline _illumgray_bin_index(v::UInt8, ::Int) = Int(v) + 1
@inline _illumgray_bin_index(v::UInt16, ::Int) = Int(v) + 1
@inline function _illumgray_bin_index(v::Union{Float32,Float64}, numBins::Int)
    x = Float64(v)
    isnan(x) && return 0
    x > 1.0 && return numBins

    scale = Float64(numBins - 1)
    x < -0.5 / scale && return 0

    idx = floor(Int, x * scale + 1.5)
    return ifelse(idx > numBins, numBins, idx)
end

@inline _illumgray_bin_location(::Type{UInt8}, idx::Int, ::Int) = Float64(idx - 1)
@inline _illumgray_bin_location(::Type{UInt16}, idx::Int, ::Int) = Float64(idx - 1)
@inline function _illumgray_bin_location(
    ::Type{T}, idx::Int, numBins::Int
) where {T<:Union{Float32,Float64}}
    return Float64(idx - 1) / Float64(numBins - 1)
end

@inline _illumgray_to_double(v::UInt8) = Float64(v) / 255.0
@inline _illumgray_to_double(v::UInt16) = Float64(v) / 65535.0
@inline _illumgray_to_double(v::Float32) = Float64(v)
@inline _illumgray_to_double(v::Float64) = v

@inline function _illumgray_in_range(
    v::Union{UInt8,UInt16}, minVal::Float64, maxVal::Float64
)
    return minVal <= Float64(v) <= maxVal
end

@inline function _illumgray_in_range(
    v::Union{Float32,Float64}, minVal::Float64, maxVal::Float64
)
    x = Float64(v)
    return minVal - 1e-5 <= x <= maxVal + 1e-5
end

function _illumgray_impl(
    A::AbstractArray{T,3},
    lowPercentile::Float64,
    highPercentile::Float64,
    mask::AbstractMatrix{Bool},
    exponent::Float64,
) where {T<:Union{UInt8,UInt16,Float32,Float64}}
    numBins = _illumgray_num_bins(T)
    counts = zeros(Int, numBins)
    illuminant = zeros(1, 3)

    @inbounds for k in 1:3
        fill!(counts, 0)
        maskedCount = 0

        for j in axes(A, 2), i in axes(A, 1)
            if mask[i, j]
                maskedCount += 1
                idx = _illumgray_bin_index(A[i, j, k], numBins)
                idx != 0 && (counts[idx] += 1)
            end
        end

        if maskedCount == 0
            error(
                _msg(
                    @tr(
                        "Input image has no pixels available for computation.\nMask is expected to have at least one nonzero value.",
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        idxLow = _illumgray_low_index(counts, maskedCount * lowPercentile / 100)
        idxHigh = _illumgray_high_index(counts, maskedCount * highPercentile / 100)
        minVal = _illumgray_bin_location(T, idxLow, numBins)
        maxVal = _illumgray_bin_location(T, idxHigh, numBins)

        normAccum = 0.0
        selectedCount = 0

        if isinf(exponent)
            for j in axes(A, 2), i in axes(A, 1)
                v = A[i, j, k]
                if mask[i, j] && _illumgray_in_range(v, minVal, maxVal)
                    selectedCount += 1
                    normAccum = max(normAccum, abs(_illumgray_to_double(v)))
                end
            end
            illuminant[k] = normAccum / selectedCount
        elseif exponent == 1.0
            for j in axes(A, 2), i in axes(A, 1)
                v = A[i, j, k]
                if mask[i, j] && _illumgray_in_range(v, minVal, maxVal)
                    selectedCount += 1
                    normAccum += abs(_illumgray_to_double(v))
                end
            end
            illuminant[k] = normAccum / selectedCount
        elseif exponent == 2.0
            for j in axes(A, 2), i in axes(A, 1)
                v = A[i, j, k]
                if mask[i, j] && _illumgray_in_range(v, minVal, maxVal)
                    selectedCount += 1
                    x = _illumgray_to_double(v)
                    normAccum += abs2(x)
                end
            end
            illuminant[k] = sqrt(normAccum) / selectedCount
        else
            for j in axes(A, 2), i in axes(A, 1)
                v = A[i, j, k]
                if mask[i, j] && _illumgray_in_range(v, minVal, maxVal)
                    selectedCount += 1
                    normAccum += abs(_illumgray_to_double(v))^exponent
                end
            end
            illuminant[k] = normAccum^(1 / exponent) / selectedCount
        end
    end

    return illuminant
end

function _illumgray_low_index(counts::Vector{Int}, threshold::Float64)
    total = 0
    @inbounds for idx in eachindex(counts)
        total += counts[idx]
        total > threshold && return idx
    end
    return lastindex(counts)
end

function _illumgray_high_index(counts::Vector{Int}, threshold::Float64)
    total = 0
    @inbounds for idx in lastindex(counts):-1:firstindex(counts)
        total += counts[idx]
        total > threshold && return idx
    end
    return firstindex(counts)
end

@inline _illumgray_any(f, x::Real) = f(x)
@inline _illumgray_any(f, x) = any(f, x)

@inline function _illumgray_is_default_mask(mask)
    return ndims(mask) == 2 &&
           size(mask, 1) == 1 &&
           size(mask, 2) == 1 &&
           mask[begin] == true
end

function illumgray_parseInputs(A, percentile, Mask, Norm)
    T = eltype(A)
    if !(T === Float32 || T === Float64 || T === UInt8 || T === UInt16)
        error(
            _msg(
                @tr(
                    "Invalid value for 'A'. First input, A, must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    "Float32, Float64, UInt8, UInt16",
                    eltype(A)
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

    if _illumgray_any(isnan, percentile)
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentiles'. Second input, [bottomPercentile topPercentile], must be non-NaN."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if _illumgray_any(x -> x < 0, percentile)
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentiles'. Second input, [bottomPercentile topPercentile], must be nonnegative."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if _illumgray_any(x -> x >= 100, percentile)
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentiles'. Second input, [bottomPercentile topPercentile], must be an array with all values < 100."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isempty(Mask)
        error(
            _msg(
                @tr("Invalid value for 'Mask'. Mask must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if ndims(Mask) != 2
        error(
            _msg(
                @tr("Invalid value for 'Mask'. Mask must be two-dimensional."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if _illumgray_any(isnan, Mask)
        error(
            _msg(
                @tr("Invalid value for 'Mask'. Mask must be non-NaN."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if Norm <= 0
        error(
            _msg(
                @tr("Invalid value for 'Norm'. Norm must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    percentiles = Float64.(percentile)
    mask = Mask
    exponent = Float64(Norm)

    validColorImage = (ndims(A) == 3) && (size(A, 3) == 3)
    if !validColorImage
        error(_msg(@tr("A is not a valid RGB image."), splitext(basename(@__FILE__))[1]))
    end

    if isscalar(percentiles)
        percentiles = [percentiles percentiles]
    else
        if length(percentiles) != 2
            error(
                _msg(
                    @tr("Second input, percentiles, must be an array with 2 elements."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    if (sum(percentiles) > 100)
        error(
            _msg(
                @tr(
                    "No pixels of the input image are available for computation.\nSecond input [bottomPercentile topPercentile] must have sum <= 100.\nActual input [bottomPercentile topPercentile]=[%{1} %{2}], sum is %{3}.",
                    percentiles[1],
                    percentiles[2],
                    sum(percentiles)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if _illumgray_is_default_mask(mask)
        mask = trues(size(A, 1), size(A, 2))
    end

    if (size(A, 1) != size(mask, 1)) || (size(A, 2) != size(mask, 2))
        error(
            _msg(
                @tr("A and Mask must have the same number of rows and columns."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if eltype(mask) !== Bool
        mask = image_internal_cast(mask, Bool)
    end

    return A, percentiles, mask, exponent
end

precompile(illumgray, (Array{Float64,3},))
precompile(illumgray, (Array{Float32,3},))
precompile(illumgray, (Array{UInt8,3},))
precompile(illumgray, (Array{UInt16,3},))
precompile(illumgray, (Array{Float64,3}, Int64))
precompile(illumgray, (Array{Float32,3}, Int64))
precompile(illumgray, (Array{UInt8,3}, Int64))
precompile(illumgray, (Array{UInt16,3}, Int64))
precompile(_illumgray_impl, (Array{Float64,3}, Float64, Float64, BitMatrix, Float64))
precompile(_illumgray_impl, (Array{Float64,3}, Float64, Float64, Matrix{Bool}, Float64))
precompile(_illumgray_impl, (Array{Float32,3}, Float64, Float64, BitMatrix, Float64))
precompile(_illumgray_impl, (Array{UInt8,3}, Float64, Float64, BitMatrix, Float64))
precompile(_illumgray_impl, (Array{UInt16,3}, Float64, Float64, BitMatrix, Float64))
