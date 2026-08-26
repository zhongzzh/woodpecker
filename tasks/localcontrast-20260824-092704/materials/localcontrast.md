# localcontrast
---
图像的边缘感知局部对比度调整

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
B = localcontrast(A)
B = localcontrast(A, edgeThreshold, amount)
```

## 说明

[B](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#B) = localcontrast([A](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#A)) 增强灰度或 RGB 图像 A 的局部对比度。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#eg1)

***

[B](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#B) = localcontrast([A](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#A), [edgeThreshold](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#edgeThreshold), [amount](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/localcontrast.html#amount)) 通过增强或平滑细节来增强或减弱图像 A 的局部对比度，同时保持强边缘不变。edgeThreshold 定义要保留不变的强边缘的最小强度振幅。amount 是所需的增强或平滑量。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>增加或减少图像的局部对比度</summary>
</details>
<div class="details-content">

导入一幅 RGB 图像。

```julia
using TyImageProcessing
using TyPlot

A = imread("peppers.png");
```

增加输入图像的局部对比度。

```julia
edgeThreshold = 0.4;
amount = 0.5;
B = localcontrast(A, edgeThreshold, amount);
```

将结果与原图像进行比较显示。

```julia
imshowpair(A, B, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/localcontrast/example1/example1.png')">

降低输入图像的局部对比度。

```julia
figure()
amount = -0.5;
B2 = localcontrast(A, edgeThreshold, amount);
```

再次将新结果与原图像进行比较显示。

```julia
imshowpair(A, B2, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/localcontrast/example1/example2.png')">

  </div>
</div>

## 输入参数

<div id="A" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — 要滤波的灰度或 RGB 图像<div>灰度图像 | RGB 图像</div></summary>
</details>
<div class="details-content">

要滤波的灰度或 RGB 图像，指定为 m×n 或 m×n×3 的实数非稀疏矩阵。

**数据类型：** Float32 | UInt8 | UInt16 | Int8 | Int16

  </div>
</div>

<div id="edgeThreshold" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>edgeThreshold — 要保留不变的强边缘的振幅<div>0.3（默认） | [0,1] 范围内的数值标量</div></summary>
</details>
<div class="details-content">

要保留不变的强边缘的振幅，指定为 [0,1] 范围内的数值标量。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="amount" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>amount — 所需的增强或平滑量<div>0.25（默认） | [-1,1] 范围内的数值标量</div></summary>
</details>
<div class="details-content">

所需的增强或平滑量，指定为 [-1,1] 范围内的数值标量。负值指定边缘感知平滑。正值指定边缘感知增强。

| 值 | 说明 |
| --- | --- |
| 0 | 保持输入图像不变 |
| 1 | 强烈增强输入图像的局部对比度 |
| -1 | 强烈平滑输入图像的细节 |

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

## 输出参数

<div id="B" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>B — 滤波后的图像<div>数值数组</div></summary>
</details>
<div class="details-content">

滤波后的图像，作为与输入图像 A 同样大小和数据类型的数值数组返回。

**数据类型：** Float32 | UInt8 | UInt16 | Int8 | Int16

  </div>
</div>
