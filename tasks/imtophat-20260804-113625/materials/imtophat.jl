"""
对图像执行形态学顶帽滤波运算
J = imtophat(I,SE)
I:输入图像，指定为灰度图像，二值图像  Float32 | Float64 | UInt8 | UInt16 | Int16
J:顶帽滤波后图像，与I数据类型相同
"""
function imtophat(
    I::AbstractMatrix{T}, nh::AbstractArray{T2}
) where {T<:Union{MInteger,MFloat,Bool},T2<:Union{Bool,Integer}}
    # if size(se,1)>= size(I,1) || size(se,2)>= size(I,2)
    #     error(_msg("结构元素尺寸不能大于被顶帽滤波图像尺寸", splitext(basename(@__FILE__))[1]))
    # end
    if eltype(nh) <: Integer
        if !all(elm -> elm in [0, 1], nh)
            error(
                _msg(
                    @tr(
                        "For function imtophat, nhood input contains values other than 0 or 1."
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end
    nhd = UInt8.(nh)
    if maximum(nh) > 1
        nhd = imbinarize(nhd)
        nhd = UInt8.(nhd)
    end
    nI = copy(I)
    if eltype(I) == Bool
        nI = UInt8.(I)
        res = _julia_imtophat(nI, nhd)
        res = res .!= 0
        return res
    end
    return _julia_imtophat(I, nhd)
end

function imtophat(
    I::AbstractArray{T,3}, nh::AbstractArray{T2}
) where {T<:Union{MInteger,MFloat,Bool},T2<:Union{Bool,Integer}}
    res = zeros(eltype(I), size(I))
    ker = ty_check_morph_3d_kernel(nh)
    for idx in eachindex(1:size(I, 3))
        res[:, :, idx] = imtophat(I[:, :, idx], ker[:, :, idx])
    end

    return res
end

function _julia_imtophat(
    I::AbstractMatrix{T}, nh::AbstractArray{UInt8}
) where {T<:Union{MInteger,MFloat}}
    if typeof(nh) <: AbstractVector
        nh = transpose(nh)
    end
    se = nh .!= 0
    square_diamond_radii = _imtophat_square_diamond_radii(se)
    if square_diamond_radii !== nothing
        square_radius, diamond_radius = square_diamond_radii
        opened = _imtophat_open_square_diamond(I, square_radius, diamond_radius)
        return _imtophat_subtract(I, opened)
    end
    offsets = _imtophat_offsets(se)
    opened = _imtophat_dilate(_imtophat_erode(I, offsets), offsets)
    return _imtophat_subtract(I, opened)
end

function _imtophat_square_diamond_radii(se::AbstractMatrix{Bool})
    rows, cols = size(se)
    rows == cols && isodd(rows) || return nothing
    radius = div(rows, 2)
    center = radius + 1

    for square_radius in 0:radius
        matches = true
        @inbounds for col in 1:cols, row in 1:rows
            row_distance = abs(row - center)
            half_width = radius - max(row_distance - square_radius, 0)
            expected = abs(col - center) <= half_width
            if se[row, col] != expected
                matches = false
                break
            end
        end
        matches && return (square_radius, radius - square_radius)
    end
    return nothing
end

function _imtophat_open_square_diamond(
    I::AbstractMatrix, square_radius::Int, diamond_radius::Int
)
    horizontal_offsets = [(0, offset) for offset in (-square_radius):square_radius]
    vertical_offsets = [(offset, 0) for offset in (-square_radius):square_radius]
    cross_offsets = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]

    opened = I
    if square_radius > 0
        opened = _imtophat_erode(opened, horizontal_offsets)
        opened = _imtophat_erode(opened, vertical_offsets)
    end
    for _ in 1:diamond_radius
        opened = _imtophat_erode(opened, cross_offsets)
    end
    if square_radius > 0
        opened = _imtophat_dilate(opened, horizontal_offsets)
        opened = _imtophat_dilate(opened, vertical_offsets)
    end
    for _ in 1:diamond_radius
        opened = _imtophat_dilate(opened, cross_offsets)
    end
    return opened
end

function _imtophat_erode(I::AbstractMatrix{T}, offsets::Vector{Tuple{Int,Int}}) where {T}
    rows, cols = size(I)
    isempty(offsets) && return fill(_imtophat_high(T), rows, cols)
    out = Matrix{T}(undef, rows, cols)
    fill!(out, _imtophat_high(T))

    # MATLAB erosion samples I[row + drow, col + dcol].  Updating a whole
    # overlapping column at a time keeps the innermost loop contiguous and
    # lets LLVM vectorize it for large images.
    @inbounds for (drow, dcol) in offsets
        first_row = max(1, 1 - drow)
        last_row = min(rows, rows - drow)
        first_col = max(1, 1 - dcol)
        last_col = min(cols, cols - dcol)
        for col in first_col:last_col
            source_col = col + dcol
            @simd ivdep for row in first_row:last_row
                out[row, col] = min(out[row, col], I[row + drow, source_col])
            end
        end
    end

    return out
end

function _imtophat_dilate(I::AbstractMatrix{T}, offsets::Vector{Tuple{Int,Int}}) where {T}
    rows, cols = size(I)
    isempty(offsets) && return fill(_imtophat_low(T), rows, cols)
    out = Matrix{T}(undef, rows, cols)
    fill!(out, _imtophat_low(T))

    # Dilation uses the reflected structuring element.  This is observable
    # for asymmetric neighborhoods and is required for MATLAB-compatible
    # opening (erosion followed by dilation).
    @inbounds for (offset_row, offset_col) in offsets
        drow = -offset_row
        dcol = -offset_col
        first_row = max(1, 1 - drow)
        last_row = min(rows, rows - drow)
        first_col = max(1, 1 - dcol)
        last_col = min(cols, cols - dcol)
        for col in first_col:last_col
            source_col = col + dcol
            @simd ivdep for row in first_row:last_row
                out[row, col] = max(out[row, col], I[row + drow, source_col])
            end
        end
    end

    return out
end

_imtophat_high(::Type{T}) where {T<:Integer} = typemax(T)
_imtophat_high(::Type{T}) where {T<:AbstractFloat} = T(Inf)
_imtophat_low(::Type{T}) where {T<:Integer} = typemin(T)
_imtophat_low(::Type{T}) where {T<:AbstractFloat} = T(-Inf)

function _imtophat_offsets(se::AbstractMatrix{Bool})
    krows, kcols = size(se)
    anchor_i = fld(krows + 1, 2)
    anchor_j = fld(kcols + 1, 2)
    offsets = Vector{Tuple{Int,Int}}()
    for j in 1:kcols, i in 1:krows
        se[i, j] && push!(offsets, (i - anchor_i, j - anchor_j))
    end
    return offsets
end

function _imtophat_subtract(
    I::AbstractMatrix{T}, opened::AbstractMatrix{T}
) where {T<:Integer}
    out = similar(I)
    lo = Int(typemin(T))
    hi = Int(typemax(T))
    @inbounds for idx in eachindex(I)
        out[idx] = T(clamp(Int(I[idx]) - Int(opened[idx]), lo, hi))
    end
    return out
end

function _imtophat_subtract(
    I::AbstractMatrix{T}, opened::AbstractMatrix{T}
) where {T<:AbstractFloat}
    return I .- opened
end

precompile(imtophat, (Matrix{UInt8}, BitMatrix))
precompile(_julia_imtophat, (Matrix{UInt8}, Matrix{UInt8}))
