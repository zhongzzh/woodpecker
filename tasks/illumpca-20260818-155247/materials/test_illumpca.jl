using TyImageProcessing, Test

@testset "illumpca" begin
    @testset "case image" begin
        A = imread("foosball.jpg")
        A_lin = rgb2lin(A)
        illuminant = illumpca(A_lin)
        @test size(illuminant) == (1, 3)
        @test eltype(illuminant) == Float64
    end

    @testset "percentage and mask" begin
        A = reshape(Float64.(1:144) ./ 144, 8, 6, 3)
        illuminant = illumpca(A, 10)
        @test isapprox(
            illuminant, [0.197316127987269 0.515568092535569 0.833820057083869]; rtol=1e-12
        )

        mask = trues(8, 6)
        mask[2:4, 3:5] .= false
        maskedIlluminant = illumpca(A, 10; Mask=mask)
        @test isapprox(
            maskedIlluminant,
            [0.198411829816480 0.515887192963055 0.833362556109630];
            rtol=1e-12,
        )

        numericMask = Float64.(mask)
        @test illumpca(A, 10; Mask=numericMask) ≈ maskedIlluminant

        smallA = reshape(Float64.(1:12) ./ 12, 2, 2, 3)
        @test size(illumpca(smallA, 1)) == (1, 3)
        @test illumpca(zeros(Float32, 4, 4, 3)) == zeros(1, 3)
    end

    @testset "input validation" begin
        A = zeros(Float64, 4, 4, 3)
        @test_throws Exception illumpca(A, NaN)
        @test_throws Exception illumpca(A, 0)
        @test_throws Exception illumpca(A, 51)
        @test_throws Exception illumpca(A; Mask=falses(4, 4))
        @test_throws Exception illumpca(A; Mask=trues(3, 4))
        @test_throws Exception illumpca(A; Mask=fill(NaN, 4, 4))
        @test_throws Exception illumpca(A; Mask=trues(4, 4, 1))

        nanImage = copy(A)
        nanImage[1] = NaN
        @test_throws Exception illumpca(nanImage)

        infImage = copy(A)
        infImage[1] = Inf
        @test_throws Exception illumpca(infImage)
    end
end

@testset "illumpca 补充" begin
    @testset "A 类型补充" begin
        A_u8 = reshape(UInt8.(1:144), 8, 6, 3)
        illuminant_u8 = illumpca(A_u8)
        @test size(illuminant_u8) == (1, 3)
        @test eltype(illuminant_u8) == Float64
        @test all(x -> 0 <= x <= 1, illuminant_u8)

        A_u16 = reshape(UInt16.(1:144), 8, 6, 3)
        illuminant_u16 = illumpca(A_u16)
        @test size(illuminant_u16) == (1, 3)
        @test all(isfinite, illuminant_u16)
        @test all(x -> 0 <= x <= 1, illuminant_u16)
    end

    @testset "percentage 类型补充" begin
        A = reshape(Float64.(1:144) ./ 144, 8, 6, 3)
        for T in (Float32, Float64, UInt64)
            p = T(10)
            illuminant = illumpca(A, p)
            @test size(illuminant) == (1, 3)
            @test all(isfinite, illuminant)
        end
        @test size(illumpca(A, Float32(3.5))) == (1, 3)
        @test size(illumpca(A, Float64(3.5))) == (1, 3)
        @test size(illumpca(A, 50)) == (1, 3)
    end

    @testset "percentage 缺失整数类型" begin
        A = reshape(Float64.(1:144) ./ 144, 8, 6, 3)
        reference = illumpca(A, Float64(10))

        for T in (Int8, Int16, Int32, UInt8, UInt16, UInt32)
            percentage = T(10)
            illuminant = illumpca(A, percentage)
            @test illuminant ≈ reference
        end
    end

    @testset "Mask 缺失数值类型" begin
        A = reshape(Float64.(1:144) ./ 144, 8, 6, 3)
        logicalMask = trues(8, 6)
        logicalMask[2:4, 3:5] .= false
        reference = illumpca(A, Float64(10); Mask=logicalMask)

        for T in (Float32, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64)
            numericMask = T.(logicalMask)
            illuminant = illumpca(A, Float64(10); Mask=numericMask)
            @test size(illuminant) == (1, 3)
            @test illuminant ≈ reference
        end
    end
end
