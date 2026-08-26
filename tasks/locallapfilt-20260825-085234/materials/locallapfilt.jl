"""
    locallapfilt(I, sigma, alpha[, beta]; ColorMode="luminance", NumIntensityLevels="auto")

Fast local Laplacian filtering for grayscale or RGB images. `sigma` controls the
edge amplitude threshold, `alpha` controls local detail smoothing/enhancement,
and `beta` controls larger-scale dynamic range. Supported image element types
match MATLAB: `Float32`, `UInt8`, `UInt16`, `Int8`, and `Int16`.
"""
function locallapfilt(
    I::AbstractArray,
    sigma::Real,
    alpha::Real;
    ColorMode="luminance",
    NumIntensityLevels="auto",
)
    return _locallapfilt_direct(I, sigma, alpha, 1, ColorMode, NumIntensityLevels)
end

function locallapfilt(
    I::AbstractArray,
    sigma::Real,
    alpha::Real,
    beta::Real;
    ColorMode="luminance",
    NumIntensityLevels="auto",
)
    return _locallapfilt_direct(I, sigma, alpha, beta, ColorMode, NumIntensityLevels)
end

function locallapfilt(In...; ColorMode="luminance", NumIntensityLevels="auto")
    positional, colorMode, numIntensityLevels = _llf_parse_call_args(
        In, ColorMode, NumIntensityLevels
    )
    return internal_locallapfilt(
        positional; ColorMode=colorMode, NumIntensityLevels=numIntensityLevels
    )
end

function internal_locallapfilt(varargin; ColorMode, NumIntensityLevels)
    inputs = locallapfilt_parseInputs(varargin; ColorMode, NumIntensityLevels)
    return _llf_execute(inputs)
end

function _locallapfilt_direct(A, sigma, alpha, beta, ColorMode, NumIntensityLevels)
    inputs = locallapfilt_parseInputs(
        (A, sigma, alpha, beta); ColorMode, NumIntensityLevels
    )
    return _llf_execute(inputs)
end

function _llf_execute(inputs)
    input = inputs.A
    sigma = inputs.sigma
    alpha = inputs.alpha
    beta = inputs.beta
    processLuminance = inputs.ProcessLuminance
    numIntensityLevels = inputs.NumIntensityLevels

    rows, cols = size(input, 1), size(input, 2)
    numPyrLevels = _llf_num_pyramid_levels(rows, cols)

    return llf(
        input, sigma, alpha, beta, numIntensityLevels, processLuminance, numPyrLevels
    )
end
const _LLF_SUPPORTED_IMAGE_TYPES = (Float32, UInt8, UInt16, Int8, Int16)
const _LLF_KERNEL = Float32[0.0625, 0.25, 0.375, 0.25, 0.0625]
const _LLF_UP_KERNEL = Float32[0.125, 0.5, 0.75, 0.5, 0.125]
const _LLF_REMAP_LUT_LENGTH = 8192

function _llf_num_pyramid_levels(rows::Integer, cols::Integer)
    minDim = min(rows, cols)
    return max(2, ceil(Int, log2(minDim)) - 2)
end

function _llf_parse_call_args(args, colorMode, numIntensityLevels)
    positional = Any[]
    i = 1
    while i <= length(args)
        arg = args[i]
        if _llf_is_option_name(arg)
            i < length(args) ||
                error(_msg(@tr("Missing value for name-value argument."), "locallapfilt"))
            value = args[i + 1]
            name = lowercase(String(arg))
            if name == "colormode"
                colorMode = value
            elseif name == "numintensitylevels"
                numIntensityLevels = value
            end
            i += 2
        else
            push!(positional, arg)
            i += 1
        end
    end
    return Tuple(positional), colorMode, numIntensityLevels
end

function _llf_is_option_name(x)
    return x isa Union{AbstractString,Symbol} &&
           lowercase(String(x)) in ("colormode", "numintensitylevels")
end

