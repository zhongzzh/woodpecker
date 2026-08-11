"""
dice - 图像分割中的索伦森 - 戴斯（Sørensen - Dice）相似系数

similarity = dice(BW1,BW2)

similarity = dice(L1,L2)
"""
function dice(
    A::AbstractArray{<:T}, B::AbstractArray{<:T}
) where {T<:Union{Bool,Float64,Int64}}
    jac = jaccard(A, B)

    similarity = 2 * jac ./ (1 .+ jac)
    return similarity
end
