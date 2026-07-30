"""
imresize3 - 调整三维容积强度图像的大小

B = imresize3(V,scale)

B = imresize3(V,[numrows numcols numplanes])

B = imresize3(___,method)

B = imresize3(___;Name,Value)
"""
function imresize3(
    In...; Antialiasing=nothing, Method=nothing, OutputSize=nothing, Scale=nothing
)
    if length(In) < 1
        error(
            _msg(
                @tr("Insufficient number of input arguments."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    elseif length(In) > 3
        error(_msg(@tr("Too many input arguments."), splitext(basename(@__FILE__))[1]))
    end
    varargin = []
    push!(varargin, collect(In)...)

    if !TyBaseCore.isnothing(Antialiasing)
        push!(varargin, "Antialiasing", Antialiasing)
    end
    if !TyBaseCore.isnothing(Method)
        push!(varargin, "Method", Method)
    end
    if !TyBaseCore.isnothing(OutputSize)
        push!(varargin, "OutputSize", OutputSize)
    end
    if !TyBaseCore.isnothing(Scale)
        push!(varargin, "Scale", Scale)
    end

    varargin = Tuple(varargin)

    return internal_imresize3(varargin)
end

function internal_imresize3(varargin)
    params = imresize3_parseInputs(varargin)

    makeOutputLogical = false

    if eltype(params["A"]) == Bool
        params["A"] = UInt8(255) .* UInt8.(params["A"])
        makeOutputLogical = true
    end

    order = images_internal_resize_dimensionOrder(params["scale"])

    weights = Matrix{AbstractArray}(undef, 1, params["num_dims"])
    indices = Matrix{AbstractArray}(undef, 1, params["num_dims"])
    allDimNearestNeighbor = true
    for k in 1:params["num_dims"]
        weights[k], indices[k] = images_internal_resize_contributions(
            size(params["A"], k),
            params["output_size"][k],
            params["scale"][k],
            params["kernel"],
            params["kernel_width"],
            params["antialiasing"],
        )

        if !images_internal_resize_isPureNearestNeighborComputation(weights[k])
            allDimNearestNeighbor = false
        end
    end

    if allDimNearestNeighbor
        B = images_internal_resize_resizeAllDimUsingNearestNeighbor(params["A"], indices)

    else
        B = params["A"]
        for k in 1:length(order)
            dim = order[k]

            B = imresize3_resizeAlongDim(B, dim, weights[dim], indices[dim])
        end
    end

    if makeOutputLogical
        B = Bool.(B)
    end

    return B
end

function imresize3_parseInputs(varargin)
    params = Dict()
    params["kernel"] = images_internal_resize_cubic
    params["kernel_width"] = 4
    params["antialiasing"] = Float64[]
    params["num_dims"] = 3
    params["size_dim"] = Float64[]

    method_arg_idx = imresize3_findMethodArg(varargin)

    first_param_string_idx = images_internal_resize_findFirstParamString(
        varargin, method_arg_idx
    )

    params["A"], params["scale"], params["output_size"] = imresize3_parsePreMethodArgs(
        varargin, method_arg_idx, first_param_string_idx
    )

    if !isempty(method_arg_idx)
        params["kernel"], params["kernel_width"], params["antialiasing"] = imresize3_parseMethodArg(
            varargin[method_arg_idx]
        )
    end
    params = imresize3_parseParamValuePairs(params, varargin, first_param_string_idx)

    params = imresize3_fixupSizeAndScale(params)

    if isempty(params["antialiasing"])
        params["antialiasing"] = true
    end

    return params
end

function imresize3_findMethodArg(varargin)
    idx = Float64[]
    for k in 1:length(varargin)
        arg = varargin[k]
        if typeof(arg) == String
            if imresize3_isMethodString(arg)
                idx = k
                break
            else
                break
            end
        end
    end

    return idx
end

function imresize3_parsePreMethodArgs(args, method_arg_idx, first_param_idx)
    if !isempty(method_arg_idx)
        args = args[1:(method_arg_idx - 1)]
    elseif !isempty(first_param_idx)
        args = args[1:(first_param_idx - 1)]
    end
    if length(args) < 1
        error(
            _msg(
                @tr("Invalid input syntax; missing input image in parameter list."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    scale = Float64[]
    output_size = Float64[]

    A = args[1]
    if eltype(A) ∉ [Float32, Float64, Int8, Int16, Int32, UInt8, UInt16, UInt32, Bool]
        type_list = "Float32, Float64, Int8, Int16, Int32, UInt8, UInt16, UInt32, Bool"
        error(
            _msg(
                @tr(
                    "First input, V, must be one of the following types:\n\n%{1}\n\nIts actual type is %{2}.",
                    type_list,
                    eltype(A)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if isempty(A)
        error(
            _msg(@tr("First input, V, must be nonempty."), splitext(basename(@__FILE__))[1])
        )
    end

    if ndims(A) > 3
        error(
            _msg(
                @tr(
                    "Input image has incorrect number of dimensions. Input image must have 3 dimensions, but has %{1}.",
                    ndims(A)
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if length(args) < 2
        return A, scale, output_size
    end

    next_arg = 2
    next = args[next_arg]

    scale, output_size = imresize3_scaleOrSize(next, next_arg)
    next_arg = next_arg + 1

    if next_arg <= length(args)
        error(
            _msg(
                @tr(
                    "Invalid input syntax; unrecognized input argument at position %{1}.",
                    next_arg
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return A, scale, output_size
end

function imresize3_scaleOrSize(arg, position)
    scale = Float64[]
    output_size = Float64[]

    if typeof(arg) <: Real
        if arg == 0
            error(
                _msg(
                    @tr("Input %{1} , SCALE, must be nonzero.", position),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        scale = Float64(arg)
    elseif eltype(arg) <: Real && isvector(arg) && length(arg) == 3
        if any(arg .<= 0)
            error(
                _msg(
                    @tr(
                        "Input %{1}, [NUMROWS NUMCOLS NUMPLANES], must be positive.",
                        position
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        output_size = Float64.(arg)
    else
        error(
            _msg(
                @tr("Invalid scale or size input arguments."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    return scale, output_size
end

function imresize3_parseMethodArg(method)
    valid_method_names, method_kernels, kernel_widths = imresize3_getMethodInfo()

    antialiasing = true

    idx = find(strncmpi(method, valid_method_names, length(method)))

    if length(idx) == 0
        error(
            _msg(
                @tr("Unrecognized method: %{1}.", method), splitext(basename(@__FILE__))[1]
            ),
        )
    elseif length(idx) == 1
        kernel = method_kernels[idx]
        kernel_width = kernel_widths[idx]
        if strcmp(valid_method_names[idx], "nearest")
            antialiasing = false
        end
    else
        error(
            _msg(@tr("Ambiguous method: %{1}.", method), splitext(basename(@__FILE__))[1])
        )
    end

    return kernel, kernel_width, antialiasing
end

function imresize3_isMethodString(In)
    if typeof(In) != String
        tf = false

    else
        valid_method_strings = imresize3_getMethodInfo()

        num_matches = sum(strncmpi(In, valid_method_strings, length(In)))
        tf = num_matches == 1
    end

    return tf
end

function imresize3_getMethodInfo()
    names = [
        "nearest",
        "linear",
        "trilinear",
        "cubic",
        "tricubic",
        "box",
        "triangle",
        "lanczos2",
        "lanczos3",
    ]

    kernels = [
        images_internal_resize_box,
        images_internal_resize_triangle,
        images_internal_resize_triangle,
        images_internal_resize_cubic,
        images_internal_resize_cubic,
        images_internal_resize_box,
        images_internal_resize_triangle,
        images_internal_resize_lanczos2,
        images_internal_resize_lanczos3,
    ]

    widths = [1.0 2.0 2.0 4.0 4.0 1.0 2.0 4.0 6.0]

    return names, kernels, widths
end

function imresize3_parseParamValuePairs(params_in, args, first_param_string)
    params = params_in

    if isempty(first_param_string)
        return params
    end

    if rem(length(args) - first_param_string, 2) == 0
        error(
            _msg(
                @tr(
                    "Function IMRESIZE3 requires an even number of name/value parameter pairs."
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    valid_params = ["Scale", "OutputSize", "Method", "Antialiasing"]

    param_check_fcns = [
        imresize3_processScaleParam,
        imresize3_processOutputSizeParam,
        imresize3_processMethodParam,
        images_internal_resize_processAntialiasingParam,
    ]

    for k in first_param_string:2:length(args)
        param_string = args[k]
        if typeof(param_string) != String
            error(
                _msg(
                    @tr(
                        "Input at position %{1} must be a parameter name string or character vector.",
                        k
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        idx = find(strncmpi(param_string, valid_params, length(param_string)))
        num_matches = length(idx)
        if num_matches == 0
            error(
                _msg(
                    @tr("Unrecognized parameter: %{1}.", param_string),
                    splitext(basename(@__FILE__))[1],
                ),
            )

        elseif num_matches > 1
            error(
                _msg(
                    @tr("Ambiguous parameter: %{1}.", param_string),
                    splitext(basename(@__FILE__))[1],
                ),
            )

        else
            check_fcn = param_check_fcns[idx]
            params = check_fcn(args[k + 1], params)
        end
    end

    return params
end

function imresize3_processScaleParam(arg, params_in)
    valid =
        TyBaseCore.ty_isnumeric(arg) &&
        eltype(arg) != Bool &&
        ((length(arg) == 1) || (length(arg) == params_in["num_dims"])) &&
        all(arg .> 0)

    if !valid
        error(
            _msg(
                @tr("SCALE must be a scalar or a 3-element vector of positive values."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    params = params_in
    params["scale"] = arg

    return params
end

function imresize3_processOutputSizeParam(arg, params_in)
    valid =
        TyBaseCore.ty_isnumeric(arg) &&
        eltype(arg) != Bool &&
        (length(arg) == params_in["num_dims"]) &&
        all(TyBaseCore.isnan.(arg) .| (arg .> 0))
    if !valid
        error(
            _msg(
                @tr("OUTPUTSIZE must be a three-element vector of positive values."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    params = params_in
    params["output_size"] = arg

    return params
end

function imresize3_processMethodParam(arg, params_in)
    if !isMethodString(arg)
        if typeof(arg) == String || (ty_isnumeric(arg) && eltype(arg) != Bool)
            error(
                _msg(
                    @tr("Function or variable %{1} is undefined.", arg),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        else
            error(
                _msg(
                    @tr("Invalid METHOD: %{1}.", eltype(arg)),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    params = params_in
    params["kernel"], params["kernel_width"], antialiasing = imresize3_parseMethodArg(arg)

    if TyBaseCore.isempty(params["antialiasing"])
        params["antialiasing"] = antialiasing
    end

    return params
end

function imresize3_fixupSizeAndScale(params_in)
    params = params_in

    if isempty(params["scale"]) && isempty(params["output_size"])
        error(
            _msg(
                @tr("Scale or output size must be specified."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if !isempty(params["scale"]) && isscalar(params["scale"])
        params["scale"] = repeat([params["scale"]], 1, params["num_dims"])
    end

    params["output_size"], params["size_dim"] = imresize3_fixupSize(params)

    if isempty(params["scale"])
        params["scale"] = images_internal_resize_deriveScaleFromSize(params)
    end

    if isempty(params["output_size"])
        params["output_size"] = images_internal_resize_deriveSizeFromScale(params)
    end

    return params
end

function imresize3_fixupSize(params)
    output_size = params["output_size"]
    size_dim = Float64[]

    if !isempty(output_size)
        if !all(output_size .== 0)
            error(
                _msg(
                    @tr("Specified output size cannot contain a zero."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        if all(isnan.(output_size))
            error(
                _msg(
                    @tr("Specified output size cannot contain three NaNs."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end

        if isnan(output_size[1]) && isnan(output_size[2])
            size_dim = 3
            output_size[1] = calcOutputSizeForDim(params, 1, size_dim)
            output_size[2] = calcOutputSizeForDim(params, 2, size_dim)

        elseif isnan(output_size[1]) && isnan(output_size[3])
            size_dim = 2
            output_size[1] = calcOutputSizeForDim(params, 1, size_dim)
            output_size[3] = calcOutputSizeForDim(params, 3, size_dim)

        elseif isnan(output_size[2]) && isnan(output_size[3])
            size_dim = 1
            output_size[2] = calcOutputSizeForDim(params, 2, size_dim)
            output_size[3] = calcOutputSizeForDim(params, 3, size_dim)

        elseif any(isnan.(output_size))
            error(
                _msg(
                    @tr(
                        "Output size with exactly one NaN is not allowed. All three elements of output size may be numeric, or exactly one element may be numeric and the other two NaN."
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    output_size = ceil.(output_size)

    return output_size, size_dim
end

function calcOutputSizeForDim(params, dim_unknown, dim_known)
    output_size =
        params["output_size"][dim_known] * size(params["A"], dim_unknown) /
        size(params["A"], dim_known)

    return output_size
end

function imresize3_resizeAlongDim(In, dim, weights, indices)
    if images_internal_resize_isPureNearestNeighborComputation(weights)
        out = images_internal_resize_resizeAlongDimUsingNearestNeighbor(In, dim, indices)
        return out
    end

    isThirdDimResize = 3 == dim
    if isThirdDimResize
        In = permutedims(In, [3 2 1])
        dim = 1
    end

    out = images_internal_resize_imresizemex(In, weights', indices', dim)

    if isThirdDimResize
        out = permutedims(out, [3 2 1])
    end

    return out
end
