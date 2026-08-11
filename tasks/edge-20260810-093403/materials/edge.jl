"""
    edge(I, method="Sobel"; fig=true, direction="both", threshold=nothing,
         sigma=nothing)

检测二维灰度图像中的边缘。支持 `"Sobel"`、`"Prewitt"`、`"Roberts"`、
`"log"`、`"zerocross"` 和 `"Canny"` 方法。

当 `fig=false` 时，除 Canny 外的方法返回二值边缘图；Canny 返回
`(BW, [low_threshold, high_threshold])`。Canny 的默认 `sigma` 为 `sqrt(2)`，
LoG 和 zerocross 的默认 `sigma` 为 `2`。
"""
function ty_edge end
const edge = ty_edge

const method_vec = ["Sobel", "Prewitt", "Roberts", "log", "zerocross", "Canny"]
const dir_strs = ["both", "horizontal", "vertical"]

function ty_edge(
    img::AbstractMatrix{T},
    method0::AbstractString="Sobel";
    fig=true,
    direction="both",
    threshold=nothing,
    sigma::Union{Nothing,Real}=nothing,
) where {T<:Union{MInteger,MFloat,Bool}}
    @ccall_check_func_lic :TyImageProcessing

    method = lowercase(method0)
    direction = lowercase(String(direction))
    direction in dir_strs || _edge_direction_error(direction)
    return _edge_dispatch(Val(Symbol(method)), img, fig, direction, threshold, sigma)
end

function _edge_dispatch(::Val{:canny}, img, fig, direction, threshold, sigma)
    sigma_value = isnothing(sigma) ? sqrt(2) : sigma
    dst, low_threshold, high_threshold = edge_canny(img, threshold, sigma_value)
    if fig
        imshow(dst)
        return nothing
    end
    return dst, [low_threshold, high_threshold]
end

function _edge_dispatch(::Val{:prewitt}, img, fig, direction, threshold, sigma)
    isnothing(sigma) || _edge_parameter_error()
    return _edge_display_or_return(edge_prewitt(img, direction, threshold), fig)
end

function _edge_dispatch(::Val{:sobel}, img, fig, direction, threshold, sigma)
    isnothing(sigma) || _edge_parameter_error()
    return _edge_display_or_return(edge_sobel(img, direction, threshold), fig)
end

function _edge_dispatch(::Val{:roberts}, img, fig, direction, threshold, sigma)
    isnothing(sigma) || _edge_parameter_error()
    return _edge_display_or_return(edge_roberts(img, direction, threshold), fig)
end

function _edge_dispatch(
    ::Union{Val{:log},Val{:zerocross}}, img, fig, direction, threshold, sigma
)
    sigma_value = isnothing(sigma) ? 2.0 : sigma
    return _edge_display_or_return(edge_zerocross(img, threshold, sigma_value), fig)
end

function _edge_dispatch(::Val{method}, img, fig, direction, threshold, sigma) where {method}
    return error(
        _msg(
            @tr(
                "Edge detection method \"%{1}\" is not supported. Supported methods are %{2}.",
                String(method),
                method_vec,
            ),
            splitext(basename(@__FILE__))[1],
        ),
    )
end

function _edge_display_or_return(dst, fig)
    if fig
        imshow(dst)
        return nothing
    end
    return dst
end

function _edge_parameter_error()
    return error(_msg(@tr("Invalid input parameters."), splitext(basename(@__FILE__))[1]))
end

function _edge_direction_error(direction)
    return error(
        _msg(
            @tr(
                "Edge detection direction %{1} does not exist. Valid directions are %{2}.",
                direction,
                dir_strs,
            ),
            splitext(basename(@__FILE__))[1],
        ),
    )
end

