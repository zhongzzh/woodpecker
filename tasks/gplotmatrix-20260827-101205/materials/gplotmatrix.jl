using Test
using TyStatisticsPlot
using TyPlot

# 取对角直方图单元中第一个分组的首个 patch（屏蔽 hh[3] 的深层下标）
_first_patch(hcell) = hcell[1][1]

@testset "eg1" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    h, ax, bigax = gplotmatrix(meas, [], species)
    @test h isa Matrix{Any}
    @test size(h) == (4, 4)
    @test ax isa Matrix{TyPlot.PyObject}
    # 与 MATLAB 一致：最后一行是 4 个对角直方图的覆盖坐标轴。
    @test size(ax) == (5, 4)
    @test length(ax[5, 1].patches) == 3
    @test collect(ax[1, 1].get_yticks()) == [5.0, 6.0, 7.0, 8.0]
    @test collect(ax[4, 1].get_yticks()) == [0.0, 1.0, 2.0]
    @test ax[1, 1].get_xlim() == ax[5, 1].get_xlim()
    @test ax[1, 1].get_xlim()[2] > 8.1
    for i in 1:4
        @test collect(ax[i, i].get_position().bounds) ≈
            collect(ax[5, i].get_position().bounds)
    end
    # setosa 第 4 列的 MATLAB Scott 分箱宽度为 0.12；轮廓高度也应一致。
    @test length(h[4, 4]) == 3
    xy = _first_patch(h[4, 4]).get_xy()
    @test xy[1:3, 1] ≈ [0.0, 0.0, 0.12]
    @test xy[1:3, 2] ≈ [0.0, 5 / 6, 5 / 6]
    @test ax[5, 4].get_ylim()[2] > maximum(xy[:, 2])
    @test bigax isa TyPlot.PyObject
end

@testset "eg2" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    h, ax, bigax = gplotmatrix(meas, Float64[], species)
    @test h isa Matrix{Any}
    @test size(h) == (4, 4)
    @test size(ax) == (5, 4)
    @test bigax isa TyPlot.PyObject
end

@testset "eg3" begin
    TyPlot.plt_close("all")
    include("discrim.jl")
    X = ratings[:, 1:2]
    Y = ratings[:, [4, 7]]
    xnames = ["climate", "housing"]
    ynames = ["crime", "arts"]
    h, ax, bigax = gplotmatrix(
        X, Y, group, "br", ".o", [], "on", []; xnam=xnames, ynam=ynames
    )
    @test ax[2, 1].get_xlabel() == "climate"
    @test ax[1, 1].get_xlabel() == ""
    @test ax[1, 1].get_ylabel() == "crime"
end

@testset "eg4" begin
    TyPlot.plt_close("all")
    include("hospital.jl")
    X = [hospital.Age hospital.Weight]
    g = (hospital.Sex, hospital.Smoker)
    xnames = ["Age", "Weight"]
    h, ax, bigax = gplotmatrix(X, Float64[], g, [], [], [], [], "grpbars"; xnam=xnames)
    @test h isa Matrix{Any}
    @test size(h) == (2, 2)
    @test size(ax) == (3, 2)
    @test bigax isa TyPlot.PyObject
end

@testset "eg5" begin
    TyPlot.plt_close("all")
    include("carsmall.jl")
    X = [Acceleration Displacement Horsepower MPG Weight]
    xnames = ["Acceleration", "Displacement", "Horsepower", "MPG", "Weight"]
    h, ax, bigax = gplotmatrix(
        X, Float64[], Cylinders, [], [], [], [], "variable"; xnam=xnames
    )
    title(bigax, "Car Data")
    @test h isa Matrix{Any}
    @test size(h) == (5, 5)
end

@testset "eg6" begin
    TyPlot.plt_close("all")
    include("carsmall.jl")
    X = [Acceleration Displacement Horsepower MPG Weight]
    h, ax, bigax = gplotmatrix(X, Cylinders)
    @test size(h) == (5, 5)
