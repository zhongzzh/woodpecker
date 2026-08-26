using TyImageProcessing, Test

@testset "illumgray" begin
    @testset "case image" begin
        A = imread("foosball.jpg")
        A_lin = rgb2lin(A)
        percentiles = 10
        illuminant = illumgray(A_lin, percentiles)
        @test size(illuminant) == (1, 3)
        @test eltype(illuminant) == Float64
    end

    @testset "synthetic usage" begin
        A = cat(fill(0.1, 4, 4), fill(0.2, 4, 4), fill(0.4, 4, 4); dims=3)
        mask = trues(4, 4)
        mask[1:2, 1:2] .= false

        @test illumgray(A, 0) ≈ [0.1 0.2 0.4]
        @test illumgray(A, [0 0]) ≈ [0.1 0.2 0.4]
        @test illumgray(A; Mask=mask, Norm=2) ≈ [0.1 0.2 0.4] ./ sqrt(count(mask))

        B = fill(UInt8(128), 4, 4, 3)
        @test illumgray(B, 0) ≈ fill(128 / 255, 1, 3)
    end

    @testset "validation" begin
        A = rand(4, 4, 3)
        @test_throws Exception illumgray(A, NaN)
        @test_throws Exception illumgray(A, -1)
        @test_throws Exception illumgray(A, 100)
        @test_throws Exception illumgray(A, [60 50])
        @test_throws Exception illumgray(A; Mask=falses(4, 4))
        @test_throws Exception illumgray(A; Mask=trues(4, 5))
        @test_throws Exception illumgray(A; Norm=0)
    end
end
