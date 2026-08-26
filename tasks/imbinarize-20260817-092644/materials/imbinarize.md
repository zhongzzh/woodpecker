# imbinarize
---
通过阈值化将二维灰度图像或三维体二值化

<h2>函数库: TyImageProcessing</h2>

## 语法

```
BW = imbinarize(I)
BW = imbinarize(I;method)
BW = imbinarize(I,T)
```

## 说明

[BW](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#x3a7fea06) = imbinarize([I](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#bd3940c3)) 输入图像，指定为二维灰度图像或三维灰度图像体。imbinarize 要求数据类型 Float64 和 Float32 的像素值在 [0, 1] 范围内。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#x1f12e9b7)

***
[BW](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#x3a7fea06) = imbinarize([I](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#bd3940c3);[method](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#f75c2420)) 使用 method 指定的阈值化方法（"global" 或 "adaptive"）从图像 I 创建二值图像。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#da44684a)

***
[BW](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#x3a7fea06) = imbinarize([I](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#bd3940c3),[T](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html#f7050482)) 使用阈值 T 从图像 I 创建二值图像。T 可以是指定为标量亮度值的全局图像阈值，也可以是指定为亮度值矩阵的局部自适应阈值。


## 示例

<div id="x1f12e9b7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用全局阈值对图像进行二值化</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("coins.png");
```

将图像转换为二值图像。

```julia
BW = imbinarize(I);
```

将原始图像与其二值版本进行显示。

```julia
figure()
imshowpair(I, BW, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/imbinarize/example1/example1.webp')">

  </div>
</div>

<div id="da44684a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用局部自适应阈值对图像进行二值化</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("rice.png");
```

将图像转换为二值图像。

```julia
BW = imbinarize(I; method = "adaptive");
```

将原始图像与其二值版本进行显示。

```julia
figure()
imshowpair(I, BW, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/imbinarize/example2/example1.webp')">

  </div>
</div>

## 输入参数

<div id="bd3940c3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 输入图像<div>二维灰度图像 | 三维灰度图像体</div></summary>
</details>
<div class="details-content">

输入图像，指定为二维灰度图像或三维灰度图像体。imbinarize 要求数据类型 Float32 和 Float64 的像素值在 [0, 1] 范围内。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="f75c2420" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>method — 用于二值化图像的方法<div>"global" (默认) | "adaptive"</div></summary>
</details>
<div class="details-content">

用于二值化图像的方法，指定为下列值之一。
| 值   | 意义   |
| ------ | ----------- |
| "global"    | 用 Otsu 方法计算全局图像阈值。     |
| "adaptive"    | 使用每个像素周围的局部一阶图像统计量来计算局部自适应图像阈值。     |

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="f7050482" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>T — 阈值<div>数值标量 | 数值数组</div></summary>
</details>
<div class="details-content">

亮度阈值，指定为由范围 [0, 1] 内的值组成的数值标量或数值数组。

* 如果 T 是数值标量，则 imbinarize 将 T 解释为全局图像阈值；

* 如果 T 是数值数组，则 imbinarize 将 T 解释为局部自适应阈值。

**数据类型：** Real

  </div>
</div>

## 输出参数

<div id="x3a7fea06" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW — 输出二值图像<div>逻辑矩阵</div></summary>
</details>
<div class="details-content">

输出二值图像，以与 I 大小相同的数组形式返回。

**数据类型：** Bool

  </div>
</div>