end

@testset "error" begin
    TyPlot.plt_close("all")
    aemsg = ArgumentError("X and Y must have the same number of rows.")
    @test_throws aemsg gplotmatrix(ones(5, 3), ones(4, 2), [1, 2, 1, 2, 1])
    aemsg = ArgumentError("The \"xnam\" input must have one name for each column of X.")
    @test_throws aemsg gplotmatrix(ones(5, 3), [1, 2, 1, 2, 1]; xnam=["a"])
    aemsg = ArgumentError("The \"ynam\" input must have one name for each column of Y.")
    @test_throws aemsg gplotmatrix(ones(5, 3), ones(5, 2), [1, 2, 1, 2, 1]; ynam=["a"])
    aemsg = ArgumentError("doleg must be \"on\" or \"off\".")
    @test_throws aemsg gplotmatrix(
        ones(5, 3), Float64[], [1, 2, 1, 2, 1], "", ".", [], "bad"
    )
    @test_throws aemsg gplotmatrix(
        ones(5, 3), Float64[], [1, 2, 1, 2, 1], "", ".", [], [1, 2]
    )
    aemsg = ArgumentError("The dispopt parameter must be a string.")
    @test_throws aemsg gplotmatrix(
        ones(5, 3), Float64[], [1, 2, 1, 2, 1], "", ".", [], "on", [1, 2]
    )
    aemsg = ArgumentError(
        "The dispopt parameter must be one of \"hist\", \"stairs\", \"grpbars\", \"variable\", or \"none\".",
    )
    @test_throws aemsg gplotmatrix(
        ones(5, 3), Float64[], [1, 2, 1, 2, 1], "", ".", [], "on", "bad"
    )
    aemsg = ArgumentError("There must be one value of G for each row of X.")
    @test_throws aemsg gplotmatrix(ones(5, 3), Float64[], [1, 2, 1, 2])
end

@testset "robustness" begin
    TyPlot.plt_close("all")
    # 含 NaN 分组（位于中间，前后均有有效组）：NaN 对应行应被剔除，不参与散点与直方图；
    # 各有效分组均含 >=2 点
    X = [1.0 5.0; 1.5 5.5; 2.0 6.0; 2.5 6.5; 3.0 7.0; 3.5 7.5; 4.0 8.0; 4.5 8.5]
    g = [1.0, 1.0, 1.0, 2.0, 2.0, NaN, 3.0, 3.0]
    h, ax, bigax = gplotmatrix(X, Float64[], g)
    @test h isa Matrix{Any}
    @test size(h) == (2, 2)
    @test size(ax) == (3, 2)
    @test bigax isa TyPlot.PyObject
    # NaN 分组被剔除，对角直方图只含 3 个有效分组
    @test length(h[1, 1]) == 3
    @test length(h[2, 2]) == 3
end

@testset "dispopt hist none" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    h, ax, bigax = gplotmatrix(meas, Float64[], species, [], [], [], [], "hist")
    @test size(h) == (4, 4)
    @test size(ax) == (5, 4)
    @test length(h[1, 1]) == 1

    TyPlot.plt_close("all")
    h, ax, bigax = gplotmatrix(meas, Float64[], species, [], [], [], [], "none")
    @test size(h) == (4, 4)
    @test size(ax) == (4, 4)
    @test isempty(h[1, 1])
end

@testset "doleg off" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", ".", [], false)
    @test size(h) == (4, 4)
    @test size(ax) == (5, 4)
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", ".", [], "off")
    @test size(h) == (4, 4)
end

@testset "sym siz forms" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", ["o", "s", "x"])
    @test size(h) == (4, 4)
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", ['o', 's'])
    @test size(h) == (4, 4)
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", ".", 8)
    @test size(h) == (4, 4)
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", ".", [6.0, 8.0])
    @test size(h) == (4, 4)
