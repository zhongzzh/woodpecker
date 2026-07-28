using TyImageProcessing, Test

@testset "graycomatrix" begin
    @testset "src" begin
        I = imread("circuit.tif")
        glcm, SI = graycomatrix(I; Offset=[2 0])
        @test typeof(glcm) <: AbstractArray{Float64} && typeof(SI) <: AbstractArray{Float64}

        I = [1.0 1 5 6 8 8; 2 3 5 7 0 2; 0 2 3 5 6 7]
        glcm, SI = graycomatrix(I; NumLevels=9, GrayLimits=Float64[])
        @test typeof(glcm) <: AbstractArray{Float64} && typeof(SI) <: AbstractArray{Float64}

        I = imread("cell.tif")
        offsets = [0 1; -1 1; -1 0; -1 -1]
        glcm, SI = graycomatrix(I; Offset=offsets)
        @test typeof(glcm) <: AbstractArray{Float64} && typeof(SI) <: AbstractArray{Float64}

        I = imread("circuit.tif")
        glcm, SI = graycomatrix(I; Offset=[2 0], Symmetric=true)
        @test typeof(glcm) <: AbstractArray{Float64} && typeof(SI) <: AbstractArray{Float64}
    end
end
