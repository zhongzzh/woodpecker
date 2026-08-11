# edgetaper
---
沿图像边缘逐渐减小不连续性

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = edgetaper(I,PSF)
```

## 说明

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/edgetaper.html#x1f7a3b51) = edgetaper([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/edgetaper.html#a2b8c4d6),[PSF](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/edgetaper.html#b3c9d5e7)) 使用点扩散函数 PSF 模糊输入图像 I 的边缘。

输出图像 J 是原始图像 I 与其模糊版本的加权和。加权数组由 PSF 的自相关函数确定，使 J 在中心区域等于 I，在边缘附近等于 I 的模糊版本。

edgetaper 函数可减少使用离散傅里叶变换的图像去模糊方法（如 [deconvwnr](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/deconvwnr.html)、 deconvreg 和 [deconvlucy](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/deconvlucy.html)）中的振铃效应。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/edgetaper.html#c4d0e6f8)

## 示例

<div id="c4d0e6f8" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>模糊图像边缘</summary>
</details>
<div class="details-content">

将图像读入工作区，创建高斯点扩散函数并对图像边缘进行渐变处理，然后显示原始图像和结果。

```julia
using TyImageProcessing
using TyPlot

original = imread("cameraman.tif");
PSF = fspecial("gaussian", 60, 10);
edgesTapered = edgetaper(original, PSF);
figure(), imshow(original, []);
```

<img :src="$withBase('/TyImageProcessing/Images/edgetaper/example1/cameraman.png')">

```
figure(), imshow(edgesTapered, []);
```

<img :src="$withBase('/TyImageProcessing/Images/edgetaper/example1/edgetaper.png')">

  </div>
</div>

## 输入参数

<div id="a2b8c4d6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 输入图像<div>数值数组</div></summary>
</details>
<div class="details-content">

输入图像，指定为数值数组。

**数据类型：** Float32 | Float64 | Int16 | UInt8 | UInt16

  </div>
</div>

<div id="b3c9d5e7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>PSF — 点扩散函数<div>数值数组</div></summary>
</details>
<div class="details-content">

点扩散函数，指定为数值数组。PSF 在任何维度上的大小不能超过图像尺寸的一半。

**数据类型：** Float32 | Float64 | Int16 | UInt8 | UInt16

  </div>
</div>

## 输出参数

<div id="x1f7a3b51" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 原始图像与其模糊版本的加权和<div>数值数组</div></summary>
</details>
<div class="details-content">

原始图像与其模糊版本的加权和，以与 [I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/edgetaper.html#a2b8c4d6) 相同大小和数据类型的数值数组形式返回。加权数组由 [PSF](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/edgetaper.html#b3c9d5e7) 的自相关函数确定，使 J 在中心区域等于 I，在边缘附近等于 I 的模糊版本。

  </div>
</div>

## 参考

[deconvlucy](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/deconvlucy.html) | [deconvwnr](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/deconvwnr.html) | [otf2psf](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/otf2psf.html) | [padarray](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/padarray.html) | [psf2otf](/Doc/TyImageProcessing/ImageFilteringandEnhancement/Deblurring/psf2otf.html)