using TyImageProcessing
using Test

@testset "localcontrast" begin
    A = reshape(UInt8.(mod.(0:191, 256)), 8, 8, 3)
    internal = TyImageProcessing.__Internal__

    @testset "defaults and output shape" begin
        B = localcontrast(A)
        @test size(B) == size(A)
        @test eltype(B) == eltype(A)

        G = reshape(Float32.(range(0, 1; length=64)), 8, 8)
        H = localcontrast(G, 0.4, 0.5)
        @test size(H) == size(G)
        @test eltype(H) == Float32
    end

    @testset "Float32 RGB and LUT paths" begin
        rgb32 = Float32.(A) ./ Float32(255)
        enhancedRGB = localcontrast(rgb32, 0.4, 0.5)
        @test size(enhancedRGB) == size(rgb32)
        @test eltype(enhancedRGB) == Float32
        @test all(isfinite, enhancedRGB)

        largeGray = reshape(Float32.(range(0, 1; length=96 * 96)), 96, 96)
        enhancedLarge = localcontrast(largeGray, 0.4, 0.5)
        @test size(enhancedLarge) == size(largeGray)
        @test eltype(enhancedLarge) == Float32
        @test all(isfinite, enhancedLarge)

        remapped = similar(Float32[0.4, 0.405, 0.415, 0.45, 0.9])
        internal._localcontrast_remap!(
            remapped, Float32[0.4, 0.405, 0.415, 0.45, 0.9], 0.4f0, 0.4f0, 0.505f0, 1.0f0
        )
        @test remapped[1:2] ≈ Float32[0.4, 0.405] atol = 1.0f-6
        @test all(isfinite, remapped)
    end
    @testset "MATLAB reference outputs" begin
        sampleIndices = [1, 8, 9, 32, 64, 65, 96, 128, 129, 160, 192]

        enhanced = localcontrast(A, 0.4, 0.5)
        @test sum(Int, enhanced) == 21069
        @test sum(x -> Int(x)^2, enhanced) == 3275525
        @test Int.(enhanced[sampleIndices]) == [0, 5, 7, 35, 89, 36, 108, 180, 73, 181, 255]

        reduced = localcontrast(A, 0.4, -0.5)
        @test sum(Int, reduced) == 15936
        @test sum(x -> Int(x)^2, reduced) == 1846976
        @test Int.(reduced[sampleIndices]) ==
            [19, 19, 19, 19, 19, 83, 83, 83, 147, 147, 147]
    end

    @testset "MATLAB pyramid impulse response" begin
        impulse = zeros(Float32, 5, 9)
        impulse[:, 1] .= 1
        downsampled = TyImageProcessing.__Internal__._localcontrast_pyrdownsample(impulse)
        @test downsampled[2, :] ≈ Float32[0.65, 0.05, 0, 0, 0] atol = 1.0f-6
    end
    @testset "no-op cases" begin
        @test localcontrast(A, 0, 0.5) === A
        @test localcontrast(A, 0.4, 0) === A
    end

    @testset "scalar array inputs" begin
        B = localcontrast(A, [0.4], [0.5])
        @test size(B) == size(A)
        @test eltype(B) == UInt8
    end
    @testset "validation" begin
        @test_throws ErrorException localcontrast()
        @test_throws ErrorException localcontrast(1, 0.4, 0.5)
        @test_throws ErrorException localcontrast(Array{UInt8}(undef, 0, 0), 0.4, 0.5)
        @test_throws ErrorException localcontrast(A, Float64[], 0.5)
        @test_throws ErrorException localcontrast(A, "invalid", 0.5)
        @test_throws ErrorException localcontrast(A, 0.4, true)
        @test_throws ErrorException localcontrast(A, 0.4, 0.5, 1)
        @test_throws ErrorException localcontrast(rand(Float64, 8, 8), 0.4, 0.5)
        @test_throws ErrorException localcontrast(reshape(UInt8.(1:64), 8, 8, 1), 0.4, 0.5)
        @test_throws ErrorException localcontrast(A, -0.1, 0.5)
        @test_throws ErrorException localcontrast(A, 1.1, 0.5)
        @test_throws ErrorException localcontrast(A, 0.4, -1.1)
        @test_throws ErrorException localcontrast(A, 0.4, 1.1)
        @test_throws ErrorException localcontrast(A, [0.3, 0.4], 0.5)
        @test_throws ErrorException localcontrast(A, 0.4, NaN)
    end
end
