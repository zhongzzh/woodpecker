using TyImageProcessing, Test

@testset "imbinarize" begin
    @testset "scalar thresholds use normalized image ranges" begin
        @test imbinarize(UInt8[0 127; 128 255], 0.5) == Bool[0 0; 1 1]
        @test imbinarize(UInt16[0 32767; 32768 65535], 0.5) == Bool[0 0; 1 1]
        @test imbinarize(Int16[-32768 -1; 0 32767], 0.5) == Bool[0 0; 1 1]
        @test imbinarize(Float32[0 0.5; 0.5001 1], 0.5) == Bool[0 0; 1 1]

        # Comparison is strictly greater than the threshold.
        @test imbinarize(Float64[-1 0; 1 2], 1) == Bool[0 0; 0 1]
    end

    @testset "per-pixel thresholds" begin
        thresholds = [0.0 0.5; 0.75 1.0]
        @test imbinarize(UInt8[1 128; 192 255], thresholds) == Bool[1 1; 1 0]
        @test imbinarize(UInt16[1 32768; 49152 65535], thresholds) == Bool[1 1; 1 0]
        @test imbinarize(Int16[-32767 0; 16384 32767], thresholds) == Bool[1 1; 1 0]
        @test imbinarize(Float64[0.1 0.5; 0.8 1.0], thresholds) == Bool[1 0; 1 0]

        @test_throws DimensionMismatch imbinarize(zeros(UInt8, 2, 2), zeros(2, 3))
    end

    @testset "global Otsu methods and supported classes" begin
        expected = Bool[0 0; 1 1]
        @test imbinarize(UInt8[0 0; 255 255]) == expected
        @test imbinarize(UInt16[0 0; 65535 65535]) == expected
        @test imbinarize(Int16[-32768 -32768; 32767 32767]) == expected
        @test imbinarize(Float32[0 0; 1 1]) == expected

        # The optimal split is above the third sample, rather than fixed at mid-range.
        @test imbinarize(UInt8[0 64; 128 255]) == Bool[0 0; 0 1]
        # A nonzero constant image has no between-class variance, so Otsu returns zero.
        @test imbinarize(fill(UInt8(100), 2, 3)) == trues(2, 3)

        special = Float64[NaN -Inf 0.25; 0.75 1 Inf]
        @test imbinarize(special) == Bool[0 0 0; 1 1 1]
        @test imbinarize(zeros(UInt8, 0, 0)) == falses(0, 0)

        image = UInt8[0 0; 255 255]
        @test imbinarize(image, "GLOBAL") == expected
        @test imbinarize(image; method="g") == expected
        @test imbinarize(@view(image[:, :]); method="") == expected
    end

    @testset "adaptive method and validation" begin
        image = fill(UInt8(100), 3, 3)
        @test imbinarize(image, "ADAPTIVE"; Sensitivity=0.5) == falses(3, 3)
        @test imbinarize(image; method="a", Sensitivity=0.5, ForegroundPolarity="dark") ==
            trues(3, 3)

        @test_throws ArgumentError imbinarize(image; method="local")
        @test_throws ArgumentError imbinarize(image; method="globalized")
        @test_throws ArgumentError imbinarize(image; method="adaptive-local")
        @test_throws ErrorException imbinarize(image; method="adaptive", Sensitivity=-0.1)
        @test_throws ErrorException imbinarize(
            image; method="adaptive", ForegroundPolarity="neither"
        )
    end
end