function locallapfilt_parseInputs(varargin; ColorMode, NumIntensityLevels)
    if length(varargin) < 3
        error(_msg(@tr("Insufficient number of input arguments."), "locallapfilt"))
    elseif length(varargin) > 4
        error(_msg(@tr("Too many input arguments."), "locallapfilt"))
    end

    A = varargin[1]
    _llf_validate_image(A)

    sigma = _llf_scalar_real(varargin[2], "sigma")
    sigma < 0 && error(_msg(@tr("sigma must be nonnegative."), "locallapfilt"))

    alpha = _llf_scalar_real(varargin[3], "alpha")
    alpha <= 0 && error(_msg(@tr("alpha must be positive."), "locallapfilt"))

    beta = length(varargin) == 4 ? _llf_scalar_real(varargin[4], "beta") : 1
    beta < 0 && error(_msg(@tr("beta must be nonnegative."), "locallapfilt"))

    colorMode = _llf_match_string(ColorMode, ("luminance", "separate"), "ColorMode")
    numIntensityLevels = _llf_parse_num_intensity_levels(NumIntensityLevels, Float32(alpha))

    return (
        A=A,
        sigma=Float32(sigma),
        alpha=Float32(alpha),
        beta=Float32(beta),
        ProcessLuminance=(colorMode == "luminance"),
        NumIntensityLevels=numIntensityLevels,
    )
end

function _llf_validate_image(A)
    A isa AbstractArray || error(_msg(@tr("A must be an array."), "locallapfilt"))
    isempty(A) && error(_msg(@tr("A must be nonempty."), "locallapfilt"))

    T = eltype(A)
    any(==(T), _LLF_SUPPORTED_IMAGE_TYPES) ||
        error(_msg(@tr("A has unsupported element type %{1}.", string(T),), "locallapfilt"))

    isGray = ndims(A) == 2
    isRGB = ndims(A) == 3 && size(A, 3) == 3
    (isGray || isRGB) ||
        error(_msg(@tr("A is not a grayscale or RGB image."), "locallapfilt"))
    return nothing
end

function _llf_scalar_real(x, name)
    value = _llf_unwrap_scalar(x, name)
    (value isa Real && !(value isa Bool)) ||
        error(_msg(@tr("%{1} must be a numeric real scalar.", name), "locallapfilt"))
    isfinite(Float64(value)) ||
        error(_msg(@tr("%{1} must be finite.", name), "locallapfilt"))
    return value
end

function _llf_unwrap_scalar(x, name)
    if x isa Number
        return x
    elseif x isa AbstractArray && length(x) == 1
        return first(x)
    end
    return error(_msg(@tr("%{1} must be a scalar.", name), "locallapfilt"))
end

function _llf_match_string(value, valid, name)
    value isa Union{AbstractString,Symbol} ||
        error(_msg(@tr("%{1} must be a string scalar.", name), "locallapfilt"))
    str = lowercase(String(value))
    matches = String[v for v in valid if startswith(v, str)]
    length(matches) == 1 && return matches[1]
    isempty(matches) && error(_msg(@tr("Invalid value for %{1}.", name), "locallapfilt"))
    return error(_msg(@tr("Ambiguous value for %{1}.", name), "locallapfilt"))
end

function _llf_parse_num_intensity_levels(value, alpha::Float32)
    if value isa Union{AbstractString,Symbol}
        _llf_match_string(value, ("auto",), "NumIntensityLevels")
        return _llf_auto_num_intensity_levels(alpha)
    end

    n = _llf_scalar_real(value, "NumIntensityLevels")
    n > 0 || error(_msg(@tr("NumIntensityLevels must be positive."), "locallapfilt"))
    round(n) == n ||
        error(_msg(@tr("NumIntensityLevels must be an integer value."), "locallapfilt"))
    n <= typemax(Int) ||
        error(_msg(@tr("NumIntensityLevels is too large."), "locallapfilt"))
    return Int(n)
end

function _llf_auto_num_intensity_levels(alpha::Float32)
    if alpha < Float32(0.1)
        return 50
    elseif alpha < Float32(0.9)
        return Int(round((Float32(43.4) - Float32(34) * alpha) / Float32(0.8)))
    else
        return 16
    end
end

