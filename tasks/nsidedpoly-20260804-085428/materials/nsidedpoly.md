# nsidedpoly
---
创建具有 n 条边的正多边形

<h2>函数库: TyMath</h2>

## 语法

```julia
pgon = nsidedpoly(n)
pgon = nsidedpoly(n; Center=Center)
pgon = nsidedpoly(n; Radius=Radius)
pgon = nsidedpoly(n; SideLength=SideLength)
pgon = nsidedpoly(n; Center=Center, Radius=Radius)
pgon = nsidedpoly(n; Center=Center, SideLength=SideLength)
```

## 说明

pgon = nsidedpoly([n](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/nsidedpoly.html#n)) 创建具有 n 条等长边的正多边形，并返回 polyshape 对象。默认情况下，多边形的中心为 [0, 0]，外接圆半径为 1。[示例](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/nsidedpoly.html#eg1)

使用 Center 指定多边形中心，使用 Radius 指定外接圆半径，或使用 SideLength 指定边长。Radius 和 SideLength 不能同时指定。[示例](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/nsidedpoly.html#eg2)

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>绘制六边形</summary>
  </details>
  <div class="details-content">

创建边长为 1、中心位于原点的六边形，以及边长为 3、中心位于 [5, 0] 的六边形。

```julia
using TyMath
using TyPlot

pgon1 = nsidedpoly(6)
pgon2 = nsidedpoly(6; Center=[5, 0], SideLength=3)

figure(facecolor="white")
plot(pgon1)
plot(pgon2)
axis("equal")
```

<img :src="$withBase('/TyMath/ComputationalGeometry/ElementaryPolygons/nsidedpoly/Figure_1.png')">

  </div>
</div>

<div id="eg2" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>指定中心和外接圆半径</summary>
  </details>
  <div class="details-content">

创建中心位于 [2, -1]、外接圆半径为 3 的正方形，并计算其边数、中心、面积和周长。

```julia
pgon = nsidedpoly(4; Center=[2, -1], Radius=3)
(n=numsides(pgon), center=centroid(pgon), area=area(pgon), perimeter=perimeter(pgon))
```

```dataframe
(n = 4, center = (1.9999999999999996, -1.0), area = 17.999999999999996, perimeter = 16.97056274847714)
```

  </div>
</div>

## 输入参数

<div id="n" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>n — 边数<div>数值标量</div></summary>
</details>
<div class="details-content">

正多边形的边数，指定为大于或等于 3 的有限整数。

  </div>
</div>

## 名称-值参数

<div id="Center" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Center — 中心点<div>二元素数值向量</div></summary>
</details>
<div class="details-content">

多边形的中心点，指定为包含 x 坐标和 y 坐标的有限实数向量。默认值为 [0, 0]。

  </div>
</div>

<div id="Radius" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Radius — 外接圆半径<div>正标量</div></summary>
</details>
<div class="details-content">

多边形外接圆的半径，指定为有限正实数标量。Radius 不能与 SideLength 同时指定。

  </div>
</div>

<div id="SideLength" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>SideLength — 边长<div>正标量</div></summary>
</details>
<div class="details-content">

多边形每条边的长度，指定为有限正实数标量。SideLength 不能与 Radius 同时指定。

  </div>
</div>

## 输出参数

<div id="pgon" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>pgon — 正多边形<div>polyshape 对象</div></summary>
</details>
<div class="details-content">

由 n 条等长边构成的二维正多边形。

  </div>
</div>

## 另请参阅

[polyshape](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/polyshape.html) | [alphaShape](/Doc/TyMath/ComputationalGeometry/BoundingRegions/alphaShape.html) | [numsides](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/numsides.html) | [area](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/area.html) | [perimeter](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/perimeter.html) | [plot](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/plot.html)
