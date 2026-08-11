using TyImageProcessing, Test, TyBaseCore

@testset "cc2bw" begin
    @testset "src" begin
        I = imread("blobs.png")
        I = I .!= 0
        CC = bwconncomp(I)
        CC = bwpropfilt(CC, "Circularity", [0.7 1])
        BW = cc2bw(CC)
        @test CC.NumObjects == 9
        @test count(BW) == 842
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize

        CC = bwpropfilt(CC, "Area", [20 Inf])
        BW = cc2bw(CC)
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize

        BW = imread("text.png")
        BW = BW .!= 0
        CC = bwconncomp(BW)
        p = regionprops(CC, "Area")
        area = Float64[]
        for i in 1:length(p)
            area = vcat(area, p[i].Area)
        end
        _, idx = ty_sort(area, "descend"; nargout=2)
        BWfilt = cc2bw(CC; ObjectsToKeep=idx[2:10])
        @test eltype(BWfilt) == Bool && size(BWfilt) == CC.ImageSize

        I = imread("rice.png")
        BW = imbinarize(I)
        CC = bwconncomp(BW)
        stats = regionprops(CC, "Area", "BoundingBox")
        area = Float64[]
        for i in 1:length(stats)
            area = vcat(area, stats[i].Area)
        end
        bbox = []
        for i in 1:length(stats)
            bbox = vcat(bbox, stats[i].BoundingBox)
        end
        selection = (area .> 50) .& (bbox[:, 3] .< 15) .& (bbox[:, 4] .>= 20)
        BW2 = cc2bw(CC; ObjectsToKeep=selection)
        @test eltype(BW2) == Bool && size(BW2) == CC.ImageSize
    end

    @testset "BW = cc2bw(CC)" begin
        I = imread("blobs.png")
        I = I .!= 0
        CC = bwconncomp(I)
        CC = bwpropfilt(CC, "Circularity", [0.7 1])
        BW = cc2bw(CC)
        @test CC.NumObjects == 9
        @test count(BW) == 842
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize
    end

    @testset "BW = cc2bw(CC;ObjectsToKeep=objectsToKeep)" begin
        BW = imread("text.png")
        BW = BW .!= 0
        CC = bwconncomp(BW)
        objectsToKeep = 1
        BW = cc2bw(CC; ObjectsToKeep=objectsToKeep)
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize

        objectsToKeep = [1 2]
        BW = cc2bw(CC; ObjectsToKeep=objectsToKeep)
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize

        objectsToKeep = [true false]
        BW = cc2bw(CC; ObjectsToKeep=objectsToKeep)
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize

        objectsToKeep = rand(Bool, 50)
        BW = cc2bw(CC; ObjectsToKeep=objectsToKeep)
        @test eltype(BW) == Bool && size(BW) == CC.ImageSize
    end
end
