"""
cc2bw - 将连通分量转换为二值图像

BW = cc2bw(CC)

BW = cc2bw(CC,ObjectsToKeep=objectsToKeep)
"""
function cc2bw(
    cc::TyImage_CC;
    ObjectsToKeep::Union{Real,AbstractVecOrMat{<:Real}}=1:length(cc.PixelIdxList),
)
    bw = falses(cc.ImageSize)
    if eltype(ObjectsToKeep) != Bool
        sel = unique(ObjectsToKeep)
    else
        sel = ObjectsToKeep
    end
    if TyBaseCore.isscalar(sel)
        sel = [sel]
    end

    sel = vec(sel)
    if eltype(sel) == Bool
        n = length(cc.PixelIdxList)
        if n > length(sel)
            num_zeros = n - length(sel)
            zeros_to_add = fill(false, num_zeros)
            extended_vector = vcat(sel, zeros_to_add)
        else
            extended_vector = sel
        end
        sel = extended_vector
    end
    pixIdxListToKeep = cc.PixelIdxList[sel]

    for k in 1:length(pixIdxListToKeep)
        bw[pixIdxListToKeep[k]] .= true
    end

    return bw
end
