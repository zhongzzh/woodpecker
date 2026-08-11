using TyImageProcessing, Test

@testset "psnr" begin
    @testset "default peak values and output types" begin
        cases = (
            (UInt8, 255.0),
            (UInt16, 65535.0),
            (Int16, 65535.0),
            (Float32, 1.0f0),
            (Float64, 1.0),
        )

        for (T, peak) in cases
            reference = T[1 2; 3 4]
            source = reference .+ T(1)
            result = psnr(source, reference)

            @test result ≈ 20 * log10(peak)
            @test typeof(result) === (T === Float32 ? Float32 : Float64)
            @test psnr(reference, source) ≈ result
        end

        @test isinf(psnr(fill(0.5, 2, 2), fill(0.5, 2, 2)))
    end

    @testset "custom peak and SNR output" begin
        source = [2.0, 4.0]
        reference = [1.0, 2.0]

        @test psnr(source, reference, 4; nargout=1) ≈ 10 * log10(16 / 2.5)
        peaksnr, snr = psnr(source, reference; nargout=2, DataFormat="S")
        @test peaksnr ≈ 10 * log10(1 / 2.5)
        @test snr ≈ 0.0 atol = 10eps()
    end

    @testset "batch dimension" begin
        reference = reshape(Float32[1, 2, 2, 2], 2, 1, 2)
        source = reference .+ reshape(Float32[1, 1, 2, 2], 2, 1, 2)

        peaksnr, snr = psnr(source, reference, 4; nargout=2, DataFormat="SSB")
        @test size(peaksnr) == (1, 1, 2)
        @test eltype(peaksnr) === Float32
        @test vec(peaksnr) ≈ Float32[10 * log10(16), 10 * log10(4)]
        @test vec(snr) ≈ Float32[10 * log10(2.5), 0]

        batch_first = permutedims(source, (3, 1, 2))
        reference_first = permutedims(reference, (3, 1, 2))
        @test vec(psnr(batch_first, reference_first, 4; DataFormat="BSS")) ≈ vec(peaksnr)

        @test psnr(source, reference, 4; DataFormat="SSC") ≈ 10 * log10(16 / 2.5)
        @test psnr(source, reference, 4; DataFormat="") ≈ 10 * log10(16 / 2.5)
    end

    @testset "empty inputs" begin
        vector_result = psnr(UInt8[], UInt8[])
        @test vector_result == UInt8[]

        peaksnr, snr = psnr(Float32[], Float32[]; nargout=2)
        @test peaksnr == Float32[]
        @test snr == Float32[]
        @test peaksnr !== snr

        @test size(psnr(zeros(0, 3), zeros(0, 3))) == (0, 0)
        @test size(psnr(zeros(Float32, 0, 3), zeros(Float32, 0, 3); DataFormat="")) ==
            (0, 0)
        @test size(
            psnr(zeros(Float32, 0, 3, 2), zeros(Float32, 0, 3, 2); DataFormat="SCB")
        ) == (0, 0, 1)
        @test size(
            psnr(zeros(Float32, 2, 0, 3), zeros(Float32, 2, 0, 3); DataFormat="BSS")
        ) == (1, 0, 0)
        @test psnr(Float64[], Float64[]; DataFormat="B") == Float64[]
    end

    @testset "invalid inputs" begin
        image = zeros(Float64, 2, 2)

        @test_throws ErrorException psnr(image, zeros(Float64, 2, 3))
        @test_throws MethodError psnr(image, zeros(Float32, 2, 2))
        @test_throws MethodError psnr(zeros(UInt32, 2), zeros(UInt32, 2))
        @test_throws ArgumentError psnr(image, image; nargout=0)
        @test_throws ArgumentError psnr(image, image; nargout=3)
        @test_throws ArgumentError psnr(image, image, -1)
        @test_throws ArgumentError psnr(image, image, NaN)
        @test_throws ArgumentError psnr(image, image; DataFormat="S")
        @test_throws ArgumentError psnr(image, image; DataFormat="SX")
        @test_throws ArgumentError psnr(zeros(2, 2, 2), zeros(2, 2, 2); DataFormat="SCC")
        @test_throws ArgumentError psnr(zeros(2, 2, 2), zeros(2, 2, 2); DataFormat="SBB")
    end
end