function llf(
    input, sigma, alpha, beta, numIntensityLevels, processLuminance, numPyramidLevels
)
    if (alpha == 1 && beta == 1) || (sigma == 0 && beta == 1)
        return copy(input)
    end

    isRGB = ndims(input) == 3 && size(input, 3) == 3
    origClass = eltype(input)

    work = _llf_to_float32_image(input, origClass)

    output = if isRGB && processLuminance
        gray = _llf_rgb_to_gray_float(work)
        filtered = llfCore(gray, sigma, alpha, beta, numIntensityLevels, numPyramidLevels)
        if origClass == UInt8
            return _llf_luminance_to_uint8(filtered, work, gray)
        end
        _llf_apply_luminance_ratios(filtered, work, gray)
    elseif isRGB
        out = similar(work, Float32)
        for channel in 1:3
            out[:, :, channel] .= llfCore(
                @view(work[:, :, channel]),
                sigma,
                alpha,
                beta,
                numIntensityLevels,
                numPyramidLevels,
            )
        end
        out
    else
        llfCore(work, sigma, alpha, beta, numIntensityLevels, numPyramidLevels)
    end

    return _llf_cast_output(output, origClass)
end

function _llf_to_float32_image(input, ::Type{UInt8})
    output = Array{Float32}(undef, size(input))
    scale = inv(Float32(255))
    @inbounds for idx in eachindex(input)
        output[idx] = Float32(input[idx]) * scale
    end
    return output
end

function _llf_to_float32_image(input, ::Type{Int8})
    output = Array{Float32}(undef, size(input))
    scale = inv(Float32(255))
    @inbounds for idx in eachindex(input)
        output[idx] = (Float32(input[idx]) + Float32(128)) * scale
    end
    return output
end

function _llf_to_float32_image(input, ::Type{Float32})
    return input isa Array{Float32} ? copy(input) : Array{Float32}(input)
end

_llf_to_float32_image(input, ::Type) = im2single(input)
function _llf_cast_output(output, ::Type{T}) where {T}
    if T == UInt8
        return im2uint8(output)
    elseif T == Int8
        return image_internal_cast(output .* Float32(255) .- Float32(128), Int8)
    elseif T == UInt16
        return im2uint16(output)
    elseif T == Int16
        return im2int16(output)
    elseif T == Float32
        return Float32.(output)
    end
    return output
end

function convertRGBToGrayFloat(input)
    output = _llf_rgb_to_gray_float(input)
    ratios = _llf_luminance_ratios(input, output)
    return output, ratios
end

function _llf_rgb_to_gray_float(input)
    kRCoeff = Float32(0.298936021293776)
    kGCoeff = Float32(0.587043074451121)
    kBCoeff = Float32(0.114020904255103)
    rows, cols = size(input, 1), size(input, 2)
    output = Matrix{Float32}(undef, rows, cols)

    @inbounds for col in 1:cols, row in 1:rows
        output[row, col] =
            kRCoeff * input[row, col, 1] +
            kGCoeff * input[row, col, 2] +
            kBCoeff * input[row, col, 3]
    end
    return output
end

function _llf_luminance_ratios(input, gray)
    rows, cols = size(gray)
    ratios = similar(input, Float32)
    @inbounds for channel in 1:3, col in 1:cols, row in 1:rows
        ratios[row, col, channel] =
            input[row, col, channel] / (gray[row, col] + eps(Float32))
    end
    return ratios
end

function _llf_apply_luminance_ratios(filtered, input, gray)
    rows, cols = size(gray)
    output = similar(input, Float32)
    @inbounds for channel in 1:3, col in 1:cols, row in 1:rows
        output[row, col, channel] =
            filtered[row, col] * input[row, col, channel] / (gray[row, col] + eps(Float32))
    end
    return output
end

function _llf_luminance_to_uint8(filtered, input, gray)
    rows, cols = size(gray)
    output = Array{UInt8}(undef, rows, cols, 3)
    @inbounds for channel in 1:3, col in 1:cols, row in 1:rows
        value =
            filtered[row, col] * input[row, col, channel] / (gray[row, col] + eps(Float32))
        output[row, col, channel] = _llf_float01_to_uint8(value)
    end
    return output
end

@inline function _llf_float01_to_uint8(value)
    if isnan(value) || value <= 0
        return UInt8(0)
    elseif value >= 1
        return UInt8(255)
    end
    return UInt8(round(Int, Float64(value) * 255.0))
end

