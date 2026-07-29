using TyPlot, TyImageProcessing, Test, TyI18N

@testset "imfindcircles" begin
    pkg_dir = pkgdir(TyImageProcessing)
    source_path = pkg_dir * "/resources/rice.png"
    I = imread(source_path)
    BW = imbinarize(I)
    @testset "src1" begin
        res = bwboundaries(BW, "noholes")
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    source_path = pkg_dir * "/resources/blobs.png"
    BW = imread(source_path)
    @testset "src2" begin
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    #新增
    source_path = pkg_dir * "/resources/blobs.png"
    BW = imread(source_path)
    @testset "conn" begin
        res = bwboundaries(BW, 8)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end
    #新增
    source_path = pkg_dir * "/resources/blobs.png"
    BW = imread(source_path)
    @testset "options" begin
        res = bwboundaries(BW, "holes")
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    #新增
    source_path = pkg_dir * "/resources/blobs.png"
    BW = imread(source_path)
    @testset "CoordinateOrder" begin
        res = bwboundaries(BW; CoordinateOrder="yx")
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end
    #新增
    @testset "CoordinateOrder" begin
        res = bwboundaries(BW; CoordinateOrder="xy")
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end
    #新增
    @testset "输出" begin
        res = bwboundaries(BW, "noholes")
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Bool1" begin
        BW = rand(Bool, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Bool2" begin
        BW = Bool.(rand(Bool, 10, 10))
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "UInt8" begin
        BW = rand(UInt8, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "UInt16" begin
        BW = rand(UInt16, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "UInt32" begin
        BW = rand(UInt32, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "UInt64" begin
        BW = rand(UInt64, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Int8" begin
        BW = rand(Int8, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Int16" begin
        BW = rand(Int16, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Int32" begin
        BW = rand(Int32, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Int64" begin
        BW = rand(Int64, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Float32" begin
        BW = rand(Float32, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "Float64" begin
        BW = rand(Float64, 10, 10)
        res = bwboundaries(BW)
        if length(res) == 3
            @test typeof(res[1]) == Matrix{Matrix{Int64}} &&
                typeof(res[2]) == Matrix{Float64} &&
                typeof(res[3]) == Int64
        elseif length(res) == 2
            @test typeof(res[1]) == Matrix{Matrix{Int64}} && typeof(res[2]) == Int64
        end
    end

    @testset "empty-array" begin
        res_ = bwboundaries(Matrix{Float64}(undef, 0, 0))
        @test isa(res_, AbstractArray) && isempty(res_)
    end

    @testset "error-throws" begin
        TyI18N.set_locale_zh!()
        BW = rand(Float64, 10, 10)
        _msg = "参数 'conn' 当前仅支持 8像素连通性。"
        @test_throws _msg bwboundaries(BW, 5)

        _msg = "参数 'options' 当前仅支持 'holes' 或 'noholes'"
        @test_throws _msg bwboundaries(BW, 8, "hh")

        _msg = "参数 'CoordinateOrder' 当前仅支持 'xy' 或 'yx'。"
        @test_throws _msg bwboundaries(BW, CoordinateOrder="xz")
    end
end
