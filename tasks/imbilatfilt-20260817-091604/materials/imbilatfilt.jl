"""
imbilatfilt - 高斯核图像的双边滤波

J = imbilatfilt(I)

J = imbilatfilt(I,degreeOfSmoothing)

J = imbilatfilt(I,degreeOfSmoothing,spatialSigma)

J = imbilatfilt(I,degreeOfSmoothing,spatialSigma,neighborhoodSize)
"""
function imbilatfilt(
    I::AbstractArray{T,N}
) where {T<:Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,Float32,Float64},N}
    degreeOfSmoothing = 0.01 * diff(getrangefromclass(I))[1]^2
    return imbilatfilt(I, degreeOfSmoothing)
end

function imbilatfilt(
    I::AbstractArray{T,N}, degreeOfSmoothing::Real
) where {T<:Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,Float32,Float64},N}
    _imbilat_validate_smoothing(degreeOfSmoothing)
    return imbilatfilt(I, degreeOfSmoothing, 1)
end

function imbilatfilt(
    I::AbstractArray{T,N}, degreeOfSmoothing::Real, spatialSigma::Real
) where {T<:Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,Float32,Float64},N}
    _imbilat_validate_smoothing(degreeOfSmoothing)
    _imbilat_validate_spatial_sigma(spatialSigma)
    neighborhoodSize = 2 * ceil(Int, 2 * spatialSigma) + 1
    return imbilatfilt(I, degreeOfSmoothing, spatialSigma, neighborhoodSize)
end

function imbilatfilt(
    I::AbstractArray{T,N},
    degreeOfSmoothing::Real,
    spatialSigma::Real,
    neighborhoodSize::Real,
) where {T<:Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,Float32,Float64},N}
    @ccall_check_func_lic :TyImageProcessing
    _imbilat_validate_image(I)
    _imbilat_validate_smoothing(degreeOfSmoothing)
    _imbilat_validate_spatial_sigma(spatialSigma)
    n = _imbilat_validate_neighborhood(I, neighborhoodSize)

    spatial_weights = _imbilat_spatial_weights(n, Float64(spatialSigma))
    output = Array{T,N}(undef, size(I))
    if N == 2
        _imbilat_grayscale!(output, I, spatial_weights, Float64(degreeOfSmoothing))
    else
        _imbilat_color!(output, I, spatial_weights, Float64(degreeOfSmoothing))
    end
    return output
end

