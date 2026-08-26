"""
    localtonemap(HDR; RangeCompression=1, EnhanceContrast=0)
    localtonemap(HDR, name, value, ...)

Compress the dynamic range of a nonnegative `Float32` HDR grayscale or RGB image.
`RangeCompression` controls large-scale compression and `EnhanceContrast` controls
local contrast enhancement. Both parameters must be in the interval `[0, 1]`.
"""
function localtonemap(In...; RangeCompression=1, EnhanceContrast=0)
    isempty(In) &&
        error(_msg(@tr("Insufficient number of input arguments."), "localtonemap"))
    length(In) <= 5 || error(_msg(@tr("Too many input arguments."), "localtonemap"))

    HDR = In[1]
    options = In[2:end]
    iseven(length(options)) ||
        error(_msg(@tr("Name-value arguments must occur in pairs."), "localtonemap"))

    rangeCompression = RangeCompression
    enhanceContrast = EnhanceContrast
    for index in 1:2:length(options)
        option = _localtonemap_option_name(options[index])
        if option == :RangeCompression
            rangeCompression = options[index + 1]
        else
            enhanceContrast = options[index + 1]
        end
    end

    _localtonemap_validate_hdr(HDR)
    compression = _localtonemap_unit_scalar(rangeCompression, "RangeCompression")
    enhancement = _localtonemap_unit_scalar(enhanceContrast, "EnhanceContrast")
    return _localtonemap_impl(HDR, compression, enhancement)
end

function _localtonemap_impl(HDR, compression::Float32, enhancement::Float32)
    beta = Float32(1) - compression
    alpha = Float32(1) - Float32(0.99) * enhancement
    numIntensityLevels = enhancement == 0 ? _llf_auto_num_intensity_levels(alpha) : 50
    sigma = log(Float32(2.5))
    epsilon = eps(Float32)
    isRGB = ndims(HDR) == 3

    luminance = isRGB ? _llf_rgb_to_gray_float(HDR) : Matrix{Float32}(HDR)
    logLuminance = similar(luminance)
    @inbounds for index in eachindex(luminance)
        logLuminance[index] = log(luminance[index] + epsilon)
    end

    filteredLog = _localtonemap_llf_core(
        logLuminance, sigma, alpha, beta, numIntensityLevels
    )
    mappedLuminance = similar(filteredLog)
    @inbounds for index in eachindex(filteredLog)
        mappedLuminance[index] = exp(filteredLog[index]) - epsilon
    end

    low, high = _localtonemap_percentiles(mappedLuminance)
    currentDynamicRange = high / low
    currentDynamicRange == 1 && return HDR
    if !isfinite(currentDynamicRange)
        return fill(Float32(NaN), size(HDR))
    end

    exponent = log(Float32(100)) / log(currentDynamicRange)
    invHigh = inv(high)
    gamma = inv(Float32(2.2))

    if isRGB
        output = similar(HDR)
        @inbounds for channel in 1:3, col in axes(HDR, 2), row in axes(HDR, 1)
            tone = max(Float32(0), mappedLuminance[row, col] * invHigh)^exponent
            value = tone * HDR[row, col, channel] / (luminance[row, col] + epsilon)
            output[row, col, channel] = clamp(value, Float32(0), Float32(1))^gamma
        end
        return output
    end

    output = similar(HDR)
    @inbounds for index in eachindex(output)
        value = max(Float32(0), mappedLuminance[index] * invHigh)^exponent
        output[index] = clamp(value, Float32(0), Float32(1))^gamma
    end
    return output
end

