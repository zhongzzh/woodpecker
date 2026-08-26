# locallapfilt
---
图像的快速局部拉普拉斯滤波

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = locallapfilt(I,sigma,alpha)
J = locallapfilt(I,sigma,alpha,beta)
J = locallapfilt(___;Name=Value)
```

## 说明

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x8a3b5c7d) = locallapfilt([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x1f2e3d4c),[sigma](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x0a1b2c3d),[alpha](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x9e8f7a6b)) 使用边缘感知的快速局部拉普拉斯滤波器对灰度图像或 RGB 图像 I 进行滤波。sigma 表征 I 中边缘的振幅，alpha 控制细节的平滑程度。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x77a1b2c3)

***

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x8a3b5c7d) = locallapfilt([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x1f2e3d4c),[sigma](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x0a1b2c3d),[alpha](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x9e8f7a6b),[beta](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x5c4d3e2f)) 使用 beta 控制 I 的动态范围，对图像进行滤波。

***

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x8a3b5c7d) = locallapfilt(___;[Name=Value](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x11aa22bb)) 使用名称-值参数来控制滤波器的高级方面。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x99a7b8c9)

## 示例

<div id="x77a1b2c3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用局部拉普拉斯滤波增强 RGB 图像的局部对比度</summary>
</details>
<div class="details-content">

读入 RGB 图像。

```julia
using TyImageProcessing