_edge_float_image(img::AbstractMatrix{Bool}) = Float32.(img)
_edge_float_image(img::AbstractMatrix{UInt8}) = Float32.(img) ./ 255.0f0
_edge_float_image(img::AbstractMatrix{UInt16}) = Float32.(img) ./ 65535.0f0
_edge_float_image(img::AbstractMatrix{Int16}) = (Float32.(img) .+ 32768.0f0) ./ 65535.0f0
_edge_float_image(img::AbstractMatrix{Float32}) = Float32.(img)
_edge_float_image(img::AbstractMatrix{Float64}) = Float64.(img)

function edge_sobel(img, direction, threshold=nothing)
    return _edge_gradient3_method(img, true, direction, threshold)
end

function edge_prewitt(img, direction, threshold=nothing)
    return _edge_gradient3_method(img, false, direction, threshold)
end

function edge_roberts(img, direction, threshold=nothing)
    kernel_x = [1.0 0.0; 0.0 -1.0] ./ 2.0
    kernel_y = [0.0 1.0; -1.0 0.0] ./ 2.0
    return _edge_gradient_method(
        img, kernel_x, kernel_y, direction, threshold, 6.0, (-1, 1, 1, -1)
    )
end

function _edge_gradient3_method(img, is_sobel, direction, threshold)
    src = _edge_float_image(img)
    rows, cols = size(src)
    gradient_x = similar(src)
    gradient_y = similar(src)
    magnitude_squared = similar(src)
    T = eltype(src)
    side_weight = is_sobel ? T(1 / 8) : T(1 / 6)
    center_weight = is_sobel ? T(1 / 4) : side_weight
    kx = direction == "horizontal" ? zero(T) : one(T)
    ky = direction == "vertical" ? zero(T) : one(T)

    @inbounds for col in 1:cols
        left = max(1, col - 1)
        right = min(cols, col + 1)
        for row in 1:rows
            top = max(1, row - 1)
            bottom = min(rows, row + 1)

            gx = zero(T)
            gx += side_weight * src[top, left]
            gx += center_weight * src[row, left]
            gx += side_weight * src[bottom, left]
            gx -= side_weight * src[top, right]
            gx -= center_weight * src[row, right]
            gx -= side_weight * src[bottom, right]

            gy = zero(T)
            gy += side_weight * src[top, left]
            gy -= side_weight * src[bottom, left]
            gy += center_weight * src[top, col]
            gy -= center_weight * src[bottom, col]
            gy += side_weight * src[top, right]
            gy -= side_weight * src[bottom, right]

            gradient_x[row, col] = gx
            gradient_y[row, col] = gy
            magnitude_squared[row, col] = kx * gx * gx + ky * gy * gy
        end
    end

    cutoff = if _edge_threshold_isempty(threshold)
        4 * sum(magnitude_squared) / length(magnitude_squared)
    else
        threshold_value = _edge_scalar_threshold(threshold)
        threshold_value * threshold_value
    end
    return _edge_compute_gradient_edges(
        magnitude_squared, gradient_x, gradient_y, kx, ky, (0, 0, 0, 0), cutoff
    )
end

function _edge_gradient_method(img, kernel_x, kernel_y, direction, threshold, scale, offset)
    src = _edge_float_image(img)
    kernel_x = eltype(src).(kernel_x)
    kernel_y = eltype(src).(kernel_y)
    gradient_x = _edge_filter2_replicate(src, kernel_x)
    gradient_y = _edge_filter2_replicate(src, kernel_y)

    kx = direction == "horizontal" ? 0.0 : 1.0
    ky = direction == "vertical" ? 0.0 : 1.0
    magnitude_squared = @. kx * gradient_x * gradient_x + ky * gradient_y * gradient_y

    cutoff = if _edge_threshold_isempty(threshold)
        scale * sum(magnitude_squared) / length(magnitude_squared)
    else
        threshold_value = _edge_scalar_threshold(threshold)
        threshold_value * threshold_value
    end
    return _edge_compute_gradient_edges(
        magnitude_squared, gradient_x, gradient_y, kx, ky, offset, cutoff
    )
end

