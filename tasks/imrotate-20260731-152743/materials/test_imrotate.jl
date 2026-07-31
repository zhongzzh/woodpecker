using TyImageProcessing, Test, TyBaseCore, TyFileIO, TyRandom
using TyPlot, TyPlotTest

pic_dir = joinpath(pkgdir(TyImageProcessing), "test", "resources", "imrotate")
@testset "imrotate" begin
    @testset "灰度图逆时针旋转45°" begin
        refs = [joinpath(pic_dir, "cameraman_clockwise45.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, 45)
            imshow(dst)
        end
    end

    @testset "灰度图顺时针旋转135°" begin
        refs = [joinpath(pic_dir, "cameraman_counter-clockwise135.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, -135)
            imshow(dst)
        end
    end

    @testset "灰度图旋转后裁剪以保持尺寸" begin
        refs = [joinpath(pic_dir, "cameraman_rotate_crop.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, -135, "lanczos", "crop")
            imshow(dst)
        end
    end

    @testset "灰度图双三次插值旋转" begin
        refs = [joinpath(pic_dir, "cameraman_rotate_bicubic.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, 45, "bicubic")
            imshow(dst)
        end
    end

    @testset "灰度图双线性插值旋转" begin
        refs = [joinpath(pic_dir, "cameraman_rotate_bilinear.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, 135, "bilinear")
            imshow(dst)
        end
    end

    @testset "灰度图最近邻插值旋转" begin
        refs = [joinpath(pic_dir, "cameraman_rotate_nearest.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, -45, "nearest")
            imshow(dst)
        end
    end

    @testset "灰度图LANCZOS插值旋转" begin
        refs = [joinpath(pic_dir, "cameraman_rotate_lanczos.png")]
        @test compare_plot(refs) do
            src = imread("cameraman")
            dst = imrotate(src, -135, "lanczos")
            imshow(dst)
        end
    end

    @testset "彩色图逆时针旋转45°" begin
        refs = [joinpath(pic_dir, "coffee_clockwise45.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, 45)
            imshow(dst)
        end
    end

    @testset "彩色图顺时针旋转135°" begin
        refs = [joinpath(pic_dir, "coffee_counter-clockwise135.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, -135)
            imshow(dst)
        end
    end

    @testset "彩色图旋转后裁剪以保持尺寸" begin
        refs = [joinpath(pic_dir, "coffee_rotate_crop.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, 135, "bilinear", "crop")
            imshow(dst)
        end
    end

    @testset "彩色图双三次插值旋转" begin
        refs = [joinpath(pic_dir, "coffee_rotate_bicubic.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, 45, "bicubic")
            imshow(dst)
        end
    end

    @testset "彩色图双线性插值旋转" begin
        refs = [joinpath(pic_dir, "coffee_rotate_bilinear.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, 135, "bilinear")
            imshow(dst)
        end
    end

    @testset "彩色图最近邻插值旋转" begin
        refs = [joinpath(pic_dir, "coffee_rotate_nearest.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, -45, "nearest")
            imshow(dst)
        end
    end

    @testset "彩色图LANCZOS插值旋转" begin
        refs = [joinpath(pic_dir, "coffee_lanc_counter-clockwise135.png")]
        @test compare_plot(refs) do
            src = imread("coffee")
            dst = imrotate(src, -135, "lanczos")
            imshow(dst)
        end
    end

    @testset "I传入 UInt8" begin
        I = [1 2 3 4 5; 6 7 8 9 10]
        I = convert.(UInt8, I)
        J = imrotate(I, -1, "bilinear")
        @test typeof(J) == typeof(I) && typeof(J) == Matrix{UInt8}
    end

    @testset "I传入 UInt16 " begin
        I = [1 2 3 4 5; 6 7 8 9 10]
        I = convert.(UInt16, I)
        J = imrotate(I, -1, "bilinear")
        @test typeof(J) == typeof(I) && typeof(J) == Matrix{UInt16}
    end

    @testset "I传入 Int16 " begin
        I = [1 2 3 4 5; 6 7 8 9 10]
        I = convert.(Int16, I)
        J = imrotate(I, -1, "bilinear")
        @test typeof(J) == typeof(I) && typeof(J) == Matrix{Int16}
    end

    @testset "I传入 Float32 " begin
        I = [1 2 3 4 5; 6 7 8 9 10]
        I = convert.(Float32, I)
        J = imrotate(I, -1, "bilinear")
        @test typeof(J) == typeof(I) && typeof(J) == Matrix{Float32}
    end

    @testset "I传入 Float64 + 大数据测试" begin
        I = randn(Float64, 100, 100)
        J = imrotate(I, -1, "bilinear")
        @test typeof(J) == typeof(I) && typeof(J) == Matrix{Float64}
    end

    # @testset "I为分类数组" begin
    #     A = ["S1"; "S2"; "S1"; "S3"; "S2"]
    #     I = categorical(A)
    #     J = imrotate(I, -20)
    #     @test typeof(J) == typeof(I)
    # end

    pkg_dir = pkgdir(TyImageProcessing)
    source_path = pkg_dir * "/resources/solarspectra_fts_rescale.mat"
    dic = load(source_path)
    I = dic["I"]

    @testset "angle传正负数时，逆/顺时针旋转图像" begin
        refs = [joinpath(pic_dir, "imrotate1_clockwise30.png")]
        @test compare_plot(refs) do
            J = imrotate(I, -30)
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片

        refs = [joinpath(pic_dir, "imrotate1_anticlockwise90.png")]
        @test compare_plot(refs) do
            J = imrotate(I, 90)
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片
    end

    @testset "不同插值方法及比边界框测试" begin
        refs = [joinpath(pic_dir, "imrotate1_nearest.png")]
        @test compare_plot(refs) do
            J = imrotate(I, -20, "nearest")
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片

        refs = [joinpath(pic_dir, "imrotate1_bilinear.png")]
        @test compare_plot(refs) do
            J = imrotate(I, -50, "bilinear")
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片

        refs = [joinpath(pic_dir, "imrotate1_lanczos.png")]
        @test compare_plot(refs) do
            J = imrotate(I, 135, "lanczos")
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片

        refs = [joinpath(pic_dir, "imrotate1_bicubic.png")]
        @test compare_plot(refs) do
            J = imrotate(I, 720, "bicubic")
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片

        refs = [joinpath(pic_dir, "imrotate1_loose.png")]
        @test compare_plot(refs) do
            J = imrotate(I, 720, "nearest", "loose")
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片

        refs = [joinpath(pic_dir, "imrotate1_crop.png")]
        @test compare_plot(refs) do
            J = imrotate(I, -180, "nearest", "crop")
            figure("Rotated Image")
            imshow(J)
        end
        plt_close()#关闭图片
    end

    @testset "compare-results" begin
        # dims == 2
        I = [1 2 3 4 5; 6 7 8 9 10.0]
        res_ = imrotate(I, 68)
        Mres_ = [
            0 0 0 0
            0 0 5 10
            0 3 9 0
            0 2 8 0
            1 6 0 0
            0 0 0 0.0
        ]
        @test res_ ≈ Mres_ rtol = 1e-10

        # dims == 3
        I = [1 2 3; 4 5 6;;; 7 8 9; 10 11 12.0]
        res_ = imrotate(I, 25)
        Mres_ = [0 0 0 0; 0 2 3 0; 0 4 5 0; 0 0 0 0;;; 0 0 0 0; 0 8 9 0; 0 10 11 0; 0 0 0 0]
        @test res_ ≈ Mres_ rtol = 1e-10

        # dims == 4
        rng = MT19937ar(5489)
        A = rand(rng, 2, 2, 3, 2) * 10
        A = round.(A)
        res_ = imrotate(A, 90)
        Mres_ = Array{Float64,4}(undef, 2, 2, 3, 2)
        Mres_[:, :, :, 1] = [1 9; 8 9;;; 3 5; 6 1;;; 2 10; 10 10]
        Mres_[:, :, :, 2] = [8 1; 10 5;;; 8 10; 4 9;;; 8 9; 7 0]
        @test res_ ≈ Mres_ rtol = 1e-10
    end
end
