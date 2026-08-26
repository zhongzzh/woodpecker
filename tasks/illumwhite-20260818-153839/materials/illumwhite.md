# illumwhite
---
使用 White Patch Retinex 算法估计光源

<h2>函数库: TyImageProcessing</h2>

## 语法

```
illuminant = illumwhite(A)
illuminant = illumwhite(A, topPercentile)
illuminant = illumwhite(___; Mask=mask)
```

## 说明

[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#illuminant) = illumwhite([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#A)) 估计 RGB 图像 A 中的场景光源，假定最亮的 1% 的红色、绿色和蓝色值代表白色。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#eg1)

***
[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#illuminant) = illumwhite([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#A), [topPercentile](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#topPercentile)) 使用最亮的 topPercentile% 红色、绿色和蓝色值估计光源。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#eg1)

***
[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#illuminant) = illumwhite(___, Mask=[mask](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#mask)) 仅使用二值掩膜定义的 ROI 内的像素估计光源。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用白色小块视网膜算法校正白平衡</summary>
</details>
<div class="details-content">

打开并显示一幅白平衡较差的图像。

```julia
using TyImageProcessing
using TyPlot

A = imread("foosball.jpg");
imshow(A)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/illumwhite/example1/originalImage.png')">

JPEG 文件格式以经过伽马校正的 sRGB 色彩空间保存图像。使用 [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html) 函数撤销伽马校正。

```julia
A_lin = rgb2lin(A);
```

根据最亮的 5% 像素估计场景光源。

```julia
topPercentile = 5;
illuminant = illumwhite(A, topPercentile)
```

```dataframe
illuminant = 
1×3 Matrix{Float64}:
 0.733333  0.831373  1.0
```

illuminant 的第三个系数最大，这与图像的蓝色色调一致。

通过将估计的光源提供给 [chromadapt](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html) 函数来校正颜色。

```julia
B_lin = chromadapt(A_lin, illuminant; ColorSpace="linear-rgb");
```

要在屏幕上正确显示白平衡后的图像，请使用 [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) 函数应用伽马校正。

```julia
B = lin2rgb(B_lin);
```

显示校正后的图像。

```julia
imshow(B)
title("White-Balanced Image using White Patch with topPercentile = $(topPercentile)")
```

<img :src="$withBase('/TyImageProcessing/Images/illumwhite/example1/White-BalancedImage.png')">

  </div>
</div>

## 输入参数

<div id="A" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — RGB 图像<div>m×n×3 数值数组</div></summary>
</details>
<div class="details-content">

RGB 图像，指定为 m×n×3 的数值数组。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

<div id="topPercentile" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>topPercentile — 最亮颜色的百分比<div>1 (默认) | 数值标量</div></summary>
</details>
<div class="details-content">

用于光源估计的最亮颜色的百分比，指定为 [0, 100) 范围内的数值标量。要返回最大的红色、绿色和蓝色值，请将 topPercentile 设置为 0。

该图像显示了为估计光源而选定的红、绿、蓝通道数值。各颜色通道的选择是分别独立进行的。

<img :src="$withBase('/TyImageProcessing/Images/illumwhite/topPercentile/topPercentile.png')">

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="mask" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>mask — 图像掩膜<div>m×n 逻辑或数值矩阵</div></summary>
</details>
<div class="details-content">

图像掩膜，指定为 m×n 的逻辑或数值矩阵。掩膜指示在估计光源时要使用输入图像 [A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumwhite.html#A) 的哪些像素。计算会排除 A 中掩膜值为 0 的像素。默认情况下，掩膜全为 1，即 A 中的所有像素都包含在估计中。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64 | Bool

  </div>
</div>

## 输出参数

<div id="illuminant" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>illuminant — 场景光源的估计<div>三元素数值行向量</div></summary>
</details>
<div class="details-content">

场景光源的估计，以三元素数值行向量的形式返回。三个元素分别对应于光源的红色、绿色和蓝色值。

**数据类型：** Float64

  </div>
</div>

## 另请参阅

[whitepoint](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/whitepoint.html) | [chromadapt](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html) | [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) | [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html)
