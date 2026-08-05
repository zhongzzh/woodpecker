using TyComputationalGeometry
using Test
using TyI18N

TyI18N.set_locale_zh!()

function _sorted_tri_rows(T)
    isempty(T) && return T
    return sortslices(sort(T; dims=2); dims=1)
end

function _sorted_points(P)
    isempty(P) && return P
    return sortslices(P; dims=1)
end

function _tri_area(P, T)
    a = 0.0
    @inbounds for i in axes(T, 1)
        p1 = T[i, 1]
        p2 = T[i, 2]
        p3 = T[i, 3]
        a +=
            0.5 * abs(
                (P[p2, 1] - P[p1, 1]) * (P[p3, 2] - P[p1, 2]) -
                (P[p2, 2] - P[p1, 2]) * (P[p3, 1] - P[p1, 1]),
            )
    end
    return a
end

function _tet_volume(P, T)
    v = 0.0
    @inbounds for i in axes(T, 1)
        a, b, c, d = T[i, 1], T[i, 2], T[i, 3], T[i, 4]
        ad = (P[a, 1] - P[d, 1], P[a, 2] - P[d, 2], P[a, 3] - P[d, 3])
        bd = (P[b, 1] - P[d, 1], P[b, 2] - P[d, 2], P[b, 3] - P[d, 3])
        cd = (P[c, 1] - P[d, 1], P[c, 2] - P[d, 2], P[c, 3] - P[d, 3])
        cross = (
            bd[2] * cd[3] - bd[3] * cd[2],
            bd[3] * cd[1] - bd[1] * cd[3],
            bd[1] * cd[2] - bd[2] * cd[1],
        )
        v += abs(ad[1] * cross[1] + ad[2] * cross[2] + ad[3] * cross[3]) / 6
    end
    return v
end

@testset "alphaTriangulation_output_indexing" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P = [0 0; 1 0; 0 1; 100 100];
    shp = alphaShape(P, 0.8);
    tri_one_output = alphaTriangulation(shp)
    [tri_two_output, P_two_output] = alphaTriangulation(shp)
    area_one_output = polyarea(P(tri_one_output,1), P(tri_one_output,2))
    area_two_output = polyarea(P_two_output(tri_two_output,1), P_two_output(tri_two_output,2))
    =#
    shp = alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0; 100.0 100.0], 0.8)
    tri = @inferred alphaTriangulation(shp)
    tri2, P2 = alphaTriangulation(shp; nargout=Val(2))

    @test size(tri) == (1, 3)
    @test _sorted_tri_rows(tri) == [1 2 3]
    @test tri2 == [1 2 3]
    @test isapprox(_tri_area(shp.Points, tri), 0.5; rtol=1e-14)
    @test isapprox(_tri_area(P2, tri2), 0.5; rtol=1e-14)
    @test isapprox(_sorted_points(P2), [0.0 0.0; 0.0 1.0; 1.0 0.0]; rtol=1e-14)
end

@testset "alphaTriangulation_cache_invalidates_after_escaped_points_mutation" begin
    shp = alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0], Inf)
    tri = alphaTriangulation(shp)
    @test isapprox(_tri_area(getfield(shp, :Points), tri), 0.5; rtol=1e-14)

    P = shp.Points
    P[2, 1] = 2.0
    tri = alphaTriangulation(shp)
    @test isapprox(_tri_area(getfield(shp, :Points), tri), 1.0; rtol=1e-14)
end

