# convexHull
---
计算 Delaunay 三角剖分的凸包

<h2>函数库: TyMath</h2>

## 语法

```julia
C, v = convexHull(DT)
```

## 说明

[C](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/convexHull.html#C), [v](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/convexHull.html#v) = convexHull([DT](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/convexHull.html#DT)) 返回 Delaunay 三角剖分 DT 的凸包。对于二维三角剖分，C 为按凸包边界顺序排列的顶点 ID 向量，v 为凸包围成的面积；对于三维三角剖分，C 为凸包边界三角形面片的连接列表，v 为凸包围成的体积。[示例](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/convexHull.html#eg1)

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>二维 Delaunay 三角剖分的凸包</summary>
  </details>
  <div class="details-content"> 

创建一组二维点，并基于这些点创建 Delaunay 三角剖分。

```julia
using TyMath
using TyPlot
rng = MT19937ar(5489);
x = rand(rng,10);
y = rand(rng,10);
DT = delaunayTriangulation(x,y);
```

计算凸包。

```julia
C, = convexHull(DT)
```

绘制三角剖分和用红色高亮凸包区域

```julia
plot(DT.Points[:,1],DT.Points[:,2],".",MarkerSize=10)
hold("on")
plot(DT.Points[C,1],DT.Points[C,2],"r")
hold("off")
```

<img :src="$withBase('/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/convexHull/Figure_1.png')">

  </div>
</div>

<div id="eg2" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>三维 Delaunay 三角剖分的凸包</summary>
  </details>
  <div class="details-content"> 

创建一组三维点，并基于这些点创建 Delaunay 三角剖分。

```julia
using TyMath
using TyPlot
rng = MT19937ar(5489);
P = rand(rng,25,3);
DT = delaunayTriangulation(P);
```

计算凸包边界面片和凸包体积。

```julia
C, v = convexHull(DT);
v
```

```dataframe
v = 0.39434652634263645
```

C 是三列矩阵，每一行包含一个边界三角形面片的三个顶点 ID。

  </div>
</div>

## 输入参数

<div id="DT" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>DT — Delaunay 三角剖分<div>标量 delaunayTriangulation 对象</div></summary>
</details>
<div class="details-content">

Delaunay 三角剖分，指定为标量 [delaunayTriangulation](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/delaunayTriangulation.html) 对象。convexHull 支持二维或三维 Delaunay 三角剖分。

**数据类型：** delaunayTriangulation

</div>
</div>

## 输出参数

<div id="C" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>C — 凸包顶点或边界面片<div>向量 | 矩阵</div></summary>
</details>
<div class="details-content">

凸包顶点或边界面片，返回为向量或矩阵。

- 当 DT 为二维三角剖分时，C 为按凸包边界顺序排列的顶点 ID 向量。C 是闭合向量，首尾元素相同；
- 当 DT 为三维三角剖分时，C 为三列矩阵，每一行包含一个边界三角形面片的三个顶点 ID。

顶点 ID 是属性 DT.Points 中对应顶点的行号。

**数据类型：** Int64

</div>
</div>

<div id="v" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>v — 面积或体积<div>标量</div></summary>
</details>
<div class="details-content">

凸包围成的面积或体积，返回为标量。对于二维三角剖分，v 为凸包面积；对于三维三角剖分，v 为凸包体积。

**数据类型：** Float64

</div>
</div>

## 另请参阅

[delaunayTriangulation](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/delaunayTriangulation.html) | [convhull](/Doc/TyMath/ComputationalGeometry/BoundingRegions/convhull.html) | [convhulln](/Doc/TyMath/ComputationalGeometry/BoundingRegions/convhulln.html) | [alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html)
