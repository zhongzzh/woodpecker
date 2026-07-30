# cmunique
---
消除颜色图中的重复颜色；将灰度或真彩色图像转换为索引图像

<h2>函数库: TyImageProcessing</h2>

## 语法

```
Y,newmap = cmunique(X,map)
Y,newmap = cmunique(RGB)
Y,newmap = cmunique(I)
```

## 说明

[Y](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x57b3a095),[newmap](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x7ef1c602) = cmunique([X](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x3ce1f2da),[map](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x22fe02d6)) 从颜色图 map 中删除重复的行以生成新颜色图 newmap。该函数还会调整强度图像 X 中的索引以保持索引与颜色图之间的对应，并在 Y 中返回结果。图像 Y 和关联的颜色图 newmap 生成与 X 和 map 相同但包含尽可能小的颜色图的图像。[示例](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x26d0aa65)

*****
[Y](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x57b3a095),[newmap](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x7ef1c602) = cmunique([RGB](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x81ffdde5)) 将真彩色图像 RGB 转换为索引图像 Y 及其关联的颜色图 newmap。返回的颜色图是图像的可能的最小颜色图，包含 RGB 中每种唯一颜色对应的一项。

:::warning 注意
newmap 可能非常大，因为项数可能与 RGB 中的像素数一样多。
:::

*****
[Y](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x57b3a095),[newmap](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#x7ef1c602) = cmunique([I](/Doc/TyImageProcessing/Graphics/Images/ModifyImageColors/cmunique.html#f69566f7)) 将灰度图像 I 转换为索引图像 Y 及其关联的颜色图 newmap。返回的颜色图是图像的可能的最小颜色图，包含 I 中每种唯一强度级别对应的一项。

## 示例

<div id="x26d0aa65" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>消除颜色图中的重复项</summary>
</details>
<div class="details-content">

使用 magic 函数将 X 定义为一个 4×4 的数组，该数组使用范围 1 至 16 之间的每个值。

```julia
using TyImageProcessing
using TyPlot
using TyMath

X = Float64.(magic(4))
```

使用 gray 函数创建一个包含八项的颜色图。然后，串联这两个包含八项的颜色图，以创建一个包含 16 项的颜色图 map。在 map 中，第 9 至第 16 项是第 1 至第 8 项的重复项。

```julia
map = [gray(8);gray(8)]
size(map)
```

```dataframe
(16, 3)
```

使用 cmunique 消除颜色图中的重复项。

```julia
Y, newmap = cmunique(X, map);
size(newmap)
```

```dataframe
(8, 3)  
```

cmunique 调整原始图像 X 中的值，以便 Y 和 newmap 生成与 X 和 map 相同的图像。

```julia
figure()
image(X)
title("X")
```

<img :src="$withBase('/TyImageProcessing/Images/cmunique/example1/example1.png')">

```julia
figure()
image(Y)
title("Y")
```

<img :src="$withBase('/TyImageProcessing/Images/cmunique/example1/example2.png')">

</div>
</div>

## 输入参数

<div id="x3ce1f2da" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>X - 具有重复颜色的索引图像<div>m×n 整数矩阵</div></summary>
</details>
<div class="details-content">

具有重复颜色的索引图像，指定为 m×n 整数矩阵。

**数据类型：** Float64 | UInt8 | UInt16

</div>
</div>

<div id="x22fe02d6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>map - 具有重复颜色的颜色图<div>c<sub>1</sub>×3 矩阵</div></summary>
</details>
<div class="details-content">

与索引图像 X 相关联的具有重复颜色的颜色图，指定为由范围 [0, 1] 内的值组成的 c<sub>1</sub>×3 矩阵。map 的每行都是一个三元素 RGB，指定颜色图的单种颜色的红、绿和蓝分量。

**数据类型：** Float64

</div>
</div>

<div id="x81ffdde5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RGB - RGB 图像<div>由非负数组成的 m×n×3 数组</div></summary>
</details>
<div class="details-content">

RGB 图像，指定为由非负数组成的 m×n×3 数组。

**数据类型：** Float64 | UInt8 | UInt16

</div>
</div>

<div id="f69566f7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I - 灰度图片<div>m×n 数值矩阵</div></summary>
</details>
<div class="details-content">

灰度图像，指定为 m×n 数值矩阵。

**数据类型：** Float64 | UInt8 | UInt16

</div>
</div>

## 输出参数

<div id="x57b3a095" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Y - 具有唯一颜色的索引图像<div>m×n 整数矩阵</div></summary>
</details>
<div class="details-content">

具有唯一颜色的索引图像，以 m×n 整数矩阵形式返回。如果 newmap 的长度小于或等于 256，则输出图像可以属于 uint8 类。否则，输出图像属于 Float64 类。

**数据类型：** Float64 | UInt8

</div>
</div>

<div id="x7ef1c602" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>newmap - 具有唯一颜色的颜色图<div>c<sub>2</sub>×3 矩阵</div></summary>
</details>
<div class="details-content">

与输出索引图像 Y 相关联的具有唯一颜色的颜色图，返回为由范围 [0, 1] 内的值组成的 c<sub>2</sub>×3 矩阵。newmap 的每行都是一个三元素 RGB，指定颜色图的单种颜色的红、绿和蓝分量。

**数据类型：** Float64

</div>
</div>