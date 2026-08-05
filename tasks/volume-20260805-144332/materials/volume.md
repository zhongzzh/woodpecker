# volume
---
三维 alpha 形状的体积

<h2>函数库: TyMath</h2>

## 语法
<!-- DOC_CHECK:FUNCTION -->
[V = volume(shp)](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#f1)

[V = volume(shp,RegionID)](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#f2)

## 说明

<div id="f1" class="jump-target"></div>

[V](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#V) = volume([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#shp)) 返回三维 alpha 形状 shp 的体积。[示例](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#eg1)

---

<div id="f2" class="jump-target"></div>

[V](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#V) = volume([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#shp),[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#RegionID)) 返回 alpha 形状中指定区域的体积。[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html#RegionID) 是该区域的 ID 并且 1 ≤ RegionID ≤ numRegions(shp)。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算三维 alpha 形状的体积</summary>
</details>
<div class="details-content">

创建包含三个区域的三维点集，并使用 alpha 半径 1 创建 alpha 形状。

```julia
using TyMath

P = [0.0 0.0 0.0
     1.0 0.0 0.0
     0.0 1.0 0.0
     0.0 0.0 1.0
     5.0 0.0 0.0
     6.0 0.0 0.0
     5.0 1.0 0.0
     5.0 0.0 1.0
     10.0 0.0 0.0
     10.3 0.0 0.0
     10.0 0.3 0.0
     10.0 0.0 0.3]
shp = alphaShape(P, 1.0)
```

计算 alpha 形状的总体积。

```julia
totalvol = volume(shp)
```

```dataframe
totalvol = 0.3378333333333333
```

分别计算各区域的体积。

```julia
regionvols = volume(shp, 1:numRegions(shp))
```

```dataframe
regionvols = [0.16666666666666666, 0.16666666666666666, 0.00450000000000001]
```

</div>
</div>

## 输入参数

<div id="shp" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>shp — 三维 alpha 形状<div>alphaShape 对象</div></summary>
</details>
<div class="details-content">

三维 alpha 形状，指定为 [alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) 对象。

**示例：** shp = alphaShape(x, y, z) 根据点坐标 (x,y,z) 创建三维 alphaShape 对象。

</div>
</div>

<div id="RegionID" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RegionID — alpha 形状中区域的 ID 编号<div>正整数标量 | 正整数数组</div></summary>
</details>
<div class="details-content">

alpha 形状中区域的 ID 编号，指定为介于 1 和 numRegions(shp) 之间的正整数标量或整数数组。alpha 形状可以包含多个较小的区域，具体取决于点集和参数；每个区域按体积从大到小分配唯一的 RegionID。

</div>
</div>

## 输出参数

<div id="V" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>V — 体积<div>标量 | 数值数组</div></summary>
</details>
<div class="details-content">

体积，以标量或数值数组形式返回。未指定 RegionID 或 RegionID 为标量时，V 为标量；RegionID 为数组时，V 的大小与 RegionID 相同。

</div>
</div>

## 另请参阅

[alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) | [area](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html) | [surfaceArea](/Doc/TyMath/ComputationalGeometry/BoundingRegions/surfaceArea.html) | [numRegions](/Doc/TyMath/ComputationalGeometry/BoundingRegions/numRegions.html)
