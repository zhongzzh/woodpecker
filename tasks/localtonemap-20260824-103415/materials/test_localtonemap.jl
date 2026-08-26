using TyImageProcessing, Test

const _LTM = TyImageProcessing.__Internal__

@testset "localtonemap" begin
    @testset "grayscale and RGB output" begin
        gray = Float32[(row + 2col)^2 / 40 for row in 1:12, col in 1:15]
        rgb = cat(gray, gray .* 0.6f0, gray .* 0.2f0; dims=3)

        grayOutput = localtonemap(gray; RangeCompression=0.2)
        rgbOutput = localtonemap(rgb, "RangeCompression", 0.2, "EnhanceContrast", 0.5)

        @test typeof(grayOutput) == typeof(gray)
        @test typeof(rgbOutput) == typeof(rgb)
        @test size(grayOutput) == size(gray)
        @test size(rgbOutput) == size(rgb)
        @test all(isfinite, grayOutput)
        @test all(isfinite, rgbOutput)
        @test all(value -> 0 <= value <= 1, grayOutput)
        @test all(value -> 0 <= value <= 1, rgbOutput)
        @test sum(Float64, rgbOutput) / length(rgbOutput) ≈ 0.482862353 atol = 3e-7
        @test vec(rgbOutput[4, 7, :]) ≈ Float32[0.537121177, 0.425825804, 0.258439362] atol =
            2.0f-6
    end

    @testset "calling forms and special dynamic ranges" begin
        HDR = reshape(Float32.(1:120) ./ 30, 10, 12)
        keyword = localtonemap(HDR; RangeCompression=0.1, EnhanceContrast=0.4)
        positional = localtonemap(HDR, :Range, 0.1, "Enhance", 0.4)
        @test keyword ≈ positional rtol = 1.0f-6 atol = 1.0f-6

        constantHDR = fill(2.0f0, 8, 9, 3)
        @test localtonemap(constantHDR) === constantHDR

        nonfiniteHDR = copy(HDR)
        nonfiniteHDR[1] = Inf32
        @test all(isnan, localtonemap(nonfiniteHDR))
    end

    @testset "percentiles match MATLAB interpolation" begin
        values = reshape(Float32.(1:200), 10, 20)
        low, high = _LTM._localtonemap_percentiles(values)
        @test low == 1.5f0
        @test high == 199.5f0

        sameLow, sameHigh = _LTM._localtonemap_percentiles(fill(3.0f0, 4, 4))
        @test sameLow == 3.0f0
        @test sameHigh == 3.0f0
        nanLow, nanHigh = _LTM._localtonemap_percentiles(fill(NaN32, 2, 2))
        @test isnan(nanLow)
        @test isnan(nanHigh)
    end

    @testset "validation" begin
        HDR = ones(Float32, 8, 8)
        @test_throws ErrorException localtonemap()
        @test_throws ErrorException localtonemap(HDR, "RangeCompression")
        @test_throws ErrorException localtonemap(
            HDR, "RangeCompression", 0.2, "EnhanceContrast", 0.3, "extra", 1
        )
        @test_throws ErrorException localtonemap(HDR, "Unknown", 0.2)
        @test_throws ErrorException localtonemap(HDR, 1, 0.2)
        @test_throws ErrorException localtonemap(ones(Float64, 8, 8))
        @test_throws ErrorException localtonemap(Float32[])
        @test_throws ErrorException localtonemap(ones(Float32, 4, 4, 2))
        @test_throws ErrorException localtonemap(fill(-1.0f0, 4, 4))
        @test_throws ErrorException localtonemap(HDR; RangeCompression=-0.1)
        @test_throws ErrorException localtonemap(HDR; RangeCompression=1.1)
        @test_throws ErrorException localtonemap(HDR; RangeCompression=NaN)
        @test_throws ErrorException localtonemap(HDR; EnhanceContrast=true)
        @test_throws ErrorException localtonemap(HDR; EnhanceContrast=[0.1, 0.2])
    end
end
