"""
    hdrread(filename)

Read a Radiance RGBE image and return an `M`-by-`N`-by-3 `Float32` array.
"""
function hdrread(In...)
    isempty(In) && error(_msg(@tr("Insufficient number of input arguments."), "hdrread"))
    length(In) == 1 || error(_msg(@tr("Too many input arguments."), "hdrread"))

    filename = In[1]
    filename isa AbstractString ||
        error(_msg(@tr("Filename must be a string scalar."), "hdrread"))
    path = _hdrread_resolve_path(filename)

    try
        return open(path, "r") do io
            height, width = _hdrread_header(io)
            _hdrread_image(read(io), height, width)
        end
    catch errorValue
        errorValue isa ErrorException && rethrow()
        error(_msg(@tr("Unable to open HDR file \"%{1}\".", filename), "hdrread"))
    end
end

function _hdrread_resolve_path(filename)
    isfile(filename) && return String(filename)

    if isempty(dirname(filename)) || dirname(filename) == "."
        resourcePath = joinpath(@__DIR__, "..", "resources", basename(filename))
        isfile(resourcePath) && return resourcePath
    end
    return error(_msg(@tr("Unable to open HDR file \"%{1}\".", filename), "hdrread"))
end

function _hdrread_header(io)
    markerLine = nothing
    while !eof(io)
        line = chomp(readline(io; keep=true))
        if occursin("#?", line)
            markerLine = line
            break
        end
    end
    isnothing(markerLine) && error(_msg(@tr("File is not a Radiance HDR file."), "hdrread"))
    (occursin("RADIANCE", markerLine) || occursin("RGBE", markerLine)) ||
        error(_msg(@tr("Radiance HDR marker is missing."), "hdrread"))

    foundSeparator = false
    while !eof(io)
        if isempty(strip(chomp(readline(io; keep=true))))
            foundSeparator = true
            break
        end
    end
    foundSeparator ||
        error(_msg(@tr("HDR file has an invalid resolution line."), "hdrread"))
    eof(io) && error(_msg(@tr("HDR file has an invalid resolution line."), "hdrread"))

    descriptors = split(strip(chomp(readline(io; keep=true))))
    length(descriptors) == 4 ||
        error(_msg(@tr("HDR file has an invalid resolution line."), "hdrread"))
    length(descriptors[1]) == 2 && length(descriptors[3]) == 2 ||
        error(_msg(@tr("HDR file has an invalid resolution line."), "hdrread"))
    uppercase(descriptors[1][2]) == 'Y' && uppercase(descriptors[3][2]) == 'X' ||
        error(_msg(@tr("HDR file has an invalid resolution line."), "hdrread"))

    height = tryparse(Int, descriptors[2])
    width = tryparse(Int, descriptors[4])
    (isnothing(height) || isnothing(width) || height <= 0 || width <= 0) &&
        error(_msg(@tr("HDR file has an invalid resolution line."), "hdrread"))
    return height, width
end

function _hdrread_image(encodedData, height, width)
    isempty(encodedData) &&
        error(_msg(@tr("HDR file does not contain enough encoded data."), "hdrread"))

    output = Array{Float32}(undef, height, width, 3)
    scanline = Matrix{UInt8}(undef, width, 4)
    offset = 1
    compressed = _hdrread_is_compressed(encodedData, offset)

    for row in 1:height
        if compressed
            offset = _hdrread_decompress_scanline!(scanline, encodedData, offset, width)
        else
            offset = _hdrread_unpack_scanline!(scanline, encodedData, offset, width)
        end
        _hdrread_rgbe_to_rgb!(output, row, scanline)
    end
    return output
end

function _hdrread_is_compressed(encodedData, offset)
    _hdrread_require_bytes(encodedData, offset, 3)
    if encodedData[offset] == 0x02 && encodedData[offset + 1] == 0x02
        return true
    elseif encodedData[offset] == 0x01 &&
        encodedData[offset + 1] == 0x01 &&
        encodedData[offset + 2] == 0x01
        error(_msg(@tr("Old-style HDR run-length encoding is not supported."), "hdrread"))
    end
    return false
end

function _hdrread_decompress_scanline!(scanline, encodedData, offset, width)
    _hdrread_require_bytes(encodedData, offset, 4)
    encodedWidth = Int(encodedData[offset + 2]) * 256 + Int(encodedData[offset + 3])
    encodedWidth == width ||
        error(_msg(@tr("HDR scanline width does not match the header."), "hdrread"))
    offset += 4

    for component in 1:4
        offset = _hdrread_decode_component!(
            @view(scanline[:, component]), encodedData, offset, width
        )
    end
    return offset
end

function _hdrread_decode_component!(decoded, encodedData, offset, width)
    outputOffset = 1
    while outputOffset <= width
        _hdrread_require_bytes(encodedData, offset, 1)
        code = Int(encodedData[offset])
        offset += 1

        if code > 128
            runLength = code - 128
            outputOffset + runLength - 1 <= width ||
                error(_msg(@tr("HDR run length is invalid."), "hdrread"))
            _hdrread_require_bytes(encodedData, offset, 1)
            fill!(
                @view(decoded[outputOffset:(outputOffset + runLength - 1)]),
                encodedData[offset],
            )
            offset += 1
            outputOffset += runLength
        else
            runLength = code
            (runLength > 0 && outputOffset + runLength - 1 <= width) ||
                error(_msg(@tr("HDR run length is invalid."), "hdrread"))
            _hdrread_require_bytes(encodedData, offset, runLength)
            @inbounds for index in 0:(runLength - 1)
                decoded[outputOffset + index] = encodedData[offset + index]
            end
            offset += runLength
            outputOffset += runLength
        end
    end
    return offset
end

function _hdrread_unpack_scanline!(scanline, encodedData, offset, width)
    _hdrread_require_bytes(encodedData, offset, 4width)
    @inbounds for column in 1:width, component in 1:4
        scanline[column, component] = encodedData[offset + 4(column - 1) + component - 1]
    end
    return offset + 4width
end

function _hdrread_rgbe_to_rgb!(output, row, scanline)
    @inbounds for column in axes(scanline, 1)
        red = scanline[column, 1]
        green = scanline[column, 2]
        blue = scanline[column, 3]
        exponent = scanline[column, 4]
        if (red | green | blue | exponent) == 0x00
            output[row, column, 1] = 0.0f0
            output[row, column, 2] = 0.0f0
            output[row, column, 3] = 0.0f0
        else
            scale = ldexp(1.0f0 / 256.0f0, Int(exponent) - 128)
            output[row, column, 1] = Float32(red) * scale
            output[row, column, 2] = Float32(green) * scale
            output[row, column, 3] = Float32(blue) * scale
        end
    end
    return output
end

function _hdrread_require_bytes(encodedData, offset, count)
    count >= 0 && offset >= 1 && offset + count - 1 <= length(encodedData) && return nothing
    return error(_msg(@tr("HDR file does not contain enough encoded data."), "hdrread"))
end
