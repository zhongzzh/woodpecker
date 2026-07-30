"""
消除颜色图中的重复颜色；将灰度或真彩色图像转换为索引图像

Y,newmap = cmunique(X,map)
Y,newmap = cmunique(RGB)
Y,newmap = cmunique(I)

输入说明
X: 具有重复颜色的索引图像，指定为 m×n 整数矩阵  Float64 | UInt8 | UInt16
map: 具有重复颜色的颜色图，指定为由范围 [0, 1] 内的值组成的 c1×3 矩阵  Float64
RGB: 非负数组成的 m×n×3 数组
I: 灰度图， Float64 | UInt8 | UInt16


输出说明：
Y: 具有唯一颜色的索引图像，以 m×n 整数矩阵形式返回。如果 newmap 的长度小于或等于 256，则输出图像可以属于 UInt8 类。
   否则，输出图像属于 Float64 类
newmap: 由范围 [0, 1] 内的值组成的 c2×3 矩阵    Float64
"""
function cmunique(src::AbstractMatrix{T}) where {T<:Union{UInt8,UInt16,Float64,Int64}}
    @ccall_check_func_lic :TyImageProcessing
    _check_nonnegative(src)
    x, map = grayToInd(src)
    return get_new_idxarray_map(x, map)
end

function cmunique(src::AbstractArray{T,3}) where {T<:Union{UInt8,UInt16,Float64,Int64}}
    @ccall_check_func_lic :TyImageProcessing
    _check_nonnegative(src)
    size(src, 3) == 3 || _invalid_index_error()
    x, map = rgbToInd(src)
    return get_new_idxarray_map(x, map)
end

function cmunique(
    idx_mtx::AbstractMatrix{T}, map::AbstractMatrix{<:Real}
) where {T<:Union{UInt8,UInt16,Float64,Int64}}
    @ccall_check_func_lic :TyImageProcessing
    size(map, 2) == 3 || _invalid_index_error()
    _check_index_image(idx_mtx, size(map, 1))
    return get_new_idxarray_map(idx_mtx, Float64.(map))
end

function _invalid_index_error()
    return error(
        _msg(
            @tr("Array index must be a positive integer."), splitext(basename(@__FILE__))[1]
        ),
    )
end

function _check_nonnegative(src)
    all(x -> x >= 0, src) || _invalid_index_error()
    return nothing
end

function _check_index_image(idx_mtx, ncolors)
    if eltype(idx_mtx) == Float64
        all(x -> isfinite(x) && x >= 1 && x == round(x) && x <= ncolors, idx_mtx) ||
            _invalid_index_error()
    else
        all(x -> x >= 0 && x < ncolors, idx_mtx) || _invalid_index_error()
    end
    return nothing
end

function get_new_idxarray_map(idx_mtx, rmap)
    ncolors = size(rmap, 1)
    ncolors > 0 || _invalid_index_error()

    res = Float64.(idx_mtx)
    # MATLAB stores integer-class indexed images with zero-based values,
    # whereas double indexed images use one-based values. Convert integer
    # indices before using them to index Julia arrays.
    if eltype(idx_mtx) <: Integer
        res .+= 1
    end

    tol = 1 / 1024
    rmap = @. round(rmap / tol, RoundNearestTiesAway) * tol
    ndx = sortperm(axes(rmap, 1); by=i -> (rmap[i, 3], rmap[i, 2], rmap[i, 1]))
    pos = zeros(Int, ncolors)
    pos[ndx] = 1:ncolors

    duplicate = falses(ncolors - 1)
    for i in eachindex(duplicate)
        duplicate[i] = all(abs.(rmap[ndx[i + 1], :] .- rmap[ndx[i], :]) .< tol)
    end
    loc = collect(1:ncolors) .- vcat(0, cumsum(duplicate))
    res_idx = Int.(res)
    res .= loc[pos[res_idx]]

    keep_sorted = vcat(.!duplicate, true)
    rmap = rmap[ndx[keep_sorted], :]

    used = falses(size(rmap, 1))
    res_idx = Int.(res)
    used[res_idx] .= true
    loc = collect(1:length(used)) .- cumsum(.!used)
    res .= loc[res_idx]
    rmap = rmap[used, :]

    # A UInt8 indexed image can represent only the 256 zero-based indices
    # 0:255.  Decide from the retained colormap size, not from a one-based
    # intermediate index (whose largest value is 256 for a 256-color map).
    if size(rmap, 1) <= 256
        return UInt8.(res .- 1), rmap
    end
    return Float64.(res), rmap
end

function rgbToInd(rgb)
    m, n = size(rgb, 1), size(rgb, 2)
    map = im2doubleLocal(reshape(rgb, m * n, 3))
    return Float64.(reshape(1:(m * n), m, n)), map
end

function grayToInd(gray)
    m, n = size(gray)
    map = im2doubleLocal(repeat(gray[:], 1, 3))
    return Float64.(reshape(1:(m * n), m, n)), map
end

function im2doubleLocal(img)
    tp = eltype(img)
    if tp == UInt8 || tp == UInt16
        return Float64.(img) ./ typemax(tp)
    elseif tp == Float32
        return Float64.(img)
    end
    return img
end
