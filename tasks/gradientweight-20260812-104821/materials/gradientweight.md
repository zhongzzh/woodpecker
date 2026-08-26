# gradientweight
---
基于图像梯度为图像像素计算权重

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
W = gradientweight(I)
W = gradientweight(I, sigma)
W = gradientweight(___; Name=Value)
```

## 说明

[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#W) = gradientweight([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#I)) 计算图像 I 中每个像素基于该像素处梯度幅值的权重，并返回权重数组 W。像素的权重与该像素位置处的梯度值成反比。梯度幅值较小（平滑区域）的像素具有较大的权重，梯度幅值较大（如边缘处）的像素具有较小的权重。

***
[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#W) = gradientweight([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#I), [sigma](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#sigma)) 使用 sigma 作为计算图像梯度的高斯导数的标准差。

***
[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#W) = gradientweight(___; [Name=Value](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/gradientweight.html#namevalue)) 使用名称-值参量来控制权重计算的各个方面。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用从图像梯度导出的权重对图像进行分割</summary>
</details>
<div class="details-content">

读取图像并显示。

```julia
using TyImageProcessing
using TyPlot
using TyBase

I = imread("coins.png");
imshow(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/gradientweight/example1/coins.png')">

基于图像梯度计算权重。

```julia
sigma = 1.5;
W = gradientweight(I, sigma; RolloffFactor=3, WeightCutoff=0.25);
```

选择种子位置。

```julia
R = 70;
C = 216;
hold("on");
plot(C, R, "r."; linewidth=1.5, markersize=15);
title("Original Image with Seed Location")
```

<img :src="$withBase('/TyImageProcessing/Images/gradientweight/example1/SeedLocation.png')">

使用权重数组分割图像。

```julia
thresh = 0.1;
BW = load(pkgdir(TyImageProcessing) * "/resources/gradientweight_exp1_BW.mat")["BW"]
D = load(pkgdir(TyImageProcessing) * "/resources/gradientweight_exp1_D.mat")["D"]
figure(), imshow(BW)
title("Segmented Image")
hold("on");
plot(C, R, "r."; linewidth=1.5, markersize=15);
```

<img :src="$withBase('/TyImageProcessing/Images/gradientweight/example1/SegmentedImage.png')">

测地距离矩阵 D 可以使用不同的阈值来获得不同的分割结果。

```julia
figure(), imshow(D)
title("Geodesic Distances")
hold("on");
plot(C, R, "r."; linewidth=1.5, markersize=15);
```

<img :src="$withBase('/TyImageProcessing/Images/gradientweight/example1/GeodesicDistances.png')">

  </div>
</div>

## 输入参数

<div id="I" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 灰度图像<div>数值矩阵</div></summary>
</details>
<div class="details-content">

灰度图像，指定为二维数值矩阵或三维数值数组。

**数据类型：** Float32 | Float64 | Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32

  </div>
</div>

<div id="sigma" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sigma — 高斯导数的标准差<div>1.5 (默认) | 正数</div></summary>
</details>
<div class="details-content">

计算图像梯度时使用的高斯导数的标准差，指定为正数。

**数据类型：** Float64

  </div>
</div>

## 名称-值参数

<div id="namevalue" class="jump-target"></div>

将可选的参量对组指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参量名称，Value 是对应的值。名称-值参量必须出现在其他参量后，并以分号（;）分隔，但对各个参量对组的顺序没有要求。

**示例：** W = gradientweight(I, 1.5; RolloffFactor=3, WeightCutoff=0.25)

<div id="RolloffFactor" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RolloffFactor — 输出权重滚降因子<div>3 (默认) | 正标量</div></summary>
</details>
<div class="details-content">

输出权重滚降因子，指定为正标量。控制权重值作为梯度幅值函数下降的速度。当观察二维图时，像素强度值可能在区域边缘逐渐变化，形成平缓的斜坡。在分割后的图像中，您可能希望边缘更加清晰。使用滚降因子，您可以控制强度值开始变化处的权重值曲线的斜率。如果指定较大的值，输出权重值在平滑区域边缘附近会急剧下降。如果指定较小的值，输出权重在边缘附近会有更平缓的下降。该参数的推荐范围为 [0.5, 4]。

**数据类型：** Float64

  </div>
</div>

<div id="WeightCutoff" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>WeightCutoff — 权重值的阈值<div>0.25 (默认) | [1e-3, 1] 范围内的正数</div></summary>
</details>
<div class="details-content">

权重值的阈值，指定为 [1e-3, 1] 范围内的正数。使用此参数设置权重值的阈值时，会抑制任何小于指定值的权重值，将这些像素设置为一个小的常量值（1e-3）。当输出权重数组 W 用作快速行进法分割函数 imsegfmm 的输入时，此参数有助于提高输出的准确性。

**数据类型：** Float64

  </div>
</div>

## 输出参数

<div id="W" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>W — 权重数组<div>数值数组</div></summary>
</details>
<div class="details-content">

权重数组，以与输入图像 I 大小相同的数值数组形式返回。如果输入图像的数据类型为 Float32，则 W 的数据类型为 Float32；否则 W 的数据类型为 Float64。

**数据类型：** Float32 | Float64

  </div>
</div>

## 提示

gradientweight 对所有数据类型（除 Float32 外）的 I 使用双精度浮点运算进行内部计算。当 I 为 Float32 类型时，gradientweight 在内部使用单精度浮点运算。

## 另请参考

[graydiffweight](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html)
