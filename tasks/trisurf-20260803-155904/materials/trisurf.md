# trisurf
---
三角形曲面图

<h2>函数库: TyMath</h2>

## 语法

```julia
trisurf(T,x,y,z)
trisurf(T,x,y,z,c)
trisurf(TR)
trisurf(TR,c)
trisurf(___;key=value)
h = trisurf(___)
```

## 说明

trisurf([T](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input1),[x](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input2),[y](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input3),[z](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input4)) 绘制由 x、y 和 z 中的点以及三角连接矩阵 T 定义的三维三角形曲面。[示例](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#jump_eg1)

---

trisurf([T](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input1),[x](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input2),[y](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input3),[z](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input4),[c](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input5)) 还指定曲面的顶点颜色数据。

---

trisurf([TR](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input6)) 绘制由三维 Triangulation 定义的曲面。[示例](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#jump_eg2)

---

trisurf([TR](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input6),[c](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#input5)) 使用指定的顶点颜色数据绘制三角形曲面。

---

trisurf(___;[key=value](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#name-value)) 使用名称-值对组指定曲面的一个或多个属性。例如，facecolor="yellow" 将曲面颜色设置为黄色。

---

[h](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf.html#output1) = trisurf(___) 返回用于创建曲面的补片对象。可以使用 h 查询或修改曲面属性。

## 示例

<div id="jump_eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>绘制三维三角形曲面</summary>
</details>
<div class="details-content">

创建一组网格点，计算德劳内三角剖分，并绘制由三角剖分定义的曲面。

```julia
using TyMath
using TyBase
using TyPlot

x, y = meshgrid2(1:15, 1:15)
_, _, z = peaks(15)
T = delaunay(x, y)
trisurf(T, x, y, z)
```

<img :src="$withBase('/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf/trisurf1.png')">

或者，你可以创建并绘制一个 triangulation 对象。

```julia
TO = triangulation(T,x[:],y[:],z[:])
trisurf(TO)
```

<img :src="$withBase('/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/trisurf/trisurf1.png')">

</div>
</div>

## 输入参数

<div id="input1" class="jump-target"></div>
<div class="details-box"><details open><summary>T — 三角连接<div>三列矩阵</div></summary></details><div class="details-content">

三角连接，指定为三列矩阵。每行包含定义一个三角形面的三个顶点索引，索引必须是有效的正整数。

</div></div>

<div id="input2" class="jump-target"></div>
<div class="details-box"><details open><summary>x — x 坐标<div>向量 | 矩阵</div></summary></details><div class="details-content">

x 坐标，指定为向量或矩阵。x、y 和 z 必须包含相同数量的元素。

</div></div>

<div id="input3" class="jump-target"></div>
<div class="details-box"><details open><summary>y — y 坐标<div>向量 | 矩阵</div></summary></details><div class="details-content">

y 坐标，指定为向量或矩阵。x、y 和 z 必须包含相同数量的元素。

</div></div>

<div id="input4" class="jump-target"></div>
<div class="details-box"><details open><summary>z — z 坐标<div>向量 | 矩阵</div></summary></details><div class="details-content">

z 坐标，指定为向量或矩阵。未指定 c 时，z 同时用作逐顶点颜色数据。

</div></div>

<div id="input5" class="jump-target"></div>
<div class="details-box"><details open><summary>c — 顶点颜色数据<div>向量 | 矩阵</div></summary></details><div class="details-content">

顶点颜色数据，指定为与 z 包含相同元素数量的向量或矩阵。

</div></div>

<div id="input6" class="jump-target"></div>
<div class="details-box"><details open><summary>TR — 三角剖分对象<div>Triangulation | ConstrainedTriangulation</div></summary></details><div class="details-content">

三角剖分对象，指定为包含三维点的 Triangulation 或 ConstrainedTriangulation 对象。

</div></div>

### 名称-值对组参数<a id="name-value" class="jump-target"></a>

指定可选的、以逗号分隔的 key=value 对组参数。key 为参数名称，value 为对应的值。可以采用任意顺序指定多个名称-值对组参数，如 key1=value1,...,keyN=valueN 所示。

此处列出的属性只是补片属性的一个子集。

<div id="key1" class="jump-target"></div>
<div class="details-box"><details open><summary>facecolor — 面颜色<div>"flat"（默认） | "none" | 颜色名称 | RGB 三元组 | 十六进制颜色代码</div></summary></details><div class="details-content">

面颜色，指定为 "flat"、"none"、颜色名称、RGB 三元组或十六进制颜色代码。默认值 "flat" 根据顶点颜色数据设置每个面的颜色。

</div></div>

<div id="key2" class="jump-target"></div>
<div class="details-box"><details open><summary>facealpha — 面透明度<div>1（默认） | 范围 [0,1] 内的标量</div></summary></details><div class="details-content">

面透明度，指定为范围 [0,1] 内的标量。值 1 表示完全不透明，值 0 表示完全透明。

</div></div>

<div id="key3" class="jump-target"></div>
<div class="details-box"><details open><summary>edgecolor — 边颜色<div>[0,0,0]（默认） | "none" | 颜色名称 | RGB 三元组 | 十六进制颜色代码</div></summary></details><div class="details-content">

边颜色，指定为 "none"、颜色名称、RGB 三元组或十六进制颜色代码。默认值 [0,0,0] 对应黑色边。

</div></div>

<div id="key4" class="jump-target"></div>
<div class="details-box"><details open><summary>linewidth — 线宽<div>0.5（默认） | 正值</div></summary></details><div class="details-content">

线宽，指定为以磅为单位的正值。

</div></div>

<div id="key5" class="jump-target"></div>
<div class="details-box"><details open><summary>linestyle — 线型<div>"-"（默认） | "--" | ":" | "-." | "none"</div></summary></details><div class="details-content">

线型，指定为下列值之一：

- "-" 表示实线；
- "--" 表示虚线；
- ":" 表示点线；
- "-." 表示点划线；
- "none" 表示不显示边线。

</div></div>

## 输出参数

<div id="output1" class="jump-target"></div>
<div class="details-box"><details open><summary>h — 补片对象<div>标量</div></summary></details><div class="details-content">

补片对象，以标量形式返回。可以使用 h 查询或修改曲面属性。

</div></div>

## 另请参阅

[triplot](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TransformationStorageAndDrawing/triplot.html) | [delaunay](/Doc/TyMath/ComputationalGeometry/Delaunay/Base/delaunay.html) | [triangulation](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TriangulationObject/triangulation.html) | [patch](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/patch.html)