using TyImageProcessing, Test

@testset "radon" begin
    @testset "single pixel has a hand-checkable projection" begin
        for T in (Bool, UInt8, UInt16, Int16, Float32, Float64)
            R, xp = radon(fill(T(1), 1, 1), 0)

            @test R == reshape([0.125, 0.75, 0.125], :, 1)
            @test xp == reshape([-1.0, 0.0, 1.0], :, 1)
            @test eltype(R) == Float64
        end
    end

    @testset "angle forms and projection invariants" begin
        I = [1.0 0.0; -2.0 3.0]
        theta = [0.0 90.0; 180.0 270.0]
        R, xp = radon(I, theta)

        @test size(R) == (7, 4)
        @test size(xp) == (7, 1)
        @test vec(xp) == collect(-3.0:3.0)
        @test vec(sum(R; dims=1)) ≈ fill(sum(I), 4)
        @test R[:, 2] ≈ reverse(R[:, 1])
        @test R[:, 4] ≈ reverse(R[:, 3])

        scalar_R, scalar_xp = radon(I, 90)
        @test scalar_R == R[:, 3:3]
        @test scalar_xp == xp

        empty_R, empty_xp = radon(I, Float64[])
        @test size(empty_R) == (7, 0)
        @test empty_xp == xp
    end

    @testset "default and non-finite angles" begin
        R, xp = radon(Bool[1 0; 0 1])
        @test size(R) == (7, 180)
        @test vec(sum(R; dims=1)) ≈ fill(2.0, 180)
        @test vec(xp) == collect(-3.0:3.0)

        invalid_R, invalid_xp = radon(ones(2, 2), [Inf, NaN])
        @test all(isnan, invalid_R[1:2, :])
        @test all(iszero, invalid_R[3:end, :])
        @test invalid_xp == xp
    end

    @testset "unsupported inputs" begin
        @test_throws MethodError radon(ones(2, 2, 1))
        @test_throws MethodError radon(fill(1 + 0im, 2, 2))
    end
end