function _edge_compute_gradient_edges(
    magnitude, gradient_x, gradient_y, kx, ky, offset, cutoff
)
    rows, cols = size(magnitude)
    result = falses(rows, cols)
    tolerance = 100 * eps(Float64)

    @inbounds for col in 1:cols, row in 1:rows
        value = magnitude[row, col]
        value > cutoff || continue

        row1 = row + offset[1]
        row2 = row + offset[2]
        col3 = col + offset[3]
        col4 = col + offset[4]
        b1 = row1 < 1 || row1 > rows || col == 1 || magnitude[row1, col - 1] <= value
        b2 = row2 < 1 || row2 > rows || col == cols || value > magnitude[row2, col + 1]
        b3 = col3 < 1 || col3 > cols || row == 1 || magnitude[row - 1, col3] <= value
        b4 = col4 < 1 || col4 > cols || row == rows || value > magnitude[row + 1, col4]

        abs_x = abs(gradient_x[row, col])
        abs_y = abs(gradient_y[row, col])
        result[row, col] =
            (abs_x >= kx * abs_y - tolerance && b1 && b2) ||
            (abs_y >= ky * abs_x - tolerance && b3 && b4)
    end
    return result
end

function edge_canny(img, threshold, sigma)
    sigma > 0 || throw(ArgumentError("sigma must be positive"))
    src = _edge_float_image(img)
    gradient_x, gradient_y = smoothGradient(src, sigma)
    magnitude = hypot.(gradient_x, gradient_y)
    maximum_magnitude = isempty(magnitude) ? 0.0 : maximum(magnitude)
    if maximum_magnitude > 0
        magnitude ./= maximum_magnitude
    end

    low_threshold, high_threshold = selectThresholds(threshold, magnitude, 0.7, 0.4)
    thinned = _edge_nonmaximum_suppression(magnitude, gradient_x, gradient_y)
    weak = thinned .> low_threshold
    strong = thinned .> high_threshold
    return _edge_hysteresis(weak, strong), low_threshold, high_threshold
end

function smoothGradient(img, sigma)
    filter_extent = ceil(Int, 4 * sigma)
    x = collect((-filter_extent):filter_extent)
    gaussian = @. exp(-(x * x) / (2 * sigma * sigma))
    gaussian ./= sum(gaussian)

    derivative = _edge_gradient_1d(gaussian)
    negative = derivative .< 0
    positive = derivative .> 0
    derivative[negative] ./= abs(sum(derivative[negative]))
    derivative[positive] ./= sum(derivative[positive])

    gradient_x = _edge_filter_axis_replicate(img, gaussian, 1)
    gradient_x = _edge_filter_axis_replicate(gradient_x, derivative, 2)
    gradient_y = _edge_filter_axis_replicate(img, gaussian, 2)
    gradient_y = _edge_filter_axis_replicate(gradient_y, derivative, 1)
    return gradient_x, gradient_y
end

function _edge_gradient_1d(values)
    result = similar(values)
    n = length(values)
    result[1] = values[2] - values[1]
    result[n] = values[n] - values[n - 1]
    @inbounds for i in 2:(n - 1)
        result[i] = (values[i + 1] - values[i - 1]) / 2
    end
    return result
end

