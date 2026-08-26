using Test
using TyDifferentialEquation
using TyMathCore

include("ode45_data.jl")

@testset "ode45" begin
    # tspan = [0 5];
    # y0 = 0;
    # [t,y] = ode45(@(t,y) 2*t, tspan, y0);
    @testset "test1" begin
        tspan = [0 5]
        y0 = 0
        t, y, = ode45((t, y) -> 2 * t, tspan, y0)
        @test isapprox(y, res1, atol=1e-14, rtol=1e-14)
    end

    # [t,y] = ode45(@vdp1,[0 20],[2; 0]);
    @testset "test2" begin
        t, y, = ode45((t, y) -> [y[2]; (1 - y[1]^2) * y[2] - y[1]], [0 20], [2; 0])
        @test isapprox(y, res2, atol=1e-11, rtol=1e-11)
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
    # [t,y] = ode45(@(t,y) odefcn(t,y,A,B), tspan, y0); 
    ## [t,y] = ode45(@(t,y) [y(2);(A/B)*t.*y(1)], tspan, y0);
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
        t, y, = ode45((t, y) -> odefcn(t, y, A, B), tspan, y0)
        @test isapprox(y, res3, atol=1e-14, rtol=1e-14)
    end

    # yprime = @(t,y) -2*y + 2*cos(t).*sin(2*t);
    # y0 = -5:5;
    # tspan = [0 3];
    # [t, y] = ode45(yprime, tspan, y0);
    @testset "test4" begin
        yprime = (t, y) -> @. -2 * y + 2 * cos(t) .* sin(2 * t)
        y0 = -5:5
        tspan = [0 3]
        t, y, = ode45(yprime, tspan, y0)
        @test isapprox(y, res4, atol=1e-14, rtol=1e-14)
    end

    # ft = linspace(0, 5, 25);
    # f = ft .^ 2 - ft - 3;
    # gt = linspace(1, 6, 25);
    # g = 3 * sin(gt - 0.25);
    # function dydt = myode(t,y,ft,f,gt,g)
    # f = interp1(ft,f,t); % Interpolate the data set (ft,f) at time t
    # g = interp1(gt,g,t); % Interpolate the data set (gt,g) at time t
    # dydt = -f.*y + g; % Evaluate ODE at time t
    # tspan = [1 5];
    # ic = 1;
    # opts = odeset('RelTol',1e-2,'AbsTol',1e-4);
    # [t,y] = ode45(@(t,y) myode(t,y,ft,f,gt,g), tspan, ic, opts); 
    ## [t,y] = ode45(@(t,y) (-interp1(ft,f,t).*y + interp1(gt,g,t)), tspan, ic, opts);
    @testset "test5" begin
        ft = LinRange(0, 5, 25)
        f = ft .^ 2 - ft .- 3
        gt = LinRange(1, 6, 25)
        g = 3 * sin.(gt .- 0.25)
        tspan = [1 5]
        ic = 1
        opts = odeset(; reltol=1e-2, abstol=1e-4)
        t, y, = ode45(
            (t, y) -> -interp1(ft, f, t) .* y .+ interp1(gt, g, t), tspan, ic, opts
        )
        @test isapprox(y, res5, atol=1e-14, rtol=1e-14)
    end

    # tspan = [0 20]
    # y0 = [2 0]
    # sol = ode45(@vdp1, tspan, y0)
    @testset "test6" begin
        tspan = [0 20]
        y0 = [2 0]
        sol = ode45(
            (t, y) -> [y[2]; (1 - y[1]^2) * y[2] - y[1]], tspan, y0; output_sol=ReturnStruct
        )
        @test isapprox(sol.x, resx, atol=1e-12, rtol=1e-12)
        @test isapprox(sol.y, resy, atol=1e-11, rtol=1e-11)
    end

    @testset "test7" begin
        function lotka(t, y)
            alpha = 0.01
            beta = 0.02
            return [(1 - alpha * y[2]) * y[1]; (-1 + beta * y[1]) * y[2]]
        end

        t0 = 0
        tfinal = 15
        y0 = [20; 20]
        @test_nowarn t, y = ode45(lotka, [t0 tfinal], y0)
    end
    @testset "test8" begin
        function mass(t, q, P)
            m1 = P.m1
            m2 = P.m2
            L = P.L
            g = P.g
            M = zeros(6, 6)
            M[1, 1] = 1
            M[2, 2] = m1 + m2
            M[2, 6] = -m2 * L * sin(q[5])
            M[3, 3] = 1
            M[4, 4] = m1 + m2
            M[4, 6] = m2 * L * cos(q[5])
            M[5, 5] = 1
            M[6, 2] = -L * sin(q[5])
            M[6, 4] = L * cos(q[5])
            M[6, 6] = L^2
            return M
        end

        function f(t, q, P)
            m1 = P.m1
            m2 = P.m2
            L = P.L
            g = P.g
            return [
                q[2]
                m2 * L * q[6]^2 * cos(q[5])
                q[4]
                m2 * L * q[6]^2 * sin(q[5]) - (m1 + m2) * g
                q[6]
                -g * L * cos(q[5])
            ]
        end

        P = (m1=0.1, m2=0.1, L=1, g=9.81)

        tspan = LinRange(0, 4, 25)

        y0 = [0; 4; P.L; 20; -pi / 2; 2]

        opts = odeset(; mass=(t, q) -> mass(t, q, P))

        @test_nowarn t, q = ode45((t, q) -> f(t, q, P), tspan, y0, opts)
    end
    @testset "test9" begin
        ode = (t, y) -> -abs.(y)
        options1 = odeset(; refine=1)
        @test_nowarn t0, y0 = ode45(ode, [0 40], 1, options1)

        options2 = odeset(options1; nonnegative=[1])
        @test_nowarn t1, y1 = ode45(ode, [0 40], 1, options2)
    end

    @testset "test10" begin
        tstart = 0
        tfinal = 30
        y0 = [0; 20]
        refine = 4
        function g(t, y)
            return [y[2]; -9.8]
        end

        function events(t, y)
            return y[1], 1, -1
        end
        options = odeset(;
            events=events, refine=refine, normcontrol=:on, mass=Matrix{Int}(I, 2, 2)
        )
        t, y, te, ye, ie = ode45(g, [tstart tfinal], y0, options)
        @test isapprox(t, res10t)
        @test isapprox(y, res10y)
        @test isapprox(te, [res10te])
        @test isapprox(ye, res10ye)
        @test isapprox(ie, [res10ie])
    end
    @testset "AI_matlab_refine1_reference" begin
        matlab_t = [
            0.0,
            0.10000000000000001,
            0.20000000000000001,
            0.30000000000000004,
            0.40000000000000002,
            0.5,
            0.59999999999999998,
            0.69999999999999996,
            0.79999999999999993,
            0.89999999999999991,
            1.0,
        ]
        matlab_y = [
            1.0,
            0.81873077333333333,
            0.67032007920299808,
            0.54881167682673182,
            0.44932900858271357,
            0.36787948667802506,
            0.30119425662136917,
            0.24659700664717205,
            0.2018965579539243,
            0.16529892502695459,
            0.1353353167184872,
        ]
        opts = odeset(; refine=1)
        t, y = ode45((t, y) -> -2 * y, [0 1], 1, opts)
        @test isapprox(vec(t), matlab_t; atol=1e-14, rtol=1e-14)
        @test isapprox(vec(y), matlab_y; atol=1e-12, rtol=1e-12)
    end

    @testset "AI_matlab_initialstep_outputfcn_reference" begin
        matlab_t = [
            0.0,
            0.050000000000000003,
            0.10000000000000001,
            0.15000000000000002,
            0.20000000000000001,
            0.25,
            0.29999999999999999,
            0.34999999999999998,
            0.39999999999999997,
            0.44999999999999996,
            0.5,
        ]
        matlab_y = [
            1.0,
            0.95122942450520831,
            0.90483741804450979,
            0.8607079764372576,
            0.818730753093455,
            0.77880078308980305,
            0.74081822070271897,
            0.7046880897420198,
            0.67032004606097606,
            0.63762815164888698,
            0.60653065974129039,
        ]
        callback_count = Ref(0)
        function ai_outputfcn(t, y, flag)
            callback_count[] += 1
            return false
        end
        opts = odeset(; initialstep=0.05, refine=1, outputfcn=ai_outputfcn, outputsel=[1])
        t, y = ode45((t, y) -> -y, [0 0.5], 1, opts)
        @test callback_count[] > 0
        @test isapprox(vec(t), matlab_t; atol=1e-14, rtol=1e-14)
        @test isapprox(vec(y), matlab_y; atol=1e-12, rtol=1e-12)
    end

    @testset "test11" begin
        # tspan = [0 5];
        # y0 = 0 + 10i;
        # [t,y,a] = ode45(@(t,y) 2*t, tspan, y0);
        @testset "test1" begin
            tspan = [0 5]
            y0 = 0 + 10im
            t1, y1, a = ode45((t, y) -> 2 * t, tspan, y0)
            @test isapprox(y1, resy11, atol=1e-14, rtol=1e-14)
            @test isapprox(t1, rest11, atol=1e-14, rtol=1e-14)
            @test_skip isapprox(a, [10; 0; 61; 0; 0; 0; 5], atol=1e-14, rtol=1e-14)
            sk = ode45((t, y) -> 2 * t, tspan, y0; output_sol=true)
            @test isapprox(
                sk.y,
                [0 + 10im 0.25 + 10im 1 + 10im 2.25 + 10im 4 + 10im 6.25 + 10im 9 + 10im 12.25 +
                                                                                         10im 16 +
                                                                                              10im 20.25 +
                                                                                                   10im 25 +
                                                                                                        10im],
                atol=1e-14,
                rtol=1e-14,
            )
        end
    end
end

@testset "tspan_vector" begin
    tspan1 = [0, 1]
    t1, y1 = ode45((t, y) -> 1, tspan1, 0)
    @test isapprox(vec(y1), vec(t1), atol=1e-14, rtol=1e-14)
    tspan2 = [0.0, 0.25, 0.5, 0.75, 1.0]
    t2, y2 = ode45((t, y) -> 1.0, tspan2, 0.0)
    @test isapprox(vec(t2), tspan2, atol=1e-14, rtol=1e-14)
    @test isapprox(vec(y2), tspan2, atol=1e-14, rtol=1e-14)
end
@testset "maxstep" begin
    options = odeset(; maxstep=0.1)
    t, y = ode45((t, y) -> -y, [0 1], 1, options)
    @test maximum(abs.(diff(vec(t)))) <= 0.1 + eps(Float64)
    @test isapprox(y[end], exp(-1), atol=1e-6, rtol=1e-6)
end
