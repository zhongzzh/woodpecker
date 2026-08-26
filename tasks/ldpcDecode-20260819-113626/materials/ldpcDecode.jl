using TyCommunication
using Test
using TyMathCore
using TyFileIO
@testset "ldpcDecode" begin
    @testset "1-ldpcDecode" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix)
        M = 4
        maxnumiter = 10
        snr = [3]
        numframes = 10
        ber = comm_ErrorRate()
        ber2 = comm_ErrorRate()

        for ii in 1:length(snr)
            global errStats, errStats1
            global errStatsNoCoding, errStatsNoCoding1
            errStats = zeros(1, 3)
            errStatsNoCoding = zeros(1, 3)
            errStats1 = zeros(1, 3)
            errStatsNoCoding1 = zeros(1, 3)
            for counter in 1:numframes
                rng = MT19937ar(1234)
                data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
                # Transmit and receive with LDPC coding
                encodedData = ldpcEncode(data, cfgLDPCEnc)
                modSignal = pskmod(encodedData, M; InputType="bit")
                rxsig, noisevar = awgn(rng, modSignal, snr[ii]; nargout=2)
                demodSignal = pskdemod(
                    rxsig, M; OutputType="approxllr", NoiseVariance=noisevar
                )
                rxbits = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter; nargout=1)
                errStats = step(ber, data, rxbits)
                #Transmit and receive with no LDPC coding
                noCoding = pskmod(data, M; InputType="bit")
                rxNoCoding = awgn(rng, noCoding, snr[ii])
                rxBitsNoCoding = pskdemod(rxNoCoding, M; OutputType="bit")
                errStatsNoCoding = step(ber2, data, Int8.(rxBitsNoCoding))
            end
        end
        w1 = [
            0.106995884773663
            520
            4860
        ]
        w2 = [
            0.045267489711934
            220
            4860
        ]
        @test all(abs.(errStats .- w1) .< 1e-10)
        @test all(abs.(errStatsNoCoding .- w2) .< 1e-10)
    end
    @testset "2-ldpcDecode" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix)
        M = 4
        maxnumiter = 10
        snr = [3]
        numframes = 10
        ber = comm_ErrorRate()
        ber2 = comm_ErrorRate()
        for ii in 1:length(snr)
            global errStats, errStats1
            global errStatsNoCoding, errStatsNoCoding1
            errStats = zeros(1, 3)
            errStatsNoCoding = zeros(1, 3)
            errStats1 = zeros(1, 3)
            errStatsNoCoding1 = zeros(1, 3)
            for counter in 1:numframes
                rng = MT19937ar(1234)
                data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
                # Transmit and receive with LDPC coding
                encodedData = ldpcEncode(data, cfgLDPCEnc)
                modSignal = pskmod(encodedData, M; InputType="bit")
                rxsig, noisevar = awgn(rng, modSignal, snr[ii]; nargout=2)
                demodSignal = pskdemod(
                    rxsig, M; OutputType="approxllr", NoiseVariance=noisevar
                )
                #1
                rxbits = ldpcDecode(
                    demodSignal, cfgLDPCDec, maxnumiter; OutputFormat="whole", nargout=1
                )
                errStats = step(ber, data, rxbits[1:length(data)])
                #Transmit and receive with no LDPC coding
                noCoding = pskmod(data, M; InputType="bit")
                rxNoCoding = awgn(rng, noCoding, snr[ii])
                rxBitsNoCoding = pskdemod(rxNoCoding, M; OutputType="bit")
                errStatsNoCoding = step(ber2, data, Int8.(rxBitsNoCoding))
            end
        end
        w1 = [
            0.106995884773663
            520
            4860
        ]
        w2 = [
            0.045267489711934
            220
            4860
        ]
        @test all(abs.(errStats .- w1) .< 1e-10)
        @test all(abs.(errStatsNoCoding .- w2) .< 1e-10)
    end
    @testset "3-ldpcDecode" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix)
        M = 4
        snr = 3
        maxnumiter = 10
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        rxbits = ldpcDecode(
            demodSignal,
            cfgLDPCDec,
            maxnumiter;
            OutputFormat="whole",
            DecisionType="soft",
            nargout=1,
        )
        d = load(joinpath(@__DIR__, "Resources", "ldpcDecode", "ldpcDecode_3.mat"))
        rxbitsm = d["rxbitsm"]
        @test maximum(abs, rxbits - rxbitsm) < 1e-10
    end
    @testset "4-ldpcDecode--Algorithm=bp" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix)
        M = 4
        snr = 3
        maxnumiter = 10
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        rxbits = ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft", nargout=1
        )
        d = load(joinpath(@__DIR__, "Resources", "ldpcDecode", "ldpcDecode_4.mat"))
        rxbitsm = d["rxbitsm"]
        @test maximum(abs, rxbits - rxbitsm) < 1e-10
    end
    @testset "5-ldpcDecode--Algorithm=layered-bp" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix, "layered-bp")
        M = 4
        snr = 3
        maxnumiter = 10
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        demodSignal1 = zeros(length(encodedData), 1)
        demodSignal2 = [0; demodSignal[2:end];;]
        rxbits, a, b = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft")
        rxbits1 = ldpcDecode(
            demodSignal1, cfgLDPCDec, maxnumiter; DecisionType="soft", nargout=1
        )
        rxbits2 = ldpcDecode(
            demodSignal2, cfgLDPCDec, maxnumiter; DecisionType="soft", nargout=1
        )
        rxbits3, a, b = ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft", Termination="max"
        )
        d = load(joinpath(@__DIR__, "Resources", "ldpcDecode", "ldpcDecode_5.mat"))
        rxbitsm = d["rxbitsm"]
        rxbitsm1 = d["rxbitsm1"]
        rxbitsm2 = d["rxbitsm2"]
        rxbitsm3 = d["rxbitsm3"]
        @test maximum(abs, rxbits - rxbitsm) < 1e-10
        @test maximum(abs, rxbits1 - rxbitsm1) < 1e-10
        @test maximum(abs, rxbits2 - rxbitsm2) < 1e-10
        @test maximum(abs, rxbits3 - rxbitsm3) < 1e-10
    end
    @testset "6-ldpcDecode--Algorithm=norm-min-sum" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix, "norm-min-sum")
        M = 4
        snr = 3
        maxnumiter = 30
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        demodSignal1 = zeros(length(encodedData), 1)
        demodSignal2 = [0; demodSignal[2:end];;]
        rxbits, a, b = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft")
        rxbits1 = ldpcDecode(
            demodSignal1,
            cfgLDPCDec,
            maxnumiter;
            DecisionType="soft",
            Termination="max",
            nargout=1,
        )
        rxbits2, a, b = ldpcDecode(
            demodSignal2, cfgLDPCDec, maxnumiter; DecisionType="soft", Termination="max"
        )
        d = load(joinpath(@__DIR__, "Resources", "ldpcDecode", "ldpcDecode_6.mat"))
        rxbitsm = d["rxbitsm"]
        rxbitsm1 = d["rxbitsm1"]
        rxbitsm2 = d["rxbitsm2"]
        @test maximum(abs, rxbits - rxbitsm) < 1e-6
        @test maximum(abs, rxbits1 - rxbitsm1) < 1e-10
        @test maximum(abs, rxbits2 - rxbitsm2) < 1e-6
    end
    @testset "7-ldpcDecode--Algorithm=norm-min-sum" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix, "norm-min-sum")
        M = 4
        snr = 3
        maxnumiter = 30
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        rxbits, a, b = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft")
        rxbits1, c = ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft", nargout=2
        )
        rxbits2 = ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft", nargout=1
        )
        d = load(joinpath(@__DIR__, "Resources", "ldpcDecode", "ldpcDecode_7.mat"))
        rxbitsm = d["rxbitsm"]
        rxbitsm1 = d["rxbitsm1"]
        rxbitsm2 = d["rxbitsm2"]
        @test maximum(abs, rxbits - rxbitsm) < 1e-6
        @test maximum(abs, rxbits1 - rxbitsm1) < 1e-6
        @test maximum(abs, rxbits2 - rxbitsm2) < 1e-6
    end
    @testset "8-ldpcDecode--Algorithm=offset-min-sum" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix, "offset-min-sum")
        M = 4
        snr = 3
        maxnumiter = 30
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        demodSignal1 = zeros(length(encodedData), 1)
        rxbits1, a, b = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft")
        rxbits2, a, b = ldpcDecode(
            demodSignal1, cfgLDPCDec, maxnumiter; DecisionType="soft", Termination="max"
        )
        d = load(joinpath(@__DIR__, "Resources", "ldpcDecode", "ldpcDecode_8.mat"))
        rxbitsm1 = d["rxbitsm1"]
        @test maximum(abs, rxbits1 - rxbitsm1) < 1e-6

        @test all(iszero, rxbits2)
    end

    @testset "errorest-ldpcDecode" begin
        P = [
            16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
            25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
            25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
            9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
            24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
            2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
        ]
        blockSize = 27
        pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
        cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix, "offset-min-sum")
        M = 4
        snr = 3
        maxnumiter = 30
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        # rxbits1, a, b = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter; DecisionType="soft")
        msg1 = "the second input argument must be an ldpcDecoderConfig object"
        msg2 = "OutputFormat must be info or whole"
        msg3 = "DecisionType must be hard or soft"
        msg4 = "Termination must be early or max"
        msg5 = "The MinSumScalingFactor is wrong"
        msg6 = "The Multithreaded is wrong"
        msg7 = "The MinSumOffset is wrong"
        @test_throws ErrorException(msg1) ldpcDecode(
            demodSignal, cfgLDPCEnc, maxnumiter; DecisionType="soft"
        )
        @test_throws ErrorException(msg2) ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; OutputFormat="aaa"
        )
        @test_throws ErrorException(msg3) ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; DecisionType="aaa"
        )
        @test_throws ErrorException(msg4) ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; Termination="aaa"
        )
        @test_throws ErrorException(msg5) ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; MinSumScalingFactor=2
        )
        @test_throws ErrorException(msg6) ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; Multithreaded="aaa"
        )
        @test_throws ErrorException(msg7) ldpcDecode(
            demodSignal, cfgLDPCDec, maxnumiter; MinSumOffset="aaa"
        )
    end
end