function selectThresholds(threshold, magnitude, percent_not_edges, threshold_ratio)
    if _edge_threshold_isempty(threshold)
        counts = zeros(Int, 64)
        @inbounds for value in magnitude
            bin = clamp(floor(Int, value * 63 + 0.5) + 1, 1, 64)
            counts[bin] += 1
        end
        target = percent_not_edges * length(magnitude)
        cumulative = 0
        high_threshold = 1.0
        @inbounds for i in eachindex(counts)
            cumulative += counts[i]
            if cumulative > target
                high_threshold = i / 64
                break
            end
        end
        low_threshold = threshold_ratio * high_threshold
    elseif _edge_threshold_length(threshold) == 1
        high_threshold = _edge_scalar_threshold(threshold)
        high_threshold < 1 || error(
            _msg(
                @tr("Given single threshold is out of range (0,1)."),
                splitext(basename(@__FILE__))[1],
            ),
        )
        low_threshold = threshold_ratio * high_threshold
    elseif _edge_threshold_length(threshold) == 2
        low_threshold = Float64(threshold[1])
        high_threshold = Float64(threshold[2])
        (low_threshold < high_threshold && high_threshold < 1) || error(
            _msg(
                @tr("Given thresholds are out of range (0,1)."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    else
        _edge_parameter_error()
    end
    return Float64(low_threshold), Float64(high_threshold)
end

function _edge_threshold_isempty(threshold)
    return isnothing(threshold) || (threshold isa AbstractArray && isempty(threshold))
end
_edge_threshold_length(threshold::Real) = 1
_edge_threshold_length(threshold) = length(threshold)
_edge_scalar_threshold(threshold::Real) = Float64(threshold)
function _edge_scalar_threshold(threshold)
    _edge_threshold_length(threshold) == 1 || _edge_parameter_error()
    return Float64(first(threshold))
end

function edge_log(img, threshold=nothing, sigma=2.0)
    return edge_zerocross(img, threshold, sigma)
end

function edge_zerocross(img, threshold=nothing, sigma=2.0)
    sigma > 0 || throw(ArgumentError("sigma must be positive"))
    src = _edge_float_image(img)
    kernel = _edge_log_kernel(sigma)
    response = _edge_filter2_replicate(src, kernel)
    threshold_value = if _edge_threshold_isempty(threshold)
        0.75 * sum(abs, response) / length(response)
    else
        _edge_scalar_threshold(threshold)
    end
    return _edge_zero_crossings(response, threshold_value)
end

function _edge_log_kernel(sigma)
    radius = ceil(Int, 3 * sigma)
    n = 2 * radius + 1
    kernel = Matrix{Float64}(undef, n, n)
    sigma_squared = sigma * sigma
    @inbounds for j in 1:n, i in 1:n
        y = i - radius - 1
        x = j - radius - 1
        radius_squared = x * x + y * y
        kernel[i, j] = exp(-radius_squared / (2 * sigma_squared))
    end
    maximum_value = maximum(kernel)
    kernel[kernel .< eps(Float64) * maximum_value] .= 0
    kernel ./= sum(kernel)
    @inbounds for j in 1:n, i in 1:n
        y = i - radius - 1
        x = j - radius - 1
        kernel[i, j] *=
            (x * x + y * y - 2 * sigma_squared) / (sigma_squared * sigma_squared)
    end
    kernel .-= sum(kernel) / length(kernel)
    return kernel
end

function _edge_zero_crossings(response, threshold)
    rows, cols = size(response)
    result = falses(rows, cols)
    (rows < 3 || cols < 3) && return result

    @inbounds for col in 2:(cols - 1), row in 2:(rows - 1)
        center = response[row, col]
        if center < 0
            result[row, col] =
                (
                    response[row, col + 1] > 0 &&
                    abs(center - response[row, col + 1]) > threshold
                ) ||
                (
                    response[row, col - 1] > 0 &&
                    abs(center - response[row, col - 1]) > threshold
                ) ||
                (
                    response[row + 1, col] > 0 &&
                    abs(center - response[row + 1, col]) > threshold
                ) ||
                (
                    response[row - 1, col] > 0 &&
                    abs(center - response[row - 1, col]) > threshold
                )
        elseif center == 0
            result[row, col] =
                (
                    response[row - 1, col] < 0 < response[row + 1, col] &&
                    abs(response[row - 1, col] - response[row + 1, col]) > 2 * threshold
                ) ||
                (
                    response[row - 1, col] > 0 > response[row + 1, col] &&
                    abs(response[row - 1, col] - response[row + 1, col]) > 2 * threshold
                ) ||
                (
                    response[row, col - 1] < 0 < response[row, col + 1] &&
                    abs(response[row, col - 1] - response[row, col + 1]) > 2 * threshold
                ) ||
                (
                    response[row, col - 1] > 0 > response[row, col + 1] &&
                    abs(response[row, col - 1] - response[row, col + 1]) > 2 * threshold
                )
        end
    end
    return result
end

function _edge_nonmaximum_suppression(magnitude, gradient_x, gradient_y)
    rows, cols = size(magnitude)
    result = zeros(Float64, rows, cols)
    (rows < 3 || cols < 3) && return result

    @inbounds for col in 2:(cols - 1), row in 2:(rows - 1)
        value = magnitude[row, col]
        value == 0 && continue
        gx = gradient_x[row, col]
        gy = gradient_y[row, col]
        abs_x = abs(gx)
        abs_y = abs(gy)
        step_col = gx < 0 ? -1 : 1
        step_row = gy < 0 ? -1 : 1

        before, after = if abs_x >= abs_y
            weight = abs_x == 0 ? 0.0 : abs_y / abs_x
            forward =
                (1 - weight) * magnitude[row, col + step_col] +
                weight * magnitude[row + step_row, col + step_col]
            backward =
                (1 - weight) * magnitude[row, col - step_col] +
                weight * magnitude[row - step_row, col - step_col]
            backward, forward
        else
            weight = abs_x / abs_y
            forward =
                (1 - weight) * magnitude[row + step_row, col] +
                weight * magnitude[row + step_row, col + step_col]
            backward =
                (1 - weight) * magnitude[row - step_row, col] +
                weight * magnitude[row - step_row, col - step_col]
            backward, forward
        end
        if value >= before && value >= after
            result[row, col] = value
        end
    end
    return result
end

function _edge_hysteresis(weak, strong)
    result = BitMatrix(strong)
    queue = findall(result)
    index = 1
    rows, cols = size(result)
    while index <= length(queue)
        point = queue[index]
        index += 1
        row, col = Tuple(point)
        @inbounds for next_col in max(1, col - 1):min(cols, col + 1)
            for next_row in max(1, row - 1):min(rows, row + 1)
                if weak[next_row, next_col] && !result[next_row, next_col]
                    result[next_row, next_col] = true
                    push!(queue, CartesianIndex(next_row, next_col))
                end
            end
        end
    end
    return result
end

function _edge_filter_axis_replicate(input, kernel, dimension)
    rows, cols = size(input)
    radius = (length(kernel) - 1) ÷ 2
    output = similar(input, rows, cols)
    if dimension == 1
        @inbounds for col in 1:cols, row in 1:rows
            value = zero(eltype(input))
            for k in eachindex(kernel)
                source_row = clamp(row + k - radius - 1, 1, rows)
                value += eltype(input)(kernel[k]) * input[source_row, col]
            end
            output[row, col] = value
        end
    else
        @inbounds for col in 1:cols, row in 1:rows
            value = zero(eltype(input))
            for k in eachindex(kernel)
                source_col = clamp(col + k - radius - 1, 1, cols)
                value += eltype(input)(kernel[k]) * input[row, source_col]
            end
            output[row, col] = value
        end
    end
    return output
end

function _edge_filter2_replicate(input, kernel)
    rows, cols = size(input)
    kernel_rows, kernel_cols = size(kernel)
    row_radius = (kernel_rows - 1) ÷ 2
    col_radius = (kernel_cols - 1) ÷ 2
    output = similar(input, rows, cols)
    @inbounds for col in 1:cols, row in 1:rows
        value = zero(eltype(input))
        for kernel_col in 1:kernel_cols, kernel_row in 1:kernel_rows
            source_row = clamp(row + kernel_row - row_radius - 1, 1, rows)
            source_col = clamp(col + kernel_col - col_radius - 1, 1, cols)
            value +=
                eltype(input)(kernel[kernel_row, kernel_col]) *
                input[source_row, source_col]
        end
        output[row, col] = value
    end
    return output
end
