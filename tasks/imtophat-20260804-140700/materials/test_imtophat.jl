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


@testset "imtophat Bool 二值图像输入" begin
    image_bool = falses(5, 5)
    image_bool[3, 3] = true

    se_bool = Bool[
        0 1 0
        1 1 1
        0 1 0
    ]

    result_bool = imtophat(image_bool, se_bool)

    @test eltype(result_bool) == Bool
    @test size(result_bool) == size(image_bool)
    @test result_bool isa AbstractMatrix{Bool}
end

@testset "imtophat UInt8 数值结构元素" begin
    image_uint8 = zeros(UInt8, 7, 7)
    image_uint8[2, 2] = 0x09
    image_uint8[4, 5] = 0x07
    image_uint8[5, 4] = 0x07
    image_uint8[5, 5] = 0x07
    image_uint8[5, 6] = 0x07
    image_uint8[6, 5] = 0x07

    se_uint8 = UInt8[
        0 1 0
        1 1 1
        0 1 0
    ]

    result_uint8_se = imtophat(image_uint8, se_uint8)

    expected = zeros(UInt8, 7, 7)
    expected[2, 2] = 0x09

    @test eltype(se_uint8) == UInt8
    @test result_uint8_se isa AbstractMatrix{UInt8}
    @test size(result_uint8_se) == size(image_uint8)
    @test result_uint8_se == expected
    @test result_uint8_se == imtophat(image_uint8, Bool.(se_uint8))
end