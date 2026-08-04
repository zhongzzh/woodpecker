using TyPlot, TyImageProcessing, Test
using TyPlotTest

@testset "imtophat" begin
    pkg_dir = pkgdir(TyImageProcessing)
    pic_dir = joinpath(pkg_dir, "test", "resources", "imtophat")
    @testset "灰度图像顶帽滤波" begin
        refs = [joinpath(pic_dir, "imtophat_rice.png")]
        source_path = pkg_dir * "/resources/rice.png"
        src = imread(source_path)
        @test compare_plot(refs) do
            kernel = strel("disk", 12)
            dst = imtophat(src, kernel)
            imshow(dst)
        end
    end

    #新增(缺少比较@teset待补充)
    @testset "大数据" begin
        I1 = rand(100, 100) * 100
        I2 = rand(Bool, 100, 100)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (100, 100)
    end

    @testset "向量-矩阵" begin
        I1 = rand(10000, 1) * 100
        I2 = rand(Bool, 10000, 1)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (10000, 1)
    end

    @testset "向量-向量" begin
        I1 = rand(1, 10000) * 100
        I2 = rand(Bool, 1, 10000)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (1, 10000)
    end

    @testset "维度不同" begin
        I1 = rand(1, 10000) * 100
        I2 = rand(Bool, 1, 100)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (1, 10000)

        I1 = rand(1, 10000) * 100
        I2 = rand(Bool, 100, 1)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (1, 10000)

        I1 = rand(1, 10000) * 100
        I2 = rand(Bool, 1, 1)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (1, 10000)

        I1 = rand(1, 100) * 100
        I2 = rand(Bool, 100, 10)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (1, 100)
    end

    @testset "不同类型" begin
        I1 = rand(UInt8, 5, 4)
        I2 = rand(Bool, 5, 4)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == UInt8 && size(r1) == (5, 4)

        I1 = rand(UInt16, 5, 4)
        I2 = rand(Bool, 5, 4)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == UInt16 && size(r1) == (5, 4)

        I1 = rand(Int16, 5, 4)
        I2 = rand(Bool, 5, 4)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Int16 && size(r1) == (5, 4)

        I1 = rand(Float32, 5, 4)
        I2 = rand(Bool, 5, 4)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float32 && size(r1) == (5, 4)

        I1 = rand(Float64, 5, 4)
        I2 = rand(Bool, 5, 4)
        r1 = imtophat(I1, I2)
        @test eltype(r1) == Float64 && size(r1) == (5, 4)
    end
end
