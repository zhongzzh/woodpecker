using TyImageProcessing, Test
using Random

@testset "locallapfilt" begin
    @testset "identity preserves type and values" begin
        A = reshape(UInt8.(0:47), 4, 4, 3)
        B = locallapfilt(A, 0.4, 1.0)
        @test typeof(B) == typeof(A)
        @test size(B) == size(A)
        @test B == A
        @test B !== A
    end

    @testset "RGB luminance and separate modes" begin
        data = UInt8.(mod.(collect(0:89) .* 3, 256))
        A = reshape(data, 5, 6, 3)

        B = locallapfilt(A, 0.35, 0.6; NumIntensityLevels=6)
        C = locallapfilt(A, 0.35, 0.6; ColorMode=:sep, NumIntensityLevels=6)

        @test typeof(B) == typeof(A)
        @test typeof(C) == typeof(A)
        @test size(B) == size(A)
        @test size(C) == size(A)
    end

    @testset "Float32 grayscale" begin
        A = Float32[(row + 2col) / 32 for row in 1:7, col in 1:9]
        B = locallapfilt(A, 0.2f0, 0.7f0; NumIntensityLevels=8)
        C = locallapfilt(A, 0.2f0, 0.7f0; NumIntensityLevels=1)

        @test typeof(B) == typeof(A)
        @test typeof(C) == typeof(A)
        @test size(B) == size(A)
        @test size(C) == size(A)
        @test all(isfinite, B)
        @test all(isfinite, C)
    end

    @testset "constant images remain constant" begin
        A = fill(UInt16(1200), 6, 6)
        B = locallapfilt(A, 0.25, 0.5)
        @test typeof(B) == typeof(A)
        @test B == A
    end

    @testset "edge-aware denoising improves PSNR" begin
        Random.seed!(1234)
        A = im2single(imread("pout.tif"))
        A_noisy = imnoise(A, "gaussian", 0, 0.001)
        B = locallapfilt(A_noisy, 0.1, 4.0)
        @test psnr(A_noisy, A) < 31
        @test psnr(B, A) > psnr(A_noisy, A)
        @test minimum(B) >= -0.1f0
        @test maximum(B) <= 1.1f0
    end
    @testset "validation" begin
        @test_throws ErrorException locallapfilt(rand(Float64, 4, 4), 0.2, 0.5)
        @test_throws ErrorException locallapfilt(rand(Float32, 4, 4, 2), 0.2, 0.5)
        @test_throws ErrorException locallapfilt(rand(Float32, 4, 4), -0.1, 0.5)
        @test_throws ErrorException locallapfilt(rand(Float32, 4, 4), 0.2, 0.0)
        @test_throws ErrorException locallapfilt(
            rand(Float32, 4, 4), 0.2, 0.5; ColorMode="bad"
        )
        @test_throws ErrorException locallapfilt(
            rand(Float32, 4, 4), 0.2, 0.5; NumIntensityLevels=2.5
        )
    end
end

@testset "locallapfilt 补充" begin
    @testset "Int8 与 Int16 图像" begin
        for T in (Int8, Int16)
            A = T[-3 4; 5 -6; 7 8]
            B = locallapfilt(A, 0.2f0, 0.8f0; NumIntensityLevels=4)
            @test eltype(B) == T
            @test size(B) == size(A)
            @test all(isfinite, Float32.(B))
        end
    end

    @testset "标量参数浮点与整数类型及 beta 显式传入" begin
        A = Float32[(row + col) / 8 for row in 1:6, col in 1:6]
        for T in
            (Float32, Float64, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64)
            sigma = T(1)
            alpha = T(1)
            beta = T(1)
            B = locallapfilt(A, sigma, alpha, beta; NumIntensityLevels=2)
            @test size(B) == size(A)
        end
    end

    @testset "NumIntensityLevels 数据类型与 auto" begin
        A = Float32[(row + 2col) / 16 for row in 1:5, col in 1:7]
        for T in (Float32, Float64, Int8, Int16, Int32, UInt8, UInt16, UInt32, UInt64)
            n = T(2)
            B = locallapfilt(A, 0.2f0, 0.7f0; NumIntensityLevels=n)
            @test size(B) == size(A)
        end
        B_auto = locallapfilt(A, 0.2f0, 0.7f0; NumIntensityLevels="auto")
        @test eltype(B_auto) == Float32
        @test size(B_auto) == size(A)
    end

    @testset "ColorMode 显式字符串" begin
        A = reshape(UInt8.(0:47), 4, 4, 3)
        B_lum = locallapfilt(A, 0.35, 0.6; ColorMode="luminance", NumIntensityLevels=4)
        B_sep = locallapfilt(A, 0.35, 0.6; ColorMode="separate", NumIntensityLevels=4)
        @test eltype(B_lum) == UInt8
        @test eltype(B_sep) == UInt8
        @test size(B_lum) == size(A)
        @test size(B_sep) == size(A)
    end
end
