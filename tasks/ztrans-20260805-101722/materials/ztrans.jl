using TySymbolicMath
using Test

@testset "ztrans_test1" begin
    @variables n, z
    f = sin(n)
    expected = z * sin(1) / (z^2 - 2 * cos(1) * z + 1)
    @test isequal(sym_simplify(ztrans(f) - expected), 0)
end

@testset "ztrans_test2" begin
    @variables n z
    expected = (z * (z - cos(1))) / (z^2 - 2 * cos(1) * z + 1)
    @test isequal(sym_simplify(ztrans(cos(n), n, z) - expected), 0)
end

@testset "ztrans_test3" begin
    @variables n z
    expected = TySymbolicMath.Ztrans(tan(n), n, z)
    @test isequal(ztrans(tan(n), z), expected)
    @test isequal(sym_simplify(ztrans(tan(n), z, n) - (n * tan(n)) / (-1 + n)), 0)
end

@testset "ztrans evaluates geometric sequences" begin
    @variables n z
    f = (-1)^n
    h = (1//3) * (-1)^n + (2//3) * 3^n

    @test isequal(ztrans(f), z / (z + 1))
    @test isequal(
        sym_simplify(ztrans(h) - (z / (3 * (z + 1)) + (2 * z) / (3 * (z - 3)))), 0
    )
end

@testset "ztrans uses its independent variable as summation index" begin
    @variables n w

    @test isequal(ztrans((-1)^n, w), w / (w + 1))
    @test isequal(ztrans((-1)^n, n, w), w / (w + 1))
end

@testset "ztrans follows documented variable selection" begin
    @variables m n y z
    f = exp(m + n)

    @test isequal(sym_simplify(ztrans(f) - z * exp(m) / (z - exp(1))), 0)
    @test isequal(sym_simplify(ztrans(f, y) - y * exp(m) / (y - exp(1))), 0)
    @test isequal(sym_simplify(ztrans(f, m, y) - y * exp(n) / (y - exp(1))), 0)
end

@testset "ztrans evaluates polynomial sequences" begin
    @variables n z

    @test isequal(sym_simplify(ztrans(n, n, z) - z / (z - 1)^2), 0)
    @test isequal(sym_simplify(ztrans(n^2, n, z) - z * (z + 1) / (z - 1)^3), 0)
end

@testset "ztrans_docs_test" begin
    @variables m n z
    f = exp(m + n)
    fz = ztrans(f)
    @test isequal(fz, (z * exp(m)) / (-2.718281828459045 + z))
    @variables y
    fz = ztrans(f, y)
    @test isequal(fz, (y * exp(m)) / (-2.718281828459045 + y))
    fz = ztrans(f, m, y)
    @test isequal(fz, (y * exp(n)) / (-2.718281828459045 + y))
end

@testset "ztrans keeps unevaluated transforms symbolic" begin
    @variables n z
    expected = TySymbolicMath.Ztrans(tan(n), n, z)

    @test isequal(ztrans(tan(n)), expected)
    @test isequal(ztrans(tan(n), n, z), expected)
end
@testset "ztrans supports complex matrices" begin
    @variables a b c d w x y z
    M = [exp(x) 1; sin(y) im*z]
    vars = [w x; y z]
    transvars = [a b; c d]

    fz = ztrans(M, vars, transvars)
    expected = [
        a * exp(x)/(a - 1) b/(b - 1)
        c * sin(1)/(c^2 - 2cos(1) * c + 1) im * d/(d - 1)^2
    ]

    @test size(fz) == (2, 2)
    @test all(isequal(sym_simplify(fz[i] - expected[i]), 0) for i in eachindex(fz))
end
@testset "ztrans avoids default transform-variable collisions" begin
    @variables w z n

    @test isequal(sym_simplify(ztrans(im * z) - im * w / (w - 1)^2), 0)
    @test isequal(sym_simplify(ztrans(im * z, z, w) - im * w / (w - 1)^2), 0)
    @test isequal(sym_simplify(ztrans(im * n) - im * z / (z - 1)^2), 0)
end

@testset "ztrans follows MATLAB default n selection" begin
    @variables n w z
    @test isequal(sym_simplify(ztrans(n + z) - z / (z - 1)^2 - z^2 / (z - 1)), 0)
    @test isequal(sym_simplify(ztrans(n * z) - z^2 / (z - 1)^2), 0)
    @test isequal(sym_simplify(ztrans(n + z, w) - (w / (w - 1)^2 + z * w / (w - 1))), 0)
    @test isequal(sym_simplify(ztrans(n + z, z, w) - (n * w / (w - 1) + w / (w - 1)^2)), 0)
end
@testset "ztrans keeps variable inference transform-local" begin
    @variables m n z

    @test isequal(ztrans(Num(1)), z / (z - 1))
    @test isequal(TySymbolicMath._trans_get_var(Num(1), :htrans), Num[])
    @test isequal(
        TySymbolicMath._trans_get_var(exp(m + n), :htrans),
        TySymbolicMath.sym_get_var(exp(m + n)),
    )
end

@testset "ztrans supports vector inputs" begin
    @variables n w z
    f = [sin(n), cos(n)]
    vars = [n, n]
    transvars = [z, w]

    fz = ztrans(f, vars, transvars)
    expected = [
        z * sin(1) / (z^2 - 2 * cos(1) * z + 1),
        w * (w - cos(1)) / (w^2 - 2 * cos(1) * w + 1),
    ]

    @test size(fz) == (2,)
    @test all(isequal(sym_simplify(fz[i] - expected[i]), 0) for i in eachindex(fz))
end

@testset "ztrans supports symbolic functions" begin
    @variables n z w f(n) g(n)
    expected = TySymbolicMath.Ztrans(f, n, z)

    @test isequal(ztrans(f, n, z), expected)

    fz = ztrans.([f g], n, [z w])
    expected = [
        TySymbolicMath.Ztrans(f, n, z)
        TySymbolicMath.Ztrans(g, n, w)
    ]

    @test size(fz) == (1, 2)
    @test all(isequal(fz[i], expected[i]) for i in eachindex(fz))
end

@testset "ztrans supports transform-variable expressions" begin
    @variables n z
    transvar = z + 1

    @test isequal(sym_simplify(ztrans((-1)^n, n, transvar) - (z + 1) / (z + 2)), 0)
end
