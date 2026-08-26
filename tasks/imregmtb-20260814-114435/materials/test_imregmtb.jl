using TyImageProcessing, Test, TyRandom, TyI18N

@testset "imregmtb" begin
    @testset "deterministic office example" begin
        I1 = imread("office_1.jpg")
        I2 = imread("office_2.jpg")
        I3 = imread("office_3.jpg")
        I4 = imread("office_4.jpg")
        I5 = imread("office_5.jpg")
        I6 = imread("office_6.jpg")

        r = MT19937ar(5489)
        t = Float64.(rand(r, -30:30, 5, 2))
        I1, = imtranslate(I1, reshape(t[1, :], 1, 2))
        I2, = imtranslate(I2, reshape(t[2, :], 1, 2))
        I3, = imtranslate(I3, reshape(t[3, :], 1, 2))
        I4, = imtranslate(I4, reshape(t[4, :], 1, 2))
        I5, = imtranslate(I5, reshape(t[5, :], 1, 2))

        R1, R2, R3, R4, R5, shift = imregmtb(I1, I2, I3, I4, I5, I6)

        @test size(R1) == size(I1) && eltype(R1) == eltype(I1)
        @test size(R2) == size(I2) && eltype(R2) == eltype(I2)
        @test size(R3) == size(I3) && eltype(R3) == eltype(I3)
        @test size(R4) == size(I4) && eltype(R4) == eltype(I4)
        @test size(R5) == size(I5) && eltype(R5) == eltype(I5)
        @test size(shift) == (5, 2)
        expectedShift = [-26.0 25.0; -25.0 14.0; 23.0 -3.0; -25.0 -28.0; -8.0 -28.0]
        @test shift == expectedShift
    end

    @testset "non-UInt8 image classes" begin
        Iu8 = imread("office_6.jpg")
        If32 = im2single(Iu8)
        Iu16 = im2uint16(Iu8)

        Rf32, shiftF32 = imregmtb(If32, If32)
        Ru16, shiftU16 = imregmtb(Iu16, Iu16)

        @test size(Rf32) == size(If32) && eltype(Rf32) == Float32
        @test size(Ru16) == size(Iu16) && eltype(Ru16) == UInt16
        @test shiftF32 == zeros(1, 2)
        @test shiftU16 == zeros(1, 2)
    end

    @testset "language" begin
        TyI18N.set_locale_zh!()

        err = try
            imregmtb(zeros(UInt8, 63, 64), zeros(UInt8, 63, 64))
            nothing
        catch e
            e
        end
        @test err !== nothing
        @test occursin("支持的最小图像大小为 64×64。", sprint(showerror, err))

        err = try
            imregmtb(zeros(Bool, 64, 64), zeros(Bool, 64, 64))
            nothing
        catch e
            e
        end
        @test err !== nothing
        @test occursin("第 1 个输入, chkImg, 应为以下类型之一", sprint(showerror, err))

        err = try
            imregmtb(zeros(UInt8, 64, 64), zeros(Float32, 64, 64))
            nothing
        catch e
            e
        end
        @test err !== nothing
        @test occursin("所有输入图像应具有相同的类。", sprint(showerror, err))
    end
end
