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

@testset "illumwhite 补充" begin
    @testset "A Float32、UInt16、Float64 正常路径" begin
        A32 = zeros(Float32, 4, 4, 3)
        @test illumwhite(A32, 1) ≈ zeros(1, 3)

        A16 = zeros(UInt16, 4, 4, 3)
        @test illumwhite(A16, 1) ≈ zeros(1, 3)

        A64 = ones(Float64, 4, 4, 3)
        @test illumwhite(A64, 1) ≈ ones(1, 3)
    end

    @testset "topPercentile 类型与 0 边界" begin
        A = zeros(UInt8, 4, 4, 3)
        A[:, :, 1] .= 10
        A[:, :, 2] .= 20
        A[:, :, 3] .= 40
        A[1, 1, :] .= UInt8[200, 210, 220]
        expected = reshape(Float64[200, 210, 220] ./ 255, 1, 3)

        @test illumwhite(A, 0) ≈ expected

        for p in (Int8(1), Int16(1), Int32(1), Float32(1.0), Float64(1.0))
            @test illumwhite(A, p) ≈ expected
        end

        @test illumwhite(A) ≈ expected
    end

    @testset "Mask 数值类型与非 1 非零值" begin
        A = zeros(UInt8, 4, 4, 3)
        A[:, :, 1] .= 10
        A[:, :, 2] .= 20
        A[:, :, 3] .= 40
        A[1, 1, :] .= UInt8[200, 210, 220]
        expected_all = reshape(Float64[200, 210, 220] ./ 255, 1, 3)
        expected_excl = reshape(Float64[10, 20, 40] ./ 255, 1, 3)

        for T in (Float32, Int8, Int16, UInt32, UInt64)
            M = ones(T, 4, 4)
            @test illumwhite(A; Mask=M) ≈ expected_all
        end

        mixed = fill(2.0, 4, 4)
        mixed[1, 1] = 0.0
        @test illumwhite(A; Mask=mixed) ≈ expected_excl
    end
end
