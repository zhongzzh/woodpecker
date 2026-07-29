"""
graydiffweight - 基于灰度强度差异为图像像素计算权重

W = graydiffweight(I,refGrayVal)

W = graydiffweight(I,mask)

W = graydiffweight(I,C,R)

W = graydiffweight(V,C,R,P)

W = graydiffweight(___; Name,Value)
"""
const GrayDiffWeightImageType = Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,Float32,Float64}

function graydiffweight(
    I::AbstractArray{T},
    refGrayVal::Real;
    RolloffFactor::Real=0.5,
    GrayDifferenceCutoff::Real=Inf,
) where {T<:GrayDiffWeightImageType}
    graydiffweight_validate_image(I)
    graydiffweight_validate_ref_gray_val(refGrayVal)
    rolloffFactor, grayDiffCutoff = graydiffweight_validate_name_values(
        RolloffFactor, GrayDifferenceCutoff
    )
    return graydiffweight_compute(I, Float64(refGrayVal), rolloffFactor, grayDiffCutoff)
end

function graydiffweight(
    I::AbstractArray{T},
    mask::AbstractArray{Bool};
    RolloffFactor::Real=0.5,
    GrayDifferenceCutoff::Real=Inf,
) where {T<:GrayDiffWeightImageType}
    graydiffweight_validate_image(I)
    refGrayVal = graydiffweight_ref_from_mask(I, mask)
    rolloffFactor, grayDiffCutoff = graydiffweight_validate_name_values(
        RolloffFactor, GrayDifferenceCutoff
    )
    return graydiffweight_compute(I, refGrayVal, rolloffFactor, grayDiffCutoff)
end

function graydiffweight(
    I::AbstractArray{T},
    C::Union{Real,AbstractArray{<:Real}},
    R::Union{Real,AbstractArray{<:Real}};
    RolloffFactor::Real=0.5,
    GrayDifferenceCutoff::Real=Inf,
) where {T<:GrayDiffWeightImageType}
    graydiffweight_validate_image(I)
    refGrayVal = graydiffweight_ref_from_cr(I, C, R)
    rolloffFactor, grayDiffCutoff = graydiffweight_validate_name_values(
        RolloffFactor, GrayDifferenceCutoff
    )
    return graydiffweight_compute(I, refGrayVal, rolloffFactor, grayDiffCutoff)
end

function graydiffweight(
    V::AbstractArray{T,3},
    C::Union{Real,AbstractArray{<:Real}},
    R::Union{Real,AbstractArray{<:Real}},
    P::Union{Real,AbstractArray{<:Real}};
    RolloffFactor::Real=0.5,
    GrayDifferenceCutoff::Real=Inf,
) where {T<:GrayDiffWeightImageType}
    refGrayVal = graydiffweight_ref_from_crp(V, C, R, P)
    rolloffFactor, grayDiffCutoff = graydiffweight_validate_name_values(
        RolloffFactor, GrayDifferenceCutoff
    )
    return graydiffweight_compute(V, refGrayVal, rolloffFactor, grayDiffCutoff)
end

