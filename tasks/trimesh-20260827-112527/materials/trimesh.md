# trimesh
---
三角网格图

<h2>函数库: TyPlot</h2>

## 语法

```julia
trimesh(T,x,y)
trimesh(T,x,y,z)
trimesh(x,y,z,c)
trimesh(TO)
trimesh(___;Name=Value)
h = trimesh(___)
```


## 说明


trimesh([T](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#c22e22da),[x](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x67642c70),[y](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#d45b5a02)) 绘制由向量 x 和 y 中的点以及三角连接矩阵 T 定义的二维三角网格。

---

trimesh([T](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#c22e22da),[x](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x67642c70),[y](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#d45b5a02),[z](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x312db606)) 绘制三维三角网格。[示例](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#e840a8c6)

---

trimesh([x](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x67642c70),[y](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#d45b5a02),[z](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x312db606),[c](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x39c34c90)) 还指定三维三角网格的网格边颜色。

---

trimesh([TO](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#to)) 绘制由三维 triangulation 或 delaunayTriangulation 对象定义的网格。[示例](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#e840a8c6)

---

trimesh(___;[Name=Value](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh.html#x8b85d93c)) 使用名称-值对组指定网格图的一个或多个属性。例如，linewidth = 2 将边宽度设置为 2 磅。

---

h = trimesh(___) 返回用于创建网格图的 Cpatch 对象。

## 示例

<div id="e840a8c6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>三维三角网格</summary>
</details>
<div class="details-content">

创建一个三维点集，并绘制三维三角网格。

```julia
using TyPlot
using TyBase

pkg_dir = pkgdir(TyPlot)
source_path = pkg_dir * "/examples/trimesh/0-data.jl"
include(source_path)

x, y = meshgrid2(1:15, 1:15)
m, n, z = peaks(15)
trimesh(T, x, y, z)
```

<img :src="$withBase('/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh/figure1.webp')">

您也可以创建 triangulation 对象来绘制网格。

```julia
using TyMath

TO = triangulation(T, vec(x), vec(y), vec(z))
trimesh(TO)
```

<img :src="$withBase('/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/trimesh/figure1.webp')">

  </div>
</div>

## 输入参数

<div id="c22e22da" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>T - 三角连接<div>矩阵</div></summary>
</details>
<div class="details-content">

三角连接，指定为三列矩阵，其中每行包含用于定义三角形的顶点。

  </div>
</div>

<div id="x67642c70" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>x - x 坐标<div>列向量 | 矩阵</div></summary>
</details>
<div class="details-content">

x 坐标，指定为列向量或矩阵。

  </div>
</div>

<div id="d45b5a02" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>y - Y 坐标<div>列向量 | 矩阵</div></summary>
</details>
<div class="details-content">

y 坐标，指定为列向量或矩阵。

  </div>
</div>

<div id="x312db606" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>z - Z 坐标<div>列向量 | 矩阵</div></summary>
</details>
<div class="details-content">

z 坐标，指定为列向量或矩阵。

  </div>
</div>

<div id="x39c34c90" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>c - 边颜色<div>矩阵</div></summary>
</details>
<div class="details-content">

边颜色，指定为与 z 相同大小的颜色图索引矩阵。

  </div>
</div>

<div id="to" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>TO - 三角剖分对象<div>triangulation 对象| delaunayTriangulation 对象</div></summary>
</details>
<div class="details-content">

三角剖分对象，指定为包含三维点的 [triangulation](/Doc/TyMath/ComputationalGeometry/TriangulationRepresentation/TriangulationObject/triangulation.html) 或 [delaunayTriangulation](/Doc/TyMath/ComputationalGeometry/Delaunay/DelaunayTriangulation/delaunayTriangulation.html) 对象。

  </div>
</div>

## 名称-值对组参数<a id="x8b85d93c" class="jump-target"></a>
指定可选的、以逗号分隔的 Key=Value 对组参数。Key 为参数名称，Value 为对应的值。您可采用任意顺序指定多个名称-值对组参数，如 Key1=Value1,...,KeyN=ValueN 所示。

**示例：** trimesh(T, X, Y, Z; linestyle="--")

<div id="facecolor-面颜色" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>facecolor - 面颜色<div>"none" | RGB 三元组 | 十六进制颜色代码 | "r" | "g" | "b" | ...</div></summary>
</details>
<div class="details-content">

面颜色，指定为下表中的值之一。

| 选项   | 说明        |
| ------ | ---------- |
| RGB 三元组、十六进制颜色代码或颜色名称         | 对所有面使用指定的颜色。  <img :src="$withBase('/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/surf/figure_039.png')">           |
| "none"         | 不绘制面。          |

RGB 三元组和十六进制颜色代码对于指定自定义颜色非常有用。

* RGB 三元组是包含三个元素的行向量，其元素分别指定颜色中红、绿、蓝分量的强度。强度值必须位于 [0,1] 范围内，例如 [0.4, 0.6, 0.7]；
* 十六进制颜色代码是字符向量或字符串标量，以井号 (#) 开头，后跟三个或六个十六进制数字，范围可以是 0 到 F。

这些值不区分大小写。因此，颜色代码 "#FF8800" 与 "#ff8800"、"#F80" 与 "#f80" 是等效的。

此外，还可以按名称指定一些常见的颜色。下表列出了命名颜色选项、等效 RGB 三元组和十六进制颜色代码。

|  颜色名称  |   短名称   |    RGB 三元组  |   十六进制颜色代码 | 外观 |
| --------- | ------ | ---------- | ---------------- | ----------------------------------------- |
| "red"     | "r"    | [1, 0, 0]    | "#FF0000"        | <img :src="$withBase('/color/hg_red.webp')">         |
| "green"   | 不适用  | [0, 0.5019607843137255, 0]| "#008000"        | <img :src="$withBase('/color/hg_g.webp')">     |
| 不适用    | "g"    | [0, 0.5, 0]    | "#007F00"        | <img :src="$withBase('/color/hg_g.webp')">     |
| 不适用    |  不适用 | [0, 1, 0]    | "#00FF00"        | <img :src="$withBase('/color/hg_green.webp')">     |
| "blue"    | "b"    | [0, 0, 1]    | "#0000FF"        | <img :src="$withBase('/color/hg_blue.webp')">       |
| "cyan"    | 不适用 | [0, 1, 1]    | "#00FFFF"        | <img :src="$withBase('/color/hg_cyan.webp')">       |
| 不适用    | "c"    | [0, 0.75, 0.75]  | "#00BFBF"        | <img :src="$withBase('/color/hg_c.webp')">       |
| "magenta" | 不适用 | [1, 0, 1]    | "#FF00FF"        | <img :src="$withBase('/color/hg_magenta.webp')"> |
| 不适用    |  "m"     | [0.75, 0, 0.75]    | "#BF00BF"        | <img :src="$withBase('/color/hg_m.webp')"> |
| "yellow"  | 不适用 | [1, 1, 0]    | "#FFFF00"        | <img :src="$withBase('/color/hg_yellow.webp')">   |
| 不适用    | "y"    | [0.75, 0.75, 0]    | "#BFBF00"        | <img :src="$withBase('/color/hg_y.webp')">   |
| "black"   | "k"    | [0, 0, 0]    | "#000000"        | <img :src="$withBase('/color/hg_black.webp')">     |
| "white"   | "w"    | [1, 1, 1]    | "#FFFFFF"        | <img :src="$withBase('/color/hg_white.webp')">     |
| "none"    | 不适用 | 不适用     | 不适用           | 无颜色                                    |

以下是 Syslab 在许多类型的绘图中使用的默认颜色的 RGB 三元组和十六进制颜色代码。

| **RGB 三元组**         | 十六进制颜色代码 | 外观                                        |
| ---------------------- | ---------------- | ------------------------------------------- |
| [0, 0.4470, 0.7410]      | "#0072BD"        | <img :src="$withBase('/color/colororder1.webp')"> |
| [0.8500, 0.3250, 0.0980] | "#D95319"        | <img :src="$withBase('/color/colororder2.webp')"> |
| [0.9290, 0.6940, 0.1250] | "#EDB120"        | <img :src="$withBase('/color/colororder3.webp')"> |
| [0.4940, 0.1840, 0.5560] | "#7E2F8E"        | <img :src="$withBase('/color/colororder4.webp')"> |
| [0.4660, 0.6740, 0.1880] | "#77AC30"        | <img :src="$withBase('/color/colororder5.webp')"> |
| [0.3010, 0.7450, 0.9330] | "#4DBEEE"        | <img :src="$withBase('/color/colororder6.webp')"> |
| [0.6350, 0.0780, 0.1840] | "#A2142F"        | <img :src="$withBase('/color/colororder7.webp')"> |

</div>
</div>

<div id="facealpha-面透明度" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>facealpha - 面透明度<div>1 （默认） | 范围 [0,1] 中的标量 </div></summary>
</details>
<div class="details-content">

面透明度，范围 [0,1] 中的标量 - 在所有图形对象上使用统一的透明度。值为 1 时完全不透明，值为 0 时完全透明。介于 0 和 1 之间的值表示半透明。

</div>
</div>

<div id="edgecolor-边颜色" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>edgecolor - 边颜色<div>[0,0,0] （默认） | "none" |  RGB 三元组 | 十六进制颜色代码 | | "r" | "g" | "b" | ...</div></summary>
</details>
<div class="details-content">

边线颜色，指定为下面列出的值之一。默认颜色 [0,0,0] 对应于黑边。

| 选项   | 说明        |
| ------ | ---------- |
| "none"         | 不绘制边。           |
| RGB 三元组、十六进制颜色代码或颜色名称         | 对所有边使用指定的颜色。 <img :src="$withBase('/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/surf/figure_038.png')">          |

RGB 三元组和十六进制颜色代码对于指定自定义颜色非常有用。

* RGB 三元组是包含三个元素的行向量，其元素分别指定颜色中红、绿、蓝分量的强度。强度值必须位于 [0,1] 范围内，例如 [0.4, 0.6, 0.7]；
* 十六进制颜色代码是字符向量或字符串标量，以井号 (#) 开头，后跟三个或六个十六进制数字，范围可以是 0 到 F。

这些值不区分大小写。因此，颜色代码 "#FF8800" 与 "#ff8800"、"#F80" 与 "#f80" 是等效的。

此外，还可以按名称指定一些常见的颜色。下表列出了命名颜色选项、等效 RGB 三元组和十六进制颜色代码。

|  颜色名称  |   短名称   |    RGB 三元组  |   十六进制颜色代码 | 外观 |
| --------- | ------ | ---------- | ---------------- | ----------------------------------------- |
| "red"     | "r"    | [1, 0, 0]    | "#FF0000"        | <img :src="$withBase('/color/hg_red.webp')">         |
| "green"   | 不适用  | [0, 0.5019607843137255, 0]| "#008000"        | <img :src="$withBase('/color/hg_g.webp')">     |
| 不适用    | "g"    | [0, 0.5, 0]    | "#007F00"        | <img :src="$withBase('/color/hg_g.webp')">     |
| 不适用    |  不适用 | [0, 1, 0]    | "#00FF00"        | <img :src="$withBase('/color/hg_green.webp')">     |
| "blue"    | "b"    | [0, 0, 1]    | "#0000FF"        | <img :src="$withBase('/color/hg_blue.webp')">       |
| "cyan"    | 不适用 | [0, 1, 1]    | "#00FFFF"        | <img :src="$withBase('/color/hg_cyan.webp')">       |
| 不适用    | "c"    | [0, 0.75, 0.75]  | "#00BFBF"        | <img :src="$withBase('/color/hg_c.webp')">       |
| "magenta" | 不适用 | [1, 0, 1]    | "#FF00FF"        | <img :src="$withBase('/color/hg_magenta.webp')"> |
| 不适用    |  "m"     | [0.75, 0, 0.75]    | "#BF00BF"        | <img :src="$withBase('/color/hg_m.webp')"> |
| "yellow"  | 不适用 | [1, 1, 0]    | "#FFFF00"        | <img :src="$withBase('/color/hg_yellow.webp')">   |
| 不适用    | "y"    | [0.75, 0.75, 0]    | "#BFBF00"        | <img :src="$withBase('/color/hg_y.webp')">   |
| "black"   | "k"    | [0, 0, 0]    | "#000000"        | <img :src="$withBase('/color/hg_black.webp')">     |
| "white"   | "w"    | [1, 1, 1]    | "#FFFFFF"        | <img :src="$withBase('/color/hg_white.webp')">     |
| "none"    | 不适用 | 不适用     | 不适用           | 无颜色                                    |

以下是 Syslab 在许多类型的绘图中使用的默认颜色的 RGB 三元组和十六进制颜色代码。

| **RGB 三元组**         | 十六进制颜色代码 | 外观                                        |
| ---------------------- | ---------------- | ------------------------------------------- |
| [0, 0.4470, 0.7410]      | "#0072BD"        | <img :src="$withBase('/color/colororder1.webp')"> |
| [0.8500, 0.3250, 0.0980] | "#D95319"        | <img :src="$withBase('/color/colororder2.webp')"> |
| [0.9290, 0.6940, 0.1250] | "#EDB120"        | <img :src="$withBase('/color/colororder3.webp')"> |
| [0.4940, 0.1840, 0.5560] | "#7E2F8E"        | <img :src="$withBase('/color/colororder4.webp')"> |
| [0.4660, 0.6740, 0.1880] | "#77AC30"        | <img :src="$withBase('/color/colororder5.webp')"> |
| [0.3010, 0.7450, 0.9330] | "#4DBEEE"        | <img :src="$withBase('/color/colororder6.webp')"> |
| [0.6350, 0.0780, 0.1840] | "#A2142F"        | <img :src="$withBase('/color/colororder7.webp')"> |

</div>
</div>

<div id="linewidth-线宽" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>linewidth - 线宽<div>0.5 （默认） | 正值</div></summary>
</details>
<div class="details-content">

线宽，以参数等式形式指定，该等式左边为 linewidth，右边为一个正数值（以磅为单位）。

**示例：** trimesh(T, X, Y, Z; linewidth=0.5)

  </div>
</div>

<div id="linestyle-线型" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>linestyle - 线型<div>"-" （默认） | "--" | ":" | "-."</div></summary>
</details>
<div class="details-content">

线型，指定为下表中列出的选项之一。

|   线型  |    说明      |    表示的线条 |
| ------ | ------ | ------------------------------------------------------------ |
| "-"    | 实线   | <img :src="$withBase('/linestyle/solid.webp')">           |
| "\-\-" | 虚线   | <img :src="$withBase('/linestyle/dashed.webp')">         |
| ":"    | 点线   | <img :src="$withBase('/linestyle/dotted.webp')">         |
| "-."   | 点划线 | <img :src="$withBase('/linestyle/dashdotted.webp')"> |
| "none" | 无线条 |  无线条  |
</div>
</div>


## 另请参阅
[delaunay](/Doc/TyMath/ComputationalGeometry/Delaunay/Base/delaunay.html)
| [patch](/Doc/TyPlot/2Dand3DPlots/SurfacesVolumesandPolygons/patch.html)