"""
   img = imresize(src,[rows,cols])
   img = imresize(src,0.7)
   img = imresize(src,1.2;method = "nearest")

对图像进行缩放拉伸
"""
function im_resize end
const imresize = im_resize

function im_resize(
    img::AbstractArray{T}, sc::Real; method::AbstractString="bicubic"
) where {T<:Union{MInteger,MFloat,Bool}}
    sc > 0 || error(
        _msg(@tr("Scale factor must be greater than 0."), splitext(basename(@__FILE__))[1]),
    )
    height = ceil(Int, size(img, 1) * sc)
    width = ceil(Int, size(img, 2) * sc)
    return _julia_resize(img, height, width, method, Float64(sc), Float64(sc))
end

function im_resize(
    img::AbstractArray{T}, sc::Real, method::AbstractString
) where {T<:Union{MInteger,MFloat,Bool}}
    return im_resize(img, sc; method=method)
end

function im_resize(
    img::AbstractArray{T}, sz::Matrix{<:Real}; method::AbstractString="bicubic"
) where {T<:Union{MInteger,MFloat,Bool}}
    length(sz) == 2 || error(
        _msg(@tr("Size argument must have length 2."), splitext(basename(@__FILE__))[1])
    )
    vec_s = vec(sz)

    if isnan(vec_s[1]) && isnan(vec_s[2])
        error(
            _msg(
                @tr("Size arguments cannot both be NaN."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    sr, sc = vec_s
    aspect_dimension = isnan(sr) ? 2 : (isnan(sc) ? 1 : 0)
    ri, ci = size(img)
    if isnan(sr)
        sr = Float64(ri * sc / ci)
    end

    if isnan(sc)
        sc = Float64(ci * sr / ri)
    end

    sr, sc = ceil(Int, sr), ceil(Int, sc)
    (sr > 0 && sc > 0) || error(
        _msg(
            @tr("Both size arguments must be greater than 0."),
            splitext(basename(@__FILE__))[1],
        ),
    )
    if aspect_dimension == 1
        scale = sr / ri
        return _julia_resize(img, sr, sc, method, scale, scale)
    elseif aspect_dimension == 2
        scale = sc / ci
        return _julia_resize(img, sr, sc, method, scale, scale)
    end
    return _julia_resize(img, sr, sc, method)
end

function im_resize(
    img::AbstractArray{T}, sz::Matrix{<:Real}, method::AbstractString
) where {T<:Union{MInteger,MFloat,Bool}}
    return im_resize(img, sz; method=method)
end

function im_resize(
    img::AbstractArray{T}, sz::Vector{Int}; method::AbstractString="bicubic"
) where {T<:Union{MInteger,MFloat,Bool}}
    length(sz) == 2 || error(
        _msg(@tr("Size argument must have length 2."), splitext(basename(@__FILE__))[1])
    )

    if isnan(sz[1]) && isnan(sz[2])
        error(
            _msg(
                @tr("Size arguments cannot both be NaN."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    sr, sc = sz
    aspect_dimension = isnan(sr) ? 2 : (isnan(sc) ? 1 : 0)
    ri, ci = size(img)
    if isnan(sr)
        sr = Float64(ri * sc / ci)
    end

    if isnan(sc)
        sc = Float64(ci * sr / ri)
    end

    sr, sc = ceil(Int, sr), ceil(Int, sc)
    (sr > 0 && sc > 0) || error(
        _msg(
            @tr("Both size arguments must be greater than 0."),
            splitext(basename(@__FILE__))[1],
        ),
    )
    if aspect_dimension == 1
        scale = sr / ri
        return _julia_resize(img, sr, sc, method, scale, scale)
    elseif aspect_dimension == 2
        scale = sc / ci
        return _julia_resize(img, sr, sc, method, scale, scale)
    end
    return _julia_resize(img, sr, sc, method)
end

function im_resize(
    img::AbstractArray{T}, sz::Vector{Int}, method::AbstractString
) where {T<:Union{MInteger,MFloat,Bool}}
    return im_resize(img, sz; method=method)
end

function im_resize(
    img::AbstractArray{T}, sz::Vector{Float64}; method::AbstractString="bicubic"
) where {T<:Union{MInteger,MFloat,Bool}}
    length(sz) == 2 || error(
        _msg(@tr("Size argument must have length 2."), splitext(basename(@__FILE__))[1])
    )

    if isnan(sz[1]) && isnan(sz[2])
        error(
            _msg(
                @tr("Size arguments cannot both be NaN."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    sr, sc = sz
    aspect_dimension = isnan(sr) ? 2 : (isnan(sc) ? 1 : 0)
    ri, ci = size(img)
    if isnan(sr)
        sr = Float64(ri * sc / ci)
    end

    if isnan(sc)
        sc = Float64(ci * sr / ri)
    end

    sr, sc = ceil(Int, sr), ceil(Int, sc)
    (sr > 0 && sc > 0) || error(
        _msg(
            @tr("Both size arguments must be greater than 0."),
            splitext(basename(@__FILE__))[1],
        ),
    )
    if aspect_dimension == 1
        scale = sr / ri
        return _julia_resize(img, sr, sc, method, scale, scale)
    elseif aspect_dimension == 2
        scale = sc / ci
        return _julia_resize(img, sr, sc, method, scale, scale)
    end
    return _julia_resize(img, sr, sc, method)
end

function im_resize(
    img::AbstractArray{T}, sz::Vector{Float64}, method::AbstractString
) where {T<:Union{MInteger,MFloat,Bool}}
    return im_resize(img, sz; method=method)
end

function im_resize(
    X::AbstractMatrix{T},
    map::AbstractMatrix{Float64},
    sc::Real;
    nargout::Int64=1,
    method::AbstractString="nearest",
) where {T<:Union{MInteger,MFloat,Bool}}
    Y = _julia_resize(X, ceil(Int, size(X, 1) * sc), ceil(Int, size(X, 2) * sc), method)
    return nargout == 1 ? Y : (Y, map)
end

function _julia_resize(
    img::AbstractArray,
    height::Int,
    width::Int,
    method::AbstractString,
    scale_y::Float64=height / size(img, 1),
    scale_x::Float64=width / size(img, 2),
)
    @ccall_check_func_lic :TyImageProcessing
    method_str = ("area", "bilinear", "nearest", "lanczos", "bicubic")
    if !(method in method_str)
        info_str = @tr(
            "Supported interpolation methods for resize are:\n bicubic - bicubic interpolation (default),\n area - area interpolation,\n bilinear - bilinear interpolation,\n nearest - nearest-neighbor interpolation,\n lanczos - Lanczos interpolation.",
        )
        error(
            _msg(
                @tr("resize does not support method \"%{1}\".\n%{2}", method, info_str),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    kernel, kernel_width, antialiasing = if method == "nearest"
        (_resize_box, 1.0, false)
    elseif method == "area"
        (_resize_box, 1.0, true)
    elseif method == "bilinear"
        (_resize_triangle, 2.0, true)
    elseif method == "bicubic"
        (_resize_cubic, 4.0, true)
    else
        (_resize_lanczos4, 8.0, true)
    end

    source = eltype(img) == Bool ? UInt8.(img) .* 0xff : img
    if method == "bicubic" &&
        eltype(source) == UInt8 &&
        scale_y == 0.5 &&
        scale_x == 0.5 &&
        height == ceil(Int, size(source, 1) / 2) &&
        width == ceil(Int, size(source, 2) / 2)
        resized = _resize_bicubic_half_uint8(source)
        return eltype(img) == Bool ? resized .> 128 : resized
    end

    weights_y, indices_y = _resize_contributions(
        size(source, 1), height, scale_y, kernel, kernel_width, antialiasing
    )
    weights_x, indices_x = _resize_contributions(
        size(source, 2), width, scale_x, kernel, kernel_width, antialiasing
    )

    resized = if scale_y <= scale_x
        tmp = _resize_along_dim(source, 1, weights_y, indices_y)
        _resize_along_dim(tmp, 2, weights_x, indices_x)
    else
        tmp = _resize_along_dim(source, 2, weights_x, indices_x)
        _resize_along_dim(tmp, 1, weights_y, indices_y)
    end
    return eltype(img) == Bool ? resized .> 128 : resized
end

function _resize_bicubic_half_uint8(img::AbstractArray{UInt8})
    input_height, input_width = size(img, 1), size(img, 2)
    planes = length(img) ÷ (input_height * input_width)
    source = reshape(Int32.(img), input_height, input_width, planes)
    half_height = ceil(Int, input_height / 2)
    half_width = ceil(Int, input_width / 2)

    vertical_raw = Array{Int32}(undef, half_height, input_width, planes)
    first_interior_row = 3
    last_interior_row = min(half_height, fld(input_height - 3, 2))
    @inbounds for plane in 1:planes, column in 1:input_width
        for row in 1:min(first_interior_row - 1, half_height)
            first_index = 2 * row - 4
            value = _resize_bicubic_half_sum_dim1_boundary(
                source, first_index, column, plane, input_height
            )
            vertical_raw[row, column, plane] = Int32(value)
        end
        @inbounds @simd ivdep for row in first_interior_row:last_interior_row
            first_index = 2 * row - 4
            vertical_raw[row, column, plane] =
                -Int32(3) * (
                    source[first_index, column, plane] +
                    source[first_index + 7, column, plane]
                ) -
                Int32(9) * (
                    source[first_index + 1, column, plane] +
                    source[first_index + 6, column, plane]
                ) +
                Int32(29) * (
                    source[first_index + 2, column, plane] +
                    source[first_index + 5, column, plane]
                ) +
                Int32(111) * (
                    source[first_index + 3, column, plane] +
                    source[first_index + 4, column, plane]
                )
        end
        for row in max(last_interior_row + 1, first_interior_row):half_height
            first_index = 2 * row - 4
            value = _resize_bicubic_half_sum_dim1_boundary(
                source, first_index, column, plane, input_height
            )
            vertical_raw[row, column, plane] = Int32(value)
        end
    end

    vertical = similar(vertical_raw)
    @inbounds @simd ivdep for index in eachindex(vertical, vertical_raw)
        value = vertical_raw[index]
        vertical[index] = max(min((value + Int32(128)) >> 8, Int32(255)), Int32(0))
    end

    output_raw = Array{Int32}(undef, half_height, half_width, planes)
    @inbounds for plane in 1:planes, column in 1:half_width
        first_index = 2 * column - 4
        if first_index >= 1 && first_index + 7 <= input_width
            @inbounds @simd ivdep for row in 1:half_height
                output_raw[row, column, plane] =
                    -Int32(3) * (
                        vertical[row, first_index, plane] +
                        vertical[row, first_index + 7, plane]
                    ) -
                    Int32(9) * (
                        vertical[row, first_index + 1, plane] +
                        vertical[row, first_index + 6, plane]
                    ) +
                    Int32(29) * (
                        vertical[row, first_index + 2, plane] +
                        vertical[row, first_index + 5, plane]
                    ) +
                    Int32(111) * (
                        vertical[row, first_index + 3, plane] +
                        vertical[row, first_index + 4, plane]
                    )
            end
        else
            for row in 1:half_height
                value = _resize_bicubic_half_sum_dim2_boundary(
                    vertical, row, first_index, plane, input_width
                )
                output_raw[row, column, plane] = Int32(value)
            end
        end
    end
    output = Array{UInt8}(undef, half_height, half_width, planes)
    @inbounds @simd ivdep for index in eachindex(output, output_raw)
        output[index] = _resize_bicubic_half_cast(output_raw[index])
    end

    return reshape(output, half_height, half_width, size(img)[3:end]...)
end

@inline function _resize_bicubic_half_sum_dim1(source, index, column, plane)
    return -3 *
           (Int(source[index, column, plane]) + Int(source[index + 7, column, plane])) -
           9 *
           (Int(source[index + 1, column, plane]) + Int(source[index + 6, column, plane])) +
           29 *
           (Int(source[index + 2, column, plane]) + Int(source[index + 5, column, plane])) +
           111 *
           (Int(source[index + 3, column, plane]) + Int(source[index + 4, column, plane]))
end

@inline function _resize_bicubic_half_sum_dim1_boundary(
    source, index, column, plane, input_length
)
    return -3 * (
               Int(source[_resize_reflect_index(index, input_length), column, plane]) +
               Int(source[_resize_reflect_index(index + 7, input_length), column, plane])
           ) -
           9 * (
               Int(source[_resize_reflect_index(index + 1, input_length), column, plane]) +
               Int(source[_resize_reflect_index(index + 6, input_length), column, plane])
           ) +
           29 * (
               Int(source[_resize_reflect_index(index + 2, input_length), column, plane]) +
               Int(source[_resize_reflect_index(index + 5, input_length), column, plane])
           ) +
           111 * (
               Int(source[_resize_reflect_index(index + 3, input_length), column, plane]) +
               Int(source[_resize_reflect_index(index + 4, input_length), column, plane])
           )
end

@inline function _resize_bicubic_half_sum_dim2(source, row, index, plane)
    return -3 * (Int(source[row, index, plane]) + Int(source[row, index + 7, plane])) -
           9 * (Int(source[row, index + 1, plane]) + Int(source[row, index + 6, plane])) +
           29 * (Int(source[row, index + 2, plane]) + Int(source[row, index + 5, plane])) +
           111 * (Int(source[row, index + 3, plane]) + Int(source[row, index + 4, plane]))
end

@inline function _resize_bicubic_half_sum_dim2_boundary(
    source, row, index, plane, input_length
)
    return -3 * (
               Int(source[row, _resize_reflect_index(index, input_length), plane]) +
               Int(source[row, _resize_reflect_index(index + 7, input_length), plane])
           ) -
           9 * (
               Int(source[row, _resize_reflect_index(index + 1, input_length), plane]) +
               Int(source[row, _resize_reflect_index(index + 6, input_length), plane])
           ) +
           29 * (
               Int(source[row, _resize_reflect_index(index + 2, input_length), plane]) +
               Int(source[row, _resize_reflect_index(index + 5, input_length), plane])
           ) +
           111 * (
               Int(source[row, _resize_reflect_index(index + 3, input_length), plane]) +
               Int(source[row, _resize_reflect_index(index + 4, input_length), plane])
           )
end

@inline function _resize_bicubic_half_cast(value::Int32)
    rounded = if value >= 0
        (value + Int32(128)) >> 8
    else
        -((-value + Int32(128)) >> 8)
    end
    return Base.unsafe_trunc(UInt8, clamp(rounded, Int32(0), Int32(255)))
end

@inline _resize_box(x::Float64) = (-0.5 <= x < 0.5) ? 1.0 : 0.0
@inline function _resize_triangle(x::Float64)
    return (-1.0 <= x < 0.0) ? x + 1.0 : ((0.0 <= x <= 1.0) ? 1.0 - x : 0.0)
end

@inline function _resize_cubic(x::Float64)
    ax = abs(x)
    if ax <= 1.0
        return 1.5 * ax^3 - 2.5 * ax^2 + 1.0
    elseif ax <= 2.0
        return -0.5 * ax^3 + 2.5 * ax^2 - 4.0 * ax + 2.0
    end
    return 0.0
end

@inline function _resize_lanczos4(x::Float64)
    ax = abs(x)
    ax >= 4.0 && return 0.0
    ax < eps(Float64) && return 1.0
    return sinpi(x) * sinpi(x / 4.0) / (pi^2 * x^2 / 4.0)
end

function _resize_contributions(
    input_length::Int,
    output_length::Int,
    scale::Float64,
    kernel::F,
    kernel_width::Float64,
    antialiasing::Bool,
) where {F}
    use_antialiasing = scale < 1.0 && antialiasing
    effective_width = use_antialiasing ? kernel_width / scale : kernel_width
    tap_count = ceil(Int, effective_width) + 2
    weights = Matrix{Float64}(undef, tap_count, output_length)
    indices = Matrix{Int}(undef, tap_count, output_length)

    @inbounds for out_idx in 1:output_length
        input_coordinate = out_idx / scale + 0.5 * (1.0 - 1.0 / scale)
        left = floor(Int, input_coordinate - effective_width / 2.0)
        weight_sum = 0.0
        for tap in 1:tap_count
            source_idx = left + tap - 1
            distance = input_coordinate - source_idx
            weight = use_antialiasing ? scale * kernel(scale * distance) : kernel(distance)
            indices[tap, out_idx] = _resize_reflect_index(source_idx, input_length)
            weights[tap, out_idx] = weight
            weight_sum += weight
        end
        for tap in 1:tap_count
            weights[tap, out_idx] /= weight_sum
        end
    end

    nonzero_rows = vec(any(x -> !iszero(x), weights; dims=2))
    return weights[nonzero_rows, :], indices[nonzero_rows, :]
end

@inline function _resize_reflect_index(index::Int, input_length::Int)
    position = mod(index - 1, 2 * input_length) + 1
    return position <= input_length ? position : 2 * input_length - position + 1
end

function _resize_along_dim(
    img::AbstractArray{T}, dim::Int, weights::Matrix{Float64}, indices::Matrix{Int}
) where {T}
    input_height, input_width = size(img, 1), size(img, 2)
    planes = prod(size(img)[3:end]; init=1)
    source = reshape(img, input_height, input_width, planes)
    tap_count, output_length = size(weights)

    if dim == 1
        output = Array{T}(undef, output_length, input_width, planes)
        @inbounds for plane in 1:planes, column in 1:input_width, row in 1:output_length
            value = 0.0
            @simd for tap in 1:tap_count
                value +=
                    weights[tap, row] * Float64(source[indices[tap, row], column, plane])
            end
            output[row, column, plane] = _resize_cast(T, value)
        end
        output_shape = (output_length, input_width, size(img)[3:end]...)
    else
        output = Array{T}(undef, input_height, output_length, planes)
        @inbounds for plane in 1:planes, column in 1:output_length, row in 1:input_height
            value = 0.0
            @simd for tap in 1:tap_count
                value +=
                    weights[tap, column] * Float64(source[row, indices[tap, column], plane])
            end
            output[row, column, plane] = _resize_cast(T, value)
        end
        output_shape = (input_height, output_length, size(img)[3:end]...)
    end
    return reshape(output, output_shape)
end

@inline function _resize_cast(::Type{UInt8}, value::Float64)
    return Base.unsafe_trunc(UInt8, clamp(trunc(Int, value + 0.5), 0, 255))
end

@inline function _resize_cast(::Type{T}, value::Float64) where {T<:Integer}
    rounded = round(Int, value, RoundNearestTiesAway)
    return T(clamp(rounded, Int(typemin(T)), Int(typemax(T))))
end

@inline _resize_cast(::Type{T}, value::Float64) where {T<:AbstractFloat} = T(value)

precompile(im_resize, (Array{UInt8,3}, Float64))
precompile(_julia_resize, (Array{UInt8,3}, Int, Int, String, Float64, Float64))
precompile(_resize_bicubic_half_uint8, (Array{UInt8,3},))

# """
# imresize - 调整图像大小

# B = imresize(A,scale)

# B = imresize(A,[numrows numcols])

# Y,newmap = imresize(X,map,___)

# ___ = imresize(___,method)

# ___ = imresize(___;Name=Value)
# """
# function imresize(
#     In...;
#     nargout::Int64=1,
#     Antialiasing=nothing,
#     Colormap=nothing,
#     Dither=nothing,
#     Method=nothing,
#     OutputSize=nothing,
#     Scale=nothing,
#     method=nothing,
# )
#     @ccall_check_func_lic :TyImageProcessing
#     if length(In) < 1
#         error("输入参数的数目不足。", splitext(basename(@__FILE__))[1]))
#     elseif length(In) > 3
#         error(_msg("输入参数太多。", splitext(basename(@__FILE__))[1]))
#     end
#     varargin = []
#     push!(varargin, collect(In)...)

#     if !TyBaseCore.isnothing(Antialiasing)
#         push!(varargin, "Antialiasing", Antialiasing)
#     end
#     if !TyBaseCore.isnothing(Colormap)
#         push!(varargin, "Colormap", Colormap)
#     end
#     if !TyBaseCore.isnothing(Dither)
#         push!(varargin, "Dither", Dither)
#     end
#     if !TyBaseCore.isnothing(method)
#         push!(varargin, "Method", method)
#     else
#         if !TyBaseCore.isnothing(Method)
#             push!(varargin, "Method", Method)
#         end
#     end
#     if !TyBaseCore.isnothing(OutputSize)
#         push!(varargin, "OutputSize", OutputSize)
#     end
#     if !TyBaseCore.isnothing(Scale)
#         push!(varargin, "Scale", Scale)
#     end

#     varargin = Tuple(varargin)

#     return internal_imresize(varargin; nargout=nargout)
# end

# function internal_imresize(varargin; nargout=1)
#     args = varargin

#     params = images_internal_resize_resizeParseInputs(args)

#     images_internal_resize_checkForMissingOutputArgument(params, nargout)

#     A = images_internal_resize_preprocessImage(params)

#     order = images_internal_resize_dimensionOrder(params["scale"])

#     weights = Matrix{Union{Function,AbstractArray,Nothing}}(nothing, 1, params["num_dims"])
#     indices = Matrix{Union{Function,AbstractArray,Nothing}}(nothing, 1, params["num_dims"])
#     allDimNearestNeighbor = true
#     for k in 1:params["num_dims"]
#         weights[k], indices[k] = images_internal_resize_contributions(
#             size(A, k),
#             params["output_size"][k],
#             params["scale"][k],
#             params["kernel"],
#             params["kernel_width"],
#             params["antialiasing"],
#         )
#         if !images_internal_resize_isPureNearestNeighborComputation(weights[k])
#             allDimNearestNeighbor = false
#         end
#     end

#     if allDimNearestNeighbor
#         B = images_internal_resize_resizeAllDimUsingNearestNeighbor(A, indices)
#     else
#         B = A
#         for k in 1:length(order)
#             dim = order[k]
#             B = imresize_resizeAlongDim(B, dim, weights[dim], indices[dim])
#         end
#     end

#     B, map = images_internal_resize_postprocessImage(B, params)

#     if nargout == 1
#         return B
#     end
#     return B, map
# end

# function imresize_resizeAlongDim(In, dim, weights, indices)
#     if images_internal_resize_isPureNearestNeighborComputation(weights)
#         out = images_internal_resize_resizeAlongDimUsingNearestNeighbor(In, dim, indices)
#         return out
#     end

#     out_length = size(weights, 1)

#     size_in = collect(size(In))
#     if length(size_in) < dim
#         for i in dim - length(size_in)
#             size_in = [size_in 1]
#         end
#     end

#     if (ndims(In) > 3)
#         pseudo_size_in = [size_in[1:2] prod(size_in[3:end])]
#         In = reshape(In, pseudo_size_in...)
#     end

#     out = images_internal_resize_imresizemex(In, weights', indices', dim)

#     if ((maximum(size(size_in)) > 3) && (size_in[end] > 1))
#         size_out = size_in
#         size_out[dim] = out_length
#         out = reshape(out, size_out...)
#     end

#     return out
# end

# function images_internal_resize_resizeParseInputs(varargin)
#     params = Dict()

#     params["kernel"] = images_internal_resize_cubic
#     params["kernel_width"] = 4
#     params["antialiasing"] = Float64[]
#     params["colormap_method"] = "optimized"
#     params["dither_option"] = "dither"
#     params["num_dims"] = 2
#     params["size_dim"] = Float64[]

#     method_arg_idx = imresize_findMethodArg(varargin)

#     first_param_string_idx = images_internal_resize_findFirstParamString(
#         varargin, method_arg_idx
#     )

#     if !TyBaseCore.isempty(first_param_string_idx)
#         first_param_string_idx = first_param_string_idx[1]
#     end

#     params["A"], params["inputCategories"], params["map"], params["scale"], params["output_size"] = imresize_parsePreMethodArgs(
#         varargin, method_arg_idx, first_param_string_idx
#     )

#     if !TyBaseCore.isempty(method_arg_idx)
#         params["kernel"], params["kernel_width"], params["antialiasing"] = imresize_parseMethodArg(
#             varargin[method_arg_idx]
#         )
#     end

#     warnIfPostMethodArgs(varargin, method_arg_idx, first_param_string_idx)

#     params = imresize_parseParamValuePairs(params, varargin, first_param_string_idx)

#     params = imresize_fixupSizeAndScale(params)

#     if TyBaseCore.isempty(params["antialiasing"])
#         params["antialiasing"] = true
#     end

#     return params
# end

# function imresize_parsePreMethodArgs(args, method_arg_idx, first_param_idx)
#     if !TyBaseCore.isempty(method_arg_idx)
#         args = args[1:(method_arg_idx - 1)]
#     elseif !TyBaseCore.isempty(first_param_idx)
#         args = args[1:(first_param_idx - 1)]
#     end

#     if length(args) < 1
#         error(_msg("输入语法无效；参数列表中缺少输入图像。", splitext(basename(@__FILE__))[1]))
#     end

#     map = Float64[]
#     scale = Float64[]
#     output_size = Float64[]
#     inputCategories = Float64[]

#     A = args[1]

#     if eltype(A) ∉ [Float32, Float64, Int8, Int16, Int32, UInt8, UInt16, UInt32, Bool]
#         error(
#             "第 1 个输入, A, 应为以下类型之一:\n\nFloat32, Float64, Int8, Int16, Int32, UInt8, UInt16, UInt32, Bool\n\n但其类型为 $(eltype(A))。",
#         )
#     end
#     if TyBaseCore.isempty(A)
#         error(_msg("第 1 个输入, A, 应为 非空。", splitext(basename(@__FILE__))[1]))
#     end

#     if length(args) < 2
#         return A, inputCategories, map, scale, output_size
#     end

#     next_arg = 2
#     if size(args[next_arg], 2) == 3
#         # IMRESIZE(X,MAP,...)
#         map = args[next_arg]

#         try
#             iptcheckmap(map, "imresize", "MAP", 2)
#         catch ME
#             if isequal(size(map), (1, 3)) && TyBaseCore.strcmp(
#                 ME.msg, "函数 imresize 要求第 2 个输入 MAP 应为有效的颜色图。有效的颜色图不能包含超出 [0,1] 范围的值。"
#             )
#                 error(
#                     "当第二个参数是 1×3 向量时，IMRESIZE 将其解释为 M×3 颜色图。如果您打算指定输出大小，请使以下语法: imresize(A,___;OutputSize=SZ)，其中 SZ 是 1×2 向量。",
#                 )
#             else
#                 error(ME.msg)
#             end
#         end
#         next_arg = next_arg + 1
#     end

#     if next_arg > length(args)
#         return A, inputCategories, map, scale, output_size
#     end

#     next = args[next_arg]

#     scale, output_size = imresize_scaleOrSize(next, next_arg)
#     next_arg = next_arg + 1

#     if next_arg <= length(args)
#         error(_msg("输入语法无效；编号为 $(next_arg) 的输入参数无法识别", splitext(basename(@__FILE__))[1]))
#     end

#     return A, inputCategories, map, scale, output_size
# end

# function imresize_findMethodArg(varargin)
#     nargin = length(varargin)

#     idx = Float64[]
#     for k in 1:nargin
#         arg = varargin[k]
#         if typeof(arg) == String
#             if imresize_isMethodString(arg)
#                 idx = k
#                 break

#             else
#                 break
#             end

#         elseif TyBaseCore.isvector(arg) &&
#             (any(typeof.(arg) .<: Function) || any(typeof.(arg) .<: String))
#             idx = k
#             break
#         end
#     end

#     return idx
# end

# function imresize_scaleOrSize(arg, position)
#     scale = Float64[]
#     output_size = Float64[]

#     if TyBaseCore.ty_isnumeric(arg) && eltype(arg) != Bool && TyBaseCore.isscalar(arg)
#         if !(TyBaseCore.ty_isnumeric(arg) && eltype(arg) != Bool)
#             error(
#                 "第 $(position) 个输入, SCALE, 应为以下类型之一:\n\nFloat64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64\n\n但其类型为 $(eltype(arg))。",
#             )
#         end
#         if arg == 0
#             error(_msg("第 $(position) 个输入, SCALE, 应为 非零。", splitext(basename(@__FILE__))[1]))
#         end
#         if !TyBaseCore.isreal(arg)
#             error(_msg("第 $(position) 个输入, SCALE, 应为 实数。", splitext(basename(@__FILE__))[1]))
#         end
#         scale = Float64.(arg)

#     elseif TyBaseCore.ty_isnumeric(arg) && TyBaseCore.isvector(arg) && length(arg) == 2
#         if !(TyBaseCore.ty_isnumeric(arg) && eltype(arg) != Bool)
#             error(
#                 "第 $(position) 个输入, [MROWS NCOLS], 应为以下类型之一:\n\nFloat64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64\n\n但其类型为 $(eltype(arg))。",
#             )
#         end
#         if !TyBaseCore.isvector(arg)
#             error(_msg("第 $(position) 个输入, [MROWS NCOLS], 应为 向量。", splitext(basename(@__FILE__))[1]))
#         end
#         if !TyBaseCore.isreal(arg)
#             error(_msg("第 $(position) 个输入, [MROWS NCOLS], 应为 实数。", splitext(basename(@__FILE__))[1]))
#         end
#         if any(arg .<= 0)
#             error(_msg("第 $(position) 个输入, [MROWS NCOLS], 应为 正值。", splitext(basename(@__FILE__))[1]))
#         end
#         output_size = Float64.(arg)

#     else
#         error(_msg("比例或大小输入参数无效。", splitext(basename(@__FILE__))[1]))
#     end

#     return scale, output_size
# end

# function imresize_parseMethodArg(method)
#     valid_method_names, method_kernels, kernel_widths = imresize_getMethodInfo()

#     antialiasing = true

#     if typeof(method) == String
#         idx = find(strncmpi.(method, valid_method_names, length(method)))

#         if length(idx) == 0
#             error(_msg("无法识别的方法: $(method)", splitext(basename(@__FILE__))[1]))

#         elseif length(idx) == 1
#             idx = idx[1]
#             kernel = method_kernels[idx]
#             kernel_width = kernel_widths[idx]
#             if TyBaseCore.strcmp(valid_method_names[idx], "nearest")
#                 antialiasing = false
#             end

#         else
#             error(_msg("具有多义性的方法: $(method)", splitext(basename(@__FILE__))[1]))
#         end
#     else
#         kernel = method[1]
#         kernel_width = method[2]
#     end

#     return kernel, kernel_width, antialiasing
# end

# function warnIfPostMethodArgs(args, method_arg_idx, first_param_string_idx)
#     if TyBaseCore.isempty(method_arg_idx)
#         method_arg_idx = length(args) + 1
#     end

#     if TyBaseCore.isempty(first_param_string_idx)
#         first_param_string_idx = length(args) + 1
#     end

#     if (first_param_string_idx - method_arg_idx) > 1
#         @warn(
#             "警告: N and H are now ignored in the old syntaxes IMRESIZE(...,method,N) and IMRESIZE(...,method,H)."
#         )
#     end
# end

# function imresize_parseParamValuePairs(params_in, args, first_param_string)
#     params = params_in

#     if TyBaseCore.isempty(first_param_string)
#         return params
#     end

#     if rem(length(args) - first_param_string, 2) == 0
#         error(_msg("函数 IMRESIZE 的名称/值参数个数应为偶数。", splitext(basename(@__FILE__))[1]))
#     end

#     valid_params = ["Scale", "Colormap", "Dither", "OutputSize", "Method", "Antialiasing"]

#     param_check_fcns = [
#         imresize_processScaleParam,
#         processColormapParam,
#         processDitherParam,
#         imresize_processOutputSizeParam,
#         imresize_processMethodParam,
#         images_internal_resize_processAntialiasingParam,
#     ]

#     for k in first_param_string:2:length(args)
#         param_string = args[k]
#         if typeof(param_string) != String
#             error(_msg("输入参数应为参数名称字符串或字符向量: 参数编号 $(k)", splitext(basename(@__FILE__))[1]))
#         end

#         idx = find(TyBaseCore.strncmpi.(param_string, valid_params, length(param_string)))
#         num_matches = length(idx)
#         if num_matches == 0
#             error(_msg("无法识别的参数: $(param_string)", splitext(basename(@__FILE__))[1]))

#         elseif num_matches > 1
#             error(_msg("具有多义性的参数: $(param_string)", splitext(basename(@__FILE__))[1]))

#         else
#             idx = idx[1]
#             check_fcn = param_check_fcns[idx]
#             params = check_fcn(args[k + 1], params)
#         end
#     end

#     return params
# end

# function imresize_fixupSizeAndScale(params_in)
#     params = params_in

#     if TyBaseCore.isempty(params["scale"]) && TyBaseCore.isempty(params["output_size"])
#         error(_msg("必须指定比例或输出大小。", splitext(basename(@__FILE__))[1]))
#     end

#     if !TyBaseCore.isempty(params["scale"]) && TyBaseCore.isscalar(params["scale"])
#         params["scale"] = repeat([params["scale"]], 1, params["num_dims"])
#     end

#     params["output_size"], params["size_dim"] = imresize_fixupSize(params)

#     if TyBaseCore.isempty(params["scale"])
#         params["scale"] = images_internal_resize_deriveScaleFromSize(params)
#     end

#     if TyBaseCore.isempty(params["output_size"])
#         params["output_size"] = images_internal_resize_deriveSizeFromScale(params)
#     end

#     return params
# end

# function imresize_processScaleParam(arg, params_in)
#     valid =
#         TyBaseCore.ty_isnumeric(arg) &&
#         eltype(arg) != Bool &&
#         ((length(arg) == 1) || (length(arg) == params_in["num_dims"])) &&
#         all(arg .> 0)

#     if !valid
#         error(_msg("SCALE 必须为标量或二元正值向量。", splitext(basename(@__FILE__))[1]))
#     end

#     params = params_in
#     params["scale"] = arg

#     return params
# end

# function processColormapParam(arg, params_in)
#     valid = typeof(arg) == String && (strcmp(arg, "optimized") || strcmp(arg, "original"))
#     if !valid
#         error(_msg("COLORMAP 必须为 'optimized' 或 'original'。", splitext(basename(@__FILE__))[1]))
#     end
#     params = params_in
#     params["colormap_method"] = arg

#     return params
# end

# function processDitherParam(arg, params_in)
#     valid = TyBaseCore.ty_isnumeric(arg) && TyBaseCore.isscalar(arg)
#     if !valid
#         error(_msg("DITHER 必须为 true 或 false。", splitext(basename(@__FILE__))[1]))
#     end
#     params = params_in
#     if arg
#         params["dither_option"] = "dither"
#     else
#         params["dither_option"] = "nodither"
#     end

#     return params
# end

# function imresize_processOutputSizeParam(arg, params_in)
#     valid =
#         TyBaseCore.ty_isnumeric(arg) &&
#         eltype(arg) != Bool &&
#         (length(arg) == params_in["num_dims"]) &&
#         all(TyBaseCore.isnan.(arg) .| (arg .> 0))
#     if !valid
#         error(_msg("OUTPUTSIZE 必须为二元正值向量。", splitext(basename(@__FILE__))[1]))
#     end

#     params = params_in
#     params["output_size"] = arg

#     return params
# end

# function imresize_processMethodParam(arg, params_in)
#     valid = imresize_isMethodString(arg) || isMethodCell(arg)
#     if !valid
#         error(_msg("METHOD 无效。", splitext(basename(@__FILE__))[1]))
#     end

#     params = params_in
#     params["kernel"], params["kernel_width"], antialiasing = imresize_parseMethodArg(arg)

#     if TyBaseCore.isempty(params["antialiasing"])
#         params["antialiasing"] = antialiasing
#     end

#     return params
# end

# function isMethodCell(In)
#     tf =
#         TyBaseCore.isvector(In) &&
#         length(In) == 2 &&
#         typeof(In[1]) <: Function &&
#         TyBaseCore.ty_isnumeric(In[2]) &&
#         eltype(In[2]) != Bool &&
#         TyBaseCore.isscalar(In[2])

#     return tf
# end

# function imresize_isMethodString(In)
#     if typeof(In) != String
#         tf = false

#     else
#         valid_method_strings = getMethodInfo()[1]

#         num_matches = sum(TyBaseCore.strncmpi.(In, valid_method_strings, length(In)))
#         tf = num_matches == 1
#     end
#     return tf
# end

# function imresize_getMethodInfo()
#     names = [
#         "nearest", "bilinear", "bicubic", "box", "triangle", "cubic", "lanczos2", "lanczos3"
#     ]

#     kernels = [
#         images_internal_resize_box,
#         images_internal_resize_triangle,
#         images_internal_resize_cubic,
#         images_internal_resize_box,
#         images_internal_resize_triangle,
#         images_internal_resize_cubic,
#         images_internal_resize_lanczos2,
#         images_internal_resize_lanczos3,
#     ]

#     widths = [1.0 2.0 4.0 1.0 2.0 4.0 4.0 6.0]

#     return names, kernels, widths
# end

# function imresize_fixupSize(params)
#     output_size = params["output_size"]
#     size_dim = Float64[]

#     if !TyBaseCore.isempty(output_size)
#         if !all(output_size .!= 0)
#             error(_msg("指定的输出大小不能包含零。", splitext(basename(@__FILE__))[1]))
#         end

#         if all(TyBaseCore.isnan.(output_size))
#             error(_msg("指定的输出大小不能包含两个 NaN。", splitext(basename(@__FILE__))[1]))
#         end

#         if TyBaseCore.isnan(output_size[1])
#             output_size[1] =
#                 params["output_size"][2] * size(params["A"], 1) / size(params["A"], 2)
#             size_dim = 2
#         elseif TyBaseCore.isnan(output_size[2])
#             output_size[2] =
#                 params["output_size"][1] * size(params["A"], 2) / size(params["A"], 1)
#             size_dim = 1
#         end

#         output_size = ceil.(output_size)
#     end

#     return output_size, size_dim
# end

function images_internal_resize_box(x)
    f = Int.((-0.5 .<= x) .& (x .< 0.5))
    return f
end

function images_internal_resize_triangle(x)
    f = (x .+ 1) .* ((-1 .<= x) .& (x .< 0)) + (1 .- x) .* Int.((0 .<= x) .& (x .<= 1))
    return f
end

function images_internal_resize_cubic(x)
    absx = abs.(x)
    absx2 = absx .^ 2
    absx3 = absx .^ 3

    f =
        (1.5 * absx3 .- 2.5 * absx2 .+ 1) .* (absx .<= 1) .+
        (-0.5 * absx3 .+ 2.5 * absx2 .- 4 * absx .+ 2) .* Int.((1 .< absx) .& (absx .<= 2))
    return f
end

function images_internal_resize_lanczos2(x)
    f = (sin.(pi * x) .* sin.(pi * x / 2) .+ eps()) ./ ((pi^2 * x .^ 2 / 2) .+ eps())
    f = f .* Int.(abs.(x) .< 2)
    return f
end

function images_internal_resize_lanczos3(x)
    f = (sin.(pi * x) .* sin.(pi * x / 3) .+ eps()) ./ ((pi^2 * x .^ 2 / 3) .+ eps())
    f = f .* Int.(abs.(x) .< 3)
    return f
end

function images_internal_resize_findFirstParamString(args, method_arg_idx)
    if TyBaseCore.isempty(method_arg_idx)
        method_arg_idx = 0
    end

    is_class = Int.(collect(typeof.(args[(method_arg_idx .+ 1):end]) .== String))
    first_param_string_idx = TyBaseCore.find(is_class, 1) .+ method_arg_idx

    return first_param_string_idx
end

function images_internal_resize_deriveScaleFromSize(params)
    if !TyBaseCore.isempty(params["size_dim"])
        scale =
            params["output_size"][params["size_dim"]] /
            size(params["A"], params["size_dim"])
        if TyBaseCore.isscalar(scale)
            scale = [scale]
        end
        scale = repeat(scale, 1, params["num_dims"])
    else
        A_size = size(params["A"])
        scale =
            reshape(params["output_size"], 1, :) ./ collect(A_size[1:params["num_dims"]])'
    end

    return scale
end

function images_internal_resize_deriveSizeFromScale(params)
    A_size = collect(size(params["A"]))
    A_size = reshape(A_size, 1, length(A_size))
    while length(A_size) < params["num_dims"]
        A_size = [A_size 1]
    end
    output_size = ceil.(params["scale"] .* collect(A_size[1:params["num_dims"]]'))
    return output_size
end

function images_internal_resize_processAntialiasingParam(arg, params_in)
    valid = TyBaseCore.ty_isnumeric(arg) && TyBaseCore.isscalar(arg)
    if !valid
        error(
            _msg(
                @tr("ANTIALIASING must be true or false."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    params = params_in
    params["antialiasing"] = arg
    return params
end

function images_internal_resize_checkForMissingOutputArgument(params, num_output_args)
    if images_internal_resize_isInputIndexed(params) &&
        TyBaseCore.strcmp(params["colormap_method"], "optimized") &&
        (num_output_args < 2)
        @warn(
            "警告: 索引图像缺少第二个输出参数。当您调整索引图像的大小时，imresize 默认情况下会计算新的颜色图，该颜色图将作为第二个输出参数返回。您可以通过按以下方式调用 imresize 来解决该问题:\nY,newmap = imresize(X,map,...)\n您也可以通过以下语法使用原始颜色图来进行大小调整:\nY = imresize(X,map,...;Colormap=\"original\",...)"
        )
    end
end

function images_internal_resize_isInputIndexed(params)
    tf = !TyBaseCore.isempty(params["map"])
    return tf
end

function images_internal_resize_preprocessImage(params)
    if images_internal_resize_isInputIndexed(params)
        A = im2uint8(ind2rgb(params["A"], params["map"]))
    elseif eltype(params["A"]) == Bool
        A = UInt8.(255 * Int.(params["A"]))
    else
        A = params["A"]
    end

    return A
end

function images_internal_resize_dimensionOrder(scale)
    _, order = TyBaseCore.ty_sort(scale; nargout=2)
    return order
end

function images_internal_resize_contributions(
    in_length, out_length, scale, kernel, kernel_width, antialiasing
)
    if (scale < 1) && (antialiasing)
        h(x) = scale * kernel(scale * x)
        kernel_width = kernel_width / scale
    else
        h = kernel
    end

    x = if TyBaseCore.isempty(1:out_length)
        Float64[]
    else
        collect(reshape(1:out_length, Int(out_length), 1))
    end

    u = TyBaseCore.isempty(x) ? Float64[] : x / scale .+ 0.5 * (1 - 1 / scale)

    left = TyBaseCore.isempty(u) ? Float64[] : floor.(u .- kernel_width / 2)

    P = ceil(kernel_width) .+ 2

    indices = TyBaseCore.bsxfun(.+, left, collect(reshape(0:(P - 1), 1, Int(P))))

    weights = h(TyBaseCore.bsxfun(.-, u, indices))

    weights = TyBaseCore.bsxfun(./, weights, sum(weights; dims=2))

    aux = [reshape(1:in_length, 1, in_length) reshape(in_length:-1:1, 1, in_length)]
    indices = aux[Int.(mod.(indices .- 1, length(aux)) .+ 1)]

    logicalweights = copy(weights)

    logicalweights[logicalweights .!= 0] .= 1
    logicalweights = Bool.(logicalweights)

    kill = find(.!any(logicalweights; dims=1))
    if !TyBaseCore.isempty(kill)
        weights = weights[:, setdiff(1:size(weights, 2), kill)]
        indices = indices[:, setdiff(1:size(indices, 2), kill)]
    end

    return weights, indices
end

function images_internal_resize_isPureNearestNeighborComputation(weights)
    one_weight_per_pixel = size(weights, 2) == 1
    tf = one_weight_per_pixel && all(weights .== 1)
    return tf
end

function images_internal_resize_resizeAllDimUsingNearestNeighbor(In, indices)
    subscripts = indices
    if (length(indices) + 1) <= ndims(In)
        Nsubscripts = Matrix{Union{Function,AbstractArray,Nothing}}(nothing, 1, ndims(In))
        Nsubscripts[1:length(indices)] = subscripts[1:length(indices)]
        subscripts = Nsubscripts
    end
    subscripts[collect((length(indices) + 1):ndims(In))] .= Base.:(:)
    for i in 1:length(subscripts)
        if subscripts[i] != Base.:(:)
            subscripts[i] = vec(subscripts[i])
        end
    end
    out = In[subscripts[:]...]

    return out
end

function images_internal_resize_resizeAlongDimUsingNearestNeighbor(In, dim, indices)
    num_dims = max(ndims(In), dim)
    subscripts = Base.:(:)
    nsubscripts = Matrix{Union{Function,AbstractArray,Nothing}}(nothing, 1, num_dims)
    for i in 1:num_dims
        nsubscripts[i] = subscripts
    end
    subscripts = nsubscripts
    subscripts[dim] = indices
    out = In[subscripts[:]...]
    if dim == 1
        out = reshape(out, size(out)[2:end])
    else
        dim == 2
        out = reshape(out, Tuple([size(out)[1] size(out)[3:end]...]))
    end
    return out
end

function images_internal_resize_postprocessImage(B_in, params)
    map = Float64[]
    if images_internal_resize_isInputIndexed(params)
        if TyBaseCore.strcmp(params["colormap_method"], "original")
            map = params["map"]
            B, = rgb2ind(B_in, map; dithering=params["dither_option"])
        else
            B, map = rgb2ind(B_in, 256; dithering=params["dither_option"])
        end

    elseif eltype(params["A"]) == Bool
        B = B_in .> 128

    else
        B = B_in
    end
    return B, map
end

function images_internal_resize_imresizemex(In, weights, indices, dim)
    outtype = eltype(In)
    In = Float64.(In)
    if ndims(In) <= 3
        if dim == 1
            out = zeros(size(weights, 2), size(In, 2), size(In, 3))
        else
            out = zeros(size(In, 1), size(weights, 2), size(In, 3))
        end
        for k in 1:size(In, 3)
            for i in 1:size(out, dim)
                for j in 1:size(weights, 1)
                    if dim == 1
                        out[i, :, k] =
                            out[i, :, k] + In[indices[j, i], :, k] .* weights[j, i]
                    else
                        out[:, i, k] =
                            out[:, i, k] + In[:, indices[j, i], k] .* weights[j, i]
                    end
                end
            end
        end
    end
    if ndims(out) == 3 && size(out, 3) == 1
        out = out[:, :, 1]
    end
    if outtype <: Integer
        out = outtype.(TyBaseCore.ty_round(clamp.(out, typemin(outtype), typemax(outtype))))
    else
        out = outtype.(out)
    end
    return out
end
