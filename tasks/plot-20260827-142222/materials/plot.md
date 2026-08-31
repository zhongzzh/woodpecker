# plot
---
绘制 polyshape

<h2>函数库: TyMath</h2>

## 语法

```julia
plot(pgon)
```


## 说明

plot([pgon](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/plot.html#pgon)) 绘制 polyshape 对象。[示例](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/plot.html#eg1)

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>简单的矩形</summary>
  </details>
  <div class="details-content">

绘制一个矩形。

```julia
using TyMath
pgon = polyshape([0,0,2,2],[2,0,0,2]);
plot(pgon)
```

<img :src="$withBase('/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/plot/plot_1.png')">

  </div>
</div>

<div id="eg2" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>多个简单的矩形</summary>
  </details>
  <div class="details-content">

绘制多个矩形。

```julia
using TyMath
p1 = polyshape([0,0,1,1],[1,0,0,1]);
p2 = polyshape([0.75,1.25,1.25,0.75],[0.25,0.25,0.75,0.75]);
p3 = polyshape([1.25,1.25,1.75,1.75],[0.75,1.25,1.25,0.75]);
polyvec = [p1,p2,p3];
plot(polyvec);
```

<img :src="$withBase('/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/overlaps/Figure_1.png')">

  </div>
</div>

## 输入参数

<div id="pgon" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>pgon — 输入 polyshape<div>标量 | 向量 | 矩阵 | 多维数组</div></summary>
</details>
<div class="details-content">

输入 polyshape，指定为标量、向量、矩阵或多维数组。

**数据类型：** polyshape

  </div>
</div> 

## 另请参阅

[polyshape](/Doc/TyMath/ComputationalGeometry/ElementaryPolygons/Polyshape/polyshape.html)