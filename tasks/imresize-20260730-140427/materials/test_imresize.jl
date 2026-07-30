using TyImageProcessing, Test
@testset "imresize" begin
    #gray img
    @testset "size" begin
        # scale to resize
        img = rand(UInt8, 20, 30)
        _scale = 0.5
        new_img = imresize(img, _scale)
        @test size(new_img) == ceil.(Int, size(img) .* _scale)

        # fixed size to resize
        img = rand(UInt8, 20, 30)
        _sz = [12, 20]
        new_img = imresize(img, _sz)
        @test size(new_img) == (12, 20)

        # using interpolation method: nearest
        img = imread("cameraman")
        rimg = imresize(img, 0.3; method="nearest")
        @test size(rimg) == ceil.(Int, size(img) .* 0.3)

        # using interpolation method: bicubic
        rimg = imresize(img, 0.3; method="bicubic")
        @test size(rimg) == ceil.(Int, size(img) .* 0.3)

        # using interpolation method: area
        rimg = imresize(img, 0.3; method="area")
        @test size(rimg) == ceil.(Int, size(img) .* 0.3)

        # using interpolation method: bilinear
        rimg = imresize(img, 0.3; method="bilinear")
        @test size(rimg) == ceil.(Int, size(img) .* 0.3)

        # using interpolation method: lanczos
        rimg = imresize(img, 0.3; method="lanczos")
        @test size(rimg) == ceil.(Int, size(img) .* 0.3)
    end

    #color img
    @testset "method" begin
        # scale to resize
        img = rand(UInt8, 20, 30, 3)
        _scale = 0.5
        new_img = imresize(img, _scale)
        @test size(new_img) == (10, 15, 3)

        # fixed size to resize
        img = rand(UInt8, 20, 30, 3)
        _sz = [12, 20]
        new_img = imresize(img, _sz)
        @test size(new_img) == (12, 20, 3)

        # using interpolation method: nearest
        img = imread("coffee")
        rimg = imresize(img, 0.3; method="nearest")
        @test size(rimg) == (120, 180, 3)

        # using interpolation method: bicubic
        rimg = imresize(img, 0.3; method="bicubic")
        @test size(rimg) == (120, 180, 3)

        # using interpolation method: area
        rimg = imresize(img, 0.3; method="area")
        @test size(rimg) == (120, 180, 3)

        # using interpolation method: bilinear
        rimg = imresize(img, 0.3; method="bilinear")
        @test size(rimg) == (120, 180, 3)

        # using interpolation method: lanczos
        rimg = imresize(img, 0.3; method="lanczos")
        @test size(rimg) == (120, 180, 3)
    end
end

@testset "imresize 补充覆盖" begin
    @testset "A 数据类型" begin
        # UInt16 灰度图像
        img_uint16 = rand(UInt16, 20, 30)
        resized_uint16 = imresize(img_uint16, 0.5)
        @test eltype(resized_uint16) == UInt16
        @test size(resized_uint16) == ceil.(Int, size(img_uint16) .* 0.5)

        # Int16 灰度图像
        img_int16 = rand(Int16, 20, 30)
        resized_int16 = imresize(img_int16, 0.5)
        @test eltype(resized_int16) == Int16
        @test size(resized_int16) == ceil.(Int, size(img_int16) .* 0.5)

        # Float32 灰度图像
        img_float32 = rand(Float32, 20, 30)
        resized_float32 = imresize(img_float32, 0.5)
        @test eltype(resized_float32) == Float32
        @test size(resized_float32) == ceil.(Int, size(img_float32) .* 0.5)

        # Float64 灰度图像
        img_float64 = rand(Float64, 20, 30)
        resized_float64 = imresize(img_float64, 0.5)
        @test eltype(resized_float64) == Float64
        @test size(resized_float64) == ceil.(Int, size(img_float64) .* 0.5)

        # Bool 二值图像
        img_bool = rand(Bool, 20, 30)
        resized_bool = imresize(img_bool, 0.5)
        @test eltype(resized_bool) == Bool
        @test size(resized_bool) == ceil.(Int, size(img_bool) .* 0.5)

        # Float32 彩色图像
        img_float32_3d = rand(Float32, 20, 30, 3)
        resized_float32_3d = imresize(img_float32_3d, 0.5)
        @test eltype(resized_float32_3d) == Float32
        @test size(resized_float32_3d) == (ceil(Int, 20 * 0.5), ceil(Int, 30 * 0.5), 3)
    end
end
