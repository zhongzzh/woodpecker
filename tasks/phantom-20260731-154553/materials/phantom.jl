"""
phantom - 创建头部幻影图像

P, = phantom(def,n)

P, = phantom(E,n)

P,E = phantom(___)
"""
function phantom(In...)
    varargin = In
    return internal_phantom(varargin)
end

function internal_phantom(varargin)
    ellipse, n = phantom_parse_inputs(varargin)

    p = zeros(n, n)

    xax = reshape(collect((0:(n - 1)) .- (n - 1) / 2) / ((n - 1) / 2), 1, n)
    xg = repeat(xax, n, 1)

    for k in 1:size(ellipse, 1)
        asq = ellipse[k, 2]^2
        bsq = ellipse[k, 3]^2
        phi = ellipse[k, 6] * pi / 180
        x0 = ellipse[k, 4]
        y0 = ellipse[k, 5]
        A = ellipse[k, 1]
        x = xg .- x0
        y = rotl90(xg) .- y0
        cosp = cos.(phi)
        sinp = sin.(phi)
        idx = find(
            ((x .* cosp .+ y .* sinp) .^ 2) ./ asq .+
            ((y .* cosp .- x .* sinp) .^ 2) ./ bsq .<= 1,
        )
        p[idx] = p[idx] .+ A
    end

    return p, ellipse
end

function phantom_parse_inputs(varargin)
    n = 256
    e = Float64[]
    defaults = ["shepp-logan", "modified shepp-logan"]

    for i in 1:length(varargin)
        if typeof(varargin[i]) == String
            def = lowercase(varargin[i])
            idx = find(def .== defaults)
            if TyBaseCore.isempty(idx)
                error(
                    _msg(
                        @tr("Unknown default phantom selected."),
                        splitext(basename(@__FILE__))[1],
                    ),
                )
            end
            if defaults[idx[1]] == "shepp-logan"
                e = shepp_logan()
            elseif defaults[idx[1]] == "modified shepp-logan"
                e = modified_shepp_logan()
            end
        elseif length(varargin[i]) == 1
            n = varargin[i]
        elseif ndims(varargin[i]) == 2 && size(varargin[i], 2) == 6
            e = varargin[i]
        else
            error(_msg(@tr("Invalid input parameters."), splitext(basename(@__FILE__))[1]))
        end
    end

    if isempty(e)
        e = modified_shepp_logan()
    end

    return e, n
end

function shepp_logan()
    shep = [
        1 0.69 0.92 0 0 0
        -0.98 0.6624 0.8740 0 -0.0184 0
        -0.02 0.1100 0.3100 0.22 0 -18
        -0.02 0.1600 0.4100 -0.22 0 18
        0.01 0.2100 0.2500 0 0.35 0
        0.01 0.0460 0.0460 0 0.1 0
        0.01 0.0460 0.0460 0 -0.1 0
        0.01 0.0460 0.0230 -0.08 -0.605 0
        0.01 0.0230 0.0230 0 -0.606 0
        0.01 0.0230 0.0460 0.06 -0.605 0
    ]
    return shep
end

function modified_shepp_logan()
    toft = [
        1 0.69 0.92 0 0 0
        -0.8 0.6624 0.8740 0 -0.0184 0
        -0.2 0.1100 0.3100 0.22 0 -18
        -0.2 0.1600 0.4100 -0.22 0 18
        0.1 0.2100 0.2500 0 0.35 0
        0.1 0.0460 0.0460 0 0.1 0
        0.1 0.0460 0.0460 0 -0.1 0
        0.1 0.0460 0.0230 -0.08 -0.605 0
        0.1 0.0230 0.0230 0 -0.606 0
        0.1 0.0230 0.0460 0.06 -0.605 0
    ]
    return toft
end
