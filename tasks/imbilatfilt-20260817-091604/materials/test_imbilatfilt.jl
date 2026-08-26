using TyImageProcessing
using Test

const TIPInternal = TyImageProcessing.__Internal__

@testset "imbilatfilt" begin
    @testset "public overloads and grayscale behavior" begin
        constant_u8 = fill(UInt8(73), 7, 8)
        # MATLAB's UInt8 path truncates after adding eps to the denominator.
        expected_constant = fill(UInt8(72), size(constant_u8))
        @test imbilatfilt(constant_u8) == expected_constant
        @test imbilatfilt(constant_u8, 25) == expected_constant
        @test imbilatfilt(constant_u8, 25, 0.6) == expected_constant
        @test imbilatfilt(constant_u8, 25, 0.6, 3.0) == expected_constant

        impulse = zeros(UInt8, 7, 7)
        impulse[4, 4] = 100
        filtered = imbilatfilt(impulse, 10_000, 1, 5)
        @test filtered[4, 4] < impulse[4, 4]
        @test filtered[4, 4] > filtered[4, 3] > filtered[4, 2]
        @test filtered == reverse(filtered; dims=1)
        @test filtered == reverse(filtered; dims=2)

        edge = hcat(fill(UInt8(0), 7, 4), fill(UInt8(255), 7, 4))
        preserved = imbilatfilt(edge, 1, 1, 5)
        smoothed = imbilatfilt(edge, 100_000, 1, 5)
        @test all(iszero, preserved[:, 1:4])
        @test all(x -> x >= 254, preserved[:, 5:8])
        @test smoothed[4, 4] > 0
        @test smoothed[4, 5] < 255
    end

    @testset "element types and implementation paths" begin
        base = reshape(collect(1:56), 7, 8)
        fixtures = (
            Int8.(base .- 29),
            UInt16.(base .* 1000),
            Int16.(base .* 500 .- 14_000),
            UInt32.(base .* 100_000),
            Int32.(base .* 100_000 .- 2_900_000),
            Float32.(base ./ 56),
            Float64.(base ./ 56),
        )
        for input in fixtures
            result = imbilatfilt(input, 10_000, 0.8, 3)
            @test size(result) == size(input)
            @test eltype(result) === eltype(input)
            @test all(minimum(input) .<= result .<= maximum(input))
        end

        # Exercise the specialized UInt16 5-by-5 path with both its sparse
        # candidate optimization and the all-candidates branch.
        u16 = UInt16.(base .* 1000)
        @test imbilatfilt(u16, 4_000_000, 1, 5) != u16
        @test imbilatfilt(u16, 1.0e12, 1, 5) != u16

        # A small smoothing variance makes distant UInt16 values exact identities.
        separated = reshape(UInt16.(0:5000:35000), 4, 2)
        separated = repeat(separated, 2, 4)[1:7, 1:8]
        @test imbilatfilt(separated, 1, 1, 5) == separated
    end

    @testset "RGB filtering" begin
        rgb_u8 = fill(UInt8(20), 7, 8, 3)
        rgb_u8[4, 4, :] .= UInt8[100, 120, 140]
        filtered_u8 = imbilatfilt(rgb_u8, 20_000, 1, 5)
        @test size(filtered_u8) == size(rgb_u8)
        @test eltype(filtered_u8) === UInt8
        @test all(filtered_u8[4, 4, :] .< rgb_u8[4, 4, :])
        @test all(filtered_u8[4, 4, :] .> filtered_u8[4, 3, :])

        rgb_f32 = Float32.(rgb_u8) ./ 255
        filtered_f32 = imbilatfilt(rgb_f32, 0.5, 0.8, 3)
        @test eltype(filtered_f32) === Float32
        @test all(isfinite, filtered_f32)
        @test filtered_f32 != rgb_f32

        rgb_constant = fill(Int16(-123), 7, 8, 3)
        @test imbilatfilt(rgb_constant, 50, 1, 5) == rgb_constant
    end

    @testset "replicate padding and helpers" begin
        corner = zeros(Float64, 7, 7)
        corner[1, 1] = 1
        result = imbilatfilt(corner, 100, 1, 3)
        @test result[1, 1] > result[1, 2] > result[1, 3]
        @test result[1, 2] == result[2, 1]
        @test result[7, 7] == 0

        weights = TIPInternal._imbilat_spatial_weights(5, 1.0)
        @test size(weights) == (5, 5)
        @test sum(weights) ≈ 1
        @test weights[3, 3] == maximum(weights)
        @test weights == reverse(weights; dims=1) == reverse(weights; dims=2)
        @test TIPInternal._imbilat_cast(UInt8, -1.0) == 0
        @test TIPInternal._imbilat_cast(UInt8, 256.0) == 255
        @test TIPInternal._imbilat_cast(Int16, 1.5) == 2
        @test TIPInternal._imbilat_cast(Float32, 0.25) === 0.25f0
    end

    @testset "validation" begin
        valid = zeros(UInt8, 7, 8)
        for smoothing in (0, -1, Inf, NaN)
            @test_throws ErrorException imbilatfilt(valid, smoothing)
        end
        for sigma in (0, -1, Inf, NaN)
            @test_throws ErrorException imbilatfilt(valid, 1, sigma)
        end
        for neighborhood in (0, -1, Inf, NaN)
            @test_throws ErrorException imbilatfilt(valid, 1, 1, neighborhood)
        end
        @test_throws ErrorException imbilatfilt(valid, 1, 1, 3.5)
        @test_throws ErrorException imbilatfilt(valid, 1, 1, 4)
        @test_throws ErrorException imbilatfilt(valid, 1, 1, 9)
        @test_throws ErrorException imbilatfilt(zeros(UInt8, 0, 7), 1, 1, 1)
        @test_throws ErrorException imbilatfilt(zeros(UInt8, 7), 1, 1, 1)
        @test_throws ErrorException imbilatfilt(zeros(UInt8, 7, 8, 2), 1, 1, 1)
        @test_throws MethodError imbilatfilt(falses(7, 8), 1)
    end

    @testset "threaded large-input branches" begin
        # With multiple Julia threads these cross the implementation's threshold;
        # with one thread they remain inexpensive deterministic regression tests.
        large_u8 = fill(UInt8(91), 256, 256)
        large_u16 = fill(UInt16(12_345), 256, 256)
        large_f32 = fill(Float32(0.25), 256, 256)
        large_rgb = fill(UInt8(42), 256, 256, 3)
        @test imbilatfilt(large_u8, 100, 1, 5) == large_u8
        @test imbilatfilt(large_u16, 4_000_000, 1, 5) == large_u16
        @test imbilatfilt(large_f32, 0.1, 0.6, 3) == large_f32
        @test imbilatfilt(large_rgb, 100, 0.6, 3) == fill(UInt8(41), size(large_rgb))
    end
end
