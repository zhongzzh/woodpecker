using TyImageProcessing, Test, TyBaseCore, TyFileIO

@testset "roicolor" begin
    @testset "src" begin
        pkg_dir = pkgdir(TyImageProcessing)
        source_path = pkg_dir * "/resources/trees_tif_X.mat"
        X = load(source_path)["X"]
        source_path = pkg_dir * "/resources/trees_tif_map.mat"
        map = load(source_path)["map"]
        BW = roicolor(X, 10, 20)
        @test eltype(BW) == Bool && size(BW) == size(X)
    end

    @testset "BW = roicolor(I,low,high)" begin
        I = rand(Float64, 100, 90)
        low = 0.1
        high = 1.1
        BW = roicolor(I, low, high)
        @test eltype(BW) == Bool && size(BW) == size(I)

        I = rand(Float32, 100, 90)
        low = 0.1
        high = 100
        BW = roicolor(I, low, high)
        @test eltype(BW) == Bool && size(BW) == size(I)

        I = rand(Int, 100, 90)
        low = 0.1
        high = 100
        BW = roicolor(I, low, high)
        @test eltype(BW) == Bool && size(BW) == size(I)
    end

    @testset "BW = roicolor(I,v)" begin
        I = rand(Float64, 100, 90)
        v = rand(Float64, 5)
        BW = roicolor(I, v)
        @test eltype(BW) == Bool && size(BW) == size(I)

        I = rand(Float64, 100, 90)
        v = rand(Float64, 5, 1)
        BW = roicolor(I, v)
        @test eltype(BW) == Bool && size(BW) == size(I)

        I = rand(Int, 100, 90)
        v = rand(Int, 1, 5)
        BW = roicolor(I, v)
        @test eltype(BW) == Bool && size(BW) == size(I)
    end
end
