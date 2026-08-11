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


@testset "edgetaper 补充" begin
    @testset "integer image and PSF classes" begin
        I16 = fill(Int16(24), 16, 16)
        PSF16 = fill(Int16(1), 3, 3)
        J16 = edgetaper(I16, PSF16)
        @test eltype(J16) == Int16
        @test size(J16) == size(I16)
        @test all(isfinite, J16)
        @test all(J16 .== I16)

        Iu16 = fill(UInt16(240), 16, 16)
        PSFu16 = fill(UInt16(1), 3, 3)
        Ju16 = edgetaper(Iu16, PSFu16)
        @test eltype(Ju16) == UInt16
        @test size(Ju16) == size(Iu16)
        @test all(isfinite, Ju16)
        @test all(Ju16 .== Iu16)
    end

    @testset "Float64 image success path and near-boundary PSF" begin
        I64 = fill(Float64(0.4), 5, 5)
        PSF64 = fill(Float64(1.0), 2, 2)
        J64 = edgetaper(I64, PSF64)
        @test eltype(J64) == Float64
        @test size(J64) == size(I64)
        @test all(isfinite, J64)
        @test all(J64 .== I64)
    end

    @testset "additional PSF classes" begin
        I32 = fill(Float32(0.35), 16, 16)

        PSF32 = fill(Float32(1), 3, 3)
        J32 = edgetaper(I32, PSF32)
        @test eltype(J32) == Float32
        @test size(J32) == size(I32)
        @test all(isfinite, J32)

        PSFu8 = fill(UInt8(1), 3, 3)
        Ju8 = edgetaper(I32, PSFu8)
        @test eltype(Ju8) == Float32
        @test size(Ju8) == size(I32)
        @test all(isfinite, Ju8)
    end

    @testset "three-dimensional PSF" begin
        I3 = fill(Float32(0.6), 8, 8, 8)
        PSF3 = fill(Float64(1.0), 3, 3, 3)
        J3 = edgetaper(I3, PSF3)
        @test eltype(J3) == Float32
        @test size(J3) == size(I3)
        @test all(isfinite, J3)
        @test all(J3 .== I3)
    end
end