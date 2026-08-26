"""
    imbothat(I, nhood)

对灰度图像或二值图像 `I` 执行形态学底帽滤波。`nhood` 是由 0 和 1
组成的结构元素邻域。返回值与输入图像具有相同的大小和元素类型。
"""
function imbothat(I::Matrix{UInt8}, nh::Matrix{Bool})
    square_diamond_radii = _imtophat_square_diamond_radii(nh)
    square_diamond_radii === nothing && return _imbothat_uint8_mask_general(I, nh)

    square_radius, diamond_radius = square_diamond_radii
    closed = _imbothat_close_square_diamond(I, square_radius, diamond_radius)
    return _imbothat_subtract(closed, I)
end

@noinline function _imbothat_uint8_mask_general(I::Matrix{UInt8}, nh::Matrix{Bool})
    return _julia_imbothat(I, UInt8.(nh))
end

function imbothat(
    I::AbstractMatrix{T}, nh::AbstractArray{T2}
) where {T<:Union{MInteger,MFloat,Bool},T2<:Union{Bool,Integer}}
    if eltype(nh) <: Integer
        if !all(elm -> elm in (0, 1), nh)
            error(
                _msg(
                    @tr(
                        "For function imbothat, nhood input contains values other than 0 or 1."
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    nhd = UInt8.(nh)
    if maximum(nh) > 1
        nhd = UInt8.(imbinarize(nhd))
    end

    if eltype(I) == Bool
        closed = _imbothat_close(UInt8.(I), nhd)
        return (closed .!= 0) .& .!I
    end
    return _julia_imbothat(I, nhd)
end

function imbothat(
    I::AbstractArray{T,3}, nh::AbstractArray{T2}
) where {T<:Union{MInteger,MFloat,Bool},T2<:Union{Bool,Integer}}
    res = zeros(eltype(I), size(I))
    ker = ty_check_morph_3d_kernel(nh)
    for idx in axes(I, 3)
        res[:, :, idx] = imbothat(I[:, :, idx], ker[:, :, idx])
    end
    return res
end

function _julia_imbothat(
    I::AbstractMatrix{T}, nh::AbstractArray{UInt8}
) where {T<:Union{MInteger,MFloat}}
    closed = _imbothat_close(I, nh)
    return _imbothat_subtract(closed, I)
end

function _imbothat_close(I::AbstractMatrix, nh::AbstractArray{UInt8})
    ndims(nh) == 1 && (nh = reshape(nh, 1, :))
    se = nh .!= 0

    square_diamond_radii = _imtophat_square_diamond_radii(se)
    if square_diamond_radii !== nothing
        square_radius, diamond_radius = square_diamond_radii
        return _imbothat_close_square_diamond(I, square_radius, diamond_radius)
    end

    offsets = _imtophat_offsets(se)
    isempty(offsets) && return _imtophat_erode(_imtophat_dilate(I, offsets), offsets)

    min_row, max_row, min_col, max_col = _imbothat_offset_extrema(offsets)
    pad_top = max(0, -min_row)
    pad_bottom = max(0, max_row)
    pad_left = max(0, -min_col)
    pad_right = max(0, max_col)
    padded = _imbothat_pad_low(I, pad_top, pad_bottom, pad_left, pad_right)
    closed = _imtophat_erode(_imtophat_dilate(padded, offsets), offsets)
    return _imbothat_crop(closed, size(I), pad_top, pad_left)
end

function _imbothat_close_square_diamond(
    I::AbstractMatrix, square_radius::Int, diamond_radius::Int
)
    radius = square_radius + diamond_radius
    horizontal_offsets = [(0, offset) for offset in (-square_radius):square_radius]
    vertical_offsets = [(offset, 0) for offset in (-square_radius):square_radius]
    cross_offsets = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]

    closed = _imbothat_pad_low(I, radius, radius, radius, radius)
    if square_radius > 0
        closed = _imtophat_dilate(closed, horizontal_offsets)
        closed = _imtophat_dilate(closed, vertical_offsets)
    end
    for _ in 1:diamond_radius
        closed = _imtophat_dilate(closed, cross_offsets)
    end
    if square_radius > 0
        closed = _imtophat_erode(closed, horizontal_offsets)
        closed = _imtophat_erode(closed, vertical_offsets)
    end
    for _ in 1:diamond_radius
        closed = _imtophat_erode(closed, cross_offsets)
    end
    return _imbothat_crop(closed, size(I), radius, radius)
end

function _imbothat_offset_extrema(offsets::Vector{Tuple{Int,Int}})
    min_row = max_row = offsets[1][1]
    min_col = max_col = offsets[1][2]
    @inbounds for idx in 2:length(offsets)
        row, col = offsets[idx]
        min_row = min(min_row, row)
        max_row = max(max_row, row)
        min_col = min(min_col, col)
        max_col = max(max_col, col)
    end
    return min_row, max_row, min_col, max_col
end

function _imbothat_pad_low(
    I::AbstractMatrix{T}, pad_top::Int, pad_bottom::Int, pad_left::Int, pad_right::Int
) where {T}
    rows, cols = size(I)
    padded = fill(
        _imtophat_low(T), rows + pad_top + pad_bottom, cols + pad_left + pad_right
    )
    copyto!(
        @view(padded[(pad_top + 1):(pad_top + rows), (pad_left + 1):(pad_left + cols)]), I
    )
    return padded
end

function _imbothat_crop(
    closed::AbstractMatrix, input_size::Tuple{Int,Int}, pad_top::Int, pad_left::Int
)
    rows, cols = input_size
    return copy(
        @view closed[(pad_top + 1):(pad_top + rows), (pad_left + 1):(pad_left + cols)]
    )
end

function _imbothat_subtract(
    closed::AbstractMatrix{T}, I::AbstractMatrix{T}
) where {T<:Integer}
    out = similar(I)
    lo = Int(typemin(T))
    hi = Int(typemax(T))
    @inbounds @simd for idx in eachindex(I)
        out[idx] = T(clamp(Int(closed[idx]) - Int(I[idx]), lo, hi))
    end
    return out
end

function _imbothat_subtract(
    closed::AbstractMatrix{T}, I::AbstractMatrix{T}
) where {T<:AbstractFloat}
    return closed .- I
end
