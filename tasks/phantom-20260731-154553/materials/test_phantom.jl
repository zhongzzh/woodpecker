using TyImageProcessing, Test

@testset "phantom" begin
    @testset "src" begin
        P, E = phantom("Modified Shepp-Logan", 200)
        @test size(P) == (200, 200) && size(E, 2) == 6
    end

    @testset "P, = phantom(def,n)" begin
        def = ["Modified Shepp-Logan", "Shepp-Logan"]
        n = 256
        P, E = phantom(def[1], n)
        @test size(P) == (n, n) && size(E, 2) == 6

        def = ["Modified Shepp-Logan", "Shepp-Logan"]
        n = 216
        P, E = phantom(def[2], n)
        @test size(P) == (n, n) && size(E, 2) == 6
    end

    @testset "P, = phantom(E,n)" begin
        E = rand(5, 6)
        n = 256
        P, E = phantom(E, n)
        @test size(P) == (n, n) && size(E, 2) == 6
    end
end
