"""
函数说明\n
Create LDPC decoder configuration\n
示例：\n 
        decodercfg = ldpcDecoderConfig
        decodercfg = ldpcDecoderConfig(H)
        decodercfg = ldpcDecoderConfig(H,alg)
        decodercfg = ldpcDecoderConfig(encodercfg)
        decodercfg = ldpcDecoderConfig(encodercfg,alg)
        ...\n
"""
mutable struct ldpcDecoderConfig
    ParityCheckMatrix::SparseMatrixCSC
    Algorithm::String
    BlockLength::Int
    NumInformationBits::Int
    NumParityCheckBits::Int
    CodeRate::Float64
    NumRowsPerLayer::Int
    derivedParams
    AlgorithmChoice::Int
    function ldpcDecoderConfig(;
        ParityCheckMatrix::AbstractArray=ldpcQuasiCyclicMatrix(
            27,
            [
                17 13 8 21 9 3 18 12 10 0 4 15 19 2 5 10 26 19 13 13 1 0 -1 -1
                3 12 11 14 11 25 5 18 0 9 2 26 26 10 24 7 14 20 4 2 -1 0 0 -1
                22 16 4 3 10 21 12 5 21 14 19 5 -1 8 5 18 11 5 5 15 0 -1 0 0
                7 7 14 14 4 16 16 24 24 10 1 7 15 6 10 26 8 18 21 14 1 -1 -1 0
            ],
        ),
        BlockLength::Number=648,
        NumInformationBits::Number=540,
        NumParityCheckBits::Number=108,
        CodeRate::Number=5 / 6,
        NumRowsPerLayer::Number=108,
        Algorithm::AbstractString="bp",
    )
        @ccall_check_func_lic :TyCommunication
        this = new()
        if issparse(ParityCheckMatrix) &&
            all(x -> (x in [0, 1]), ParityCheckMatrix) &&
            size(ParityCheckMatrix, 1) < size(ParityCheckMatrix, 2)
            this.ParityCheckMatrix = ParityCheckMatrix
        else
            throw(
                ArgumentError(
                    "Need a sparse logical matrix or an ldpcEncoderConfig object."
                ),
            )
        end
        this.Algorithm = Algorithm
        return this
    end
    ldpcDecoderConfig(H::AbstractArray) = ldpcDecoderConfig(; ParityCheckMatrix=H)
    function ldpcDecoderConfig(H::AbstractArray, ALG::AbstractString)
        return ldpcDecoderConfig(; ParityCheckMatrix=H, Algorithm=ALG)
    end
end

function Base.show(io::IO, obj::ldpcDecoderConfig)
    println(io, "ldpcDecoderConfig — Property :")
    a, b = size(obj.ParityCheckMatrix)
    ctype = typeof(obj.ParityCheckMatrix)
    println(io, "         ParityCheckMatrix :", "[$a x $b $ctype]")
    println(io, "         Algorithm :", obj.Algorithm)

    println("     Read-only properties:")
    println(io, "               BlockLength :", obj.BlockLength)
    println(io, "        NumInformationBits :", obj.NumInformationBits)
    println(io, "        NumParityCheckBits :", obj.NumParityCheckBits)
    println(io, "                  CodeRate :", obj.CodeRate)

    return nothing
end

