@testset "test_mussv" begin
    M = [0.5377 + 1.0347im  -1.3077 + 0.8884im  -1.3499 + 1.4384im  -0.2050 - 0.1022im   0.6715 - 0.0301im;
    1.8339 + 0.7269im  -0.4336 - 1.1471im   3.0349 + 0.3252im  -0.1241 - 0.2414im  -1.2075 - 0.1649im;
    -2.2588 - 0.3034im   0.3426 - 1.0689im   0.7254 - 0.7549im   1.4897 + 0.3192im   0.7172 + 0.6277im;
    0.8622 + 0.2939im   3.5784 - 0.8095im  -0.0631 + 1.3703im   1.4090 + 0.3129im  1.6302 + 1.0933im;
    0.3188 - 0.7873im   2.7694 - 2.9443im   0.7147 - 1.7115im   1.4172 - 0.8649im   0.4889 + 1.1093im]
    BlockStructure = [-1 0;-1 0;1 1;2 0]
    Bounds,Info = mussv(M,BlockStructure)
    @test Bounds ≈ [5.2319 4.8693] atol = 0.01
    @test mussvextract(Info) ≈ diagm([-0.2054, 0.2054, 0.0669+0.1942im, 0.1385-0.1517im, 0.1385-0.1517im]) atol = 0.01
    
    M = [0.7893 - 0.4456im  -0.2693 + 0.8912im   0.8327 - 0.4932im  -1.2613 + 0.1430im   1.7297 + 0.0108im;
    -0.0466 + 0.3929im   0.9706 - 0.1161im  -0.1847 - 0.6405im   1.1562 + 0.8344im   0.2270 + 1.1929im;
    0.3398 - 0.8005im  -0.7581 + 0.9195im   0.7491 - 0.0709im   0.6955 - 1.0649im   0.4369 + 0.2676im;
    -0.0542 - 0.1106im   0.4301 + 0.3770im  -1.5446 - 1.2342im  -0.9472 + 1.4672im   0.0115 + 2.0185im;
    1.3350 + 0.9115im  -1.0686 - 1.1982im  -0.0798 + 0.3214im  -1.9843 - 1.8432im  -0.5054 + 0.1564im]
    BlockStructure = [-1 0;1 0;1 1;2 0]
    Bounds,Info = mussv(M,BlockStructure)
    @test Bounds ≈ [3.9465 3.8990] atol = 0.01
    @test mussvextract(Info) ≈ diagm([0.2565, -0.0133-0.2561im, 0.1013-0.2357im, -0.1958-0.1657im, -0.1958-0.1657im]) atol = 0.01

    Bounds, _ = mussv(Matrix{Float64}(I, 3, 3), [-1 0; -1 0; -1 0])
    @test Bounds[1] ≈ 1 atol = 1e-5

    # MATLAB-to-Julia porting smoke tests for the main block layouts.
    M = ComplexF64[0.2+0.1im 0.3-0.2im; -0.4+0.05im 0.1+0.2im]
    for (matrix,blocks) in (
        (M,[2 2]),
        (reshape(ComplexF64[0.75],1,1),[-1 0]),
        (M,[-1 0; 1 1]),
    )
        bounds,_ = mussv(matrix,blocks)
        @test size(bounds) == (1,2)
        @test all(isfinite,bounds)
        @test 0 <= bounds[2] <= bounds[1]
    end

    # The mN option previously referenced an undefined iteration option and
    # constructed complex matrices with a scalar-only method.
    multiple_bounds,_ = mussv(M,[-1 0; 1 1],"m2")
    @test all(isfinite,multiple_bounds)
    @test 0 <= multiple_bounds[2] <= multiple_bounds[1]

    # The unavailable LMI option must explicitly fall back to the supported
    # gradient upper-bound path instead of disabling upper-bound refinement.
    @test_logs (:warn,r"LMI upper-bound option") begin
        lmi_fallback_bounds,_ = mussv(M,[2 2],"a")
        @test all(isfinite,lmi_fallback_bounds)
    end

    # wcgain-style generalized mu: the uncertainty block is fixed and the
    # final performance block varies.  An infinite initial upper bound must
    # not be passed into _mufastub.
    fixed_bounds,_ = mussv(M,[1 1; 1 1],"",[1])
    @test all(isfinite,fixed_bounds)
    @test 0 <= fixed_bounds[2] <= fixed_bounds[1]

    # A singular fixed/vary pencil can have no finite generalized
    # eigenvalues. The upper-bound initialization must fall back to _DGinit
    # instead of reducing an empty eigenvalue collection.
    singular_fixed_vary = ComplexF64[
        0.0 0.6324555320336759
        0.6324555320336759 2.0
    ]
    singular_bounds,_ = mussv(
        singular_fixed_vary,[-1 0;1 1],"",[1],
    )
    @test singular_bounds[2] ≈ 2.4 atol = 1e-8
    @test singular_bounds[2] <= singular_bounds[1] <= 2.40001

    # Rectangular full blocks require distinct row and column index sets in
    # perturbation reconstruction.
    rectangular_bounds,_ = mussv(ComplexF64[0.2 0.3],[2 1])
    @test all(isfinite,rectangular_bounds)
    @test 0 <= rectangular_bounds[2] <= rectangular_bounds[1]

    # The zero-lower-bound fallback must not mutate block metadata shared by
    # subsequent frequency points.
    real_frequency_data = reshape(ComplexF64[0.5,0.75],1,1,2)
    real_frequency_bounds,_ = mussv(real_frequency_data,[-1 0],"p")
    @test size(real_frequency_bounds) == (1,2,2)
    @test all(isfinite,real_frequency_bounds)
end
