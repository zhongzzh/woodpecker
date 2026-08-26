"""
函数说明：\n
    Modulate frequency-domain signal using orthogonal frequency division multiplexing (OFDM) | 使用正交频分复用（OFDM）调制频域信号\n
示例：\n
    out=ofdmmod(x,nfft,cpLen)
    out=ofdmmod(x,nfft,cpLen,nullidx)
    out=ofdmmod(x,nfft,cpLen,nullidx,pilotidx,pilots)
 """
function ofdmmod(x, nfft, cpLen)
    @ccall_check_func_lic :TyCommunication
    # Validate data input
    numST = size_m(x, 1)
    numSym = size_m(x, 2)
    numTx = size_m(x, 3)

    NumSymbols = numSym
    NumTransmitAntennas = numTx
    # Check nfft - scalar, positive integer > 8. 
    FFTLength = nfft
    if nfft < 8
        error("nfft must be a scalar that not less than 8.")
    end
    # Check cplen - scalar or vector, in range [0 nfft]
    if isa(cpLen, Int64)
        if cpLen < 0 || cpLen > nfft
            error(
                "CPLEN must be a scalar or a row vector of length equal to number of OFDM symbols,with values between 0 and NFFT,inclusive.",
            )
        end
    else
        if length(cpLen) != numSym || findfirst(i -> i < 0 || i > nfft, cpLen) !== nothing
            error(
                "CPLEN must be a scalar or a row vector of length equal to number of OFDM symbols,with values between 0 and NFFT,inclusive.",
            )
        end
    end
    # Calculate the DataIndices
    numPilots = 0
    if numST + numPilots != FFTLength
        error("comm:OFDM:InvalidPacking")
    end
    dataIdx = convert.(Int64, (1:nfft)')
    fftLen = FFTLength
    numSym = NumSymbols
    numTx = NumTransmitAntennas
    # Pack input data into grid
    fullGrid = complex.(zeros(fftLen, numSym, numTx), zeros(fftLen, numSym, numTx))
    fullGrid[dataIdx, 1:numSym, 1:numTx] = x[:, 1:numSym, 1:numTx]
    gridIn = copy(fullGrid)
    # call internal fcn to compute output
    # IFFT shift    
    if eltype(gridIn) <: Real
        postShift = complex(ifftshift(gridIn, 1), 0)
    else
        postShift = ifftshift(gridIn, 1)
    end
    # IFFT    
    postIFFT = ifft(postShift, 1)
    # Append cyclic prefix
    if isa(cpLen, Int64) # same length
        postCP = [postIFFT[(1:cpLen[1]) .+ end .- cpLen[1], :, :]; postIFFT]
        yout = reshape(postCP, (fftLen + cpLen[1]) * numSym, numTx)
    else # different lengths per symbol
        yout =
            complex.(
                zeros(fftLen * numSym + sum(cpLen), numTx),
                zeros(fftLen * numSym + sum(cpLen), numTx),
            )
        for symIdx in 1:numSym
            SQ = reshape(postIFFT[:, symIdx, :], size_m(postIFFT, 1), size_m(postIFFT, 3))
            yout[fftLen * (symIdx - 1) + sum(cpLen[1:(symIdx - 1)]) .+ (1:(fftLen + cpLen[symIdx])), :] = [
                reshape(
                    postIFFT[end - cpLen[symIdx] .+ (1:cpLen[symIdx]), symIdx, :],
                    cpLen[symIdx],
                    numTx,
                )
                SQ
            ]
        end
    end
    return yout
end

function ofdmmod(x, nfft, cpLen, nullidx)
    @ccall_check_func_lic :TyCommunication
    # Validate data input
    numST = size_m(x, 1)
    numSym = size_m(x, 2)
    numTx = size_m(x, 3)

    NumSymbols = numSym
    NumTransmitAntennas = numTx
    # Check nfft - scalar, positive integer > 8. 
    FFTLength = nfft
    if nfft < 8
        error("nfft must be a scalar that not less than 8.")
    end
    # Check cplen - scalar or vector, in range [0 nfft]
    if isa(cpLen, Int64)
        if cpLen < 0 || cpLen > nfft
            error(
                "CPLEN must be a scalar or a row vector of length equal to number of OFDM symbols,with values between 0 and NFFT,inclusive.",
            )
        end
    else
        if length(cpLen) != numSym || findfirst(i -> i < 0 || i > nfft, cpLen) !== nothing
            error(
                "CPLEN must be a scalar or a row vector of length equal to number of OFDM symbols,with values between 0 and NFFT,inclusive.",
            )
        end
    end

    # Calculate the DataIndices
    NullIndices = nullidx
    dataIdx = zeros(nfft - length(NullIndices), 1)
    dataIdx = setdiff(1:nfft, NullIndices)

    fftLen = FFTLength
    numSym = NumSymbols
    numTx = NumTransmitAntennas
    # Pack input data into grid
    fullGrid = complex.(zeros(fftLen, numSym, numTx), zeros(fftLen, numSym, numTx))
    fullGrid[dataIdx, 1:numSym, 1:numTx] = x[:, 1:numSym, 1:numTx]
    gridIn = copy(fullGrid)
    # call internal fcn to compute output
    # IFFT shift    
    if eltype(gridIn) <: Real
        postShift = complex(ifftshift(gridIn, 1), 0)
    else
        postShift = ifftshift(gridIn, 1)
    end
    # IFFT    
    postIFFT = ifft(postShift, 1)
    # Append cyclic prefix
    if isa(cpLen, Int64) # same length
        postCP = [postIFFT[(1:cpLen[1]) .+ end .- cpLen[1], :, :]; postIFFT]
        yout = reshape(postCP, (fftLen + cpLen[1]) * numSym, numTx)
    else # different lengths per symbol
        yout =
            complex.(
                zeros(fftLen * numSym + sum(cpLen), numTx),
                zeros(fftLen * numSym + sum(cpLen), numTx),
            )
        for symIdx in 1:numSym
            SQ = reshape(postIFFT[:, symIdx, :], size_m(postIFFT, 1), size_m(postIFFT, 3))
            yout[fftLen * (symIdx - 1) + sum(cpLen[1:(symIdx - 1)]) .+ (1:(fftLen + cpLen[symIdx])), :] = [
                reshape(
                    postIFFT[end - cpLen[symIdx] .+ (1:cpLen[symIdx]), symIdx, :],
                    cpLen[symIdx],
                    numTx,
                )
                SQ
            ]
        end
    end
    return yout
end

function ofdmmod(x, nfft, cpLen, nullidx, pilotidx, pilots)
    @ccall_check_func_lic :TyCommunication
    # Validate data input
    numST = size_m(x, 1)
    numSym = size_m(x, 2)
    numTx = size_m(x, 3)

    NumSymbols = numSym
    NumTransmitAntennas = numTx
    # Check nfft - scalar, positive integer > 8. 
    FFTLength = nfft
    if nfft < 8
        error("nfft must be a scalar that not less than 8.")
    end
    # Check cplen - scalar or vector, in range [0 nfft]
    if isa(cpLen, Int64)
        if cpLen < 0 || cpLen > nfft
            error(
                "CPLEN must be a scalar or a row vector of length equal to number of OFDM symbols,with values between 0 and NFFT,inclusive.",
            )
        end
    else
        if length(cpLen) != numSym || findfirst(i -> i < 0 || i > nfft, cpLen) !== nothing
            error(
                "CPLEN must be a scalar or a row vector of length equal to number of OFDM symbols,with values between 0 and NFFT,inclusive.",
            )
        end
    end

    # Calculate the DataIndices
    NullIndices = nullidx

    PilotIndices = pilotidx

    # dataIdx=zeros(nfft-length(NullIndices)-length(PilotIndices),1)
    dataIdx = setdiff(1:nfft, NullIndices)
    dataIdx = setdiff(dataIdx, PilotIndices)

    fftLen = FFTLength
    numSym = NumSymbols
    numTx = NumTransmitAntennas
    # Pack input data into grid
    fullGrid = complex.(zeros(fftLen, numSym, numTx), zeros(fftLen, numSym, numTx))

    fullGrid[dataIdx, 1:numSym, 1:numTx] = x[:, 1:numSym, 1:numTx]
    fullGrid[PilotIndices, 1:numSym, 1:numTx] = pilots[:, 1:numSym, 1:numTx]

    gridIn = copy(fullGrid)

    # call internal fcn to compute output
    # IFFT shift    
    if eltype(gridIn) <: Real
        postShift = complex(ifftshift(gridIn, 1), 0)
    else
        postShift = ifftshift(gridIn, 1)
    end
    # IFFT    
    postIFFT = ifft(postShift, 1)
    # Append cyclic prefix
    if isa(cpLen, Int64) # same length
        postCP = [postIFFT[(1:cpLen[1]) .+ end .- cpLen[1], :, :]; postIFFT]
        yout = reshape(postCP, (fftLen + cpLen[1]) * numSym, numTx)
    else # different lengths per symbol
        yout =
            complex.(
                zeros(fftLen * numSym + sum(cpLen), numTx),
                zeros(fftLen * numSym + sum(cpLen), numTx),
            )
        for symIdx in 1:numSym
            SQ = reshape(postIFFT[:, symIdx, :], size_m(postIFFT, 1), size_m(postIFFT, 3))
            yout[fftLen * (symIdx - 1) + sum(cpLen[1:(symIdx - 1)]) .+ (1:(fftLen + cpLen[symIdx])), :] = [
                reshape(
                    postIFFT[end - cpLen[symIdx] .+ (1:cpLen[symIdx]), symIdx, :],
                    cpLen[symIdx],
                    numTx,
                )
                SQ
            ]
        end
    end
    return yout
end
