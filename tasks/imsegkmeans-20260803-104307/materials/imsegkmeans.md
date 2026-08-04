# imsegkmeans
---
基于 K 均值聚类的图像分割

<h2>函数库: TyImageProcessing</h2>

## 语法

```
L, = imsegkmeans(I,k)
L,centers = imsegkmeans(I,k)
L, = imsegkmeans(I,k;Name=Value)
```

## 说明

[L](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x91df65c9), = imsegkmeans([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x7150c595),[k](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x812f2d68)) 通过执行 k 均值聚类将图像 I 分割成 k 个簇，并在 L 中返回分割后带标签的输出。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x7d4a0c98)

***
[L](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x91df65c9),[centers](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x3930f20b) = imsegkmeans([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x7150c595),[k](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x812f2d68)) 还返回簇质心位置 centers。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#ea4370a3)

***
[L](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x91df65c9), = imsegkmeans(I,k;[Name=Value](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/imsegkmeans.html#x20087d83)) 使用名称-值参量来控制 k 均值聚类算法的各个方面。

## 示例

<div id="x7d4a0c98" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 k 均值聚类分割灰度图像</summary>
</details>
<div class="details-content">

将图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("cameraman.tif");
imshow(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imsegkmeans/example1/example1.webp')">

使用 k 均值聚类将图像分割成三个区域。

```julia
L, Centers = imsegkmeans(I, 3);
B = labeloverlay(I, L);
imshow(B)
title("Labeled Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imsegkmeans/example1/example2.webp')">

  </div>
</div>

<div id="ea4370a3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 k 均值分割压缩彩色图像</summary>
</details>
<div class="details-content">

将图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("peppers.png");
imshow(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imsegkmeans/example3/example1.webp')">

使用 k 均值聚类将图像分割成 50 个区域。返回标签矩阵 L 和簇质心位置 C。簇质心位置是 50 种颜色中每种颜色的 RGB 值。

```julia
L, C = imsegkmeans(I, 50);
```

将标签矩阵转换为 RGB 图像。指定簇质心位置 C 作为新图像的颜色图。

```julia
J = label2rgb(L, im2double(C));
```

显示量化图像。

```julia
imshow(J)
title("Color Quantized Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imsegkmeans/example3/example2.webp')">

将原始图像和压缩图像写入文件。量化的图像文件大约是原始图像文件大小的四分之一。

```julia
imwrite(I, "peppersOriginal.png");
imwrite(J, "peppersQuantized.png");
```

  </div>
</div>

<div id="使用备用颜色空间改进K均值分割" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用备用颜色空间改进 K 均值分割</summary>
</details>
<div class="details-content">

读取并显示一个用苏木精-伊红 (H&E) 染色组织的图像。这种染色方法有助于病理学家区分染成蓝-紫色和粉红色的组织类型。

```julia
using TyImageProcessing
using TyPlot

he = imread("hestain.png");
imshow(he)
title("H&E Image");
text(
    size(he, 2),
    size(he, 1) + 15,
    "Image courtesy of Alan Partin, Johns Hopkins University";
    fontsize=7,
    horizontalalignment="right",
);
```

<img :src="$withBase('/TyImageProcessing/Images/imsegkmeans/example4/example1.webp')">

使用 rgb2lab 函数将图像转换到 L\*a\*b\* 颜色空间。L\*a\*b\* 颜色空间将图像的光度和颜色分开。这使得按颜色分割区域变得更加容易并且与亮度无关。

```julia
lab_he = rgb2lab(he);
```

要仅使用颜色信息分割图像，请将图像限制为 lab_he 中的 a* 和 b* 值。将图像转换为数据类型 Float32，以便与 imsegkmeans 结合使用。使用 imsegkmeans 函数将图像分割成三个区域。

```julia
ab = lab_he[:, :, 2:3];
ab = im2single(ab);
numColors = 3;
L2, = imsegkmeans(ab, numColors);
```

将标注图像叠加显示在原始图像上。标注图像将白色、蓝紫色和粉色染色组织区域分开。

```julia
B2 = labeloverlay(he, L2);
imshow(B2)
title("Labeled Image a*b*")
```

<img :src="$withBase('/TyImageProcessing/Images/imsegkmeans/example4/example2.webp')">

  </div>
</div>

## 输入参数

<div id="x7150c595" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 要分割的图像<div>二维灰度图像 | 二维彩色图像 | 二维多光谱图像</div></summary>
</details>
<div class="details-content">

要分割的图像，指定为二维灰度图像、二维彩色图像或二维多光谱图像。如果原始图像的数据类型为 Float64，请使用 im2single 函数将图像转换为 Float32 数据类型。

**数据类型：** Float32 | Int8 | Int16 | UInt8 | UInt16

  </div>
</div>

<div id="x812f2d68" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>k — 簇的数量<div>正整数</div></summary>
</details>
<div class="details-content">

要创建的簇的数量，指定为正整数。

  </div>
</div>

<div id="x20087d83" class="jump-target"></div>

### 名称-值参数
将可选的参量对组指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参量名称，Value 是对应的值。名称-值参量必须出现在其他参量后，但对各个参量对组的顺序没有要求。

**示例：** imsegkmeans(I,k;NumAttempts=5) 重复聚类过程五次。

<div id="NormalizeInput—归一化输入数据" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>NormalizeInput — 归一化输入数据<div>true(默认) | false</div></summary>
</details>
<div class="details-content">

将输入数据归一化为零均值和单位方差，指定为逻辑值 true 或 false。如果您指定 true，则 imsegkmeans 单独归一化输入的每个通道。

  </div>
</div>

<div id="NumAttempts—重复聚类过程的次数" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>NumAttempts — 重复聚类过程的次数<div>3 (默认) | 正整数</div></summary>
</details>
<div class="details-content">

使用新初始簇质心位置重复聚类过程的次数，指定为正整数。

  </div>
</div>

<div id="MaxIterations—最大迭代次数" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>MaxIterations — 最大迭代次数<div>100 (默认) | 正整数</div></summary>
</details>
<div class="details-content">

迭代的最大次数，指定为正整数。

  </div>
</div>

<div id="Threshold—准确度阈值" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Threshold — 准确度阈值<div>1e-4 (默认) | 正数</div></summary>
</details>
<div class="details-content">

准确度阈值，指定为正值。当每个簇中心在连续迭代中的移动小于阈值时，算法停止。

  </div>
</div>

## 输出参数

<div id="x91df65c9" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>L — 标签矩阵<div>正整数矩阵</div></summary>
</details>
<div class="details-content">

标签矩阵，指定为正整数矩阵。标签为 1 的像素属于第一个簇，标签为 2 的像素属于第二个簇，对全部 k 个簇依此类推。L 的前两个维度与图像 I 相同。L 的数据类型取决于簇的数量。

| L 的数据类型 | 簇的数量               |
| -------------- | ---------------------- |
| UInt8        | k <= 255             |
| UInt16       | 256 <= k <= 65535    |
| UInt32       | 65536 <= k <= 2^32-1 |
| Float64       | 2^32 <= k            |

  </div>
</div>

<div id="x3930f20b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>centers — 簇质心位置<div>数值矩阵</div></summary>
</details>
<div class="details-content">

簇质心位置，以数值矩阵形式返回，大小为 k×c，其中 k 是簇的数量，c 是通道数量。centers 与图像 I 属于同一种数据类型。

  </div>
</div>

## 提示

该函数生成不可重现的结果。给定相同的输入参量，输出会在多次运行中发生变化。