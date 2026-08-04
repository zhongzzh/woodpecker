"""
roicolor - 基于颜色选择感兴趣区域（ROI）

BW = roicolor(I,low,high)

BW = roicolor(I,v)
"""
function roicolor(
    a::AbstractArray,
    low::Union{Number,AbstractArray},
    high::Union{Nothing,Number}=nothing;
    fig::Bool=false,
)
    if ndims(a) > 2
        error(
            _msg(
                @tr("Images with dimension greater than 2 are not supported."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if TyBaseCore.isnothing(high)
        if TyBaseCore.isscalar(low)
            low = [low]
        end
        v = low[:]
        d = falses(size(a))
        for i in 1:length(v)
            d[:] = d .| (a .== v[i])
        end
    else
        d = (a .>= low) .& (a .<= high)
    end

    if fig
        b = ones(size(a))
        b[d] = a[d]
        if minimum(a[:]) < 1
            TyPlot.imagesc(b)
        else
            image(b)
        end
        return nothing
    end

    dout = d
    return dout
end
