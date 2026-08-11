using TyImageProcessing, Test, TyBaseCore, TyFileIO

@testset "dice" begin
    @testset "src" begin
        A = imread("hands1.jpg")
        I = im2gray(A)
        mask = falses(size(I))
        mask[25:(end - 25), 25:(end - 25)] .= true
        BW = activecontour(I, mask, 300)
        BW_groundTruth = imread("hands1-mask.png")
        BW_groundTruth = BW_groundTruth .!= 0
        similarity = dice(BW, BW_groundTruth)
        @test typeof(similarity) <: (eltype(BW) == Bool ? Real : AbstractVecOrMat)

        RGB = imread("yellowlily.jpg")
        region1 = [350 700 425 120] # [x y w h] format
        BW1 = falses(size(RGB, 1), size(RGB, 2))
        BW1[region1[2]:(region1[2] + region1[4]), region1[1]:(region1[1] + region1[3])] .=
            true
        region2 = [800 1124 120 230]
        BW2 = falses(size(RGB, 1), size(RGB, 2))
        BW2[region2[2]:(region2[2] + region2[4]), region2[1]:(region2[1] + region2[3])] .=
            true
        region3 = [20 1320 480 200; 1010 290 180 240]
        BW3 = falses(size(RGB, 1), size(RGB, 2))
        BW3[
            region3[1, 2]:(region3[1, 2] + region3[1, 4]),
            region3[1, 1]:(region3[1, 1] + region3[1, 3]),
        ] .= true
        BW3[
            region3[2, 2]:(region3[2, 2] + region3[2, 4]),
            region3[2, 1]:(region3[2, 1] + region3[2, 3]),
        ] .= true
        # L = imseggeodesic(RGB,BW1,BW2,BW3;AdaptiveChannelWeighting=true);
        L = load(pkgdir(TyImageProcessing) * "/resources/dice_exp2_L.mat")["L"]
        L_groundTruth = Float64.(imread("yellowlily-segmented.png")[1])
        similarity = dice(L, L_groundTruth)
        @test typeof(similarity) <: (eltype(L) == Bool ? Real : AbstractVecOrMat)
    end

    @testset "similarity = dice(BW1,BW2)" begin
        BW1 = rand(Bool, 100, 100)
        BW2 = rand(Bool, 100, 100)
        similarity = dice(BW1, BW2)
        @test typeof(similarity) == Float64
    end

    @testset "similarity = dice(BW1,BW2)" begin
        L1 = Int64.(rand(UInt8, 100, 100))
        L2 = Int64.(rand(UInt8, 100, 100))
        similarity = dice(L1, L2)
        @test typeof(similarity) <: AbstractVecOrMat{Float64}

        L1 = Float64.(rand(UInt8, 100, 100))
        L2 = Float64.(rand(UInt8, 100, 100))
        similarity = dice(L1, L2)
        @test typeof(similarity) <: AbstractVecOrMat{Float64}
    end
end

@testset "similarity = dice(BW1,BW2) with different dimensions" begin
    BW1 = rand(Bool, 100)
    BW2 = rand(Bool, 100)
    similarity = dice(BW1, BW2)
    @test typeof(similarity) == Float64

    BW1 = rand(Bool, 10, 10, 10)
    BW2 = rand(Bool, 10, 10, 10)
    similarity = dice(BW1, BW2)
    @test typeof(similarity) == Float64
end

@testset "similarity = dice(L1,L2) with different dimensions" begin
    L1 = Int64.(rand(UInt8, 100))
    L2 = Int64.(rand(UInt8, 100))
    similarity = dice(L1, L2)
    @test typeof(similarity) <: AbstractVecOrMat{Float64}

    L1 = Int64.(rand(UInt8, 10, 10, 10))
    L2 = Int64.(rand(UInt8, 10, 10, 10))
    similarity = dice(L1, L2)
    @test typeof(similarity) <: AbstractVecOrMat{Float64}
end
