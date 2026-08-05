using TyComputationalGeometry
using Test
using TyI18N

TyI18N.set_locale_zh!()

@testset "alphaShape_area_matlab_reference" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P2d = [0 0; 2 0; 0 2; 10 0; 11 0; 10 1; 20 0; 20.4 0; 20 0.4];
    shp = alphaShape(P2d, 2.0);
    nr = numRegions(shp);
    total_area = area(shp)
    region1_area = area(shp, 1)
    region_areas = area(shp, 1:nr)
    reverse_region_areas = area(shp, nr:-1:1)
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

    @test isapprox(@inferred(area(shp)), 2.58; rtol=1e-14)
    @test isapprox(@inferred(area(shp, 1)), 2.0; rtol=1e-14)
    @test isapprox(area(shp, 1:3), [2.0, 0.5, 0.0799999999999997]; rtol=1e-14)
    @test isapprox(area(shp, 3:-1:1), [0.0799999999999997, 0.5, 2.0]; rtol=1e-14)
    @test isapprox(area(shp, [1 2; 3 1]), [2.0 0.5; 0.0799999999999997 2.0]; rtol=1e-14)
    @test isapprox(area(shp, [1 1; 2 2]), [2.0 2.0; 0.5 0.5]; rtol=1e-14)
end

@testset "alphaShape_area_thresholds_and_degenerate" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P2d = [0 0; 2 0; 0 2; 10 0; 11 0; 10 1; 20 0; 20.4 0; 20 0.4];
    shp = alphaShape(P2d, 2.0);
    smallest = area(shp, numRegions(shp));
    sh_equal = alphaShape(P2d, 2.0, 'RegionThreshold', smallest);
    sh_greater = alphaShape(P2d, 2.0, 'RegionThreshold', smallest + 8*eps(smallest));
    area_equal = area(sh_equal)
    area_greater = area(sh_greater)
    area_empty = area(alphaShape())
    area_collinear = area(alphaShape([0 0; 1 0; 2 0], Inf))
    area_triangle_inf = area(alphaShape([0 0; 1 0; 0 1], Inf))
    area_triangle_zero = area(alphaShape([0 0; 1 0; 0 1], 0))
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
    smallest = area(shp, 1:3)[end]

    @test isapprox(area(alphaShape(P2d, 2.0; RegionThreshold=smallest)), 2.5; rtol=1e-14)
    @test isapprox(
        area(alphaShape(P2d, 2.0; RegionThreshold=smallest + 8eps(smallest))),
        2.5;
        rtol=1e-14,
    )
    @test area(alphaShape()) == 0.0
    @test area(alphaShape([0.0 0.0; 1.0 0.0; 2.0 0.0], Inf)) == 0.0
    @test isapprox(area(alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0], Inf)), 0.5; rtol=1e-14)
    @test area(alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0], 0.0)) == 0.0
end

@testset "alphaShape_area_hole_threshold_matlab_reference" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    [xg, yg] = meshgrid(0:4, 0:4);
    keep = xg == 0 | xg == 4 | yg == 0 | yg == 4;
    Pring = [xg(keep), yg(keep)];
    ht_values = [0, 3.999999999, 4, 4.000000001, 100];
    out = zeros(numel(ht_values), 3);
    for k = 1:numel(ht_values)
        sh = alphaShape(Pring, 1.1, 'HoleThreshold', ht_values(k));
        out(k,:) = [numRegions(sh), area(sh), size(alphaTriangulation(sh),1)];
    end
    out

    =#
    xg = repeat(collect(0.0:4.0)', 5, 1)
    yg = repeat(collect(0.0:4.0), 1, 5)
    keep = (xg .== 0.0) .| (xg .== 4.0) .| (yg .== 0.0) .| (yg .== 4.0)
    Pring = [xg[keep] yg[keep]]
    for ht in (0.0, 3.999999999, 4.0, 4.000000001, 100.0)
        shp = alphaShape(Pring, 1.1; HoleThreshold=ht)
        @test isapprox(area(shp), 2.0; rtol=1e-14)
        @test size(alphaTriangulation(shp), 1) == 4
    end
end

@testset "alphaShape_area_hole_filling_matlab_reference" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P = [0 0; 0 1; 0 2; 0 3; 1 0; 1 2; 1 3; ...
         2 0; 2 1; 2 2; 2 3; 3 0; 3 1; 3 2; 3 3];
    ht_values = [0 1 2];
    out = zeros(numel(ht_values), 3);
    for k = 1:numel(ht_values)
        shp = alphaShape(P, 0.75, 'HoleThreshold', ht_values(k));
        out(k,:) = [numRegions(shp), area(shp), size(alphaTriangulation(shp),1)];
    end
    out

    =#
    P = [
        0.0 0.0
        0.0 1.0
        0.0 2.0
        0.0 3.0
        1.0 0.0
        1.0 2.0
        1.0 3.0
        2.0 0.0
        2.0 1.0
        2.0 2.0
        2.0 3.0
        3.0 0.0
        3.0 1.0
        3.0 2.0
        3.0 3.0
    ]
    shp0 = alphaShape(P, 0.75; HoleThreshold=0.0)
    shp1 = alphaShape(P, 0.75; HoleThreshold=1.0)
    shp2 = alphaShape(P, 0.75; HoleThreshold=2.0)

    @test isapprox(area(shp0), 7.0; rtol=1e-14)
    @test size(alphaTriangulation(shp0), 1) == 14
    @test isapprox(area(shp1), 7.0; rtol=1e-14)
    @test size(alphaTriangulation(shp1), 1) == 14
    @test isapprox(area(shp2), 9.0; rtol=1e-14)
    @test size(alphaTriangulation(shp2), 1) == 16
end

@testset "alphaShape_area_cache_invalidation" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    shp = alphaShape([0 0; 1 0; 0 1], Inf);
    area_initial = area(shp)
    shp.Alpha = 0;
    area_alpha_zero = area(shp)
    shp.Alpha = Inf;
    shp.Points(2,1) = 2;
    area_points_mutated = area(shp)
    shp.Points = [0 0; 1 0; 0 2];
    area_points_reset = area(shp)

    P2d = [0 0; 2 0; 0 2; 10 0; 11 0; 10 1];
    shp2 = alphaShape(P2d, 2.0);
    area_total = area(shp2)
    area_region1 = area(shp2, 1)
    shp2.RegionThreshold = 0.5;
    area_rt = area(shp2)
    shp2.HoleThreshold = 10;
    area_ht = area(shp2)
    =#
    shp = alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0], Inf)
    @test isapprox(area(shp), 0.5; rtol=1e-14)
    shp.Alpha = 0.0
    @test area(shp) == 0.0
    shp.Alpha = Inf
    shp.Points[2, 1] = 2.0
    @test isapprox(area(shp), 1.0; rtol=1e-14)
    shp.Points = [0.0 0.0; 1.0 0.0; 0.0 2.0]
    @test isapprox(area(shp), 1.0; rtol=1e-14)

    shp2 = alphaShape([0.0 0.0; 2.0 0.0; 0.0 2.0; 10.0 0.0; 11.0 0.0; 10.0 1.0], 2.0)
    @test isapprox(area(shp2), 2.5; rtol=1e-14)
    @test isapprox(area(shp2, 1.0), 2.0; rtol=1e-14)
    shp2.RegionThreshold = 0.5
    @test isapprox(area(shp2), 2.0; rtol=1e-14)
    shp2.HoleThreshold = 10.0
    @test isapprox(area(shp2), 2.0; rtol=1e-14)
