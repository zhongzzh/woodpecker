# illumpca
---
使用主成分分析（PCA）估计光源

<h2>函数库: TyImageProcessing</h2>

## 语法

```
illuminant = illumpca(A)
illuminant = illumpca(A, percentage)
illuminant = illumpca(___; Mask=mask)
```

## 说明

[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#illuminant) = illumpca([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#A)) 使用主成分分析（PCA），根据大的颜色差异估计 RGB 图像 A 中的场景光源。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#eg1)

***
[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#illuminant) = illumpca([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#A), [percentage](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#percentage)) 使用指定百分比的最暗和最亮像素估计光源。
***
[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#illuminant) = illumpca(___; Mask=[mask](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumpca.html#mask)) 仅使用二值掩膜定义的 ROI 内的像素估计光源。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用主成分分析校正白平衡</summary>
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

<img :src="$withBase('/TyImageProcessing/Images/illumpca/example1/originalImage.png')">

主成分分析（PCA）假定 RGB 值为线性的。但是，JPEG 文件格式以经过伽马校正的 sRGB 色彩空间保存图像。使用 [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html) 函数撤销伽马校正。

```julia
A_lin = rgb2lin(A);
```

根据最暗和最亮的 3.5% 像素（默认百分比）估计场景光源。由于输入图像是线性的，illumpca 函数返回线性 RGB 色彩空间中的光源。

```julia
illuminant = illumpca(A_lin)
```

```dataframe
illuminant = 
1×3 Matrix{Float64}:
 0.407628  0.554676  0.725378
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
title("White-Balanced Image Using PCA")
```

<img :src="$withBase('/TyImageProcessing/Images/illumpca/example1/White-BalancedImage.png')">

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

<div id="percentage" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>percentage — 要保留的像素百分比<div>3.5 (默认) | 数值标量</div></summary>
</details>
<div class="details-content">

用于光源估计的要保留的像素百分比，指定为 (0, 50] 范围内的数值标量。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="mask" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>mask — 图像掩膜<div>m×n 逻辑或数值矩阵</div></summary>
</details>
<div class="details-content">

图像掩膜，指定为 m×n 的逻辑或数值矩阵。掩膜指示在估计光源时要使用输入图像 A 的哪些像素。计算会排除 A 中掩膜值为 0 的像素。默认情况下，掩膜全为 1，即 A 中的所有像素都包含在估计中。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64 | Bool

  </div>
</div>

## 输出参数

<div id="illuminant" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>illuminant — 场景光源的估计<div>三元数值行向量</div></summary>
</details>
<div class="details-content">

场景光源的估计，以三元数值行向量的形式返回。三个元素分别对应于光源的红色、绿色和蓝色值。

**数据类型：** Float64

  </div>
</div>

## 提示

该算法假定光照均匀且 RGB 值为线性的。如果使用非线性 sRGB 或 Adobe RGB 图像，请在使用 illumpca 之前使用 [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html) 函数撤销伽马校正。此外，请确保使用 [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) 函数将色彩适应后的图像转换回 sRGB 或 Adobe RGB。

## 算法

像素颜色表示为 RGB 色彩空间中的向量。该算法根据颜色在图像平均颜色上的投影的亮度（范数）对颜色进行排序。根据这种排序，该算法仅保留最暗和最亮的颜色。然后对颜色的子集执行主成分分析（PCA）。PCA 的第一个成分指示光源估计。

## 参考文献

[1] Cheng, Dongliang, Dilip K. Prasad, and Michael S. Brown. "Illuminant Estimation for Color Constancy: Why spatial-domain methods work and the role of the color distribution." Journal of the Optical Society of America A. Vol. 31, Number 5, 2014, pp. 1049–1058.

## 另请参阅

[chromadapt](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html) | [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) | [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html)
