"""
    imedge(img, "sobel"; kwargs...)
    imedge(img, "prewitt"; kwargs...)
    imedge(img, "roberts"; kwargs...)
    imedge(img, "canny"; kwargs...)

使用指定的边缘检测方法检测图像的边缘。

## 关键词参数

- `thinning::Bool`： 是否对边缘进行细化。 默认为 `true`。
- `direction::Union{Symbol,String}`: 检测边缘的方向，可选值为 `:both`、`:horizontal`、`:vertical`，默认为 `:both`。
- `thresh::Real`： 边缘检测的阈值，如果不填，则根据图像的平均梯度自动计算阈值。
  若为 canny 方法，则为两个阈值的数组，第一个为低阈值，第二个为高阈值。
- `sigma::Real`： 高斯滤波的标准差，仅对 canny 方法有效。 默认为 `sqrt(2)`。

## 示例

```julia
img = imread("lake_gray")
edge1 = imedge(img)
edge2 = imedge(img, "canny")
```

"""
function imedge(img, method="sobel", args...; kwargs...)
    _ensure_gray(im2julia(img))
    method = Symbol(lowercase(String(method)))
    if method == :canny
        return imedge_canny(img, args...; kwargs...)
    elseif method == :prewitt
        return imedge_prewitt(img, args...; kwargs...)
    elseif method == :sobel
        return imedge_sobel(img, args...; kwargs...)
    elseif method == :roberts
        return imedge_roberts(img, args...; kwargs...)
    elseif method == :log
        return imedge_log(img, args...; kwargs...)
    elseif method == :zerocross
        return imedge_zerocross(img, args...; kwargs...)
    elseif method == :approxcanny
        return imedge_approxcanny(img, args...; kwargs...)
    else
        error(
            _msg(
                @tr("Unsupported edge detection method: %{1}.", method),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
end

function imedge_sobel(img; kwargs...)
    return _imedge_kernel(img, ImageFiltering.KernelFactors.sobel; kwargs...)
end
function imedge_prewitt(img; kwargs...)
    return _imedge_kernel(img, ImageFiltering.KernelFactors.prewitt; kwargs...)
end
imedge_roberts(img; kwargs...) = _imedge_kernel(img, roberts; kwargs...)

function roberts(extended, d)
    h1 = centered([1.0 0.0; 0.0 -1.0])
    h2 = centered([0.0 1.0; -1.0 0.0])
    return ImageFiltering.KernelFactors.gradfactors(extended, d, h1, h2)
end

function _imedge_kernel(
    img, kernel; thresh::Union{Nothing,Real}=nothing, thinning=true, direction="both"
)
    direction = Symbol(lowercase(String(direction)))
    if !(direction in (:both, :horizontal, :vertical))
        error(
            _msg(
                @tr("Unsupported direction: %{1}.", direction),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    imgjl = im2julia(img)

    g₁, g₂ = ImageFiltering.imgradients(imgjl, kernel)
    mag = if direction == :both
        hypot.(g₁, g₂)
    elseif direction == :horizontal
        abs2.(g₁)
    else
        abs2.(g₂)
    end

    if isnothing(thresh)
        cutoff = 4 * sum(mag) / length(mag)
        thresh = sqrt(cutoff)
    else
        cutoff = thresh^2
    end

    if thinning
        thin_method = ImageEdgeDetection.NonmaximaSuppression()
        edge = ImageEdgeDetection.thin_edges(mag, g₁, g₂, thin_method)
    else
        edge = mag
    end

    return @. Float64(edge > cutoff)
end

function imedge_log(img, args...; kwargs...)
    return error(
        _msg(
            @tr("log edge detection method is not implemented yet."),
            splitext(basename(@__FILE__))[1],
        ),
    )
end

function imedge_zerocross(img, args...; kwargs...)
    return error(
        _msg(
            @tr("zerocross edge detection method is not implemented yet."),
            splitext(basename(@__FILE__))[1],
        ),
    )
end

function imedge_canny(img; thresh=nothing, sigma=sqrt(2))
    imgjl = im2julia(img)
    alg = if isnothing(thresh)
        ImageEdgeDetection.Canny(; spatial_scale=sigma)
    else
        if length(thresh) != 2
            error(
                _msg(
                    @tr("thresh parameter must be an array of length 2."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        ImageEdgeDetection.Canny(; spatial_scale=sigma, low=thresh[1], high=thresh[2])
    end
    return Float64.(ImageEdgeDetection.detect_edges(imgjl, alg))
end

function imedge_approxcanny(img, args...; kwargs...)
    return error(
        _msg(
            @tr("approxcanny edge detection method is not implemented yet."),
            splitext(basename(@__FILE__))[1],
        ),
    )
end

_ensure_gray(img::AbstractArray{T}) where {T<:Real} = nothing
_ensure_gray(img::AbstractArray{T}) where {T<:Gray} = nothing
function _ensure_gray(img::AbstractArray{T}) where {T<:RGB}
    return error(
        _msg(@tr("Only grayscale images are supported."), splitext(basename(@__FILE__))[1])
    )
end