@testset "alphaTriangulation_2d_regions" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P2d = [0 0; 2 0; 0 2; 10 0; 11 0; 10 1; 20 0; 20.4 0; 20 0.4];
    shp = alphaShape(P2d, 2.0);
    tri_all = alphaTriangulation(shp, 1:numRegions(shp))
    tri_rev = alphaTriangulation(shp, numRegions(shp):-1:1)
    [tri_region1, P_region1] = alphaTriangulation(shp, 1);
    area_all = area(shp)
    area_region1 = polyarea(P_region1(tri_region1,1), P_region1(tri_region1,2))
    =#
    P2d = [
        0.0 0.0
        2.0 0.0
        0.0 2.0
        10.0 0.0
        11.0 0.0
        10.0 1.0
        20.0 0.0
        20.4 0.0
        20.0 0.4
    ]
    shp = alphaShape(P2d, 2.0)
    tri_unfiltered = @inferred alphaTriangulation(shp)
    tri_region1 = alphaTriangulation(shp, 1)
    tri = @inferred alphaTriangulation(shp, 1:3)
    tri_rev = alphaTriangulation(shp, 3:-1:1)
    tri_perm = alphaTriangulation(shp, [3 1; 2 3])
    tri_dup = alphaTriangulation(shp, [1, 1, 2])
    tri_dup_matrix = alphaTriangulation(shp, [1 1; 2 2])
    tri_float_region = alphaTriangulation(shp, 1.0)
    tri2, P = alphaTriangulation(shp, 1; nargout=Val(2))

    @test tri_unfiltered == tri
    @test _sorted_tri_rows(tri_region1) == [1 2 3]
    @test _sorted_tri_rows(tri) == [1 2 3; 4 5 6; 7 8 9]
    @test tri_rev == tri
    @test tri_perm == tri
    @test _sorted_tri_rows(tri_dup) == [1 2 3; 4 5 6]
    @test tri_dup_matrix == tri_dup
    @test _sorted_tri_rows(tri_float_region) == [1 2 3]
    @test isapprox(_tri_area(shp.Points, tri), 2.58; rtol=1e-14)
    @test size(tri2) == (1, 3)
    @test maximum(tri2) <= size(P, 1)
    @test isapprox(_sorted_points(P), [0.0 0.0; 0.0 2.0; 2.0 0.0]; rtol=1e-14)
    @test isapprox(_tri_area(P, tri2), 2.0; rtol=1e-14)
end

@testset "alphaTriangulation_3d_regions_and_empty" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P3d = [0 0 0; 1 0 0; 0 1 0; 0 0 1; ...
           5 0 0; 6 0 0; 5 1 0; 5 0 1; ...
           10 0 0; 10.3 0 0; 10 0.3 0; 10 0 0.3];
    shp = alphaShape(P3d, 1.0);
    [tri_all, P_all] = alphaTriangulation(shp, 1:numRegions(shp));
    tri_size = size(tri_all)
    P_size = size(P_all)
    V = zeros(1, size(tri_all,1));
    for k = 1:size(tri_all,1)
        T = P_all(tri_all(k,:),:);
        V(k) = abs(dot(T(1,:) - T(4,:), cross(T(2,:) - T(4,:), T(3,:) - T(4,:))))/6;
    end
    total_volume_from_tri = sum(V)
    tri_empty = alphaTriangulation(alphaShape())
    [tri_empty2, P_empty2] = alphaTriangulation(alphaShape())
    tri_collinear = alphaTriangulation(alphaShape([0 0; 1 0; 2 0], Inf))
    [tri_col2, P_col2] = alphaTriangulation(alphaShape([0 0; 1 0; 2 0], Inf))
    tri_coplanar = alphaTriangulation(alphaShape([0 0 0; 1 0 0; 0 1 0; 1 1 0], Inf))
    [tri_cop2, P_cop2] = alphaTriangulation(alphaShape([0 0 0; 1 0 0; 0 1 0; 1 1 0], Inf))
    =#
    P3d = [
        0.0 0.0 0.0
        1.0 0.0 0.0
        0.0 1.0 0.0
        0.0 0.0 1.0
        5.0 0.0 0.0
        6.0 0.0 0.0
        5.0 1.0 0.0
        5.0 0.0 1.0
        10.0 0.0 0.0
        10.3 0.0 0.0
        10.0 0.3 0.0
        10.0 0.0 0.3
    ]
    shp = alphaShape(P3d, 1.0)
    tri_unfiltered = @inferred alphaTriangulation(shp)
    tri_region1 = alphaTriangulation(shp, 1)
    tri_all = alphaTriangulation(shp, 1:3)
    tri_rev = alphaTriangulation(shp, 3:-1:1)
    tri_perm = alphaTriangulation(shp, [3 1; 2 3])
    tri_dup = alphaTriangulation(shp, [1, 1, 2])
    tri_dup_matrix = alphaTriangulation(shp, [1 1; 2 2])
    tri, P = alphaTriangulation(shp, 1:3; nargout=Val(2))

    @test tri_unfiltered == tri_all
    @test _sorted_tri_rows(tri_region1) == [1 2 3 4]
    @test _sorted_tri_rows(tri_all) == [1 2 3 4; 5 6 7 8; 9 10 11 12]
    @test tri_rev == tri_all
    @test tri_perm == tri_all
    @test _sorted_tri_rows(tri_dup) == [1 2 3 4; 5 6 7 8]
    @test tri_dup_matrix == tri_dup
    @test size(tri) == (3, 4)
    @test tri == [1 2 3 4; 5 6 7 8; 9 10 11 12]
    @test size(P) == (12, 3)
    @test maximum(tri) <= size(P, 1)
    @test isapprox(_tet_volume(P, tri), 0.337833333333333; rtol=1e-14)
    @test alphaTriangulation(alphaShape()) == zeros(Int, 0, 0)
    tri_empty, P_empty = alphaTriangulation(alphaShape(); nargout=Val(2))
    @test tri_empty == zeros(Int, 0, 0)
    @test P_empty == zeros(Float64, 0, 0)
    @test alphaTriangulation(alphaShape([0.0 0.0; 1.0 0.0; 2.0 0.0], Inf)) ==
        zeros(Int, 0, 0)
    tri_col2, P_col2 = alphaTriangulation(
        alphaShape([0.0 0.0; 1.0 0.0; 2.0 0.0], Inf); nargout=Val(2)
    )
    @test tri_col2 == zeros(Int, 0, 0)
    @test P_col2 == zeros(Float64, 0, 0)
    @test alphaTriangulation(
        alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 1.0 1.0 0.0], Inf)
    ) == zeros(Int, 0, 0)
    tri_cop2, P_cop2 = alphaTriangulation(
        alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 1.0 1.0 0.0], Inf);
        nargout=Val(2),
    )
    @test tri_cop2 == zeros(Int, 0, 0)
    @test P_cop2 == zeros(Float64, 0, 0)
