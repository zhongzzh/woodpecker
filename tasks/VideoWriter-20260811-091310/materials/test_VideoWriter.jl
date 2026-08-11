using TyImageProcessing, Test

@testset "VideoWriter" begin
    @testset "src" begin
        pkg_dir = pkgdir(TyImageProcessing)
        source_path = pkg_dir * "/resources/peppers.png"
        A = imread(source_path)
        v = VideoWriter("myFile", [size(A, 2) size(A, 1)])
        @test typeof(v) == VideoWriter

        pkg_dir = pkgdir(TyImageProcessing)
        source_path = pkg_dir * "/resources/xylophone_video.mp4"
        reader = VideoReader(source_path)
        v = VideoWriter("transcoded_xylophone.avi", [reader.Width reader.Height])
        @test typeof(v) == VideoWriter
    end
    # 新增
    @testset "mp4" begin
        v = VideoWriter("newfile.mp4", [512 384]; profile="MPEG-4")
        @test typeof(v) == VideoWriter

        v = VideoWriter("newfile.mp4", "MPEG-4")
        @test typeof(v) == VideoWriter
        @test v.FileFormat == ".mp4"
        @test (v.Width, v.Height) == (0, 0)
    end

    @testset "frameRate " begin
        v = VideoWriter("myFile", [1 2], 12)
        @test typeof(v) == VideoWriter
    end
end
