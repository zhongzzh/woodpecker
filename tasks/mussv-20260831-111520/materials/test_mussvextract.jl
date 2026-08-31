@testset "test_mussvextract" begin
    M = [0.5377 + 1.0347im  -1.3077 + 0.8884im  -1.3499 + 1.4384im  -0.2050 - 0.1022im   0.6715 - 0.0301im;
    1.8339 + 0.7269im  -0.4336 - 1.1471im   3.0349 + 0.3252im  -0.1241 - 0.2414im  -1.2075 - 0.1649im;
    -2.2588 - 0.3034im   0.3426 - 1.0689im   0.7254 - 0.7549im   1.4897 + 0.3192im   0.7172 + 0.6277im;
    0.8622 + 0.2939im   3.5784 - 0.8095im  -0.0631 + 1.3703im   1.4090 + 0.3129im  1.6302 + 1.0933im;
    0.3188 - 0.7873im   2.7694 - 2.9443im   0.7147 - 1.7115im   1.4172 - 0.8649im   0.4889 + 1.1093im]
    BlockStructure = [-1 0;-1 0;1 1;2 0]
    _,Info = mussv(M,BlockStructure)
    VDelta,VSigma,VLmi = mussvextract(Info;nargout=3)

    @test VDelta ≈ diagm([-0.2054,0.2054,0.0669 + 0.1942im,0.1385 - 0.1517im,0.1385 - 0.1517im]) atol = 0.1
    @test VSigma["DLeft"] ≈ blkdiag(diagm([0.7242,0.7834,0.6842]),[0.5092 -0.0420+0.0013im; -0.0420-0.0013im 0.5047]) atol = 0.1
    @test VSigma["GRight"] ≈ diagm([1.1374, -0.1239,0,0,0]) atol = 0.1
end