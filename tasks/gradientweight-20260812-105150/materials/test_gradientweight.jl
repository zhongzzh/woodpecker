using TyImageProcessing, Test

const _GRADIENTWEIGHT_INTERNAL = TyImageProcessing.__Internal__

@testset "gradientweight" begin
    @testset "src" begin
        I = imread("coins.png")
        sigma = 1.5
        W = gradientweight(I, sigma; RolloffFactor=3, WeightCutoff=0.25)
        @test size(W) == size(I) &&
            eltype(W) == ((eltype(I) == Float32) ? Float32 : Float64)

        W_default = gradientweight(I)
        W_sigma = gradientweight(I, sigma)
        @test W_default ≈ W_sigma

        If32 = Float32.(I) ./ Float32(255)
        Wf32 = gradientweight(If32, Float32(1.5))
        @test size(Wf32) == size(If32) && eltype(Wf32) == Float32

        constantI = fill(UInt8(7), 8, 9)
        Wconstant = gradientweight(constantI)
        @test size(Wconstant) == size(constantI) && all(Wconstant .== 1)

        volume = reshape(Int16.(1:27), 3, 3, 3)
        Wvolume = gradientweight(volume, [1, 1, 1])
        @test size(Wvolume) == size(volume) && eltype(Wvolume) == Float64
        @testset "validation and sigma coverage" begin
            small2 = reshape(Float64.(1:9), 3, 3)
            small3 = reshape(Float64.(1:27), 3, 3, 3)

            Wsigma2 = gradientweight(small2, [1, 2])
            @test size(Wsigma2) == size(small2) && eltype(Wsigma2) == Float64

            Wsigma3 = gradientweight(small3, 1)
            @test size(Wsigma3) == size(small3) && eltype(Wsigma3) == Float64

            @test_throws ErrorException _GRADIENTWEIGHT_INTERNAL.images_internal_imgradientdog(
                small2, [-1, 1]
            )
            @test_throws ErrorException _GRADIENTWEIGHT_INTERNAL.images_internal_imgradientdog3(
                small3, [-1, 1, 1]
            )
            @test_throws ErrorException _GRADIENTWEIGHT_INTERNAL.images_internal_imgradientdog3(
                small3, [1, 1]
            )
        end
    end
end

@testset "gradientweight 补充" begin
    source_values = reshape(collect(1:12), 3, 4)

    @testset "缺失的 I 元素类型" begin
        for T in (Int8, UInt16, Int32, UInt32)
            I = T.(source_values)
            W = gradientweight(I, 1.5)

            @test eltype(W) == Float64
            @test all(isfinite, W)
            @test all((W .>= 1e-3) .& (W .<= 1.0))
        end
    end

    @testset "RolloffFactor Float64 正标量" begin
        I = Float64.(source_values)
        W = gradientweight(I, 1.5; RolloffFactor=2.0)

        @test eltype(W) == Float64
        @test all(isfinite, W)
        @test all((W .>= 1e-3) .& (W .<= 1.0))
    end
end
