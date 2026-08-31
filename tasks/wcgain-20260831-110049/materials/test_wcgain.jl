@testset "test_wcgain" begin
    default_options = wcOptions()
    @test default_options isa WCOptions
    @test default_options.ULevel == 1
    @test default_options.Display == false
    @test default_options.VaryUncertainty == false
    @test default_options.VaryFrequency == false
    @test default_options.Sensitivity == false
    @test default_options.SensitivityPercent == 25
    @test default_options.MussvOptions == ""

    custom_options = wcOptions(;
        ULevel=0.75,
        Display=true,
        VaryUncertainty=true,
        VaryFrequency=true,
        Sensitivity=true,
        SensitivityPercent=10,
        MussvOptions="f",
    )
    @test custom_options.ULevel == 0.75
    @test custom_options.Display == true
    @test custom_options.VaryUncertainty == true
    @test custom_options.VaryFrequency == true
    @test custom_options.Sensitivity == true
    @test custom_options.SensitivityPercent == 10
    @test custom_options.MussvOptions == "f"

    P = uss(tf(1, [1, 0])) + ultidyn("delta", [1, 1]; Bound=0.4)
    K = tf(2, [1 / 50 1])
    S = feedback(uss(1), P * K)
    maxgain, wcunc, info = wcgain(S)
    # MATLAB R2024b: [5.1036072481, 5.1139687414] at 10.7240662914 rad/s.
    # The Julia upper-bound descent can produce a tighter valid certificate.
    @test maxgain["LowerBound"] ≈ 5.1036072481 atol = 0.005
    @test maxgain["LowerBound"] <= maxgain["UpperBound"] <= 5.11897
    @test maxgain["CriticalFrequency"] ≈ 10.7240662914 atol = 0.2
    @test maxgain["LowerBound"] <= maxgain["UpperBound"]
    @test info["WorstPerturbation"] == wcunc
    @test maxgain isa AbstractDict
    @test all(value -> value isa Real, values(maxgain))
    @test wcunc isa AbstractDict
    @test info isa AbstractDict
    @test info["Model"] isa Integer
    @test info["Frequency"] isa AbstractVector{<:Real}
    @test info["Bounds"] isa AbstractMatrix{<:Real}
    @test info["WorstPerturbation"] isa AbstractDict
    @test info["Sensitivity"] isa AbstractDict
    @test size(info["Bounds"]) == (length(info["Frequency"]), 2)
    @test all(info["Bounds"][:, 1] .<= info["Bounds"][:, 2])
    @test length(info["Frequency"]) <= 2

    curve_options = wcOptions(; VaryFrequency=true)
    curve_gain, _, curve_info = wcgain(S, curve_options)
    # MATLAB R2024b VaryFrequency="on":
    # [5.1034111102, 5.1136525191] at 10.3470522449 rad/s.
    @test curve_gain["LowerBound"] ≈ 5.1034111102 atol = 0.005
    @test curve_gain["LowerBound"] <= curve_gain["UpperBound"] <= 5.11866
    @test curve_gain["CriticalFrequency"] ≈ 10.3470522449 atol = 0.4
    @test length(curve_info["Frequency"]) > 2
    @test curve_options.MussvOptions == ""

    range_gain, _, range_info = wcgain(S, (1.0, 20.0))
    @test 1.0 <= range_gain["CriticalFrequency"] <= 20.0
    @test all(1.0 .<= range_info["Frequency"] .<= 20.0)

    specified_frequency = [1, 5, 10]
    specified_gain, _, specified_info = wcgain(S, specified_frequency)
    # MATLAB R2024b evaluates USS models independently at explicitly supplied
    # frequencies.  The lower bounds agree to numerical precision.
    matlab_grid_lower = [0.7052614348, 4.1182841518, 5.0990195136]
    matlab_grid_upper = [0.7061676445, 4.1186245641, 5.1023797917]
    @test specified_info["Frequency"] == specified_frequency
    @test specified_info["Bounds"][:, 1] ≈ matlab_grid_lower atol = 1e-7
    @test all(specified_info["Bounds"][:, 1] .<= specified_info["Bounds"][:, 2])
    @test all(specified_info["Bounds"][:, 2] .<= matlab_grid_upper .+ 1e-7)
    @test specified_gain["LowerBound"] ≈ 5.0990195136 atol = 1e-7
    @test specified_gain["CriticalFrequency"] == 10.0
    _, _, specified_option_info = wcgain(
        S, specified_frequency, wcOptions(; VaryFrequency=true)
    )
    @test specified_option_info["Frequency"] == specified_info["Frequency"]
    @test specified_option_info["Bounds"] ≈ specified_info["Bounds"] atol = 1e-10
    @test_throws ErrorException wcgain(S, (10.0, 1.0))
    @test_throws ErrorException wcgain(S, Float64[])
    @test_throws ErrorException wcgain(S, [-1.0, 1.0])
    @test_throws ErrorException wcgain(S, wcOptions(; ULevel=0.0))
    @test_throws MethodError wcgain(tf(1.0, [1.0, 1.0]))

    # The second controller from the help example (BW=0.8) exercises a much
    # flatter peak than BW=2.0. MATLAB R2024b reports
    # [1.5064246973, 1.5088847810] at 4.9298241064 rad/s.
    slow_bandwidth = 0.8
    slow_controller = tf(slow_bandwidth, [1 / (25 * slow_bandwidth), 1.0])
    slow_sensitivity = feedback(uss(1), P * slow_controller)
    slow_gain, _, slow_info = wcgain(slow_sensitivity)
    @test slow_gain["LowerBound"] ≈ 1.5064246973 atol = 0.002
    @test slow_gain["LowerBound"] <= slow_gain["UpperBound"] <= 1.51089
    @test slow_gain["CriticalFrequency"] ≈ 4.9298241064 atol = 0.35
    @test length(slow_info["Frequency"]) <= 2

    # ULevel changes the normalized uncertainty radius without rebuilding the
    # model. MATLAB R2024b with ULevel=0.5 reports
    # [1.7055338183, 1.7082196579] at 11.6752794012 rad/s.
    half_level_gain, _, _ = wcgain(S, wcOptions(; ULevel=0.5))
    @test half_level_gain["LowerBound"] ≈ 1.7055338183 atol = 0.003
    @test half_level_gain["LowerBound"] <= half_level_gain["UpperBound"] <= 1.71122
    @test half_level_gain["CriticalFrequency"] ≈ 11.6752794012 atol = 0.8

    # Pure real parametric uncertainty. MATLAB R2024b reports
    # [2.4, 2.4051028604] at 0 rad/s.
    real_gain_block = ureal("real_gain_wcgain", 2.0; Percentage=20)
    real_uncertain_system = real_gain_block * tf(1.0, [1.0, 1.0])
    real_gain, real_wcu, real_info = wcgain(real_uncertain_system)
    @test real_gain["LowerBound"] ≈ 2.4 atol = 1e-8
    @test real_gain["LowerBound"] <= real_gain["UpperBound"] <= 2.40511
    @test real_gain["CriticalFrequency"] ≈ 0.0 atol = 1e-6
    @test real_wcu["real_gain_wcgain"] ≈ 2.4 atol = 1e-8
    @test real_info["WorstPerturbation"] == real_wcu

    sensitivity_gain, _, sensitivity_info = wcgain(
        S, wcOptions(; Sensitivity=true, SensitivityPercent=25)
    )
    @test sensitivity_gain["LowerBound"] <= sensitivity_gain["UpperBound"]
    @test haskey(sensitivity_info["Sensitivity"], "delta")
    @test isfinite(sensitivity_info["Sensitivity"]["delta"])

    nominal_system = uss(ss(tf(1, [1, 1])))
    nominal_gain, nominal_wcu, nominal_info = wcgain(nominal_system)
    @test nominal_gain["LowerBound"] ≈ 1 atol = 1e-5
    @test nominal_gain["UpperBound"] ≈ 1 atol = 1e-5
    @test isempty(nominal_wcu)
    @test size(nominal_info["Bounds"]) == (length(nominal_info["Frequency"]), 2)

    unstable_system = uss(ss(tf(1, [1, -1])))
    @test_throws ErrorException wcgain(unstable_system)

    # Mixed real/dynamic uncertainty exercises the fixed/vary _DGinit path
    # used by the Robust Controller Design guide.
    bw = ureal("bw_wcgain_regression", 5.0; Percentage=10)
    Gnom = ss(-bw, bw, 1.0, 0.0)
    weight = makeweight(0.05, 9.0, 10.0)
    dynamic_delta = ultidyn("Delta_wcgain_regression", [1, 1])
    plant = Gnom * (1.0 + weight * dynamic_delta)
    guide_results = Dict{Float64,Any}()
    for wn in (3.0, 7.5)
        kp = 2.0 * 0.707 * wn / 5.0 - 1.0
        ki = wn^2 / 5.0
        controller = tf([kp, ki], [1.0, 0.0])
        guide_sensitivity = feedback(uss(ss(1.0)), plant * controller)
        guide_gain, guide_wcu, guide_info = wcgain(guide_sensitivity)
        guide_results[wn] = guide_gain
        @test guide_gain["LowerBound"] <= guide_gain["UpperBound"]
        @test !isempty(guide_wcu)
        @test size(guide_info["Bounds"]) == (length(guide_info["Frequency"]), 2)
        @test all(guide_info["Bounds"][:, 1] .<= guide_info["Bounds"][:, 2])
    end

    # MATLAB Robust Control Toolbox reference values from the guide example.
    @test guide_results[3.0]["LowerBound"] ≈ 1.8831 atol = 0.01
    @test guide_results[3.0]["UpperBound"] ≈ 1.8862 atol = 0.02
    @test guide_results[3.0]["CriticalFrequency"] ≈ 3.1952 atol = 0.1
    @test guide_results[7.5]["LowerBound"] ≈ 4.6286 atol = 0.02
    @test guide_results[7.5]["UpperBound"] ≈ 4.6378 atol = 0.02
    @test guide_results[7.5]["CriticalFrequency"] ≈ 11.6132 atol = 0.2

    # Mixed real/dynamic uncertainty, PID control, limited frequency range,
    # and VaryFrequency=true. MATLAB R2024b reports
    # [2.0847990356, 2.0897251609] at 6.0749026435 rad/s (19 points).
    stiffness = ureal("k_wcgain_pid", 10.0; Percentage=40)
    second_order = ss([0.0 1.0; -stiffness -1.8], [0.0; 18.0], [1.0 0.0], 0.0)
    pid_delta = ultidyn("delta_wcgain_pid", [1, 1])
    pid_plant = second_order * (1.0 + 0.5 * pid_delta)
    pid_controller = pid(2.3, 3.0, 0.38, 0.001)
    pid_closed_loop = feedback(pid_plant * pid_controller, uss(1.0))
    pid_gain, pid_wcu, pid_info = wcgain(
        pid_closed_loop, (0.1, 10.0), wcOptions(; VaryFrequency=true)
    )
    @test pid_gain["LowerBound"] ≈ 2.0847990356 atol = 1e-4
    @test pid_gain["LowerBound"] <= pid_gain["UpperBound"] <= 2.08983
    @test pid_gain["CriticalFrequency"] ≈ 6.0749026435 atol = 0.05
    @test length(pid_info["Frequency"]) == 19
    @test all(0.1 .<= pid_info["Frequency"] .<= 10.0)
    @test haskey(pid_wcu, "k_wcgain_pid")
    @test haskey(pid_wcu, "delta_wcgain_pid")
end
