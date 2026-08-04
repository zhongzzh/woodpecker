using TyComputationalGeometryPlot
using Test
using TyPlot
using TyPlotTest
using TyRandom
using TyInterpolations
using TyComputationalGeometry
using TyBase
res_dir = joinpath(
    pkgdir(TyComputationalGeometryPlot),
    "test",
    "TriangulationRepresentation",
    "TransformationStorageAndDrawing",
    "trisurf_figure",
)

@testset "trisurf_test1" begin
    ref = joinpath(res_dir, "trisurf_res1.png")
    @test compare_plot(ref; by=PSNR(9)) do
        x, y = meshgrid2(1:15, 1:15)
        a, b, z = peaks(15)
        T = delaunay(x, y)
        trisurf(T, x, y, z)
    end
end

@testset "trisurf_test2" begin
    ref = joinpath(res_dir, "trisurf_res2.png")
    @test compare_plot(ref; by=PSNR(9)) do
        rng = MT19937ar(5489)
        x = rand(rng, 100)
        y = rand(rng, 100)
        z = rand(rng, 100)
        T = delaunay(x, y)
        trisurf(T, x, y, z)
    end
end

@testset "trisurf_test3" begin
    ref = joinpath(res_dir, "trisurf_res1.png")
    @test compare_plot(ref; by=PSNR(9)) do
        x, y = meshgrid2(1:15, 1:15)
        a, b, z = peaks(15)
        T = delaunay(x, y)
        TO = triangulation(T, x[:], y[:], z[:])
        trisurf(TO)
    end
end

@testset "trisurf_test4" begin
    ref = joinpath(res_dir, "trisurf_res3.png")
    @test compare_plot(ref; by=PSNR(9)) do
        rng = MT19937ar(5489)
        P = [
            2.5 8.0
            6.5 8.0
            2.5 5.0
            6.5 5.0
            1.0 6.5
            8.0 6.5
        ]
        T = [
            5 3 1
            3 2 1
            3 4 2
            4 6 2
        ]
        TO = triangulation(T, P[:, 1], P[:, 2], rand(rng, 6))
        trisurf(TO)
    end
end
