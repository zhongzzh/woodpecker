# adapthisteq
---
对比度受限的自适应直方图均衡化 (CLAHE)

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = adapthisteq(I)
J = adapthisteq(I;Name=Value)
```

## 说明

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#d5cecd87) = adapthisteq([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#x9f9d4e3a)) 使用限制对比度的自适应直方图均衡化 (CLAHE) 来变换值，从而增强灰度图像 I 的对比度。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#x3f1463dc))

***
[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#d5cecd87) = adapthisteq([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#x9f9d4e3a);[Name=Value](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#x3cc26846)) 使用名称-值参量来控制对比度增强的各个方面。

## 示例

<div id="x3f1463dc" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>应用对比度受限的自适应直方图均衡化 (CLAHE)</summary>
</details>
<div class="details-content">

对图像应用 CLAHE 并显示结果。

```julia
using TyImageProcessing
using TyPlot

I = imread("tire.tif");
J = adapthisteq(I; ClipLimit=0.02);
imshowpair(I, J, "montage");
title("Original Image (left) and Contrast Enhanced Image (right)")
```

<img :src="$withBase('/TyImageProcessing/Images/adapthisteq/example1/example1.webp')">

  </div>
</div>

## 输入参数

<div id="x9f9d4e3a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 灰度图像<div>二维数值矩阵</div></summary>
</details>
<div class="details-content">

灰度图像，指定为二维数值矩阵。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="x3cc26846" class="jump-target"></div>

### 名称-值参数
将可选的参量对组指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参量名称，Value 是对应的值。名称-值参量必须出现在其他参量后，但对各个参量对组的顺序没有要求。

**示例：** "NumTiles"=[8 16] 将图像分成 8 行 16 列的图块。

<div id="NumTiles—图块数量" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>NumTiles — 图块数量<div>[8,8] (默认) | 由正整数组成的二元素向量</div></summary>
</details>
<div class="details-content">

adapthisteq 将图像分割成的矩形上下文区域（图块）的数量，指定为由正整数组成的二元素向量。原始图像分成大小为 M 行 N 列的图块，NumTiles 的值为 [M N]。M 和 N 都必须至少是 2。图块总数等于 M*N。图块的最佳数量取决于输入图像的类型，最好通过试验来确定。

**数据类型：** Float64

  </div>
</div>

<div id="ClipLimit—对比度增强限制" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ClipLimit — 对比度增强限制<div>0.01 (默认) | [0, 1] 范围内的数值</div></summary>
</details>
<div class="details-content">

对比度增强限制，指定为 [0, 1] 范围内的数值。限值越高，对比度越大。

ClipLimit 是对比度因子，用于防止图像的同质区域出现过饱和现象。由于许多像素落在相同的灰度级范围内，这些区域在图像图块的直方图中呈现尖峰特征。在没有限幅的情况下，自适应直方图均衡化方法在某些情况下可能会产生比原始图像更差的结果。

**数据类型：** Float64

  </div>
</div>

## 输出参数

<div id="d5cecd87" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 对比度增强图像<div>二维矩阵</div></summary>
</details>
<div class="details-content">

对比度增强图像，以与输入图像 [I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/adapthisteq.html#x9f9d4e3a) 具有相同数据类型的二维矩阵形式返回。

  </div>
</div>