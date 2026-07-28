"""
graycoprops - 灰度共生矩阵（GLCM）的特性

stats = graycoprops(glcm,properties)
"""
function graycoprops(glcm::AbstractArray{<:Real}, properties::AbstractVecOrMat{String})
    glcm, requestedStats = graycoprops_ParseInputs(glcm, properties)

    return intenal_graycoprops(glcm, requestedStats)
end

function graycoprops(glcm::AbstractArray{<:Real}, properties::String...)
    glcm, requestedStats = graycoprops_ParseInputs(glcm, collect(properties))

    return intenal_graycoprops(glcm, requestedStats)
end

function graycoprops(glcm::AbstractArray{<:Real}, properties::String="all")
    glcm, requestedStats = graycoprops_ParseInputs(glcm, properties)

    return intenal_graycoprops(glcm, requestedStats)
end

function graycoprops_ParseInputs(glcm, properties)
    allStats = ["Contrast", "Correlation", "Energy", "Homogeneity"]

    if any(glcm .< 0)
        error(
            _msg(
                @tr("The first input, GLCM, must be nonnegative."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isinteger.(glcm))
        error(
            _msg(
                @tr("The first input, GLCM, must contain integer values."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if ndims(glcm) > 3
        error(
            _msg(
                @tr("GLCM must be an m-by-n or m-by-n-by-p array."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if eltype(glcm) != Float64
        glcm = Float64.(glcm)
    end

    list = properties

    if isempty(list)
        reqStats = allStats
    else
        if typeof(list) == String
            reqStats = [list]
        else
            reqStats = collect(list)
        end
    end

    if !all(x -> x in [allStats..., "all"], reqStats)
        error(
            _msg(
                @tr(
                    "PROPERTIES must match one of: 'Contrast', 'Correlation', 'Energy', 'Homogeneity', 'all'. The input %{1} does not match any valid value.",
                    string(reqStats),
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if "all" ∈ reqStats
        reqStats = allStats
    end

    reqStats = sort(reqStats)

    if isempty(reqStats)
        error(
            _msg(@tr("requestedStats must not be empty."), splitext(basename(@__FILE__))[1])
        )
    end

    return glcm, reqStats
end

struct graycoprops_struct
    Contrast::Matrix{Union{<:Real,DataType}}
    Correlation::Matrix{Union{<:Real,DataType}}
    Energy::Matrix{Union{<:Real,DataType}}
    Homogeneity::Matrix{Union{<:Real,DataType}}
end

function Base.show(io::IO, graycoprops_struct::graycoprops_struct)
    println(io, @tr("Struct with the following fields:\n"))
    if !any(graycoprops_struct.Contrast .== Nothing)
        println(io, @tr("        Contrast: %{1}"), graycoprops_struct.Contrast)
    end
    if !any(graycoprops_struct.Correlation .== Nothing)
        println(io, @tr("     Correlation: %{1}"), graycoprops_struct.Correlation)
    end
    if !any(graycoprops_struct.Energy .== Nothing)
        println(io, @tr("          Energy: %{1}"), graycoprops_struct.Energy)
    end
    if !any(graycoprops_struct.Homogeneity .== Nothing)
        println(io, @tr("     Homogeneity: %{1}"), graycoprops_struct.Homogeneity)
    end
    return nothing
end

function intenal_graycoprops(glcm, requestedStats)
    numStats = length(requestedStats)
    numGLCM = size(glcm, 3)
    # empties = repeat(zeros(1, numGLCM), numStats, 1)
    # stats = cell2struct(empties, requestedStats, 1)

    stats = graycoprops_struct(
        repeat([Nothing], 1, numGLCM),
        repeat([Nothing], 1, numGLCM),
        repeat([Nothing], 1, numGLCM),
        repeat([Nothing], 1, numGLCM),
    )

    for p in 1:numGLCM
        if numGLCM != 1
            tGLCM = normalizeGLCM(glcm[:, :, p])
        else
            tGLCM = normalizeGLCM(glcm)
        end

        s = size(tGLCM)
        c, r = meshgrid2(1:s[1], 1:s[2])
        r = r[:]
        c = c[:]

        for k in 1:numStats
            name = requestedStats[k]
            if name == "Contrast"
                stats.Contrast[p] = calculateContrast(tGLCM, r, c)
            elseif name == "Correlation"
                stats.Correlation[p] = calculateCorrelation(tGLCM, r, c)
            elseif name == "Energy"
                stats.Energy[p] = calculateEnergy(tGLCM)
            elseif name == "Homogeneity"
                stats.Homogeneity[p] = calculateHomogeneity(tGLCM, r, c)
            end
        end
    end

    return stats
end

function normalizeGLCM(glcm)
    if any(glcm[:] .!= 0)
        glcm = glcm ./ sum(glcm[:])
    end
    return glcm
end

function calculateContrast(glcm, r, c)
    k = 2
    l = 1
    term1 = abs.(r .- c) .^ k
    term2 = glcm .^ l

    term = term1 .* term2[:]
    C = sum(term)

    return C
end

function calculateCorrelation(glcm, r, c)
    mr = meanIndex(r, glcm)
    Sr = stdIndex(r, glcm, mr)

    mc = meanIndex(c, glcm)
    Sc = stdIndex(c, glcm, mc)

    term1 = (r .- mr) .* (c .- mc) .* glcm[:]
    term2 = sum(term1)

    Corr = term2 / (Sr * Sc)

    return Corr
end

function stdIndex(index, glcm, m)
    term1 = (index .- m) .^ 2 .* glcm[:]
    S = sqrt.(sum(term1))

    return S
end

function meanIndex(index, glcm)
    M = index .* glcm[:]
    M = sum(M)

    return M
end

function calculateEnergy(glcm)
    foo = glcm .^ 2
    E = sum(foo[:])

    return E
end

function calculateHomogeneity(glcm, r, c)
    term1 = (1 .+ abs.(r .- c))
    term = glcm[:] ./ term1
    H = sum(term)
    return H
end
