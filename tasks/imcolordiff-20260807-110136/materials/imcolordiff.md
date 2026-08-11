# imcolordiff
---
基于 CIE94 或 CIE2000 标准的色差

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
dE = imcolordiff(I1,I2)
dE = imcolordiff(I1,I2,Name=Value)
```

## 说明

[dE](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#dE) = imcolordiff([I1](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#I1),[I2](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#I2)) 使用 CIE94 标准计算彩色图像之间或两组颜色之间的色差。默认情况下，该函数假定颜色处于 sRGB 色彩空间中。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#eg1)

***
[dE](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#dE) = imcolordiff([I1](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#I1),[I2](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#I2),[Name=Value](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#name-value-arguments)) 使用一个或多个名称-值参数指定计算的其他方面，如输入色彩空间和 CIE 标准。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#eg4)

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 CIE94 标准计算图像的色差</summary>
</details>
<div class="details-content">

将一张彩色图像读取到工作空间中。

```julia
using TyImageProcessing
using TyPlot
using TyBase

I1 = imread("peppers.png");
imshow(I1)
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example1/peppers.png')">

改变图像中的局部颜色对比度。

```julia
pkg_dir = pkgdir(TyImageProcessing)
I2 = load(pkg_dir * "/resources/imcolordiff_exp1_I2.mat")["I2"]
imshow(I2)
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example1/localcontrast.png')">

使用默认的 CIE94 标准计算图像之间的色差。

```julia
dE = imcolordiff(I1, I2);
```

将色差作为图像显示。将显示范围缩放到 dE 的像素值范围。明亮的像素表示较大的色差。

```julia
imshow(dE, [])
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example1/imcolordiff.png')">

  </div>
</div>

<div id="eg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 CIE94 标准计算 L*a*b* 图像的色差</summary>
</details>
<div class="details-content">

读取并显示一张用苏木精和伊红（H&E）染色的组织图像。

```julia
using TyImageProcessing
using TyPlot

he = imread("hestain.png");
imshow(he)
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example2/hestain.png')">

将图像转换为 L\*a\*b\* 色彩空间。

```julia
lab = rgb2lab(he);
```

制作图像的副本，然后增加 a\* 通道的信号。图像中的红色调变得更加饱和，同时整体亮度和蓝色调保持不变。

```julia
lab2 = copy(lab);
scaleFactor = 1.1;
lab2[:, :, 2] = scaleFactor * lab[:, :, 2];
```

计算原始图像和增强图像在 L\*a\*b\* 色彩空间中的色差。

```julia
dE = imcolordiff(lab, lab2; isInputLab=true);
```

将色差作为图像显示。将显示范围缩放到与 dE 的像素值范围相匹配。明亮的区域表示最大的色差，并与组织中的粉红色区域对应。

```julia
imshow(dE, [])
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example2/imcolordiff.png')">

  </div>
</div>

<div id="eg3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 CIEDE2000 标准计算两种颜色的色差</summary>
</details>
<div class="details-content">

指定两个 RGB 颜色值。

```julia
using TyImageProcessing
using TyPlot

pureRed = UInt8.([255 0 0]);
darkRed = UInt8.([255 10 50]);
```

使用 CIEDE2000 标准计算这些颜色的色差。

```julia
dE = imcolordiff(pureRed, darkRed; Standard="CIEDE2000")
```

```dataframe
dE = 
7.444409565678752
```

  </div>
</div>

<div id="eg4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用纺织加权因子计算色差</summary>
</details>
<div class="details-content">

将一张彩色图像读取到工作空间中。

```julia
using TyImageProcessing
using TyPlot
using TyBase

fabric = imread("fabric.png");
imshow(fabric)
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example4/fabric.png')">

改变图像中的局部颜色对比度。

```julia
pkg_dir = pkgdir(TyImageProcessing)
fabric2 = load(pkg_dir * "/resources/imcolordiff_exp4_fabric2.mat")["fabric2"]
imshow(fabric2)
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example4/localcontrast.png')">

