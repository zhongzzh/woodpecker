using TyImageProcessing, Test

@testset "chromadapt" begin
    @testset "src" begin
        A = imread("hallway.jpg")
        x = 2800
        y = 1000
        gray_val = impixel(A, x, y)
        B = chromadapt(A, gray_val)
        @test size(A) == size(B) && eltype(A) == eltype(B)

        A = imread("foosballraw.tiff")
        A = demosaic(A, "rggb")
        A_sRGB = lin2rgb(A)
        x = 1510
        y = 1250
        light_color = [A[y, x, 1] A[y, x, 2] A[y, x, 3]]
        B = chromadapt(A, light_color; ColorSpace="linear-rgb")
        @test size(A) == size(B) && eltype(A) == eltype(B)
    end

    @testset "B = chromadapt(A,illuminant)" begin
        A = rand(Float32, 100, 100, 3)
        illuminant = rand(Float32, 3)
        B = chromadapt(A, illuminant)
        @test size(A) == size(B) && eltype(A) == eltype(B)

        A = rand(Float64, 100, 100, 3)
        illuminant = rand(Float64, 3)
        B = chromadapt(A, illuminant)
        @test size(A) == size(B) && eltype(A) == eltype(B)

        A = rand(UInt8, 100, 100, 3)
        illuminant = rand(UInt8, 3)
        B = chromadapt(A, illuminant)
        @test size(A) == size(B) && eltype(A) == eltype(B)

        A = rand(UInt16, 100, 100, 3)
        illuminant = rand(UInt16, 3)
        B = chromadapt(A, illuminant)
        @test size(A) == size(B) && eltype(A) == eltype(B)
    end

    @testset "Name=Value" begin
        A = rand(Float32, 100, 100, 3)
        illuminant = rand(Float32, 3)

        A = rand(Float64, 100, 100, 3)
        ColorSpace = ["srgb", "adobe-rgb-1998", "prophoto-rgb"]
        B = chromadapt(A, illuminant; ColorSpace=ColorSpace[1])
        @test size(A) == size(B) && eltype(A) == eltype(B)

        A = rand(UInt8, 100, 100, 3)
        B = chromadapt(A, illuminant; ColorSpace=ColorSpace[2])
        @test size(A) == size(B) && eltype(A) == eltype(B)

        A = rand(UInt16, 100, 100, 3)
        B = chromadapt(A, illuminant; ColorSpace=ColorSpace[3])
        @test size(A) == size(B) && eltype(A) == eltype(B)

        Method = ["bradford", "vonkries", "simple"]
        B = chromadapt(A, illuminant; Method=Method[1])
        @test size(A) == size(B) && eltype(A) == eltype(B)

        B = chromadapt(A, illuminant; Method=Method[2])
        @test size(A) == size(B) && eltype(A) == eltype(B)

        B = chromadapt(A, illuminant; Method=Method[3])
        @test size(A) == size(B) && eltype(A) == eltype(B)
    end
end
