using Test
using TyStatisticsCore
using TyMathCore

@testset "lillitest" begin
    include("lillietest_data1.jl")
    include("lillietest_data2.jl")
    @testset "lillitest_test1" begin
        @test isequal(lillietest(MPG)[1], 1)
        @test isequal(lillietest(MPG)[1], 1)
        @test isequal(lillietest(MPG)[2], 0.001)
        @test isapprox(lillietest(MPG)[3], 0.0788791104643846, atol=1e-15)
        @test isapprox(lillietest(MPG)[4], 0.0451246074533684, atol=1e-15)
    end
    @testset "lillitest_test2" begin
        @test isequal(lillietest(MPG; alpha=0.03, dist="ev")[1], 1)
        @test isequal(lillietest(MPG; alpha=0.03, dist="ev")[1], 1)
        @test isequal(lillietest(MPG; alpha=0.03, dist="ev")[2], 0.001)
        # @test isapprox(lillietest(MPG, alpha=0.03, dist="ev", Np = true)[3], 0.122922695707806,atol=1e-5)   evfit涉及优化算法，存在精度差异
        @test isapprox(
            lillietest(MPG; alpha=0.03, dist="ev")[4], 0.0468839265710448, atol=1e-15
        )
    end
    @testset "lillitest_test3" begin
        @test isequal(lillietest(MPG; alpha=0.03, dist="exponential")[1], 1)
        @test isequal(lillietest(MPG; alpha=0.03, dist="exponential")[1], 1)
        @test isequal(lillietest(MPG; alpha=0.03, dist="exponential")[2], 0.001)
        @test isapprox(
            lillietest(MPG; alpha=0.03, dist="exponential")[3], 0.39202806575992, atol=1e-15
        )
        @test isapprox(
            lillietest(MPG; alpha=0.03, dist="exponential")[4],
            0.0578083131765893,
            atol=1e-15,
        )
    end
    @testset "lillitest_test4" begin
        rng = MT19937ar(5489)
        @test isequal(lillietest(rng, MPG; alpha=0.05, dist="normal", mctol=0.003)[1], 1)
        @test isequal(lillietest(rng, MPG; alpha=0.05, dist="normal", mctol=0.003)[2], 0.0)
        #= @test isapprox(
            lillietest(MPG, alpha=0.05, dist="normal", 0.003; Np = true)[3],
            0.0788791104643846,
            atol = 1e-15,
        ) =#
        # @test isapprox(lillietest(MPG, alpha=0.05, dist="normal", 0.003, Np = true)[4], 0.0448620111359219, atol = 1e-15)
    end
    @testset "lillitest_test5" begin
        @test isequal(lillietest(MPG; alpha=0.05, dist="ev", mctol=0.003)[1], 1)
        @test isequal(lillietest(MPG; alpha=0.05, dist="ev", mctol=0.003)[2], 0.0)
        #= @test isapprox(
            lillietest(MPG, alpha=0.05, dist="ev"; mctol = 0.003, Np = true)[3], 0.122922695707806, atol = 1e-15
        )
        @test isapprox(
            lillietest(MPG, alpha=0.05, dist="ev"; mctol = 0.003, Np = true)[4], 0.0443256247639556, atol = 1e-15
        ) =#
    end
    @testset "lillitest_test6" begin
        @test isequal(lillietest(MPG; alpha=0.05, dist="exponential", mctol=0.003)[1], 1)
        @test isequal(lillietest(MPG; alpha=0.05, dist="exponential", mctol=0.003)[2], 0.0)
        @test isapprox(
            lillietest(MPG; alpha=0.05, dist="exponential", mctol=0.003)[3],
            0.39202806575992,
            atol=1e-15,
        )
        #=  @test isapprox(
            lillietest(MPG, alpha=0.05, dist="exponential", 0.003; Np = true)[4], 0.054029765368407, atol = 1e-15
        ) =#
    end
    @testset "lillietest_test7" begin
        @test isequal(lillietest(x)[1], 1)
        @test isapprox(lillietest(x)[2], 0.0347714996826993, atol=1e-9)
        @test isapprox(lillietest(x)[3], 0.0847670378804077, atol=1e-15)
        @test isapprox(lillietest(x)[4], 0.0814138040049847, atol=1e-15)
        @test isequal(lillietest(x; alpha=0.01)[1], 0)
        @test isapprox(lillietest(x; alpha=0.01)[2], 0.0347714996826993, atol=1e-9) ## 涉及Optim中Brent()算法，存在一定精度差异
        @test isapprox(lillietest(x; alpha=0.01)[3], 0.0847670378804077, atol=1e-15)
        @test isapprox(lillietest(x; alpha=0.01)[4], 0.0948928614487432, atol=1e-15)
        @test isequal(lillietest(x; alpha=0.01, dist="exponential")[1], 1)
        @test isequal(lillietest(x; alpha=0.01, dist="exponential")[2], 0.001)
        @test isapprox(
            lillietest(x; alpha=0.01, dist="exponential")[3], 0.515627417212194, atol=1e-15
        )
        @test isapprox(
            lillietest(x; alpha=0.01, dist="exponential")[4], 0.116158294189483, atol=1e-15
        )
        @test isequal(lillietest(x; alpha=0.01, dist="ev")[1], 0)
        # @test isapprox(lillietest(x, alpha=0.01, dist="ev";Np = true)[2], 0.049276912045086, atol = 1e-9)
        # @test isapprox(lillietest(x, alpha=0.01, dist="ev";Np = true)[3], 0.0802869507971561, atol = 1e-9)
        @test isapprox(
            lillietest(x; alpha=0.01, dist="ev")[4], 0.0930122602428879, atol=1e-15
        )
    end

    @testset "lillietest_test8" begin
        x = [
            118
            115
            115
            122
            118
            121
            120
            122
            120
            113
            120
            123
            121
            109
            117
            117
            120
            116
            118
            125
        ]
        h, p, kstat, critval = lillietest(x)
        @test !h
        @test isapprox(p, 0.221427599329261, rtol=1e-14)
        @test isapprox(kstat, 0.156028285057096, rtol=1e-14)
        @test critval == 0.192
    end

    @testset "lillietest preserves non-NaN input data" begin
        input = [3.0, 1.0, 4.0, 2.0]
        expected = copy(input)
        lillietest(input)
        @test isequal(input, expected)
    end

    @testset "lillietest rejects insufficient valid observations" begin
        function capture_lillietest_error(input)
            try
                lillietest(input)
            catch err
                return err
            end
            return nothing
        end

        expected = capture_lillietest_error([1, 2, 3])
        @test expected isa ErrorException
        expected_message = sprint(showerror, expected)

        inputs = (
            Any[],
            Int[],
            Float64[],
            [1],
            [1, 2],
            [NaN],
            fill(NaN, 4),
            [1.0, NaN, 2.0, NaN, 3.0],
        )
        for input in inputs
            actual = capture_lillietest_error(input)
            @test actual isa ErrorException
            @test sprint(showerror, actual) == expected_message
        end
    end

    @testset "lillitest_error" begin
        msg = "The sample vector x must contain at least 4 valid observations."
        @test_throws ErrorException(msg) lillietest([1, 2, 3])
        msg = "sdga is not a valid value for the dist keyword parameter. Valid values are: \"normal\", \"exponential\", \"ev\", \"extreme value\"."
        @test_throws ErrorException(msg) lillietest([1, 2, 3, 4], alpha=0.05, dist="sdga")
        msg = "The significance level alpha must be a scalar value between 0 and 1."
        @test_throws ErrorException(msg) lillietest([1, 2, 3, 4], alpha=2)
        msg = "The Monte Carlo standard error tolerance mctol must be a positive scalar value."
        @test_throws ErrorException(msg) lillietest(
            [1, 2, 3, 4], alpha=0.05, dist="normal"; mctol=-1
        )
        msg = "The significance level alpha exceeds the range of the listed values. Please use a value within the interval [0.001, 0.5], or use the mctol input parameter."
        @test_throws ErrorException(msg) lillietest([1, 2, 3, 4], alpha=0.99)
    end
end
