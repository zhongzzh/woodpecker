using TyImageProcessing, Test

@testset "edgetaper" begin
    @testset "example workload" begin
        original = imread("cameraman.tif")
        PSF = fspecial("gaussian", 60, 10)
        edgesTapered = edgetaper(original, PSF)
        @test eltype(edgesTapered) == eltype(original)
        @test size(edgesTapered) == size(original)
        lo, hi = extrema(original)
        @test all((edgesTapered .>= lo) .& (edgesTapered .<= hi))
    end

    @testset "class and dimensional behavior" begin
        I32 = fill(Float32(0.25), 32, 32)
        PSF = fspecial("gaussian", 5, 1)
        J32 = edgetaper(I32, PSF)
        @test eltype(J32) == Float32
        @test size(J32) == size(I32)
        @test J32 ≈ I32

        RGB = fill(UInt8(120), 16, 16, 3)
        JRGB = edgetaper(RGB, ones(Float64, 3, 3))
        @test eltype(JRGB) == UInt8
        @test size(JRGB) == size(RGB)
        @test all(JRGB .== RGB)
    end

    @testset "input validation" begin
        I = ones(Float64, 16, 16)
        @test_throws ErrorException edgetaper(I, zeros(Float64, 3, 3))
        @test_throws ErrorException edgetaper(I, [1.0])
        @test_throws ErrorException edgetaper(I, [NaN 1.0; 1.0 1.0])
        @test_throws ErrorException edgetaper(ones(Float64, 4, 4), ones(Float64, 2, 2))
    end
end
