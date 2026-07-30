"""
integralImage3 - 计算三维积分图像

J = integralImage3(I)
"""
function integralImage3(I::AbstractArray{<:Real})
    if ndims(I) > 3
        error(_msg(@tr("I must be three-dimensional."), splitext(basename(@__FILE__))[1]))
    end

    isempty(I) && return Float64[]

    if ndims(I) == 1
        return integralImage3_vector(I)
    elseif ndims(I) == 2
        return integralImage3_matrix(I)
    end

    return integralImage3_volume(I)
end

function integralImage3_vector(I::AbstractVector{<:Real})
    nrows = length(I)
    intVolume = zeros(Float64, nrows + 1, 2, 2)

    rowsum = 0.0
    @inbounds for r in 1:nrows
        rowsum += Float64(I[r])
        intVolume[r + 1, 2, 2] = rowsum
    end
    return intVolume
end

function integralImage3_matrix(I::AbstractMatrix{<:Real})
    nrows, ncols = size(I)
    intVolume = zeros(Float64, nrows + 1, ncols + 1, 2)

    @inbounds for c in 1:ncols
        colsum = 0.0
        for r in 1:nrows
            colsum += Float64(I[r, c])
            intVolume[r + 1, c + 1, 2] = intVolume[r + 1, c, 2] + colsum
        end
    end
    return intVolume
end

function integralImage3_volume(I::AbstractArray{<:Real,3})
    nrows, ncols, nplanes = size(I)
    intVolume = zeros(Float64, nrows + 1, ncols + 1, nplanes + 1)

    @inbounds for p in 1:nplanes
        for c in 1:ncols
            colsum = 0.0
            for r in 1:nrows
                colsum += Float64(I[r, c, p])
                intVolume[r + 1, c + 1, p + 1] =
                    intVolume[r + 1, c, p + 1] + colsum + intVolume[r + 1, c + 1, p] -
                    intVolume[r + 1, c, p]
            end
        end
    end
    return intVolume
end

try
    precompile(integralImage3, (Vector{Int64},))
    precompile(integralImage3, (Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}},))
    precompile(integralImage3, (Array{Int64,3},))
    precompile(integralImage3, (Array{UInt8,3},))
    precompile(integralImage3, (Array{Float64,3},))
    precompile(integralImage3, (Matrix{UInt8},))
    precompile(integralImage3, (Matrix{Float64},))
catch _
end