function _localtonemap_llf_core(input, sigma, alpha, beta, numIntensityLevels)
    rows, cols = size(input)
    numPyramidLevels = floor(Int, log2(min(rows, cols))) + 1
    minValue, maxValue = extrema(input)

    if minValue == maxValue
        return copy(input)
    end

    inputGaussian = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    inputGaussian[1] = input
    for level in 2:numPyramidLevels
        inputGaussian[level] = _localtonemap_pyrdown(inputGaussian[level - 1])
    end

    outputLaplacian = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    for level in 1:(numPyramidLevels - 1)
        outputLaplacian[level] = zeros(Float32, size(inputGaussian[level]))
    end
    outputLaplacian[end] = copy(inputGaussian[end])

    remappedGaussian = [Matrix{Float32}(undef, size(level)) for level in inputGaussian]
    downTemps = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    for level in 2:numPyramidLevels
        downTemps[level] = Matrix{Float32}(
            undef, size(remappedGaussian[level - 1], 1), size(remappedGaussian[level], 2)
        )
    end
    expanded = [
        Matrix{Float32}(undef, size(inputGaussian[level])) for
        level in 1:(numPyramidLevels - 1)
    ]
    upTemps = [
        Matrix{Float32}(
            undef, size(inputGaussian[level + 1], 1), size(inputGaussian[level], 2)
        ) for level in 1:(numPyramidLevels - 1)
    ]

    delta = (maxValue - minValue) / Float32(numIntensityLevels - 1)
    inverseDelta = inv(delta)
    useRemapLUT = alpha < 1.0f0
    remapLUT, remapLUTScale =
        useRemapLUT ? _localtonemap_build_remap_lut(sigma, alpha) : (Float32[], 0.0f0)
    for sample in 0:(numIntensityLevels - 1)
        reference = minValue + Float32(sample) * delta
        if useRemapLUT
            _localtonemap_remap_lut!(
                remappedGaussian[1], input, reference, sigma, beta, remapLUT, remapLUTScale
            )
        else
            _localtonemap_remap!(remappedGaussian[1], input, reference, sigma, alpha, beta)
        end
        for level in 2:numPyramidLevels
            _localtonemap_pyrdown!(
                remappedGaussian[level], remappedGaussian[level - 1], downTemps[level]
            )
        end
        for level in (numPyramidLevels - 1):-1:1
            _localtonemap_pyrup!(
                expanded[level], remappedGaussian[level + 1], upTemps[level]
            )
            _llf_add_laplacian_contribution!(
                outputLaplacian[level],
                remappedGaussian[level],
                expanded[level],
                inputGaussian[level],
                reference,
                inverseDelta,
            )
        end
    end

    for level in (numPyramidLevels - 1):-1:1
        _localtonemap_pyrup!(expanded[level], outputLaplacian[level + 1], upTemps[level])
        outputLaplacian[level] .+= expanded[level]
    end
    return outputLaplacian[1]
end

function _localtonemap_remap!(output, input, reference, sigma, alpha, beta)
    @inbounds for index in eachindex(input)
        output[index] = _localtonemap_remap_value(
            input[index], reference, sigma, alpha, beta
        )
    end
    return output
end

const _LOCALTONEMAP_REMAP_LUT_LENGTH = 131_073

function _localtonemap_build_remap_lut(sigma, alpha)
    lut = Vector{Float32}(undef, _LOCALTONEMAP_REMAP_LUT_LENGTH)
    step = sigma / Float32(_LOCALTONEMAP_REMAP_LUT_LENGTH - 1)
    @inbounds for index in eachindex(lut)
        magnitude = Float32(index - 1) * step
        lut[index] = _localtonemap_remap_value(magnitude, 0.0f0, sigma, alpha, 1.0f0)
    end
    return lut, inv(step)
end

function _localtonemap_remap_lut!(output, input, reference, sigma, beta, lut, lutScale)
    lastIndex = length(lut)
    @inbounds for index in eachindex(input)
        difference = input[index] - reference
        magnitude = abs(difference)
        mapped = if magnitude >= sigma
            sigma + beta * (magnitude - sigma)
        else
            position = magnitude * lutScale
            lower = min(unsafe_trunc(Int, position) + 1, lastIndex - 1)
            fraction = position - Float32(lower - 1)
            muladd(fraction, lut[lower + 1] - lut[lower], lut[lower])
        end
        output[index] = difference < 0 ? reference - mapped : reference + mapped
    end
    return output
end

