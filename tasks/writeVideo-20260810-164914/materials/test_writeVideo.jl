using TyImageProcessing, Test

@testset "writeVideo" begin
    @testset "src" begin
        pkg_dir = pkgdir(TyImageProcessing)
        source_path = pkg_dir * "/resources/peppers.png"
        A = imread(source_path)
        v = VideoWriter("myFile", [size(A, 2) size(A, 1)])
        open(v)
        writeVideo(v, A)
        @test v.FrameCount != 0

        pkg_dir = pkgdir(TyImageProcessing)
        source_path = pkg_dir * "/resources/xylophone_video.mp4"
        reader = VideoReader(source_path)
        writer = VideoWriter("transcoded_xylophone.avi", [reader.Width reader.Height])
        writer.FrameRate = reader.FrameRate
        open(writer)
        while hasFrame(reader)
            local img = readFrame(reader)
            writeVideo(writer, img)
        end
        @test writer.FrameCount != 0
    end
    # 新增
    @testset "img" begin
        A = Float32.(rand(100, 100))
        v = VideoWriter("myFile", [100 100])
        open(v)
        writeVideo(v, A)

        # A = Int16.(rand( 100, 100));
        # v = VideoWriter("myFile",[100 100]);
        # open(v)
        # writeVideo(v, A);
    end
    @testset "infer frame size" begin
        output = tempname() * ".mp4"
        try
            v = VideoWriter(output, "MPEG-4")
            open(v)
            writeVideo(v, rand(200, 200))
            close(v)

            @test (v.Width, v.Height) == (200, 200)
            @test v.FrameCount == 1
            @test v.Duration == 1 / v.FrameRate
            @test isfile(output)
            @test filesize(output) > 0
        finally
            rm(output; force=true)
        end
    end
    # 新增
    @testset "performance" begin
        A = Float32.(rand(0:1, 100, 100))
        v = VideoWriter("myFile", [100 100])
        open(v)
        @time writeVideo(v, A)
    end
end
