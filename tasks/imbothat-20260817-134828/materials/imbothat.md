# imbothat
---
底帽滤波

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = imbothat(I,SE)
```

## 说明

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imbothat.html#x237448c7) = imbothat([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imbothat.html#fc610f38),[SE](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imbothat.html#ad9388d6)) 使用结构元素 SE 对灰度或二值图像 I 执行形态学底帽滤波。底帽滤波计算图像的形态学闭运算（使用 [imclose](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imclose.html)），然后从结果中减去原始图像。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imbothat.html#c21463af)

## 示例

<div id="c21463af" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用底帽和顶帽滤波增强对比度</summary>
</details>
<div class="details-content">

将图像读入工作区并显示它。

```julia
using TyImageProcessing
using TyPlot

I = imread("pout.tif");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Images/imbothat/example1/example1.webp')">

创建一个盘形结构元素。

```julia
se = strel("disk",3);
```

将原始图像 I 加到顶帽滤波图像上，然后减去底帽滤波图像。

```julia
J = imsubtract(imadd(I,imtophat(I,se)),imbothat(I,se));
figure()
imshow(J)
```

<img :src="$withBase('/TyImageProcessing/Images/imbothat/example1/example2.webp')">

  </div>
</div>

## 输入参数

<div id="fc610f38" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 输入图像<div>灰度图像 | 二值图像</div></summary>
</details>
<div class="details-content">

输入图像，指定为任意维度的灰度图像或二值图像。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64 | Bool

  </div>
</div>

<div id="ad9388d6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>SE — 结构元素<div>数值矩阵 | 逻辑矩阵</div></summary>
</details>
<div class="details-content">

结构元素，数值矩阵或逻辑矩阵。

**数据类型：** UInt8 | Bool

  </div>
</div>

## 输出参数

<div id="x237448c7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 底帽滤波图像<div>灰度图像 | 二值图像</div></summary>
</details>
<div class="details-content">

经过底帽滤波的图像，以灰度图像或二值图像形式返回。J 与输入图像 [I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imbothat.html#fc610f38) 具有相同的数据类型。

  </div>
</div>