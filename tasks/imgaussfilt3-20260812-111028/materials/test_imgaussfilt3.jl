using TyImageProcessing, Test, TyBaseCore, TyFileIO

const _IMGAUSSFILT3_INTERNAL = TyImageProcessing.__Internal__

@testset "imgaussfilt3" begin
    vol = load(pkgdir(TyImageProcessing) * "/resources/mri.mat")
    A = squeeze(vol["D"])
    B = imgaussfilt3(A, 2)
    @test eltype(B) == eltype(A) && size(B) == size(A)

    small = UInt8.(reshape(0:26, 3, 3, 3))
    @test imgaussfilt3(small) isa Array{UInt8,3}
    @test imgaussfilt3(small, 1; Padding="symmetric", FilterDomain="spatial") isa
        Array{UInt8,3}
    @test imgaussfilt3(small, 1; Padding="circular", FilterDomain="spatial") isa
        Array{UInt8,3}
    @test imgaussfilt3(small, 1; FilterSize=3, Padding=0, FilterDomain="spatial") isa
        Array{UInt8,3}

    aniso = imgaussfilt3(
        small,
        [0.5 1.0 1.5];
        FilterSize=[3 5 7],
        Padding="replicate",
        FilterDomain="spatial",
    )
    @test size(aniso) == size(small) && eltype(aniso) == UInt8

    f32 = Float32.(small) ./ 26
    f32out = imgaussfilt3(f32, [0.5, 0.75, 1.0]; FilterSize=[3, 3, 5])
    @test size(f32out) == size(f32) && eltype(f32out) == Float32

    i32out = imgaussfilt3(Int32.(small), 0.5; FilterSize=3)
    @test size(i32out) == size(small) && eltype(i32out) == Int32

    spatial = imgaussfilt3(
        small, 0.5; FilterSize=3, Padding="replicate", FilterDomain="spatial"
    )
    frequency = imgaussfilt3(
        small, 0.5; FilterSize=3, Padding="replicate", FilterDomain="frequency"
    )
    @test size(frequency) == size(spatial) && eltype(frequency) == eltype(spatial)
    @test maximum(abs.(Int.(frequency) .- Int.(spatial))) <= 1

    @test _IMGAUSSFILT3_INTERNAL.chooseFilterImplementation(
        small, [3.0 3.0 3.0], "spatial"
    ) == "spatial"
    @test _IMGAUSSFILT3_INTERNAL.chooseFilterImplementation(small, [3.0 3.0 3.0], "auto") ==
        "spatial"
    @test _IMGAUSSFILT3_INTERNAL.chooseFilterDomain3(
        zeros(UInt8, 160, 160, 100), [9.0 9.0 9.0], false
    ) == "frequency"
    @test _IMGAUSSFILT3_INTERNAL.computePadSize(size(small), [3.0 5.0 7.0]) == [1, 2, 3]
    @test _IMGAUSSFILT3_INTERNAL.computePadSize(size(small), [3.0]) == [1, 0, 0]
    @test _IMGAUSSFILT3_INTERNAL.imgaussfilt3_cast(Float64.(small), Float32) isa
        Array{Float32,3}
    padded, padSize = _IMGAUSSFILT3_INTERNAL.imgaussfilt3_padImage(small, [3.0 3.0 3.0], 7)
    @test size(padded) == (5, 5, 5) && padSize == [1, 1, 1]

    @test _IMGAUSSFILT3_INTERNAL.validateSigma(2) == [2.0 2.0 2.0]
    @test _IMGAUSSFILT3_INTERNAL.validateSigma([0.5, 1.0, 1.5]) == [0.5, 1.0, 1.5]
    @test _IMGAUSSFILT3_INTERNAL.images_internal_validateThreeDFilterSize(3) ==
        [3.0 3.0 3.0]
    @test _IMGAUSSFILT3_INTERNAL.images_internal_validateThreeDFilterSize([3, 5, 7]) ==
        [3.0 5.0 7.0]
    @test _IMGAUSSFILT3_INTERNAL.validatePadding("replicate") == "replicate"
    @test _IMGAUSSFILT3_INTERNAL.validatePadding("circular") == "circular"
    @test _IMGAUSSFILT3_INTERNAL.validatePadding("symmetric") == "symmetric"
    @test _IMGAUSSFILT3_INTERNAL.validatePadding(4) == 4
    @test _IMGAUSSFILT3_INTERNAL.validateFilterDomain("auto") == "auto"
    @test _IMGAUSSFILT3_INTERNAL.validateFilterDomain("frequency") == "frequency"
    @test _IMGAUSSFILT3_INTERNAL.imgaussfilt3_replicate_index(0, 3) == 1
    @test _IMGAUSSFILT3_INTERNAL.imgaussfilt3_circular_index(0, 3) == 3
    @test _IMGAUSSFILT3_INTERNAL.imgaussfilt3_symmetric_index(4, 3) == 3

    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.imgaussfilt3_spatialGaussianFilter(
        zeros(Int64, 2, 2, 2), [1.0 1.0 1.0], [3.0 3.0 3.0], "replicate"
    )
    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.imgaussfilt3_separable_filter(
        zeros(Float32, 2, 2, 2), [1.0], Val(1), "bad"
    )
    @test_throws ErrorException imgaussfilt3(falses(size(small)))
    @test_throws ErrorException imgaussfilt3(zeros(Float64, 2, 2, 2, 2))
    @test_throws ErrorException imgaussfilt3(small, -1)
    @test_throws InexactError imgaussfilt3(small, Inf)
    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.validateSigma(Float64[])
    @test_throws ErrorException imgaussfilt3(small, [1, 2])
    @test_throws ErrorException imgaussfilt3(small, 1; FilterSize=0)
    @test_throws ErrorException imgaussfilt3(small, 1; FilterSize=2)
    @test_throws ErrorException imgaussfilt3(small, 1; FilterSize=[3, 5])
    @test_throws TypeError imgaussfilt3(small, 1; FilterSize=3.5)
    @test_throws ErrorException imgaussfilt3(small, 1; Padding="bad")
    @test_throws ErrorException imgaussfilt3(small, 1; FilterDomain="bad")
    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.validateSigma(1 + 2im)
    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.images_internal_validateThreeDFilterSize(
        Bool[true]
    )
    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.images_internal_validateThreeDFilterSize(
        Int[]
    )
    @test_throws ErrorException _IMGAUSSFILT3_INTERNAL.images_internal_validateThreeDFilterSize([
        1.5
    ])
    @test_throws MethodError _IMGAUSSFILT3_INTERNAL.images_internal_validateThreeDFilterSize(
        ComplexF64[1 + 0im]
    )
end