function llfCore(input, sigma, alpha, beta, numIntensityLevels, numPyramidLevels)
    work = input isa Matrix{Float32} ? input : Matrix{Float32}(input)
    minVal, maxVal = extrema(work)

    if numIntensityLevels == 1
        refVal = (minVal + maxVal) / Float32(2)
        return _llf_remap(work, refVal, sigma, alpha, beta)
    end

    if minVal == maxVal || numPyramidLevels <= 1
        return copy(work)
    end

    inGPyramid = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    inGPyramid[1] = work
    for level in 2:numPyramidLevels
        inGPyramid[level] = _llf_pyrdownsample(inGPyramid[level - 1])
    end

    outLPyramid = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    for level in 1:(numPyramidLevels - 1)
        outLPyramid[level] = zeros(Float32, size(inGPyramid[level]))
    end
    outLPyramid[numPyramidLevels] = copy(inGPyramid[numPyramidLevels])

    rGPyramid = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    for level in 1:numPyramidLevels
        rGPyramid[level] = Matrix{Float32}(undef, size(inGPyramid[level]))
    end

    downTemps = Vector{Matrix{Float32}}(undef, numPyramidLevels)
    for level in 2:numPyramidLevels
        downTemps[level] = Matrix{Float32}(
            undef, size(rGPyramid[level - 1], 1), size(rGPyramid[level], 2)
        )
    end

    expanded = Vector{Matrix{Float32}}(undef, numPyramidLevels - 1)
    upTemps = Vector{Matrix{Float32}}(undef, numPyramidLevels - 1)
    for level in 1:(numPyramidLevels - 1)
        expanded[level] = Matrix{Float32}(undef, size(inGPyramid[level]))
        upTemps[level] = Matrix{Float32}(
            undef, size(inGPyramid[level + 1], 1), size(inGPyramid[level], 2)
        )
    end

    delta = (maxVal - minVal) / Float32(numIntensityLevels - 1)
    invDelta = inv(delta)
    useRemapLut = length(work) >= _LLF_REMAP_LUT_LENGTH && sigma > 0
    remapLut = useRemapLut ? Vector{Float32}(undef, _LLF_REMAP_LUT_LENGTH) : Float32[]
    remapScale =
        useRemapLut ? Float32((_LLF_REMAP_LUT_LENGTH - 1) / (maxVal - minVal)) : Float32(0)
    remapNearRef = useRemapLut ? Float32(2) / remapScale : Float32(0)
    remapIndices, remapFracs = if useRemapLut
        _llf_precompute_remap_lut_positions(work, minVal, remapScale, _LLF_REMAP_LUT_LENGTH)
    else
        (UInt16[], Float32[])
    end

    for k in 0:(numIntensityLevels - 1)
        refVal = minVal + Float32(k) * delta
        if useRemapLut
            _llf_build_remap_lut!(remapLut, minVal, maxVal, refVal, sigma, alpha, beta)
            _llf_remap_lut!(
                rGPyramid[1],
                work,
                remapLut,
                remapIndices,
                remapFracs,
                refVal,
                remapNearRef,
                sigma,
                alpha,
                beta,
            )
        else
            _llf_remap!(rGPyramid[1], work, refVal, sigma, alpha, beta)
        end

        for level in 2:numPyramidLevels
            _llf_pyrdownsample!(rGPyramid[level], rGPyramid[level - 1], downTemps[level])
        end

        for level in (numPyramidLevels - 1):-1:1
            _llf_pyrupsample!(expanded[level], rGPyramid[level + 1], upTemps[level])
            _llf_add_laplacian_contribution!(
                outLPyramid[level],
                rGPyramid[level],
                expanded[level],
                inGPyramid[level],
                refVal,
                invDelta,
            )
        end
    end

    for level in (numPyramidLevels - 1):-1:1
        _llf_pyrupsample!(expanded[level], outLPyramid[level + 1], upTemps[level])
        outLPyramid[level] .+= expanded[level]
    end

    return outLPyramid[1]
end
function _llf_remap(input, refVal::Float32, sigma::Float32, alpha::Float32, beta::Float32)
    output = similar(input, Float32)
    return _llf_remap!(output, input, refVal, sigma, alpha, beta)
end

function _llf_remap!(
    output, input, refVal::Float32, sigma::Float32, alpha::Float32, beta::Float32
)
    if sigma == 0
        @. output = refVal + beta * (input - refVal)
        return output
    end

    @inbounds for idx in eachindex(input)
        output[idx] = _llf_remap_value(input[idx], refVal, sigma, alpha, beta)
    end
    return output
end

