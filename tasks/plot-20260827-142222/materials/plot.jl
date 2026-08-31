using TyPlot
using Test
using TyComputationalGeometry
using TyComputationalGeometryPlot

@testset "plot polyshape" begin
    p1 = polyshape([0, 0, 1, 1], [1, 0, 0, 1])
    p2 = polyshape([0.75, 1.25, 1.25, 0.75], [0.25, 0.25, 0.75, 0.75])
    p3 = polyshape([1.25, 1.25, 1.75, 1.75], [0.75, 1.25, 1.25, 0.75])
    polyvec = [p1 p2 p3]

    @test plot(p1) !== nothing

    handles = plot(polyvec)
    @test size(handles) == size(polyvec)
    @test handles[1].facecolor != handles[2].facecolor

    ax = plt_axes()
    @test plot(ax, p1) !== nothing

    ax_handles = plot(ax, polyvec)
    @test size(ax_handles) == size(polyvec)
    @test ax_handles[1].facecolor != ax_handles[2].facecolor

    colororder(ax, [(0.2, 0.3, 0.4), (0.6, 0.7, 0.8)])
    custom_color_handles = plot(ax, [p1 p2])
    @test custom_color_handles[1].facecolor != custom_color_handles[2].facecolor

    pgon_with_hole = polyshape(
        ([0, 0, 2, 2], [0.5, 1.5, 1.5, 0.5]), ([0, 2, 2, 0], [0.5, 0.5, 1.5, 1.5])
    )
    hole_handles = plot(ax, pgon_with_hole)
    @test ishole(pgon_with_hole, 2)
    @test hole_handles isa AbstractVector
    @test length(hole_handles) == 2
    @test hole_handles[1].facecolor[1, 4] == 0.35
    @test hole_handles[2].facecolor == ones(1, 4)

    h1 = plot(polyvec[1])
    hold("on")
    h2 = plot(polyvec[2])
    h3 = plot(polyvec[3])
    hold("off")
    @test h1.facecolor != h2.facecolor
    @test h2.facecolor != h3.facecolor
    @test h3.facecolor != h1.facecolor
end
