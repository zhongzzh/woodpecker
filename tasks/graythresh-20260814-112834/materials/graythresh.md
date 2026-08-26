# graythresh
---
使用 Otsu 方法计算全局图像阈值

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
T = graythresh(I)
```

## 说明

[T](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/graythresh.html#x37056b14) = graythresh([I](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/graythresh.html#x23150228)) 使用 Otsu 方法根据灰度图像 I 计算全局阈值 T。Otsu 方法选择一个阈值，使阈值化的黑白像素的类内方差最小化。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/graythresh.html#x79c450bc)

## 示例

<div id="x79c450bc" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用灰度级阈值将强度图像转换为二值图像</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("coins.png");
```

使用 graythresh 计算阈值。阈值归一化至范围 [0, 1]。

```julia
level = graythresh(I)
```

level = 0.49411764705882355

使用阈值将图像转换为二值图像。

```julia
BW = imbinarize(I, level);
```

在二值图像旁边显示原始图像。

```julia
imshowpair(I, BW, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/graythresh/example1/example1.webp')">

  </div>
</div>

## 输入参数

<div id="x23150228" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 灰度图像<div>数值数组</div></summary>
</details>
<div class="details-content">

灰度图像，指定为任意维度的数值数组

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

## 输出参数

<div id="x37056b14" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>T — 全局阈值<div>非负数</div></summary>
</details>
<div class="details-content">

全局阈值，以范围 [0, 1] 内的非负数形式返回。

**数据类型：** Float64

  </div>
</div>

## 提示

- 默认情况下，函数 imbinarize 使用通过 Otsu 方法获得的阈值创建二值图像。该默认阈值与 graythresh 返回的阈值相同。但是，imbinarize 只返回二值图像。如果您需要灰度级或有效性度量，请在调用 imbinarize 之前使用 graythresh。