A = imread("peppers.png");
```

设置滤波器参数，增强小于 0.4 的细节。

```julia
sigma = 0.4;
alpha = 0.5;
```

使用快速局部拉普拉斯滤波增强图像。

```julia
B = locallapfilt(A, sigma, alpha);
```

并排显示原图像与增强后的图像。

```julia
imshowpair(A, B, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example1/montage.png')">

  </div>
</div>

<div id="x88d4e5f6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>平衡局部拉普拉斯滤波的速度和质量</summary>
</details>
<div class="details-content">

局部拉普拉斯滤波是一种计算量较大的算法。为了加快处理速度，locallapfilt 通过将强度范围离散为若干个采样来近似该算法，采样数由 NumIntensityLevels 参数定义。此参数可用于平衡速度与质量。

读入并显示 RGB 图像。

```julia
using Printf
using TyImageProcessing
using TyPlot

A = imread("peppers.png");
figure()
imshow(A)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example2/OriginalImage.png')">

使用 sigma 值处理细节，使用 alpha 值增强对比度，从而有效地增强图像的局部对比度。

```julia
sigma = 0.2;
alpha = 0.3;
```

使用较少的采样数可以提高执行速度，但可能产生可见的伪影，尤其是在对比度平坦的区域。仅使用 20 个强度级别处理图像，并测量执行时间。

```julia
t_speed = @elapsed B_speed = locallapfilt(A, sigma, alpha; NumIntensityLevels=20);
```

```dataframe
t_speed =
0.025879
```

```julia
figure()
imshow(B_speed)
title(@sprintf("Enhanced with 20 intensity levels in %.5f sec", t_speed))
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example2/Enhanced20.png')">

较多的采样数会以更多的处理时间为代价，获得更好的结果。使用 100 个强度级别处理图像，并测量执行时间。

```julia
t_quality = @elapsed B_quality = locallapfilt(A, sigma, alpha; NumIntensityLevels=100);
```

```dataframe
t_quality =
0.1037831
```

```julia
figure()
imshow(B_quality)
title(@sprintf("Enhancement with 100 intensity levels in %.5f sec", t_quality))
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example2/Enhanced100.png')">

可以在自己的图像上尝试改变强度级别数，也可以尝试压缩对比度（alpha > 1）。最佳强度级别数因图像而异，并随 alpha 变化。默认情况下，locallapfilt 使用启发式方法来平衡速度和质量，但无法预测每张图像的最佳值。

  </div>
</div>

<div id="x99a7b8c9" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 ColorMode 增强局部颜色对比度</summary>
</details>
<div class="details-content">

读入彩色图像，缩小其尺寸并显示。

```julia
using TyImageProcessing
using TyPlot

A = imread("car2.jpg")
A = imresize(A, 0.25);
figure()
imshow(A)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example3/OriginalImage.png')">

设置滤波器参数，以大幅增强小于 0.3 的细节（归一化范围为 0 到 1）。

```julia
sigma = 0.3;
alpha = 0.1;
```

比较两种不同的颜色滤波模式：分别通过滤波其亮度与分别滤波每个颜色通道来处理图像。

```julia
B_luminance = locallapfilt(A, sigma, alpha);
B_separate = locallapfilt(A, sigma, alpha; ColorMode="separate");
```

显示通过增强局部亮度对比度滤波的图像。

```julia
figure()
imshow(B_luminance)
title("Enhanced by boosting the local luminance contrast")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example3/EnhancedLuminance.png')">

显示通过增强局部颜色对比度滤波的图像。

```julia
figure()
imshow(B_separate)
title("Enhanced by boosting the local color contrast")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example3/EnhancedColor.png')">

每张图像都应用了相同数量的对比度增强，但将 ColorMode 设置为 "separate" 时颜色更加饱和。

  </div>
</div>

<div id="xaab1c2d3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>执行边缘感知降噪</summary>
</details>
<div class="details-content">

读入图像，并将图像转换为单精度浮点数，以便更容易地添加人工噪声。

```julia
using Printf
using TyImageProcessing
using TyPlot

A = imread("pout.tif");
A = im2single(A);
```

添加均值为 0、方差为 0.001 的高斯噪声，并计算含噪图像的峰值信噪比。

```julia
A_noisy = imnoise(A, "gaussian", 0, 0.001);
psnr_noisy = psnr(A_noisy, A);
@printf("The peak signal-to-noise ratio of the noisy image is %0.4f\n", psnr_noisy)
```

```dataframe
The peak signal-to-noise ratio of the noisy image is 30.0050
```

设置要平滑的细节振幅，然后设置要应用的平滑量。

```julia
sigma = 0.1;
alpha = 4.0;
```

应用边缘感知滤波器，并计算降噪后图像的峰值信噪比。

```julia
B = locallapfilt(A_noisy, sigma, alpha);
psnr_denoised = psnr(B, A);
@printf("The peak signal-to-noise ratio of the denoised image is %0.4f\n", psnr_denoised)
```

```dataframe
The peak signal-to-noise ratio of the denoised image is 32.4828
```

注意图像 PSNR 的改善。并排显示原图像、含噪图像与降噪后的图像，观察细节被平滑，而边缘处的剧烈强度变化保持不变。

```julia
figure()
subplot(1, 3, 1)
imshow(A)
title("Original")
subplot(1, 3, 2)
imshow(A_noisy)
title("Noisy")
subplot(1, 3, 3)
imshow(B)
title("Denoised")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example4/subplot.png')">

  </div>
</div>

<div id="xbbc4d5e6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>平滑图像细节并保持边缘锐度</summary>
</details>
<div class="details-content">

读入图像，缩小其尺寸并显示。

```julia
using TyImageProcessing
using TyPlot

A = imread("car1.jpg");
A = imresize(A, 0.25);
figure()
imshow(A)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example5/OriginalImage.png')">

汽车很脏且布满污渍。尝试擦除车身上的灰尘和污渍。设置要平滑的细节振幅，并设置较大的平滑量。

```julia
sigma = 0.2;
alpha = 5.0;
```

当进行平滑（alpha > 1）时，滤波器使用少量强度级别即可产生高质量的结果。设置较少的强度级别数以更快地处理图像。

```julia
numLevels = 16;
```

应用滤波器。

```julia
B = locallapfilt(A, sigma, alpha; NumIntensityLevels=numLevels);
```

显示"干净"的汽车。

```julia
figure()
imshow(B)
title("After smoothing details")
```

<img :src="$withBase('/TyImageProcessing/Images/locallapfilt/example5/SmoothingDetails.png')">

  </div>
</div>

## 输入参数

<div id="x1f2e3d4c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 要滤波的图像<div>二维灰度图像 | 二维 RGB 图像</div></summary>
</details>
<div class="details-content">

要滤波的图像，指定为大小为 m×n 的二维灰度图像或大小为 m×n×3 的二维 RGB 图像。

**数据类型：** Float32 | Int8 | Int16 | UInt8 | UInt16

  </div>
</div>

<div id="x0a1b2c3d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sigma — 边缘振幅<div>非负数</div></summary>
</details>
<div class="details-content">

边缘的振幅，指定为非负数。对于整数图像和取值范围为 [0, 1] 的单精度图像，sigma 应在 [0, 1] 范围内。对于取值范围为 [a, b] 的单精度图像，sigma 也应在 [a, b] 范围内。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="x9e8f7a6b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>alpha — 细节平滑<div>正数</div></summary>
</details>
<div class="details-content">

细节的平滑，指定为正数。alpha 的典型值在 [0.01, 10] 范围内。

|值|说明|
|:---|:---|
|alpha 小于 1|增加输入图像的细节，有效地增强图像的局部对比度，而不影响边缘或引入光晕。|
|alpha 大于 1|平滑输入图像中的细节，同时保留清晰的边缘。|
|alpha 等于 1|输入图像的细节保持不变。|

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="x5c4d3e2f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>beta — 动态范围<div>1（默认） | 非负数</div></summary>
</details>
<div class="details-content">

动态范围，指定为非负数。beta 的典型值在 [0, 5] 范围内。beta 影响 I 的动态范围。

|值|说明|
|:---|:---|
|beta 小于 1|减小图像中边缘的振幅，有效地压缩动态范围而不影响细节。|
|beta 大于 1|扩展图像的动态范围。|
|beta 等于 1|图像的动态范围保持不变。这是默认值。|

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="x11aa22bb" class="jump-target"></div>

## 名称-值参数
指定可选的参数对作为 Name1=Value1,...,NameN=ValueN，其中 Name 是参数名称，Value 是相应的值。名称-值参数必须出现在其他参数之后，但是对这些对的顺序不重要。

**示例：** J = locallapfilt(I,sigma,alpha; ColorMode="separate"); 独立地滤波每个颜色通道。

<div id="x33cc44dd" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ColorMode — 用于滤波 RGB 图像的方法<div>"luminance"（默认） | "separate"</div></summary>
</details>
<div class="details-content">

用于滤波 RGB 图像的方法，指定为下列值之一。此参数对灰度图像没有影响。

|值|说明|
|:---|:---|
|"luminance"|locallapfilt 在滤波前将输入 RGB 图像转换为灰度，并在滤波后重新引入颜色，从而在不影响颜色的情况下改变输入图像的对比度。|
|"separate"|locallapfilt 独立地滤波每个颜色通道。|

**数据类型：** AbstractString | Symbol

  </div>
</div>

<div id="x55ee66ff" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>NumIntensityLevels — 强度采样数<div>"auto"（默认） | 正整数</div></summary>
</details>
<div class="details-content">

输入图像动态范围内的强度采样数，指定为 "auto" 或正整数。采样数越多，结果越接近精确的局部拉普拉斯滤波；采样数越少，执行速度越快。典型值在 [10, 100] 范围内。如果设置为 "auto"，locallapfilt 会根据滤波器的其他参数自动选择强度级别数，以平衡质量与速度。

**数据类型：** AbstractString | Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

## 输出参数

<div id="x8a3b5c7d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 滤波后的图像<div>数值数组</div></summary>
</details>
<div class="details-content">

滤波后的图像，以与输入图像 [I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/locallapfilt.html#x1f2e3d4c) 大小和数据类型相同的数值数组形式返回。

**数据类型：** Float32 | Int8 | Int16 | UInt8 | UInt16

  </div>
</div>

## 另请参阅

[imbilatfilt](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/Edge-PreservingFiltering/imbilatfilt.html) | [imsharpen](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/imsharpen.html)
