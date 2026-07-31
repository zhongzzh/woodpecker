"""
imrotate3 - 旋转三维体灰度图像

B = imrotate3(V,angle,W)

B = imrotate3(V,angle,W,method)

B = imrotate3(V,angle,W,method,bbox)

B = imrotate3(___;"FillValues",fillValues)
"""
function imrotate3(
    V::AbstractArray{<:Real},
    angle::Real,
    W::AbstractVecOrMat{<:Real},
    method::AbstractString="linear",
    bbox::AbstractString="loose";
    FillValues::Real=0,
)
    V, ANGLE, W, METHOD, BBOX, FILLVAL = imrotate3_parse_inputs(
        V, angle, W, method, bbox, FillValues
    )

    if isempty(V) || all(W .== 0)
        B = V
    else
        unit_W = W / LinearAlgebra.norm(W)

        t_quat = quat_matrix(unit_W, ANGLE)

        tf = affinetform3d(t_quat')

        RA = imref3d(size(V))
        Rout = images_spatialref_internal_applyGeometricTransformToSpatialRef(RA, tf)

        if BBOX == "crop"
            Rout.ImageSize = RA.ImageSize
            xTrans = mean(Rout.XWorldLimits) - mean(RA.XWorldLimits)
            yTrans = mean(Rout.YWorldLimits) - mean(RA.YWorldLimits)
            zTrans = mean(Rout.ZWorldLimits) - mean(RA.ZWorldLimits)
            Rout.XWorldLimits = RA.XWorldLimits + xTrans
            Rout.YWorldLimits = RA.YWorldLimits + yTrans
            Rout.ZWorldLimits = RA.ZWorldLimits + zTrans
        end

        B, = imwarp(V, tf, METHOD; OutputView=Rout, FillValues=FILLVAL, SmoothEdges=true)
    end

    return B
end

function quat_matrix(W, ANGLE)
    a_x = W[1, 1]
    a_y = W[1, 2]
    a_z = W[1, 3]

    c = cosd(ANGLE)
    s = sind(ANGLE)

    t1 = c + a_x^2 * (1 - c)
    t2 = a_x * a_y * (1 - c) - a_z * s
    t3 = a_x * a_z * (1 - c) + a_y * s
    t4 = a_y * a_x * (1 - c) + a_z * s
    t5 = c + a_y^2 * (1 - c)
    t6 = a_y * a_z * (1 - c) - a_x * s
    t7 = a_z * a_x * (1 - c) - a_y * s
    t8 = a_z * a_y * (1 - c) + a_x * s
    t9 = c + a_z^2 * (1 - c)

    t = [
        t1 t2 t3 0
        t4 t5 t6 0
        t7 t8 t9 0
        0 0 0 1
    ]

    return t
end

function imrotate3_parse_inputs(V, angle, W, method, bbox, FillValues)
    if ndims(V) != 3
        error(
            _msg(
                @tr("First input, V, must be a 3-D array."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    ang = Float64.(angle)

    W = Float64.(W)
    if length(W) != 3
        error(
            _msg(
                @tr("Third input, W, size must be 1x3, but actual size is %{1}.", size),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
    if !all(isfinite.(W))
        error(
            _msg(@tr("Third input, W, must be finite."), splitext(basename(@__FILE__))[1])
        )
    end

    methodstrs = ["nearest", "linear", "cubic", "crop", "loose", "fillvalues"]
    if method ∉ methodstrs
        error(
            _msg(
                @tr(
                    "Input must match one of:\n\n%{1}\n\nInput %{2} does not match any valid value.",
                    methodstrs,
                    method
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    bboxstrs = ["nearest", "linear", "cubic", "crop", "loose", "fillvalues"]
    if bbox ∉ bboxstrs
        error(
            _msg(
                @tr(
                    "Input must match one of: %{1}. Input '%{2}' does not match any valid value.",
                    bboxstrs,
                    bbox
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    fillval = FillValues

    return V, ang, W, method, bbox, fillval
end
