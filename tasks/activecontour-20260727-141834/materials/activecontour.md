# activecontour
---
使用主动轮廓 (snake) 区域增长方法将图像分割成前景和背景

<h2>函数库: TyImageProcessing</h2>

## 语法

```
BW = activecontour(A,mask)
BW = activecontour(A,mask,n)
```

## 说明

主动轮廓方法，也称为 snake，是一种迭代式区域增长图像分割算法。使用主动轮廓算法，您可以在图像上指定初始曲线，然后使用 activecontour 函数使曲线向对象边界演化。

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#b4e07384) = activecontour([A](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#b14c579c),[mask](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#x1401e884)) 使用主动轮廓将图像 A 分割成前景（对象）和背景区域。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#a2c13435)

mask 参量是一个指定主动轮廓初始状态的二值图像。mask 中对象区域（白色）的边界定义轮廓演化的初始轮廓位置，以用于分割图像。输出图像 BW 是一个二值图像，前景为白色（逻辑 true），背景为黑色（逻辑 false）。

要获得更快、更准确的分割结果，请指定靠近所需对象边界的初始轮廓位置。

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#b4e07384) = activecontour([A](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#b14c579c),[mask](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#x1401e884),[n](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#f5b7b80d)) 通过最多迭代 n 次的轮廓演化来分割图像。

## 示例

<div id="a2c13435" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用主动轮廓分割图像</summary>
</details>
<div class="details-content">

读取并显示灰度图像。

```julia
using TyImageProcessing
using TyPlot

I = imread("coins.png");
imshow(I)
title("Original Image")
```
<img :src="$withBase('/TyImageProcessing/Images/activecontour/example1/example1.webp')">

指定感兴趣对象周围的初始轮廓。显示该轮廓。

```julia
mask = zeros(size(I));
mask[25:(end - 25), 25:(end - 25)] .= 1;
imshow(mask)
title("Initial Contour Location")
```

<img :src="$withBase('/TyImageProcessing/Images/activecontour/example1/example2.png')">

使用 activecontour 函数分割图像。默认情况下，该函数通过 100 次迭代进行分割演化。

```julia
bw = activecontour(I, mask);
```

显示结果。经过 100 次迭代后，对象并未从背景中完全分割出来，因为原始轮廓没有接近对象边界。

```julia
imshow(bw)
title("Segmented Image, 100 Iterations")
```

<img :src="$withBase('/TyImageProcessing/Images/activecontour/example1/example3.png')">

要继续进行分割演化，请增加迭代次数。经过 300 次迭代，对象从背景中完全分割出来。

```julia
bw = activecontour(I, mask, 300);
imshow(bw)
title("Segmented Image, 300 Iterations")
```

<img :src="$withBase('/TyImageProcessing/Images/activecontour/example1/example4.png')">

  </div>
</div>

## 输入参数

<div id="b14c579c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — 要分割的图像<div>二维数值矩阵</div></summary>
</details>
<div class="details-content">

要分割的图像，指定为二维数值矩阵。

**数据类型：** Float32 | Float64 | Int16 | UInt8 | UInt16

  </div>
</div>

<div id="x1401e884" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>mask — 初始轮廓<div>二值图像</div></summary>
</details>
<div class="details-content">

分割开始演化时的初始轮廓，指定为与 A 大小相同的二值图像。对于二维灰度图像，mask 的大小必须与图像 A 的大小相匹配。

**数据类型：** Bool

  </div>
</div>

<div id="f5b7b80d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>n — 最大迭代次数<div>100 (默认) | 正整数</div></summary>
</details>
<div class="details-content">

分割演化中要执行的最大迭代次数，指定为正整数。当主动轮廓达到最大迭代次数时，activecontour 停止主动轮廓的演化。如果当前迭代中的轮廓位置与最近五次迭代之一中的轮廓位置相同，activecontour 也会停止演化。

如果初始轮廓位置（由 [mask](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#x1401e884) 指定）远离对象边界，请指定较大的 n 值以获得所需的分割结果。

  </div>
</div>


## 输出参数

<div id="b4e07384" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW — 分割后的图像<div>逻辑数组</div></summary>
</details>
<div class="details-content">

分割后的图像，以与输入图像 [A](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#b14c579c) 大小相同的逻辑数组形式返回。前景是白色（逻辑 true），背景是黑色（逻辑 false）。

**数据类型：** Bool

  </div>
</div>

## 提示

- activecontour 使用 [mask](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/activecontour.html#x1401e884) 中区域的边界作为演化开始时轮廓的初始状态。掩膜上的孔洞可能会导致不可预测的结果。请使用 imfill 填充 mask 区域中的孔洞。

- 如果某个区域触及图像边界，则 activecontour 在进一步处理之前，会从该区域中删除单像素层，以便该区域不会触及图像边界。

- 要获得更快、更准确的结果，请指定靠近所需对象边界的初始轮廓位置。