@inline function _localtonemap_remap_value(value, reference, sigma, alpha, beta)
    difference = value - reference
    magnitude = abs(difference)
    mapped = if magnitude > sigma
        sigma + beta * (magnitude - sigma)
        # MATLAB blends away the singular slope of x^alpha near zero.
    elseif alpha < 1.0f0 && magnitude < 0.02f0
        if magnitude <= 0.01f0
            magnitude
        else
            powerMapped = sigma * (magnitude / sigma)^alpha
            position = (magnitude - 0.01f0) * 100.0f0
            weight = (position * (2.0f0 - position))^2
            magnitude + weight * (powerMapped - magnitude)
        end
    elseif magnitude == 0
        0.0f0
    elseif alpha == 1.0f0
        magnitude
    else
        sigma * (magnitude / sigma)^alpha
    end
    return difference < 0 ? reference - mapped : reference + mapped
end
function _localtonemap_pyrdown(input)
    output = Matrix{Float32}(undef, (size(input, 1) + 1) >>> 1, (size(input, 2) + 1) >>> 1)
    temp = Matrix{Float32}(undef, size(input, 1), size(output, 2))
    return _localtonemap_pyrdown!(output, input, temp)
end

function _localtonemap_pyrdown!(output, input, temp)
    rows, cols = size(input)
    outRows, outCols = size(output)

    @inbounds if outCols >= 3 && cols >= 5
        for row in 1:rows
            temp[row, 1] =
                0.05f0 * input[row, 2] +
                0.25f0 * input[row, 1] +
                0.4f0 * input[row, 1] +
                0.25f0 * input[row, 2] +
                0.05f0 * input[row, 3]
        end
        for outCol in 2:(outCols - 1)
            center = 2outCol - 1
            @simd for row in 1:rows
                temp[row, outCol] =
                    0.05f0 * input[row, center - 2] +
                    0.25f0 * input[row, center - 1] +
                    0.4f0 * input[row, center] +
                    0.25f0 * input[row, center + 1] +
                    0.05f0 * input[row, center + 2]
            end
        end
        center = 2outCols - 1
        index1 = _localtonemap_symmetric_index(center - 2, cols)
        index2 = _localtonemap_symmetric_index(center - 1, cols)
        index3 = _localtonemap_symmetric_index(center, cols)
        index4 = _localtonemap_symmetric_index(center + 1, cols)
        index5 = _localtonemap_symmetric_index(center + 2, cols)
        @simd for row in 1:rows
            temp[row, outCols] =
                0.05f0 * input[row, index1] +
                0.25f0 * input[row, index2] +
                0.4f0 * input[row, index3] +
                0.25f0 * input[row, index4] +
                0.05f0 * input[row, index5]
        end
    else
        for outCol in 1:outCols
            center = 2outCol - 1
            for row in 1:rows
                temp[row, outCol] =
                    0.05f0 * input[row, _localtonemap_symmetric_index(center - 2, cols)] +
                    0.25f0 * input[row, _localtonemap_symmetric_index(center - 1, cols)] +
                    0.4f0 * input[row, center] +
                    0.25f0 * input[row, _localtonemap_symmetric_index(center + 1, cols)] +
                    0.05f0 * input[row, _localtonemap_symmetric_index(center + 2, cols)]
            end
        end
    end

    @inbounds if outRows >= 3 && rows >= 5
        for col in 1:outCols
            output[1, col] =
                0.05f0 * temp[2, col] +
                0.25f0 * temp[1, col] +
                0.4f0 * temp[1, col] +
                0.25f0 * temp[2, col] +
                0.05f0 * temp[3, col]
            for outRow in 2:(outRows - 1)
                center = 2outRow - 1
                output[outRow, col] =
                    0.05f0 * temp[center - 2, col] +
                    0.25f0 * temp[center - 1, col] +
                    0.4f0 * temp[center, col] +
                    0.25f0 * temp[center + 1, col] +
                    0.05f0 * temp[center + 2, col]
            end
        end
        center = 2outRows - 1
        index1 = _localtonemap_symmetric_index(center - 2, rows)
        index2 = _localtonemap_symmetric_index(center - 1, rows)
        index3 = _localtonemap_symmetric_index(center, rows)
        index4 = _localtonemap_symmetric_index(center + 1, rows)
        index5 = _localtonemap_symmetric_index(center + 2, rows)
        @simd for col in 1:outCols
            output[outRows, col] =
                0.05f0 * temp[index1, col] +
                0.25f0 * temp[index2, col] +
                0.4f0 * temp[index3, col] +
                0.25f0 * temp[index4, col] +
                0.05f0 * temp[index5, col]
        end
    else
        for col in 1:outCols, outRow in 1:outRows
            center = 2outRow - 1
            output[outRow, col] =
                0.05f0 * temp[_localtonemap_symmetric_index(center - 2, rows), col] +
                0.25f0 * temp[_localtonemap_symmetric_index(center - 1, rows), col] +
                0.4f0 * temp[center, col] +
                0.25f0 * temp[_localtonemap_symmetric_index(center + 1, rows), col] +
                0.05f0 * temp[_localtonemap_symmetric_index(center + 2, rows), col]
        end
    end
    return output
