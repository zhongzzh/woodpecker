using Test
using TyDifferentialEquation
using TyMathCore

include("ode89_data.jl")

@testset "ode89" begin
    # tspan = [0 5];
    # y0 = 0;
    # [t,y] = ode89(@(t,y) 2*t, tspan, y0);
    @testset "test1" begin
        tspan = [0 5]
        y0 = 0
        t, y, = ode89((t, y) -> 2 * t, tspan, y0)
        @test isapprox(y, res1, atol=1e-8, rtol=1e-8)
    end

    # [t,y] = ode89(@vdp1,[0 20],[2; 0]);
    @testset "test2" begin
        t, y, = ode89((t, y) -> [y[2]; (1 - y[1]^2) * y[2] - y[1]], [0 20], [2; 0])
        @test isapprox(y, res2, atol=1e-3, rtol=1e-3)
    end

    # function dydt = odefcn(t, y, A, B)
    #     dydt = zeros(2, 1)
    #     dydt(1) = y(2)
    #     dydt(2) = (A / B) * t .* y(1)
    # end
    # A = 1;
    # B = 2;
    # tspan = [0 5];
    # y0 = [0 0.01];
    # [t,y] = ode89(@(t,y) odefcn(t,y,A,B), tspan, y0); 
    ## [t,y] = ode89(@(t,y) [y(2);(A/B)*t.*y(1)], tspan, y0);
    @testset "test3" begin
        A = 1
        B = 2
        tspan = [0 5]
        y0 = [0 0.01]
        function odefcn(t, y, A, B)
            dydt = zeros(2, 1)
            dydt[1] = y[2]
            dydt[2] = (A / B) * t .* y[1]
            return dydt
        end
        t, y, = ode89((t, y) -> odefcn(t, y, A, B), tspan, y0)
        @test isapprox(y, res3, atol=1e-10, rtol=1e-10)
    end

    # function dy = twobodyode(t,y)
    # % Two-body problem with one mass much larger than the other.
    # r = sqrt(y(1)^2 + y(3)^2);
    # dy = [y(2); 
    #     -y(1)/r^3;
    #     y(4);
    #     -y(3)/r^3];
    # end
    # opts = odeset('Reltol',1e-13,'AbsTol',1e-14,'Stats','on');
    # tspan = [0 10*pi];
    # y0 = [2 0 0 0.5];
    # [t,y] = ode89(@twobodyode, tspan, y0, opts);
    ## [t,y] = ode89(@(t,y) [y(2);-y(1)/(sqrt(y(1)^2 + y(3)^2))^3;y(4);-y(3)/(sqrt(y(1)^2 + y(3)^2))^3], tspan, y0, opts);
    @testset "test4" begin
        opts = odeset(; reltol=1e-13, abstol=1e-14, stats=:on)
        tspan = [0 10*pi]
        y0 = [2 0 0 0.5]
        function twobodyode(t, y)
            r = sqrt(y[1]^2 + y[3]^2)
            dy = [y[2]; -y[1] / r^3; y[4]; -y[3] / r^3]
            return dy
        end
        @test_nowarn t, y, = ode89(twobodyode, tspan, y0, opts)
        @test_nowarn ode89(twobodyode, tspan, y0, opts; output_sol=ReturnStruct)
        # @test isapprox(y, res4, atol=1e-1, rtol=1e-1)
    end

    @testset "test5" begin
        function pleiades(t, q)
            x = q[1:7]
            y = q[8:14]
            xDist = (x .- transpose(x))
            yDist = (y .- transpose(y))
            r = (xDist .^ 2 + yDist .^ 2) .^ (3 / 2)
            m = (1:7)
            tmp_x = xDist .* m ./ r
            tmp_x[findall(isnan, tmp_x)] .= 0
            tmp_y = yDist .* m ./ r
            tmp_y[findall(isnan, tmp_y)] .= 0
            return [
                q[15:28]
                transpose(sum(tmp_x; dims=1))
                transpose(sum(tmp_y; dims=1))
            ]
        end

        opts = odeset(; reltol=1e-13, abstol=1e-15, stats=:on)

        init = [
            3 3 -1 -3 2 -2 2
            3 -3 2 0 0 -4 4
            0 0 0 0 0 1.75 -1.5
            0 0 0 -1.25 1 0 0
        ]'
        tspan = LinRange(1, 15, 200)

        @test_nowarn t89, q89 = ode89(pleiades, tspan, init, opts)
    end

    @testset "test6" begin
        tstart = 0
        tfinal = 30
        y0 = [0; 20]
        refine = 4
        function f(t, y)
            return [y[2]; -9.8]
        end

        function events(t, y)
            return y[1], 1, -1
        end
        options = odeset(;
            events=events, refine=refine, normcontrol=:on, mass=Matrix{Int}(I, 2, 2)
        )

        t, y, te, ye, ie = ode89(f, [tstart tfinal], y0, options)
        @test isapprox(t, res6t)
        @test isapprox(y[1:(end - 4), :], res6y[1:(end - 4), :])
        @test isapprox(te, [res6te])
        @test isapprox(ye, res6ye)
        @test isapprox(ie, [res6ie])

        options1 = odeset(options; nonnegative=[1])
        @test_nowarn t, y, te, ye, ie = ode89(f, [tstart tfinal 50], y0, options1)
    end

    @testset "AI_matlab_refine1_reference" begin
        matlab_t = [
            0.0,
            0.1,
            0.2,
            0.30000000000000004,
            0.4,
            0.5,
            0.6,
            0.7,
            0.7999999999999999,
            0.8999999999999999,
            1.0,
        ]
        matlab_y = [
            1.0,
            0.8187307530779822,
            0.6703200460356398,
            0.5488116360940269,
            0.44932896411722217,
            0.3678794411714429,
            0.3011942119122027,
            0.24659696394160707,
            0.20189651799465597,
            0.16529888822158706,
            0.13533528323661315,
        ]
        opts = odeset(; refine=1)
        t, y = ode89((t, y) -> -2 * y, [0 1], 1, opts)
        @test isapprox(vec(t), matlab_t; atol=1e-14, rtol=1e-14)
        @test isapprox(vec(y), matlab_y; atol=1e-12, rtol=1e-12)
    end

    @testset "AI_matlab_refine3_reference" begin
        matlab_t = [
            0.0,
            0.03333333333333333,
            0.06666666666666667,
            0.1,
            0.13333333333333333,
            0.16666666666666669,
            0.2,
            0.23333333333333334,
            0.2666666666666667,
            0.30000000000000004,
            0.33333333333333337,
            0.3666666666666667,
            0.4,
            0.43333333333333335,
            0.4666666666666667,
            0.5,
            0.5333333333333333,
            0.5666666666666667,
            0.6,
            0.6333333333333333,
            0.6666666666666666,
            0.7,
            0.7333333333333333,
            0.7666666666666666,
            0.7999999999999999,
            0.8333333333333333,
            0.8666666666666666,
            0.8999999999999999,
            0.9333333333333332,
            0.9666666666666667,
            1.0,
        ]
        matlab_y = [
            1.0,
            1.0344568936938139,
            1.0712115448278279,
            1.1103418361512953,
            1.1519282902581125,
            1.1960541590646174,
            1.2428055163203398,
            1.2922713532542682,
            1.3445436774632453,
            1.3997176151520063,
            1.4578915168388444,
            1.5191670666440107,
            1.5836493952825408,
            1.6514471968870141,
            1.7226728497899684,
            1.7974425414002564,
            1.875876397312171,
            1.9580986147906549,
            2.0442376007810181,
            2.13442611459659,
            2.2288014154426903,
            2.327505414940953,
            2.430684834823575,
            2.5384913699725136,
            2.6510818569849355,
            2.768618448452314,
            2.8912687931466095,
            3.0192062223139,
            3.1526099422825755,
            3.2916652335998275,
            3.4365636569180915,
        ]
        opts = odeset(; refine=3)
        t, y = ode89((t, y) -> t .+ y, [0 1], 1, opts)
        @test isapprox(vec(t), matlab_t; atol=1e-14, rtol=1e-14)
        @test isapprox(vec(y), matlab_y; atol=1e-12, rtol=1e-12)
    end

    @testset "AI_matlab_initialstep_outputfcn_reference" begin
        matlab_t = [
            0.0,
            0.05,
            0.1,
            0.15000000000000002,
            0.2,
            0.25,
            0.3,
            0.35,
            0.39999999999999997,
            0.44999999999999996,
            0.5,
        ]
        matlab_y = [
            1.0,
            0.951229424500714,
            0.9048374180359595,
            0.8607079764250578,
            0.8187307530779818,
            0.7788007830714049,
            0.7408182206817179,
            0.7046880897187134,
            0.6703200460356393,
            0.6376281516217733,
            0.6065306597126334,
        ]
        callback_count = Ref(0)
        function ai_outputfcn(t, y, flag)
            callback_count[] += 1
            return false
        end
        opts = odeset(; initialstep=0.05, refine=1, outputfcn=ai_outputfcn, outputsel=[1])
        t, y = ode89((t, y) -> -y, [0 0.5], 1, opts)
        @test callback_count[] > 0
        @test isapprox(vec(t), matlab_t; atol=1e-14, rtol=1e-14)
        @test isapprox(vec(y), matlab_y; atol=1e-12, rtol=1e-12)
    end

    # tspan = [0 5];
    # y0 = 0 + 5i;
    # [t,y,a] = ode89(@(t,y) 2*t, tspan, y0);
    @testset "test11" begin
        tspan = [0 5]
        y0 = 0 + 5im
        t, y, a = ode89((t, y) -> 2 * t, tspan, y0)
        @test isapprox(y, y11m, atol=1e-12, rtol=1e-12)
        @test_skip isapprox(a, [10; 0; 210; 0; 0; 0; 5], atol=1e-12, rtol=1e-12)
        sk89 = ode89((t, y) -> 2 * t, tspan, y0; output_sol=true)
        @test isapprox(
            sk89.y,
            [0+5im 0.25+5im 1+5im 2.25+5im 4+5im 6.25+5im 9+5im 12.25+5im 16+5im 20.25+5im 25+5im],
            atol=1e-12,
            rtol=1e-12,
        )
    end
end

@testset "test_tspan_decreasing" begin
    tspan = [1.0 0.5 0.0]
    y0 = 1.0
    t, y = ode89((t, y) -> 2 * t, tspan, y0)
    @test isapprox(vec(t), vec(tspan), atol=1e-14, rtol=1e-14)
    @test isapprox(vec(y), vec(tspan) .^ 2, atol=1e-12, rtol=1e-12)
end
