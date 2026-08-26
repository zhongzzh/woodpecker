include("../utils.jl")
using TyBase

@testset "rmnode-test" begin
    s = [1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7]
    t = [2, 4, 8, 3, 7, 4, 6, 5, 6, 8, 7, 8]
    name = ["a", "b", "c", "d", "e", "f", "g", "h"]
    nodeprop = [1, 2, 3, 4, 5, 6, 7, 8]
    G1 = Graph(s, t)
    weight = ones(Int, 12)
    edgeprop = zeros(Int, 12)
    G2 = Graph(s, t, weight, name)
    G3 = Graph(s, t, weight, name, nodeprop, edgeprop)
    Gd = DiGraph(s, t)
    @test isEqualG(
        rmnode(G3, 2),
        ["a", "c", "d", "e", "f", "g", "h"],
        [1, 3, 4, 5, 6, 7, 8],
        [1 3; 1 7; 2 3; 2 5; 3 4; 4 5; 4 7; 5 6; 6 7],
        ones(Int, 9),
        zeros(Int, 9),
    )
    @test isEqualG(
        rmnode(G3, "d"),
        ["a", "b", "c", "e", "f", "g", "h"],
        [1, 2, 3, 5, 6, 7, 8],
        [1 2; 1 7; 2 3; 2 6; 3 5; 4 5; 4 7; 5 6; 6 7],
        ones(Int, 9),
        zeros(Int, 9),
    )
    @test_throws ErrorException("无法在不含名称的图中删除带名称的节点。") rmnode(G1, "d")
    @test_throws ErrorException("找不到此节点 k。") rmnode(G3, "k")
    @test isEqualG(
        rmnode(Gd, [7, 5]),
        Matrix{String}(undef, 6, 0),
        Float64[],
        [1 2; 1 4; 1 6; 2 3; 3 4; 3 5],
        Float64[],
        Float64[],
    )
    @test isEqualG(
        rmnode(G3, ["b", "e"]),
        ["a", "c", "d", "f", "g", "h"],
        [1, 3, 4, 6, 7, 8],
        [1 3; 1 6; 2 3; 2 4; 4 5; 5 6],
        ones(Int, 6),
        zeros(Int, 6),
    )
    @test isEqualG(
        rmnode(Gd, 2),
        Matrix{String}(undef, 7, 0),
        Float64[],
        [1 3; 1 7; 2 3; 2 5; 3 4; 4 5; 4 7; 5 6; 6 7],
        Float64[],
        Float64[],
    )
    @test_throws ErrorException("找不到此节点 hxjhj。") rmnode(G2, ["a", "hxjhj"])
    @test_throws ErrorException("无法在不含名称的图中删除带名称的节点。") rmnode(G1, ["d"])
end

