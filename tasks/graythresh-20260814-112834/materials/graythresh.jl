"""
    graythresh(I)

使用 Otsu 方法计算全局图像阈值。输入 `I` 可以是 `UInt8`、`UInt16`、
`Int16`、`Float32` 或 `Float64` 数组。返回值是位于 `[0, 1]` 范围内的
`Float64` 标量，可作为 `imbinarize` 的阈值。
"""
function graythresh(src::AbstractArray{T}) where {T<:Union{MInteger,MFloat}}
    isempty(src) && return 0.0

    # MATLAB graythresh first converts the flattened input with im2uint8 and
    # then computes a 256-bin histogram.  Counting UInt8 values directly is
    # both equivalent and considerably cheaper than the generic imhist path.
    u8im = im2uint8(src)
    counts = zeros(Int, 256)
    @inbounds for value in u8im
        counts[Int(value) + 1] += 1
    end

    return _graythresh_otsu(counts, length(u8im))
end

function graythresh(src::Matrix{UInt8})

    # 如果是uint8 就不需要走14行的u8im = im2uint8(src)了
    # 此处为uint8专设一个路径
    isempty(src) && return 0.0

    counts = zeros(Int, 256)
    @inbounds for value in src
        counts[Int(value) + 1] += 1
    end

    return _graythresh_otsu(counts, length(src))
end

function _graythresh_otsu(counts::Vector{Int}, num_pixels::Int)
    # Match MATLAB otsuthresh's Float64 probability accumulation order.
    mu_t = 0.0
    @inbounds for i in eachindex(counts)
        mu_t += (counts[i] / num_pixels) * i
    end

    omega = 0.0
    mu = 0.0
    max_sigma = -Inf
    max_index_sum = 0.0
    max_index_count = 0

    @inbounds for i in eachindex(counts)
        probability = counts[i] / num_pixels
        omega += probability
        mu += probability * i

        denominator = omega * (1.0 - omega)
        sigma = (mu_t * omega - mu)^2 / denominator

        # Comparisons with NaN are false, which reproduces MATLAB max's
        # treatment of the undefined bins at the ends of the histogram.
        if sigma > max_sigma
            max_sigma = sigma
            max_index_sum = i
            max_index_count = 1
        elseif sigma == max_sigma
            max_index_sum += i
            max_index_count += 1
        end
    end

    isfinite(max_sigma) || return 0.0
    index = max_index_sum / max_index_count
    return Float64((index - 1.0) / 255.0)
end