function _imbilat_validate_image(I)
    if ndims(I) != 2 && !(ndims(I) == 3 && size(I, 3) == 3)
        error(
            _msg(
                @tr("Input image must be a 2-D grayscale image or an M-by-N-by-3 image."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    isempty(I) &&
        error(_msg(@tr("Input image must be nonempty."), splitext(basename(@__FILE__))[1]))
    return nothing
end

function _imbilat_validate_smoothing(value)
    if !isfinite(value) || value <= 0
        error(
            _msg(
                @tr(
                    "Invalid value for 'DegreeOfSmoothing'. DegreeOfSmoothing must be positive."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    return nothing
end

function _imbilat_validate_spatial_sigma(value)
    if !isfinite(value) || value <= 0
        error(
            _msg(
                @tr("Invalid value for 'SpatialSigma'. SpatialSigma must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    return nothing
end

function _imbilat_validate_neighborhood(I, value)
    if !isfinite(value) || value <= 0
        error(
            _msg(
                @tr("NeighborhoodSize must be positive."), splitext(basename(@__FILE__))[1]
            ),
        )
    end
    if !isinteger(value)
        error(
            _msg(
                @tr("NeighborhoodSize must be an integer."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    n = Int(value)
    if !isodd(n)
        error(_msg(@tr("NeighborhoodSize must be odd."), splitext(basename(@__FILE__))[1]))
    end
    if min(size(I, 1), size(I, 2)) < n
        error(
            _msg(
                @tr("Input image size must be greater than NeighborhoodSize (%{1}).", n),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    return n
end

function _imbilat_spatial_weights(n::Int, sigma::Float64)
    radius = n >> 1
    denominator = 2 * sigma * sigma
    weights = Matrix{Float64}(undef, n, n)
    total = 0.0
    @inbounds for x in (-radius):radius
        for y in (-radius):radius
            weight = exp(-(x * x + y * y) / denominator)
            weights[y + radius + 1, x + radius + 1] = weight
            total += weight
        end
    end
    weights ./= total
    return weights
end

function _imbilat_grayscale!(
    output::AbstractMatrix{T},
    input::AbstractMatrix{T},
    spatial_weights::Matrix{Float64},
    degree_of_smoothing::Float64,
) where {T}
    if T === UInt8 && size(spatial_weights, 1) == 5
        return _imbilat_grayscale_u8_5x5!(
            output, input, spatial_weights, degree_of_smoothing
        )
    elseif T === UInt16 && size(spatial_weights, 1) == 5
        return _imbilat_grayscale_u16_5x5!(
            output, input, spatial_weights, degree_of_smoothing
        )
    end
    range_weights = _imbilat_gray_range_weights(T, degree_of_smoothing)
    if Threads.nthreads() > 1 && length(input) >= 65536
        Threads.@threads :static for column in 1:size(input, 2)
            _imbilat_grayscale_column!(
                output, input, spatial_weights, range_weights, degree_of_smoothing, column
            )
        end
    else
        @inbounds for column in 1:size(input, 2)
            _imbilat_grayscale_column!(
                output, input, spatial_weights, range_weights, degree_of_smoothing, column
            )
        end
    end
    return output
end

function _imbilat_grayscale_u8_5x5!(
    output::AbstractMatrix{UInt8},
    input::AbstractMatrix{UInt8},
    spatial_weights::Matrix{Float64},
    degree_of_smoothing::Float64,
)
    rows, columns = size(input)
    padded_rows = rows + 4
    padded = Matrix{UInt8}(undef, padded_rows, columns + 4)

    # Build replicate padding once so the hot pixel loop has no bounds clamping.
    @inbounds for column in 1:(columns + 4)
        source_column = clamp(column - 2, 1, columns)
        destination_offset = (column - 1) * padded_rows
        source_offset = (source_column - 1) * rows
        first_value = input[source_offset + 1]
        last_value = input[source_offset + rows]
        padded[destination_offset + 1] = first_value
        padded[destination_offset + 2] = first_value
        copyto!(padded, destination_offset + 3, input, source_offset + 1, rows)
        padded[destination_offset + rows + 3] = last_value
        padded[destination_offset + rows + 4] = last_value
    end

    denominator = 2 * degree_of_smoothing
    combined_weights = Matrix{Float32}(undef, 256, 25)
    neighbor_offsets = Vector{Int}(undef, 25)
    neighbor_index = 1
    @inbounds for xoffset in -2:2
        for yoffset in -2:2
            neighbor_offsets[neighbor_index] = yoffset + xoffset * padded_rows
            spatial_weight = spatial_weights[yoffset + 3, xoffset + 3]
            for difference in 0:255
                combined_weights[difference + 1, neighbor_index] = Float32(
                    spatial_weight * exp(-(difference * difference) / denominator)
                )
            end
            neighbor_index += 1
        end
    end

    if Threads.nthreads() > 1 && length(input) >= 65536
        Threads.@threads :static for column in 1:columns
            _imbilat_grayscale_u8_5x5_column!(
                output,
                input,
                padded,
                combined_weights,
                neighbor_offsets,
                rows,
                padded_rows,
                column,
            )
        end
    else
        @inbounds for column in 1:columns
            _imbilat_grayscale_u8_5x5_column!(
                output,
                input,
                padded,
                combined_weights,
                neighbor_offsets,
                rows,
                padded_rows,
                column,
            )
        end
    end
    return output
end

function _imbilat_grayscale_u8_5x5_column!(
    output::AbstractMatrix{UInt8},
    input::AbstractMatrix{UInt8},
    padded::Matrix{UInt8},
    combined_weights::Matrix{Float32},
    neighbor_offsets::Vector{Int},
    rows::Int,
    padded_rows::Int,
    column::Int,
)
    input_offset = (column - 1) * rows
    padded_offset = (column + 1) * padded_rows + 2
    @inbounds for row in 1:rows
        center = input[input_offset + row]
        center_integer = Int(center)
        center_index = padded_offset + row
        weighted_sum = 0.0f0
        weight_sum = 0.0f0
        Base.Cartesian.@nexprs 25 neighbor_index -> begin
            neighbor = padded[center_index + neighbor_offsets[neighbor_index]]
            weight = combined_weights[
                abs(Int(neighbor) - center_integer) + 1, neighbor_index
            ]
            weight_sum += weight
            weighted_sum += weight * Float32(neighbor)
        end
        output[input_offset + row] = floor(
            UInt8, clamp(weighted_sum / (weight_sum + eps(Float32)), 0.0f0, 255.0f0)
        )
    end
    return nothing
end

function _imbilat_grayscale_u16_5x5!(
    output::AbstractMatrix{UInt16},
    input::AbstractMatrix{UInt16},
    spatial_weights::Matrix{Float64},
    degree_of_smoothing::Float64,
)
    rows, columns = size(input)
    padded_rows = rows + 4
    padded = Matrix{UInt16}(undef, padded_rows, columns + 4)

    @inbounds for column in 1:(columns + 4)
        source_column = clamp(column - 2, 1, columns)
        destination_offset = (column - 1) * padded_rows
        source_offset = (source_column - 1) * rows
        first_value = input[source_offset + 1]
        last_value = input[source_offset + rows]
        padded[destination_offset + 1] = first_value
        padded[destination_offset + 2] = first_value
        copyto!(padded, destination_offset + 3, input, source_offset + 1, rows)
        padded[destination_offset + rows + 3] = last_value
        padded[destination_offset + rows + 4] = last_value
    end

    neighbor_offsets = Vector{Int}(undef, 25)
    spatial_weight_vector = Vector{Float64}(undef, 25)
    neighbor_index = 1
    @inbounds for xoffset in -2:2
        for yoffset in -2:2
            neighbor_offsets[neighbor_index] = yoffset + xoffset * padded_rows
            spatial_weight_vector[neighbor_index] = spatial_weights[
                yoffset + 3, xoffset + 3
            ]
            neighbor_index += 1
        end
    end

    denominator = 2 * degree_of_smoothing
    # exp(-x) rounds to zero once x exceeds half the least subnormal value.
    exp_zero_limit = -log(nextfloat(0.0)) + log(2.0)
    cutoff_squared = min(65535^2, floor(Int, denominator * exp_zero_limit))
    cutoff_difference = min(65535, isqrt(cutoff_squared))
    range_weights = Vector{Float64}(undef, cutoff_difference + 1)
    @inbounds for difference in 0:cutoff_difference
        range_weights[difference + 1] = exp(-(difference * difference) / denominator)
    end
    identity_threshold = _imbilat_u16_identity_threshold(
        spatial_weights, degree_of_smoothing
    )
    candidates = zeros(UInt8, size(input))
    if identity_threshold < 65535
        _imbilat_mark_u16_candidates!(candidates, input, identity_threshold, rows)
        copyto!(output, input)
    else
        fill!(candidates, 1)
    end

    if Threads.nthreads() > 1 && length(input) >= 65536
        Threads.@threads :static for column in 1:columns
            _imbilat_grayscale_u16_5x5_column!(
                output,
                input,
                padded,
                spatial_weight_vector,
                neighbor_offsets,
                range_weights,
                cutoff_difference,
                candidates,
                rows,
                padded_rows,
                column,
            )
        end
    else
        @inbounds for column in 1:columns
            _imbilat_grayscale_u16_5x5_column!(
                output,
                input,
                padded,
                spatial_weight_vector,
                neighbor_offsets,
                range_weights,
                cutoff_difference,
                candidates,
                rows,
                padded_rows,
                column,
            )
        end
    end
    return output
end

function _imbilat_u16_identity_threshold(
    spatial_weights::Matrix{Float64}, degree_of_smoothing::Float64
)
    center_weight = spatial_weights[3, 3]
    relative_neighbor_weight = (sum(spatial_weights) - center_weight) / center_weight
    denominator = 2 * degree_of_smoothing
    start_difference = max(0, floor(Int, sqrt(degree_of_smoothing)))
    @inbounds for threshold in start_difference:65534
        first_omitted_difference = threshold + 1
        maximum_shift =
            relative_neighbor_weight *
            first_omitted_difference *
            exp(-(first_omitted_difference^2) / denominator)
        maximum_shift < 0.5 && return threshold
    end
    return 65535
end

function _imbilat_mark_u16_candidates!(
    candidates::Matrix{UInt8},
    input::AbstractMatrix{UInt16},
    identity_threshold::Int,
    rows::Int,
)
    columns = size(input, 2)
    reverse_candidates = zeros(UInt8, size(input))
    # Replicate padding makes every pixel in the two-pixel border a candidate.
    @inbounds begin
        for column in 1:columns
            column_offset = (column - 1) * rows
            candidates[column_offset + 1] = 1
            candidates[column_offset + 2] = 1
            candidates[column_offset + rows - 1] = 1
            candidates[column_offset + rows] = 1
        end
        for column in (1, 2, columns - 1, columns)
            column_offset = (column - 1) * rows
            fill!(view(candidates, (column_offset + 1):(column_offset + rows)), 1)
        end
    end

    # Compare each undirected pixel pair once and mark both endpoints.
    @inbounds for xoffset in 0:2
        for yoffset in -2:2
            (xoffset == 0 && yoffset <= 0) && continue
            first_row = max(1, 1 - yoffset)
            last_row = min(rows, rows - yoffset)
            for column in 1:(columns - xoffset)
                first_offset = (column - 1) * rows
                second_offset = (column + xoffset - 1) * rows + yoffset
                @simd for row in first_row:last_row
                    first_index = first_offset + row
                    second_index = second_offset + row
                    difference = abs(Int(input[second_index]) - Int(input[first_index]))
                    is_candidate = UInt8(difference <= identity_threshold)
                    candidates[first_index] |= is_candidate
                    reverse_candidates[second_index] |= is_candidate
                end
            end
        end
    end
    @inbounds @simd for index in eachindex(candidates)
        candidates[index] |= reverse_candidates[index]
    end
    return candidates
end

function _imbilat_grayscale_u16_5x5_column!(
    output::AbstractMatrix{UInt16},
    input::AbstractMatrix{UInt16},
    padded::Matrix{UInt16},
    spatial_weights::Vector{Float64},
    neighbor_offsets::Vector{Int},
    range_weights::Vector{Float64},
    cutoff_difference::Int,
    candidates::Matrix{UInt8},
    rows::Int,
    padded_rows::Int,
    column::Int,
)
    input_offset = (column - 1) * rows
    padded_offset = (column + 1) * padded_rows + 2
    @inbounds for row in 1:rows
        candidates[input_offset + row] == 0 && continue
        center = input[input_offset + row]
        center_integer = Int(center)
        center_index = padded_offset + row
        weighted_sum = 0.0
        weight_sum = 0.0
        Base.Cartesian.@nexprs 25 neighbor_index -> begin
            neighbor = padded[center_index + neighbor_offsets[neighbor_index]]
            difference = Int(neighbor) - center_integer
            absolute_difference = abs(difference)
            if absolute_difference <= cutoff_difference
                weight =
                    spatial_weights[neighbor_index] * range_weights[absolute_difference + 1]
                weight_sum += weight
                weighted_sum += weight * Float64(neighbor)
            end
        end
        output[input_offset + row] = round(
            UInt16,
            clamp(weighted_sum / (weight_sum + eps()), 0.0, 65535.0),
            RoundNearestTiesAway,
        )
    end
    return nothing
end

function _imbilat_grayscale_column!(
    output::AbstractMatrix{T},
    input::AbstractMatrix{T},
    spatial_weights::Matrix{Float64},
    range_weights,
    degree_of_smoothing::Float64,
    column::Int,
) where {T}
    radius = size(spatial_weights, 1) >> 1
    rows, columns = size(input)
    denominator = 2 * degree_of_smoothing
    @inbounds for row in 1:rows
        center = input[row, column]
        center_value = Float64(center)
        weighted_sum = 0.0
        weight_sum = 0.0
        for xoffset in (-radius):radius
            source_column = clamp(column + xoffset, 1, columns)
            wx = xoffset + radius + 1
            for yoffset in (-radius):radius
                source_row = clamp(row + yoffset, 1, rows)
                neighbor = input[source_row, source_column]
                difference = Float64(neighbor) - center_value
                range_weight = if range_weights === nothing
                    exp(-(difference * difference) / denominator)
                else
                    range_weights[abs(Int(neighbor) - Int(center)) + 1]
                end
                weight = spatial_weights[yoffset + radius + 1, wx] * range_weight
                weight_sum += weight
                weighted_sum += weight * Float64(neighbor)
            end
        end
        output[row, column] = _imbilat_cast(T, weighted_sum / (weight_sum + eps()))
    end
    return nothing
end

function _imbilat_color!(
    output::AbstractArray{T,3},
    input::AbstractArray{T,3},
    spatial_weights::Matrix{Float64},
    degree_of_smoothing::Float64,
) where {T}
    range_weights = _imbilat_color_range_weights(T, degree_of_smoothing)
    if Threads.nthreads() > 1 && size(input, 1) * size(input, 2) >= 65536
        Threads.@threads :static for column in 1:size(input, 2)
            _imbilat_color_column!(
                output, input, spatial_weights, range_weights, degree_of_smoothing, column
            )
        end
    else
        @inbounds for column in 1:size(input, 2)
            _imbilat_color_column!(
                output, input, spatial_weights, range_weights, degree_of_smoothing, column
            )
        end
    end
    return output
end

function _imbilat_color_column!(
    output::AbstractArray{T,3},
    input::AbstractArray{T,3},
    spatial_weights::Matrix{Float64},
    range_weights,
    degree_of_smoothing::Float64,
    column::Int,
) where {T}
    radius = size(spatial_weights, 1) >> 1
    rows, columns = size(input, 1), size(input, 2)
    denominator = 2 * degree_of_smoothing
    @inbounds for row in 1:rows
        center1 = input[row, column, 1]
        center2 = input[row, column, 2]
        center3 = input[row, column, 3]
        center1f = Float64(center1)
        center2f = Float64(center2)
        center3f = Float64(center3)
        weighted_sum1 = 0.0
        weighted_sum2 = 0.0
        weighted_sum3 = 0.0
        weight_sum = 0.0
        for xoffset in (-radius):radius
            source_column = clamp(column + xoffset, 1, columns)
            wx = xoffset + radius + 1
            for yoffset in (-radius):radius
                source_row = clamp(row + yoffset, 1, rows)
                neighbor1 = input[source_row, source_column, 1]
                neighbor2 = input[source_row, source_column, 2]
                neighbor3 = input[source_row, source_column, 3]
                difference1 = Float64(neighbor1) - center1f
                difference2 = Float64(neighbor2) - center2f
                difference3 = Float64(neighbor3) - center3f
                squared_distance =
                    difference1 * difference1 +
                    difference2 * difference2 +
                    difference3 * difference3
                range_weight = if range_weights === nothing
                    exp(-squared_distance / denominator)
                else
                    range_weights[Int(squared_distance) + 1]
                end
                weight = spatial_weights[yoffset + radius + 1, wx] * range_weight
                weight_sum += weight
                weighted_sum1 += weight * Float64(neighbor1)
                weighted_sum2 += weight * Float64(neighbor2)
                weighted_sum3 += weight * Float64(neighbor3)
            end
        end
        inverse_weight_sum = inv(weight_sum + eps())
        output[row, column, 1] = _imbilat_cast(T, weighted_sum1 * inverse_weight_sum)
        output[row, column, 2] = _imbilat_cast(T, weighted_sum2 * inverse_weight_sum)
        output[row, column, 3] = _imbilat_cast(T, weighted_sum3 * inverse_weight_sum)
    end
    return nothing
end

function _imbilat_gray_range_weights(::Type{UInt8}, degree_of_smoothing::Float64)
    denominator = 2 * degree_of_smoothing
    return [exp(-(difference * difference) / denominator) for difference in 0:255]
end

_imbilat_gray_range_weights(::Type, ::Float64) = nothing

function _imbilat_color_range_weights(::Type{UInt8}, degree_of_smoothing::Float64)
    denominator = 2 * degree_of_smoothing
    return [exp(-squared_distance / denominator) for squared_distance in 0:(3 * 255^2)]
end

_imbilat_color_range_weights(::Type, ::Float64) = nothing

@inline function _imbilat_cast(::Type{T}, value::Float64) where {T<:Integer}
    return round(
        T, clamp(value, Float64(typemin(T)), Float64(typemax(T))), RoundNearestTiesAway
    )
end

@inline function _imbilat_cast(::Type{UInt8}, value::Float64)
    return floor(UInt8, clamp(value, 0.0, 255.0))
end

@inline _imbilat_cast(::Type{T}, value::Float64) where {T<:AbstractFloat} = T(value)
