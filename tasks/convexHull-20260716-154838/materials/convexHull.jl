using Test
using TyComputationalGeometry
using TyI18N

TyI18N.set_locale_zh!()

@testset "convexHull_2d_basic" begin
    P = [0.0 0.0; 1.0 0.0; 1.0 1.0; 0.0 1.0; 0.5 0.5]
    DT = delaunayTriangulation(P)
    K, AV = convexHull(DT)
    @test K == [1, 2, 3, 4, 1]
    @test isapprox(AV, 1.0; rtol=1e-14)
end

@testset "convexHull_2d_nontrivial" begin
    P = [2.5 8.0; 6.5 8.0; 2.5 5.0; 6.5 5.0; 1.0 6.5; 8.0 6.5]
    DT = delaunayTriangulation(P)
    K, AV = convexHull(DT)
    @test K == [5, 3, 4, 6, 2, 1, 5]
    @test isapprox(AV, 16.5; rtol=1e-14)
end

@testset "convexHull_3d_basic" begin
    P = [0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0; 0.2 0.2 0.2]
    DT = delaunayTriangulation(P)
    K, AV = convexHull(DT)
    @test Set(Tuple.(eachrow(sort(K; dims=2)))) ==
        Set([(1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4)])
    @test isapprox(AV, 1 / 6; rtol=1e-14)
end

@testset "convexHull_cache_invalidation" begin
    P = [0.0 0.0; 1.0 0.0; 1.0 1.0; 0.0 1.0]
    DT = delaunayTriangulation(P)
    K, AV = convexHull(DT)
    @test K == [1, 2, 3, 4, 1]
    @test isapprox(AV, 1.0; rtol=1e-14)

    K[2] = 4
    K_cached, AV_cached = convexHull(DT)
    @test K_cached == [1, 2, 3, 4, 1]
    @test isapprox(AV_cached, 1.0; rtol=1e-14)

    DT.ConnectivityList = [1 2 3]
    K2, AV2 = convexHull(DT)
    @test K2 == [1, 2, 3, 1]
    @test isapprox(AV2, 0.5; rtol=1e-14)
end

@testset "convexHull_errors" begin
    DT = delaunayTriangulation()
    @test_throws ErrorException convexHull(DT)

    DT_line = delaunayTriangulation([0.0 0.0; 1.0 0.0; 2.0 0.0])
    @test_throws ErrorException convexHull(DT_line)
end
