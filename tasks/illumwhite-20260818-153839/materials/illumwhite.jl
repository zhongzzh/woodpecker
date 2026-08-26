"""
illumwhite - 使用白色小块视网膜皮层（White Patch Retinex）算法估计光源。

illuminant = illumwhite(A)

illuminant = illumwhite(A,topPercentile)

illuminant = illumwhite(___;Mask=mask)
"""
function illumwhite(
    A::AbstractArray{<:Real}, p::Real=1; Mask::AbstractArray{<:Real}=[true;;]
)
    A, p, mask = illumwhite_parseInputs(A, p, Mask)
    return _illumwhite_impl(A, p, mask)
end

function _illumwhite_impl(A::AbstractArray{T,3}, p::Float64, mask) where {T}
    rows = size(A, 1)
    cols = size(A, 2)
    numBins = _illumwhite_num_bins(T)
    pixelCount = _illumwhite_mask_count(mask, rows, cols)
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

    cutoff = pixelCount * p / 100
    counts = zeros(Int, numBins)
    illuminant = zeros(1, 3)
    for k in 1:3
        fill!(counts, 0)
        _illumwhite_accumulate!(counts, A, k, mask)
        idx = _illumwhite_high_index(counts, cutoff)
        if idx != 0
            illuminant[k] = _illumwhite_bin_location(T, idx, numBins)
        end
    end

    return illuminant
end

_illumwhite_num_bins(::Type{UInt8}) = 2^8
_illumwhite_num_bins(::Type) = 2^16

_illumwhite_bin_index(::Type{UInt8}, value::UInt8, numBins::Int) = Int(value) + 1
_illumwhite_bin_index(::Type{UInt16}, value::UInt16, numBins::Int) = Int(value) + 1
function _illumwhite_bin_index(::Type{T}, value::T, numBins::Int) where {T<:AbstractFloat}
    if isnan(value)
        return 0
    elseif value > one(T)
        return numBins
    elseif !isfinite(value)
        return 0
    end

    idx = floor(Int, Float64(value) * (numBins - 1) + 1.5)
    return 1 <= idx <= numBins ? idx : 0
end

_illumwhite_bin_location(::Type{UInt8}, idx::Int, numBins::Int) = Float64(idx - 1) / 255.0
function _illumwhite_bin_location(::Type{UInt16}, idx::Int, numBins::Int)
    return Float64(idx - 1) / 65535.0
end
function _illumwhite_bin_location(::Type{<:AbstractFloat}, idx::Int, numBins::Int)
    return Float64(idx - 1) / (numBins - 1)
end

_illumwhite_mask_count(::Nothing, rows::Int, cols::Int) = rows * cols
function _illumwhite_mask_count(mask::AbstractArray, rows::Int, cols::Int)
    count = 0
    @inbounds for j in 1:cols
        for i in 1:rows
            count += mask[i, j] != 0
        end
    end
    return count
end

function _illumwhite_accumulate!(
    counts::Vector{Int}, A::AbstractArray{T,3}, channel::Int, ::Nothing
) where {T}
    numBins = length(counts)
    rows = size(A, 1)
    cols = size(A, 2)
    @inbounds for j in 1:cols
        for i in 1:rows
            idx = _illumwhite_bin_index(T, A[i, j, channel], numBins)
            if idx != 0
                counts[idx] += 1
            end
        end
    end
    return counts
end

function _illumwhite_accumulate!(
    counts::Vector{Int}, A::AbstractArray{T,3}, channel::Int, mask::AbstractArray
) where {T}
    numBins = length(counts)
    rows = size(A, 1)
    cols = size(A, 2)
    @inbounds for j in 1:cols
        for i in 1:rows
            if mask[i, j] != 0
                idx = _illumwhite_bin_index(T, A[i, j, channel], numBins)
                if idx != 0
                    counts[idx] += 1
                end
            end
        end
    end
    return counts
end

function _illumwhite_high_index(counts::Vector{Int}, cutoff::Float64)
    tailCount = 0
    @inbounds for idx in length(counts):-1:1
        tailCount += counts[idx]
        if tailCount > cutoff
            return idx
        end
    end
    return 0
end

function _illumwhite_any_nan(mask::AbstractArray)
    return any(value -> value isa AbstractFloat && isnan(value), mask)
end
function _illumwhite_is_default_mask(mask::AbstractArray)
    return ndims(mask) == 2 && size(mask, 1) == 1 && size(mask, 2) == 1 && first(mask) != 0
end

function illumwhite_parseInputs(A, p, mask)
    if eltype(A) ∉ [Float32, Float64, UInt8, UInt16]
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

    if isnan(p)
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentile'. Second input, percentile, must be non-NaN."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if p < 0
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentile'. Second input, percentile, must be nonnegative."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if p >= 100
        error(
            _msg(
                @tr(
                    "Invalid value for 'percentile'. Second input, percentile, must be a scalar with value < 100."
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
    if _illumwhite_any_nan(mask)
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

    defaultMask = _illumwhite_is_default_mask(mask)
    if !defaultMask && ((size(A, 1) != size(mask, 1)) || (size(A, 2) != size(mask, 2)))
        error(
            _msg(
                @tr("A and Mask must have the same number of rows and columns."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return A, Float64(p), defaultMask ? nothing : mask
end

precompile(illumwhite, (Array{Float64,3},))
precompile(illumwhite, (Array{Float64,3}, Float64))
precompile(illumwhite, (Array{UInt8,3}, Int64))
precompile(_illumwhite_impl, (Array{Float64,3}, Float64, Nothing))
precompile(_illumwhite_impl, (Array{Float32,3}, Float64, Nothing))
precompile(_illumwhite_impl, (Array{UInt8,3}, Float64, Nothing))
precompile(_illumwhite_impl, (Array{UInt16,3}, Float64, Nothing))
precompile(_illumwhite_impl, (Array{Float64,3}, Float64, BitMatrix))
