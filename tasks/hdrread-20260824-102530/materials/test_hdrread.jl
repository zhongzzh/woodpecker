using TyImageProcessing, Test

@testset "hdrread" begin
    @testset "compressed Radiance image" begin
        HDR = hdrread("office.hdr")
        @test typeof(HDR) == Array{Float32,3}
        @test size(HDR) == (665, 1000, 3)
        @test extrema(HDR) == (0.0f0, 3.28125f0)
        @test vec(HDR[1, 1, :]) == Float32[0.105957031, 0.0219726562, 0.0029296875]
    end

    @testset "uncompressed RGBE image" begin
        mktemp() do path, io
            write(io, "#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y 1 +X 2\n")
            write(io, UInt8[0x80, 0x40, 0x20, 0x81, 0x00, 0x00, 0x00, 0x00])
            close(io)

            HDR = hdrread(path)
            @test size(HDR) == (1, 2, 3)
            @test vec(HDR[1, 1, :]) == Float32[1, 0.5, 0.25]
            @test all(iszero, HDR[1, 2, :])
        end
    end

    @testset "validation and malformed files" begin
        @test_throws ErrorException hdrread()
        @test_throws ErrorException hdrread("a.hdr", "b.hdr")
        @test_throws ErrorException hdrread(1)
        @test_throws ErrorException hdrread("missing_hdrread_file.hdr")

        mktemp() do path, io
            write(io, "not a Radiance image")
            close(io)
            @test_throws ErrorException hdrread(path)
        end
        mktemp() do path, io
            write(io, "#?OTHER\n\n-Y 1 +X 1\n")
            close(io)
            @test_throws ErrorException hdrread(path)
        end
        mktemp() do path, io
            write(io, "#?RADIANCE\n\n-Y 1 +X 1\n")
            write(io, UInt8[0x01, 0x01, 0x01, 0x01])
            close(io)
            @test_throws ErrorException hdrread(path)
        end
        mktemp() do path, io
            write(io, "#?RADIANCE\n\n-Y 1 +X 8\n")
            write(io, UInt8[0x02, 0x02, 0x00, 0x07])
            close(io)
            @test_throws ErrorException hdrread(path)
        end
    end
end
