using TyImageProcessing, Test

@testset "integralImage3" begin
    @testset "src" begin
        I = reshape(1:125, 5, 5, 5)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64
    end

    @testset "J = integralImage3(I)" begin
        I = rand(Float32, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(Float64, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(Int8, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(Int16, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(Int32, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(UInt8, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(UInt16, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64

        I = rand(UInt32, 2, 3, 4)
        J = integralImage3(I)
        @test size(J) == size(I) .+ 1 && eltype(J) == Float64
    end

    @testset "numeric regression" begin
        I = reshape(1:125, 5, 5, 5)
        J = integralImage3(I)
        expected = zeros(Float64, size(I) .+ 1)
        expected[2:end, 2:end, 2:end] = cumsum(
            cumsum(cumsum(Float64.(I); dims=1); dims=2); dims=3
        )
        @test J == expected

        sR, sC, sP, eR, eC, eP = 2, 2, 2, 4, 4, 4
        regionSum =
            J[eR + 1, eC + 1, eP + 1] - J[eR + 1, eC + 1, sP] - J[eR + 1, sC, eP + 1] -
            J[sR, eC + 1, eP + 1] +
            J[sR, sC, eP + 1] +
            J[sR, eC + 1, sP] +
            J[eR + 1, sC, sP] - J[sR, sC, sP]
        @test regionSum == sum(I[sR:eR, sC:eC, sP:eP])

        M = [1 2; 3 4]
        JM = integralImage3(M)
        @test size(JM) == (3, 3, 2)
        @test JM[:, :, 1] == zeros(3, 3)
        @test JM[:, :, 2] == [0.0 0.0 0.0; 0.0 1.0 3.0; 0.0 4.0 10.0]

        V = [1, 2, 3]
        JV = integralImage3(V)
        @test size(JV) == (4, 2, 2)
        @test JV[:, :, 2] == [0.0 0.0; 0.0 1.0; 0.0 3.0; 0.0 6.0]
    end
end
