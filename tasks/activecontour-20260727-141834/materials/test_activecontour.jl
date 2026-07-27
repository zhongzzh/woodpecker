using TyImageProcessing, Test

pkg_dir = pkgdir(TyImageProcessing)
source_path = pkg_dir * "/resources/coins.png"

@testset "activecontour" begin
    @testset "src" begin
        I = imread(source_path)
        mask = zeros(size(I))
        mask[25:(end - 25), 25:(end - 25)] .= 1
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
    end

    @testset "A" begin
        I = imread(source_path)
        mask = zeros(size(I))
        mask[25:(end - 25), 25:(end - 25)] .= 1

        I = Float32.(imread(source_path))
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}

        I = Float64.(imread(source_path))
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}

        I = rand(UInt8, size(I))
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}

        I = rand(UInt16, size(I))
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}

        I = rand(Int16, size(I))
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
    end

    @testset "mask" begin
        I = imread(source_path)
        mask = zeros(size(I))
        mask[25:(end - 25), 25:(end - 25)] .= 1
        mask = Bool.(mask)
        bw = activecontour(I, mask)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
    end

    @testset "n" begin
        I = imread(source_path)
        mask = zeros(size(I))
        mask[25:(end - 25), 25:(end - 25)] .= 1
        n = 100
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = UInt8.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = Int8.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = UInt16.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = Int16.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = UInt32.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = Int32.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = UInt64.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        n = Int64.(100)
        bw = activecontour(I, mask, n)
        @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
        # 新增
        # n = 0
        # bw = activecontour(I, mask, n)
        # @test typeof(bw) == BitMatrix || typeof(bw) == Matrix{Bool}
    end
    # 新增
    @testset "performance" begin
        array_3d = rand(Float64, 100, 100)
        mask = zeros(size(array_3d))
        @time activecontour(array_3d, mask)
    end

    @testset "error-throw" begin
        msg_ = "第三个输入，N, 应为正整数。"
        @test_throws msg_ activecontour(rand(5, 5), rand(3, 3), -1)
    end
end
