using TyImageProcessing, Test, TyBaseCore, TyBase

const _IMCOLORDIFF_INTERNAL = TyImageProcessing.__Internal__

@testset "imcolordiff" begin
    @testset "src" begin
        I1 = imread("peppers.png")
        # I2 = localcontrast(I1);
        pkg_dir = pkgdir(TyImageProcessing)
        I2 = load(pkg_dir * "/resources/imcolordiff_exp1_I2.mat")["I2"]
        dE = imcolordiff(I1, I2)
        @test eltype(dE) == ((eltype(I1) == Float32) ? Float32 : Float64) &&
            size(dE) == size(I1)[1:2]

        he = imread("hestain.png")
        lab = rgb2lab(he)
        lab2 = copy(lab)
        scaleFactor = 1.1
        lab2[:, :, 2] = scaleFactor * lab[:, :, 2]
        dE = imcolordiff(lab, lab2; isInputLab=true)
        @test eltype(dE) == ((eltype(lab) == Float32) ? Float32 : Float64) &&
            size(dE) == size(lab)[1:2]

        pureRed = UInt8.([255 0 0])
        darkRed = UInt8.([255 10 50])
        dE = imcolordiff(pureRed, darkRed; Standard="CIEDE2000")
        @test eltype(dE) == ((eltype(pureRed) == Float32) ? Float32 : Float64) &&
            typeof(dE) <: Real

        fabric = imread("fabric.png")
        # fabric2 = localcontrast(fabric);
        pkg_dir = pkgdir(TyImageProcessing)
        fabric2 = load(pkg_dir * "/resources/imcolordiff_exp4_fabric2.mat")["fabric2"]
        dE = imcolordiff(fabric, fabric2; Standard="CIEDE2000", kL=2, K1=0.048, K2=0.014)
        @test eltype(dE) == ((eltype(fabric) == Float32) ? Float32 : Float64) &&
            size(dE) == size(fabric)[1:2]

        @testset "validation and fallback coverage" begin
            rgb64 = reshape([0.1, 0.2, 0.3], 1, 1, 3)
            rgb64b = reshape([0.15, 0.25, 0.35], 1, 1, 3)
            lab64 = reshape([50.0, 2.0, -3.0], 1, 1, 3)
            lab64b = reshape([51.0, 1.0, -2.0], 1, 1, 3)

            @test_throws ErrorException imcolordiff(rgb64, rgb64b; kL=0)
            @test_throws ErrorException imcolordiff(rgb64, rgb64b; kC=0)
            @test_throws ErrorException imcolordiff(rgb64, rgb64b; kH=0)
            @test_throws ErrorException imcolordiff(rgb64, rgb64b; K1=0)
            @test_throws ErrorException imcolordiff(rgb64, rgb64b; K2=0)

            bad_lab_type = reshape(Bool[true, false, true], 1, 1, 3)
            lab_with_nan = copy(lab64)
            lab_with_nan[1, 1, 1] = NaN
            @test_throws ErrorException imcolordiff(lab64, bad_lab_type; isInputLab=true)
            @test_throws ErrorException imcolordiff(lab64, lab_with_nan; isInputLab=true)
            @test_throws ErrorException imcolordiff(bad_lab_type, lab64; isInputLab=true)
            @test_throws ErrorException imcolordiff(lab_with_nan, lab64; isInputLab=true)

            bad_rgb_type = reshape(Bool[true, false, true], 1, 1, 3)
            rgb_with_nan = copy(rgb64)
            rgb_with_nan[1, 1, 1] = NaN
            @test_throws ErrorException imcolordiff(rgb64, bad_rgb_type)
            @test_throws ErrorException imcolordiff(rgb64, rgb_with_nan)
            @test_throws ErrorException imcolordiff(bad_rgb_type, rgb64)
            @test_throws ErrorException imcolordiff(rgb_with_nan, rgb64)

            dE_rgb64 = imcolordiff(rgb64, rgb64b)
            @test dE_rgb64 isa Real

            rgb32 = reshape(Float32[0.1, 0.2, 0.3, 0.2, 0.3, 0.4], 1, 2, 3)
            rgb32b = reshape(Float32[0.11, 0.19, 0.31, 0.25, 0.29, 0.38], 1, 2, 3)
            @test size(imcolordiff(rgb32, rgb32b)) == (1, 2)
            @test size(imcolordiff(rgb32, rgb32b; Standard="CIEDE2000")) == (1, 2)

            lab64_4d = reshape(
                [0.1, 0.2, 0.3, 0.2, 0.3, 0.4, 0.3, 0.2, 0.1, 0.4, 0.3, 0.2], 1, 2, 3, 2
            )
            lab64_4db = lab64_4d .+ 0.01
            @test size(imcolordiff(lab64_4d, lab64_4db; isInputLab=true)) == (1, 2, 1, 2)
            @test size(
                imcolordiff(lab64_4d, lab64_4db; isInputLab=true, Standard="CIEDE2000")
            ) == (1, 2, 1, 2)
            @test imcolordiff(
                reshape(Float32[0.1, 0.2, 0.3], 1, 1, 3),
                reshape(Float32[0.11, 0.19, 0.31], 1, 1, 3),
            ) isa Real

            ct1 = UInt8[255 0 0; 0 255 0]
            ct2 = UInt8[0 0 255]
            ct_de = _IMCOLORDIFF_INTERNAL.imcolordiff_fast_path(
                ct1, ct2, (2, 1), "CIE94", false, 1.0, 1.0, 1.0, 0.045, 0.015
            )
            @test size(ct_de) == (2, 1)
            @test _IMCOLORDIFF_INTERNAL.imcolordiff_fast_path(
                UInt8[1 2; 3 4],
                UInt8[1 2; 3 4],
                (2, 2),
                "CIE94",
                false,
                1.0,
                1.0,
                1.0,
                0.045,
                0.015,
            ) === nothing
        end
    end
end