end

function _localtonemap_pyrup!(output, input, temp)
    inRows, inCols = size(input)
    outRows, outCols = size(output)
    @inbounds for outCol in 1:outCols
        if iseven(outCol)
            index = outCol >>> 1
            if index < inCols
                @simd for row in 1:inRows
                    temp[row, outCol] = 0.5f0 * (input[row, index] + input[row, index + 1])
                end
            else
                @simd for row in 1:inRows
                    temp[row, outCol] = input[row, inCols]
                end
            end
        else
            index = (outCol + 1) >>> 1
            leftIndex = max(index - 1, 1)
            rightIndex = min(index + 1, inCols)
            @simd for row in 1:inRows
                temp[row, outCol] =
                    0.1f0 * input[row, leftIndex] +
                    0.8f0 * input[row, index] +
                    0.1f0 * input[row, rightIndex]
            end
        end
    end
    @inbounds for col in 1:outCols
        for outRow in 1:outRows
            if iseven(outRow)
                index = outRow >>> 1
                output[outRow, col] = if index < inRows
                    0.5f0 * (temp[index, col] + temp[index + 1, col])
                else
                    temp[inRows, col]
                end
            else
                index = (outRow + 1) >>> 1
                above = temp[max(index - 1, 1), col]
                below = temp[min(index + 1, inRows), col]
                output[outRow, col] =
                    0.1f0 * above + 0.8f0 * temp[index, col] + 0.1f0 * below
            end
        end
    end
    return output
end
function _localtonemap_symmetric_index(index, dimension)
    index < 1 && return 1 - index
    index > dimension && return 2 * dimension + 1 - index
    return index
end
function _localtonemap_percentiles(values)
    sorted = sort!(vec(copy(values)))
    n = count(!isnan, sorted)
    n == 0 && return (Float32(NaN), Float32(NaN))
    return (
        _localtonemap_percentile(sorted, n, Float32(0.5)),
        _localtonemap_percentile(sorted, n, Float32(99.5)),
    )
end

function _localtonemap_percentile(sorted, n, percentile::Float32)
    rank = percentile / Float32(100) * Float32(n)
    lower = floor(Int, rank + Float32(0.5))
    fraction = rank - Float32(lower)
    upper = min(lower + 1, n)
    lower = clamp(lower, 1, n)
    x0 = sorted[lower]
    x1 = sorted[upper]
    (fraction == Float32(-0.5) || x0 == x1) && return x0
    return (Float32(0.5) - fraction) * x0 + (Float32(0.5) + fraction) * x1
end

