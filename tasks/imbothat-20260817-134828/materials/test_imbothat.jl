using TyImageProcessing, Test

@testset "imbothat" begin
    pit = fill(UInt8(9), 5, 5)
    pit[3, 3] = 1
    expected_pit = zeros(UInt8, 5, 5)
    expected_pit[3, 3] = 8

    @testset "square and diamond neighborhoods" begin
        @test imbothat(pit, trues(3, 3)) == expected_pit
        @test imbothat(pit, Bool[0 1 0; 1 1 1; 0 1 0]) == expected_pit

        valley = UInt8[
            8 8 8 8 8
            8 4 4 4 8
            8 4 1 4 8
            8 4 4 4 8
            8 8 8 8 8
        ]
        @test imbothat(valley, trues(3, 3)) == UInt8[
            0 0 0 0 0
            0 0 0 0 0
            0 0 3 0 0
            0 0 0 0 0
            0 0 0 0 0
        ]
        @test imbothat(fill(3.5f0, 4, 4), trues(3, 3)) == zeros(Float32, 4, 4)
    end

    @testset "generic, asymmetric, and vector neighborhoods" begin
        image = UInt8[
            9 9 9 9
            9 2 6 9
            9 7 8 9
            9 9 9 9
        ]
        asymmetric = Bool[1 1 0; 0 1 0]
        result = imbothat(image, asymmetric)
        @test result == UInt8[
            0 0 0 0
            0 6 3 0
            0 1 0 0
            0 0 0 0
        ]

        row_signal = reshape(UInt8[6, 6, 1, 6, 6], 1, :)
        expected = reshape(UInt8[0, 0, 5, 0, 0], 1, :)
        @test imbothat(row_signal, Bool[1, 1, 1]) == expected
        @test imbothat(row_signal, reshape(Bool[1, 1, 1], 1, :)) == expected
    end

    @testset "boolean and numeric element types" begin
        boolean_pit = pit .!= 1
        expected_boolean = falses(5, 5)
        expected_boolean[3, 3] = true
        @test imbothat(boolean_pit, trues(3, 3)) == expected_boolean
        @test eltype(imbothat(boolean_pit, trues(3, 3))) == Bool

        for T in (UInt16, Int16, Float32, Float64)
            input = T.(pit)
            result = imbothat(input, trues(3, 3))
            @test result == T.(expected_pit)
            @test eltype(result) == T
        end
    end

    @testset "three-dimensional input" begin
        volume = cat(pit, UInt8(2) .* pit, UInt8(3) .* pit; dims=3)
        expected = cat(
            expected_pit, UInt8(2) .* expected_pit, UInt8(3) .* expected_pit; dims=3
        )
        @test imbothat(volume, trues(3, 3)) == expected

        kernels = cat(trues(3, 3), Bool[0 1 0; 1 1 1; 0 1 0], trues(3, 3); dims=3)
        @test imbothat(volume, kernels) == expected
    end

    @testset "edge cases and invalid neighborhoods" begin
        @test imbothat(pit, trues(1, 1)) == zeros(UInt8, 5, 5)
        empty_result = fill(UInt8(246), 5, 5)
        empty_result[3, 3] = 254
        @test imbothat(pit, falses(2, 2)) == empty_result

        @test_throws ErrorException imbothat(pit, [0 2; 1 0])
        @test_throws ErrorException imbothat(reshape(pit, 5, 5, 1), zeros(Int, 2, 2, 2, 1))
        @test_throws MethodError imbothat(pit, ones(Float64, 3, 3))
    end
end
