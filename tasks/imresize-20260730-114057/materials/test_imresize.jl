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
