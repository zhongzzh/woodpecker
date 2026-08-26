# imbilatfilt
---
高斯核图像的双边滤波

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = imbilatfilt(I)
J = imbilatfilt(I,degreeOfSmoothing)
J = imbilatfilt(I,degreeOfSmoothing,spatialSigma)
J = imbilatfilt(I,degreeOfSmoothing,spatialSigma,neighborhoodSize)
```

## 说明

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x74a67404) = imbilatfilt([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#f3dee3ff)) 将边缘保持高斯双边滤波器应用于灰度或 RGB 图像 I。

***
[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x74a67404) = imbilatfilt([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#f3dee3ff),[degreeOfSmoothing](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x0f549446)) 指定平滑的量。当 degreeOfSmoothing 是一个小值时，imbilatfilt 平滑方差较小的邻域（均匀区域），但不平滑方差较大的邻域，如强边。当 degreeOfSmoothing 的值增加时，imbilatfilt 平滑均匀区域和方差较大的邻域。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x0908b01a)

***
[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x74a67404) = imbilatfilt([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#f3dee3ff),[degreeOfSmoothing](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x0f549446),[spatialSigma](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#debc4c98)) 还指定了空间高斯平滑内核的标准偏差 spatialSigma。较大的 spatialSigma 值会增加距离较远的相邻像素的贡献，从而有效地增加邻域大小。

***
[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x74a67404) = imbilatfilt([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#f3dee3ff),[degreeOfSmoothing](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x0f549446),[spatialSigma](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#debc4c98),[neighborhoodSize](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#x6df086d3)) 使用关键字参数来更改双边筛选器的行为。

## 示例

<div id="x0908b01a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用高斯滤波器对图像进行平滑处理</summary>
</details>
<div class="details-content">

读取并显示灰度图像。观察天空区域的水平条纹伪影。

```julia
using TyImageProcessing
using TyPlot

I = imread("cameraman.tif");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Images/imbilatfilt/example1/example1.webp')">

检查天空区域的图像补丁。计算面片的方差，该方差近似于噪声的方差。

```julia
patch = imcrop(I, [170 35 50 50]);
imshow(patch)
```

<img :src="$withBase('/TyImageProcessing/Images/imbilatfilt/example1/example2.png')">

```julia
patchVar = std2(patch)^2;
```

使用双边滤波对图像进行滤波。将平滑度设置为大于噪声的方差。

```julia
DoS = 2 * patchVar;
J = imbilatfilt(I, DoS);
imshow(J)
title("Degree of Smoothing: $DoS")
```

<img :src="$withBase('/TyImageProcessing/Images/imbilatfilt/example1/example3.webp')">

条纹伪影减少了，但没有消除。若要改进平滑，请将spatialSigma的值增加到2，以便远处的相邻像素对高斯平滑内核的贡献更大。这有效地增加了双边滤波器的空间范围。

```julia
K = imbilatfilt(I, DoS, 2);
imshow(K)
title("Degree of Smoothing: $DoS, Spatial Sigma: 2")
```

<img :src="$withBase('/TyImageProcessing/Images/imbilatfilt/example1/example4.webp')">

成功移除了天空中的条纹伪影。强边缘（如男子的轮廓）和纹理区域（如图像前景中的草地）的清晰度得到了保留。

  </div>
</div>

## 输入参数

<div id="f3dee3ff" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 要滤波的图像<div>二维灰度图像 | 二维彩色图像</div></summary>
</details>
<div class="details-content">

要过滤的图像，指定为大小为 m×n 的二维灰度图像或大小为 m×n×3 的二维彩色图像。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="x0f549446" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>degreeOfSmoothing — 平滑度<div>正数</div></summary>
</details>
<div class="details-content">

平滑度，指定为正数。degreeOfSmoothing 的默认值取决于图像 I 的数据类型。

  </div>
</div>

<div id="debc4c98" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>spatialSigma — 空间高斯平滑核的标准差<div>1（默认） | 正数</div></summary>
</details>
<div class="details-content">

空间高斯平滑核的标准偏差，指定为正数。

  </div>
</div>

<div id="x6df086d3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>neighborhoodSize — 邻域大小<div>奇值正整数</div></summary>
</details>
<div class="details-content">

邻域大小，指定为奇数值的正整数。默认情况下，邻域大小为 2×ceil(2×spatialSigma)+1 像素

**数据类型：** Int64

  </div>
</div>

## 输出参数

<div id="x74a67404" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 滤波后的图像<div>数值数组</div></summary>
</details>
<div class="details-content">

滤波后的图像，以与输入图像 [I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html#f3dee3ff) 大小和类相同的数值数组形式返回。

  </div>
</div>