function Base.setproperty!(obj::ldpcDecoderConfig, name::Symbol, value)
    if name == :ParityCheckMatrix
        if issparse(value) &&
            all(x -> (x in [0, 1]), value) &&
            size(value, 1) < size(value, 2)
            setfield!(obj, name, value)
        else
            throw(ArgumentError("ParityCheckMatrix must be a sparse logical matrix."))
        end
        all(collect(minimum(sum(value; dims=1); dims=2)) .== 0) && throw(
            ArgumentError(
                "The parity-check matrix must have at least one nonzero element in each column.",
            ),
        )
        all(collect(minimum(sum(value; dims=2); dims=1)) .== 0) && throw(
            ArgumentError(
                "The parity-check matrix must have at least one nonzero element in each row.",
            ),
        )
        setfield!(obj, name, value)
        setfield!(obj, :BlockLength, size(value, 2))
        setfield!(obj, :NumParityCheckBits, size(value, 1))
        setfield!(obj, :NumInformationBits, size(value, 2) - size(value, 1))
        setfield!(obj, :NumInformationBits, size(value, 2) - size(value, 1))
        setfield!(obj, :CodeRate, (size(value, 2) - size(value, 1)) / size(value, 2))
        setfield!(obj, :derivedParams, CalcDerivedParams(obj))
        setfield!(obj, :NumRowsPerLayer, CalcNumRowsPerLayer(obj))

    elseif name == :Algorithm
        !isa(value, AbstractString) ||
            !(lowercase(value) in ["bp", "layered-bp", "norm-min-sum", "offset-min-sum"]) &&
                throw(
                    ArgumentError(
                        "Algorithm must be one of \"bp\", \"layered-bp\", \"norm-min-sum\", \"offset-min-sum\".",
                    ),
                )
        if lowercase(value) == "bp"
            setfield!(obj, :AlgorithmChoice, 0)
        elseif lowercase(value) == "layered-bp"
            setfield!(obj, :AlgorithmChoice, 1)
        elseif lowercase(value) == "norm-min-sum"
            setfield!(obj, :AlgorithmChoice, 2)
        elseif lowercase(value) == "offset-min-sum"
            setfield!(obj, :AlgorithmChoice, 3)
        else
            setfield!(obj, :AlgorithmChoice, 4)
        end
        setfield!(obj, name, value)
    elseif name == :BlockLength
        throw(
            ArgumentError(
                "Unable to set the 'BlockLength' property of the 'ldpcDecoderConfig'  class because it is a read-only property.",
            ),
        )
    elseif name == :NumInformationBits
        throw(
            ArgumentError(
                "Unable to set the 'NumInformationBits' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
            ),
        )
    elseif name == :NumParityCheckBits
        throw(
            ArgumentError(
                "Unable to set the 'NumParityCheckBits' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
            ),
        )
    elseif name == :CodeRate
        throw(
            ArgumentError(
                "Unable to set the 'CodeRate' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
            ),
        )
    elseif name == :NumRowsPerLayer
        throw(
            ArgumentError(
                "Unable to set the 'NumRowsPerLayer' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
            ),
        )
    else
        setfield!(obj, name, value)
    end
end

mutable struct ldpcdecoderderivedParams
    offsetWeight
    columnIndexMap
    function ldpcdecoderderivedParams(; offsetWeight=nothing, columnIndexMap=nothing)
        this = new()
        this.offsetWeight = offsetWeight
        this.columnIndexMap = columnIndexMap
        return this
    end
end

function CalcDerivedParams(obj::ldpcDecoderConfig)
    _, nCols = size(obj.ParityCheckMatrix)
    if size(obj.ParityCheckMatrix, 1) == 1
        idxtmp = findall(!=(0), obj.ParityCheckMatrix')
        columnIndex = [idx[1] for idx in idxtmp]
        rowIndex = [idx[2] for idx in idxtmp]
    else
        idxtmp = findall(!=(0), obj.ParityCheckMatrix)
        rowIndex = [idx[1] for idx in idxtmp]
        columnIndex = [idx[2] for idx in idxtmp]
    end

    temp = sortrows([(rowIndex .- 1) * nCols + columnIndex (1:nnz(obj.ParityCheckMatrix))])
    indexMap = temp[:, 2]

    tmpidx = findall(!=(0), obj.ParityCheckMatrix')
    columnIndex = [idx[1] for idx in tmpidx]

    rowWeight = collect(sum(obj.ParityCheckMatrix; dims=2))
    rowOffset = [0; cumsum(rowWeight[1:(end - 1), 1])]

    columnWeight = collect(sum(obj.ParityCheckMatrix; dims=1))'
    columnOffset = [0; cumsum(columnWeight[1:(end - 1), 1])]

    derivedParams = ldpcdecoderderivedParams()
    derivedParams.offsetWeight = ([rowOffset; rowWeight; columnOffset; columnWeight])
    derivedParams.columnIndexMap = ([columnIndex; indexMap] .- 1)
    return derivedParams
end

function CalcNumRowsPerLayer(obj::ldpcDecoderConfig)
    t = obj.ParityCheckMatrix' # More efficient to use columns
    totalsum = zeros(size(t, 1), 1)
    numRowsPerLayer = 0
    for i in 1:size(t, 2)
        totalsum = totalsum + t[:, i]
        if maximum(totalsum) > 1
            # Assuming that the prototype matrix of the QC LDPC
            # code has one value not equal to -1 in the first row,
            # when totalsum > 1, i is in the beginning of the
            # second partition
            break
        end
        numRowsPerLayer = numRowsPerLayer + 1
    end
    if mod(size(obj.ParityCheckMatrix, 1), numRowsPerLayer) != 0
        # Not an integer number of partitions
        # Be conservative and set numRowsPerLayer = 1
        numRowsPerLayer = 1
    end
    return numRowsPerLayer
end

function isInactiveProperty(obj, prop)
    flag = false
    if strcmp(prop, "NumRowsPerLayer")
        flag = strcmpi(obj.Algorithm, "bp")
    end
    return flag
end
