"""
旋转图像

J = imrotate(I,angle)

J = imrotate(I,angle,method)

J = imrotate(I,angle,method,bbox)

J = imrotate(I,angle,method="nearest")

J = imrotate(I,angle,bbox="crop")

 I: 待旋转的图像，Float32 | Float64 | UInt8 | UInt16 | Int16

 angle: 数值标量，单位为degree, 逆时针旋转：angle>0,  顺时针：angle<0

 J:旋转后的图像，与I格式相同

 method: 插值算法，"bilinear","nearest"(默认),"lanczos","bicubic"；
         "lanczos" 通过 Python/OpenCV 实现

 bbox: 是否裁剪以保持原来尺寸，"loose"(默认)：不裁剪，"crop":裁剪

"""
function imrotate(
    I::AbstractArray{<:Real}, angle::Real, option1::AbstractString, option2::AbstractString
)
    method, bbox = :nearest, :loose
    for option in (option1, option2)
        parsed = Symbol(lowercase(option))
        if parsed in BBOX_METHODS
            bbox = parsed
        elseif parsed in INTERP_METHODS
            method = parsed
        else
            throw(
                DomainError(
                    option,
                    @tr(
                        "Invalid imrotate option; expected one of %{1}.",
                        string((INTERP_METHODS..., BBOX_METHODS...)),
                    ),
                ),
            )
        end
    end
    A, ang, method, bbox = _imrotate_parse_inputs(I, angle, method, bbox)

    return _internal_imrotate(A, ang, method, bbox)
end

function imrotate(I::AbstractArray{<:Real}, angle::Real, method::AbstractString)
    option = Symbol(lowercase(method))
    parsed_method, parsed_bbox =
        option in BBOX_METHODS ? (:nearest, option) : (option, :loose)
    A, ang, method, bbox = _imrotate_parse_inputs(I, angle, parsed_method, parsed_bbox)

    return _internal_imrotate(A, ang, method, bbox)
end

function imrotate(
    I::AbstractArray{<:Real},
    angle::Real;
    method::AbstractString="nearest",
    bbox::AbstractString="loose",
)
    A, ang, method, bbox = _imrotate_parse_inputs(I, angle, method, bbox)

    return _internal_imrotate(A, ang, method, bbox)
end

# 主入口
function _internal_imrotate(
    A::AbstractArray{T}, ang::Float64, method::Symbol, bbox::Symbol
) where {T}
    isempty(A) && return A

    sz = size(A)

    # 与 MATLAB 一致：仅严格整除 90 度时进入快速旋转路径。
    if rem(ang, 90) == 0
        return _rotate_90_multiple(A, mod(floor(Int, ang / 90), 4), bbox, sz)
    else
        return _rotate_arbitrary(A, ang, method, bbox, sz)
    end
end

# 90度倍数旋转
function _rotate_90_multiple(A::AbstractArray, k::Int, bbox::Symbol, sz)
    k == 0 && return A

    indices = ntuple(i -> (:), ndims(A))

    if k == 2  # 180度
        return @view A[end:-1:1, end:-1:1, indices[3:end]...]
    end

    # 90/270度
    if ndims(A) == 2
        _rotate_90_2d(A, k, bbox, sz)
    else
        _rotate_90_nd(A, k, bbox, sz)
    end
end

function _rotate_90_2d(A::AbstractMatrix, k::Int, bbox::Symbol, sz)
    if bbox == :crop && sz[1] != sz[2]
        mindim = min(sz[1], sz[2])
        offset = abs(fld(sz[1], 2) - fld(sz[2], 2))

        src_ranges = if sz[1] > sz[2]
            (1 + offset):(mindim + offset), 1:mindim
        else
            1:mindim, (1 + offset):(mindim + offset)
        end

        B = similar(A, sz[1:2])
        fill!(B, zero(eltype(B)))
        @views B[src_ranges...] .= rotl90(A[src_ranges...], k)
        return B
    end

    # 正方形或loose模式
    return rotl90(A, k)
end

# 多维数组旋转（批量处理）
function _rotate_90_nd(A::AbstractArray{T}, k::Int, bbox::Symbol, sz) where {T}
    thirdD = prod(sz[3:end])
    twod_size = (sz[1], sz[2])

    out_sz = if bbox == :crop && sz[1] != sz[2]
        sz
    else
        (sz[2], sz[1], sz[3:end]...)
    end

    B = similar(A, out_sz)
    bbox == :crop && sz[1] != sz[2] && fill!(B, zero(T))

    @inbounds for ch in 1:thirdD
        view_src = @view reshape(A, twod_size..., thirdD)[:, :, ch]
        view_dst = @view reshape(B, (out_sz[1], out_sz[2], :))[:, :, ch]

        if bbox == :crop && sz[1] != sz[2]
            _crop_rotate_90!(view_dst, view_src, k, twod_size)
        else
            copyto!(view_dst, rotl90(view_src, k))
        end
    end
    return B
