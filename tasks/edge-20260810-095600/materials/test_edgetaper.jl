using TyImageProcessing, Test

@testset "edgetaper" begin
    @testset "src" begin
        original = imread("cameraman.tif")
        PSF = fspecial("gaussian", 60, 10)
        edgesTapered = edgetaper(original, PSF)
        @test eltype(edgesTapered) == eltype(original) &&
            size(edgesTapered) == size(original)
    end
end
