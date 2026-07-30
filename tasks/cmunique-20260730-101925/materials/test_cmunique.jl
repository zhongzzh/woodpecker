using TyImageProcessing, TyI18N
using Test
using TyPlot

@testset "cmunique" begin
    @testset "1_Y,newmap = cmunique(X,map)" begin
        @testset "输入参数 X 类型为 Float64 ，newmap 长度大于256" begin
            X = [16 2 3 13; 5 11 10 8; 9 7 6 12; 4 14 15 1.0]
            map = [gray(8); gray(8)]
            Y, newmap = cmunique(X, map)
            @test size(Y) == size(X) && size(Y) == (4, 4)
            @test typeof(Y) == Matrix{UInt8}
            @test size(newmap) == (8, 3)
            @test typeof(newmap) == Matrix{Float64}
        end

        @testset "输入参数 X 类型为 UInt8 " begin
            X = UInt8[16 2 3 13; 5 11 10 8; 9 7 6 12; 4 14 15 1]
            map = [gray(10); gray(10)]
            Y, newmap = cmunique(X, map)
            @test size(Y) == size(X) && size(Y) == (4, 4)
            @test typeof(Y) == Matrix{UInt8}
            @test size(newmap) == (10, 3)
            @test typeof(newmap) == Matrix{Float64}
        end

        @testset "输入参数 X 类型为 UInt16 ,newmap 长度大于256，大数据测试" begin
            # UInt16 indexed images use zero-based colormap indices, as in MATLAB.
            X = rand(0:19999, 100, 100)
            X = UInt16.(X)
            map = [gray(10000); gray(10000)]
            Y, newmap = cmunique(X, map)
            @test size(Y) == size(X) && size(Y) == (100, 100)
            @test typeof(Y) == Matrix{Float64}
            @test size(newmap, 2) == 3
            @test typeof(newmap) == Matrix{Float64}
        end

        @testset "输入参数 X 类型为 UInt16 , newmap 长度大于256" begin
            # Reference every colormap entry so cmunique must retain all 257 colors.
            X = reshape(UInt16.(0:256), 257, 1)
            values = collect(0.0:256.0) ./ 256
            map = hcat(values, zeros(257), zeros(257))
            Y, newmap = cmunique(X, map)
            @test size(Y) == size(X) && size(Y) == (257, 1)
            @test typeof(Y) == Matrix{Float64}
            @test size(newmap) == size(map) && size(newmap) == (257, 3)
            @test typeof(newmap) == Matrix{Float64}
        end
    end

    @testset "2_Y,newmap = cmunique(RGB)" begin
        @testset "输入参数 RGB 类型为 Float64 " begin
            A = [1 2 3 4; 3 1 100 5; 2 2 2 2]
            A = cat(A, [10 11 12 13; 13 14 15 16; 16 17 18 19]; dims=3)
            RGB = cat(A, [10 11 12 13; 13 14 15 16; 16 17 18 19]; dims=3)
            Y, newmap = cmunique(RGB)
            @test size(Y) == (3, 4)
            @test typeof(Y) == Matrix{UInt8}
            @test size(newmap, 2) == 3
            @test typeof(newmap) == Matrix{Float64}
        end

        @testset "输入参数 RGB 类型为 Float64 " begin
            A = [1 2 3; 3 1 100; 2 2 2]
            A = cat(A, [10 11 12; 13 14 15; 16 17 18]; dims=3)
            RGB = cat(A, [10 11 12; 13 14 15; 16 17 18]; dims=3)
            RGB = convert.(UInt8, RGB)
            Y, newmap = cmunique(RGB)
            @test size(Y) == (3, 3)
            @test typeof(Y) == Matrix{UInt8}
            @test size(newmap, 2) == 3
            @test typeof(newmap) == Matrix{Float64}
        end

        @testset "输入参数 RGB 类型为 UInt16 " begin
            A = [1 2 3; 3 1 100; 2 2 2]
            A = cat(A, [10 11 12; 13 14 15; 16 17 18]; dims=3)
            RGB = cat(A, [10 11 12; 13 14 15; 16 17 18]; dims=3)
            RGB = convert.(UInt16, RGB)
            Y, newmap = cmunique(RGB)
            @test size(Y) == (3, 3)
            @test typeof(Y) == Matrix{UInt8}
            @test size(newmap, 2) == 3
            @test typeof(newmap) == Matrix{Float64}
        end
    end

    @testset "3_Y,newmap = cmunique(I)" begin
        @testset "输入参数 I 类型为 Float64 " begin
            I = rand(Float64, 3, 7)
            Y, newmap = cmunique(I)
            @test size(Y) == (3, 7)
            @test typeof(Y) == Matrix{UInt8}
            @test size(newmap, 2) == 3
            @test typeof(newmap) == Matrix{Float64}
        end

        @testset "输入参数 I 类型为 UInt16  " begin
            I = rand(UInt16, 1000, 1500)
            Y, newmap = cmunique(I)
            @test size(Y) == (1000, 1500)
            @test typeof(Y) == Matrix{Float64}
            @test size(newmap, 2) == 3
            @test typeof(newmap) == Matrix{Float64}
        end
    end

    @testset "error-throws" begin
        TyI18N.set_locale_zh!()
        _msg = "数组索引必须为正整数"
        @test_throws _msg cmunique(randn(10, 15))
        @test_throws _msg cmunique(randn(2, 5, 2))
        @test_throws _msg cmunique(randn(2, 5), rand(4, 3))
    end
end
