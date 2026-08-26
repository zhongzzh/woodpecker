using TyCommunication
using Test
using TyMathCore
@testset "ldpcDecoderConfig" begin
    @testset "1-ldpcDecoderConfig" begin
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
        cfgLDPCDec = ldpcDecoderConfig(pcmatrix)
        cfgLDPCDec1 = ldpcDecoderConfig(pcmatrix, "layered-bp")
        cfgLDPCDec2 = ldpcDecoderConfig(pcmatrix, "norm-min-sum")
        cfgLDPCDec3 = ldpcDecoderConfig(pcmatrix, "offset-min-sum")
        cfgLDPCDec4 = ldpcDecoderConfig(sparse([true true true]))
        show(ldpcDecoderConfig())
        show(cfgLDPCDec)
        show(cfgLDPCDec1)
        show(cfgLDPCDec2)
        show(cfgLDPCDec3)
        show(cfgLDPCDec4)
    end
    @testset "2-ldpcDecoderConfig" begin
        msg1 = "Need a sparse logical matrix or an ldpcEncoderConfig object."
        @test_throws ArgumentError(msg1) ldpcDecoderConfig(; ParityCheckMatrix=[2 2])
        @test_throws ArgumentError(msg1) ldpcDecoderConfig(; ParityCheckMatrix=[1 1 1]')
    end
    @testset "属性 read only" begin
        # BlockLength = pkgdir(TyRF) * "/examples/rfnetparamfiles/passive.s2p"
        cfgLDPCDec = ldpcDecoderConfig()
        @test_throws ArgumentError(
            "Unable to set the 'BlockLength' property of the 'ldpcDecoderConfig'  class because it is a read-only property.",
        ) cfgLDPCDec.BlockLength = 1
        @test_throws ArgumentError(
            "Unable to set the 'NumInformationBits' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
        ) cfgLDPCDec.NumInformationBits = 1
        @test_throws ArgumentError(
            "Unable to set the 'NumParityCheckBits' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
        ) cfgLDPCDec.NumParityCheckBits = 1
        @test_throws ArgumentError(
            "Unable to set the 'CodeRate' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
        ) cfgLDPCDec.CodeRate = 1
        @test_throws ArgumentError(
            "Unable to set the 'NumRowsPerLayer' property of the 'ldpcDecoderConfig' class because it is a read-only property.",
        ) cfgLDPCDec.NumRowsPerLayer = 1
    end
end
