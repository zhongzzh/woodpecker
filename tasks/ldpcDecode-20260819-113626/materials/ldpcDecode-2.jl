
"""
函数说明：\n
        Decode binary LDPC code\n
示例：\n
    y,actualnumiter,finalparitychecks = ldpcDecode(llr,decodercfg,maxnumiter)
    y,actualnumiter,finalparitychecks = ldpcDecode(llr,decodercfg,maxnumiter;Name=Value)
"""
function ldpcDecode(
    llr,
    decoderConfig,
    maxNumIter;
    OutputFormat="info",
    DecisionType="hard",
    MinSumScalingFactor=0.75,
    MinSumOffset=0.5,
    Termination="early",
    Multithreaded=true,
    nargout=3,
)
    @ccall_check_func_lic :TyCommunication
    if !isa(decoderConfig, ldpcDecoderConfig)
        error("the second input argument must be an ldpcDecoderConfig object")
    end

    #Parse
    if strcmpi(OutputFormat, "whole")
        isWholeCodeword = true
    elseif strcmpi(OutputFormat, "info")
        isWholeCodeword = false
    else
        error("OutputFormat must be info or whole")
    end
    if strcmpi(DecisionType, "hard")
        isHardDecision = true
    elseif strcmpi(DecisionType, "soft")
        isHardDecision = false
    else
        error("DecisionType must be hard or soft")
    end
    if strcmpi(Termination, "early")
        isEarlyExit = true
    elseif strcmpi(Termination, "max")
        isEarlyExit = false
    else
        error("Termination must be early or max")
    end
    if isa(MinSumScalingFactor, Number) &&
        MinSumScalingFactor .> 0 &&
        MinSumScalingFactor <= 1
        msScalingFactor = MinSumScalingFactor
    else
        error("The MinSumScalingFactor is wrong")
    end
    if isa(MinSumOffset, Number)
        msOffset = MinSumOffset
    else
        error("The MinSumOffset is wrong")
    end
    if isa(Multithreaded, Bool)
        useMultithread = Multithreaded
    else
        error("The Multithreaded is wrong")
    end

    if decoderConfig.AlgorithmChoice == 2
        # validateattributes(msScalingFactor,{'numeric'},{'scalar','real','>',0,'<=',1},'','MinSumScalingFactor');
        alphaBeta = Float64(msScalingFactor)
    elseif decoderConfig.AlgorithmChoice == 3
        # validateattributes(msOffset,{'numeric'},{'scalar','real','finite','>=',0},'','MinSumOffset');
        alphaBeta = Float64(msOffset)
    else
        alphaBeta = 0
    end

    C = size(llr, 2)
    # typeIn = class(llr);
    finalParityChecks = (zeros(Int, decoderConfig.NumParityCheckBits, C))
    actualNumIter = (zeros(Int, 1, C))
    compFinalParityChecks = (nargout == 3)
    numEdges = Int.(length(decoderConfig.derivedParams.columnIndexMap) / 2)

    #Initialize output to fix dimension and data type
    if isHardDecision
        if isWholeCodeword
            decoderOut = Int8.(zeros(decoderConfig.BlockLength, C))
        else
            decoderOut = Int8.(zeros(decoderConfig.NumInformationBits, C))
        end
    else
        if isWholeCodeword
            decoderOut = (zeros(decoderConfig.BlockLength, C))
        else
            decoderOut = (zeros(decoderConfig.NumInformationBits, C))
        end
    end

    LLR_out = (zeros(decoderConfig.BlockLength, C))

    if decoderConfig.AlgorithmChoice == 0 # Use BP
        _ldpcForEachCodeword(C, useMultithread) do cwIdx
            LQ, numIter, finalParityChecks1 = BPDecode(
                (llr[:, cwIdx]),
                maxNumIter,
                decoderConfig.BlockLength,
                decoderConfig.NumParityCheckBits,
                numEdges,
                decoderConfig.derivedParams.offsetWeight,
                decoderConfig.derivedParams.columnIndexMap,
                isEarlyExit,
                compFinalParityChecks,
            )
            LLR_out[:, cwIdx] .= LQ
            actualNumIter[:, cwIdx] .= numIter
            finalParityChecks[:, cwIdx] .= Int.(finalParityChecks1)
        end
    elseif decoderConfig.AlgorithmChoice == 1 #Use Layered BP
        _ldpcForEachCodeword(C, useMultithread) do cwIdx
            Lq, numIter, finalParityChecks1 = LayeredBPDecode(
                transpose(collect(Float64.(llr[:, cwIdx]'))),
                maxNumIter,
                decoderConfig.NumParityCheckBits,
                numEdges,
                decoderConfig.derivedParams.offsetWeight,
                decoderConfig.derivedParams.columnIndexMap,
                isEarlyExit,
                compFinalParityChecks,
            )
            LLR_out[:, cwIdx] .= Lq
            actualNumIter[:, cwIdx] .= numIter
            finalParityChecks[:, cwIdx] .= finalParityChecks1
        end
    elseif decoderConfig.AlgorithmChoice == 2  # Use Layered normalized min-sum
        _ldpcForEachCodeword(C, useMultithread) do cwIdx
            Lq, numIter, finalParityChecks1 = LayeredBPNormMSDecode(
                transpose(collect(Float64.(llr[:, cwIdx]'))),
                maxNumIter,
                decoderConfig.NumParityCheckBits,
                numEdges,
                decoderConfig.derivedParams.offsetWeight,
                decoderConfig.derivedParams.columnIndexMap,
                isEarlyExit,
                compFinalParityChecks,
                alphaBeta,
            )
            LLR_out[:, cwIdx] .= Lq
            actualNumIter[:, cwIdx] .= numIter
            finalParityChecks[:, cwIdx] .= finalParityChecks1
        end
    else
        decoderConfig.AlgorithmChoice == 3   #Use Layered offset min-sum
        _ldpcForEachCodeword(C, useMultithread) do cwIdx
            Lq, numIter, finalParityChecks1 = LayeredBPOffsetMSDecode(
                transpose(collect(Float64.(llr[:, cwIdx]'))),
                maxNumIter,
                decoderConfig.NumParityCheckBits,
                numEdges,
                decoderConfig.derivedParams.offsetWeight,
                decoderConfig.derivedParams.columnIndexMap,
                isEarlyExit,
                compFinalParityChecks,
                alphaBeta,
            )
            LLR_out[:, cwIdx] .= Lq
            actualNumIter[:, cwIdx] .= numIter
            finalParityChecks[:, cwIdx] .= finalParityChecks1
        end
    end
    #Format output
    if isHardDecision
        if isWholeCodeword
            decoderOut[:] = Int8.(LLR_out .<= 0)
        else
            decoderOut[:] = Int8.(LLR_out[1:(decoderConfig.NumInformationBits), :] .<= 0)
        end
    else
        if isWholeCodeword
            decoderOut[:] = LLR_out
        else
            decoderOut[:] = LLR_out[1:(decoderConfig.NumInformationBits), :]
        end
    end
    if nargout == 1
        return decoderOut
    elseif nargout == 2
        return decoderOut, actualNumIter
    elseif nargout == 3
        return decoderOut, actualNumIter, finalParityChecks
    end
end

function _ldpcForEachCodeword(f, numCodewords, useMultithread)
    if useMultithread && numCodewords > 1 && Threads.nthreads() > 1
        errors = Vector{Any}(undef, numCodewords)
        fill!(errors, nothing)
        Threads.@threads for codewordIdx in 1:numCodewords
            try
                f(codewordIdx)
            catch exception
                errors[codewordIdx] = exception
            end
        end
        for errorValue in errors
            errorValue === nothing || throw(errorValue)
        end
    else
        for codewordIdx in 1:numCodewords
            f(codewordIdx)
        end
    end
    return nothing
end

@inline function _ldpcTwoSmallestMagnitudes(values)
    if length(values) < 2
        magnitudes, indices = mink(abs.(values), 2; nargout=2)
        return magnitudes[1], magnitudes[2], indices[1]
    end

    valueIndices = eachindex(values)
    firstIndex, iterationState = iterate(valueIndices)
    secondIndex, iterationState = iterate(valueIndices, iterationState)
    firstMagnitude = abs(values[firstIndex])
    secondMagnitude = abs(values[secondIndex])

    if isless(secondMagnitude, firstMagnitude)
        firstMagnitude, secondMagnitude = secondMagnitude, firstMagnitude
        firstIndex = secondIndex
    end

    nextIndex = iterate(valueIndices, iterationState)
    @inbounds while nextIndex !== nothing
        valueIndex, iterationState = nextIndex
        magnitude = abs(values[valueIndex])
        if isless(magnitude, firstMagnitude)
            secondMagnitude = firstMagnitude
            firstMagnitude = magnitude
            firstIndex = valueIndex
        elseif isless(magnitude, secondMagnitude)
            secondMagnitude = magnitude
        end
        nextIndex = iterate(valueIndices, iterationState)
    end

    return firstMagnitude, secondMagnitude, firstIndex
end

function LayeredBPDecode(
    Lq,
    maxNumIter,
    parityLen,
    numEdges,
    offsetWeight,
    columnIndexMap,
    earlyTermination,
    calcAllParityChecks,
)
    #LAYEREDBPDECODE LDPC decoding by layered belief propagation
    #codegen
    N = columnIndexMap[1:(Int.(length(columnIndexMap) / 2))]' .+ 1
    rowOffset = transpose(collect(offsetWeight[1:parityLen, 1]'))
    rowWeight = transpose(collect(offsetWeight[parityLen .+ (1:parityLen), 1]'))
    columnIndex = transpose(collect(columnIndexMap[1:numEdges]')) .+ 1
    finalParityChecks = zeros(parityLen, 1)

    Lq, numIter, finalParityChecks = LayeredBPDecodeImpl(
        Lq,
        maxNumIter,
        parityLen,
        N,
        rowOffset,
        rowWeight,
        columnIndex,
        finalParityChecks,
        earlyTermination,
        calcAllParityChecks,
    )

    return Lq, numIter, finalParityChecks
end

function LayeredBPDecodeImpl(
    Lq,
    maxNumIter,
    parityLen,
    N,
    rowOffset,
    rowWeight,
    columnIndex,
    finalParityChecks,
    earlyTermination,
    calcAllParityChecks,
)
    R_mj = zeros(1, length(N))
    numIter = 0
    for iteration in 1:maxNumIter
        numIter = numIter + 1

        for m in 1:parityLen
            idx = rowOffset[m] .+ (1:rowWeight[m])
            Lq_mj = Lq[N[idx]] - transpose(collect(R_mj[idx]'))
            zeroLoc = 0
            for i in 1:length(Lq_mj)
                if Lq_mj[i] == 0
                    if zeroLoc == 0
                        zeroLoc = i
                    else
                        zeroLoc = -1
                        break
                    end
                end
            end

            if zeroLoc < 0
                R_mj[idx] .= 0
            else
                temp = tanh.(Lq_mj ./ 2)
                if zeroLoc == 0
                    prodLq = prod(temp)
                    y = 2 .* atanh.(prodLq ./ temp)
                else
                    temp[zeroLoc] = 1
                    prodLq = prod(temp)
                    y = zeros(size(Lq_mj))
                    y[zeroLoc] = 2 * atanh.(prodLq)
                end
                y[y .== Inf] .= 2 * (19.07)
                y[y .== -Inf] .= 2 * (-19.07)
                R_mj[idx] = y
            end
            Lq[transpose(collect(N[idx]'))] = Lq_mj + (R_mj[idx])
        end

        if earlyTermination
            result, finalParityChecks = computeParityChecks(
                Lq, parityLen, rowWeight, rowOffset, columnIndex, calcAllParityChecks
            )
            #目前单元测试没覆盖
            if !result
                break
            end
        end
    end

    if !earlyTermination && calcAllParityChecks
        a, finalParityChecks = computeParityChecks(
            Lq, parityLen, rowWeight, rowOffset, columnIndex, calcAllParityChecks
        )
    end
    return Lq, numIter, finalParityChecks
end

function LayeredBPNormMSDecode(
    Lq,
    maxNumIter,
    parityLen,
    numEdges,
    offsetWeight,
    columnIndexMap,
    earlyTermination,
    calcAllParityChecks,
    alpha,
)
    #LAYEREDBPNORMMSDECODE LDPC decoding by layered belief propagation with
    #normalized min-sum approximation

    N = columnIndexMap[1:(Int.(length(columnIndexMap) / 2))]' .+ 1
    rowOffset = transpose(collect(offsetWeight[1:parityLen, 1]'))
    rowWeight = transpose(collect(offsetWeight[parityLen .+ (1:parityLen), 1]'))
    columnIndex = transpose(collect(columnIndexMap[1:numEdges]')) .+ 1
    finalParityChecks = zeros(parityLen, 1)

    Lq, numIter, finalParityChecks = LayeredBPNormMSDecodeImpl(
        Lq,
        maxNumIter,
        parityLen,
        N,
        rowOffset,
        rowWeight,
        columnIndex,
        finalParityChecks,
        earlyTermination,
        calcAllParityChecks,
        alpha,
    )

    return Lq, numIter, finalParityChecks
end

function LayeredBPNormMSDecodeImpl(
    Lq,
    maxNumIter,
    parityLen,
    N,
    rowOffset,
    rowWeight,
    columnIndex,
    finalParityChecks,
    earlyTermination,
    calcAllParityChecks,
    alpha,
)

    # Choose max LLR value to enable BPSK (+/-1) operation at SNR=60 dB, with received value of 1000
    Lq[Lq .> 1e10] .= 1e10
    Lq[Lq .< -1e10] .= -1e10
    R_mj = zeros(1, length(N))
    numIter = 0
    for iteration in 1:maxNumIter
        numIter = numIter + 1

        for m in 1:parityLen
            idx = rowOffset[m] .+ (1:rowWeight[m])
            Lq_mj = Lq[N[idx]] - transpose(collect(R_mj[idx]'))

            minMagnitude, secondMinMagnitude, minIndex = _ldpcTwoSmallestMagnitudes(Lq_mj)
            if minMagnitude == 0 && secondMinMagnitude == 0
                # Two zeros
                R_mj[idx] .= 0
            else
                if minMagnitude == 0
                    #One zero
                    y = sign.(Lq_mj)
                    y[minIndex] = 1
                    s = prod(y)
                    y[:] .= 0
                    y[minIndex] = s * secondMinMagnitude
                else
                    # No zero
                    y = sign.(Lq_mj)
                    s = prod(y) ./ y
                    y = s * minMagnitude
                    y[minIndex] = s[minIndex] * secondMinMagnitude
                end
                R_mj[idx] = y * alpha
            end

            Lq[transpose(collect(N[idx]'))] = Lq_mj .+ R_mj[idx]
        end

        if earlyTermination
            result, finalParityChecks = computeParityChecks(
                Lq, parityLen, rowWeight, rowOffset, columnIndex, calcAllParityChecks
            )
            #目前单元测试没覆盖
            if !result
                break
            end
        end
    end

    if !earlyTermination && calcAllParityChecks
        a, finalParityChecks = computeParityChecks(
            Lq, parityLen, rowWeight, rowOffset, columnIndex, calcAllParityChecks
        )
    end

    return Lq, numIter, finalParityChecks
end

function LayeredBPOffsetMSDecode(
    Lq,
    maxNumIter,
    parityLen,
    numEdges,
    offsetWeight,
    columnIndexMap,
    earlyTermination,
    calcAllParityChecks,
    beta,
)
    #LAYEREDBPOFFSETMSDECODE LDPC decoding by layered belief propagation with
    #   offset min-sum approximation
    N = transpose(collect(columnIndexMap[1:(Int.(length(columnIndexMap) / 2))]')) .+ 1
    rowOffset = transpose(collect(offsetWeight[1:parityLen, 1]'))
    rowWeight = transpose(collect(offsetWeight[parityLen .+ (1:parityLen), 1]'))
    columnIndex = transpose(collect(columnIndexMap[1:numEdges]')) .+ 1
    finalParityChecks = zeros(parityLen, 1)

    Lq, numIter, finalParityChecks = LayeredBPOffsetMSDecodeImpl(
        Lq,
        maxNumIter,
        parityLen,
        N,
        rowOffset,
        rowWeight,
        columnIndex,
        finalParityChecks,
        earlyTermination,
        calcAllParityChecks,
        beta,
    )

    return Lq, numIter, finalParityChecks
end

function LayeredBPOffsetMSDecodeImpl(
    Lq,
    maxNumIter,
    parityLen,
    N,
    rowOffset,
    rowWeight,
    columnIndex,
    finalParityChecks,
    earlyTermination,
    calcAllParityChecks,
    beta,
)

    # Choose max LLR value to enable BPSK (+/-1) operation at SNR=60 dB, with received value of 1000
    Lq[Lq .> 1e10] .= 1e10
    Lq[Lq .< -1e10] .= -1e10
    R_mj = zeros(1, length(N))
    numIter = 0
    for iteration in 1:maxNumIter
        numIter = numIter + 1

        for m in 1:parityLen
            idx = rowOffset[m] .+ (1:rowWeight[m])
            Lq_mj = Lq[N[idx]] - transpose(collect(R_mj[idx]'))

            minMagnitude, secondMinMagnitude, minIndex = _ldpcTwoSmallestMagnitudes(Lq_mj)
            minMagnitude = minMagnitude - beta
            secondMinMagnitude = secondMinMagnitude - beta
            if minMagnitude < 0
                minMagnitude = zero(minMagnitude)
            end
            if secondMinMagnitude < 0
                secondMinMagnitude = zero(secondMinMagnitude)
            end
            if minMagnitude == 0 && secondMinMagnitude == 0
                # Two zeros
                R_mj[idx] .= 0
            else
                if minMagnitude == 0
                    # One zero
                    y = sign.(Lq_mj)
                    y[minIndex] = 1
                    s = prod(y)
                    y[:] .= 0
                    y[minIndex] = s * secondMinMagnitude
                else
                    # No zero
                    y = sign.(Lq_mj)
                    s = prod(y) ./ y
                    y = s * minMagnitude
                    y[minIndex] = s[minIndex] * secondMinMagnitude
                end
                R_mj[idx] .= y
            end

            Lq[transpose(collect(N[idx]'))] = Lq_mj .+ R_mj[idx]
        end

        if earlyTermination
            result, finalParityChecks = computeParityChecks(
                Lq, parityLen, rowWeight, rowOffset, columnIndex, calcAllParityChecks
            )
            #目前单元测试没覆盖
            if !result
                break
            end
        end
    end

    if !earlyTermination && calcAllParityChecks
        a, finalParityChecks = computeParityChecks(
            Lq, parityLen, rowWeight, rowOffset, columnIndex, calcAllParityChecks
        )
    end

    return Lq, numIter, finalParityChecks
end