end

@testset "alphaTriangulation_errors" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P2d = [0 0; 2 0; 0 2; 10 0; 11 0; 10 1; 20 0; 20.4 0; 20 0.4];
    shp = alphaShape(P2d, 2.0);
    try, alphaTriangulation(shp,0); catch ME, disp(ME.identifier), disp(ME.message), end
    try, alphaTriangulation(shp,numRegions(shp)+1); catch ME, disp(ME.identifier), disp(ME.message), end
    try, alphaTriangulation(shp,[NaN,1]); catch ME, disp(ME.message), end
    try, alphaTriangulation(shp,[1.2,1]); catch ME, disp(ME.message), end
    try, alphaTriangulation(shp,[1.2]); catch ME, disp(ME.message), end
    try, alphaTriangulation(shp,[0,1]); catch ME, disp(ME.message), end
    =#
    shp = alphaShape(
        [
            0.0 0.0
            2.0 0.0
            0.0 2.0
            10.0 0.0
            11.0 0.0
            10.0 1.0
            20.0 0.0
            20.4 0.0
            20.0 0.4
        ],
        2.0,
    )
    region_msg = "REGIONID 必须为 1 到 numRegions(SHP) 范围内的索引。"
    nargout_msg = "nargout 的值必须为 Val(1) 或 Val(2)。"

    @test_throws ErrorException(region_msg) alphaTriangulation(shp, 0)
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, 4)
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, 1.2)
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, NaN)
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, "1")
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, [NaN, 1])
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, [1.2, 1])
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, [1.2])
    @test_throws ErrorException(region_msg) alphaTriangulation(shp, [0, 1])
    @test_throws ErrorException(nargout_msg) alphaTriangulation(shp; nargout=Val(3))
    @test_throws ErrorException(nargout_msg) alphaTriangulation(shp; nargout=2)
end
