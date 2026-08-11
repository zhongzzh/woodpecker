"""
    peaksnr = psnr(A, ref[, peakval]; DataFormat="")
    peaksnr, snr = psnr(A, ref[, peakval]; nargout=2, DataFormat="")

Compute the peak signal-to-noise ratio between `A` and the reference array `ref`.
`A` and `ref` must have the same size and element type. When `DataFormat`
contains a `B` dimension, one result is returned for each batch element.
"""
function psnr(
    src1::AbstractArray{T},
    ref::AbstractArray{T},
    peakval::Real=_psnr_peakval(T);
    nargout::Union{Nothing,Integer}=nothing,
    DataFormat::Union{Nothing,AbstractString}=nothing,
) where {T<:Union{MInteger,MFloat}}
    size(src1) != size(ref) && _psnr_size_error()
    return_snr = if isnothing(nargout)
        false
    else
        nargout in (1, 2) || throw(ArgumentError("nargout must be 1 or 2."))
        nargout == 2
    end
    (!isnan(peakval) && peakval >= 0) ||
        throw(ArgumentError("peakval must be a nonnegative scalar other than NaN."))
    batchdim = _psnr_batchdim(DataFormat, ndims(src1))
    if isempty(src1)
        result = _psnr_empty_result(src1, DataFormat)
        return return_snr ? (result, copy(result)) : result
    end
    return _psnr(src1, ref, peakval, batchdim, Val(return_snr))
end

@noinline function _psnr_size_error()
    return error(
        _msg(
            @tr("Input image 1 and input image 2 must have the same size."),
            splitext(basename(@__FILE__))[1],
        ),
    )
end

@inline _psnr_peakval(::Type{UInt8}) = 255.0
@inline _psnr_peakval(::Type{UInt16}) = 65535.0
@inline _psnr_peakval(::Type{Int16}) = 65535.0
@inline _psnr_peakval(::Type{<:AbstractFloat}) = 1.0

function _psnr(
    src1::AbstractArray{T},
    ref::AbstractArray{T},
    peakval::Real,
    ::Nothing,
    ::Val{ReturnSnr},
) where {T,ReturnSnr}
    outtype = T === Float32 ? Float32 : Float64
    peak = outtype(peakval)
    err_sum, signal_sum = _psnr_sums(src1, ref, outtype, Val(ReturnSnr))
    err = err_sum / outtype(length(src1))
    peaksnr = 10 * log10(peak^2 / err)
    return if ReturnSnr
        (peaksnr, 10 * log10(signal_sum / outtype(length(ref)) / err))
    else
        peaksnr
    end
end

function _psnr(
    src1::AbstractArray{T},
    ref::AbstractArray{T},
    peakval::Real,
    batchdim::Integer,
    ::Val{ReturnSnr},
) where {T,ReturnSnr}
    outtype = T === Float32 ? Float32 : Float64
    peak = outtype(peakval)
    result_size = ntuple(dim -> dim == batchdim ? size(src1, dim) : 1, ndims(src1))
    peaksnr = Array{outtype}(undef, result_size)
    snr = ReturnSnr ? Array{outtype}(undef, result_size) : nothing
    for batch in axes(src1, batchdim)
        src_batch = Base.selectdim(src1, batchdim, batch)
        ref_batch = Base.selectdim(ref, batchdim, batch)
        err_sum, signal_sum = _psnr_sums(src_batch, ref_batch, outtype, Val(ReturnSnr))
        err = err_sum / outtype(length(src_batch))
        out_index = ntuple(dim -> dim == batchdim ? batch : 1, ndims(src1))
        peaksnr[out_index...] = 10 * log10(peak^2 / err)
        ReturnSnr &&
            (snr[out_index...] = 10 * log10(signal_sum / outtype(length(ref_batch)) / err))
    end
    return ReturnSnr ? (peaksnr, snr) : peaksnr
end

function _psnr_sums(
    src1::AbstractArray, ref::AbstractArray, ::Type{R}, ::Val{false}
) where {R<:AbstractFloat}
    err_sum = zero(R)
    @inbounds @simd for index in eachindex(src1, ref)
        difference = R(src1[index]) - R(ref[index])
        err_sum += difference * difference
    end
    return err_sum, zero(R)
end

function _psnr_sums(
    src1::AbstractArray, ref::AbstractArray, ::Type{R}, ::Val{true}
) where {R<:AbstractFloat}
    err_sum = zero(R)
    signal_sum = zero(R)
    @inbounds @simd for index in eachindex(src1, ref)
        reference = R(ref[index])
        difference = R(src1[index]) - reference
        err_sum += difference * difference
        signal_sum += reference * reference
    end
    return err_sum, signal_sum
end

_psnr_batchdim(::Nothing, ::Integer) = nothing

function _psnr_batchdim(dataformat::AbstractString, ndim::Integer)
    isempty(dataformat) && return nothing
    length(dataformat) == ndim ||
        throw(ArgumentError("DataFormat must have one label per input dimension."))
    all(label -> label in ('S', 'C', 'B'), dataformat) ||
        throw(ArgumentError("DataFormat labels must be S, C, or B."))
    count(==('C'), dataformat) <= 1 ||
        throw(ArgumentError("DataFormat can contain at most one C dimension."))
    count(==('B'), dataformat) <= 1 ||
        throw(ArgumentError("DataFormat can contain at most one B dimension."))
    index = findfirst(==('B'), dataformat)
    return isnothing(index) ? nothing : index
end

function _psnr_empty_result(src::AbstractArray{T}, ::Nothing) where {T}
    ndims(src) == 1 && return Vector{T}(undef, 0)
    return Matrix{T}(undef, 0, 0)
end

function _psnr_empty_result(src::AbstractArray{T}, dataformat::AbstractString) where {T}
    ndim = ndims(src)
    ndim == 1 && return Vector{T}(undef, 0)
    isempty(dataformat) && return Matrix{T}(undef, 0, 0)

    label_order = Dict('S' => 1, 'C' => 2, 'B' => 3)
    permutation = sortperm(collect(dataformat); by=label -> label_order[label])
    result_size = ones(Int, ndim)
    for internal_dim in 1:min(2, ndim)
        result_size[permutation[internal_dim]] = 0
    end
    return Array{T}(undef, Tuple(result_size))
end
