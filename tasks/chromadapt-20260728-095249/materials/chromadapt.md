# chromadapt
---
通过色彩适应调整 RGB 图像的色彩平衡

<h2>函数库: TyImageProcessing</h2>

## 语法

```
B = chromadapt(A, illuminant)
B = chromadapt(A, illuminant; Name=Value)
```

## 说明

[B](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x1a2b3c4d) = chromadapt([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x5e6f7a8b), [illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x9c0d1e2f)) 根据场景光源调整 sRGB 图像 A 的色彩平衡。光源必须与输入图像处于同一颜色空间。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x3a4b5c6d)

***
[B](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x1a2b3c4d) = chromadapt([A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x5e6f7a8b), [illuminant](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x9c0d1e2f); Name=Value) 使用名称-值参数调整 A 的色彩平衡，以控制其他选项。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x7d8e9f0a)

## 示例

<div id="x3a4b5c6d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>通过指定灰色像素进行色彩平衡</summary>
</details>
<div class="details-content">

读取并显示一张具有强烈黄色色偏的图像。

```julia
using TyImageProcessing
using TyPlot

A = imread("hallway.jpg")
imshow(A)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/chromadapt/example1/originalImage.png')">

选取图像中应该显示为白色或灰色的像素点作为场景光源参考。请勿选取饱和像素（如天花板灯光上的点）。将选定点以绿色显示。

```julia
x = 2800
y = 1000
gray_val = impixel(A, x, y)
hold("on")
plot(x, y, "."; color="g")
hold("off")
```

<img :src="$withBase('/TyImageProcessing/Images/chromadapt/example1/plotedImage.png')">

使用该选定颜色作为场景光源参考，校正图像的白平衡。

```julia
B = chromadapt(A, gray_val)
```

显示校正后的图像。校正后的图像中，原本偏黄的柱子将呈现为白色，图像其余部分没有黄色色调。

```julia
figure()
imshow(B)
title("White-Balanced Image")
```
<img :src="$withBase('/TyImageProcessing/Images/chromadapt/example1/White-BalancedImage.png')">

  </div>
</div>

<div id="x7d8e9f0a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>在线性 RGB 颜色空间中调整色彩平衡</summary>
</details>
<div class="details-content">

打开包含最小处理线性 RGB 强度的图像文件。

```julia
using TyImageProcessing
using TyPlot

A = imread("foosballraw.tiff")
```

图像数据为校正黑电平并缩放到每像素 16 位后的原始传感器数据。对强度值进行插值以重建颜色，颜色滤波阵列模式为 RGGB。

```julia
A = demosaic(A, "rggb")
```

显示图像，由于图像位于线性 RGB 颜色空间中，应用伽马校正使图像在屏幕上正确显示。

```julia
A_sRGB = lin2rgb(A)
imshow(A_sRGB)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/chromadapt/example2/OriginalImage.png')">

场景中有一个 ColorChecker 图表。要获取环境光的颜色，显示图表中某个中性补丁像素的 RGB 值。红色通道的强度低于其他两个通道，指示光线为蓝绿色。

```julia
x = 1510
y = 1250
light_color = [A[y, x, 1] A[y, x, 2] A[y, x, 3]]
```

```dataframe
1×3 Matrix{UInt16}:
 0x32d2  0x32d2  0x32d2
```

平衡图像的颜色通道。使用 ColorSpace 键值参数指定图像和光源均以线性 RGB 表示。

```julia
B = chromadapt(A, light_color; ColorSpace="linear-rgb")
```

显示经过伽马校正的色彩平衡图像。

```julia
B_sRGB = lin2rgb(B)
figure()
imshow(B_sRGB)
title("Color-Balanced Image")
```

<img :src="$withBase('/TyImageProcessing/Images/chromadapt/example2/Color-BalancedImage.png')">

确认灰色补丁已实现色彩平衡。如同预期，色彩平衡后的灰色补丁中三个颜色通道具有相似的强度值。

```julia
patch_color = [B[y, x, 1] B[y, x, 2] B[y, x, 3]]
```

```dataframe
1×3 Matrix{UInt16}:
 0x32d2  0x32d2  0x32d2
```

  </div>
</div>

## 输入参数

<div id="x5e6f7a8b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — RGB 图像<div>m×n×3 数值数组</div></summary>
</details>
<div class="details-content">

RGB 图像，指定为 m×n×3 的数值数组。输入的图像必须是非空的真实彩色 RGB 图像。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

<div id="x9c0d1e2f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>illuminant — 场景光源<div>3 元素数值向量</div></summary>
</details>
<div class="details-content">

场景光源，指定为 3 元素数值向量。光源必须与输入图像 [A](/Doc/TyImageProcessing/Import,Export,andConversion/Color/AutomaticWhiteBalance/chromadapt.html#x5e6f7a8b),  处于同一颜色空间。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

## 名称-值参数

可选参数对以分号分隔，指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参数名称，Value 是对应的值。名称-值参数必须出现在其他参数之后，但参数对的顺序不重要。

**示例：** B = chromadapt(A, uint8([22 97 118]); ColorSpace="linear-rgb") 在线性 RGB 颜色空间中调整图像 A 的色彩平衡。

<div id="x0b1c2d3e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ColorSpace — 颜色空间<div>"srgb" (默认) | "adobe-rgb-1998" | "prophoto-rgb" | "linear-rgb"</div></summary>
</details>
<div class="details-content">

输入图像和光源的颜色空间，指定为以下值之一。

| 值                   | 说明                                          |
| ---------------------- | ----------------------------------------------- |
| "srgb"              | sRGB 颜色空间（默认）                        |
| "adobe-rgb-1998"    | Adobe RGB 1998 颜色空间                      |
| "prophoto-rgb"      | ProPhoto (ROMM RGB) 颜色空间，具有比 sRGB 和 Adobe RGB 1998 更广的色域 |
| "linear-rgb"        | 线性 RGB 颜色空间，适用于强度为线性的 RGB 图像 |

**数据类型：** String

  </div>
</div>

<div id="x4f5g6h7i" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Method — 色彩适应方法<div>"bradford" (默认) | "vonkries" | "simple"</div></summary>
</details>
<div class="details-content">

用于缩放 A 中 RGB 值的色彩适应方法，指定为以下值之一。

| 值           | 说明                                   |
| -------------- | ---------------------------------------- |
| "bradford"   | 使用 Bradford 锥体响应模型进行缩放（默认） |
| "vonkries"   | 使用 von Kries 锥体响应模型进行缩放      |
| "simple"     | 直接使用光源值进行缩放                   |

Bradford 方法是最常用的色彩适应模型，在大多数场景下都能提供良好的结果。von Kries 方法是一种经典的色彩适应模型。simple 方法直接通过光源值对各通道进行缩放，计算最为简单。

**数据类型：** String

  </div>
</div>

## 输出参数

<div id="x1a2b3c4d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>B — 色彩平衡后的 RGB 图像<div>m×n×3 数值数组</div></summary>
</details>
<div class="details-content">

色彩平衡后的 RGB 图像，返回为与 A 相同大小的 m×n×3 数值数组。输出图像的数据类型与输入图像 A 相同。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>