@testset "rmnode-copy-contract" begin
    s = [1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7]
    t = [2, 4, 8, 3, 7, 4, 6, 5, 6, 8, 7, 8]
    name = ["a", "b", "c", "d", "e", "f", "g", "h"]
    nodeprop = [1, 2, 3, 4, 5, 6, 7, 8]
    weight = ones(Int, 12)
    edgeprop = zeros(Int, 12)

    # 无名无权图：原图不被修改，且返回图与原图不共享任何数组对象
    G = Graph(s, t)
    en0 = copy(G.Edges.endnodes)
    H = rmnode(G, 2)
    @test G.Edges.endnodes == en0
    @test H.Edges.endnodes !== G.Edges.endnodes
    @test H.Nodes.nodeNames !== G.Nodes.nodeNames
    @test H.Edges.weights !== G.Edges.weights
    @test H.Edges.props !== G.Edges.props
    @test H.Nodes.props !== G.Nodes.props
    push!(H.Edges.weights, 1.0)
    @test isempty(G.Edges.weights)

    # 命名含属性图：原图内容保持不变
    G3 = Graph(s, t, weight, name, nodeprop, edgeprop)
    H3 = rmnode(G3, ["b", "e"])
    @test G3.Nodes.nodeNames == name
    @test G3.Nodes.props == nodeprop
    @test G3.Edges.weights == weight
    @test G3.Edges.props == edgeprop
    @test size(G3.Edges.endnodes, 1) == 12
    @test H3.Nodes.nodeNames !== G3.Nodes.nodeNames
    @test H3.Nodes.props !== G3.Nodes.props
    @test H3.Edges.weights !== G3.Edges.weights
    @test H3.Edges.props !== G3.Edges.props

    # 重复 ID 按集合语义删除一次，与单次删除结果一致
    Gd = DiGraph(s, t)
    Hd_dup = rmnode(Gd, [3, 3])
    Hd_single = rmnode(Gd, 3)
    @test Hd_dup.Nodes.nodeNames == Hd_single.Nodes.nodeNames
    @test Hd_dup.Edges.endnodes == Hd_single.Edges.endnodes
    @test size(Hd_dup.Edges.endnodes, 1) == 9
    @test all(1 .<= Hd_dup.Edges.endnodes .<= 7)

    Hn_dup = rmnode(G3, ["b", "b"])
    Hn_single = rmnode(G3, "b")
    @test Hn_dup.Nodes.nodeNames == Hn_single.Nodes.nodeNames
    @test Hn_dup.Edges.endnodes == Hn_single.Edges.endnodes

    # 越界 ID（> n）按 MATLAB 语义静默忽略；混合输入只删有效项
    Ho = rmnode(Gd, 10)
    @test size(Ho.Nodes.nodeNames, 1) == 8
    @test Ho.Edges.endnodes == Gd.Edges.endnodes
    @test rmnode(Gd, [3, 10]).Edges.endnodes == rmnode(Gd, 3).Edges.endnodes
    @test rmnode(G, [1, 9]).Edges.endnodes == rmnode(G, 1).Edges.endnodes

    # 非正 ID 明确报错
    @test_throws ErrorException("超出范围。") rmnode(Gd, 0)
    @test_throws ErrorException("超出范围。") rmnode(Gd, -1)
    @test_throws ErrorException("超出范围。") rmnode(G, [1, 0])
end

# ========================================================================
# 与 MATLAB 对拍：matlab_results_rmnode.mat 由 MATLAB R2024a 实测生成
# ========================================================================

@testset "rmnode-matlab-compare" begin
    res = TyBase.load(joinpath(@__DIR__, "matlab_results_rmnode.mat"))["results"]
    s = [1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7]
    t = [2, 4, 8, 3, 7, 4, 6, 5, 6, 8, 7, 8]
    name = ["a", "b", "c", "d", "e", "f", "g", "h"]
    G = Graph(s, t)
    Gn = Graph(s, t, Float64[], name)
    Gd = DiGraph(s, t)

    function checkmat(H, key)
        m = res[key]
        @test sortslices(H.Edges.endnodes; dims=1) == Int.(m["endnodes"])
        @test numnodes(H) == Int(m["nnodes"])
        @test numedges(H) == Int(m["nedges"])
        if haskey(m, "nodenames")
            @test H.Nodes.nodeNames == string.(vec(m["nodenames"]))
        end
    end

    # 重复 ID / 重复名称按集合语义删除一次
    checkmat(rmnode(G, [3, 3]), "dup_single")
    checkmat(rmnode(G, [2, 2, 4, 4]), "dup_multi")
    checkmat(rmnode(G, [4, 2, 2]), "unsorted_dup")
    checkmat(rmnode(Gn, ["b", "b"]), "dup_name")
    checkmat(rmnode(Gn, ["b", "b", "e"]), "dup_name_multi")
    checkmat(rmnode(Gd, [3, 3]), "digraph_dup")

    # 越界 ID（> n）静默忽略；混合输入只删有效项
    checkmat(rmnode(G, 10), "oob_ignore")
    checkmat(rmnode(G, [3, 10]), "mixed_valid_oob")
    checkmat(rmnode(G, [10, 11]), "all_oob")
    checkmat(rmnode(Gd, 10), "digraph_oob")
    checkmat(rmnode(Gd, [3, 10]), "digraph_mixed")

    # 非正 ID：MATLAB 侧同样报错（iserr=1），本实现报「超出范围。」
    @test Int(res["neg_error"]["iserr"]) == 1
    @test Int(res["zero_error"]["iserr"]) == 1
    @test Int(res["mixed_zero_error"]["iserr"]) == 1
    @test_throws ErrorException("超出范围。") rmnode(G, -1)
    @test_throws ErrorException("超出范围。") rmnode(G, 0)
    @test_throws ErrorException("超出范围。") rmnode(G, [3, 0])
end
