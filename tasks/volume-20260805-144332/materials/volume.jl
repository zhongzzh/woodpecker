using TyComputationalGeometry
using Test
using TyI18N

TyI18N.set_locale_zh!()

@testset "alphaShape_volume_matlab_reference" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P3d = [0 0 0; 1 0 0; 0 1 0; 0 0 1; ...
           5 0 0; 6 0 0; 5 1 0; 5 0 1; ...
           10 0 0; 10.3 0 0; 10 0.3 0; 10 0 0.3];
    shp = alphaShape(P3d, 1.0);
    nr = numRegions(shp);
    total_volume = volume(shp)
    region1_volume = volume(shp, 1)
    region_volumes = volume(shp, 1:nr)
    reverse_region_volumes = volume(shp, nr:-1:1)
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

    @test isapprox(@inferred(volume(shp)), 0.337833333333333; rtol=1e-14)
    @test isapprox(@inferred(volume(shp, 1)), 0.166666666666667; rtol=1e-14)
    @test isapprox(
        volume(shp, 1:3),
        [0.166666666666667, 0.166666666666667, 0.00450000000000001];
        rtol=1e-14,
    )
    @test isapprox(
        volume(shp, 3:-1:1),
        [0.00450000000000001, 0.166666666666667, 0.166666666666667];
        rtol=1e-14,
    )
    @test isapprox(
        volume(shp, [1 2; 3 1]),
        [0.166666666666667 0.166666666666667; 0.00450000000000001 0.166666666666667];
        rtol=1e-14,
    )
    @test isapprox(
        volume(shp, [1 1; 2 2]),
        [0.166666666666667 0.166666666666667; 0.166666666666667 0.166666666666667];
        rtol=1e-14,
    )
end

@testset "alphaShape_volume_thresholds_and_degenerate" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P3d = [0 0 0; 1 0 0; 0 1 0; 0 0 1; ...
           5 0 0; 6 0 0; 5 1 0; 5 0 1; ...
           10 0 0; 10.3 0 0; 10 0.3 0; 10 0 0.3];
    shp = alphaShape(P3d, 1.0);
    smallest = volume(shp, numRegions(shp));
    sh_equal = alphaShape(P3d, 1.0, 'RegionThreshold', smallest);
    sh_greater = alphaShape(P3d, 1.0, 'RegionThreshold', smallest + 8*eps(smallest));
    volume_equal = volume(sh_equal)
    volume_greater = volume(sh_greater)
    volume_empty = volume(alphaShape())
    volume_coplanar = volume(alphaShape([0 0 0; 1 0 0; 0 1 0; 1 1 0], Inf))
    volume_tetra_inf = volume(alphaShape([0 0 0; 1 0 0; 0 1 0; 0 0 1], Inf))
    volume_tetra_zero = volume(alphaShape([0 0 0; 1 0 0; 0 1 0; 0 0 1], 0))
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
    smallest = volume(shp, 1:3)[end]

    @test isapprox(
        volume(alphaShape(P3d, 1.0; RegionThreshold=smallest)),
        0.333333333333333;
        rtol=1e-14,
    )
    @test isapprox(
        volume(alphaShape(P3d, 1.0; RegionThreshold=smallest + 8eps(smallest))),
        0.333333333333333;
        rtol=1e-14,
    )
    @test volume(alphaShape()) == 0.0
    @test volume(alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 1.0 1.0 0.0], Inf)) ==
        0.0
    @test isapprox(
        volume(alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], Inf)),
        0.166666666666667;
        rtol=1e-14,
    )
    @test volume(alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], 0.0)) ==
        0.0
end

@testset "alphaShape_volume_hole_filling_matlab_reference" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P = [0 0 0; 0 0 1; 0 0 2; 0 1 0; 0 1 1; 0 1 2; ...
         0 2 0; 0 2 1; 0 2 2; 1 0 0; 1 0 1; 1 0 2; ...
         1 1 0; 1 1 2; 1 2 0; 1 2 1; 1 2 2; ...
         2 0 0; 2 0 1; 2 0 2; 2 1 0; 2 1 1; 2 1 2; ...
         2 2 0; 2 2 1; 2 2 2];
    ht_values = [0 1 2];
    out = zeros(numel(ht_values), 3);
    for k = 1:numel(ht_values)
        shp = alphaShape(P, 0.9, 'HoleThreshold', ht_values(k));
        out(k,:) = [numRegions(shp), volume(shp), size(alphaTriangulation(shp),1)];
    end
    out

    =#
    P = [
        0.0 0.0 0.0
        0.0 0.0 1.0
        0.0 0.0 2.0
        0.0 1.0 0.0
        0.0 1.0 1.0
        0.0 1.0 2.0
        0.0 2.0 0.0
        0.0 2.0 1.0
        0.0 2.0 2.0
        1.0 0.0 0.0
        1.0 0.0 1.0
        1.0 0.0 2.0
        1.0 1.0 0.0
        1.0 1.0 2.0
        1.0 2.0 0.0
        1.0 2.0 1.0
        1.0 2.0 2.0
        2.0 0.0 0.0
        2.0 0.0 1.0
        2.0 0.0 2.0
        2.0 1.0 0.0
        2.0 1.0 1.0
        2.0 1.0 2.0
        2.0 2.0 0.0
        2.0 2.0 1.0
        2.0 2.0 2.0
    ]
    shp0 = alphaShape(P, 0.9; HoleThreshold=0.0)
    shp1 = alphaShape(P, 0.9; HoleThreshold=1.0)
    shp2 = alphaShape(P, 0.9; HoleThreshold=2.0)

    @test isapprox(volume(shp0), 6.66666666666667; rtol=1e-14)
    @test size(alphaTriangulation(shp0), 1) == 40
    @test isapprox(volume(shp1), 6.66666666666667; rtol=1e-14)
    @test size(alphaTriangulation(shp1), 1) == 40
    @test isapprox(volume(shp2), 8.00000000000001; rtol=1e-14)
    @test size(alphaTriangulation(shp2), 1) == 44
