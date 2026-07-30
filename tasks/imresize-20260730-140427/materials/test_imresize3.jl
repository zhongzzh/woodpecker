using TyImageProcessing, Test, TyBaseCore, TyFileIO

@testset "imresize3" begin
    @testset "src" begin
        s = load(pkgdir(TyImageProcessing) * "/resources/mri.mat")
        mriVolumeOriginal = squeeze(s["D"])
        sizeO = size(mriVolumeOriginal)
        mriVolumeResized = imresize3(mriVolumeOriginal, 0.5)
        sizeR = size(mriVolumeResized)
        @test eltype(mriVolumeResized) == eltype(mriVolumeOriginal)
    end
end
