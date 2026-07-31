using TyImageProcessing, Test, TyBaseCore, TyFileIO

@testset "imrotate3" begin
    @testset "src" begin
        D = load(pkgdir(TyImageProcessing) * "/resources/mri.mat")["D"]
        vol = squeeze(D)
        volRot = imrotate3(vol, 90, [0 0 1], "nearest", "loose")
        @test eltype(volRot) == eltype(vol)
    end
end