end

@testset "alphaShape_volume_cache_invalidation" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    shp = alphaShape([0 0 0; 1 0 0; 0 1 0; 0 0 1], Inf);
    volume_initial = volume(shp)
    shp.Alpha = 0;
    volume_alpha_zero = volume(shp)
    shp.Alpha = Inf;
    shp.Points(2,1) = 2;
    volume_points_mutated = volume(shp)
    shp.Points = [0 0 0; 1 0 0; 0 2 0; 0 0 1];
    volume_points_reset = volume(shp)

    P3d = [0 0 0; 1 0 0; 0 1 0; 0 0 1; ...
           5 0 0; 6 0 0; 5 1 0; 5 0 1; ...
           10 0 0; 10.3 0 0; 10 0.3 0; 10 0 0.3];
    shp2 = alphaShape(P3d, 1.0);
    volume_total = volume(shp2)
    volume_region1 = volume(shp2, 1)
    shp2.RegionThreshold = 0.005;
    volume_rt = volume(shp2)
    shp2.HoleThreshold = 10;
    volume_ht = volume(shp2)
    =#
    shp = alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], Inf)
    @test isapprox(volume(shp), 0.166666666666667; rtol=1e-14)
    @test isapprox(volume(shp, 1.0), 0.166666666666667; rtol=1e-14)
    shp.Alpha = 0.0
    @test volume(shp) == 0.0
    shp.Alpha = Inf
    shp.Points[2, 1] = 2.0
    @test isapprox(volume(shp), 0.333333333333333; rtol=1e-14)
    shp.Points = [0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 2.0 0.0; 0.0 0.0 1.0]
    @test isapprox(volume(shp), 0.333333333333333; rtol=1e-14)

    shp2 = alphaShape(
        [
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
        ],
        1.0,
    )
    @test isapprox(volume(shp2), 0.337833333333333; rtol=1e-14)
    @test isapprox(volume(shp2, 1.0), 0.166666666666667; rtol=1e-14)
    shp2.RegionThreshold = 0.005
    @test isapprox(volume(shp2), 0.333333333333333; rtol=1e-14)
    shp2.HoleThreshold = 10.0
    @test isapprox(volume(shp2), 0.333333333333333; rtol=1e-14)
end

@testset "alphaShape_volume_errors" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    shp3 = alphaShape([0 0 0; 1 0 0; 0 1 0; 0 0 1], Inf);
    shp2 = alphaShape([0 0; 1 0; 0 1], Inf);
    try, volume(shp3,0); catch ME, disp(ME.identifier), disp(ME.message), end
    try, volume(shp3,2); catch ME, disp(ME.identifier), disp(ME.message), end
    try, volume(shp3,1.2); catch ME, disp(ME.identifier), disp(ME.message), end
    try, volume(shp2); catch ME, disp(ME.identifier), disp(ME.message), end
    try, volume(shp2,1); catch ME, disp(ME.message), end
    try, volume(shp3,[NaN,1]); catch ME, disp(ME.message), end
    try, volume(shp3,[1.2,1]); catch ME, disp(ME.message), end
    try, volume(shp3,[1.2]); catch ME, disp(ME.message), end
    =#
    shp = alphaShape([0.0 0.0 0.0; 1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], Inf)
    region_msg = "REGIONID 必须为 1 到 numRegions(SHP) 范围内的索引。"
    dim_msg = "此方法仅适用于 3 维 Alpha 形状。"
    alpha_msg = "Alpha 参数必须为非负标量。"
    hole_msg = "HoleThreshold 参数必须为非负标量。"
    region_threshold_msg = "RegionThreshold 参数必须为非负标量。"

    @test_throws ErrorException(region_msg) volume(shp, 0)
    @test_throws ErrorException(region_msg) volume(shp, 2)
    @test_throws ErrorException(region_msg) volume(shp, 1.2)
    @test_throws ErrorException(region_msg) volume(shp, NaN)
    @test_throws ErrorException(region_msg) volume(shp, "1")
    @test_throws ErrorException(region_msg) volume(shp, [NaN, 1])
    @test_throws ErrorException(region_msg) volume(shp, [1.2, 1])
    @test_throws ErrorException(region_msg) volume(shp, [1.2])
    @test_throws ErrorException(region_msg) volume(alphaShape(), 1)
    @test_throws ErrorException(dim_msg) volume(alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0]))
    @test_throws ErrorException(dim_msg) volume(alphaShape([0.0 0.0; 1.0 0.0; 0.0 1.0]), 1)
    @test_throws ErrorException(alpha_msg) (shp.Alpha = -1.0)
    @test_throws ErrorException(hole_msg) (shp.HoleThreshold = -1.0)
    @test_throws ErrorException(region_threshold_msg) (shp.RegionThreshold = Inf)
end

@testset "AI_volume_all_regions_filtered" begin
    #= MATLAB R2024a baseline, copy into MATLAB:
    P3d = [0 0 0; 1 0 0; 0 1 0; 0 0 1; ...
           5 0 0; 6 0 0; 5 1 0; 5 0 1; ...
           10 0 0; 10.3 0 0; 10 0.3 0; 10 0 0.3];
    shp = alphaShape(P3d, 1.0, 'RegionThreshold', 100);
    V = volume(shp)
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
    @test volume(alphaShape(P3d, 1.0; RegionThreshold=100.0)) == 0.0
end
