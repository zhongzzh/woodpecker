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
@testset "VideoWriter 补充" begin
    @testset "frameRate 浮点值与 profile 显式传入" begin
        v_float = VideoWriter("float_rate.avi", [64, 64], 29.97)
        @test v_float.FrameRate == 29.97

        v_mjpeg = VideoWriter("mjpeg_explicit.avi", [32, 32]; profile="Motion JPEG AVI")
        @test v_mjpeg.FileFormat == ".avi"
        @test v_mjpeg.VideoCompressionMethod == "Motion JPEG"
    end

    @testset "frameRate " begin
        v = VideoWriter("myFile", [1 2], 12)
        @test typeof(v) == VideoWriter
        @test v.FrameRate == 12
        v = VideoWriter("myFile", [1 2], 12.5)
        @test typeof(v) == VideoWriter
        @test v.FrameRate == 12.5
    end
    @testset "properties" begin
        v = VideoWriter("myFile", [1 2])
        v.FrameRate = 24
        @test v.FrameRate == 24
        v.FrameRate = 24.5
        @test v.FrameRate == 24.5
        v.Quality = 95
        @test v.Quality == 95
        v.Quality = 0
        @test v.Quality == 0
        v.Quality = 100
        @test v.Quality == 100
    end
end
