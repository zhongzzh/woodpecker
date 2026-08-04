"""
imsegkmeans - 基于 K 均值聚类的图像分割

L, = imsegkmeans(I,k)

L,centers = imsegkmeans(I,k)

L, = imsegkmeans(I,k;Name=Value)
"""
function imsegkmeans(
    I::AbstractArray,
    k::Real;
    NormalizeInput::Bool=true,
    NumAttempts::Real=3,
    MaxIterations::Real=100,
    Threshold::Real=0.0001,
)
    @ccall_check_func_lic :TyImageProcessing
    L, Centers = algkmeans(
        I, k, "imsegkmeans", NormalizeInput, NumAttempts, MaxIterations, Threshold
    )

    return L, Centers
end

function algkmeans(Inp, k, filename, NormalizeInput, NumAttempts, MaxIterations, Threshold)
    Inp, k, NormalizeInput, NumAttempts, MaxIterations, Threshold = algkmeans_ParseInputs(
        Inp, k, filename, NormalizeInput, NumAttempts, MaxIterations, Threshold
    )

    classInp = eltype(Inp)
    if classInp != Float32
        Inp = Float32.(Inp)
    end

    if TyBaseCore.strcmp(filename, "imsegkmeans")
        if ndims(Inp) == 2
            m, n = size(Inp)
            c = 1
        elseif ndims(Inp) == 3
            m, n, c = size(Inp)
        end
        p = 1
        X = reshape(Inp, m * n, c)

    else
        TyBaseCore.strcmp(filename, "imsegkmeans3")
        m, n, p = size(Inp)
        c = 1
        X = reshape(Inp, m * n * p, c)
    end

    avgChn = zeros(1, c)
    stdDevChn = ones(1, c)
    if NormalizeInput
        X, avgChn, stdDevChn = normInp(X)
    end

    if size(X, 1) < k
        error(
            _msg(
                @tr("Number of clusters exceeds input size."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if m == 1 && n == 1 && p == 1
        Label = [1.0;;]
        NormCen = zeros(eltype(X), size(X))
    else
        Label, NormCen = internal_ocvkmeans(X, k, NumAttempts, MaxIterations, Threshold)
    end
    Centers = denormalizeCenters(NormCen, avgChn, stdDevChn)
    if classInp <: Integer
        Centers = TyBaseCore.ty_round(Centers)
    end
    Centers = convert.(classInp, Centers)

    if TyBaseCore.strcmp(filename, "imsegkmeans")
        Label = reshape(Label, m, n)
    elseif TyBaseCore.strcmp(filename, "imsegkmeans3")
        Label = reshape(Label, m, n, p)
    end

    if k <= typemax(UInt8)
        dataType = UInt8
    elseif k <= typemax(UInt16)
        dataType = UInt16
    elseif k <= typemax(UInt32)
        dataType = UInt32
    else
        dataType = Float64
    end
    Label = convert.(dataType, Label)

    return Label, Centers
end

function algkmeans_ParseInputs(
    Inp, k, filename, NormalizeInput, NumAttempts, MaxIterations, Threshold
)
    if TyBaseCore.strcmp(filename, "imsegkmeans")
        Inp = Inp
        if (ndims(Inp) > 3)
            error(
                _msg(
                    @tr("Im must have at most 3 dimensions."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        validateImage(Inp)
    else
        Inp = Inp
        if (ndims(Inp) > 4)
            error(
                _msg(
                    @tr("V must have at most 4 dimensions."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        validateVolume(Inp)
    end

    k = k
    validateNumClusters(k)
    NormalizeInput = NormalizeInput
    validateNormalizeInput(NormalizeInput)
    NumAttempts = NumAttempts
    validateNumAttempts(NumAttempts)
    MaxIterations = MaxIterations
    validateMaxIterations(MaxIterations)
    Threshold = Threshold
    validateThreshold(Threshold)

    return Inp, k, NormalizeInput, NumAttempts, MaxIterations, Threshold
end

function validateImage(Im)
    if !(eltype(Im) in [UInt8, UInt16, Int8, Int16, Float32])
        type_list = "UInt8, UInt16, Int8, Int16, Float32"
        error(
            _msg(
                @tr(
                    "Invalid value for 'Im'. First input must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    type_list,
                    eltype(Im)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(Im)
        error(
            _msg(
                @tr("Invalid value for 'Im'. First input must be real."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(Im)
        error(
            _msg(
                @tr("Invalid value for 'Im'. First input must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite, Im)
        error(
            _msg(
                @tr("Invalid value for 'Im'. First input must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function validateVolume(V)
    if !(eltype(V) in [UInt8, UInt16, Int8, Int16, Float32])
        type_list = "UInt8, UInt16, Int8, Int16, Float32"
        error(
            _msg(
                @tr(
                    "Invalid value for 'V'. First input must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    type_list,
                    eltype(V)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(V)
        error(
            _msg(
                @tr("Invalid value for 'V'. First input must be real."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(V)
        error(
            _msg(
                @tr("Invalid value for 'V'. First input must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite, V)
        error(
            _msg(
                @tr("Invalid value for 'V'. First input must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function validateNumClusters(k)
    if !(
        eltype(k) in
        [Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64]
    )
        error(
            _msg(
                @tr(
                    "Invalid value for 'k'. Second input, k, must be one of the following types:\n\nFloat64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64\n\nbut its type was %{1}.",
                    eltype(k)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !TyBaseCore.isscalar(k)
        error(
            _msg(
                @tr("Invalid value for 'k'. Second input, k, must be a scalar."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(k)
        error(
            _msg(
                @tr("Invalid value for 'k'. Second input must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !any(isfinite.(k))
        error(
            _msg(
                @tr("Invalid value for 'k'. Second input must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if k != floor(k)
        error(
            _msg(
                @tr("Invalid value for 'k'. Second input, k, must be an integer value."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !(k > 0)
        error(
            _msg(
                @tr("Invalid value for 'k'. Second input, k, must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function validateNormalizeInput(inp)
    if !(
        eltype(inp) in
        [Bool, Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64]
    )
        type_list = "Bool, Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64"
        error(
            _msg(
                @tr(
                    "Invalid value for 'NormalizeInput'. NormalizeInput must be one of the following types:\n\n%{1}.",
                    type_list
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    inp = inp isa AbstractArray ? inp : [inp]
    if !all(v -> v in [true, false, 1, 0], inp)
        error(
            _msg(
                @tr(
                    "Invalid value for 'NormalizeInput'. NormalizeInput must be a scalar of type Bool."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if length(inp) == 1
        inp = inp[1]
    else
        error(
            _msg(
                @tr("Invalid value for 'NormalizeInput'. NormalizeInput must be a scalar."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function validateNumAttempts(inp)
    if !(
        eltype(inp) in
        [Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64]
    )
        type_list = "Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64"
        error(
            _msg(
                @tr(
                    "Invalid value for 'NumAttempts'. NumAttempts must be one of the following types:\n\n%{1}.",
                    type_list
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !TyBaseCore.isscalar(inp)
        error(
            _msg(
                @tr("Invalid value for 'NumAttempts'. NumAttempts must be a scalar."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(inp)
        error(
            _msg(
                @tr("Invalid value for 'NumAttempts'. NumAttempts must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !any(isfinite.(inp))
        error(
            _msg(
                @tr("Invalid value for 'NumAttempts'. NumAttempts must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if inp != floor(inp)
        error(
            _msg(
                @tr(
                    "Invalid value for 'NumAttempts'. NumAttempts must be an integer value."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !(inp > 0)
        error(
            _msg(
                @tr("Invalid value for 'NumAttempts'. NumAttempts must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function validateMaxIterations(inp)
    if !(
        eltype(inp) in
        [Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64]
    )
        type_list = "Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64"
        error(
            _msg(
                @tr(
                    "Invalid value for 'MaxIterations'. MaxIterations must be one of the following types:\n\n%{1}.",
                    type_list
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !TyBaseCore.isscalar(inp)
        error(
            _msg(
                @tr("Invalid value for 'MaxIterations'. MaxIterations must be a scalar."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(inp)
        error(
            _msg(
                @tr("Invalid value for 'MaxIterations'. MaxIterations must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !any(isfinite.(inp))
        error(
            _msg(
                @tr("Invalid value for 'MaxIterations'. MaxIterations must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if inp != floor(inp)
        error(
            _msg(
                @tr(
                    "Invalid value for 'MaxIterations'. MaxIterations must be an integer value."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !(inp > 0)
        error(
            _msg(
                @tr("Invalid value for 'MaxIterations'. MaxIterations must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function validateThreshold(inp)
    if !(
        eltype(inp) in
        [Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64]
    )
        type_list = "Float64, Float32, UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64"
        error(
            _msg(
                @tr(
                    "Invalid value for 'Threshold'. Threshold must be one of the following types:\n\n%{1}.",
                    type_list
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !TyBaseCore.isscalar(inp)
        error(
            _msg(
                @tr("Invalid value for 'Threshold'. Threshold must be a scalar."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(inp)
        error(
            _msg(
                @tr("Invalid value for 'Threshold'. Threshold must be nonempty."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !any(isfinite.(inp))
        error(
            _msg(
                @tr("Invalid value for 'Threshold'. Threshold must be finite."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !isreal(inp)
        error(
            _msg(
                @tr("Invalid value for 'Threshold'. Threshold must be real."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !(inp > 0)
        error(
            _msg(
                @tr("Invalid value for 'Threshold'. Threshold must be positive."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    flag = true

    return flag
end

function normInp(X)
    avgChn = mean(X; dims=1)
    stdDevChn = std(X; corrected=true, dims=1)

    # MATLAB normalizes every channel independently with the sample standard
    # deviation. A single observation produces a zero deviation there, while
    # Statistics.std returns NaN, so handle both cases as irrelevant channels.
    zeroLoc = (stdDevChn .== 0) .| .!isfinite.(stdDevChn)
    stdDevChn[zeroLoc] .= one(eltype(stdDevChn))
    out = (X .- avgChn) ./ stdDevChn

    return out, avgChn, stdDevChn
end

function internal_ocvkmeans(X, k, NumAttempts, MaxIterations, Threshold)
    labels, centers = _julia_kmeans(X, k, NumAttempts, MaxIterations, Threshold)
    return labels, centers
end

function _julia_kmeans(X, k, NumAttempts, MaxIterations, Threshold)
    k = Int(k)
    attempts = Int(NumAttempts)
    maxiter = Int(MaxIterations)
    threshold_sq = Float64(Threshold)^2
    n, c = size(X)
    X32 = Matrix{Float32}(X)
    compressed_1d = c == 1 ? _kmeans_compress_1d(X32, 512) : nothing
    thread_changes = if k == 3 && c == 3 && n >= 32_768 && Threads.nthreads() > 1
        zeros(Int, Threads.nthreads())
    else
        Int[]
    end

    best_labels = Vector{Int}(undef, n)
    best_centers = Matrix{Float32}(undef, k, c)
    best_compactness = Inf
    # MATLAB's OpenCV wrapper resets its RNG to this seed for reproducible
    # results on every imsegkmeans call.
    rng_state = UInt64(1000)

    for _ in 1:attempts
        centers, rng_state = _kmeans_initial_centers(X32, k, rng_state)

        if compressed_1d !== nothing
            compressed_result = _kmeans_refine_compressed_1d(
                compressed_1d, centers, k, maxiter, threshold_sq
            )
            if compressed_result !== nothing
                labels, centers, compactness = compressed_result
                if compactness < best_compactness
                    best_compactness = compactness
                    best_labels .= labels
                    best_centers .= centers
                end
                continue
            end
        end

        labels = zeros(Int, n)
        counts = zeros(Int, k)
        sums = zeros(Float32, k, c)
        new_centers = similar(centers)

        for _ in 1:maxiter
            fill!(counts, 0)
            fill!(sums, 0)
            changed = if k == 3 && c == 3
                _kmeans_assign_accumulate_rgb3!(
                    labels, X32, centers, counts, sums, thread_changes
                )
            else
                _kmeans_assign_accumulate_generic!(labels, X32, centers, counts, sums)
            end

            _kmeans_repair_empty_clusters!(X32, labels, counts, sums)

            max_shift_sq = 0.0
            @inbounds for cluster in 1:k
                inv_count = 1.0f0 / counts[cluster]
                shift_sq = 0.0
                for ch in 1:c
                    new_value = sums[cluster, ch] * inv_count
                    d = Float64(new_value - centers[cluster, ch])
                    shift_sq += d * d
                    new_centers[cluster, ch] = new_value
                end
                max_shift_sq = max(max_shift_sq, shift_sq)
            end
            centers, new_centers = new_centers, centers

            if max_shift_sq <= threshold_sq || changed == 0
                break
            end
        end

        compactness = _kmeans_compactness(X32, labels, centers)
        if compactness < best_compactness
            best_compactness = compactness
            best_labels .= labels
            best_centers .= centers
        end
    end

    return reshape(best_labels, n, 1), best_centers
end

function _kmeans_assign_accumulate_generic!(labels, X, centers, counts, sums)
    n, c = size(X)
    k = size(centers, 1)
    changed = 0

    @inbounds for i in 1:n
        best_label = 1
        best_dist = Inf32
        for cluster in 1:k
            dist = 0.0f0
            for ch in 1:c
                d = X[i, ch] - centers[cluster, ch]
                dist += d * d
            end
            if dist < best_dist
                best_dist = dist
                best_label = cluster
            end
        end

        changed += labels[i] == best_label ? 0 : 1
        labels[i] = best_label
        counts[best_label] += 1
        for ch in 1:c
            sums[best_label, ch] += X[i, ch]
        end
    end

    return changed
end

function _kmeans_assign_accumulate_rgb3!(
    labels, X, centers, counts, sums, changed_by_worker
)
    n = size(X, 1)
    if isempty(changed_by_worker)
        return _kmeans_assign_accumulate_rgb3_serial!(labels, X, centers, counts, sums)
    end

    worker_count = min(length(changed_by_worker), n)
    c11, c12, c13 = centers[1, 1], centers[1, 2], centers[1, 3]
    c21, c22, c23 = centers[2, 1], centers[2, 2], centers[2, 3]
    c31, c32, c33 = centers[3, 1], centers[3, 2], centers[3, 3]

    Threads.@threads :dynamic for worker in 1:worker_count
        first_point = div((worker - 1) * n, worker_count) + 1
        last_point = div(worker * n, worker_count)
        local_changed = 0

        @inbounds for i in first_point:last_point
            x1, x2, x3 = X[i, 1], X[i, 2], X[i, 3]
            d1, d2, d3 = x1 - c11, x2 - c12, x3 - c13
            distance1 = d1 * d1 + d2 * d2 + d3 * d3
            d1, d2, d3 = x1 - c21, x2 - c22, x3 - c23
            distance2 = d1 * d1 + d2 * d2 + d3 * d3
            d1, d2, d3 = x1 - c31, x2 - c32, x3 - c33
            distance3 = d1 * d1 + d2 * d2 + d3 * d3
            best_label = if distance2 < distance1
                distance3 < distance2 ? 3 : 2
            else
                distance3 < distance1 ? 3 : 1
            end

            local_changed += labels[i] == best_label ? 0 : 1
            labels[i] = best_label
        end
        changed_by_worker[worker] = local_changed
    end

    @inbounds for i in 1:n
        label = labels[i]
        counts[label] += 1
        sums[label, 1] += X[i, 1]
        sums[label, 2] += X[i, 2]
        sums[label, 3] += X[i, 3]
    end

    return sum(changed_by_worker)
end

function _kmeans_assign_accumulate_rgb3_serial!(labels, X, centers, counts, sums)
    n = size(X, 1)
    changed = 0
    c11, c12, c13 = centers[1, 1], centers[1, 2], centers[1, 3]
    c21, c22, c23 = centers[2, 1], centers[2, 2], centers[2, 3]
    c31, c32, c33 = centers[3, 1], centers[3, 2], centers[3, 3]

    # Keep the nearest-center pass independent across points so LLVM can
    # vectorize it even when Julia was started with a single thread.  The
    # reduction below remains a separate, ordered pass to preserve the
    # Float32 accumulation order used by the MATLAB-compatible path.
    @inbounds @simd for i in 1:n
        x1, x2, x3 = X[i, 1], X[i, 2], X[i, 3]
        d1, d2, d3 = x1 - c11, x2 - c12, x3 - c13
        distance1 = d1 * d1 + d2 * d2 + d3 * d3
        d1, d2, d3 = x1 - c21, x2 - c22, x3 - c23
        distance2 = d1 * d1 + d2 * d2 + d3 * d3
        d1, d2, d3 = x1 - c31, x2 - c32, x3 - c33
        distance3 = d1 * d1 + d2 * d2 + d3 * d3
        best_label = if distance2 < distance1
            distance3 < distance2 ? 3 : 2
        else
            distance3 < distance1 ? 3 : 1
        end

        changed += labels[i] == best_label ? 0 : 1
        labels[i] = best_label
    end

    @inbounds for i in 1:n
        label = labels[i]
        counts[label] += 1
        sums[label, 1] += X[i, 1]
        sums[label, 2] += X[i, 2]
        sums[label, 3] += X[i, 3]
    end

    return changed
end

function _kmeans_compress_1d(X::AbstractMatrix{Float32}, max_unique::Int)
    n = size(X, 1)
    bin_indices = Vector{Int}(undef, n)
    values = Float32[]
    weights = Int[]
    value_to_bin = Dict{Float32,Int}()

    @inbounds for i in 1:n
        value = X[i, 1]
        bin = get(value_to_bin, value, 0)
        if bin == 0
            length(values) == max_unique && return nothing
            push!(values, value)
            push!(weights, 0)
            bin = length(values)
            value_to_bin[value] = bin
        end
        weights[bin] += 1
        bin_indices[i] = bin
    end

    return values, weights, bin_indices
end

function _kmeans_refine_compressed_1d(
    compressed, centers, k::Int, maxiter::Int, threshold_sq::Float64
)
    values, weights, bin_indices = compressed
    bin_labels = zeros(Int, length(values))
    counts = zeros(Int, k)
    sums = zeros(Float32, k)
    new_centers = similar(centers)

    for _ in 1:maxiter
        fill!(counts, 0)
        fill!(sums, 0)
        changed = 0

        @inbounds for bin in eachindex(values)
            value = values[bin]
            best_label = 1
            best_distance = Inf32
            for cluster in 1:k
                d = value - centers[cluster, 1]
                distance = d * d
                if distance < best_distance
                    best_distance = distance
                    best_label = cluster
                end
            end

            changed += bin_labels[bin] == best_label ? 0 : weights[bin]
            bin_labels[bin] = best_label
            counts[best_label] += weights[bin]
            sums[best_label] += value * weights[bin]
        end

        any(iszero, counts) && return nothing

        max_shift_sq = 0.0
        @inbounds for cluster in 1:k
            new_value = sums[cluster] / counts[cluster]
            d = Float64(new_value - centers[cluster, 1])
            max_shift_sq = max(max_shift_sq, d * d)
            new_centers[cluster, 1] = new_value
        end
        centers, new_centers = new_centers, centers

        if max_shift_sq <= threshold_sq || changed == 0
            break
        end
    end

    labels = Vector{Int}(undef, length(bin_indices))
    @inbounds for i in eachindex(labels)
        labels[i] = bin_labels[bin_indices[i]]
    end

    compactness = 0.0
    @inbounds for bin in eachindex(values)
        d = Float64(values[bin] - centers[bin_labels[bin], 1])
        compactness += weights[bin] * d * d
    end

    return labels, centers, compactness
end

function _kmeans_initial_centers(X::AbstractMatrix{Float32}, k::Int, rng_state::UInt64)
    n, c = size(X)
    centers = Matrix{Float32}(undef, k, c)
    distances = Vector{Float32}(undef, n)
    candidate_distances = similar(distances)
    best_distances = similar(distances)

    rng_state, random_value = _opencv_rng_next(rng_state)
    first_index = Int(mod(UInt64(random_value), UInt64(n))) + 1
    @inbounds centers[1, :] .= X[first_index, :]

    potential = 0.0
    @inbounds for i in 1:n
        distance = _kmeans_squared_distance(X, i, centers, 1, c)
        distances[i] = distance
        potential += distance
    end

    # OpenCV's k-means++ initialization evaluates three candidates for each
    # new center and keeps the one with the lowest remaining potential.
    for cluster in 2:k
        best_index = 1
        best_potential = Inf

        if potential <= 0
            best_index = mod1(first_index + cluster - 1, n)
            best_potential = 0.0
            @inbounds best_distances .= distances
        else
            for _ in 1:3
                rng_state, random_unit = _opencv_rng_double(rng_state)
                target = random_unit * potential
                candidate_index = n
                @inbounds for i in 1:n
                    target -= distances[i]
                    if target <= 0
                        candidate_index = i
                        break
                    end
                end

                candidate_potential = 0.0
                @inbounds for i in 1:n
                    distance = _kmeans_squared_distance_points(X, i, candidate_index, c)
                    candidate_distances[i] = min(distances[i], distance)
                    candidate_potential += candidate_distances[i]
                end

                if candidate_potential < best_potential
                    best_potential = candidate_potential
                    best_index = candidate_index
                    best_distances .= candidate_distances
                end
            end
        end

        @inbounds centers[cluster, :] .= X[best_index, :]
        distances .= best_distances
        potential = best_potential
    end

    return centers, rng_state
end

function _kmeans_repair_empty_clusters!(
    X::AbstractMatrix{Float32},
    labels::Vector{Int},
    counts::Vector{Int},
    sums::Matrix{Float32},
)
    n, c = size(X)
    @inbounds for empty_cluster in eachindex(counts)
        counts[empty_cluster] == 0 || continue

        donor = argmax(counts)
        donor_count = counts[donor]
        donor_count > 1 || continue

        farthest_index = 0
        farthest_distance = -Inf32
        for i in 1:n
            labels[i] == donor || continue
            distance = 0.0f0
            for ch in 1:c
                center_value = sums[donor, ch] / donor_count
                d = X[i, ch] - center_value
                distance += d * d
            end
            if distance > farthest_distance
                farthest_distance = distance
                farthest_index = i
            end
        end

        labels[farthest_index] = empty_cluster
        counts[donor] -= 1
        counts[empty_cluster] = 1
        for ch in 1:c
            value = X[farthest_index, ch]
            sums[donor, ch] -= value
            sums[empty_cluster, ch] = value
        end
    end

    return nothing
end

function _kmeans_compactness(X, labels, centers)
    n, c = size(X)
    compactness = 0.0
    @inbounds for i in 1:n
        compactness += _kmeans_squared_distance(X, i, centers, labels[i], c)
    end
    return compactness
end

@inline function _kmeans_squared_distance(X, point, centers, cluster, channels)
    distance = 0.0f0
    @inbounds for ch in 1:channels
        d = X[point, ch] - centers[cluster, ch]
        distance += d * d
    end
    return distance
end

@inline function _kmeans_squared_distance_points(X, first, second, channels)
    distance = 0.0f0
    @inbounds for ch in 1:channels
        d = X[first, ch] - X[second, ch]
        distance += d * d
    end
    return distance
end

@inline function _opencv_rng_next(state::UInt64)
    low = UInt32(state & UInt64(typemax(UInt32)))
    high = UInt32(state >> 32)
    state = UInt64(low) * UInt64(4164903690) + UInt64(high)
    return state, UInt32(state & UInt64(typemax(UInt32)))
end

@inline function _opencv_rng_double(state::UInt64)
    state, high = _opencv_rng_next(state)
    state, low = _opencv_rng_next(state)
    bits = (UInt64(high) << 32) | UInt64(low)
    return state, Float64(bits) / 18446744073709551616.0
end

function denormalizeCenters(NormCen, avgChn, stdDevChn)
    Centers = NormCen .* stdDevChn .+ avgChn
    return Centers
end

precompile(imsegkmeans, (Matrix{UInt8}, Int))
precompile(imsegkmeans, (Array{UInt8,3}, Int))
precompile(imsegkmeans, (Matrix{Float32}, Int))
precompile(imsegkmeans, (Array{Float32,3}, Int))
