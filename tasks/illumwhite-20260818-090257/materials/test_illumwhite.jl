using TyImageProcessing, Test

@testset "illumwhite" begin
    @testset "case image" begin
        A = imread("foosball.jpg")
        topPercentile = 5
        illuminant = illumwhite(A, topPercentile)
        @test size(illuminant) == (1, 3)
        @test eltype(illuminant) == Float64
    end

    @testset "percentile and mask" begin
        A = zeros(UInt8, 4, 4, 3)
        A[:, :, 1] .= 10
        A[:, :, 2] .= 20
        A[:, :, 3] .= 40
        A[1, 1, :] .= UInt8[200, 210, 220]

        @test illumwhite(A, 1) ≈ reshape(Float64[200, 210, 220] ./ 255, 1, 3)

        mask = trues(4, 4)
        mask[1, 1] = false
        @test illumwhite(A; Mask=mask) ≈ reshape(Float64[10, 20, 40] ./ 255, 1, 3)

        numericMask = Float64.(mask)
        @test illumwhite(A, 1; Mask=numericMask) ≈ reshape(Float64[10, 20, 40] ./ 255, 1, 3)
    end

    @testset "input validation" begin
        A = zeros(Float64, 4, 4, 3)
        @test_throws Exception illumwhite(A, NaN)
        @test_throws Exception illumwhite(A, -1)
        @test_throws Exception illumwhite(A, 100)
        @test_throws Exception illumwhite(A; Mask=falses(4, 4))
        @test_throws Exception illumwhite(A; Mask=trues(3, 4))
        @test_throws Exception illumwhite(A; Mask=fill(NaN, 4, 4))
        @test_throws Exception illumwhite(A; Mask=trues(4, 4, 1))
    end
end
