# alphaTriangulation
---
填充 alpha 形状的三角剖分

<h2>函数库: TyMath</h2>

## 语法
<!-- DOC_CHECK:FUNCTION -->
[tri = alphaTriangulation(shp)](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#f1)

[tri = alphaTriangulation(shp,RegionID)](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#f2)

[tri,P = alphaTriangulation(shp; nargout=Val(2))](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#f3)

[tri,P = alphaTriangulation(shp,RegionID; nargout=Val(2))](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#f4)

## 说明

<div id="f1" class="jump-target"></div>

[tri](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#tri) = alphaTriangulation([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#shp)) 返回一个定义 alpha 形状的域的三角剖分。tri 中的每一行指定一个由顶点 ID（shp.Points 矩阵的行号）定义的三角形或四面体。[示例](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#eg1)

---

<div id="f2" class="jump-target"></div>

[tri](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#tri) = alphaTriangulation([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#shp),[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#RegionID)) 为 alpha 形状的某个区域返回一个三角剖分。[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#RegionID) 是该区域的 ID 并且 1 ≤ RegionID ≤ numRegions(shp)。

---

<div id="f3" class="jump-target"></div>

[tri](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#tri),[P](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#P) = alphaTriangulation([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#shp); nargout=Val(2)) 同时返回顶点坐标矩阵 [P](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#P)。此双输出形式中，[tri](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#tri) 的顶点索引对应 [P](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#P) 的行号，而不是 shp.Points 的行号。

---

<div id="f4" class="jump-target"></div>

[tri](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#tri),[P](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#P) = alphaTriangulation([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#shp),[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#RegionID); nargout=Val(2)) 支持按指定区域返回重新编号后的三角剖分和顶点坐标矩阵。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算二维 alpha 形状的三角剖分</summary>
</details>
<div class="details-content">

创建一个包含一个远离主点集的二维点集，并使用 alpha 半径 0.8 创建 alpha 形状。

```julia
using TyMath

P = [0.0 0.0
     1.0 0.0
     0.0 1.0
     100.0 100.0]
shp = alphaShape(P, 0.8)
```

恢复定义 alpha 形状域的三角剖分，并计算三角形数量。

```julia
tri = alphaTriangulation(shp)
numtriangles = size(tri, 1)
```

```dataframe
numtriangles = 1
```

使用 nargout=Val(2) 同时返回三角剖分和重新编号后的顶点坐标。

```julia
tri, Pcompact = alphaTriangulation(shp; nargout=Val(2))
(size(tri), size(Pcompact))
```

```dataframe
((1, 3), (3, 2))
```

</div>
</div>

## 输入参数

<div id="shp" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>shp — alpha 形状<div>alphaShape 对象</div></summary>
</details>
<div class="details-content">

alpha 形状，指定为 [alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) 对象。

**示例：** shp = alphaShape(x, y) 根据点坐标 (x,y) 创建二维 alphaShape 对象。

</div>
</div>

<div id="RegionID" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RegionID — alpha 形状中区域的 ID 编号<div>正整数标量 | 正整数数组</div></summary>
</details>
<div class="details-content">

alpha 形状中区域的 ID 编号，指定为介于 1 和 numRegions(shp) 之间的正整数标量或整数数组。alpha 形状可以包含多个较小的区域，具体取决于点集和参数；每个区域按面积（二维）或体积（三维）从大到小分配唯一的 RegionID。

传入整数数组时，按给定区域集合筛选三角剖分。

</div>
</div>

## 输出参数

<div id="tri" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>tri — 三角剖分<div>整数矩阵</div></summary>
</details>
<div class="details-content">

三角剖分，以矩阵形式返回。tri 的大小为 m×nv，其中 m 是 alpha 形状中的三角形或四面体数，nv 为每个单形的顶点数。二维 alpha 形状的 nv 为 3，三维 alpha 形状的 nv 为 4。

单输出时，tri 中的索引对应 shp.Points 的行号；使用 nargout=Val(2) 时，索引对应 [P](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaTriangulation.html#P) 的行号。

</div>
</div>

<div id="P" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>P — 顶点坐标<div>数值矩阵</div></summary>
</details>
<div class="details-content">

顶点坐标，以矩阵形式返回。P 的大小为 N×dim，其中 N 是所返回三角剖分使用的顶点数，dim 为 2 或 3。仅在 nargout=Val(2) 时返回 P。

</div>
</div>

## 另请参阅

[alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) | [boundaryFacets](/Doc/TyMath/ComputationalGeometry/BoundingRegions/boundaryFacets.html) | [triangulation](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TriangulationObject/triangulation.html)
