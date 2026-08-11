using TyPlot, TyImageProcessing, Test

@testset "edge" begin
    pkg_dir = pkgdir(TyImageProcessing)
    src = imread(joinpath(pkg_dir, "resources", "cameraman.tif"))
    pic_dir = joinpath(pkg_dir, "test", "resources", "edge")

    @testset "reference results" begin
        sobel_ref = imread(joinpath(pic_dir, "test1.png")) .!= 0
        @test edge(src; fig=false) == sobel_ref
        @test isnothing(edge(src))

        vertical_ref = imread(joinpath(pic_dir, "test2.png")) .!= 0
        @test edge(src; direction="vertical", fig=false) == vertical_ref

        canny_ref = imread(joinpath(pic_dir, "test3.png")) .!= 0
        canny_result, = edge(src, "Canny"; fig=false)
        @test canny_result == canny_ref

        canny_horizontal_ref = imread(joinpath(pic_dir, "test4.png")) .!= 0
        canny_horizontal, = edge(src, "Canny"; direction="horizontal", fig=false)
        @test canny_horizontal == canny_horizontal_ref

        dst, thresholds = edge(src, "Canny"; sigma=sqrt(5), fig=false)
        @test size(dst) == size(src)
        @test thresholds ≈ [0.0375, 0.09375] atol = 1e-3
    end

    @testset "methods and directions" begin
        step_mask = falses(7, 7)
        step_mask[:, 5:end] .= true
        step_image = Float64.(step_mask)

        expected_gradient = falses(7, 7)
        expected_gradient[:, 5] .= true
        @test edge(step_image, "Sobel"; threshold=0.1, fig=false) == expected_gradient
        @test edge(step_image, "prewitt"; threshold=0.1, fig=false) == expected_gradient

        horizontal = edge(
            step_image, "Sobel"; direction="HORIZONTAL", threshold=0.1, fig=false
        )
        @test !any(horizontal)

        expected_roberts = falses(7, 7)
        expected_roberts[:, 4] .= true
        @test edge(step_image, "Roberts"; threshold=0.1, fig=false) == expected_roberts
        @test edge(step_image, "Roberts"; fig=false) == expected_roberts

        expected_log = falses(7, 7)
        expected_log[2:6, 5] .= true
        log_result = edge(step_image, "log"; threshold=0.01, sigma=1, fig=false)
        zerocross_result = edge(
            step_image, "zerocross"; threshold=[0.01], sigma=1, fig=false
        )
        @test log_result == expected_log
        @test zerocross_result == expected_log
    end

    @testset "thresholds and small inputs" begin
        step_mask = falses(7, 7)
        step_mask[:, 5:end] .= true
        step_image = Float64.(step_mask)

        @test edge(step_image; threshold=Float64[], fig=false) ==
            edge(step_image; fig=false)
        @test !any(edge(step_image; threshold=1, fig=false))

        canny_single, single_thresholds = edge(
            step_image, "Canny"; threshold=0.5, sigma=1, fig=false
        )
        canny_pair, pair_thresholds = edge(
            step_image, "Canny"; threshold=[0.1, 0.3], sigma=1, fig=false
        )
        @test single_thresholds == [0.2, 0.5]
        @test pair_thresholds == [0.1, 0.3]
        @test canny_single == canny_pair
        @test isnothing(edge(step_image, "Canny"; threshold=0.5, sigma=1))

        small_canny, small_thresholds = edge(zeros(2, 2), "Canny"; fig=false)
        @test !any(small_canny)
        @test small_thresholds == [0.00625, 0.015625]
        @test !any(edge(zeros(2, 2), "zerocross"; fig=false))

        zero_crossings = getfield(parentmodule(edge), :_edge_zero_crossings)
        response = [0.0 0.0 0.0; -1.0 0.0 1.0; 0.0 0.0 0.0]
        expected = falses(3, 3)
        expected[2, 2] = true
        @test zero_crossings(response, 0.4) == expected
        @test !any(zero_crossings(response, 1.1))
    end

    @testset "supported element types" begin
        step_mask = falses(7, 7)
        step_mask[:, 5:end] .= true
        expected = falses(7, 7)
        expected[:, 5] .= true
        inputs = (
            step_mask,
            ifelse.(step_mask, UInt8(255), UInt8(0)),
            ifelse.(step_mask, UInt16(65535), UInt16(0)),
            ifelse.(step_mask, typemax(Int16), typemin(Int16)),
            Float32.(step_mask),
            Float64.(step_mask),
        )
        for input in inputs
            @test edge(input; threshold=0.1, fig=false) == expected
        end
    end

    @testset "invalid parameters" begin
        image = zeros(5, 5)
        @test_throws ErrorException edge(image, "unknown"; fig=false)
        @test_throws ErrorException edge(image; direction="diagonal", fig=false)
        @test_throws ErrorException edge(image, "Sobel"; sigma=1, fig=false)
        @test_throws ErrorException edge(image, "Sobel"; threshold=[0.1, 0.2], fig=false)
        @test_throws ArgumentError edge(image, "Canny"; sigma=0, fig=false)
        @test_throws ArgumentError edge(image, "log"; sigma=0, fig=false)
        @test_throws ErrorException edge(image, "Canny"; threshold=1, fig=false)
        @test_throws ErrorException edge(image, "Canny"; threshold=[0.4, 0.3], fig=false)
        @test_throws ErrorException edge(image, "Canny"; threshold=[0.1, 1.0], fig=false)
        @test_throws ErrorException edge(
            image, "Canny"; threshold=[0.1, 0.2, 0.3], fig=false
        )
    end
end

@testset "edge 补充" begin
    gray_image = [
        0.0 0.2 0.4 0.6 0.8
        0.1 0.3 0.5 0.7 0.9
        0.2 0.4 0.6 0.8 1.0
        0.3 0.5 0.7 0.9 0.1
        0.4 0.6 0.8 0.0 0.2
    ]

    @testset "nonbinary grayscale input" begin
        gray_result = edge(gray_image, "Sobel"; threshold=0.1, fig=false)
        @test gray_result isa AbstractMatrix
        @test size(gray_result) == size(gray_image)
    end

    @testset "explicit fig true" begin
        @test isnothing(edge(gray_image, "Sobel"; fig=true))
    end

    @testset "Float64 sigma for log and zerocross" begin
        log_result = edge(gray_image, "log"; threshold=0.01, sigma=1.0, fig=false)
        zerocross_result = edge(
            gray_image, "zerocross"; threshold=0.01, sigma=1.0, fig=false
        )

        @test log_result isa AbstractMatrix
        @test zerocross_result isa AbstractMatrix
        @test size(log_result) == size(gray_image)
        @test size(zerocross_result) == size(gray_image)
    end

    @testset "explicit Float64 threshold" begin
        sobel_result = edge(gray_image, "Sobel"; threshold=1.0, fig=false)
        @test sobel_result isa AbstractMatrix
        @test size(sobel_result) == size(gray_image)
    end

    @testset "explicit empty Canny threshold" begin
        canny_result, canny_thresholds = edge(
            gray_image, "Canny"; threshold=Float64[], sigma=1.0, fig=false
        )
        @test canny_result isa AbstractMatrix
        @test size(canny_result) == size(gray_image)
        @test canny_thresholds isa AbstractVector
        @test length(canny_thresholds) == 2
    end
end
