using TySymbolicMath
using Test

@testset "iztrans(F)_test1" begin
    # syms z
    # F = 2*z/(z-2)^2;
    # iztrans(F)
    @variables z n
    F = 2 * z / (z - 2)^2
    @test isequal(iztrans(F), 2^n + (-1 + n) * (2^n))
end

@testset "iztrans(F)_test2" begin
    # syms z a
    # F = 1/(a*z);
    # iztrans(F)
    @variables a, z, n
    F = 1 / (a * z)
    @test isequal(sym_simplify(iztrans(F) - kroneckerDelta(-1 + n, 0) / a), 0)
end

@testset "iztrans(F,transvar)_test1" begin
    # syms z a m
    # F = 1/(a*z);
    # iztrans(F,m)
    @variables a, z, m
    F = 1 / (a * z)
    @test isequal(sym_simplify(iztrans(F, m) - kroneckerDelta(-1 + m, 0) / a), 0)
end

@testset "iztrans(F,var,transvar)_test1" begin
    # syms z n
    # f = (z^3 + 3*z^2)/z^5;;
    # iztrans(f,z,n)
    @variables z n
    f = (z^3 + 3 * z^2) / z^5
    expected =
        TySymbolicMath.kroneckerDelta(-2 + n, 0) + 3TySymbolicMath.kroneckerDelta(-3 + n, 0)
    @test isequal(sym_simplify(iztrans(f, z, n) - expected), 0)
end

@testset "iztrans(F::Matrix,var::Matrix,transvar::Matrix)_test2" begin
    # syms a b c d w x y z
    # M = [exp(x) 1; sin(y) i*z];
    # vars = [w x; y z];
    # transVars = [a b; c d];
    # iztrans(M,vars,transVars)
    @variables a b c d w x y z
    M = [exp(x) 1; sin(y) im*z]
    vars = [w x; y z]
    transVars = [a b; c d]
    @test isequal(
        string(iztrans(M, vars, transVars)),
        string(
            Number[
                kroneckerDelta(a, 0)*exp(x) kroneckerDelta(b, 0)
                TySymbolicMath.iZtrans(sin(y), y, c) im*TySymbolicMath.iZtrans(z, z, d)
            ],
        ),
    )
end

@testset "iztrans(F::Matrix,transvar)_test1" begin
    # syms s m
    # F = 2*s/(s-2)^2;
    # iztrans(F,n)
    @variables s m
    F = 2 * s / (s - 2)^2
    @test isequal(iztrans(F, m), 2^m + (-1 + m) * (2^m))
end

@testset "iztrans_bug_1" begin
    # syms z a T b n
    # F_2 = z/((z-exp(-a*T))*(z-exp(-b*T)))
    # fk_2 = iztrans(F_2,z,n)
    @variables z, a, T, b, n
    F_2 = z / ((z - exp(-a * T)) * (z - exp(-b * T)))
    fk_2 = iztrans(F_2, z, n)
    @test isequal(
        fk_2,
        exp(T * (a + b - b * n)) / (-exp(T * b) + exp(T * a)) +
        (-exp(T * (a + b - a * n))) / (-exp(T * b) + exp(T * a)),
    )
end
@testset "iztrans recovers the documented z-domain product" begin
    @variables n z
    Fz = z / (z + 1)
    Hz = z / (3 * (z + 1)) + (2 * z) / (3 * (z - 3))

    # The constant term of Fz * Hz contributes the n = 0 impulse.
    @test isequal(
        iztrans(Fz * Hz, z, n),
        TySymbolicMath.kroneckerDelta(n, 0) +
        (1//2) * (3^n) +
        (5//6) * ((-1)^n) +
        (1//3) * (-1 + n) * ((-1)^n),
    )
end

@testset "iztrans handles documented scalar and array forms" begin
    @variables m n z

    @test isequal(iztrans(Num(1), z, n), kroneckerDelta(n, 0))

    inverse_powers = iztrans([1 / z, 1 / z^2], z, n)
    @test size(inverse_powers) == (2,)
    @test isequal(inverse_powers[1], kroneckerDelta(n - 1, 0))
    @test isequal(inverse_powers[2], kroneckerDelta(n - 2, 0))

    expanded = iztrans(1 / z, z, [n, m])
    @test size(expanded) == (2,)
    @test isequal(expanded[1], kroneckerDelta(n - 1, 0))
    @test isequal(expanded[2], kroneckerDelta(m - 1, 0))
end

@testset "iztrans inverts unevaluated ztrans nodes" begin
    @variables n x z
    F = ztrans(tan(n), n, z)

    @test isequal(iztrans(F), tan(n))
    @test isequal(iztrans(F, x), tan(x))
    @test isequal(iztrans(F, z, x), tan(x))
end

@testset "iztrans(F::Vector,var::Vector,transvar::Vector)_test1" begin
    # syms z n
    # F = [1/z, 1/z^2];
    # vars = [z, z];
    # transVars = [n, n];
    # iztrans(F,vars,transVars)
    @variables z n
    F_2 = [1 / z, 1 / z^2]
    vars = [z, z]
    transVars = [n, n]
    expected = [kroneckerDelta(-1 + n, 0), kroneckerDelta(-2 + n, 0)]
    @test isequal(iztrans(F_2, vars, transVars), expected)
end