@inline function _llf_remap_value(
    x::Float32, refVal::Float32, sigma::Float32, alpha::Float32, beta::Float32
)
    d = x - refVal
    ad = abs(d)
    mapped = if ad <= sigma
        ad == 0 ? Float32(0) : sigma * exp(alpha * log(ad / sigma))
    else
        sigma + beta * (ad - sigma)
    end
    return ifelse(d < 0, refVal - mapped, refVal + mapped)
end

function _llf_build_remap_lut!(lut, minVal, maxVal, refVal, sigma, alpha, beta)
    step = (maxVal - minVal) / Float32(length(lut) - 1)
    @inbounds for i in eachindex(lut)
        lut[i] = _llf_remap_value(
            minVal + Float32(i - 1) * step, refVal, sigma, alpha, beta
        )
    end
    return lut
end

function _llf_precompute_remap_lut_positions(input, minVal, scale, lutLength)
    indices = Array{UInt16}(undef, size(input))
    fracs = Matrix{Float32}(undef, size(input))
    lastIdx = lutLength - 1

    @inbounds for idx in eachindex(input)
        pos = (input[idx] - minVal) * scale + Float32(1)
        lo = Int(floor(pos))
        if lo < 1
            indices[idx] = UInt16(1)
            fracs[idx] = Float32(0)
        elseif lo >= lutLength
            indices[idx] = UInt16(lastIdx)
            fracs[idx] = Float32(1)
        else
            indices[idx] = UInt16(lo)
            fracs[idx] = pos - Float32(lo)
        end
    end

    return indices, fracs
end

function _llf_remap_lut!(
    output, input, lut, indices, fracs, refVal, nearRef, sigma, alpha, beta
)
    @inbounds for idx in eachindex(input)
        x = input[idx]
        if alpha < 1 && abs(x - refVal) <= nearRef
            output[idx] = _llf_remap_value(x, refVal, sigma, alpha, beta)
        else
            lo = Int(indices[idx])
            frac = fracs[idx]
            output[idx] = lut[lo] + frac * (lut[lo + 1] - lut[lo])
        end
    end
    return output
end
function _llf_add_laplacian_contribution!(
    out, currentGaussian, expandedNextGaussian, inputGaussian, refVal, invDelta
)
    @inbounds for idx in eachindex(out)
        weight = Float32(1) - abs(inputGaussian[idx] - refVal) * invDelta
        if weight > 0
            out[idx] += weight * (currentGaussian[idx] - expandedNextGaussian[idx])
        end
    end
    return out
end

function _llf_pyrdownsample(input::AbstractMatrix{Float32})
    outRows = (size(input, 1) + 1) >>> 1
    outCols = (size(input, 2) + 1) >>> 1
    output = Matrix{Float32}(undef, outRows, outCols)
    temp = Matrix{Float32}(undef, size(input, 1), outCols)
    return _llf_pyrdownsample!(output, input, temp)
end

