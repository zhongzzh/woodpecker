# gplotmatrix
---
按组分组的散点图矩阵

<h2>函数库: TyStatistics</h2>

## 语法

```julia
h, ax, bigax = gplotmatrix(X, g)
h, ax, bigax = gplotmatrix(X, Y, g)
h, ax, bigax = gplotmatrix(X, Y, g, clr, sym, siz)
h, ax, bigax = gplotmatrix(X, Y, g, clr, sym, siz, doleg)
h, ax, bigax = gplotmatrix(X, Y, g, clr, sym, siz, doleg, dispopt)
```

## 说明

gplotmatrix([X](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp1), [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3)) 创建数据 X 的散点图矩阵，并按分组变量 g 分组（等价于 gplotmatrix(X, Float64[], g)）。生成的图中的每个非对角线图都是 X 的一列相对于另一列的散点图，对角线图绘制分组直方图的轮廓，且坐标轴处于隐藏状态。X 和 g 必须具有相同的行数。[示例](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#eg1)

---

gplotmatrix([X](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp1), [Y](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp2), [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3)) 创建散点图矩阵，其中每个图都是 X 的一列相对于 Y 的一列的散点图。例如，如果 X 有 p 列、Y 有 q 列，则图窗包含一个 q×p 的散点图矩阵。所有图均按分组变量 g 分组。输入 X、Y 和 g 必须具有相同的行数。[示例](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#eg2)

---

gplotmatrix([X](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp1), [Y](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp2), [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3), [clr](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp4), [sym](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp5), [siz](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp6)) 为每个组指定标记颜色 clr、符号 sym 和大小 siz。

---

gplotmatrix([X](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp1), [Y](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp2), [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3), [clr](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp4), [sym](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp5), [siz](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp6), [doleg](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp7)) 控制是否在图上显示图例。默认情况下会创建图例。

---

gplotmatrix([X](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp1), [Y](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp2), [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3), [clr](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp4), [sym](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp5), [siz](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp6), [doleg](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp7), [dispopt](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp8)) 控制 X 的散点图矩阵中对角线图的显示选项。[示例](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#eg3)

---

您可以为 clr、sym、siz、doleg 和 dispopt 传入 []，以使用其默认值。

## 示例
<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>分组数据的散点图矩阵</summary>
</details>
<div class="details-content"> 

为数据集中的每个变量组合创建一个散点图矩阵，并根据单独的变量对数据进行分组。

加载 fisheriris 数据集，该数据集包含花朵数据。meas 的四列分别是花朵的萼片长度、萼片宽度、花瓣长度和花瓣宽度。species 包含花朵的物种名称 setosa、versicolor 和 virginica。对不同物种的花朵测量值进行可视化比较。

```julia
using TyStatistics
using TyPlot
include(pkgdir(TyStatistics)*"/data/PlotData/parallelcoords/fisheriris.jl")
h, ax, bigax = gplotmatrix(meas, species)
title(bigax, "Iris Data")
```

<img :src="$withBase('/TyStatistics/DescripitiveStatisticsAndVisualization/StatisticalVisualization/gplotmatrix/gplotmatrix_1.png')">

在散点图矩阵中，最左侧一列散点图的 x 轴对应于萼片长度（meas 的第一列），最底下一行散点图的 y 轴对应于花瓣宽度（meas 的最后一列）。因此，矩阵左下角的散点图将萼片长度值（沿 x 轴）与花瓣宽度值（沿 y 轴）进行比较。每个点的颜色取决于花的物种。对角线图是直方图而不是散点图。

</div>
</div>

<div id="eg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>变量子集的散点图矩阵</summary>
</details>
<div class="details-content"> 

创建散点图，将数据集中的一部分变量与另一部分变量进行比较，并根据单独的变量对数据进行分组。

加载 discrim 数据集。

```julia
using TyStatistics
using TyPlot
include(pkgdir(TyStatistics)*"/data/PlotData/gscatter/discrim.jl")
```

ratings 数组包含 329 座美国城市在九个类别上的评分信息。group 数组包含城市规模代码，对于 26 个最大的城市取值为 2，其余城市取值为 1。

创建散点图矩阵，将前两个类别 climate 和 housing 与第四个和第七个类别 crime 和 arts 进行比较。指定 group 作为分组变量，以便在视觉上区分大城市和小城市的数据。

```julia
X = ratings[:, 1:2]
Y = ratings[:, [4, 7]]
xnames = ["climate", "housing"]
ynames = ["crime", "arts"]
gplotmatrix(X, Y, group, "br", ".o", [], "on", []; xnam=xnames, ynam=ynames)
```

<img :src="$withBase('/TyStatistics/DescripitiveStatisticsAndVisualization/StatisticalVisualization/gplotmatrix/gplotmatrix_2.png')">

散点图矩阵显示了指定的比较结果，每个城市规模组用不同的颜色表示。

</div>
</div>

<div id="eg3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>多个分组变量的散点图矩阵</summary>
</details>
<div class="details-content"> 

使用两个分组变量创建散点图矩阵，比较不同数据变量。

加载 hospital 数据集。比较患者的年龄（Age）和体重（Weight）。按患者的性别和吸烟状况对患者进行分组。使用 grpbars 显示选项沿绘图矩阵的对角线显示分组直方图，并标注坐标轴。

```julia
using TyStatistics
using TyPlot
include(pkgdir(TyStatistics)*"/data/PlotData/gscatter/hospital.jl")
X = [hospital.Age hospital.Weight]
g = (hospital.Sex, hospital.Smoker)
xnames = ["Age", "Weight"]
gplotmatrix(X, Float64[], g, [], [], [], [], "grpbars"; xnam=xnames)
```

<img :src="$withBase('/TyStatistics/DescripitiveStatisticsAndVisualization/StatisticalVisualization/gplotmatrix/gplotmatrix_3.png')">

分组变量 g 是一个元组 (hospital.Sex, hospital.Smoker)，Sex 和 Smoker 取值都相同的观测值会被归入同一组。对角线上的分组直方图显示了每个组在相应变量上的分布。

</div>
</div>

## 输入参数
<div id="inp1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>X — 输入数据<div>数值矩阵</div></summary>
</details>
<div class="details-content"> 

输入数据，指定为 n×p 数值矩阵。gplotmatrix 使用 X 的列创建绘图矩阵。如果未指定额外的输入矩阵 [Y](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp2)，则 gplotmatrix 创建 p×p 的绘图矩阵，其中非对角线图是散点图，而对角线图取决于 [dispopt](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp8) 的值。在每个散点图中，gplotmatrix 都会绘制 X 的一列相对于另一列的散点图，散点图中的点根据 [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3) 分组。

</div>
</div>
<div id="inp2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Y — 输入数据<div>数值矩阵</div></summary>
</details>
<div class="details-content"> 

输入数据，指定为 n×q 数值矩阵，其中 n 必须与 X 的行数相同，q 是 Y 的列数。gplotmatrix 使用 X 的 p 列和 Y 的 q 列创建 q×p 的散点图矩阵。对于绘图矩阵的每个列，散点图的 x 轴值与 X 中对应列的值相同；对于绘图矩阵的每个行，散点图的 y 轴值与 Y 中对应列的值相同。散点图中的点根据 [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3) 分组。

如果省略 Y 或 Y 为空数组，则创建 X 自身的 p×p 散点图矩阵，对角线为直方图。

</div>
</div>
<div id="inp3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>g — 分组变量<div>数值向量 | 字符串向量 | 元组</div></summary>
</details>
<div class="details-content"> 

分组变量，指定为数值向量或字符串向量。g 也可以是包含若干分组变量的元组（如 (g1, g2, g3)），在这种情况下，所有分组变量的值相同的观测值都会放在同一个组中。无论采用何种形式，g 都必须具有与 [X](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp1) 相同的行数。同一组中的点以相同的标记颜色、符号和大小显示在散点图上。

**示例：** species

**示例：** (hospital.Sex, hospital.Smoker)

</div>
</div>
<div id="inp4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>clr — 标记颜色<div>Syslab 默认颜色（默认） | 由短颜色名称组成的字符串 | RGB 三元组矩阵</div></summary>
</details>
<div class="details-content"> 

标记颜色，指定为由短颜色名称组成的字符串、字符串标量或 RGB 三元组矩阵。

如果想自定义颜色，请指定一个 RGB 三元组矩阵。RGB 三元组是包含三个元素的行向量，其元素分别指定颜色中红、绿、蓝分量的强度。强度值必须位于 [0,1] 范围内，例如 [0.4 0.6 0.7]。

此外，还可以按名称指定一些常见的颜色。

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

clr 的默认值为包含 Syslab 默认颜色的 RGB 三元组矩阵。

如果您没有为 g 中的所有唯一组指定足够多的颜色，则 gplotmatrix 会循环使用 clr 中指定的值。如果在唯一组的数量超过默认颜色数量 (7) 时使用默认值，则 gplotmatrix 会根据需要循环使用这些默认值。

**示例：** "rgb"

**示例：** [0 0 1; 0 0 0]

</div>
</div>
<div id="inp5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sym — 标记符号<div>"." （默认） | 由符号组成的字符串</div></summary>
</details>
<div class="details-content"> 

标记符号，指定为由 plot 函数识别的符号组成的字符串。下表列出了可用的标记符号。

|值|描述|
|-|-|
|"o"|圆形|
|"+"|加号|
|"*"|星号|
|"."|点|
|"x"|叉号|
|"s"|正方形|
|"d"|菱形|
|"^"|上三角|
|"v"|下三角|
|">"|右三角|
|"<"|左三角|
|"p"|五角星（五角形）|
|"h"|六角星（六角形）|
|"none"|无标记|

如果没有为所有组指定足够多的值，则 gplotmatrix 会根据需要循环使用指定的值。

**示例：** "o+*v"

</div>
</div>
<div id="inp6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>siz — 标记大小<div>正数值向量 | 标量</div></summary>
</details>
<div class="details-content"> 

标记大小，指定为以磅为单位的正数值向量或标量。如果没有为所有组指定足够多的值，则 gplotmatrix 会根据需要循环使用指定的值。默认大小为 6。

**示例：** [6,12]

</div>
</div>
<div id="inp7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>doleg — 包含图例的选项<div>true （默认） | false | "on" | "off"</div></summary>
</details>
<div class="details-content"> 

包含图例的选项，指定为 true 或 false，或 "on" 或 "off"。默认情况下，图例显示在图上。

</div>
</div>
<div id="inp8" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>dispopt — 对角线图的显示选项<div>"stairs" （默认） | "hist" | "grpbars" | "none" | "variable"</div></summary>
</details>
<div class="details-content"> 

绘图矩阵中对角线图的显示选项，指定为下表值之一。

|值|描述|
|-|-|
|"stairs"|绘制分组直方图的轮廓。|
|"hist"|绘制直方图。|
|"grpbars"|绘制分组直方图。|
|"none"|显示空白图。|
|"variable"|显示变量名称。要使用此显示选项，必须同时通过 xnam 指定 X 的列名。|

当 [g](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp3) 包含多个组时，默认值为 "stairs"；否则默认在对角线绘制单个直方图。

</div>
</div>

### 键-值参数

实现 Key1=Value1,...,KeyN=ValueN 功能的键-值参数，其中 Key 与 Value 相互对应。键-值参数必须在其余参数以及一个英文分号以后，但是内部出现顺序不重要。

**示例**： xnam=["x1","x2"] 指定 X 每一列的坐标轴标签。

<div class="details-box">
<details open>
<summary>xnam — X 列名<div>字符串向量</div></summary>
</details>
<div class="details-content"> 

X 列名，指定为字符串向量。xnam 必须为 X 的每一列指定一个名称。

**示例：** ["Sepal Length", "Sepal Width", "Petal Length", "Petal Width"]

</div>
</div>
<div class="details-box">
<details open>
<summary>ynam — Y 列名<div>字符串向量</div></summary>
</details>
<div class="details-content"> 

Y 列名，指定为字符串向量。ynam 必须为 Y 的每一列指定一个名称。

**示例：** ["crime", "arts"]

</div>
</div>
<div class="details-box">
<details open>
<summary>sort — 分组排序指示<div>true （默认） | false</div></summary>
</details>
<div class="details-content"> 

分组排序指示，指定为 true 或 false。默认情况下，gplotmatrix 对分组组名进行排序。

</div>
</div>

## 输出参数
<div id="oup1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>h — 图形句柄矩阵<div>Line 和直方图对象矩阵</div></summary>
</details>
<div class="details-content"> 

各个绘图对象的句柄，以矩阵形式返回。当未指定 [Y](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp2) 时，返回由 Line 和直方图对象组成的矩阵，每个散点图对应 k 个 Line 对象，每个直方图对应 k 个直方图对象，其中 k 是 g 中的唯一组数。

</div>
</div>
<div id="oup2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ax — 坐标区句柄矩阵<div>Axes 对象矩阵</div></summary>
</details>
<div class="details-content"> 

各个绘图的坐标区句柄，以 Axes 对象矩阵形式返回。如果 [dispopt](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gplotmatrix.html#inp8) 为 "hist"、"stairs" 或 "grpbars"，则 ax 包含额外一行用于绘制对角直方图的隐藏坐标区句柄。

</div>
</div>
<div id="oup3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>bigax — 整个绘图矩阵的坐标区句柄<div>Axes 对象</div></summary>
</details>
<div class="details-content"> 

整个绘图矩阵的坐标区句柄，以 Axes 对象形式返回。bigax 指向覆盖整个矩阵、不显示坐标轴的坐标区，因此后续的 title、xlabel 或 ylabel 命令会生成相对于整个绘图矩阵居中的标签。

</div>
</div>

## 另请参阅

[gscatter](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/gscatter.html) | [glyphplot](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/StatisticalVisualization/glyphplot.html)