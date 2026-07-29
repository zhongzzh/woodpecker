using TyImageProcessing, Test

@testset "graydiffweight" begin
    @testset "src" begin
        I = imread("cameraman.tif")
        seedpointR = 159
        seedpointC = 67
        W = graydiffweight(I, seedpointC, seedpointR; GrayDifferenceCutoff=25)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)
    end

    @testset "W = graydiffweight(I,refGrayVal)" begin
        I = rand(Float32, 100, 100)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(Float64, 100, 100, 3)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(Int8, 100, 100, 4)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(Int16, 100, 100, 3)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(Int32, 100, 100, 3)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(UInt8, 100, 100, 4)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(UInt16, 100, 100, 3)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(UInt32, 100, 100, 3)
        refGrayVal = 0.1
        W = graydiffweight(I, refGrayVal)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)
    end

    @testset "W = graydiffweight(I,mask)" begin
        I = rand(100, 100, 5)
        mask = rand(Bool, size(I))
        W = graydiffweight(I, mask)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)
    end

    @testset "W = graydiffweight(I,C,R)" begin
        I = rand(100, 100, 5)
        C = Float32.(rand(1:100, 1, 5))
        R = rand(1:100, 5, 1)
        W = graydiffweight(I, C, R)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(100, 100, 5)
        C = rand(1:100, 5)
        R = Float64.(rand(1:100, 5, 1))
        W = graydiffweight(I, C, R)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)

        I = rand(100, 100, 5)
        C = rand(1:100, 5, 1)
        R = rand(1:100, 5)
        W = graydiffweight(I, C, R)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)
    end

    @testset "W = graydiffweight(V,C,R,P)" begin
        V = rand(100, 100, 5)
        C = Float32.(rand(1:100, 1, 5))
        R = rand(1:100, 5, 1)
        P = rand(1:5, 5)
        W = graydiffweight(V, C, R, P)
        @test size(W) == size(V) && eltype(W) == (eltype(V) == Float32 ? Float32 : Float64)
    end

    @testset "W = graydiffweight(___; Name=Value)" begin
        I = imread("cameraman.tif")
        seedpointR = 159
        seedpointC = 67
        GrayDifferenceCutoff = Inf
        W1 = graydiffweight(I, seedpointC, seedpointR)
        W = graydiffweight(
            I, seedpointC, seedpointR; GrayDifferenceCutoff=GrayDifferenceCutoff
        )
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)
        @test isequal(W1, W)

        I = imread("cameraman.tif")
        seedpointR = 159
        seedpointC = 67
        RolloffFactor = 0.5
        W1 = graydiffweight(I, seedpointC, seedpointR)
        W = graydiffweight(I, seedpointC, seedpointR; RolloffFactor=RolloffFactor)
        @test size(W) == size(I) && eltype(W) == (eltype(I) == Float32 ? Float32 : Float64)
        @test isequal(W1, W)
    end

    @testset "numeric regression" begin
        I = UInt8[10 20; 30 40]
        expected = [
            3.99201198401998 1.0e6
            3.99201198401998 1.0
        ]
        @test graydiffweight(I, UInt8(20)) ≈ expected rtol = 1e-14

        mask = falses(size(I))
        mask[1, 2] = true
        @test graydiffweight(I, mask) ≈ expected rtol = 1e-14
        @test graydiffweight(I, 2, 1) ≈ expected rtol = 1e-14

        expectedCutoff = [
            2.51648622572717 1.0e4
            2.51648622572717 1.0
        ]
        @test graydiffweight(I, 2, 1; RolloffFactor=0.75, GrayDifferenceCutoff=15) ≈
            expectedCutoff rtol = 1e-14

        V = cat(I, UInt8[20 30; 40 50]; dims=3)
        W = graydiffweight(V, [2, 1], [1, 2], [1, 2])
        expectedPlane1 = [
            1.0 3.99201198401998
            1.0e6 3.99201198401998
        ]
        @test W[:, :, 1] ≈ expectedPlane1 rtol = 1e-14
        @test W[:, :, 2] ≈ expected rtol = 1e-14
    end
end
