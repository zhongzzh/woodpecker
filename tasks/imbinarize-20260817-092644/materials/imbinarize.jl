"""
    imbinarize(I)
    imbinarize(I, method)
    imbinarize(I, threshold)

将二维灰度图像 `I` 转换为二值图像。默认使用 Otsu 全局阈值；`method`
可为 `"global"` 或 `"adaptive"`；数值阈值按 MATLAB 的归一化亮度范围解释。

自适应阈值支持关键字 `Sensitivity`（默认 `0.5`）和
`ForegroundPolarity`（默认 `"bright"`）。
"""
function imbinarize(I::AbstractMatrix{T}, threshold::Real) where {T<:Union{MInteger,MFloat}}
    return ty_binarize(I, threshold)
end

function imbinarize(
    I::AbstractMatrix{T}, threshold::AbstractMatrix{<:Real}
) where {T<:Union{MInteger,MFloat}}
    size(threshold) == size(I) || throw(
        DimensionMismatch("threshold must be a scalar or have the same size as the image"),
    )
    return ty_binarize(I, threshold)
end

function ty_binarize(
    I::AbstractMatrix{T}, threshold::Real
) where {T<:Union{MInteger,MFloat}}
    @ccall_check_func_lic :TyImageProcessing

    if T <: Unsigned
        return _imbinarize_compare(I, Float64(threshold) * Float64(typemax(T)))
    elseif T <: Signed
        lo = Float64(typemin(T))
        range = Float64(typemax(T)) - lo
        return _imbinarize_compare(I, lo + Float64(threshold) * range)
    else
        return _imbinarize_compare(I, threshold)
    end
end

function ty_binarize(
    I::AbstractMatrix{T}, threshold::AbstractMatrix{<:Real}
) where {T<:Union{MInteger,MFloat}}
    @ccall_check_func_lic :TyImageProcessing

    result = BitMatrix(undef, size(I))
    if T <: Unsigned
        scale = Float64(typemax(T))
        @inbounds @simd for index in eachindex(I, threshold, result)
            result[index] = I[index] > Float64(threshold[index]) * scale
        end
    elseif T <: Signed
        lo = Float64(typemin(T))
        range = Float64(typemax(T)) - lo
        @inbounds @simd for index in eachindex(I, threshold, result)
            result[index] = I[index] > lo + Float64(threshold[index]) * range
        end
    else
        @inbounds @simd for index in eachindex(I, threshold, result)
            result[index] = I[index] > threshold[index]
        end
    end
    return result
end

function _imbinarize_compare(I::AbstractMatrix, threshold)
    return I .> threshold
end

function imbinarize(
    I::AbstractMatrix{T},
    method::AbstractString;
    Sensitivity::Real=0.5,
    ForegroundPolarity::AbstractString="bright",
) where {T<:Union{MInteger,MFloat}}
    return _imbinarize_method(I, method, Sensitivity, ForegroundPolarity)
end

function imbinarize(
    I::AbstractMatrix{T};
    method::AbstractString="",
    Sensitivity::Real=0.5,
    ForegroundPolarity::AbstractString="bright",
) where {T<:Union{MInteger,MFloat}}
    return _imbinarize_method(I, method, Sensitivity, ForegroundPolarity)
end

imbinarize(I::Matrix{T}) where {T<:Union{MInteger,MFloat}} = _imbinarize_global(I)

@noinline function _imbinarize_method(I, method, sensitivity, foreground_polarity)
    Base.@nospecialize I
    normalized_method = lowercase(method)
    if isempty(normalized_method) || startswith("global", normalized_method)
        return _imbinarize_global(I)
    elseif startswith("adaptive", normalized_method)
        threshold = adaptthresh(I, sensitivity; ForegroundPolarity=foreground_polarity)
        return ty_binarize(I, threshold)
    end

    throw(ArgumentError("method must match \"global\" or \"adaptive\""))
end

function _imbinarize_global(I)
    return ty_binarize(I, _imbinarize_otsu_threshold(I))
end

# MATLAB 的全局方法使用原生整数类型计算 256 个分箱的直方图。
# 浮点图像会先转换为 UInt8，以确保 NaN（非数值）和 Inf（无穷大）不会参与 Otsu 计算。
function _imbinarize_histogram(I::AbstractMatrix{UInt8})
    counts = zeros(Int, 256)
    @inbounds for value in I
        counts[Int(value) + 1] += 1
    end
    return counts
end

function _imbinarize_histogram(I::AbstractMatrix{UInt16})
    counts = zeros(Int, 256)
    @inbounds for value in I
        bin = div(Int(value) * 255 + 32767, 65535)
        counts[bin + 1] += 1
    end
    return counts
end

function _imbinarize_histogram(I::AbstractMatrix{Int16})
    counts = zeros(Int, 256)
    @inbounds for value in I
        shifted = Int(value) - Int(typemin(Int16))
        bin = div(shifted * 255 + 32767, 65535)
        counts[bin + 1] += 1
    end
    return counts
end

function _imbinarize_histogram(I::AbstractMatrix{<:MFloat})
    counts = zeros(Int, 256)
    @inbounds for value in I
        bin = if isnan(value) || value <= 0
            0
        elseif value >= 1
            255
        else
            floor(Int, Float64(value) * 255 + 0.5)
        end
        counts[bin + 1] += 1
    end
    return counts
end

function _imbinarize_otsu_threshold(I)
    counts = _imbinarize_histogram(I)
    return _imbinarize_otsu_threshold_from_counts(counts)
end

@noinline function _imbinarize_otsu_threshold_from_counts(counts::Vector{Int})
    total = 0
    weighted_total = 0.0
    @inbounds for index in 1:256
        count = counts[index]
        total += count
        weighted_total += index * count
    end
    total == 0 && return 0.0

    max_sigma = -Inf
    max_index_sum = 0
    max_index_count = 0
    cumulative_count = 0
    cumulative_weight = 0.0
    total_float = Float64(total)

    @inbounds for index in 1:256
        count = counts[index]
        cumulative_count += count
        cumulative_weight += index * count

        if cumulative_count == 0 || cumulative_count == total
            continue
        end

        omega = cumulative_count / total_float
        mu = cumulative_weight / total_float
        mu_total = weighted_total / total_float
        sigma = (mu_total * omega - mu)^2 / (omega * (1 - omega))

        if sigma > max_sigma
            max_sigma = sigma
            max_index_sum = index
            max_index_count = 1
        elseif sigma == max_sigma
            max_index_sum += index
            max_index_count += 1
        end
    end
    isfinite(max_sigma) || return 0.0
    return (max_index_sum / max_index_count - 1) / 255
end
