"""
bwboundaries - 跟踪二值图像中的对象边界

B, = bwboundaries(BW)

B, = bwboundaries(BW,conn)

B, = bwboundaries(___,options)

B, = bwboundaries(___;CoordinateOrder="yx")

B,n = bwboundaries(___,options="holes")

B,L,n = bwboundaries(___,options="noholes")
"""
function bwboundaries(BW::AbstractMatrix{<:Real}; CoordinateOrder="yx")
    return bwboundaries(BW, 8, "holes"; CoordinateOrder=CoordinateOrder)
end

function bwboundaries(BW::AbstractMatrix{<:Real}, conn::Int; CoordinateOrder="yx")
    return bwboundaries(BW, conn, "holes"; CoordinateOrder=CoordinateOrder)
end

function bwboundaries(
    BW::AbstractMatrix{<:Real}, options::AbstractString; CoordinateOrder="yx"
)
    return bwboundaries(BW, 8, options; CoordinateOrder=CoordinateOrder)
end

function bwboundaries(
    BW::AbstractMatrix{<:Real},
    conn::Int64,
    options::AbstractString;
    CoordinateOrder::AbstractString="yx",
)
    @ccall_check_func_lic :TyImageProcessing
    isempty(BW) && return zeros(0, 1)
    if conn != 8
        error(
            _msg(
                @tr("Parameter 'conn' currently supports only 8-pixel connectivity."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    options = lowercase(options)
    if !(options == "holes" || options == "noholes")
        error(
            _msg(
                @tr("Parameter 'options' currently supports only 'holes' or 'noholes'."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    CoordinateOrder = lowercase(CoordinateOrder)
    if !(CoordinateOrder == "yx" || CoordinateOrder == "xy")
        error(
            _msg(
                @tr("Parameter 'CoordinateOrder' currently supports only 'xy' or 'yx'."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    NBW = _bwboundaries_mask(BW)
    B, n, L = _julia_bwboundaries(NBW, options, CoordinateOrder)
    if options == "holes"
        return B, n
    else
        return B, L, n
    end
end

function _bwboundaries_mask(BW::AbstractMatrix{<:Real})
    rows, cols = size(BW)
    mask = Matrix{Bool}(undef, rows, cols)
    @inbounds for idx in eachindex(BW)
        mask[idx] = BW[idx] != 0
    end
    return mask
end

function _julia_bwboundaries(
    mask::AbstractMatrix{Bool}, options::AbstractString, CoordinateOrder::AbstractString
)
    rows, cols = size(mask)
    exterior = _bwboundaries_exterior_background(mask)
    labels = zeros(Float64, rows, cols)
    visited = fill(false, rows, cols)
    queue = Vector{Int}(undef, length(mask))
    boundary_marks = fill(false, rows, cols)
    contours = Vector{Matrix{Int64}}()
    hole_contours = Vector{Matrix{Int64}}()
    label = 0

    @inbounds for col in 1:cols, row in 1:rows
        idx = row + (col - 1) * rows
        if mask[idx] && !visited[idx]
            label += 1
            component_length = _bwboundaries_label_foreground_component!(
                labels, visited, queue, mask, idx, label
            )
            boundary = _bwboundaries_trace_object_boundary(labels, Float64(label), idx)
            _bwboundaries_append_object_endpoint_pixels!(
                boundary, boundary_marks, labels, Float64(label), queue, component_length
            )
            push!(
                contours, _bwboundaries_boundary_to_matrix(boundary, rows, CoordinateOrder)
            )
        end
    end

    n = label
    if options == "holes"
        hole_visited = fill(false, rows, cols)
        hole_labels = zeros(Int32, rows, cols)
        hole_label = Int32(0)
        @inbounds for col in 1:cols, row in 1:rows
            idx = row + (col - 1) * rows
            if !mask[idx] && !exterior[idx] && !hole_visited[idx]
                hole_label += Int32(1)
                component_length = _bwboundaries_label_hole_component!(
                    hole_visited, hole_labels, queue, mask, exterior, idx, hole_label
                )
                boundary = _bwboundaries_trace_hole_boundary(hole_labels, hole_label, idx)
                _bwboundaries_append_hole_diagonal_pixels!(
                    boundary,
                    boundary_marks,
                    hole_labels,
                    hole_label,
                    queue,
                    component_length,
                    mask,
                    labels,
                )
                if !isempty(boundary)
                    push!(
                        hole_contours,
                        _bwboundaries_boundary_to_matrix(boundary, rows, CoordinateOrder),
                    )
                end
            end
        end
        append!(contours, hole_contours)
    end

    return reshape(contours, length(contours), 1), n, labels
end

function _bwboundaries_exterior_background(mask::AbstractMatrix{Bool})
    rows, cols = size(mask)
    exterior = fill(false, rows, cols)
    queue = Vector{Int}(undef, length(mask))
    head = 1
    tail = 0

    @inbounds begin
        for col in 1:cols
            top = 1 + (col - 1) * rows
            bottom = rows + (col - 1) * rows
            if !mask[top] && !exterior[top]
                tail += 1
                queue[tail] = top
                exterior[top] = true
            end
            if !mask[bottom] && !exterior[bottom]
                tail += 1
                queue[tail] = bottom
                exterior[bottom] = true
            end
        end
        for row in 1:rows
            left = row
            right = row + (cols - 1) * rows
            if !mask[left] && !exterior[left]
                tail += 1
                queue[tail] = left
                exterior[left] = true
            end
            if !mask[right] && !exterior[right]
                tail += 1
                queue[tail] = right
                exterior[right] = true
            end
        end

        while head <= tail
            idx = queue[head]
            head += 1
            row = (idx - 1) % rows + 1
            col = (idx - row) ÷ rows + 1
            if row > 1
                nidx = idx - 1
                if !mask[nidx] && !exterior[nidx]
                    exterior[nidx] = true
                    tail += 1
                    queue[tail] = nidx
                end
            end
            if row < rows
                nidx = idx + 1
                if !mask[nidx] && !exterior[nidx]
                    exterior[nidx] = true
                    tail += 1
                    queue[tail] = nidx
                end
            end
            if col > 1
                nidx = idx - rows
                if !mask[nidx] && !exterior[nidx]
                    exterior[nidx] = true
                    tail += 1
                    queue[tail] = nidx
                end
            end
            if col < cols
                nidx = idx + rows
                if !mask[nidx] && !exterior[nidx]
                    exterior[nidx] = true
                    tail += 1
                    queue[tail] = nidx
                end
            end
        end
    end

    return exterior
end

function _bwboundaries_label_foreground_component!(
    labels::AbstractMatrix{Float64},
    visited::AbstractMatrix{Bool},
    queue::Vector{Int},
    mask::AbstractMatrix{Bool},
    start::Int,
    label::Int,
)
    rows, cols = size(mask)
    head = 1
    tail = 1
    queue[tail] = start
    visited[start] = true

    @inbounds while head <= tail
        idx = queue[head]
        head += 1
        labels[idx] = label
        row = (idx - 1) % rows + 1
        col = (idx - row) ÷ rows + 1

        for dc in -1:1
            nc = col + dc
            1 <= nc <= cols || continue
            for dr in -1:1
                (dr == 0 && dc == 0) && continue
                nr = row + dr
                1 <= nr <= rows || continue
                nidx = idx + dr + dc * rows
                if mask[nidx] && !visited[nidx]
                    visited[nidx] = true
                    tail += 1
                    queue[tail] = nidx
                end
            end
        end
    end
    return tail
end

function _bwboundaries_label_hole_component!(
    visited::AbstractMatrix{Bool},
    labels::AbstractMatrix{Int32},
    queue::Vector{Int},
    mask::AbstractMatrix{Bool},
    exterior::AbstractMatrix{Bool},
    start::Int,
    label::Int32,
)
    rows, cols = size(mask)
    head = 1
    tail = 1
    queue[tail] = start
    visited[start] = true
    labels[start] = label

    @inbounds while head <= tail
        idx = queue[head]
        head += 1
        row = (idx - 1) % rows + 1
        col = (idx - row) ÷ rows + 1

        if row > 1
            nidx = idx - 1
            if !mask[nidx] && !exterior[nidx] && !visited[nidx]
                visited[nidx] = true
                labels[nidx] = label
                tail += 1
                queue[tail] = nidx
            end
        end
        if row < rows
            nidx = idx + 1
            if !mask[nidx] && !exterior[nidx] && !visited[nidx]
                visited[nidx] = true
                labels[nidx] = label
                tail += 1
                queue[tail] = nidx
            end
        end
        if col > 1
            nidx = idx - rows
            if !mask[nidx] && !exterior[nidx] && !visited[nidx]
                visited[nidx] = true
                labels[nidx] = label
                tail += 1
                queue[tail] = nidx
            end
        end
        if col < cols
            nidx = idx + rows
            if !mask[nidx] && !exterior[nidx] && !visited[nidx]
                visited[nidx] = true
                labels[nidx] = label
                tail += 1
                queue[tail] = nidx
            end
        end
    end
    return tail
end

const _BWBOUNDARIES_DROW = (-1, -1, 0, 1, 1, 1, 0, -1)
const _BWBOUNDARIES_DCOL = (0, 1, 1, 1, 0, -1, -1, -1)

@inline function _bwboundaries_dir_from_offset(offset::Int, rows::Int)
    offset == -1 && return 1
    offset == rows - 1 && return 2
    offset == rows && return 3
    offset == rows + 1 && return 4
    offset == 1 && return 5
    offset == -rows + 1 && return 6
    offset == -rows && return 7
    return 8
end

@inline function _bwboundaries_next_dir(dir::Int)
    return dir == 8 ? 1 : dir + 1
end

@inline function _bwboundaries_prev_dir(dir::Int)
    return dir == 1 ? 8 : dir - 1
end

@inline function _bwboundaries_neighbor_index(idx::Int, dir::Int, rows::Int)
    return idx + _BWBOUNDARIES_DROW[dir] + _BWBOUNDARIES_DCOL[dir] * rows
end

@inline function _bwboundaries_object_member(
    labels::AbstractMatrix{Float64}, label::Float64, idx::Int
)
    return labels[idx] == label
end

@inline function _bwboundaries_hole_member(
    labels::AbstractMatrix{Int32}, label::Int32, idx::Int
)
    return labels[idx] == label
end

function _bwboundaries_trace_object_boundary(
    labels::AbstractMatrix{Float64}, label::Float64, start::Int
)
    rows, cols = size(labels)
    return _bwboundaries_trace_boundary(
        idx -> _bwboundaries_object_member(labels, label, idx), start, rows, cols
    )
end

function _bwboundaries_trace_hole_boundary(
    labels::AbstractMatrix{Int32}, label::Int32, start::Int
)
    rows, cols = size(labels)
    return _bwboundaries_trace_boundary(
        idx -> _bwboundaries_hole_member(labels, label, idx), start, rows, cols
    )
end

function _bwboundaries_trace_boundary(
    is_member::F, start::Int, rows::Int, cols::Int
) where {F}
    boundary = Int[start]
    sizehint!(boundary, 64)
    start_backtrack = start - rows
    p = start
    b = start_backtrack
    max_steps = max(8, rows * cols * 4)

    @inbounds for _ in 1:max_steps
        row = (p - 1) % rows + 1
        col = (p - row) ÷ rows + 1
        dir = _bwboundaries_dir_from_offset(b - p, rows)
        found = false
        next_p = p
        next_b = b

        for _ in 1:8
            dir = _bwboundaries_next_dir(dir)
            nr = row + _BWBOUNDARIES_DROW[dir]
            nc = col + _BWBOUNDARIES_DCOL[dir]
            if 1 <= nr <= rows && 1 <= nc <= cols
                nidx = _bwboundaries_neighbor_index(p, dir, rows)
                if is_member(nidx)
                    prev_dir = _bwboundaries_prev_dir(dir)
                    next_b = _bwboundaries_neighbor_index(p, prev_dir, rows)
                    next_p = nidx
                    found = true
                    break
                end
            end
        end

        if !found
            push!(boundary, start)
            return boundary
        end

        push!(boundary, next_p)
        p = next_p
        b = next_b
        p == start && break
    end
    return boundary
end

function _bwboundaries_append_object_endpoint_pixels!(
    boundary::Vector{Int},
    marked::AbstractMatrix{Bool},
    labels::AbstractMatrix{Float64},
    label::Float64,
    component_pixels::Vector{Int},
    component_length::Int,
)
    rows, cols = size(labels)
    @inbounds for idx in boundary
        marked[idx] = true
    end

    @inbounds for k in 1:component_length
        idx = component_pixels[k]
        marked[idx] && continue
        row = (idx - 1) % rows + 1
        col = (idx - row) ÷ rows + 1
        degree = 0
        for dir in 1:8
            nr = row + _BWBOUNDARIES_DROW[dir]
            nc = col + _BWBOUNDARIES_DCOL[dir]
            if 1 <= nr <= rows && 1 <= nc <= cols
                nidx = _bwboundaries_neighbor_index(idx, dir, rows)
                labels[nidx] == label && (degree += 1)
            end
        end
        if degree == 1
            push!(boundary, idx)
            marked[idx] = true
        end
    end

    @inbounds for idx in boundary
        marked[idx] = false
    end
    return boundary
end

function _bwboundaries_append_hole_diagonal_pixels!(
    boundary::Vector{Int},
    marked::AbstractMatrix{Bool},
    labels::AbstractMatrix{Int32},
    label::Int32,
    component_pixels::Vector{Int},
    component_length::Int,
    mask::AbstractMatrix{Bool},
    object_labels::AbstractMatrix{Float64},
)
    rows, cols = size(mask)
    parent_label = 0.0
    @inbounds for k in 1:component_length
        idx = component_pixels[k]
        row = (idx - 1) % rows + 1
        col = (idx - row) ÷ rows + 1
        if row > 1 && object_labels[idx - 1] != 0
            parent_label = object_labels[idx - 1]
            break
        elseif row < rows && object_labels[idx + 1] != 0
            parent_label = object_labels[idx + 1]
            break
        elseif col > 1 && object_labels[idx - rows] != 0
            parent_label = object_labels[idx - rows]
            break
        elseif col < cols && object_labels[idx + rows] != 0
            parent_label = object_labels[idx + rows]
            break
        end
    end
    parent_label == 0.0 && return boundary

    @inbounds for idx in boundary
        marked[idx] = true
    end

    @inbounds for k in 1:component_length
        idx = component_pixels[k]
        marked[idx] && continue
        labels[idx] == label || continue
        row = (idx - 1) % rows + 1
        col = (idx - row) ÷ rows + 1
        touches_diagonal_foreground = false
        for dir in (2, 4, 6, 8)
            nr = row + _BWBOUNDARIES_DROW[dir]
            nc = col + _BWBOUNDARIES_DCOL[dir]
            if 1 <= nr <= rows && 1 <= nc <= cols
                nidx = _bwboundaries_neighbor_index(idx, dir, rows)
                if mask[nidx] && object_labels[nidx] == parent_label
                    touches_diagonal_foreground = true
                    break
                end
            end
        end
        if touches_diagonal_foreground
            push!(boundary, idx)
            marked[idx] = true
        end
    end

    @inbounds for idx in boundary
        marked[idx] = false
    end
    return boundary
end

function _bwboundaries_boundary_to_matrix(
    boundary::Vector{Int}, rows::Int, CoordinateOrder::AbstractString
)
    contour = Matrix{Int64}(undef, length(boundary), 2)
    @inbounds for k in eachindex(boundary)
        idx = boundary[k]
        row = (idx - 1) % rows + 1
        col = (idx - row) ÷ rows + 1
        if CoordinateOrder == "yx"
            contour[k, 1] = row - 1
            contour[k, 2] = col - 1
        else
            contour[k, 1] = col - 1
            contour[k, 2] = row - 1
        end
    end
    return contour
end