end

@inline function _crop_rotate_90!(dst, src, k, sz)
    mindim = min(sz...)
    offset = abs(fld(sz[1], 2) - fld(sz[2], 2))

    # 使用CartesianIndices进行高效迭代
    src_ranges = if sz[1] > sz[2]
        (1 + offset):(mindim + offset), 1:mindim
    else
        1:mindim, (1 + offset):(mindim + offset)
    end

    @views @inbounds dst[src_ranges...] .= rotl90(src[src_ranges...], k)
end

# 任意角度旋转
function _rotate_arbitrary(A::Matrix{UInt8}, ang::Float64, method::Symbol, bbox::Symbol, sz)
    method == :lanczos && return _py_lanczos_imrotate(A, ang, bbox)
    if method == :bilinear && bbox == :crop
        return _rotate_bilinear_crop_uint8(A, ang)
    end
    return _rotate_arbitrary_imwarp(A, ang, method, bbox, sz)
end

function _rotate_arbitrary(
    A::Array{UInt8,3}, ang::Float64, method::Symbol, bbox::Symbol, sz
)
    method == :lanczos && return _py_lanczos_imrotate(A, ang, bbox)
    if method == :bilinear && bbox == :crop
        return _rotate_bilinear_crop_uint8(A, ang)
    end
    return _rotate_arbitrary_imwarp(A, ang, method, bbox, sz)
end

function _rotate_arbitrary(A::AbstractArray, ang::Float64, method::Symbol, bbox::Symbol, sz)
    method == :lanczos && return _py_lanczos_imrotate(A, ang, bbox)
    return _rotate_arbitrary_imwarp(A, ang, method, bbox, sz)
end

function _rotate_arbitrary_imwarp(
    A::AbstractArray, ang::Float64, interp_method::Symbol, bbox::Symbol, sz
)
    cos_a, sin_a = cosd(ang), sind(ang)

    M = [
        cos_a -sin_a 0.0
        sin_a cos_a 0.0
        0.0 0.0 1.0
    ]

    tform = affinetform2d(inv(M))
    RA = imref2d(sz)
    Rout = images_spatialref_internal_applyGeometricTransformToSpatialRef(RA, tform)

    if bbox == :crop
        x_mid_diff = mean(Rout.XWorldLimits) - mean(RA.XWorldLimits)
        y_mid_diff = mean(Rout.YWorldLimits) - mean(RA.YWorldLimits)

        Rout.ImageSize = sz[1:2]
        Rout.XWorldLimits = RA.XWorldLimits .+ x_mid_diff
        Rout.YWorldLimits = RA.YWorldLimits .+ y_mid_diff
    end

    return first(imwarp(A, tform, string(interp_method); OutputView=Rout, SmoothEdges=true))
end

# 定义常量（编译时常量）
const ALLOWED_ARRAY_TYPES = Union{
    AbstractArray{Float64},
    AbstractArray{Float32},
    AbstractArray{UInt8},
    AbstractArray{UInt16},
    AbstractArray{Int8},
    AbstractArray{Int16},
    AbstractArray{Bool},
}
const INTERP_METHODS = (:nearest, :bilinear, :bicubic, :lanczos)
const BBOX_METHODS = (:crop, :loose)

# 主函数 - 完全类型稳定
function _imrotate_parse_inputs(
    A::ALLOWED_ARRAY_TYPES, ang::Real, method::Symbol, bbox::Symbol
)
    ang_fl = Float64(ang)
    @boundscheck method in INTERP_METHODS || throw(
        DomainError(
            method,
            @tr(
                "Invalid interpolation method; expected one of %{1}.",
                string(INTERP_METHODS)
            )
        ),
    )
    @boundscheck bbox in BBOX_METHODS || throw(
        DomainError(
            bbox, @tr("Invalid boundary method; expected one of %{1}.", BBOX_METHODS)
        ),
    )

    return A, ang_fl, method, bbox
end

@inline function _imrotate_parse_inputs(A, ang, method::String, bbox::String)
    return _imrotate_parse_inputs(
        A, ang, Symbol(lowercase(method)), Symbol(lowercase(bbox))
    )
end

# 错误处理分支 - 单独编译（避免污染主路径）
@noinline function _imrotate_parse_inputs(A, ang, method, bbox)
    return _validate_types(A, ang)
end

@noinline function _validate_types(A, ang)
    if !TyBaseCore.ty_isnumeric(A)
        error(@tr("Image type %{1} is not a supported numeric type.", typeof(A)))
    end
    if !(TyBaseCore.ty_isnumeric(ang) && TyBaseCore.isreal(ang))
        error(@tr("Rotation angle must be a real scalar."))
    end

    return A, Float64(ang), :bilinear, :crop
