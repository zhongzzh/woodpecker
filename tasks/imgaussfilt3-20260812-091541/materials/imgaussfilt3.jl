"""
imgaussfilt3 - 三维图像的三维高斯滤波

B = imgaussfilt3(A)

B = imgaussfilt3(A,sigma)

B = imgaussfilt3(___;Name,Value)
"""
function imgaussfilt3(
    A::AbstractArray{<:Real},
    sigma::Union{<:Real,AbstractVecOrMat{<:Real}}=0.5;
    FilterSize::Union{<:Integer,AbstractVecOrMat{<:Integer}}=Int.(
        2 * ceil.(2 * sigma) .+ 1
    ),
    Padding::Union{<:Real,AbstractString}="replicate",
    FilterDomain::AbstractString="auto",
)
    A, sigma, hsize, padding, domain = imgaussfilt3_parseInputs(
        A, sigma, FilterSize, Padding, FilterDomain
    )

    domain = chooseFilterImplementation(A, hsize, domain)

    if domain == "spatial"
        B = imgaussfilt3_spatialGaussianFilter(A, sigma, hsize, padding)
    elseif domain == "frequency"
        B = frequencyGaussianFilter(A, sigma, hsize, padding)
    else
        error(
            _msg(
                @tr("Unknown filter domain; must be 'spatial' or 'frequency'."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return B
end

function imgaussfilt3_spatialGaussianFilter(A, sigma, hsize, padding)
    dtype = eltype(A)

    hCol, hRow, hSlc = imgaussfilt3_createSeparableGaussianKernel(sigma, hsize)

    if dtype ∈ [Int32, UInt32]
        A = Float64.(A)
    elseif dtype ∈ [UInt8, Int8, UInt16, Int16]
        A = Float32.(A)
    elseif dtype ∈ [Float32, Float64]

    else
        error(_msg(@tr("Unknown data type."), splitext(basename(@__FILE__))[1]))
    end

    A = imgaussfilt3_separable_filter(A, hRow, Val(2), padding)
    A = imgaussfilt3_separable_filter(A, hCol, Val(1), padding)
    A = imgaussfilt3_separable_filter(A, hSlc, Val(3), padding)

    if eltype(A) != dtype
        A = imgaussfilt3_cast(A, dtype)
    end

    return A
end

function imgaussfilt3_separable_filter(
    A::AbstractArray{T,3}, h, dim::Val, padding
) where {T}
    kernel = T.(vec(h))
    B = similar(A)
    if padding isa Real
        imgaussfilt3_filter_constant!(B, A, kernel, dim, T(padding))
    elseif padding == "replicate"
        imgaussfilt3_filter_padded!(B, A, kernel, dim, Val(:replicate))
    elseif padding == "circular"
        imgaussfilt3_filter_padded!(B, A, kernel, dim, Val(:circular))
    elseif padding == "symmetric"
        imgaussfilt3_filter_padded!(B, A, kernel, dim, Val(:symmetric))
    else
        error(_msg(@tr("Unsupported padding mode."), splitext(basename(@__FILE__))[1]))
    end
    return B
end

@inline imgaussfilt3_replicate_index(i::Int, n::Int) = clamp(i, 1, n)
@inline imgaussfilt3_circular_index(i::Int, n::Int) = mod1(i, n)

@inline function imgaussfilt3_symmetric_index(i::Int, n::Int)
    n == 1 && return 1
    period = 2n
    r = mod(i - 1, period) + 1
    return r <= n ? r : period - r + 1
end

@inline imgaussfilt3_pad_index(i::Int, n::Int, ::Val{:replicate}) =
    imgaussfilt3_replicate_index(i, n)
@inline imgaussfilt3_pad_index(i::Int, n::Int, ::Val{:circular}) =
    imgaussfilt3_circular_index(i, n)
@inline imgaussfilt3_pad_index(i::Int, n::Int, ::Val{:symmetric}) =
    imgaussfilt3_symmetric_index(i, n)

function imgaussfilt3_filter_padded!(
    B::AbstractArray{T,3}, A::AbstractArray{T,3}, kernel::AbstractVector{T}, ::Val{1}, mode
) where {T}
    m, n, p = size(A)
    radius = length(kernel) ÷ 2
    @inbounds for k3 in 1:p, j in 1:n, i in 1:m
        acc = zero(T)
        for kk in eachindex(kernel)
            ii = imgaussfilt3_pad_index(i + kk - radius - 1, m, mode)
            acc += kernel[kk] * A[ii, j, k3]
        end
        B[i, j, k3] = acc
    end
    return B
end

function imgaussfilt3_filter_padded!(
    B::AbstractArray{T,3}, A::AbstractArray{T,3}, kernel::AbstractVector{T}, ::Val{2}, mode
) where {T}
    m, n, p = size(A)
    radius = length(kernel) ÷ 2
    @inbounds for k3 in 1:p, j in 1:n, i in 1:m
        acc = zero(T)
        for kk in eachindex(kernel)
            jj = imgaussfilt3_pad_index(j + kk - radius - 1, n, mode)
            acc += kernel[kk] * A[i, jj, k3]
        end
        B[i, j, k3] = acc
    end
    return B
end

function imgaussfilt3_filter_padded!(
    B::AbstractArray{T,3}, A::AbstractArray{T,3}, kernel::AbstractVector{T}, ::Val{3}, mode
) where {T}
    m, n, p = size(A)
    radius = length(kernel) ÷ 2
    @inbounds for k3 in 1:p, j in 1:n, i in 1:m
        acc = zero(T)
        for kk in eachindex(kernel)
            z = imgaussfilt3_pad_index(k3 + kk - radius - 1, p, mode)
            acc += kernel[kk] * A[i, j, z]
        end
        B[i, j, k3] = acc
    end
    return B
end

function imgaussfilt3_filter_constant!(
    B::AbstractArray{T,3},
    A::AbstractArray{T,3},
    kernel::AbstractVector{T},
    ::Val{1},
    padval::T,
) where {T}
    m, n, p = size(A)
    radius = length(kernel) ÷ 2
    @inbounds for k3 in 1:p, j in 1:n, i in 1:m
        acc = zero(T)
        for kk in eachindex(kernel)
            ii = i + kk - radius - 1
            acc += kernel[kk] * (1 <= ii <= m ? A[ii, j, k3] : padval)
        end
        B[i, j, k3] = acc
    end
    return B
end

function imgaussfilt3_filter_constant!(
    B::AbstractArray{T,3},
    A::AbstractArray{T,3},
    kernel::AbstractVector{T},
    ::Val{2},
    padval::T,
) where {T}
    m, n, p = size(A)
    radius = length(kernel) ÷ 2
    @inbounds for k3 in 1:p, j in 1:n, i in 1:m
        acc = zero(T)
        for kk in eachindex(kernel)
            jj = j + kk - radius - 1
            acc += kernel[kk] * (1 <= jj <= n ? A[i, jj, k3] : padval)
        end
        B[i, j, k3] = acc
    end
    return B
end

function imgaussfilt3_filter_constant!(
    B::AbstractArray{T,3},
    A::AbstractArray{T,3},
    kernel::AbstractVector{T},
    ::Val{3},
    padval::T,
) where {T}
    m, n, p = size(A)
    radius = length(kernel) ÷ 2
    @inbounds for k3 in 1:p, j in 1:n, i in 1:m
        acc = zero(T)
        for kk in eachindex(kernel)
            z = k3 + kk - radius - 1
            acc += kernel[kk] * (1 <= z <= p ? A[i, j, z] : padval)
        end
        B[i, j, k3] = acc
    end
    return B
end

function imgaussfilt3_cast(A::AbstractArray, ::Type{T}) where {T<:Integer}
    B = Array{T}(undef, size(A))
    lo = typemin(T)
    hi = typemax(T)
    @inbounds @simd for i in eachindex(A, B)
        B[i] = T(TyBaseCore.ty_round(clamp(A[i], lo, hi)))
    end
    return B
end

imgaussfilt3_cast(A::AbstractArray, ::Type{T}) where {T<:AbstractFloat} = T.(A)

function imgaussfilt3_createSeparableGaussianKernel(sigma, hsize)
    isIsotropic = all(sigma .== sigma[1]) && all(hsize .== hsize[1])

    hcol = images_internal_createGaussianKernel(sigma[1], hsize[1])

    if isIsotropic
        hrow = hcol
        hslc = hcol
    else
        hrow = images_internal_createGaussianKernel(sigma[2], hsize[2])
        hslc = images_internal_createGaussianKernel(sigma[3], hsize[3])
    end

    hrow = reshape(hrow, 1, Int(hsize[2]))
    hslc = reshape(hslc, 1, 1, Int(hsize[3]))

    return hcol, hrow, hslc
end

function frequencyGaussianFilter(A, sigma, hsize, padding)
    dtype = eltype(A)
    outSize = ntuple(d -> size(A, d), 3)

    paddedA, padSize = imgaussfilt3_padImage(A, hsize, padding)
    paddedA = Float64.(paddedA)

    hCol, hRow, hSlc = imgaussfilt3_createSeparableGaussianKernel(sigma, hsize)
    h = hCol .* hRow .* hSlc
    fftSize = size(paddedA)
    paddedH = zeros(Float64, fftSize)
    paddedH[1:size(h, 1), 1:size(h, 2), 1:size(h, 3)] .= h
    paddedH = circshift(paddedH, ntuple(d -> -Int(floor(size(h, d) / 2)), 3))

    B = real.(FFTW.ifft(FFTW.fft(paddedA) .* FFTW.fft(paddedH)))

    start = Tuple(Int.(padSize) .+ 1)
    stop = start .+ outSize .- 1
    B = B[start[1]:stop[1], start[2]:stop[2], start[3]:stop[3]]

    if eltype(B) != dtype
        B = imgaussfilt3_cast(B, dtype)
    end

    return B
end

function chooseFilterImplementation(A, hsize, domain)
    ippFlag = false

    if domain == "auto"
        domain = chooseFilterDomain3(A, hsize, ippFlag)
    end

    return domain
end

function imgaussfilt3_padImage(A, hsize, padding)
    padSize = computePadSize(size(A), hsize)

    if typeof(padding) <: AbstractString
        method = padding
        padVal = Float64[]
    else
        method = "constant"
        padVal = padding
    end

    A = images_internal_padarray_algo(A, padSize, method, padVal, "both")

    return A, padSize
end

function computePadSize(sizeA, sizeH)
    rankA = length(sizeA)
    rankH = length(sizeH)
    h = vec(sizeH)
    if rankH < rankA
        h = vcat(h, ones(eltype(h), rankA - rankH))
    end
    return Int.(floor.(h ./ 2))
end

function imgaussfilt3_parseInputs(A, Sigma, FilterSize, Padding, FilterDomain)
    if eltype(A) ∉ [UInt8, UInt16, UInt32, Int8, Int16, Int32, Float32, Float64]
        type_list = "UInt8, UInt16, UInt32, Int8, Int16, Int32, Float32, Float64"
        error(
            _msg(
                @tr(
                    "A must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    type_list,
                    eltype(A)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(A)
        error(_msg(@tr("A must be real."), splitext(basename(@__FILE__))[1]))
    end
    if ndims(A) > 3
        error(_msg(@tr("A must be three-dimensional."), splitext(basename(@__FILE__))[1]))
    end

    Sigma = validateSigma(Sigma)
    FilterSize = images_internal_validateThreeDFilterSize(FilterSize)
    Padding = validatePadding(Padding)
    FilterDomain = validateFilterDomain(FilterDomain)

    return A, Sigma, FilterSize, Padding, FilterDomain
end

function validateSigma(sigma)
    if !isreal(sigma)
        error(_msg(@tr("Sigma must be real."), splitext(basename(@__FILE__))[1]))
    end
    if isempty(sigma)
        error(_msg(@tr("Sigma must be nonempty."), splitext(basename(@__FILE__))[1]))
    end
    if any(sigma .< 0)
        error(_msg(@tr("Sigma must be positive."), splitext(basename(@__FILE__))[1]))
    end
    if any(.!isfinite.(sigma))
        error(_msg(@tr("Sigma must be finite."), splitext(basename(@__FILE__))[1]))
    end

    if isscalar(sigma)
        sigma = [sigma sigma sigma]
    end

    if length(sigma) != 3
        error(
            _msg(
                @tr("Sigma may be a scalar or a 3-element vector."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    sigma = Float64.(sigma)

    return sigma
end

function validatePadding(padding)
    if typeof(padding) != String

    else
        if padding ∉ ["replicate", "circular", "symmetric"]
            error(
                _msg(
                    @tr(
                        "Padding must match one of:\n\n'replicate', 'circular', 'symmetric'\n\nInput '%{1}' does not match any valid value.",
                        padding
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    return padding
end

function validateFilterDomain(filterDomain)
    if filterDomain ∉ ["spatial", "frequency", "auto"]
        error(
            _msg(
                @tr(
                    "FilterDomain must match one of:\n\n'spatial', 'frequency', 'auto'\n\nInput '%{1}' does not match any valid value.",
                    filterDomain
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return filterDomain
end

function images_internal_validateThreeDFilterSize(filterSize_)
    if !(ty_isnumeric(filterSize_) && eltype(filterSize_) != Bool)
        type_list = "Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64"
        error(
            _msg(
                @tr(
                    "filterSize must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    type_list,
                    eltype(filterSize_)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(filterSize_)
        error(_msg(@tr("filterSize must be real."), splitext(basename(@__FILE__))[1]))
    end
    if isempty(filterSize_)
        error(_msg(@tr("filterSize must be nonempty."), splitext(basename(@__FILE__))[1]))
    end
    if any(filterSize_ .<= 0)
        error(_msg(@tr("filterSize must be positive."), splitext(basename(@__FILE__))[1]))
    end
    if !(eltype(filterSize_) <: Integer)
        error(
            _msg(
                @tr("filterSize must contain integer values."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isodd.(filterSize_))
        error(_msg(@tr("filterSize must be odd."), splitext(basename(@__FILE__))[1]))
    end

    if isscalar(filterSize_)
        filterSize = [Float64(filterSize_) Float64(filterSize_) Float64(filterSize_)]
    else
        if length(filterSize_) != 3
            error(
                _msg(
                    @tr("filterSize may be a scalar or a 3-element vector."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        filterSize =
            [Float64(filterSize_[1]) Float64(filterSize_[2]) Float64(filterSize_[3])]
    end

    return filterSize
end

function chooseFilterDomain3(A, hsize, ippFlag)
    bigImageThreshold = 2.5e6
    bigKernelThreshold = 729

    imageIsBig = length(A) >= bigImageThreshold
    kernelIsBig = prod(hsize) >= bigKernelThreshold

    if imageIsBig && kernelIsBig
        domain = "frequency"
    else
        domain = "spatial"
    end

    return domain
end
precompile(imgaussfilt3, (Array{UInt8,3},))
precompile(imgaussfilt3, (Array{UInt8,3}, Int64))
precompile(validateSigma, (Int64,))
precompile(images_internal_validateThreeDFilterSize, (Int64,))
precompile(validatePadding, (String,))
precompile(validateFilterDomain, (String,))
precompile(chooseFilterImplementation, (Array{UInt8,3}, Matrix{Float64}, String))
precompile(chooseFilterDomain3, (Array{UInt8,3}, Matrix{Float64}, Bool))
precompile(imgaussfilt3_createSeparableGaussianKernel, (Matrix{Float64}, Matrix{Float64}))
precompile(images_internal_createGaussianKernel, (Float64, Float64))
precompile(
    imgaussfilt3_spatialGaussianFilter,
    (Array{UInt8,3}, Matrix{Float64}, Matrix{Float64}, String),
)
precompile(
    imgaussfilt3_separable_filter, (Array{Float32,3}, Matrix{Float64}, Val{1}, String)
)
precompile(
    imgaussfilt3_separable_filter, (Array{Float32,3}, Matrix{Float64}, Val{2}, String)
)
precompile(
    imgaussfilt3_separable_filter, (Array{Float32,3}, Array{Float64,3}, Val{3}, String)
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{1}, Val{:replicate}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{2}, Val{:replicate}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{3}, Val{:replicate}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{1}, Val{:symmetric}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{2}, Val{:symmetric}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{3}, Val{:symmetric}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{1}, Val{:circular}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{2}, Val{:circular}),
)
precompile(
    imgaussfilt3_filter_padded!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{3}, Val{:circular}),
)
precompile(
    imgaussfilt3_filter_constant!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{1}, Float32),
)
precompile(
    imgaussfilt3_filter_constant!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{2}, Float32),
)
precompile(
    imgaussfilt3_filter_constant!,
    (Array{Float32,3}, Array{Float32,3}, Vector{Float32}, Val{3}, Float32),
)
precompile(imgaussfilt3_cast, (Array{Float32,3}, Type{UInt8}))
precompile(
    Tuple{
        typeof(Core.kwcall),
        NamedTuple{(:FilterSize, :Padding, :FilterDomain),Tuple{Int64,String,String}},
        typeof(imgaussfilt3),
        Array{UInt8,3},
        Int64,
    },
)