function graydiffweight_validate_image(I)
    if ndims(I) > 3
        error(
            _msg(
                @tr("First input, I, must be three-dimensional."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    return nothing
end

function graydiffweight_validate_ref_gray_val(refGrayVal::Real)
    if isnan(refGrayVal)
        error(
            _msg(
                @tr("Invalid value for 'refGrayVal'. refGrayVal must be non-NaN."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    return nothing
end

function graydiffweight_validate_name_values(RolloffFactor, GrayDifferenceCutoff)
    validateRollOffFactor(RolloffFactor)
    validateGrayDiffCutoff(GrayDifferenceCutoff)
    return Float64(RolloffFactor), Float64(GrayDifferenceCutoff)
end

function graydiffweight_ref_from_mask(I, mask::AbstractArray{Bool})
    if !isequal(size(mask), size(I))
        error(
            _msg(
                @tr("I and MASK must have the same size."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    total = 0.0
    count = 0
    @inbounds for idx in eachindex(I, mask)
        if mask[idx]
            total += Float64(I[idx])
            count += 1
        end
    end

    if count == 0
        error(
            _msg(
                @tr("At least one element of MASK must be true."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    return total / count
end

@inline graydiffweight_seed_length(seed::Real) = 1
@inline graydiffweight_seed_length(seed) = length(seed)
@inline graydiffweight_seed_value(seed::Real, ::Integer) = seed
@inline graydiffweight_seed_value(seed, i::Integer) = seed[i]

function graydiffweight_validate_seed_fast(seed)
    if !(ty_isnumeric(seed) && eltype(seed) != Bool)
        error(_msg(@tr("Input must be numeric."), splitext(basename(@__FILE__))[1]))
    end
    @inbounds for v in seed
        if !isinteger(v)
            error(
                _msg(
                    @tr("Input must contain integer values."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end
    if !(isvector(seed))
        error(_msg(@tr("Input must be a vector."), splitext(basename(@__FILE__))[1]))
    end
    return nothing
end

function graydiffweight_ref_from_cr(I, C, R)
    graydiffweight_validate_seed_fast(C)
    graydiffweight_validate_seed_fast(R)
    nseeds = graydiffweight_seed_length(C)
    if graydiffweight_seed_length(R) != nseeds
        error(
            _msg(
                @tr("C and R must have the same number of elements."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    nrows = size(I, 1)
    ncols = size(I, 2)
    total = 0.0
    @inbounds for i in 1:nseeds
        c = Int(graydiffweight_seed_value(C, i))
        r = Int(graydiffweight_seed_value(R, i))
        if r < 1 || r > nrows
            error(
                _msg(
                    @tr("R must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if c < 1 || c > ncols
            error(
                _msg(
                    @tr("C must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        total += Float64(I[r + (c - 1) * nrows])
    end
    return total / nseeds
end

function graydiffweight_ref_from_crp(V::AbstractArray{<:Real,3}, C, R, P)
    graydiffweight_validate_seed_fast(C)
    graydiffweight_validate_seed_fast(R)
    graydiffweight_validate_seed_fast(P)
    nseeds = graydiffweight_seed_length(C)
    if graydiffweight_seed_length(R) != nseeds || graydiffweight_seed_length(P) != nseeds
        error(
            _msg(
                @tr("C and R must have the same number of elements."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    nrows, ncols, nplanes = size(V)
    planeStride = nrows * ncols
    total = 0.0
    @inbounds for i in 1:nseeds
        c = Int(graydiffweight_seed_value(C, i))
        r = Int(graydiffweight_seed_value(R, i))
        p = Int(graydiffweight_seed_value(P, i))
        if r < 1 || r > nrows
            error(
                _msg(
                    @tr("R must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if c < 1 || c > ncols
            error(
                _msg(
                    @tr("C must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if p < 1 || p > nplanes
            error(
                _msg(
                    @tr("P must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        total += Float64(V[r + (c - 1) * nrows + (p - 1) * planeStride])
    end
    return total / nseeds
end

function graydiffweight_compute(
    I::AbstractArray{T},
    refGrayVal::Float64,
    rolloffFactor::Float64,
    grayDiffCutoff::Float64,
) where {T}
    OutT = T == Float32 ? Float32 : Float64
    W = Array{OutT}(undef, size(I))
    isempty(I) && return W

    minDiff = Inf
    maxDiff = -Inf
    hasNaN = false
    @inbounds for v in I
        diff = abs(Float64(v) - refGrayVal)
        if isnan(diff)
            hasNaN = true
            break
        end
        if diff < minDiff
            minDiff = diff
        end
        if diff > maxDiff
            maxDiff = diff
        end
    end

    if hasNaN
        minDiff = NaN
        maxDiff = NaN
    end

    spread = maxDiff - minDiff
    doScale = spread > eps(min(abs(minDiff), abs(maxDiff)))
    if !doScale
        @warn(@tr("Warning: input data is padded with zeros up to working precision."))
    end

    scale = doScale ? 0.999 / spread : 1.0
    cutoffEnabled = !isinf(grayDiffCutoff)
    power = 1.0 / rolloffFactor
    useSquare = power == 2.0

    @inbounds for idx in eachindex(I)
        diff = abs(Float64(I[idx]) - refGrayVal)
        scaled = if doScale
            0.001 + scale * (diff - minDiff)
        else
            diff
        end
        if cutoffEnabled && diff > grayDiffCutoff
            scaled = 1.0
        end
        weight = useSquare ? 1.0 / (scaled * scaled) : 1.0 / (scaled^power)
        W[idx] = OutT(weight)
    end
    return W
end

function graydiffweight(In...; RolloffFactor::Real=0.5, GrayDifferenceCutoff::Real=Inf)
    varargin = In

    I, refGrayVal, rolloffFactor, grayDiffCutoff = graydiffweight_parse_inputs(
        varargin; RolloffFactor, GrayDifferenceCutoff
    )

    if eltype(I) <: Integer
        I = Float64.(I)
    end
    if isempty(I)
        W = I
        return W
    end

    W = abs.(I .- refGrayVal)

    if !isinf(grayDiffCutoff)
        isSuppressed = W .> grayDiffCutoff
    end
    W, = images_internal_imlinscale(W, [1e-3 1])
    if !isinf(grayDiffCutoff)
        W[isSuppressed] .= 1
    end

    W = 1 ./ (W .^ (1 ./ rolloffFactor))

    return eltype(I) == Float32 ? Float32.(W) : Float64.(W)
end

function graydiffweight_parse_inputs(varargin; RolloffFactor, GrayDifferenceCutoff)
    nargin = length(varargin)
    validImageTypes = [UInt8, Int8, UInt16, Int16, UInt32, Int32, Float32, Float64]

    I = varargin[1]
    if eltype(I) ∉ validImageTypes
        error(
            _msg(
                @tr(
                    "First input, I, must be one of the following types:\n\nUInt8, Int8, UInt16, Int16, UInt32, Int32, Float32, Float64\n\nbut its type was %{1}.",
                    eltype(I)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if ndims(I) > 3
        error(
            _msg(
                @tr("First input, I, must be three-dimensional."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if isempty(varargin[2])
        error(_msg(@tr("refGrayVal must not be empty."), splitext(basename(@__FILE__))[1]))
    end

    isArg2Numeric = ty_isnumeric(varargin[2]) && eltype(varargin[2]) != Bool
    isArg2Logical = eltype(varargin[2]) == Bool

    if isArg2Logical
        typeOfSyntax = "MaskSyntax"

    elseif isArg2Numeric
        if (
            (nargin > 3) &&
            (ty_isnumeric(varargin[3]) && eltype(varargin[3]) != Bool) &&
            (ty_isnumeric(varargin[4]) && eltype(varargin[4]) != Bool)
        )
            typeOfSyntax = "CRPSyntax"

        elseif ((nargin > 2) && (ty_isnumeric(varargin[3]) && eltype(varargin[3]) != Bool))
            typeOfSyntax = "CRSyntax"

        else
            typeOfSyntax = "RefGrayValSyntax"
        end

    else
        error(
            _msg(
                @tr(
                    "Invalid value for second argument. graydiffweight requires second argument to be numeric or logical."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if typeOfSyntax == "RefGrayValSyntax"
        refGrayVal = varargin[2]
        validateRefGrayVal(refGrayVal)

        refGrayVal = Float64.(refGrayVal)

    elseif typeOfSyntax == "MaskSyntax"
        mask = varargin[2]

        if isequal(size(mask), size(I))
            if all(mask[:] .== false)
                error(
                    _msg(
                        @tr("At least one element of MASK must be true."),
                        splitext(basename(@__FILE__))[1],
                    ),
                )
            else
                refGrayVal = mean(I[mask])
            end
        else
            error(
                _msg(
                    @tr("I and MASK must have the same size."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

    elseif typeOfSyntax == "CRSyntax"
        C = varargin[2]
        R = varargin[3]
        validateSeed(C)
        validateSeed(R)

        if !isequal(length(R), length(C))
            error(
                _msg(
                    @tr("C and R must have the same number of elements."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        C = Int.(C)
        R = Int.(R)

        nrows, ncols = size(I)
        isRinValidRange = all((R .>= 1) .& (R .<= nrows))
        isCinValidRange = all((C .>= 1) .& (C .<= ncols))

        if !isRinValidRange
            error(
                _msg(
                    @tr("R must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !isCinValidRange
            error(
                _msg(
                    @tr("C must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        refGrayVal = mean(I[sub2ind([nrows ncols], R, C)])

    elseif typeOfSyntax == "CRPSyntax"
        C = varargin[2]
        R = varargin[3]
        P = varargin[4]
        validateSeed(C)
        validateSeed(R)
        validateSeed(P)

        C = Int.(C)
        R = Int.(R)
        P = Int.(P)

        if !isequal(length(R), length(C)) || !isequal(length(R), length(P))
            error(
                _msg(
                    @tr("C and R must have the same number of elements."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        nrows, ncols, nplanes = size(I)
        isRinValidRange = all((R .>= 1) .& (R .<= nrows))
        isCinValidRange = all((C .>= 1) .& (C .<= ncols))
        isPinValidRange = all((P .>= 1) .& (P .<= nplanes))

        if !isRinValidRange
            error(
                _msg(
                    @tr("R must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !isCinValidRange
            error(
                _msg(
                    @tr("C must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !isPinValidRange
            error(
                _msg(
                    @tr("P must contain valid subscripts."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        refGrayVal = mean(I[sub2ind([nrows ncols nplanes], R, C, P)])

    else
        error(_msg(@tr("Invalid input syntax."), splitext(basename(@__FILE__))[1]))
    end

    rolloffFactor = Float64(RolloffFactor)
    validateRollOffFactor(RolloffFactor)
    grayDiffCutoff = Float64(GrayDifferenceCutoff)
    validateGrayDiffCutoff(GrayDifferenceCutoff)

    return I, refGrayVal, rolloffFactor, grayDiffCutoff
end

function validateRollOffFactor(rolloffFactor)
    if rolloffFactor <= 0
        error(
            _msg(
                @tr("Invalid value for 'RolloffFactor'. RolloffFactor must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isfinite(rolloffFactor)
        error(
            _msg(
                @tr("Invalid value for 'RolloffFactor'. RolloffFactor must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
end

function validateGrayDiffCutoff(grayDiffCutoff)
    if grayDiffCutoff < 0
        error(
            _msg(
                @tr(
                    "Invalid value for 'GrayDifferenceCutoff'. GrayDifferenceCutoff must be nonnegative."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isnan(grayDiffCutoff)
        error(
            _msg(
                @tr(
                    "Invalid value for 'GrayDifferenceCutoff'. GrayDifferenceCutoff must be non-NaN."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
end

function validateRefGrayVal(refGrayVal)
    validImageTypes = [UInt8, Int8, UInt16, Int16, UInt32, Int32, Float32, Float64]
    if eltype(refGrayVal) ∉ validImageTypes
        error(
            _msg(
                @tr(
                    "Invalid value for 'refGrayVal'. refGrayVal must be one of the following types:\n\nUInt8, Int8, UInt16, Int16, UInt32, Int32, Float32, Float64\n\nbut its type was %{1}.",
                    eltype(refGrayVal)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isscalar(refGrayVal)
        error(
            _msg(
                @tr("Invalid value for 'refGrayVal'. refGrayVal must be a scalar."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(refGrayVal)
        error(
            _msg(
                @tr("Invalid value for 'refGrayVal'. refGrayVal must be real."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isnan(refGrayVal)
        error(
            _msg(
                @tr("Invalid value for 'refGrayVal'. refGrayVal must be non-NaN."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
end

function validateSeed(seed)
    if !(ty_isnumeric(seed) && eltype(seed) != Bool)
        error(_msg(@tr("Input must be numeric."), splitext(basename(@__FILE__))[1]))
    end
    if !all(isinteger.(seed))
        error(
            _msg(
                @tr("Input must contain integer values."), splitext(basename(@__FILE__))[1]
            ),
        )
    end
    if !(isvector(seed))
        error(_msg(@tr("Input must be a vector."), splitext(basename(@__FILE__))[1]))
    end
end
try
    precompile(graydiffweight, (Matrix{UInt8}, UInt8))
    precompile(graydiffweight, (Matrix{UInt8}, BitMatrix))
    precompile(graydiffweight, (Matrix{UInt8}, Int64, Int64))
    precompile(
        graydiffweight, (Array{UInt8,3}, Vector{Int64}, Vector{Int64}, Vector{Int64})
    )
    precompile(
        Core.kwcall,
        (
            NamedTuple{(:RolloffFactor, :GrayDifferenceCutoff),Tuple{Float64,Int64}},
            typeof(graydiffweight),
            Matrix{UInt8},
            Int64,
            Int64,
        ),
    )
    precompile(
        Core.kwcall,
        (
            NamedTuple{(:GrayDifferenceCutoff,),Tuple{Int64}},
            typeof(graydiffweight),
            Matrix{UInt8},
            Int64,
            Int64,
        ),
    )
catch _
end