function _localtonemap_validate_hdr(HDR)
    HDR isa AbstractArray || error(_msg(@tr("HDR must be an array."), "localtonemap"))
    isempty(HDR) && error(_msg(@tr("HDR must be nonempty."), "localtonemap"))
    eltype(HDR) == Float32 ||
        error(_msg(@tr("HDR must have element type Float32."), "localtonemap"))
    isGray = ndims(HDR) == 2
    isRGB = ndims(HDR) == 3 && size(HDR, 3) == 3
    (isGray || isRGB) ||
        error(_msg(@tr("HDR is not a grayscale or RGB image."), "localtonemap"))
    any(value -> value < Float32(0), HDR) &&
        error(_msg(@tr("HDR must contain only nonnegative values."), "localtonemap"))
    return nothing
end

function _localtonemap_unit_scalar(value, name)
    scalar = _llf_unwrap_scalar(value, name)
    (scalar isa Real && !(scalar isa Bool)) ||
        error(_msg(@tr("%{1} must be a numeric real scalar.", name), "localtonemap"))
    isfinite(Float64(scalar)) ||
        error(_msg(@tr("%{1} must be finite.", name), "localtonemap"))
    0 <= scalar <= 1 ||
        error(_msg(@tr("%{1} must be between 0 and 1.", name), "localtonemap"))
    return Float32(scalar)
end

function _localtonemap_option_name(value)
    value isa Union{AbstractString,Symbol} ||
        error(_msg(@tr("Unknown parameter name: %{1}.", string(value)), "localtonemap"))
    name = lowercase(String(value))
    isRangeCompression = startswith("rangecompression", name)
    isEnhanceContrast = startswith("enhancecontrast", name)
    isRangeCompression == isEnhanceContrast &&
        error(_msg(@tr("Unknown parameter name: %{1}.", string(value)), "localtonemap"))
    return isRangeCompression ? :RangeCompression : :EnhanceContrast
end

function _localtonemap_precompile()
    try
        precompile(localtonemap, (Array{Float32,3}, String, Float64))
        precompile(localtonemap, (Array{Float32,3}, String, Float64, String, Float64))
        precompile(_localtonemap_impl, (Array{Float32,3}, Float32, Float32))
        precompile(_localtonemap_impl, (Matrix{Float32}, Float32, Float32))
        precompile(
            _localtonemap_llf_core, (Matrix{Float32}, Float32, Float32, Float32, Int64)
        )
        precompile(
            _localtonemap_remap!,
            (Matrix{Float32}, Matrix{Float32}, Float32, Float32, Float32, Float32),
        )
        precompile(_localtonemap_build_remap_lut, (Float32, Float32))
        precompile(
            _localtonemap_remap_lut!,
            (
                Matrix{Float32},
                Matrix{Float32},
                Float32,
                Float32,
                Float32,
                Vector{Float32},
                Float32,
            ),
        )
        precompile(_localtonemap_pyrdown, (Matrix{Float32},))
        precompile(
            _localtonemap_pyrdown!, (Matrix{Float32}, Matrix{Float32}, Matrix{Float32})
        )
        precompile(
            _localtonemap_pyrup!, (Matrix{Float32}, Matrix{Float32}, Matrix{Float32})
        )
        precompile(_localtonemap_percentiles, (Matrix{Float32},))
        precompile(_localtonemap_validate_hdr, (Array{Float32,3},))
        precompile(_localtonemap_validate_hdr, (Matrix{Float32},))
        precompile(_localtonemap_unit_scalar, (Float64, String))
        precompile(_localtonemap_option_name, (String,))
        precompile(_localtonemap_option_name, (Symbol,))

        if isdefined(Core, :kwcall)
            kwcall = getfield(Core, :kwcall)
            precompile(
                Tuple{
                    typeof(kwcall),
                    NamedTuple{(:RangeCompression,),Tuple{Float64}},
                    typeof(localtonemap),
                    Array{Float32,3},
                },
            )
            precompile(
                Tuple{
                    typeof(kwcall),
                    NamedTuple{
                        (:RangeCompression, :EnhanceContrast),Tuple{Float64,Float64}
                    },
                    typeof(localtonemap),
                    Array{Float32,3},
                },
            )
        end
    catch
    end
    return nothing
end

_localtonemap_precompile()