end

@testset "clr forms" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    color = [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0]
    h, ax, bigax = gplotmatrix(meas, Float64[], species, color)
    @test size(h) == (4, 4)
    h, ax, bigax = gplotmatrix(meas, Float64[], species, ["r", "g", "b"])
    @test size(h) == (4, 4)
    h, ax, bigax = gplotmatrix(
        meas, Float64[], species, [(1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)]
    )
    @test size(h) == (4, 4)
    # 单个 RGB 三元组仅在直方图路径使用（单列仅含对角直方图，避免散点图路径）
    h, ax, bigax = gplotmatrix(meas[:, 1:1], Float64[], species, [1.0, 0.0, 0.0])
    @test size(h) == (1, 1)
end

@testset "sort empty group reshape" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    h, ax, bigax = gplotmatrix(meas, Float64[], species; sort=false)
    @test size(h) == (4, 4)

    h, ax, bigax = gplotmatrix(meas, Float64[], Float64[])
    @test size(h) == (4, 4)
    @test size(ax) == (5, 4)
    @test length(h[1, 1]) == 1

    # X 单列（n×1）
    X1 = meas[:, 1:1]
    h, ax, bigax = gplotmatrix(X1, Float64[], species)
    @test size(h) == (1, 1)
    @test size(ax) == (2, 1)

    # X 单行（1×n → reshape n×1）
    Xrow = reshape([1.0, 2.0, 3.0, 4.0], 1, 4)
    h, ax, bigax = gplotmatrix(Xrow, Float64[], [1, 1, 2, 2])
    @test size(h) == (1, 1)

    # 多分组数值矩阵
    X2 = meas[1:8, 1:2]
    gmat = [1.0 1.0; 1.0 2.0; 2.0 1.0; 2.0 2.0; 1.0 1.0; 1.0 2.0; 2.0 1.0; 2.0 2.0]
    h, ax, bigax = gplotmatrix(X2, Float64[], gmat)
    @test size(h) == (2, 2)
end

@testset "constant data" begin
    TyPlot.plt_close("all")
    Xc = [1.0 2.0; 1.0 3.0; 1.0 4.0; 1.0 5.0; 1.0 6.0; 1.0 7.0]
    gc = [1, 1, 1, 2, 2, 3]
    h, ax, bigax = gplotmatrix(Xc, Float64[], gc)
    @test size(h) == (2, 2)
end

@testset "Y reshape" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    # Y 单列（n×1）
    h, ax, bigax = gplotmatrix(meas[:, 1:2], meas[:, 1:1], species)
    @test size(h) == (1, 2)
    @test size(ax) == (1, 2)
    # Y 单行（1×n → reshape n×1）
    X44 = [1.0 5.0; 2.0 6.0; 3.0 7.0; 4.0 8.0]
    Yrow = reshape([1.0, 2.0, 3.0, 4.0], 1, 4)
    h, ax, bigax = gplotmatrix(X44, Yrow, [1, 1, 2, 2])
    @test size(h) == (1, 2)
end

@testset "clr string and degenerate groups" begin
    TyPlot.plt_close("all")
    include("fisheriris.jl")
    # 颜色字符串 + 对角直方图（覆盖 _gplot_clr_for_hist 的 String 分支）
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "br")
    @test size(h) == (4, 4)
    @test size(ax) == (5, 4)
    # 每组仅 1 个点（无法估计分箱宽度，触发默认分箱回退）
    Xs = [1.0 2.0; 2.0 3.0; 3.0 4.0; 4.0 5.0]
    gs = [1, 2, 3, 4]
    h, ax, bigax = gplotmatrix(Xs, Float64[], gs)
    @test size(h) == (2, 2)
    # 空符号（回退到默认 ".")
    h, ax, bigax = gplotmatrix(meas, Float64[], species, "", "")
    @test size(h) == (4, 4)
end
