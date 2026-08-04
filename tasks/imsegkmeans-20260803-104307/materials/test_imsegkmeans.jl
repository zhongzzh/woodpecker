using TyImageProcessing, Test, TyBaseCore

@testset "imsegkmeans" begin
    @testset "src" begin
        I = imread("cameraman.tif")
        k = 3
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        I = imread("peppers.png")
        k = 50
        L, C = imsegkmeans(I, 50)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        he = imread("hestain.png")
        lab_he = rgb2lab(he)
        ab = lab_he[:, :, 2:3]
        I = im2single(ab)
        k = 3
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end

    @testset "I" begin
        I = rand(Float32, 100, 100)
        k = 3
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        I = rand(Int8, 100, 100)
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        I = rand(Int16, 100, 100)
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        I = rand(UInt8, 100, 100)
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        I = rand(UInt16, 100, 100)
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end

    @testset "k" begin
        I = imread("cameraman.tif")
        k = 10
        L, C = imsegkmeans(I, k)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end

    @testset "NormalizeInput" begin
        I = imread("cameraman.tif")
        k = 3
        NormalizeInput = true
        L, C = imsegkmeans(I, k; NormalizeInput=NormalizeInput)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end

        NormalizeInput = false
        L, C = imsegkmeans(I, k; NormalizeInput=NormalizeInput)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end

    @testset "NormalizeInput" begin
        I = imread("cameraman.tif")
        k = 3
        NumAttempts = 5
        L, C = imsegkmeans(I, k; NumAttempts=NumAttempts)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end

    @testset "MaxIterations" begin
        I = imread("cameraman.tif")
        k = 3
        MaxIterations = 111
        L, C = imsegkmeans(I, k; MaxIterations=MaxIterations)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end

    @testset "Threshold" begin
        I = imread("cameraman.tif")
        k = 3
        Threshold = 0.001
        L, C = imsegkmeans(I, k; Threshold=Threshold)
        @test size(L)[1:2] == size(I)[1:2] && eltype(C) == eltype(I)
        if ndims(I) == 2
            size(C) == (k, 1)
        elseif ndims(I) == 3
            size(C) == (k, 3)
        end
    end
    # 新增
    @testset "performance" begin
        I = rand(UInt8, 100, 100)
        @time imsegkmeans(I, 3)
    end
end
