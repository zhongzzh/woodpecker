using Test
using TyMathCore
using SpecialFunctions: SpecialFunctions

@testset "AI_bessely_matlab_scalar_reference" begin
    # MATLAB source:
    # bessely(2, 1), bessely(2, 0.375), bessely(2, 0.789), bessely(0.5, 0.75)
    # bessely(-1.5, 1 + 2i), bessely(0.5, 1 + 2i)
    expected_real = -1.6506826068162548
    expected_float32 = -9.3927961379429874
    expected_bigfloat = parse(BigFloat, "-2.4138011131315245")
    expected_noninteger_real = -0.67411792914454494
    expected_negative_order = -0.33135934722373145 - 1.1610671990114132im
    expected_generic_complex = -0.066515696518825551 + 1.9554364136610953im

    @test isapprox(bessely(Cint(2), 1.0), expected_real; rtol=1e-13, atol=1e-13)
    @test isapprox(bessely(2.0, 1.0), expected_real; rtol=1e-13, atol=1e-13)
    @test isapprox(
        bessely(Cint(2), Float32(0.375)), Float32(expected_float32); rtol=1e-6, atol=1e-6
    )
    @test isapprox(bessely(0.5, 0.75), expected_noninteger_real; rtol=1e-13, atol=1e-13)
    @test isapprox(
        bessely(2, parse(BigFloat, "0.789")), expected_bigfloat; rtol=1e-14, atol=1e-14
    )
    @test isapprox(bessely(-1.5, 1 + 2im), expected_negative_order; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(1//2, 1 + 2im), expected_generic_complex; rtol=1e-12, atol=1e-12)
end

@testset "AI_bessely_matlab_scale_and_array_dispatch" begin
    # MATLAB source:
    # z = [1+2i, 2-1i; 0.5+0.25i, 1.5-0.75i];
    # bessely(2, z), bessely(2, z, 1)
    z = ComplexF64[1+2im 2-im; 0.5+0.25im 1.5-0.75im]
    expected_unscaled = ComplexF64[
        -0.75124548726769147-0.12395010696911363im -0.57374073395963066-0.41041309825527816im
        -2.793833208201062+3.2390041122906146im -0.70647372801316988-0.41555537507843976im
    ]
    expected_scaled = ComplexF64[
        -0.10167002079960014-0.016774822833873437im -0.2110674205863621-0.15098254123559199im
        -2.175839490317883+2.5225389390234314im -0.33371455950367429-0.19629445999880196im
    ]

    @test isapprox(bessely(2, 1 + 2im, false), expected_unscaled[1]; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(2, 1 + 2im, 0), expected_unscaled[1]; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(2, 1 + 2im, true), expected_scaled[1]; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(2, 1 + 2im, 1), expected_scaled[1]; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(2, z), expected_unscaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(2, z, false), expected_unscaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(Cint(2), z, true), expected_scaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(2, z, 1), expected_scaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely.(2, z), expected_unscaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely.(2, z, 0), expected_unscaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely.(2, z, true), expected_scaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely.(2, z, 1), expected_scaled; rtol=1e-12, atol=1e-12)
    @test eltype(bessely(2, z)) === ComplexF64

    z_large = fill(z[1], 4096)
    @test isapprox(
        bessely(2, z_large), fill(expected_unscaled[1], 4096); rtol=1e-12, atol=1e-12
    )
    @test isapprox(
        bessely(2, z_large, true), fill(expected_scaled[1], 4096); rtol=1e-12, atol=1e-12
    )
end

@testset "AI_bessely1_series_matlab_reference" begin
    # MATLAB source:
    # z = [1+2i, 2-1i; 0.5+0.25i, 1.5-0.75i];
    # bessely(1, z), bessely(1, z, 1), bessely(1, 7, 1)
    # bessely(1, [6, -1+eps*1i, -1-eps*1i, 5.9+0.3i])
    z = ComplexF64[1+2im 2-im; 0.5+0.25im 1.5-0.75im]
    expected_unscaled = ComplexF64[
        -1.089469855204281+1.3149514645322733im -0.016315437820472616-0.59940684176685377im
        -1.2403713257034621+0.50034960697280695im -0.37388480709572125-0.48180690422330119im
    ]
    expected_scaled = ComplexF64[
        -0.14744371143182275+0.17795932889487387im -0.0060021141478628845-0.22050945398352931im
        -0.96600215975717307+0.38967266571989179im -0.17661067745004516-0.2275894664347809im
    ]
    expected_far = -0.30266723702418485 + 0.0im
    expected_far_scaled = -0.30266723702418491 + 0.0im

    @test isapprox(bessely(1, z), expected_unscaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(1, z, true), expected_scaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(1.0, z[1]), expected_unscaled[1]; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely(1.0, z[1], true), expected_scaled[1]; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely.(1, z), expected_unscaled; rtol=1e-12, atol=1e-12)
    @test isapprox(bessely.(1, z, true), expected_scaled; rtol=1e-12, atol=1e-12)
    broadcasted_y1 = Base.Broadcast.broadcasted(bessely, 1, z)
    fused_y1 = Base.Broadcast.broadcasted(+, broadcasted_y1, 1)
    @test broadcasted_y1 isa Base.Broadcast.Broadcasted
    @test fused_y1 isa Base.Broadcast.Broadcasted
    @test isapprox(
        Base.materialize(fused_y1), expected_unscaled .+ 1; rtol=1e-12, atol=1e-12
    )
    @test isapprox(
        bessely(1, ComplexF64[7.0 + 0.0im])[1], expected_far; rtol=1e-12, atol=1e-12
    )
    @test isapprox(
        bessely(1, ComplexF64[7.0 + 0.0im], true)[1],
        expected_far_scaled;
        rtol=1e-12,
        atol=1e-12,
    )

    z_large = fill(z[1], 4096)
    @test isapprox(
        bessely(1, z_large), fill(expected_unscaled[1], 4096); rtol=1e-12, atol=1e-12
    )
    @test isapprox(
        bessely(1, z_large, true), fill(expected_scaled[1], 4096); rtol=1e-12, atol=1e-12
    )

    boundary_points = ComplexF64[
        6.0 + 0.0im, -1.0 + eps(Float64) * im, -1.0 - eps(Float64) * im, 5.9 + 0.3im
    ]
    expected_boundary = ComplexF64[
        -0.17501034430039838 + 0.0im,
        0.78121282130028891 - 0.88010117148986677im,
        0.78121282130028891 + 0.88010117148986677im,
        -0.15674914949604532 - 0.084829415123671578im,
    ]
    for (point, expected) in zip(boundary_points, expected_boundary)
        @test isapprox(bessely(1, ComplexF64[point])[1], expected; rtol=1e-12, atol=1e-12)
    end
end

@testset "AI_bessely_single_complex_matlab_reference" begin
    # MATLAB source:
    # z = single(1 + 2i); bessely(single(1), z), bessely(single(1), z, 1)
    # bessely(single(1), single([1 + 2i, 2 - 1i]), 1)
    z = ComplexF32(1.0f0, 2.0f0)
    z_array = ComplexF32[1.0f0 + 2.0f0im, 2.0f0 - 1.0f0im]
    expected = ComplexF32(-1.08946991f0, 1.31495142f0)
    expected_scaled = ComplexF32(-0.147443712f0, 0.177959323f0)
    expected_scaled_array = ComplexF32[
        -0.147443712f0 + 0.177959323f0im, -0.00600211415f0 - 0.220509455f0im
    ]

    @test bessely(1, z) isa ComplexF32
    @test bessely(1, z, true) isa ComplexF32
    @test isapprox(bessely(1, z), expected; rtol=1e-6, atol=1e-6)
    @test isapprox(bessely(1, z, true), expected_scaled; rtol=1e-6, atol=1e-6)
    @test bessely(1, z_array, true) isa Vector{ComplexF32}
    @test isapprox(bessely(1, z_array, true), expected_scaled_array; rtol=1e-6, atol=1e-6)
end

@testset "AI_bessely_array_scale_broadcast" begin
    # MATLAB source:
    # bessely(1, [1+2i, 2-i, 3+0.5i]), bessely(1, [1+2i, 2-i], 1)
    z = [1.0, 2.0]
    @test isapprox(bessely(1, z, true), bessely.(1, z, true); rtol=1e-13, atol=1e-13)

    complex_view = view(ComplexF64[1 + 2im, 2 - im, 3 + 0.5im], 1:2)
    expected_complex_view = ComplexF64[
        -1.089469855204281 + 1.3149514645322733im,
        -0.016315437820472616 - 0.59940684176685377im,
    ]
    @test isapprox(bessely(1, complex_view), expected_complex_view; rtol=1e-12, atol=1e-12)

    nonstrided = PermutedDimsArray(reshape(ComplexF64[1 + 2im, 2 - im], 1, 2), (2, 1))
    @test isapprox(
        bessely(1, nonstrided), reshape(expected_complex_view, 2, 1); rtol=1e-12, atol=1e-12
    )

    orders = [1, 2]
    @test bessely(orders, 1.0, true) == bessely.(orders, 1.0, true)
    @test bessely(orders, z, true) == bessely.(orders, z, true)
    expected_y1_real = [-0.78121282130028891, -0.10703243154093753]
    @test isapprox(
        2 .* bessely.(1, z) .+ 1, 2 .* expected_y1_real .+ 1; rtol=1e-12, atol=1e-12
    )
end

@testset "AI_bessely_precision_and_dispatch_regression" begin
    expected_float16 = Float16(-0.78121282130028891)
    expected_mixed = -1.089469855204281 + 1.3149514645322733im

    @test bessely(1, Float16(1)) isa Float16
    @test isapprox(bessely(1, Float16(1)), expected_float16; rtol=1e-3, atol=1e-3)
    @test bessely(1, 1.0f0, true) isa Float32
    @test bessely(1, 1.0f0, true) == bessely(1, 1.0f0)
    @test bessely(1, ComplexF16(1, 2)) isa ComplexF16
    @test bessely(1, ComplexF16(1, 2), true) isa ComplexF16
    @test isapprox(bessely(1.0f0, 1.0 + 2.0im), expected_mixed; rtol=1e-12, atol=1e-12)
    @test bessely(2.0, parse(BigFloat, "0.5")) == bessely(2, parse(BigFloat, "0.5"))
    @test bessely(2, parse(BigFloat, "0.5"), true) == bessely(2, parse(BigFloat, "0.5"))
    @test bessely(parse(BigFloat, "2"), 0.5) == bessely(2, 0.5)
    @test bessely(parse(BigFloat, "2"), 1.0 + 2.0im, true) == bessely(2, 1.0 + 2.0im, true)
    @test_throws MethodError bessely(0.5, parse(BigFloat, "0.5"))
    @test_throws MethodError bessely(0.5, Complex{BigFloat}(1, 2))
    @test_throws MethodError bessely(parse(BigFloat, "0.5"), 1.0)
    @test_throws MethodError bessely(parse(BigFloat, "0.5"), 1.0 + 2.0im)
end

@testset "AI_bessely_interface_matrix" begin
    # MATLAB source:
    # bessely(2, 0.5, 1), bessely(2, 1+2i), bessely(2, 1+2i, 1)
    # bessely(single(2), single(0.5)), bessely(single(2), single(1+2i))
    # bessely(single(2), single(1+2i), 1), bessely(0.5, 0.5)
    # bessely(1, 0.5), bessely(2, 1), bessely([1, 2], [0.5, 1], 1)
    # MATLAB has no Float16 or BigFloat; Float16 expectations convert MATLAB single output.
    integer_big = parse(BigFloat, "2")
    noninteger_big = parse(BigFloat, "0.5")
    real32 = Float32(0.5)
    real16 = Float16(0.5)
    complex64 = ComplexF64(1, 2)
    complex32 = ComplexF32(1, 2)
    complex16 = ComplexF16(1, 2)
    expected_real64 = -5.441370837174266
    expected_real32 = Float32(-5.44137096)
    expected_complex64 = -0.75124548726769147 - 0.12395010696911363im
    expected_complex64_scaled = -0.10167002079960014 - 0.016774822833873437im
    expected_complex32 = ComplexF32(-0.751245499, -0.123950109)
    expected_complex32_scaled = ComplexF32(-0.101670019, -0.016774822)
    expected_half_order16 = Float16(-0.9902458802434051)
    expected_nonstrided_scaled = ComplexF64[
        -0.14744371143182275 + 0.17795932889487387im,
        -0.0060021141478628845 - 0.22050945398352931im,
    ]
    expected_generic_complex = ComplexF64[
        -1.089469855204281 + 1.3149514645322733im,
        -0.57374073395963066 - 0.41041309825527816im,
    ]
    expected_generic_real = [-1.4714723926702433, -1.6506826068162548]

    @test isapprox(bessely(integer_big, 0.5, true), expected_real64; rtol=1e-13, atol=1e-13)
    @test isapprox(
        bessely(integer_big, complex64), expected_complex64; rtol=1e-12, atol=1e-12
    )
    @test isapprox(
        bessely(integer_big, complex64, true),
        expected_complex64_scaled;
        rtol=1e-12,
        atol=1e-12,
    )
    @test bessely(integer_big, real32) isa Float32
    @test isapprox(bessely(integer_big, real32), expected_real32; rtol=1e-6, atol=1e-6)
    @test isapprox(
        bessely(integer_big, real32, true), expected_real32; rtol=1e-6, atol=1e-6
    )
    @test bessely(integer_big, real16) isa Float16
    @test isapprox(
        bessely(integer_big, real16), Float16(expected_real32); rtol=1e-3, atol=1e-3
    )
    @test isapprox(
        bessely(integer_big, real16, 1), Float16(expected_real32); rtol=1e-3, atol=1e-3
    )
    @test bessely(integer_big, complex32) isa ComplexF32
    @test isapprox(
        bessely(integer_big, complex32), expected_complex32; rtol=1e-6, atol=1e-6
    )
    @test isapprox(
        bessely(integer_big, complex32, false), expected_complex32; rtol=1e-6, atol=1e-6
    )
    @test bessely(integer_big, complex16) isa ComplexF16
    @test isapprox(
        bessely(integer_big, complex16),
        ComplexF16(expected_complex32);
        rtol=1e-3,
        atol=1e-3,
    )
    @test isapprox(
        bessely(integer_big, complex16, true),
        ComplexF16(expected_complex32_scaled);
        rtol=1e-3,
        atol=1e-3,
    )
    @test_throws MethodError bessely(noninteger_big, complex32)
    @test_throws MethodError bessely(noninteger_big, complex16, true)
    @test_throws MethodError bessely(0.5, Complex{BigFloat}(1, 2), true)

    @test bessely(0.5, real16) isa Float16
    @test isapprox(bessely(0.5, real16), expected_half_order16; rtol=1e-3, atol=1e-3)
    @test isapprox(bessely(0.5, real16, 1), expected_half_order16; rtol=1e-3, atol=1e-3)

    nonstrided = PermutedDimsArray(reshape(ComplexF64[1 + 2im, 2 - im], 1, 2), (2, 1))
    @test isapprox(
        bessely(1, nonstrided, true),
        reshape(expected_nonstrided_scaled, 2, 1);
        rtol=1e-12,
        atol=1e-12,
    )

    orders = [1.0, 2.0]
    values = ComplexF64[1 + 2im, 2 - im]
    @test isapprox(
        bessely(orders, values), expected_generic_complex; rtol=1e-12, atol=1e-12
    )
    @test isapprox(
        bessely([1, 2], [0.5, 1.0], true), expected_generic_real; rtol=1e-13, atol=1e-13
    )
end

@testset "AI_bessely_thread_exception_normalization" begin
    task = @async throw(DomainError(:bessely))
    yield()
    task_error = try
        fetch(task)
        nothing
    catch err
        err
    end
    @test task_error isa TaskFailedException
    @test TyMathCore._bessely_thread_exception(task_error) isa DomainError
    @test TyMathCore._bessely_thread_exception(CompositeException(Any[task_error])) isa
        DomainError

    other_task = @async throw(ArgumentError("other"))
    yield()
    other_error = try
        fetch(other_task)
        nothing
    catch err
        err
    end
    multiple = CompositeException(Any[task_error, other_error])
    @test TyMathCore._bessely_thread_exception(multiple) === multiple
end

@testset "AI_bessely_error_paths" begin
    @test_throws DomainError bessely(Cint(2), -1.0)
    @test_throws DomainError bessely(Cint(2), -1.0f0)
    @test_throws DomainError bessely(0.5, -1.0)
    @test_throws DomainError bessely(2, parse(BigFloat, "-0.789"))
    @test_throws DomainError bessely(2.0, parse(BigFloat, "-0.789"))
    # Complex zero is delegated to AMOS, whose existing contract is input error.
    @test_throws SpecialFunctions.AmosException bessely(1, ComplexF64[0.0 + 0.0im])
    # Keep subnormal inputs on the legacy AMOS path instead of producing NaN in the series.
    @test_throws SpecialFunctions.AmosException bessely(
        1, ComplexF64[ComplexF64(nextfloat(0.0), 0.0)]
    )
    if Threads.nthreads() > 1
        threaded_input = fill(1.0 + 0.0im, 4096)
        threaded_input[1] = 0.0 + 0.0im
        @test_throws SpecialFunctions.AmosException bessely(1, threaded_input)
        @test_throws SpecialFunctions.AmosException bessely(2, threaded_input)
    end
end
