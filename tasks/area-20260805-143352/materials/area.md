# area
---
二维 alpha 形状的面积

<h2>函数库: TyMath</h2>

## 语法
<!-- DOC_CHECK:FUNCTION -->
[A = area(shp)](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#f1)

[A = area(shp,RegionID)](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#f2)

## 说明

<div id="f1" class="jump-target"></div>

[A](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#A) = area([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#shp)) 返回二维 alpha 形状 shp 的面积。[示例](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#eg1)

---

<div id="f2" class="jump-target"></div>

[A](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#A) = area([shp](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#shp),[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#RegionID)) 返回 alpha 形状中指定区域的面积。[RegionID](/Doc/TyMath/ComputationalGeometry/BoundingRegions/area.html#RegionID) 是该区域的 ID 并且 1 ≤ RegionID ≤ numRegions(shp)。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算二维 alpha 形状的面积</summary>
</details>
<div class="details-content">

创建包含三个区域的二维点集，并使用 alpha 半径 2 创建 alpha 形状。

```julia
using TyMath

P = [0.0 0.0
     2.0 0.0
     0.0 2.0
     10.0 0.0
     11.0 0.0
     10.0 1.0
     20.0 0.0
     20.4 0.0
     20.0 0.4]
shp = alphaShape(P, 2.0)
```

计算 alpha 形状的总面积。

```julia
totalarea = area(shp)
```

```dataframe
totalarea = 2.5799999999999996
```

分别计算各区域的面积。

```julia
regionareas = area(shp, 1:numRegions(shp))
```

```dataframe
regionareas = [2.0, 0.5, 0.07999999999999972]
```

</div>
</div>

## 输入参数

<div id="shp" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>shp — 二维 alpha 形状<div>alphaShape 对象</div></summary>
</details>
<div class="details-content">

二维 alpha 形状，指定为 [alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) 对象。

**示例：** shp = alphaShape(x, y) 根据点坐标 (x,y) 创建二维 alphaShape 对象。

</div>
</div>

<div id="RegionID" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RegionID — alpha 形状中区域的 ID 编号<div>正整数标量 | 正整数数组</div></summary>
</details>
<div class="details-content">

alpha 形状中区域的 ID 编号，指定为介于 1 和 numRegions(shp) 之间的正整数标量或整数数组。alpha 形状可以包含多个较小的区域，具体取决于点集和参数；每个区域按面积从大到小分配唯一的 RegionID。

**示例：** shp.RegionThreshold = area(shp, numRegions(shp) - 2) 可隐藏二维 alpha 形状 shp 中两个最小的区域。

</div>
</div>

## 输出参数

<div id="A" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — 面积<div>标量 | 数值数组</div></summary>
</details>
<div class="details-content">

面积，以标量或数值数组形式返回。未指定 RegionID 或 RegionID 为标量时，A 为标量；RegionID 为数组时，A 的大小与 RegionID 相同。

</div>
</div>

## 另请参阅

[alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) | [volume](/Doc/TyMath/ComputationalGeometry/BoundingRegions/volume.html) | [surfaceArea](/Doc/TyMath/ComputationalGeometry/BoundingRegions/surfaceArea.html) | [numRegions](/Doc/TyMath/ComputationalGeometry/BoundingRegions/numRegions.html)
