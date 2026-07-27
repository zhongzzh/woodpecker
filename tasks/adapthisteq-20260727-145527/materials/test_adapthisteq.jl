using TyPlot, TyImageProcessing, Test, TyPlotTest, TyBaseCore

@testset "adapthisteq" begin
    pkg_dir = pkgdir(TyImageProcessing)
    source_path = pkg_dir * "/resources/tire.tif"
    src = imread(source_path)
    pic_dir = joinpath(pkg_dir, "test", "resources", "adapthisteq")

    @testset "默认参数" begin
        refs = [joinpath(pic_dir, "tire_dft.png")]
        @test compare_plot(refs) do
            dst = adapthisteq(src)
            imshow(dst)
        end
    end

    @testset "limit=0.05,tiles[8,8]" begin
        refs = [joinpath(pic_dir, "tire_0.05.png")]
        @test compare_plot(refs) do
            dst = adapthisteq(src; NumTiles=[16, 8], ClipLimit=0.05)
            imshow(dst)
        end
    end

    #新增(缺少比较@teset待补充)
    @testset "Int16" begin
        src = Int16.(src)
        dst1 = adapthisteq(src)
        dst2 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{Int16} && typeof(dst2) == Matrix{Int16}
    end

    #新增(缺少比较@teset待补充)
    @testset "uint8" begin
        src = imread(source_path)
        src = UInt8.(src)
        dst1 = adapthisteq(src)
        dst2 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{UInt8} && typeof(dst2) == Matrix{UInt8}
    end

    #新增(缺少比较@teset待补充)
    @testset "UInt16" begin
        src = imread(source_path)
        src = UInt16.(src)
        dst1 = adapthisteq(src)
        dst2 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{UInt16} && typeof(dst2) == Matrix{UInt16}
    end

    #新增(缺少比较@teset待补充)
    @testset "Float32" begin
        src = imread(source_path)
        src = Float32.(src)
        dst1 = adapthisteq(src)
        dst2 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{Float32} && typeof(dst2) == Matrix{Float32}
    end

    #新增(缺少比较@teset待补充)
    @testset "Float64" begin
        src = imread(source_path)
        src = Float64.(src)
        dst1 = adapthisteq(src)
        dst2 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{Float64} && typeof(dst2) == Matrix{Float64}
    end

    #新增(缺少比较@teset待补充)
    @testset "NumTiles" begin
        src = imread(source_path)
        # dst1 = adapthisteq(src;NumTiles = [1,8], ClipLimit=0.05)
        # dst1 = adapthisteq(src;NumTiles = [2,1], ClipLimit=0.05)
        dst1 = adapthisteq(src; NumTiles=[2, 2], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{UInt8}
        dst1 = adapthisteq(src; NumTiles=[300, 20], ClipLimit=0.05)
        # dst1 = adapthisteq(src;NumTiles = [2.5,2], ClipLimit=0.05)
        # dst1 = adapthisteq(src;NumTiles = [-10,2], ClipLimit=0.05)
        @test typeof(dst1) == Matrix{UInt8}
    end

    #新增(缺少比较@teset待补充)
    @testset "ClipLimit" begin
        src = imread(source_path)
        dst1 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0)
        @test typeof(dst1) == Matrix{UInt8}
        dst1 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=1)
        @test typeof(dst1) == Matrix{UInt8}
        # dst1 = adapthisteq(src;NumTiles = [8,8], ClipLimit=2)
        # dst1 = adapthisteq(src;NumTiles = [8,8], ClipLimit=-1)
        dst1 = adapthisteq(src; NumTiles=[8, 8], ClipLimit=0.123456)
        @test typeof(dst1) == Matrix{UInt8}
    end

    @testset "error-throw" begin
        error_msg = "输入图块数量，必须为二元素向量"
        @test_throws error_msg adapthisteq(rand(5, 5), NumTiles=[1, 2, 4])

        error_msg = "输入对比度增强限制系数，必须在0~1之间"
        @test_throws error_msg adapthisteq(rand(5, 5), ClipLimit=1.2)
        @test_throws error_msg adapthisteq(rand(5, 5), ClipLimit=-1.3)

        error_msg = "输入图块数量的两个元素，必须为>=2的正整数。"
        @test_throws error_msg adapthisteq(rand(5, 5), NumTiles=[1, 2])
        @test_throws error_msg adapthisteq(rand(5, 5), NumTiles=[3, -1])

        error_msg = "输入图块数量的两个元素，必须为正整数。"
        @test_throws error_msg adapthisteq(rand(5, 5), NumTiles=[2.2, 2])
        @test_throws error_msg adapthisteq(rand(5, 5), NumTiles=[3, 4.1])
    end
end