function _llf_pyrdownsample!(output, input, temp)
    rows, cols = size(input)
    outRows, outCols = size(output)

    @inbounds for row in 1:rows
        if outCols >= 1
            srcCol0 = 1
            temp[row, 1] =
                Float32(0.0625) * input[row, 1] +
                Float32(0.25) * input[row, 1] +
                Float32(0.375) * input[row, 1] +
                Float32(0.25) * input[row, min(2, cols)] +
                Float32(0.0625) * input[row, min(3, cols)]
        end
        for outCol in 2:(outCols - 1)
            srcCol0 = 2 * outCol - 1
            temp[row, outCol] =
                Float32(0.0625) * input[row, srcCol0 - 2] +
                Float32(0.25) * input[row, srcCol0 - 1] +
                Float32(0.375) * input[row, srcCol0] +
                Float32(0.25) * input[row, srcCol0 + 1] +
                Float32(0.0625) * input[row, srcCol0 + 2]
        end
        if outCols >= 2
            srcCol0 = 2 * outCols - 1
            temp[row, outCols] =
                Float32(0.0625) * input[row, _llf_clamp_index(srcCol0 - 2, cols)] +
                Float32(0.25) * input[row, _llf_clamp_index(srcCol0 - 1, cols)] +
                Float32(0.375) * input[row, _llf_clamp_index(srcCol0, cols)] +
                Float32(0.25) * input[row, _llf_clamp_index(srcCol0 + 1, cols)] +
                Float32(0.0625) * input[row, _llf_clamp_index(srcCol0 + 2, cols)]
        end
    end

    @inbounds for outCol in 1:outCols
        if outRows >= 1
            output[1, outCol] =
                Float32(0.0625) * temp[1, outCol] +
                Float32(0.25) * temp[1, outCol] +
                Float32(0.375) * temp[1, outCol] +
                Float32(0.25) * temp[min(2, rows), outCol] +
                Float32(0.0625) * temp[min(3, rows), outCol]
        end
        for outRow in 2:(outRows - 1)
            srcRow0 = 2 * outRow - 1
            output[outRow, outCol] =
                Float32(0.0625) * temp[srcRow0 - 2, outCol] +
                Float32(0.25) * temp[srcRow0 - 1, outCol] +
                Float32(0.375) * temp[srcRow0, outCol] +
                Float32(0.25) * temp[srcRow0 + 1, outCol] +
                Float32(0.0625) * temp[srcRow0 + 2, outCol]
        end
        if outRows >= 2
            srcRow0 = 2 * outRows - 1
            output[outRows, outCol] =
                Float32(0.0625) * temp[_llf_clamp_index(srcRow0 - 2, rows), outCol] +
                Float32(0.25) * temp[_llf_clamp_index(srcRow0 - 1, rows), outCol] +
                Float32(0.375) * temp[_llf_clamp_index(srcRow0, rows), outCol] +
                Float32(0.25) * temp[_llf_clamp_index(srcRow0 + 1, rows), outCol] +
                Float32(0.0625) * temp[_llf_clamp_index(srcRow0 + 2, rows), outCol]
        end
    end

    return output
end
function _llf_pyrupsample!(output, input, temp)
    inRows, inCols = size(input)
    outRows, outCols = size(output)

    @inbounds for inRow in 1:inRows
        for outCol in 1:outCols
            if 2 < outCol < outCols - 1
                if isodd(outCol)
                    inCol = (outCol + 1) >>> 1
                    temp[inRow, outCol] =
                        Float32(0.125) * input[inRow, inCol - 1] +
                        Float32(0.75) * input[inRow, inCol] +
                        Float32(0.125) * input[inRow, inCol + 1]
                else
                    inCol = outCol >>> 1
                    temp[inRow, outCol] =
                        Float32(0.5) * input[inRow, inCol] +
                        Float32(0.5) * input[inRow, inCol + 1]
                end
            else
                temp[inRow, outCol] =
                    _llf_upsample_value(input, inRow, outCol - 2, outCols, inCols) *
                    Float32(0.125) +
                    _llf_upsample_value(input, inRow, outCol - 1, outCols, inCols) *
                    Float32(0.5) +
                    _llf_upsample_value(input, inRow, outCol, outCols, inCols) *
                    Float32(0.75) +
                    _llf_upsample_value(input, inRow, outCol + 1, outCols, inCols) *
                    Float32(0.5) +
                    _llf_upsample_value(input, inRow, outCol + 2, outCols, inCols) *
                    Float32(0.125)
            end
        end
    end

    @inbounds for outCol in 1:outCols
        for outRow in 1:outRows
            if 2 < outRow < outRows - 1
                if isodd(outRow)
                    inRow = (outRow + 1) >>> 1
                    output[outRow, outCol] =
                        Float32(0.125) * temp[inRow - 1, outCol] +
                        Float32(0.75) * temp[inRow, outCol] +
                        Float32(0.125) * temp[inRow + 1, outCol]
                else
                    inRow = outRow >>> 1
                    output[outRow, outCol] =
                        Float32(0.5) * temp[inRow, outCol] +
                        Float32(0.5) * temp[inRow + 1, outCol]
                end
            else
                output[outRow, outCol] =
                    _llf_uprow_value(temp, outRow - 2, outRows, inRows, outCol) *
                    Float32(0.125) +
                    _llf_uprow_value(temp, outRow - 1, outRows, inRows, outCol) *
                    Float32(0.5) +
                    _llf_uprow_value(temp, outRow, outRows, inRows, outCol) *
                    Float32(0.75) +
                    _llf_uprow_value(temp, outRow + 1, outRows, inRows, outCol) *
                    Float32(0.5) +
                    _llf_uprow_value(temp, outRow + 2, outRows, inRows, outCol) *
                    Float32(0.125)
            end
        end
    end

    return output
