using Test
using TyComputationalGeometry
using TyBase

const NSIDEDPOLY_MATLAB_DATA = TyBase.load(
    joinpath(@__DIR__, "nsidedpoly_matlab_data.mat"); toworkspace=false
)

function _open_boundary(pgon)
    x, y = boundary(pgon)
    return hcat(x[1:(end - 1)], y[1:(end - 1)])
end

function _matlab_scalar(name)
    value = NSIDEDPOLY_MATLAB_DATA[name]
    return value isa Number ? value : only(value)
end

@testset "nsidedpoly" begin
    @testset "MATLAB-compatible geometry" begin
        triangle = nsidedpoly(3)
        @test _open_boundary(triangle) ≈ NSIDEDPOLY_MATLAB_DATA["default_n3_vertices"]
        @test numsides(triangle) == _matlab_scalar("default_n3_numsides")
        @test numboundaries(triangle) == _matlab_scalar("default_n3_numboundaries")
        @test triangle.NumRegions == _matlab_scalar("default_n3_numregions")
        @test triangle.NumHoles == _matlab_scalar("default_n3_numholes")
        @test issimplified(triangle) == _matlab_scalar("default_n3_issimplified")

        square = nsidedpoly(4)
        @test _open_boundary(square) ≈ NSIDEDPOLY_MATLAB_DATA["default_n4_vertices"]
        @test area(square) ≈ _matlab_scalar("default_n4_area")
        @test perimeter(square) ≈ _matlab_scalar("default_n4_perimeter")
        @test collect(centroid(square)) ≈ vec(NSIDEDPOLY_MATLAB_DATA["default_n4_centroid"])

        pentagon = nsidedpoly(5)
        @test _open_boundary(pentagon) ≈ NSIDEDPOLY_MATLAB_DATA["default_n5_vertices"]

        decagon_vertices = _open_boundary(nsidedpoly(10))
        @test decagon_vertices ≈ NSIDEDPOLY_MATLAB_DATA["default_n10_vertices"]
    end

    @testset "Center, Radius, and SideLength" begin
        centered = nsidedpoly(4; Center=[2, -1], Radius=3)
        @test _open_boundary(centered) ≈ NSIDEDPOLY_MATLAB_DATA["centered_n4_vertices"]
        @test collect(centroid(centered)) ≈
            vec(NSIDEDPOLY_MATLAB_DATA["centered_n4_centroid"])

        side_square = nsidedpoly(4; SideLength=2)
        @test _open_boundary(side_square) ≈ NSIDEDPOLY_MATLAB_DATA["side_n4_vertices"]
        @test area(side_square) ≈ _matlab_scalar("side_n4_area")
        @test perimeter(side_square) ≈ _matlab_scalar("side_n4_perimeter")

        for n in (3, 5, 8, 17)
            pgon = nsidedpoly(n; SideLength=1)
            expected = NSIDEDPOLY_MATLAB_DATA["side_n$(n)_vertices"]
            @test _open_boundary(pgon) ≈ expected
        end
    end

    @testset "Numeric input compatibility" begin
        matlab_n3 = NSIDEDPOLY_MATLAB_DATA["default_n3_vertices"]
        @test _open_boundary(nsidedpoly(3.0)) ≈ matlab_n3
        @test _open_boundary(nsidedpoly(Int32(3))) ≈ matlab_n3
        @test _open_boundary(nsidedpoly(3 + 0im)) ≈ matlab_n3
        @test _open_boundary(nsidedpoly(4; Center=Int32[1, 2])) ≈
            NSIDEDPOLY_MATLAB_DATA["integer_center_n4_vertices"]
        @test _open_boundary(nsidedpoly(4; Radius=2 + 0im)) ≈
            NSIDEDPOLY_MATLAB_DATA["radius_n4_vertices"]
        @test _open_boundary(nsidedpoly(4; SideLength=Float32(2))) ≈
            NSIDEDPOLY_MATLAB_DATA["side_n4_vertices"]
    end

    @testset "Input validation" begin
        for n in (2, 3.5, NaN, Inf, 3 + 1im, big(typemax(Int)) + 1)
            @test_throws ErrorException nsidedpoly(n)
        end
        @test_throws MethodError nsidedpoly([3])

        invalid_centers = (
            [1.0],
            [1.0, 2.0, 3.0],
            [1.0 NaN],
            [1.0, NaN],
            [1.0, Inf],
            [1.0, 2.0im],
            (1.0, 2.0),
            BigFloat[2big(floatmax(Float64)), 0],
        )
        for center in invalid_centers
            @test_throws ErrorException nsidedpoly(4; Center=center)
        end

        invalid_sizes = (0, -1, NaN, Inf, 1 + 1im, [1.0])
        for radius in invalid_sizes
            @test_throws ErrorException nsidedpoly(4; Radius=radius)
        end
        for side_length in invalid_sizes
            @test_throws ErrorException nsidedpoly(4; SideLength=side_length)
        end

        @test_throws ErrorException nsidedpoly(4; Radius=2, SideLength=1)
        @test_throws ErrorException nsidedpoly(4; Radius=big(floatmax(Float64)) * 2)
        @test_throws ErrorException nsidedpoly(4; SideLength=big(floatmax(Float64)) * 2)
        @test_throws ErrorException nsidedpoly(4; Radius=nextfloat(0.0))
        @test_throws ErrorException nsidedpoly(4; Radius=floatmax(Float64))
        @test_throws ErrorException nsidedpoly(4; SideLength=nextfloat(0.0))
        @test_throws ErrorException nsidedpoly(4; SideLength=floatmax(Float64))
        @test_throws ErrorException nsidedpoly(4; Center=[floatmax(Float64), 0.0])
    end
end