end

@inline function _bilinear_zero_padded_uint8(
    A::Matrix{UInt8}, y0::Int, x0::Int, fy::Float64, fx::Float64
)
    h, w = size(A)
    x1 = x0 + 1
    y1 = y0 + 1

    v00 = 1 <= y0 <= h && 1 <= x0 <= w ? Float64(A[y0, x0]) : 0.0
    v01 = 1 <= y0 <= h && 1 <= x1 <= w ? Float64(A[y0, x1]) : 0.0
    v10 = 1 <= y1 <= h && 1 <= x0 <= w ? Float64(A[y1, x0]) : 0.0
    v11 = 1 <= y1 <= h && 1 <= x1 <= w ? Float64(A[y1, x1]) : 0.0

    top = muladd(fx, v01 - v00, v00)
    bottom = muladd(fx, v11 - v10, v10)
    return muladd(fy, bottom - top, top)
end

@inline function _bilinear_zero_padded_uint8(
    A::Array{UInt8,3}, y0::Int, x0::Int, channel::Int, fy::Float64, fx::Float64
)
    h, w = size(A)
    x1 = x0 + 1
    y1 = y0 + 1

    v00 = 1 <= y0 <= h && 1 <= x0 <= w ? Float64(A[y0, x0, channel]) : 0.0
    v01 = 1 <= y0 <= h && 1 <= x1 <= w ? Float64(A[y0, x1, channel]) : 0.0
    v10 = 1 <= y1 <= h && 1 <= x0 <= w ? Float64(A[y1, x0, channel]) : 0.0
    v11 = 1 <= y1 <= h && 1 <= x1 <= w ? Float64(A[y1, x1, channel]) : 0.0

    top = muladd(fx, v01 - v00, v00)
    bottom = muladd(fx, v11 - v10, v10)
    return muladd(fy, bottom - top, top)
end

@inline function _uint8_from_interpolation(value::Float64)
    return Base.unsafe_trunc(UInt8, value + 0.5)
end

@inline function _bilinear_interior_uint8(
    A::Array{UInt8,3}, i00::Int, i01::Int, i10::Int, i11::Int, fy::Float64, fx::Float64
)
    v00 = Float64(A[i00])
    v01 = Float64(A[i01])
    v10 = Float64(A[i10])
    v11 = Float64(A[i11])
    top = muladd(fx, v01 - v00, v00)
    bottom = muladd(fx, v11 - v10, v10)
    return muladd(fy, bottom - top, top)
end

function _rotate_bilinear_crop_uint8(A::Matrix{UInt8}, ang::Float64)
    h, w = size(A)
    B = similar(A)

    cos_a, sin_a = cosd(ang), sind(ang)
    center_x = (w + 1) * 0.5
    center_y = (h + 1) * 0.5

    @inbounds for x_out in 1:w
        dx = x_out - center_x
        x_src = muladd(cos_a, dx, -sin_a * (1 - center_y) + center_x)
        y_src = muladd(sin_a, dx, cos_a * (1 - center_y) + center_y)

        for y_out in 1:h
            x0 = floor(Int, x_src)
            y0 = floor(Int, y_src)
            fx = x_src - x0
            fy = y_src - y0

            value = if 1 <= x0 < w && 1 <= y0 < h
                v00 = Float64(A[y0, x0])
                v01 = Float64(A[y0, x0 + 1])
                v10 = Float64(A[y0 + 1, x0])
                v11 = Float64(A[y0 + 1, x0 + 1])
                top = muladd(fx, v01 - v00, v00)
                bottom = muladd(fx, v11 - v10, v10)
                muladd(fy, bottom - top, top)
            else
                _bilinear_zero_padded_uint8(A, y0, x0, fy, fx)
            end
            B[y_out, x_out] = _uint8_from_interpolation(value)

            x_src -= sin_a
            y_src += cos_a
        end
    end

    return B
end