使用 CIEDE2000 标准计算这两个图像的色差。指定适用于纺织品的亮度系数和 K1、K2 加权因子。

```julia
dE = imcolordiff(fabric, fabric2; Standard="CIEDE2000", kL=2, K1=0.048, K2=0.014);
```

显示色差。将显示范围缩放到 dE 的像素值范围。

```julia
imshow(dE, [])
```

<img :src="$withBase('/TyImageProcessing/Images/imcolordiff/example4/imcolordiff.png')">

  </div>
</div>

## 输入参数

<div id="I1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I1 — 第一组颜色数据<div>1×3 数值向量 | c×3 数值矩阵 | 数值数组</div></summary>
</details>
<div class="details-content">

第一组颜色数据，指定为以下格式之一：

- 一个 1×3 的数值向量，表示参考颜色；

- 一个 c×3 的数值矩阵，表示 c 个颜色的集合；

- 一个 m×n×3 的数值数组，表示一张彩色图像；

- 一个多维数值数组，如 m×n×3×p 数组，表示一批彩色图像。第三维必须对应颜色通道并且有 3 个通道。

如果 [I2](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#I2) 不是参考颜色，则 I1 必须是参考颜色或与 I2 大小相同的数值数组。

I1 和 I2 必须处于相同的色彩空间。默认情况下，imcolordiff 函数期望 I1 和 I2 处于 sRGB 色彩空间。如果 I1 和 I2 处于 L\*a\*b\* 色彩空间，则需要将 isInputLab 参数指定为 true。L\*a\*b\* 颜色值只能是 Float32 或 Float64 数据类型。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

<div id="I2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I2 — 第二组颜色数据<div>1×3 数值向量 | c×3 数值矩阵 | 数值数组</div></summary>
</details>
<div class="details-content">

第二组颜色数据，指定为以下格式之一：

- 一个 1×3 的数值向量，表示参考颜色；

- 一个 c×3 的数值矩阵，表示 c 个颜色的集合；

- 一个 m×n×3 的数值数组，表示一张彩色图像；

- 一个多维数值数组，如 m×n×3×p 数组，表示一批彩色图像。第三维必须对应颜色通道并且有 3 个通道。

如果 [I1](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/imcolordiff.html#I1)  不是参考颜色，则 I2 必须是参考颜色或与 I1 大小相同的数值数组。

I1 和 I2 必须处于相同的色彩空间。默认情况下，imcolordiff 函数期望 I1 和 I2 处于 sRGB 色彩空间。如果 I1 和 I2 处于 L\*a\*b\* 色彩空间，则需要将 isInputLab 参数指定为 true。L\*a\*b\* 颜色值只能是 Float32 或 Float64 数据类型。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

## 名称-值参数
<div id="name-value-arguments" class="jump-target"></div>

指定可选的参数对作为 Name1=Value1,...,NameN=ValueN，其中 Name 是参数名称，Value 是相应的值。名称-值参数必须出现在其他参数之后，但是对这些对的顺序不重要。

示例：dE = imcolordiff（I1，I2，Standard=“CIEDE2000”）计算 使用CIEDE2000标准的两个RGB图像之间的颜色差异。

<div id="Standard" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Standard — CIE 标准<div>"CIE94"（默认） | "CIEDE2000"</div></summary>
</details>
<div class="details-content">

用于计算色差值的 CIE 标准，指定为以下值之一：

|值|描述|
|:---|:---|
|`"CIE94"`|CIE94 标准。该标准改善了 deltaE 函数中实现的 CIE76 标准的感知非均匀性。|
|`"CIEDE2000"`|CIEDE2000 标准。该标准通过五项附加校正进一步改善了感知均匀性：色调旋转项、中性色补偿以及亮度、色度和色调的补偿。|

  </div>
</div>

<div id="isLab" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>isInputLab — L*a*b*色彩空间中的颜色值<div>false（默认） | true</div></summary>
</details>
<div class="details-content">

颜色值在 L\*a\*b\* 色彩空间中，指定为逻辑值。

  </div>
</div>

<div id="kL" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>kL — 亮度系数<div>1（默认） | 数值标量</div></summary>
</details>
<div class="details-content">

亮度系数，指定为数值标量。kL 在图形艺术应用中通常为 1，在织物应用中通常为 2。

  </div>
</div>

<div id="kC" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>kC — 色度补偿系数<div>1（默认） | 数值标量</div></summary>
</details>
<div class="details-content">

色度补偿系数，指定为数值标量。kC 通常为 1。

  </div>
</div>

<div id="kH" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>kH — 色调补偿系数<div>1（默认） | 数值标量</div></summary>
</details>
<div class="details-content">

色调补偿系数，指定为数值标量。kH 通常为 1。

  </div>
</div>

<div id="K1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>K1 — K1 加权因子<div>0.045（默认） | 数值标量</div></summary>
</details>
<div class="details-content">

K1 加权因子，指定为数值标量。K1 加权因子仅适用于 CIE94 标准。该值在图形艺术应用中通常为 0.045，在织物应用中通常为 0.048。

  </div>
</div>

<div id="K2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>K2 — K2 加权因子<div>0.015（默认） | 数值标量</div></summary>
</details>
<div class="details-content">

K2 加权因子，指定为数值标量。K2 加权因子仅适用于 CIE94 标准。该值在图形艺术应用中通常为 0.015，在织物应用中通常为 0.014。

  </div>
</div>

## 输出参数

<div id="dE" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>dE — 色差<div>数值矩阵 | c×1 列向量 | 数值标量 | 数值数组</div></summary>
</details>
<div class="details-content">

色差（delta E），返回以下格式之一：

- m×n 数值矩阵：该数组表示两张彩色图像之间的逐像素色差，或表示一张彩色图像与参考颜色之间的色差；

- c×1 数值列向量：该向量表示两组颜色之间的色差，或表示一组颜色与参考颜色之间的色差；

- 数值标量：表示两个参考颜色之间的色差；

- 多维数值数组：该数组表示两批彩色图像之间的逐像素色差，或表示一批彩色图像与参考颜色之间的色差。第三维的长度为 1，表示色差。

如果 I1 或 I2 的数据类型为 Float64，则 dE 的数据类型为 Float64。否则，dE 的数据类型为 Float32。

**数据类型：** Float32 | Float64

  </div>
</div>

## 提示

- 要计算遵循 CIE76 标准的色差，请使用 deltaE 函数。该函数比 imcolordiff 函数更快，但精度较低。

- 通常应保持 kL、kC、kH、K1 和 K2 参数的默认值不变。这些值可根据特定行业群体（如图形艺术和织物）经过实验验证的照明条件进行更改。

## 参考文献

\[1\] Sharma, Gaurav, Wencheng Wu, and Edul N. Dalal, "The CIEDE2000 Color-Difference Formula: Implementation Notes, Supplementary Test Data, and Mathematical Observations." *Color Research and Application* 30, no. 1 (February 2005): 21–30. https://doi.org/10.1002/col.20070.

\[2\] ISO/CIE 11664-6:2014. "Colorimetry — Part 6: CIEDE2000 Colour-difference formula." *International Organization for Standardization*. URL: https://www.iso.org/standard/63731.html.

\[3\] CIE 116-1995. "Industrial Colour-Difference Evaluation (E)." *International Commission on Illumination (CIE)*. URL: https://cie.co.at/publications/industrial-colour-difference-evaluation.

## 另请参阅
[deltaE](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/deltaE.html) | [colorangle](/Doc/TyImageProcessing/Import,Export,andConversion/Color/MeasureColorDifferences/colorangle.html)