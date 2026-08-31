using Test
using TyComputationalGeometry
using TyComputationalGeometryPlot
using TyPlot
using TyRandom
using TyPlotTest
using TyInterpolations

res_dir = joinpath(@__DIR__, "trimesh_figure")

@testset "trimesh 补充" begin
    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    x = points[:, 1]
    y = points[:, 2]
    z = points[:, 3]

    @testset "直接调用形式" begin
        h2 = trimesh(connectivity, x, y)
        @test h2 !== nothing

        h3 = trimesh(connectivity, x, y, z)
        @test h3 !== nothing
    end

    @testset "名称-值参数补充" begin
        h_fc = trimesh(connectivity, x, y, z; facecolor="r")
        @test h_fc !== nothing
        @test plt_get(h_fc, "facecolor") == "r"

        h_fa = trimesh(connectivity, x, y, z; facealpha=0.5)
        @test h_fa !== nothing
        @test plt_get(h_fa, "facealpha") == 0.5

        h_ec = trimesh(connectivity, x, y, z; edgecolor=[1.0, 0.0, 0.0])
        @test h_ec !== nothing
        @test plt_get(h_ec, "edgecolor") == [1.0, 0.0, 0.0]
    end
end

@testset "trimesh 缺失覆盖补充" begin
    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    xcol = points[:, 1]
    ycol = points[:, 2]
    zcol = points[:, 3]

    Xmat = [0.0 1.0; 0.0 1.0]
    Ymat = [0.0 0.0; 1.0 1.0]
    Zmat = [1.0 0.0; 0.0 1.0]
    Cmat = [1 2; 3 4]

    @testset "facecolor 未覆盖取值" begin
        h_fc_rgb = trimesh(connectivity, xcol, ycol, zcol; facecolor=[0.2, 0.3, 0.4])
        @test h_fc_rgb !== nothing
        @test isapprox(plt_get(h_fc_rgb, "facecolor"), [0.2, 0.3, 0.4])

        h_fc_hex = trimesh(connectivity, xcol, ycol, zcol; facecolor="#ff0000")
        @test h_fc_hex !== nothing

        h_fc_none = trimesh(connectivity, xcol, ycol, zcol; facecolor="none")
        @test h_fc_none !== nothing
    end

    @testset "edgecolor 未覆盖取值" begin
        h_ec_hex = trimesh(connectivity, xcol, ycol, zcol; edgecolor="#00ff00")
        @test h_ec_hex !== nothing

        h_ec_none = trimesh(connectivity, xcol, ycol, zcol; edgecolor="none")
        @test h_ec_none !== nothing
    end

    @testset "linestyle 未覆盖取值" begin
        for ls in [":", "-.", "-"]
            h_ls = trimesh(connectivity, xcol, ycol, zcol; linestyle=ls)
            @test h_ls !== nothing
            @test plt_get(h_ls, "linestyle") == ls
        end
    end
end

@testset "trimesh(TO)" begin
    @test trimesh === TyPlot.trimesh

    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    tr = triangulation(connectivity, points)
    @test applicable(trimesh, tr)
    ref = joinpath(res_dir, "trimesh_res1.png")
    @test compare_plot(ref; by=PSNR(9)) do
        trimesh(tr)
    end

    x, y, z = peaks(15)
    T = delaunay(x, y)

    # TO = triangulation(T, x(:), y(:), z(:))
    TO = triangulation(T, vec(x), vec(y), vec(z))
    ref = joinpath(res_dir, "trimesh_res2.png")
    @test compare_plot(ref; by=PSNR(9)) do
        trimesh(TO)
    end

    # TO = delaunayTriangulation(x(:), y(:), z(:))
    TO = delaunayTriangulation(vec(x), vec(y), vec(z))
    ref = joinpath(res_dir, "trimesh_res3.png")
    @test compare_plot(ref; by=PSNR(9)) do
        trimesh(TO)
    end

    # rng default
    # x = rand(1000, 1) 
    # y = rand(1000, 1)
    # z = rand(1000, 1)
    # T = delaunay(x, y)
    # TO = triangulation(T, x, y, z)
    # trimesh(TO)
    ref = joinpath(res_dir, "trimesh_res4.png")
    @test compare_plot(ref; by=PSNR(9)) do
        rng = MT19937ar(5489)
        x = rand(rng, 1000)
        y = rand(rng, 1000)
        z = rand(rng, 1000)
        T = delaunay(x, y)
        TO = triangulation(T, x, y, z)
        trimesh(TO)
    end
end

@testset "TU-001-【AI生成】trimesh(TO) 返回有效 Cpatch 句柄" begin
    # Julia 文档依据：trimesh.md:42，h = trimesh(___) 返回用于创建网格图的 Cpatch 对象。
    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    tr = triangulation(connectivity, points)
    h = trimesh(tr)
    @test h !== nothing
end

@testset "TU-002-【AI生成】trimesh(TO; linewidth) 关键字参数透传" begin
    # Julia 文档依据：trimesh.md:285-294，linewidth 以参数等式形式指定为正值。
    # MATLAB baseline 断言：h.LineWidth == 3。
    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    tr = triangulation(connectivity, points)
    h = trimesh(tr; linewidth=3.0)
    @test h !== nothing
    @test plt_get(h, "linewidth") == 3.0
end

@testset "TU-003-【AI生成】trimesh(TO; linestyle) 关键字参数透传" begin
    # Julia 文档依据：trimesh.md:299-316，linestyle 指定为 "--" 等线型。
    # MATLAB baseline 断言：strcmp(h.LineStyle, '--')。
    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    tr = triangulation(connectivity, points)
    h = trimesh(tr; linestyle="--")
    @test h !== nothing
    @test plt_get(h, "linestyle") == "--"
end

@testset "TU-004-【AI生成】trimesh(TO; edgecolor) 关键字参数透传" begin
    # Julia 文档依据：trimesh.md:230-283，edgecolor 指定为颜色名称、RGB 三元组或十六进制颜色代码。
    # MATLAB baseline 断言：isequal(h.EdgeColor, [1 0 0])。
    connectivity = [1 2 3; 2 4 3]
    points = [
        0.0 0.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
        1.0 1.0 0.0
    ]
    tr = triangulation(connectivity, points)
    h = trimesh(tr; edgecolor="r")
    @test h !== nothing
    @test plt_get(h, "edgecolor") == "r"
end
