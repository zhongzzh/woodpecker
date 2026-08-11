"""
radon - 拉东变换

R, = radon(I)

R, = radon(I,theta)

R,xp = radon(___)
"""
function radon(I::AbstractArray{T,2}) where {T<:Union{Bool,MInteger,MFloat}}
    theta = 0:179
    return radon(I, theta)
end

function radon(
    I::AbstractArray{T,2}, theta::Union{Real,AbstractArray}
) where {T<:Union{Bool,MInteger,MFloat}}
    theta_values = theta isa Real ? (Float64(theta),) : Float64.(vec(theta))
    R, radius = _julia_radon(I, theta_values)
    xp = reshape(Float64.(radius), :, 1)
    return R, xp
end

function _julia_radon(I::AbstractMatrix, theta)
    rows, cols = size(I)
    x_origin = max(1, fld(cols + 1, 2))
    y_origin = max(1, fld(rows + 1, 2))
    radius_last = ceil(Int, hypot(rows - y_origin, cols - x_origin)) + 1
    radius_first = -radius_last
    radius = radius_first:radius_last
    R = zeros(Float64, length(radius), length(theta))

    x_minus = Vector{Float64}(undef, cols)
    x_plus = similar(x_minus)
    y_minus = Vector{Float64}(undef, rows)
    y_plus = similar(y_minus)

    @inbounds for (angle_index, angle) in enumerate(theta)
        if !isfinite(angle)
            R[1:min(2, size(R, 1)), angle_index] .= NaN
            continue
        end

        angle_radians = pi * angle / 180
        cosine = cos(angle_radians)
        sine = sin(angle_radians)

        for col in 1:cols
            x = col - x_origin
            x_minus[col] = (x - 0.25) * cosine
            x_plus[col] = (x + 0.25) * cosine
        end
        for row in 1:rows
            y = y_origin - row
            y_minus[row] = (y - 0.25) * sine
            y_plus[row] = (y + 0.25) * sine
        end

        for col in 1:cols, row in 1:rows
            value = Float64(I[row, col])
            if value != 0
                pixel = 0.25 * value
                _increment_radon!(
                    R, angle_index, pixel, x_minus[col] + y_minus[row], radius_first
                )
                _increment_radon!(
                    R, angle_index, pixel, x_plus[col] + y_minus[row], radius_first
                )
                _increment_radon!(
                    R, angle_index, pixel, x_minus[col] + y_plus[row], radius_first
                )
                _increment_radon!(
                    R, angle_index, pixel, x_plus[col] + y_plus[row], radius_first
                )
            end
        end
    end

    return R, radius
end

@inline function _increment_radon!(R, angle_index, pixel, radius, radius_first)
    position = radius - radius_first + 1
    lower = floor(Int, position)
    fraction = position - lower
    @inbounds begin
        R[lower, angle_index] += pixel * (1 - fraction)
        R[lower + 1, angle_index] += pixel * fraction
    end
    return nothing
end