end
@inline function _llf_upsample_value(input, row, outCol, outCols, inCols)
    srcCol = _llf_clamp_index(outCol, outCols)
    isodd(srcCol) || return Float32(0)
    inCol = (srcCol + 1) >>> 1
    return inCol <= inCols ? input[row, inCol] : Float32(0)
end

@inline function _llf_uprow_value(temp, outRow, outRows, inRows, col)
    srcRow = _llf_clamp_index(outRow, outRows)
    isodd(srcRow) || return Float32(0)
    inRow = (srcRow + 1) >>> 1
    return inRow <= inRows ? temp[inRow, col] : Float32(0)
end
function _llf_filter5(input::AbstractMatrix{Float32}, kernel::AbstractVector{Float32})
    rows, cols = size(input)
    temp = Matrix{Float32}(undef, rows, cols)
    output = Matrix{Float32}(undef, rows, cols)

    @inbounds for col in 1:cols, row in 1:rows
        acc = Float32(0)
        for k in 1:5
            srcCol = _llf_clamp_index(col + k - 3, cols)
            acc += kernel[k] * input[row, srcCol]
        end
        temp[row, col] = acc
    end

    @inbounds for col in 1:cols, row in 1:rows
        acc = Float32(0)
        for k in 1:5
            srcRow = _llf_clamp_index(row + k - 3, rows)
            acc += kernel[k] * temp[srcRow, col]
        end
        output[row, col] = acc
    end

    return output
end

@inline _llf_clamp_index(i::Integer, n::Integer) = ifelse(i < 1, 1, ifelse(i > n, n, i))

function _llf_precompile()
    try
        precompile(locallapfilt, (Array{UInt8,3}, Float64, Float64))
        precompile(locallapfilt, (Array{UInt8,3}, Float64, Float64, Float64))
        precompile(
            _locallapfilt_direct, (Array{UInt8,3}, Float64, Float64, Int64, String, Int64)
        )
        precompile(
            _locallapfilt_direct, (Array{UInt8,3}, Float64, Float64, Float64, String, Int64)
        )
        precompile(llf, (Array{UInt8,3}, Float32, Float32, Float32, Int64, Bool, Int64))
        precompile(llfCore, (Matrix{Float32}, Float32, Float32, Float32, Int64, Int64))
        precompile(_llf_to_float32_image, (Array{UInt8,3}, Type{UInt8}))
        precompile(_llf_rgb_to_gray_float, (Array{Float32,3},))
        precompile(
            _llf_luminance_to_uint8, (Matrix{Float32}, Array{Float32,3}, Matrix{Float32})
        )
        precompile(_llf_pyrdownsample!, (Matrix{Float32}, Matrix{Float32}, Matrix{Float32}))
        precompile(_llf_pyrupsample!, (Matrix{Float32}, Matrix{Float32}, Matrix{Float32}))
        precompile(
            _llf_remap_lut!,
            (
                Matrix{Float32},
                Matrix{Float32},
                Vector{Float32},
                Matrix{UInt16},
                Matrix{Float32},
                Float32,
                Float32,
                Float32,
                Float32,
                Float32,
            ),
        )
        precompile(
            _llf_add_laplacian_contribution!,
            (
                Matrix{Float32},
                Matrix{Float32},
                Matrix{Float32},
                Matrix{Float32},
                Float32,
                Float32,
            ),
        )
        if isdefined(Core, :kwcall)
            kwcall = getfield(Core, :kwcall)
            precompile(
                Tuple{
                    typeof(kwcall),
                    NamedTuple{(:NumIntensityLevels,),Tuple{Int64}},
                    typeof(locallapfilt),
                    Array{UInt8,3},
                    Float64,
                    Float64,
                },
            )
            precompile(
                Tuple{
                    typeof(kwcall),
                    NamedTuple{(:ColorMode,),Tuple{String}},
                    typeof(locallapfilt),
                    Array{UInt8,3},
                    Float64,
                    Float64,
                },
            )
            precompile(
                Tuple{
                    typeof(kwcall),
                    NamedTuple{(:ColorMode, :NumIntensityLevels),Tuple{String,Int64}},
                    typeof(locallapfilt),
                    Array{UInt8,3},
                    Float64,
                    Float64,
                },
            )
        end
    catch
    end
    return nothing
end

_llf_precompile()