function _rotate_bilinear_crop_uint8(A::Array{UInt8,3}, ang::Float64)
    h, w, channels = size(A)
    channels == 3 && return _rotate_bilinear_crop_rgb_uint8(A, ang)

    B = similar(A)

    cos_a, sin_a = cosd(ang), sind(ang)
    center_x = (w + 1) * 0.5
    center_y = (h + 1) * 0.5

    @inbounds for x_out in 1:w
        dx = x_out - center_x
        x_src = muladd(cos_a, dx, -sin_a * (1 - center_y) + center_x)
        y_src = muladd(sin_a, dx, cos_a * (1 - center_y) + center_y)

        for y_out in 1:h
            x0 = floor(Int, x_src)
            y0 = floor(Int, y_src)
            fx = x_src - x0
            fy = y_src - y0

            if 1 <= x0 < w && 1 <= y0 < h
                for channel in 1:channels
                    v00 = Float64(A[y0, x0, channel])
                    v01 = Float64(A[y0, x0 + 1, channel])
                    v10 = Float64(A[y0 + 1, x0, channel])
                    v11 = Float64(A[y0 + 1, x0 + 1, channel])
                    top = muladd(fx, v01 - v00, v00)
                    bottom = muladd(fx, v11 - v10, v10)
                    value = muladd(fy, bottom - top, top)
                    B[y_out, x_out, channel] = _uint8_from_interpolation(value)
                end
            else
                for channel in 1:channels
                    value = _bilinear_zero_padded_uint8(A, y0, x0, channel, fy, fx)
                    B[y_out, x_out, channel] = _uint8_from_interpolation(value)
                end
            end

            x_src -= sin_a
            y_src += cos_a
        end
    end

    return B
end

function _rotate_bilinear_crop_rgb_uint8(A::Array{UInt8,3}, ang::Float64)
    h, w, _ = size(A)
    B = similar(A)
    plane_length = h * w

    cos_a, sin_a = cosd(ang), sind(ang)
    center_x = (w + 1) * 0.5
    center_y = (h + 1) * 0.5

    @inbounds for x_out in 1:w
        dx = x_out - center_x
        x_src = muladd(cos_a, dx, -sin_a * (1 - center_y) + center_x)
        y_src = muladd(sin_a, dx, cos_a * (1 - center_y) + center_y)
        output_index = (x_out - 1) * h + 1

        for y_out in 1:h
            x0 = floor(Int, x_src)
            y0 = floor(Int, y_src)
            fx = x_src - x0
            fy = y_src - y0

            if 1 <= x0 < w && 1 <= y0 < h
                i00 = (x0 - 1) * h + y0
                i01 = i00 + h
                i10 = i00 + 1
                i11 = i01 + 1

                B[output_index] = _uint8_from_interpolation(
                    _bilinear_interior_uint8(A, i00, i01, i10, i11, fy, fx)
                )
                B[output_index + plane_length] = _uint8_from_interpolation(
                    _bilinear_interior_uint8(
                        A,
                        i00 + plane_length,
                        i01 + plane_length,
                        i10 + plane_length,
                        i11 + plane_length,
                        fy,
                        fx,
                    ),
                )
                B[output_index + 2 * plane_length] = _uint8_from_interpolation(
                    _bilinear_interior_uint8(
                        A,
                        i00 + 2 * plane_length,
                        i01 + 2 * plane_length,
                        i10 + 2 * plane_length,
                        i11 + 2 * plane_length,
                        fy,
                        fx,
                    ),
                )
            else
                B[output_index] = _uint8_from_interpolation(
                    _bilinear_zero_padded_uint8(A, y0, x0, 1, fy, fx)
                )
                B[output_index + plane_length] = _uint8_from_interpolation(
                    _bilinear_zero_padded_uint8(A, y0, x0, 2, fy, fx)
                )
                B[output_index + 2 * plane_length] = _uint8_from_interpolation(
                    _bilinear_zero_padded_uint8(A, y0, x0, 3, fy, fx)
                )
            end

            output_index += 1
            x_src -= sin_a
            y_src += cos_a
        end
    end

    return B
end

function _py_lanczos_imrotate(img, deg::Real, bbox::Symbol)
    py"""
    import cv2
    import numpy as np

    def ty_imrotate_lanczos(src, deg, loose):
        h, w = src.shape[:2]
        center = (w // 2, h // 2)
        rt_matrix = cv2.getRotationMatrix2D(center, deg, 1.0)
        if loose:
            cos_x = np.abs(rt_matrix[0, 0])
            sin_x = np.abs(rt_matrix[0, 1])
            new_w = h * sin_x + w * cos_x
            new_h = h * cos_x + w * sin_x
            rt_matrix[0, 2] += (new_w - w) * 0.5
            rt_matrix[1, 2] += (new_h - h) * 0.5
            w = int(np.round(new_w))
            h = int(np.round(new_h))
        return cv2.warpAffine(src, rt_matrix, (w, h), cv2.INTER_LANCZOS4)
    """

    return py"ty_imrotate_lanczos"(img, deg, bbox == :loose)
end

# Precompile the benchmark/common grayscale path so a fresh session does not
# pay its compilation cost on the first imrotate call.
precompile(_rotate_bilinear_crop_uint8, (Matrix{UInt8}, Float64))
precompile(_rotate_bilinear_crop_uint8, (Array{UInt8,3}, Float64))
precompile(_rotate_bilinear_crop_rgb_uint8, (Array{UInt8,3}, Float64))
precompile(imrotate, (Matrix{UInt8}, Float64, String, String))
precompile(imrotate, (Array{UInt8,3}, Float64, String, String))
