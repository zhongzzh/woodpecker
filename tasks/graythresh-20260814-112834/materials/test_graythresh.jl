using TyImageProcessing, Test

@testset "graythresh" begin
    @testset "UInt8 matrix fast path" begin
        @test graythresh(UInt8[0 255; 0 255]) == 127 / 255
        @test graythresh(UInt8[64 192; 64 192]) == 0.5
        @test graythresh(fill(UInt8(42), 3, 4)) == 0.0
        @test graythresh(UInt8[0 255]) isa Float64
    end

    @testset "supported numeric conversions" begin
        # Each endpoint pair converts to UInt8[0, 255] before thresholding.
        @test graythresh(UInt16[0 typemax(UInt16)]) == 127 / 255
        @test graythresh(Int16[typemin(Int16) typemax(Int16)]) == 127 / 255
        @test graythresh(Float32[0 1]) == 127 / 255
        @test graythresh(Float64[0 1]) == 127 / 255

        # Floating-point inputs are clipped to [0, 1], and NaN maps to zero.
        clipped = Float64[-1 NaN; 1 2]
        @test graythresh(clipped) == 127 / 255
        @test graythresh(fill(Float32(0.25), 2, 3)) == 0.0
    end

    @testset "generic shapes and views" begin
        vector_input = UInt8[0, 255, 0, 255]
        @test graythresh(vector_input) == 127 / 255

        volume_input = reshape(repeat(UInt8[0, 255], 4), 2, 2, 2)
        @test graythresh(volume_input) == 127 / 255

        parent = UInt8[0 10 255; 0 20 255]
        @test graythresh(@view(parent[:, [1, 3]])) == 127 / 255
    end

    @testset "empty inputs" begin
        @test graythresh(zeros(UInt8, 0, 3)) === 0.0
        @test graythresh(zeros(UInt16, 0, 3)) === 0.0
        @test graythresh(zeros(UInt8, 0, 2, 2)) === 0.0
    end

    @testset "unsupported inputs" begin
        @test_throws MethodError graythresh(UInt8(1))
        @test_throws MethodError graythresh(Bool[false true])
    end
end
