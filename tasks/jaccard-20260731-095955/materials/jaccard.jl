"""
jaccard - image segmentation Jaccard similarity coefficient

similarity = jaccard(BW1,BW2)

similarity = jaccard(L1,L2)
"""
function jaccard(
    A::AbstractArray{T}, B::AbstractArray{T}
) where {T<:Union{Bool,Float64,Int64}}
    jaccard_validate_common(A, B)

    if T == Bool
        similarity, = images_internal_segmentation_bwjaccard(A, B)
        return similarity
    end

    maxA = jaccard_validate_label_matrix(A, Val(:A))
    maxB = jaccard_validate_label_matrix(B, Val(:B))
    nclasses = Int(max(maxA, maxB))
    return jaccard_label_similarity(A, B, nclasses)
end

function jaccard_validate_common(A, B)
    if TyBaseCore.isempty(A)
        error(
            _msg(@tr("First input, A, must be nonempty."), splitext(basename(@__FILE__))[1])
        )
    end

    if TyBaseCore.isempty(B)
        error(
            _msg(
                @tr("Second input, B, must be nonempty."), splitext(basename(@__FILE__))[1]
            ),
        )
    end

    if size(A) != size(B)
        error(
            _msg(@tr("A and B must have the same size."), splitext(basename(@__FILE__))[1])
        )
    end

    if eltype(A) != eltype(B)
        error(
            _msg(@tr("A and B must have the same class."), splitext(basename(@__FILE__))[1])
        )
    end
    return nothing
end

function jaccard_validate_label_matrix(A::AbstractArray{Int64}, ::Val{:A})
    maxLabel = 0
    @inbounds for value in A
        if value < 0
            error(
                _msg(
                    @tr("First input, L1, must be nonnegative."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if value > maxLabel
            maxLabel = value
        end
    end
    return maxLabel
end

function jaccard_validate_label_matrix(B::AbstractArray{Int64}, ::Val{:B})
    maxLabel = 0
    @inbounds for value in B
        if value < 0
            error(
                _msg(
                    @tr("Second input, L2, must be nonnegative."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if value > maxLabel
            maxLabel = value
        end
    end
    return maxLabel
end

function jaccard_validate_label_matrix(A::AbstractArray{Float64}, ::Val{:A})
    maxLabel = 0.0
    @inbounds for value in A
        if !TyBaseCore.isfinite(value)
            error(
                _msg(
                    @tr("First input, L1, must be finite."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if value < 0
            error(
                _msg(
                    @tr("First input, L1, must be nonnegative."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !isinteger(value)
            error(
                _msg(
                    @tr("First input, L1, must be an integer value."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if value > maxLabel
            maxLabel = value
        end
    end
    return maxLabel
end

function jaccard_validate_label_matrix(B::AbstractArray{Float64}, ::Val{:B})
    maxLabel = 0.0
    @inbounds for value in B
        if !TyBaseCore.isfinite(value)
            error(
                _msg(
                    @tr("Second input, L2, must be finite."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if value < 0
            error(
                _msg(
                    @tr("Second input, L2, must be nonnegative."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if !isinteger(value)
            error(
                _msg(
                    @tr("Second input, L2, must be an integer value."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if value > maxLabel
            maxLabel = value
        end
    end
    return maxLabel
end

@inline jaccard_label_index(value::Int64) = value
@inline jaccard_label_index(value::Float64) = Int(value)

function jaccard_label_similarity(
    A::AbstractArray{T}, B::AbstractArray{T}, nclasses::Int
) where {T}
    inter = zeros(Int, nclasses)
    union = zeros(Int, nclasses)

    @inbounds for idx in eachindex(A, B)
        a = jaccard_label_index(A[idx])
        b = jaccard_label_index(B[idx])
        if a == b
            if a > 0
                inter[a] += 1
                union[a] += 1
            end
        else
            if a > 0
                union[a] += 1
            end
            if b > 0
                union[b] += 1
            end
        end
    end

    similarity = Matrix{Float64}(undef, nclasses, 1)
    @inbounds for k in 1:nclasses
        similarity[k, 1] = inter[k] / union[k]
    end
    return similarity
end

function images_internal_segmentation_bwjaccard(A, B)
    inter = 0
    union = 0
    @inbounds for idx in eachindex(A, B)
        a = A[idx]
        b = B[idx]
        if a & b
            inter += 1
            union += 1
        elseif a | b
            union += 1
        end
    end
    similarity = inter / union

    return similarity, inter, union
end

function images_internal_segmentation_convertToCellOfLogicals(A, classes)
    num_class = length(classes)
    C = Matrix(undef, num_class, 1)
    for k in 1:num_class
        C[k] = (A .== classes[k])
    end

    return C
end

try
    precompile(jaccard, (BitMatrix, BitMatrix))
    precompile(jaccard, (Matrix{Bool}, Matrix{Bool}))
    precompile(jaccard, (Matrix{Int64}, Matrix{Int64}))
    precompile(jaccard, (Matrix{Float64}, Matrix{Float64}))
catch _
end
