"""
imcolordiff - 基于 CIE94 或 CIE2000 标准的色差

dE = imcolordiff(I1,I2)

dE = imcolordiff(I1,I2,Name=Value)
"""
function imcolordiff(
    I1::AbstractArray{<:Real},
    I2::AbstractArray{<:Real};
    Standard::AbstractString="CIE94",
    isInputLab::Bool=false,
    kL::Number=1,
    kC::Number=1,
    kH::Number=1,
    K1::Number=0.045,
    K2::Number=0.015,
)
    if kL <= 0
        error(
            _msg(
                @tr("Invalid value for 'kL'. Value must be greater than 0."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if kC <= 0
        error(
            _msg(
                @tr("Invalid value for 'kC'. Value must be greater than 0."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if kH <= 0
        error(
            _msg(
                @tr("Invalid value for 'kH'. Value must be greater than 0."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if K1 <= 0
        error(
            _msg(
                @tr("Invalid value for 'K1'. Value must be greater than 0."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if K2 <= 0
        error(
            _msg(
                @tr("Invalid value for 'K2'. Value must be greater than 0."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isInputLab
        if eltype(I2) ∉ _IMCOLORDIFF_LAB_TYPES
            error(
                _msg(
                    @tr(
                        "Input must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                        "Float32, Float64",
                        eltype(I2)
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !all(TyBaseCore.isfinite, I2)
            error(_msg(@tr("Input must be finite."), splitext(basename(@__FILE__))[1]))
        end
        if eltype(I1) ∉ _IMCOLORDIFF_LAB_TYPES
            error(
                _msg(
                    @tr(
                        "Input must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                        "Float32, Float64",
                        eltype(I1)
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !all(TyBaseCore.isfinite, I1)
            error(_msg(@tr("Input must be finite."), splitext(basename(@__FILE__))[1]))
        end
    else
        if eltype(I2) ∉ _IMCOLORDIFF_RGB_TYPES
            error(
                _msg(
                    @tr(
                        "Input must be one of the following types:\n\nFloat32, Float64, UInt8, UInt16\n\nbut its type was %{1}.",
                        eltype(I2)
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !all(TyBaseCore.isfinite, I2)
            error(_msg(@tr("Input must be finite."), splitext(basename(@__FILE__))[1]))
        end
        if eltype(I1) ∉ _IMCOLORDIFF_RGB_TYPES
            error(
                _msg(
                    @tr(
                        "Input must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                        "Float32, Float64, UInt8, UInt16",
                        eltype(I1)
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !all(TyBaseCore.isfinite, I1)
            error(_msg(@tr("Input must be finite."), splitext(basename(@__FILE__))[1]))
        end
    end

    Stnd = validatestring((Standard, ["CIE94", "CIEDE2000"]))

    I1, I2, out_size = images_color_internal_checkAndReshapeColorArrays(I1, I2)
    fast_delE = imcolordiff_fast_path(
        I1,
        I2,
        out_size,
        Stnd,
        isInputLab,
        Float64(kL),
        Float64(kC),
        Float64(kH),
        Float64(K1),
        Float64(K2),
    )
    fast_delE !== nothing && return fast_delE

    if eltype(I1) ∈ [Float64, Int64] || eltype(I2) ∈ [Float64, Int64]
        I1 = im2double(I1)
        I2 = im2double(I2)
        kL = Float64(kL)
        kC = Float64(kC)
        kH = Float64(kH)
        K1 = Float64(K1)
        K2 = Float64(K2)
    else
        I1 = im2single(I1)
        I2 = im2single(I2)
    end

    if !isInputLab
        I1 = rgb2lab(I1)
        I2 = rgb2lab(I2)
    end

    if Stnd == "CIEDE2000"
        delE = deltaE2000(I1, I2, kL, kC, kH, K1, K2)
    elseif Stnd == "CIE94"
        delE = deltaE94(I1, I2, kL, kC, kH, K1, K2)
    end

    delE = reshape(delE, out_size...)

    if ndims(delE) == 3 && size(delE, 3) == 1
        delE = delE[:, :, 1]
    end

    if length(delE) == 1
        delE = delE[1]
    end

    return delE
end

const _IMCOLORDIFF_RGB_TYPES = (Float64, Float32, UInt8, UInt16, Int64)
const _IMCOLORDIFF_LAB_TYPES = (Float64, Float32, Int64)
const _IMCOLORDIFF_D65_X = 0.95047
const _IMCOLORDIFF_D65_Z = 1.08883
const _IMCOLORDIFF_EPSILON = 216 / 24389
const _IMCOLORDIFF_KAPPA = 24389 / 27
const _IMCOLORDIFF_RAD30 = pi / 6
const _IMCOLORDIFF_RAD275 = 55pi / 36
const _IMCOLORDIFF_RAD25 = 5pi / 36
const _IMCOLORDIFF_RAD6 = pi / 30
const _IMCOLORDIFF_RAD63 = 7pi / 20

function imcolordiff_fast_path(
    I1,
    I2,
    out_size,
    Stnd,
    isInputLab::Bool,
    kL::Float64,
    kC::Float64,
    kH::Float64,
    K1::Float64,
    K2::Float64,
)
    if eltype(I1) == Float32 ||
        eltype(I2) == Float32 ||
        eltype(I1) == Int64 ||
        eltype(I2) == Int64
        return nothing
    end

    if ndims(I1) == 3 && ndims(I2) == 3 && size(I1, 3) == 3 && size(I2, 3) == 3
        return imcolordiff_fast_image(I1, I2, Stnd, isInputLab, kL, kC, kH, K1, K2)
    elseif ndims(I1) == 2 && ndims(I2) == 2 && size(I1, 2) == 3 && size(I2, 2) == 3
        return imcolordiff_fast_colortable(
            I1, I2, out_size, Stnd, isInputLab, kL, kC, kH, K1, K2
        )
    end

    return nothing
end

function imcolordiff_fast_image(I1, I2, Stnd, isInputLab, kL, kC, kH, K1, K2)
    out = Matrix{Float64}(undef, size(I1, 1), size(I1, 2))
    use_ciede2000 = Stnd == "CIEDE2000"
    @inbounds for j in axes(out, 2), i in axes(out, 1)
        lab1 = imcolordiff_lab_pixel(I1, i, j, isInputLab)
        lab2 = imcolordiff_lab_pixel(I2, i, j, isInputLab)
        out[i, j] = if use_ciede2000
            imcolordiff_deltaE2000_pixel(lab1..., lab2..., kL, kC, kH, K1, K2)
        else
            imcolordiff_deltaE94_pixel(lab1..., lab2..., kL, kC, kH, K1, K2)
        end
    end
    return length(out) == 1 ? out[1] : out
end

function imcolordiff_fast_colortable(I1, I2, out_size, Stnd, isInputLab, kL, kC, kH, K1, K2)
    nrows = max(size(I1, 1), size(I2, 1))
    out = Matrix{Float64}(undef, nrows, 1)
    use_ciede2000 = Stnd == "CIEDE2000"
    @inbounds for r in 1:nrows
        r1 = size(I1, 1) == 1 ? 1 : r
        r2 = size(I2, 1) == 1 ? 1 : r
        lab1 = imcolordiff_lab_row(I1, r1, isInputLab)
        lab2 = imcolordiff_lab_row(I2, r2, isInputLab)
        out[r, 1] = if use_ciede2000
            imcolordiff_deltaE2000_pixel(lab1..., lab2..., kL, kC, kH, K1, K2)
        else
            imcolordiff_deltaE94_pixel(lab1..., lab2..., kL, kC, kH, K1, K2)
        end
    end
    nrows == 1 && return out[1]
    return reshape(out, out_size...)
end

function imcolordiff_lab_pixel(I, i::Int, j::Int, isInputLab::Bool)
    if isInputLab
        return Float64(I[i, j, 1]), Float64(I[i, j, 2]), Float64(I[i, j, 3])
    end
    return imcolordiff_rgb_to_lab(
        Float64(I[i, j, 1]), Float64(I[i, j, 2]), Float64(I[i, j, 3]), eltype(I)
    )
end

function imcolordiff_lab_row(I, r::Int, isInputLab::Bool)
    if isInputLab
        return Float64(I[r, 1]), Float64(I[r, 2]), Float64(I[r, 3])
    end
    return imcolordiff_rgb_to_lab(
        Float64(I[r, 1]), Float64(I[r, 2]), Float64(I[r, 3]), eltype(I)
    )
end

function imcolordiff_rgb_to_lab(r, g, b, ::Type{T}) where {T}
    rr = imcolordiff_rgb_unit(r, T)
    gg = imcolordiff_rgb_unit(g, T)
    bb = imcolordiff_rgb_unit(b, T)

    rl = imcolordiff_srgb_to_linear(rr)
    gl = imcolordiff_srgb_to_linear(gg)
    bl = imcolordiff_srgb_to_linear(bb)

    x = 0.412453 * rl + 0.357580 * gl + 0.180423 * bl
    y = 0.212671 * rl + 0.715160 * gl + 0.072169 * bl
    z = 0.019334 * rl + 0.119193 * gl + 0.950227 * bl

    fx = imcolordiff_lab_f(x / _IMCOLORDIFF_D65_X)
    fy = imcolordiff_lab_f(y)
    fz = imcolordiff_lab_f(z / _IMCOLORDIFF_D65_Z)

    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)
end

imcolordiff_rgb_unit(v::Float64, ::Type{UInt8}) = v / 255
imcolordiff_rgb_unit(v::Float64, ::Type{UInt16}) = v / 65535
imcolordiff_rgb_unit(v::Float64, ::Type) = v

function imcolordiff_srgb_to_linear(c::Float64)
    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055)^2.4
end

function imcolordiff_lab_f(t::Float64)
    return t > _IMCOLORDIFF_EPSILON ? cbrt(t) : (_IMCOLORDIFF_KAPPA * t + 16) / 116
end

function imcolordiff_deltaE94_pixel(L1, a1, b1, L2, a2, b2, kL, kC, kH, K1, K2)
    dL = L1 - L2
    C1s = hypot(a1, b1)
    C2s = hypot(a2, b2)
    dCab = C1s - C2s
    da = a1 - a2
    db = b1 - b2
    dHab = da * da + db * db - dCab * dCab
    SC = 1 + K1 * C1s
    SH = 1 + K2 * C1s
    return sqrt((dL / kL)^2 + (dCab / (kC * SC))^2 + dHab / (kH * SH)^2)
end

function imcolordiff_deltaE2000_pixel(L1, a1, b1, L2, a2, b2, kL, kC, kH, K1, K2)
    C1 = hypot(a1, b1)
    C2 = hypot(a2, b2)
    Cbar = (C1 + C2) / 2
    Cbar7 = Cbar^7
    G = 0.5 * (1 - sqrt(Cbar7 / (Cbar7 + 25.0^7)))
    a1d = (1 + G) * a1
    a2d = (1 + G) * a2
    C1d = hypot(a1d, b1)
    C2d = hypot(a2d, b2)

    h1 = atan(b1, a1d)
    h2 = atan(b2, a2d)
    h1 < 0 && (h1 += 2pi)
    h2 < 0 && (h2 += 2pi)
    (a1d == 0 && b1 == 0) && (h1 = 0.0)
    (a2d == 0 && b2 == 0) && (h2 = 0.0)

    dL = L2 - L1
    dC = C2d - C1d
    hsub = h2 - h1
    dh = if C1d * C2d == 0
        0.0
    elseif abs(hsub) <= pi
        hsub
    elseif hsub > pi
        hsub - 2pi
    else
        hsub + 2pi
    end
    dH = 2 * sqrt(C1d * C2d) * sin(dh / 2)

    Lbar = (L1 + L2) / 2
    Cdbar = (C1d + C2d) / 2
    hadd = h1 + h2
    hbar = if C1d * C2d == 0
        hadd
    elseif abs(hsub) <= pi
        hadd / 2
    elseif hadd < 2pi
        (hadd + 2pi) / 2
    else
        (hadd - 2pi) / 2
    end

    T =
        1 - 0.17 * cos(hbar - _IMCOLORDIFF_RAD30) +
        0.24 * cos(2 * hbar) +
        0.32 * cos(3 * hbar + _IMCOLORDIFF_RAD6) - 0.20 * cos(4 * hbar - _IMCOLORDIFF_RAD63)
    dTheta =
        _IMCOLORDIFF_RAD30 * exp(-((hbar - _IMCOLORDIFF_RAD275) / _IMCOLORDIFF_RAD25)^2)
    Cdbar7 = Cdbar^7
    RC = 2 * sqrt(Cdbar7 / (Cdbar7 + 25.0^7))

    SL = 1 + K2 * (Lbar - 50)^2 / sqrt(20 + (Lbar - 50)^2)
    SC = 1 + K1 * Cdbar
    SH = 1 + K2 * Cdbar * T
    RT = -sin(2 * dTheta) * RC

    c_term = dC / (kC * SC)
    h_term = dH / (kH * SH)
    return sqrt((dL / (kL * SL))^2 + c_term^2 + h_term^2 + RT * c_term * h_term)
end
function deltaE2000(I1, I2, kL, kC, kH, K1, K2)
    L1, a1, b1 = labValues(I1)
    L2, a2, b2 = labValues(I2)

    C1 = sqrt.(a1 .^ 2 + b1 .^ 2)
    C2 = sqrt.(a2 .^ 2 + b2 .^ 2)
    Cbar = (C1 + C2) ./ 2
    G = 0.5 * (1 .- ((sqrt.((Cbar .^ 7) ./ (Cbar .^ 7 .+ 25^7)))))
    a1 = (1 .+ G) .* a1
    a2 = (1 .+ G) .* a2
    C1d = sqrt.(a1 .^ 2 .+ b1 .^ 2)
    C2d = sqrt.(a2 .^ 2 .+ b2 .^ 2)

    h1 = atan.(b1, a1)
    h2 = atan.(b2, a2)

    h1[h1 .< 0] = (h1[h1 .< 0] .+ 2 * pi)
    h2[h2 .< 0] = (h2[h2 .< 0] .+ 2 * pi)
    h1[(a1 .== 0) .& (b1 .== 0)] .= 0
    h2[(a2 .== 0) .& (b2 .== 0)] .= 0

    dL = (L2 - L1)
    dC = (C2d - C1d)
    hsub = h2 - h1
    dh = zeros(size(h2))
    dh[(C1d .* C2d .!= 0) .& (abs.(hsub) .<= pi)] = hsub[(C1d .* C2d .!= 0) .& (abs.(hsub) .<= pi)]
    dh[(C1d .* C2d .!= 0) .& (hsub .> pi)] =
        hsub[(C1d .* C2d .!= 0) .& (hsub .> pi)] .- 2 * pi
    dh[(C1d .* C2d .!= 0) .& (hsub .< -pi)] =
        hsub[(C1d .* C2d .!= 0) .& (hsub .< -pi)] .+ 2 * pi
    dh[C1d .* C2d .== 0] .= 0
    dH = 2 * sqrt.(C1d .* C2d) .* sin.(dh ./ 2)

    Lbar = (L1 + L2) ./ 2
    Cdbar = (C1d + C2d) ./ 2
    hadd = h1 + h2
    hbar = zeros(size(h1))
    hbar[(abs.(hsub) .<= pi) .& (C1d .* C2d .!= 0)] =
        hadd[(abs.(hsub) .<= pi) .& (C1d .* C2d .!= 0)] ./ 2
    hbar[(abs.(hsub) .> pi) .& (hadd .< 2 * pi) .& (C1d .* C2d .!= 0)] =
        (hadd[(abs.(hsub) .> pi) .& (hadd .< 2 * pi) .& (C1d .* C2d .!= 0)] .+ 2 * pi) ./ 2
    hbar[(abs.(hsub) .> pi) .& (hadd .>= 2 * pi) .& (C1d .* C2d .!= 0)] =
        (hadd[(abs.(hsub) .> pi) .& (hadd .>= 2 * pi) .& (C1d .* C2d .!= 0)] .- 2 * pi) ./ 2
    hbar[C1d .* C2d .== 0] = hadd[C1d .* C2d .== 0]
    T =
        1 .- 0.17 * cos.(hbar .- deg2rad(30)) .+ 0.24 * cos.(2 * hbar) .+
        0.32 * cos.(3 * hbar .+ deg2rad(6)) .- 0.20 * cos.(4 * hbar .- deg2rad(63))
    dTheta = deg2rad(30) * exp.(-((hbar .- deg2rad(275)) ./ deg2rad(25)) .^ 2)
    RC = 2 * sqrt.((Cdbar .^ 7) ./ (Cdbar .^ 7 .+ 25^7))

    SL = 1 .+ ((K2 * (Lbar .- 50) .^ 2) ./ (sqrt.(20 .+ (Lbar .- 50) .^ 2)))
    SC = 1 .+ (K1 * Cdbar)
    SH = 1 .+ (K2 * Cdbar .* T)
    RT = -sin.(2 * dTheta) .* RC

    dE =
        sqrt.(
            (dL ./ (kL * SL)) .^ 2 +
            (dC ./ (kC * SC)) .^ 2 +
            (dH ./ (kH * SH)) .^ 2 +
            (RT .* ((dC ./ (kC * SC)) .* (dH ./ (kH * SH)))),
        )

    return dE
end

function deltaE94(I1, I2, kL, kC, kH, K1, K2)
    L1, a1, b1 = labValues(I1)
    L2, a2, b2 = labValues(I2)

    dL = L1 - L2
    C1s = sqrt.(a1 .^ 2 + b1 .^ 2)
    C2s = sqrt.(a2 .^ 2 + b2 .^ 2)
    dCab = C1s - C2s

    dHab = (a1 - a2) .^ 2 + (b1 - b2) .^ 2 - dCab .^ 2
    SL = 1
    SC = 1 .+ (K1) .* C1s
    SH = 1 .+ (K2) .* C1s

    dE =
        sqrt.(
            (dL ./ ((kL) .* SL)) .^ 2 +
            (dCab ./ ((kC) .* SC)) .^ 2 +
            (dHab) ./ (kH .* SH) .^ 2
        )

    return dE
end

function labValues(I)
    out_size = [size(I)...]
    if length(out_size) < 3
        push!(out_size, 1)
    end
    out_size[3] = 1
    L = reshape(I[:, :, 1, :], out_size...)
    a = reshape(I[:, :, 2, :], out_size...)
    b = reshape(I[:, :, 3, :], out_size...)

    return L, a, b
end

precompile(imcolordiff, (Array{UInt8,3}, Array{UInt8,3}))
precompile(
    Tuple{
        typeof(Core.kwcall),
        NamedTuple{(:isInputLab,),Tuple{Bool}},
        typeof(imcolordiff),
        Array{Float64,3},
        Array{Float64,3},
    },
)
precompile(
    Tuple{
        typeof(Core.kwcall),
        NamedTuple{(:Standard,),Tuple{String}},
        typeof(imcolordiff),
        Matrix{UInt8},
        Matrix{UInt8},
    },
)
precompile(
    Tuple{
        typeof(Core.kwcall),
        NamedTuple{(:Standard, :kL, :K1, :K2),Tuple{String,Int64,Float64,Float64}},
        typeof(imcolordiff),
        Array{UInt8,3},
        Array{UInt8,3},
    },
)
