using TyMathCore
using Test
using TyI18N

@testset "AI_polydiv_exact_division" begin
    q, r = polydiv([1.0 -3.0 2.0], [1.0 -1.0])
    @test q == [1.0 -2.0]
    @test r == [0.0 0.0 0.0]
end

@testset "AI_polydiv_remainder" begin
    q, r = polydiv([2.0, -3.0, 4.0, -5.0], [1.0, -2.0, 1.0])
    @test q == [2.0, 1.0]
    @test r == [0.0, 0.0, 4.0, -6.0]

    q, r = polydiv([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], [1.0, -1.0, 2.0])
    @test q == [1.0, 3.0, 4.0, 2.0]
    @test r == [0.0, 0.0, 0.0, 0.0, -1.0, 2.0]

    q, r = polydiv([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], [1.0, -1.0, 2.0, -2.0])
    @test q == [1.0, 3.0, 4.0]
    @test r == [0.0, 0.0, 0.0, 4.0, 3.0, 14.0]
end

@testset "AI_polydiv_divisor_longer" begin
    q, r = polydiv([1.0, 2.0, 3.0], [1.0, -1.0, 2.0, 4.0])
    @test q == [0.0]
    @test r == [1.0, 2.0, 3.0]
end

@testset "AI_polydiv_column_orientation" begin
    q, r = polydiv([1.0; 0.0; -4.0; 4.0], [1.0; -2.0])
    @test q == [1.0; 2.0; 0.0]
    @test r == [0.0; 0.0; 0.0; 4.0]
end

@testset "AI_polydiv_single_precision" begin
    q, r = polydiv(Float32[1.0, -3.0, 2.0, 4.0], Float32[1.0, -0.5])
    @test q isa Vector{Float32}
    @test r isa Vector{Float32}
    @test q == Float32[1.0, -2.5, 0.75]
    @test r == Float32[0.0, 0.0, 0.0, 4.375]
end

@testset "AI_polydiv_complex" begin
    q, r = polydiv([1 + 2im, -3 + 4im, 2 - im], [1 - im, 2 + 0.5im])
    @test q ≈ [-0.5 + 1.5im, -1.25 + 0.0im]
    @test r ≈ [0.0 + 0.0im, 0.0 + 0.0im, 4.5 - 0.375im]
end

@testset "AI_polydiv_scalar_and_integer" begin
    q, r = polydiv(5, 2)
    @test q == 2.5
    @test r == 0.0

    q, r = polydiv(Int32[1, 2, 3], [1, 1])
    @test q == [1.0, 1.0]
    @test r == [0.0, 0.0, 2.0]
end

@testset "AI_polydiv_empty_and_zero_divisor" begin
    q, r = polydiv(Float64[], [1.0, 2.0])
    @test q == [0.0]
    @test isempty(r)

    @test_throws ErrorException polydiv([1.0, 2.0], [0.0, 1.0])
    @test_throws BoundsError polydiv([1.0, 2.0], Float64[])
end

@testset "AI_polydiv_nonfinite_matlab_filter_path" begin
    q, r = polydiv([1.0, Inf, 3.0], [1.0, 1.0])
    @test q[1] == 1.0
    @test isinf(q[2])
    @test r[1:2] == [0.0, 0.0]
    @test isnan(r[3])

    q, r = polydiv(Inf, 1.0)
    @test isinf(q)
    @test r == 0.0
end

@testset "AI_polydiv_matrix_vector_inputs" begin
    q, r = polydiv(reshape([1.0, 0.0, -4.0, 4.0], 4, 1), reshape([1.0, -2.0], 2, 1))
    @test q == reshape([1.0, 2.0, 0.0], 3, 1)
    @test r == reshape([0.0, 0.0, 0.0, 4.0], 4, 1)

    q, r = polydiv(reshape([1.0, 0.0, -4.0, 4.0], 1, 4), reshape([1.0, -2.0], 1, 2))
    @test q == reshape([1.0, 2.0, 0.0], 1, 3)
    @test r == reshape([0.0, 0.0, 0.0, 4.0], 1, 4)

    TyI18N.set_locale_zh!()
    try
        polydiv([1.0 2.0; 3.0 4.0], [1.0, 1.0])
        @test false
    catch err
        @test occursin("B 必须为向量", sprint(showerror, err))
    end

    try
        polydiv([1.0, 2.0], [0.0, 1.0])
        @test false
    catch err
        @test occursin("A 的第一个系数必须非零", sprint(showerror, err))
    end
end
