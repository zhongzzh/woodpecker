using Test
using TyMathCore
using TyBase
using ReferenceTests
using TyCommunication
@testset "ofdmmod" begin
    @testset "使用OFDM对QPSK信号进行调制" begin
        rng = MT19937ar(1234)
        nfft = 64
        cplen = 16
        nSym = 10
        nullIdx = [1:6; 33; (64 - 4):64]
        pilotIdx = [12, 26, 40, 54]
        numDataCarrs = nfft - length(nullIdx) - length(pilotIdx)
        dataIn = complex.(randn(rng, numDataCarrs, nSym), randn(rng, numDataCarrs, nSym))
        pilots = repeat(pskmod(0:3, 4), 1, nSym)
        y1 = ofdmmod(dataIn, nfft, cplen, nullIdx, pilotIdx, pilots)
        function comp(d1, d2)
            return all(real((d1["y1"] .- d2["y1"])) .< 1e-10) &&
                   all(imag((d1["y1"] .- d2["y1"])) .< 1e-10)
        end
        @test_reference "Resources/ofdmmod/ofdmmod_1.jld" Dict("y1" => y1) by = comp
    end
end
@testset "双天线可变循环前缀OFDM调制" begin
    nfft = 8
    cplen = [1 2]
    nSym = 2
    nt = 2
    nullIdx = [1, 5]
    pilotIdx = [3, 7]
    numDataCarrs = nfft - length(nullIdx) - length(pilotIdx)
    dataIn = reshape(complex.(1:16, 101:116), numDataCarrs, nSym, nt)
    pilots = reshape(complex.(201:208, 301:308), length(pilotIdx), nSym, nt)
    y1 = ofdmmod(dataIn, nfft, cplen, nullIdx, pilotIdx, pilots)
    yExpected = ComplexF64[
        0.47855339059327379-0.47855339059327379im 0.47855339059327379-0.47855339059327379im
        51.625+126.625im 56.625+131.625im
        -0.47855339059327379+0.47855339059327379im -0.47855339059327379+0.47855339059327379im
        -50.125-75.625im -51.125-76.625im
        -0.22855339059327379+0.22855339059327379im -0.22855339059327379+0.22855339059327379im
        49.125+24.125im 46.125+21.125im
        0.22855339059327379-0.22855339059327379im 0.22855339059327379-0.22855339059327379im
        -50.625-75.125im -51.625-76.125im
        0.47855339059327379-0.47855339059327379im 0.47855339059327379-0.47855339059327379im
        -51.125-75.625im -52.125-76.625im
        0.47855339059327379-0.47855339059327379im 0.47855339059327379-0.47855339059327379im
        54.125+129.125im 59.125+134.125im
        -0.47855339059327379+0.47855339059327379im -0.47855339059327379+0.47855339059327379im
        -50.625-76.125im -51.625-77.125im
        -0.22855339059327379+0.22855339059327379im -0.22855339059327379+0.22855339059327379im
        47.625+22.625im 44.625+19.625im
        0.22855339059327379-0.22855339059327379im 0.22855339059327379-0.22855339059327379im
        -51.125-75.625im -52.125-76.625im
        0.47855339059327379-0.47855339059327379im 0.47855339059327379-0.47855339059327379im
    ]
    @test size(y1) == (nfft * nSym + sum(cplen), nt)
    @test all(abs.(real(y1 .- yExpected)) .< 1e-10) &&
        all(abs.(imag(y1 .- yExpected)) .< 1e-10)

    @testset "Float64 三维导频输入" begin
        pilots = reshape(Float64.(201:208), length(pilotIdx), nSym, nt)

        y1 = ofdmmod(dataIn, nfft, cplen, nullIdx, pilotIdx, pilots)
        y2 = ofdmmod(dataIn, nfft, cplen, nullIdx, pilotIdx, complex.(pilots))

        @test size(y1) == (nfft * nSym + sum(cplen), nt)
        @test all(abs.(real(y1 .- y2)) .< 1e-10) && all(abs.(imag(y1 .- y2)) .< 1e-10)
    end

    @testset "三参数调用与 Float64 三维输入" begin
        nfft = Int64(8)
        cplen = Int64(1)
        nSym = 2
        nt = 1
        inSym = reshape(Float64.(1:(nfft * nSym * nt)), nfft, nSym, nt)

        ofdmSig = ofdmmod(inSym, nfft, cplen)

        @test size(ofdmSig) == ((nfft + cplen) * nSym, nt)
        @test eltype(ofdmSig) <: Complex
    end
end
