"""
localcontrast - 图像的边缘感知局部对比度调整

B = localcontrast(A)

B = localcontrast(A, edgeThreshold, amount)
"""
function localcontrast(In...)
    return internal_localcontrast(In)
end

function internal_localcontrast(varargin)
    inputs = localcontrast_parseInputs(varargin)

    if inputs.edgeThreshold == 0 || inputs.amount == 0
        return inputs.A
    end

    if inputs.amount > 0
        alpha = 1 - 0.99 * inputs.amount
        processLuminance = true
    else
        alpha = 1 - 99 * inputs.amount
        processLuminance = false
    end

    alpha32 = Float32(alpha)
    sigma32 = Float32(inputs.edgeThreshold)
    numIntensityLevels = _llf_auto_num_intensity_levels(alpha32)
    numPyrLevels = floor(Int, log2(minimum(size(inputs.A)[1:2]))) + 1

    return _localcontrast_llf(
        inputs.A,
        sigma32,
        alpha32,
        Float32(1),
        numIntensityLevels,
        processLuminance,
        numPyrLevels,
    )
end

function _localcontrast_llf(
    input, sigma, alpha, beta, numIntensityLevels, processLuminance, numPyramidLevels
)
    isRGB = ndims(input) == 3 && size(input, 3) == 3
    origClass = eltype(input)
    work = _llf_to_float32_image(input, origClass)

    output = if isRGB && processLuminance
        gray = _llf_rgb_to_gray_float(work)
        filtered = _localcontrast_llf_core(
            gray, sigma, alpha, beta, numIntensityLevels, numPyramidLevels
        )
        if origClass == UInt8
            return _llf_luminance_to_uint8(filtered, work, gray)
        end
        _llf_apply_luminance_ratios(filtered, work, gray)
    elseif isRGB
        out = similar(work, Float32)
        for channel in 1:3
            out[:, :, channel] .= _localcontrast_llf_core(
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
        _localcontrast_llf_core(work, sigma, alpha, beta, numIntensityLevels, numPyramidLevels)
    end

    return _llf_cast_output(output, origClass)
end

function _localcontrast_llf_core(
    input, sigma, alpha, beta, numIntensityLevels, numPyramidLevels
)
    return _llf_core_with_pyramid(
        input,
        sigma,
        alpha,
        beta,
        numIntensityLevels,
        numPyramidLevels,
        _localcontrast_pyrdownsample,
        _localcontrast_pyrdownsample!,
        _localcontrast_pyrupsample!,
        _localcontrast_remap!,
        _localcontrast_build_remap_lut!,
        _localcontrast_remap_lut!,
    )
end

function _localcontrast_pyrdownsample(input::AbstractMatrix{Float32})
    output = Matrix{Float32}(undef, (size(input, 1) + 1) >>> 1, (size(input, 2) + 1) >>> 1)
    temp = Matrix{Float32}(undef, size(input, 1), size(output, 2))
    return _localcontrast_pyrdownsample!(output, input, temp)
end

const _LOCALCONTRAST_REMAP_EPSILON = Float32(0.01)

function _localcontrast_remap!(
    output, input, refVal::Float32, sigma::Float32, alpha::Float32, beta::Float32
)
    @inbounds for idx in eachindex(input)
        output[idx] = _localcontrast_remap_value(input[idx], refVal, sigma, alpha, beta)
    end
    return output
end

@inline function _localcontrast_remap_value(
    x::Float32, refVal::Float32, sigma::Float32, alpha::Float32, beta::Float32
)
    d = x - refVal
    ad = abs(d)
    mapped = if ad <= sigma
        powerMapped = ad == 0 ? Float32(0) : sigma * exp(alpha * log(ad / sigma))
        if alpha < 1 && ad < Float32(2) * _LOCALCONTRAST_REMAP_EPSILON
            if ad <= _LOCALCONTRAST_REMAP_EPSILON
                ad
            else
                t = (ad - _LOCALCONTRAST_REMAP_EPSILON) / _LOCALCONTRAST_REMAP_EPSILON
                weight = (t * (Float32(2) - t))^2
                ad + weight * (powerMapped - ad)
            end
        else
            powerMapped
        end
    else
        sigma + beta * (ad - sigma)
    end
    return ifelse(d < 0, refVal - mapped, refVal + mapped)
end

function _localcontrast_build_remap_lut!(lut, minVal, maxVal, refVal, sigma, alpha, beta)
    step = (maxVal - minVal) / Float32(length(lut) - 1)
    @inbounds for idx in eachindex(lut)
        lut[idx] = _localcontrast_remap_value(
            minVal + Float32(idx - 1) * step, refVal, sigma, alpha, beta
        )
    end
    return lut
end

function _localcontrast_remap_lut!(
    output, input, lut, indices, fracs, refVal, nearRef, sigma, alpha, beta
)
    @inbounds for idx in eachindex(input)
        lo = Int(indices[idx])
        frac = fracs[idx]
        output[idx] = lut[lo] + frac * (lut[lo + 1] - lut[lo])
    end
    return output
end
@inline function _localcontrast_symmetric_index(i::Int, n::Int)
    n == 1 && return 1
    return ifelse(i < 1, 1 - i, ifelse(i > n, 2 * n - i + 1, i))
end

function _localcontrast_pyrdownsample!(output, input, temp)
    rows, cols = size(input)
    outRows, outCols = size(output)

    @inbounds for outCol in 1:outCols, row in 1:rows
        center = 2 * outCol - 1
        temp[row, outCol] =
            Float32(0.05) * input[row, _localcontrast_symmetric_index(center - 2, cols)] +
            Float32(0.25) * input[row, _localcontrast_symmetric_index(center - 1, cols)] +
            Float32(0.4) * input[row, center] +
            Float32(0.25) * input[row, _localcontrast_symmetric_index(center + 1, cols)] +
            Float32(0.05) * input[row, _localcontrast_symmetric_index(center + 2, cols)]
    end

    @inbounds for outCol in 1:outCols, outRow in 1:outRows
        center = 2 * outRow - 1
        output[outRow, outCol] =
            Float32(0.05) * temp[_localcontrast_symmetric_index(center - 2, rows), outCol] +
            Float32(0.25) * temp[_localcontrast_symmetric_index(center - 1, rows), outCol] +
            Float32(0.4) * temp[center, outCol] +
            Float32(0.25) * temp[_localcontrast_symmetric_index(center + 1, rows), outCol] +
            Float32(0.05) * temp[_localcontrast_symmetric_index(center + 2, rows), outCol]
    end

    return output
end
function _localcontrast_pyrupsample!(output, input, temp)
    inRows, inCols = size(input)
    outRows, outCols = size(output)

    @inbounds for outCol in 1:outCols, row in 1:inRows
        if isodd(outCol)
            center = (outCol + 1) >>> 1
            temp[row, outCol] =
                Float32(0.1) * input[row, clamp(center - 1, 1, inCols)] +
                Float32(0.8) * input[row, center] +
                Float32(0.1) * input[row, clamp(center + 1, 1, inCols)]
        else
            left = outCol >>> 1
            temp[row, outCol] =
                Float32(0.5) * input[row, left] +
                Float32(0.5) * input[row, clamp(left + 1, 1, inCols)]
        end
    end

    @inbounds for outCol in 1:outCols, outRow in 1:outRows
        if isodd(outRow)
            center = (outRow + 1) >>> 1
            output[outRow, outCol] =
                Float32(0.1) * temp[clamp(center - 1, 1, inRows), outCol] +
                Float32(0.8) * temp[center, outCol] +
                Float32(0.1) * temp[clamp(center + 1, 1, inRows), outCol]
        else
            top = outRow >>> 1
            output[outRow, outCol] =
                Float32(0.5) * temp[top, outCol] +
                Float32(0.5) * temp[clamp(top + 1, 1, inRows), outCol]
        end
    end

    return output
end
function localcontrast_parseInputs(varargin)
    if length(varargin) < 1
        error(_msg(@tr("Insufficient number of input arguments."), "localcontrast"))
    elseif length(varargin) > 3
        error(_msg(@tr("Too many input arguments."), "localcontrast"))
    end

    A = _localcontrast_validate_image(varargin[1])
    edgeThreshold =
        length(varargin) >= 2 ? _localcontrast_validate_edge_threshold(varargin[2]) : 0.3
    amount = length(varargin) >= 3 ? _localcontrast_validate_amount(varargin[3]) : 0.25

    return (A=A, edgeThreshold=edgeThreshold, amount=amount)
end

function _localcontrast_validate_image(A)
    if !(A isa AbstractArray)
        error(
            _msg(
                @tr(
                    "Invalid value for 'A'. First input, A, must be one of the following types:\n\nFloat32, UInt8, UInt16, Int8, Int16\n\nbut its type was %{1}.",
                    string(typeof(A))
                ),
                "localcontrast",
            ),
        )
    end

    if eltype(A) ∉ (Float32, UInt8, UInt16, Int8, Int16)
        error(
            _msg(
                @tr(
                    "Invalid value for 'A'. First input, A, must be one of the following types:\n\nFloat32, UInt8, UInt16, Int8, Int16\n\nbut its type was %{1}.",
                    string(eltype(A))
                ),
                "localcontrast",
            ),
        )
    end

    if isempty(A)
        error(
            _msg(
                @tr("Invalid value for 'A'. First input, A, must be nonempty."),
                "localcontrast",
            ),
        )
    end

    validColorImage = ndims(A) == 3 && size(A, 3) == 3
    if !(ismatrix(A) || validColorImage)
        error(_msg(@tr("A is not a grayscale or RGB image."), "localcontrast"))
    end

    return A
end

function _localcontrast_validate_edge_threshold(x)
    edgeThreshold = _localcontrast_scalar_value(x, "edgeThreshold", @tr("Second"))

    if edgeThreshold < 0
        error(
            _msg(
                @tr(
                    "Invalid value for 'edgeThreshold'. Second input, edgeThreshold, must be nonnegative."
                ),
                "localcontrast",
            ),
        )
    elseif edgeThreshold > 1
        error(
            _msg(
                @tr(
                    "Invalid value for 'edgeThreshold'. Second input, edgeThreshold, must be a scalar with value <= 1."
                ),
                "localcontrast",
            ),
        )
    end

    return edgeThreshold
end

function _localcontrast_validate_amount(x)
    amount = _localcontrast_scalar_value(x, "amount", @tr("Third"))

    if amount < -1
        error(
            _msg(
                @tr(
                    "Invalid value for 'amount'. Third input, amount, must be a scalar with value >= -1."
                ),
                "localcontrast",
            ),
        )
    elseif amount > 1
        error(
            _msg(
                @tr(
                    "Invalid value for 'amount'. Third input, amount, must be a scalar with value <= 1."
                ),
                "localcontrast",
            ),
        )
    end

    return amount
end

function _localcontrast_scalar_value(x, name::String, ordinal::String)
    value = x
    if x isa AbstractArray
        if isempty(x)
            error(
                _msg(
                    @tr(
                        "Invalid value for '%{1}'. %{2} input, %{1}, must be nonempty.",
                        name,
                        ordinal
                    ),
                    "localcontrast",
                ),
            )
        elseif length(x) != 1
            error(
                _msg(
                    @tr(
                        "Invalid value for '%{1}'. %{2} input, %{1}, must be a scalar.",
                        name,
                        ordinal
                    ),
                    "localcontrast",
                ),
            )
        end
        value = first(x)
    end

    if !(value isa Real) || value isa Bool
        error(
            _msg(
                @tr(
                    "Invalid value for '%{1}'. %{2} input, %{1}, must be numeric and real.",
                    name,
                    ordinal
                ),
                "localcontrast",
            ),
        )
    end

    if !isfinite(value)
        error(
            _msg(
                @tr(
                    "Invalid value for '%{1}'. %{2} input, %{1}, must be finite.",
                    name,
                    ordinal
                ),
                "localcontrast",
            ),
        )
    end

    return Float64(value)
end
