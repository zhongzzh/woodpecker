"""
graycomatrix - 从图像创建灰度共生矩阵

glcm, = graycomatrix(I)

glcm, = graycomatrix(I;Name=Value)

glcm,SI = graycomatrix(___)
"""
function graycomatrix(
    I::AbstractMatrix{<:Real};
    GrayLimits::AbstractVecOrMat{<:Real}=getrangefromclass(I),
    NumLevels::Integer=(eltype(I) == Bool ? 2 : 8),
    Offset::AbstractArray{<:Integer}=[0 1],
    Symmetric::Bool=false,
)
    I, Offset, NL, GL, makeSymmetric = graycomatrix_ParseInputs(
        I, GrayLimits, NumLevels, Offset, Symmetric
    )

    if GL[2] == GL[1]
        SI = ones(size(I))
    else
        slope = NL / (GL[2] - GL[1])
        intercept = 1 - (slope * (GL[1]))
        SI = floor.(imlincomb(slope, I; K=intercept, outputClass="Float64"))
    end

    SI[SI .> NL] .= NL
    SI[SI .< 1] .= 1

    numOffsets = size(Offset, 1)

    if NL != 0
        s = size(I)
        r, c = meshgrid2(1:s[1], 1:s[2])
        r = r[:]
        c = c[:]

        GLCMS = zeros(NL, NL, numOffsets)
        for k in 1:numOffsets
            GLCMS[:, :, k] = computeGLCM(r, c, Offset[k, :], SI, NL)
            if makeSymmetric
                glcmTranspose = GLCMS[:, :, k]'
                GLCMS[:, :, k] = GLCMS[:, :, k] + glcmTranspose
            end
        end
    else
        GLCMS = zeros(0, 0, numOffsets)
    end

    if ndims(GLCMS) == 3 && size(GLCMS, 3) == 1
        GLCMS = GLCMS[:, :, 1]
    end

    return GLCMS, SI
end

function graycomatrix_ParseInputs(I, GrayLimits, NumLevels, Offset, Symmetric)
    offset = Offset
    nl = NumLevels
    gl = GrayLimits
    sym = Symmetric

    if ndims(offset) != 2
        error(
            _msg(
                @tr("Offset must be a two-dimensional array."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(offset)
        error(_msg(@tr("Offset must be non-empty."), splitext(basename(@__FILE__))[1]))
    end
    if size(offset, 2) != 2
        error(
            _msg(@tr("Offset must be an N-by-2 array."), splitext(basename(@__FILE__))[1])
        )
    end

    if nl < 0
        error(
            _msg(
                @tr("NumLevels (NL) must be non-negative."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if eltype(I) == Bool && nl != 2
        error(
            _msg(
                @tr("For binary images, NumLevels (NL) must be 2."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isempty(gl)
        gl = [minimum(I[:]) maximum(I[:])]
    end

    if length(gl) != 2
        error(
            _msg(
                @tr("GrayLimits (GL) must be a two-element vector."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return I, offset, nl, gl, sym
end

function computeGLCM(r, c, offset, si, nl)
    r2 = r .+ offset[1]
    c2 = c .+ offset[2]

    nRow, nCol = size(si)

    outsideBounds = find((c2 .< 1) .| (c2 .> nCol) .| (r2 .< 1) .| (r2 .> nRow))

    v1 = shiftdim(si, 1)
    v1 = v1[:]
    v1 = v1[setdiff(1:length(v1), outsideBounds)]

    r2 = r2[setdiff(1:length(r2), outsideBounds)]
    c2 = c2[setdiff(1:length(c2), outsideBounds)]
    Index = r2 + (c2 .- 1) * nRow
    v2 = si[Index]

    v2 = v2[:]

    bad = isnan.(v1) .| isnan.(v2)
    if any(bad)
        @warn @tr(
            "Warning: if either value in a pixel pair is NaN, that pair is not included in the GLCM counts.",
        )
    end

    Ind = [v1 v2]
    Ind = Ind[setdiff(1:size(Ind, 1), bad), :]

    if isempty(Ind)
        oneGLCM = zeros(nl)
    else
        oneGLCM = accumarray(Ind, 1, [nl nl])
    end

    return oneGLCM
end
