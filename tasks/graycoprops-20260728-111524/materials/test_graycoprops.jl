using TyImageProcessing, Test, TyBaseCore

@testset "graycoprops" begin
    @testset "src" begin
        glcm = [0 1 2 3; 1 1 2 3; 1 0 2 0; 0 0 0 3]
        stats = graycoprops(glcm)
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        # I = imread("circuit.tif")
        # glcm, = graycomatrix(I; Offset=[2 0; 0 2])
        # stats = graycoprops(Int.(glcm))
        # @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct
    end

    @testset "stats = graycoprops(glcm,properties)
    " begin
        glcm = round.(rand(Float32, 100, 100))
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[1])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        glcm = round.(rand(Float64, 100, 100, 3))
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[2])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        glcm = rand(UInt8, 100, 100)
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[3])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        glcm = rand(UInt16, 100, 100, 3)
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[4])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        glcm = rand(UInt32, 100, 100)
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[5])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        glcm = rand(UInt64, 100, 100, 3)
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[1])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        T = Int8
        glcm = T.(rand(0:typemax(T), 100, 100))
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[2])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        T = Int16
        glcm = T.(rand(0:typemax(T), 100, 100, 3))
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[3])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        T = Int32
        glcm = T.(rand(0:typemax(T), 100, 100))
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[4])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct

        T = Int64
        glcm = T.(rand(0:typemax(T), 100, 100, 3))
        properties = ["all", "Contrast", "Correlation", "Energy", "Homogeneity"]
        stats = graycoprops(glcm, properties[5])
        @test typeof(stats) == TyImageProcessing.__Internal__.graycoprops_struct
    end
end
