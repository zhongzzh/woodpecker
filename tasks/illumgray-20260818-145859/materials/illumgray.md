# illumgray
---
使用灰度世界算法估计光源

<h2>函数库: TyImageProcessing</h2>

## 语法

```
illuminant = illumgray(A)
illuminant = illumgray(A, percentile)
illuminant = illumgray(___; Name=Value)
```

## 说明

[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x1a2b3c4d) = illumgray([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x5e6f7a8b)) 通过假设场景的平均颜色是灰色来估计 RGB 图像 A 中场景的光照。

***
[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x1a2b3c4d) = illumgray([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x5e6f7a8b), [percentile](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x9c0d1e2f)) 估计光照，排除指定底部和顶部百分比的像素值。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#xb2c3d4e5)

***
[illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x1a2b3c4d) = illumgray(___; [Name=Value](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#name-value-arguments)) 使用名称-值参数估计光照，以控制其他选项。

## 示例

<div id="xb2c3d4e5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用灰度世界算法校正白平衡</summary>
</details>
<div class="details-content">

打开并显示一张白平衡较差的图像。

```julia
using TyImageProcessing
using TyPlot

A = imread("foosball.jpg")
imshow(A)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/illumgray/example1/originalImage.png')">

灰度世界算法假设 RGB 值为线性值。但是，JPEG 文件格式以经过伽马校正的 sRGB 颜色空间保存图像。使用 [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html) 函数取消伽马校正。

```julia
A_lin = rgb2lin(A)
```

估计场景光照，排除顶部和底部各 10% 的像素。由于输入图像已线性化，illumgray 返回线性 RGB 颜色空间中的光源。

```julia
percentiles = 10
illuminant = illumgray(A_lin, percentiles)
```

```dataframe
illuminant = 
1×3 Matrix{Float64}:
 0.220627  0.298522  0.521911
```

illuminant 的第三个系数最大，这与图像的蓝色色调一致。

通过将估计的光源提供给 [chromadapt](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html) 函数来校正颜色。

```julia
B_lin = chromadapt(A_lin, illuminant; ColorSpace="linear-rgb")
```

为了在屏幕上正确显示白平衡后的图像，使用 [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) 函数应用伽马校正。

```julia
B = lin2rgb(B_lin)
```

显示校正后的图像。

```julia
imshow(B)
title("White-Balanced Image Using Gray World with percentiles=[$(percentiles) $(percentiles)]")
```

<img :src="$withBase('/TyImageProcessing/Images/illumgray/example1/White-BalancedImage.png')">

  </div>
</div>

## 输入参数

<div id="x5e6f7a8b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — RGB 图像<div>m×n×3 数值数组</div></summary>
</details>
<div class="details-content">

RGB 图像，指定为 m×n×3 数值数组。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

<div id="x9c0d1e2f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>percentile — 要排除的像素百分比<div>1 (默认) | 数值标量 | 2 元数值向量</div></summary>
</details>
<div class="details-content">

要从光照估计中排除的像素百分比，指定为数值标量或 2 元数值向量。排除像素有助于防止过曝和欠曝像素影响估计结果。

- 如果 percentile 是标量，则底部百分位数和顶部百分位数使用相同的值。在这种情况下，percentile 必须在 [0, 50] 范围内，使得底部和顶部百分位数之和不超过 100。

- 如果 percentile 是 2 元向量，则第一个元素是底部百分位数，第二个元素是顶部百分位数。两个百分位数都必须在 [0, 100) 范围内，并且它们的和不能超过 100。

下图显示了参与光源估计的像素范围，并且每个颜色通道的选择是独立进行的。

<img :src="$withBase('/TyImageProcessing/Images/illumgray/percentile/percentile.png')">

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

## 名称-值参数
<div id="name-value-arguments" class="jump-target"></div>

可选参数对以分号分隔，指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参数名称，Value 是对应的值。名称-值参数必须出现在其他参数之后，但参数对的顺序不重要。

**示例：** illuminant = illumgray(A; Mask=m) 使用根据二进制掩膜 m 选择的图像 A 中像素子集来估计场景光照。

<div id="x3a4b5c6d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Mask — 图像掩膜<div>m×n 逻辑或数值数组</div></summary>
</details>
<div class="details-content">

图像掩膜，指定为 m×n 逻辑或数值数组。掩膜指示在估计光照时使用输入图像 [A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x5e6f7a8b) 中的哪些像素。计算会排除 A 中与掩膜值 0 对应的像素。默认情况下，掩膜全为 1，A 中的所有像素都包含在估计中。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

<div id="x7d8e9f0a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Norm — 向量范数类型（p 范数）<div>1 (默认) | 正数值标量</div></summary>
</details>
<div class="details-content">

向量范数类型（p 范数），指定为正数值标量。p 范数影响输入图像 [A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x5e6f7a8b) 中平均 RGB 值的计算。p 范数定义为 sum(abs(x)^p) ^ (1/p)。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

## 输出参数

<div id="x1a2b3c4d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>illuminant — 场景光照估计<div>3 元数值行向量</div></summary>
</details>
<div class="details-content">

场景光照估计，返回为 3 元数值行向量。三个元素分别对应光源的红、绿、蓝值。

**数据类型：** Float64

  </div>
</div>

## 提示

- 灰度世界算法假设均匀光照和线性 RGB 值。如果您处理的是非线性的 sRGB 或 Adobe RGB 图像，请在使用 illumgray 之前使用 [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html) 函数取消伽马校正。此外，请确保使用 [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) 函数将经过色彩适应的图像转换回 sRGB。

- 当您指定 [Mask](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/illumgray.html#x3a4b5c6d) 时，底部百分位数和顶部百分位数应用于掩膜图像。

- 您可以使用 [chromadapt](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html) 函数调整图像的色彩平衡，以去除场景光照。

## 参考文献

\[1\] Ebner, Marc. "The Gray World Assumption." *Color Constancy*. Chichester, West Sussex: John Wiley & Sons, 2007.

## 另请参阅
[chromadapt](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html) | [lin2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/lin2rgb.html) | [rgb2lin](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/rgb2lin.html)