end

@testset "alphaShape_area_errors" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    shp2 = alphaShape([0 0; 2 0; 0 2; 10 0; 11 0; 10 1], 2.0);
    shp3 = alphaShape([0 0 0; 1 0 0; 0 1 0; 0 0 1], Inf);
    try, area(shp2,0); catch ME, disp(ME.identifier), disp(ME.message), end
    try, area(shp2,3); catch ME, disp(ME.identifier), disp(ME.message), end
    try, area(shp2,1.2); catch ME, disp(ME.identifier), disp(ME.message), end
    try, area(shp2,[NaN,1]); catch ME, disp(ME.message), end
    try, area(shp2,[1.2,1]); catch ME, disp(ME.message), end
    try, area(shp2,[1.2]); catch ME, disp(ME.message), end
    try, area(shp3); catch ME, disp(ME.identifier), disp(ME.message), end
    try, area(shp3,1); catch ME, disp(ME.message), end
    =#
    shp2 = alphaShape([0.0 0.0; 2.0 0.0; 0.0 2.0; 10.0 0.0; 11.0 0.0; 10.0 1.0], 2.0)
    region_msg = "REGIONID 必须为 1 到 numRegions(SHP) 范围内的索引。"
    dim_msg = "此方法仅适用于 2 维 Alpha 形状。"
    alpha_msg = "Alpha 参数必须为非负标量。"
    hole_msg = "HoleThreshold 参数必须为非负标量。"
    region_threshold_msg = "RegionThreshold 参数必须为非负标量。"

    @test_throws ErrorException(region_msg) area(shp2, 0)
    @test_throws ErrorException(region_msg) area(shp2, 3)
    @test_throws ErrorException(region_msg) area(shp2, 1.2)
    @test_throws ErrorException(region_msg) area(shp2, NaN)
    @test_throws ErrorException(region_msg) area(shp2, "1")
    @test_throws ErrorException(region_msg) area(shp2, [NaN, 1])
    @test_throws ErrorException(region_msg) area(shp2, [1.2, 1])
    @test_throws ErrorException(region_msg) area(shp2, [1.2])
    @test_throws ErrorException(region_msg) area(alphaShape(), 1)
    @test_throws ErrorException(dim_msg) area(
        alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])
    )
    @test_throws ErrorException(dim_msg) area(
        alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0]), 1
    )
    @test_throws ErrorException(alpha_msg) (shp2.Alpha = -1.0)
    @test_throws ErrorException(hole_msg) (shp2.HoleThreshold = -1.0)
    @test_throws ErrorException(region_threshold_msg) (shp2.RegionThreshold = Inf)
end

@testset "AI_area_all_regions_filtered" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P2d = [0 0; 2 0; 0 2; 10 0; 11 0; 10 1; 20 0; 20.4 0; 20 0.4];
    shp = alphaShape(P2d, 2.0, 'RegionThreshold', 100);
    A = area(shp)
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
    @test area(alphaShape(P2d, 2.0; RegionThreshold=100.0)) == 0.0
end
