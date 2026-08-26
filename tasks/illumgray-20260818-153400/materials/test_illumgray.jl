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
@testset "illumgray 补充" begin
    A32 = cat(
        fill(Float32(0.1), 4, 4), fill(Float32(0.2), 4, 4), fill(Float32(0.4), 4, 4); dims=3
    )
    @test isapprox(illumgray(A32, 0), [0.1 0.2 0.4]; atol=1e-6)

    A16 = fill(UInt16(32768), 4, 4, 3)
    @test isapprox(illumgray(A16, 0), fill(32768 / 65535, 1, 3); atol=1e-12)

    A = cat(fill(0.1, 4, 4), fill(0.2, 4, 4), fill(0.4, 4, 4); dims=3)

    @test illumgray(A, [0.0, 0.0]) ≈ [0.1 0.2 0.4]
    @test illumgray(A, 10.0) ≈ [0.1 0.2 0.4]
    @test illumgray(A, UInt8(10)) ≈ [0.1 0.2 0.4]

    mask_u8 = ones(UInt8, 4, 4)
    mask_u8[1:2, 1:2] .= 0
    @test isapprox(
        illumgray(A; Mask=mask_u8, Norm=2), [0.1 0.2 0.4] ./ sqrt(12); atol=1e-12
    )

    mask_f64 = ones(4, 4)
    mask_f64[1:2, 1:2] .= 0
    @test illumgray(A; Mask=mask_f64) ≈ [0.1 0.2 0.4]

    mask_f32 = ones(Float32, 4, 4)
    mask_f32[1:2, 1:2] .= 0
    @test isapprox(
        illumgray(A; Mask=mask_f32, Norm=2), [0.1 0.2 0.4] ./ sqrt(12); atol=1e-12
    )

    mask = trues(4, 4)
    mask[1:2, 1:2] .= false
    @test isapprox(
        illumgray(A; Mask=mask, Norm=2.0), illumgray(A; Mask=mask, Norm=2); atol=0
    )
    @test isapprox(
        illumgray(A; Mask=mask, Norm=UInt8(2)), illumgray(A; Mask=mask, Norm=2); atol=0
    )

    @test_throws Exception illumgray(rand(0, 0, 3), 0)
    @test_throws Exception illumgray(rand(4, 4, 2), 0)
     
     A = cat(fill(0.1, 4, 4), fill(0.2, 4, 4), fill(0.4, 4, 4); dims=3)
    expected = [0.1 0.2 0.4]

    @test illumgray(A, Float32(50)) ≈ expected
    @test illumgray(A, UInt16(10)) ≈ expected
    @test illumgray(A, Float32[40, 60]) ≈ expected
    @test_throws Exception illumgray(A, 51)
    @test_throws Exception illumgray(A, UInt16[0, 100])

    mask_u16 = ones(UInt16, 4, 4)
    mask_u16[1:2, 1:2] .= 0
    @test isapprox(
        illumgray(A; Mask=mask_u16, Norm=Float32(2)),
        expected ./ sqrt(12);
        atol=1e-12,
    )

    mask = trues(4, 4)
    @test isapprox(
        illumgray(A; Mask=mask, Norm=UInt16(2)),
        expected ./ sqrt(16);
        atol=1e-12,
    )

    
end
