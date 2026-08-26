"""
imregmtb - 使用中值阈值位图对二维图像进行配准

R1,R2,...,Rn,shift = imregmtb(M1,M2,...,Mn,F)
"""
function imregmtb(In...)
    varargin = In
    return internal_imregmtb(varargin)
end

function internal_imregmtb(varargin)
    I = imregmtb_parseInputs(varargin)
    originalClass = eltype(I[1])
    workImages = imregmtb_prepareWorkImages(I, originalClass)

    numLevels = 6
    numImages = length(workImages)
    shift = zeros(numImages, 2)
    varargout = Vector{Any}(undef, numImages)
    pyrs = [imregmtb_pyrConstruction(workImages[idx], numLevels) for idx in 1:numImages]
    for idx in numImages:-1:2
        refPyr = pyrs[idx]
        srcPyr = pyrs[idx - 1]
        refImg = refPyr[1]
        srcImg = srcPyr[1]

        isUniformRefImage = all(refImg[:] .== refImg[1])
        isUniformSrcImage = all(srcImg[:] .== srcImg[1])
        if (isUniformRefImage && isUniformSrcImage)
            error(
                _msg(
                    @tr("Insufficient image details to compute median threshold."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        shift[idx - 1, :] = computeOffset(refPyr, srcPyr, numLevels)
        shift[idx - 1, :] = shift[idx - 1, :] .+ shift[idx, :]
        alignedImg = imregmtb_translateInteger(workImages[idx - 1], shift[idx - 1, :])
        alignedImg = imregmtb_convertToOriginalClass(alignedImg, originalClass)
        varargout[idx - 1] = alignedImg
    end

    varargout[numImages] = shift[1:(end - 1), :]

    return varargout
end

function imregmtb_prepareWorkImages(I, originalClass)
    if originalClass == UInt8
        return I
    end

    workImages = Vector{AbstractArray}(undef, length(I))
    for i in 1:length(I)
        workImages[i] = im2uint8(I[i])
    end

    return workImages
end

function imregmtb_parseInputs(varargin)
    chkImg = varargin[1]
    if eltype(chkImg) ∉ [Float32, Float64, UInt8, UInt16]
        type_list = "Float32, Float64, UInt8, UInt16"
        error(
            _msg(
                @tr(
                    "First input, chkImg, must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    type_list,
                    eltype(chkImg)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(chkImg)
        error(
            _msg(
                @tr("First input, chkImg, must be real."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    if ndims(chkImg) >= 4 || (size(chkImg, 3) != 3 && size(chkImg, 3) != 1)
        error(
            _msg(
                @tr("Images must be 2-D grayscale or RGB."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if size(chkImg, 1) < 64 || size(chkImg, 2) < 64
        error(
            _msg(
                @tr("Smallest image size supported is 64-by-64."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    cnt = 0
    originalClass = eltype(chkImg)
    Im = Vector{typeof(chkImg)}()
    for ind in 1:length(varargin)
        if !(ty_isnumeric(varargin[ind]) && eltype(varargin[ind]) != Bool)
            break
        end
        push!(Im, varargin[ind])
        if originalClass != eltype(varargin[ind])
            error(
                _msg(
                    @tr("All the input images should be of same class."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        cnt = cnt + 1
    end

    if cnt != length(varargin)
        error(
            _msg(
                @tr("Images must be 2-D grayscale or RGB."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    imgSize = size(chkImg)
    for i in 1:length(Im)
        if !isreal(Im[i])
            error(
                _msg(
                    @tr("Input %{1} , im, must be real.", i),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if any(isnan.(Im[i]))
            error(
                _msg(
                    @tr("Input %{1} , im, must be non-NaN.", i),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !all(isfinite.(Im[i]))
            error(
                _msg(
                    @tr("Input %{1} , im, must be finite.", i),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if isempty(Im[i])
            error(
                _msg(
                    @tr("Input %{1} , im, must be nonempty.", i),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if size(Im[i]) != imgSize
            error(
                _msg(
                    @tr(
                        "Input %{1}, im, size must be %{2}, but actual size is %{3}.",
                        i,
                        imgSize,
                        size(Im[i])
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    return Im
end

function pyrConstruction(ref, src, nlev)
    return imregmtb_pyrConstruction(ref, nlev), imregmtb_pyrConstruction(src, nlev)
end

function imregmtb_pyrConstruction(img, nlev)
    grayImg = imregmtb_toGrayUInt8(img)
    pyr = Vector{Matrix{UInt8}}(undef, nlev)
    pyr[1] = grayImg
    for level in 2:nlev
        pyr[level] = imregmtb_pyrDown(pyr[level - 1])
    end

    return pyr
end

function imregmtb_toGrayUInt8(img)
    if size(img, 3) == 1
        return UInt8.(img)
    end

    nrows, ncols = size(img, 1), size(img, 2)
    grayImg = Matrix{UInt8}(undef, nrows, ncols)
    @inbounds for col in 1:ncols
        for row in 1:nrows
            grayImg[row, col] = UInt8(
                (
                    Int(img[row, col, 1]) * 54 +
                    Int(img[row, col, 2]) * 183 +
                    Int(img[row, col, 3]) * 19
                ) >>> 8,
            )
        end
    end

    return grayImg
end

function imregmtb_pyrDown(src::AbstractMatrix{UInt8})
    nrows, ncols = size(src)
    outRows = (nrows + 1) >>> 1
    outCols = (ncols + 1) >>> 1
    dst = Matrix{UInt8}(undef, outRows, outCols)

    @inbounds for outCol in 1:outCols
        srcCol = 2 * outCol - 1
        c1 = imregmtb_reflectIndex(srcCol - 2, ncols)
        c2 = imregmtb_reflectIndex(srcCol - 1, ncols)
        c3 = srcCol
        c4 = imregmtb_reflectIndex(srcCol + 1, ncols)
        c5 = imregmtb_reflectIndex(srcCol + 2, ncols)
        for outRow in 1:outRows
            srcRow = 2 * outRow - 1
            r1 = imregmtb_reflectIndex(srcRow - 2, nrows)
            r2 = imregmtb_reflectIndex(srcRow - 1, nrows)
            r3 = srcRow
            r4 = imregmtb_reflectIndex(srcRow + 1, nrows)
            r5 = imregmtb_reflectIndex(srcRow + 2, nrows)

            acc =
                imregmtb_weightedRow(src, r1, c1, c2, c3, c4, c5) +
                4 * imregmtb_weightedRow(src, r2, c1, c2, c3, c4, c5) +
                6 * imregmtb_weightedRow(src, r3, c1, c2, c3, c4, c5) +
                4 * imregmtb_weightedRow(src, r4, c1, c2, c3, c4, c5) +
                imregmtb_weightedRow(src, r5, c1, c2, c3, c4, c5)
            dst[outRow, outCol] = UInt8((acc + 128) >>> 8)
        end
    end

    return dst
end

@inline function imregmtb_weightedRow(src, row, c1, c2, c3, c4, c5)
    return Int(src[row, c1]) +
           4 * Int(src[row, c2]) +
           6 * Int(src[row, c3]) +
           4 * Int(src[row, c4]) +
           Int(src[row, c5])
end

@inline function imregmtb_reflectIndex(idx, len)
    if idx < 1
        return 2 - idx
    elseif idx > len
        return 2 * len - idx
    end

    return idx
end

function computeOffset(refPyr, srcPyr, numLevels)
    shift = [0.0 0.0]
    estShift = shift
    for thisLevel in numLevels:-1:1
        refImg = refPyr[thisLevel]
        srcImg = srcPyr[thisLevel]

        refHistogram = imregmtb_medianUInt8(refImg)
        srcHistogram = imregmtb_medianUInt8(srcImg)

        refBinaryMap, refNoiseMask = imregmtb_bitmapAndNoise(refImg, refHistogram)
        srcBinaryMap, srcNoiseMask = imregmtb_bitmapAndNoise(srcImg, srcHistogram)

        minErr = size(refImg, 1) * size(refImg, 2)
        for i in -1:1
            for j in -1:1
                xs = shift[1] + i
                ys = shift[2] + j
                err = imregmtb_shiftError(
                    refBinaryMap, srcBinaryMap, refNoiseMask, srcNoiseMask, xs, ys
                )

                if err < minErr
                    estShift = [xs ys]
                    minErr = err
                end
            end
        end

        shift = estShift * 2
    end

    return estShift
end

function imregmtb_medianUInt8(img::AbstractMatrix{UInt8})
    counts = zeros(Int, 256)
    @inbounds for value in img
        counts[Int(value) + 1] += 1
    end

    n = length(img)
    mid1 = (n + 1) >>> 1
    mid2 = (n + 2) >>> 1
    acc = 0
    med1 = 0
    med2 = 0
    foundFirst = false
    @inbounds for idx in 1:256
        acc += counts[idx]
        if !foundFirst && acc >= mid1
            med1 = idx - 1
            foundFirst = true
        end
        if acc >= mid2
            med2 = idx - 1
            break
        end
    end

    return (med1 + med2) / 2
end

function imregmtb_bitmapAndNoise(img, histogram)
    nrows, ncols = size(img)
    bitmap = Matrix{Bool}(undef, nrows, ncols)
    noise = Matrix{Bool}(undef, nrows, ncols)
    low = histogram - 4
    high = histogram + 4

    @inbounds for col in 1:ncols
        for row in 1:nrows
            value = img[row, col]
            bitmap[row, col] = value > histogram
            noise[row, col] = value < low || value > high
        end
    end

    return bitmap, noise
end

function imregmtb_shiftError(refBinaryMap, srcBinaryMap, refNoiseMask, srcNoiseMask, xs, ys)
    nrows, ncols = size(refBinaryMap)
    xshift = Int(xs)
    yshift = Int(ys)

    if xshift >= 0
        refColStart = xshift + 1
        srcColStart = 1
        width = ncols - xshift
    else
        refColStart = 1
        srcColStart = 1 - xshift
        width = ncols + xshift
    end

    if yshift >= 0
        refRowStart = yshift + 1
        srcRowStart = 1
        height = nrows - yshift
    else
        refRowStart = 1
        srcRowStart = 1 - yshift
        height = nrows + yshift
    end

    if width <= 0 || height <= 0
        return nrows * ncols
    end

    err = 0
    @inbounds for colOffset in 0:(width - 1)
        refCol = refColStart + colOffset
        srcCol = srcColStart + colOffset
        for rowOffset in 0:(height - 1)
            refRow = refRowStart + rowOffset
            srcRow = srcRowStart + rowOffset
            if refNoiseMask[refRow, refCol] &&
                srcNoiseMask[srcRow, srcCol] &&
                (refBinaryMap[refRow, refCol] != srcBinaryMap[srcRow, srcCol])
                err += 1
            end
        end
    end

    return err
end

function imregmtb_translateInteger(A, translation)
    nrows, ncols = size(A, 1), size(A, 2)
    xshift = Int(translation[1])
    yshift = Int(translation[2])
    out = zeros(eltype(A), size(A))

    if xshift >= 0
        dstColStart = xshift + 1
        srcColStart = 1
        width = ncols - xshift
    else
        dstColStart = 1
        srcColStart = 1 - xshift
        width = ncols + xshift
    end

    if yshift >= 0
        dstRowStart = yshift + 1
        srcRowStart = 1
        height = nrows - yshift
    else
        dstRowStart = 1
        srcRowStart = 1 - yshift
        height = nrows + yshift
    end

    if width <= 0 || height <= 0
        return out
    end

    dstRows = dstRowStart:(dstRowStart + height - 1)
    dstCols = dstColStart:(dstColStart + width - 1)
    srcRows = srcRowStart:(srcRowStart + height - 1)
    srcCols = srcColStart:(srcColStart + width - 1)

    if ndims(A) == 2
        out[dstRows, dstCols] = A[srcRows, srcCols]
    else
        out[dstRows, dstCols, :] = A[srcRows, srcCols, :]
    end

    return out
end

function imregmtb_convertToOriginalClass(B, OriginalClass)
    if OriginalClass == UInt8
        B = UInt8.(B)
    elseif OriginalClass == UInt16
        B = im2uint16(UInt8.(B))
    elseif OriginalClass == Float32
        B = im2single(UInt8.(B))
    else
        B = im2double(UInt8.(B))
    end

    return B
end

precompile(
    imregmtb,
    (
        Array{UInt8,3},
        Array{UInt8,3},
        Array{UInt8,3},
        Array{UInt8,3},
        Array{UInt8,3},
        Array{UInt8,3},
    ),
)
precompile(internal_imregmtb, (NTuple{6,Array{UInt8,3}},))
precompile(imregmtb_prepareWorkImages, (Vector{Array{UInt8,3}}, DataType))
precompile(imregmtb_pyrConstruction, (Array{UInt8,3}, Int64))
precompile(imregmtb_toGrayUInt8, (Array{UInt8,3},))
precompile(imregmtb_pyrDown, (Matrix{UInt8},))
precompile(computeOffset, (Vector{Matrix{UInt8}}, Vector{Matrix{UInt8}}, Int64))
precompile(imregmtb_medianUInt8, (Matrix{UInt8},))
precompile(imregmtb_bitmapAndNoise, (Matrix{UInt8}, Float64))
precompile(
    imregmtb_shiftError,
    (Matrix{Bool}, Matrix{Bool}, Matrix{Bool}, Matrix{Bool}, Float64, Float64),
)
precompile(imregmtb_translateInteger, (Array{UInt8,3}, Vector{Float64}))
