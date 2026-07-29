# graydiffweight
---
基于灰度强度差异为图像像素计算权重

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
W = graydiffweight(I,refGrayVal)
W = graydiffweight(I,mask)
W = graydiffweight(I,C,R)
W = graydiffweight(V,C,R,P)
W = graydiffweight(___,Name=Value)
```

## 说明

[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#W) = graydiffweight([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#I),[refGrayVal](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#refGrayVal)) 使用单个参考灰度强度值 refGrayVal 为二维或三维灰度图像 I 中的所有像素计算像素权重 W。选择一个能代表您要分割的对象的参考灰度强度值。

像素的权重与像素强度值和参考灰度强度值之间的绝对差值成反比。如果差值较小（强度值接近 refGrayVal），则权重值较大。如果差值较大（强度值远离 refGrayVal），则权重值较小。

您可以将 graydiffweight 函数返回的权重用于基于快速行进法（Fast Marching Method）的图像或体积分割，通过 imsegfmm 函数实现。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#eg1)

***

[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#W) = graydiffweight([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#I),[mask](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#mask)) 计算像素权重，其中参考灰度强度值为 I 中标记为逻辑值 true 的所有像素的强度值的平均值。使用多个像素的平均值来计算参考灰度强度值，可能比使用单个参考强度值（如前一语法）更有效。

***

[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#W) = graydiffweight([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#I),[C](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#C,R),[R](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#C,R)) 使用从二维灰度图像 I 中选定的像素取平均得到的参考值来计算像素权重。选定的像素具有列索引 C 和行索引 R。

***

[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#W) = graydiffweight([V](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#V),[C](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#C,R,P),[R](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#C,R,P),[P](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#C,R,P)) 使用从三维灰度体积图像 V 中选定的体素取平均得到的参考值来计算体素权重。选定的体素具有列索引 C、行索引 R 和平面索引 P。

***

[W](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#W) = graydiffweight(___,[Name=Value](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/SegmentationTechniques/graydiffweight.html#namevalue)) 使用额外的名值参数来控制权重计算的各个方面。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算灰度强度差异权重</summary>
</details>
<div class="details-content">

此示例使用灰度强度差异权重（从种子位置的强度值计算得出）通过快速行进法分割图像中的对象。

读取图像并显示。

```julia
using TyImageProcessing
using TyPlot

I = imread("cameraman.tif");
imshow(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/graydiffweight/example1/Original_Image.webp')">

指定用作参考灰度强度值的像素的行和列索引。

```julia
seedpointR = 159;
seedpointC = 67;
```

计算图像的灰度强度差异权重数组并显示。该示例对 W 进行对数缩放以便更好地可视化。

```julia
W = graydiffweight(I, seedpointC, seedpointR; GrayDifferenceCutoff=25);
figure(), imshow(log.(W), [])
```

<img :src="$withBase('/TyImageProcessing/Images/graydiffweight/example1/example2.webp')">

  </div>
</div>

## 输入参数

<div id="I" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 灰度图像或体积<div>二维数值矩阵 | 三维数值数组</div></summary>
</details>
<div class="details-content">

灰度图像或体积，分别指定为二维数值矩阵或三维数值数组。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

<div id="V" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>V — 灰度体积图像<div>三维数值数组</div></summary>
</details>
<div class="details-content">

灰度体积图像，指定为三维数值数组。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

<div id="refGrayVal" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>refGrayVal — 参考灰度强度值<div>数值标量</div></summary>
</details>
<div class="details-content">

参考灰度强度值，指定为数值标量。该值应为实数且非 NaN。

**数据类型：** Float64 | Float32 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

<div id="mask" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>mask — 参考灰度强度掩码<div>逻辑数组</div></summary>
</details>
<div class="details-content">

参考灰度强度掩码，指定为与 I 大小相同的逻辑数组。至少需要一个元素为 true。参考灰度强度值计算为 I 中 mask 为 true 的所有像素的强度值的平均值。

**数据类型：** Bool

  </div>
</div>

<div id="C,R" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>C — 参考像素（或体素）的列索引<div>正整数向量</div></summary>
</details>
<div class="details-content">

二维图像中参考像素的列索引，或三维体积中参考体素的列索引，指定为正整数向量。C 和 R 必须具有相同数量的元素。

**数据类型：** Float64 | Float32 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

<div id="C,R_arg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>R — 参考像素（或体素）的行索引<div>正整数向量</div></summary>
</details>
<div class="details-content">

二维图像中参考像素的行索引，或三维体积中参考体素的行索引，指定为正整数向量。C 和 R 必须具有相同数量的元素。

**数据类型：** Float64 | Float32 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

<div id="C,R,P" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>P — 参考体素的平面索引<div>正整数向量</div></summary>
</details>
<div class="details-content">

三维体积中参考体素的平面索引，指定为正整数向量。C、R 和 P 必须具有相同数量的元素。

**数据类型：** Float64 | Float32 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

## 名值参数

指定可选的参数对组，格式为 Name1=Value1,...,NameN=ValueN，其中 Name 是参数名称，Value 是对应的值。名值参数必须出现在其他参数之后，并以分号（;）分隔，但参数对组的顺序无关紧要。

示例：W = graydiffweight(I,seedC,seedR; GrayDifferenceCutoff=25) 将绝对灰度强度差值的阈值指定为 25。

<div id="namevalue" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RolloffFactor — 输出权重衰减因子<div>0.5 (默认) | 正数</div></summary>
</details>
<div class="details-content">

输出权重衰减因子，指定为正数。权重衰减因子控制输出权重作为强度值与参考灰度强度值之间绝对差值的函数时，衰减速度的快慢。该参数的推荐范围为 [0.5, 4]。

当以二维图形观察时，像素强度值在区域边缘处可能逐渐变化，形成平缓的斜坡。在分割图像中，您可能希望边缘更加清晰。使用衰减因子，您可以控制强度值开始变化时权重值曲线的斜率。如果指定较大的值，输出权重值在强度变化区域周围会急剧下降。如果指定较小的值，输出权重在强度变化区域周围的下降会更平缓。

**数据类型：** Float64

  </div>
</div>

<div id="namevalue2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>GrayDifferenceCutoff — 绝对灰度强度差值的阈值<div>Inf (默认) | 非负数</div></summary>
</details>
<div class="details-content">

绝对灰度强度差值的阈值，指定为非负数。此参数的默认值是 Inf，这意味着没有硬性截止。

当应用此阈值时，将强烈抑制强度值远大于或远小于参考值的像素的权重。graydiffweight 会将这些像素的权重值赋为最小值 1。当输出权重数组 W 用于基于快速行进法的分割（作为 imsegfmm 的输入）时，此参数可有助于提高分割输出的精度。

此示例将权重最小值分配给所有与参考强度值之间的绝对差值大于 25 的像素。

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

权重数组，以与输入图像 I 或体积 V 大小相同的数值数组形式返回。如果输入图像或体积的数据类型为 Float32，则 W 的数据类型为 Float32；否则 W 的数据类型为 Float64。

**数据类型：** Float32 | Float64

  </div>
</div>

## 更多关于

<div id="image-segmentation" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>图像分割</summary>
</details>
<div class="details-content">

您可以将 graydiffweight 函数返回的权重用于通过 imsegfmm 函数进行图像分割。使用 imsegfmm 进行分割需要种子位置，这些位置由参考灰度强度掩码或参考像素的列索引和行索引提供。

- 如果使用标量参考灰度强度值 refGrayVal 通过 graydiffweight 计算权重，请确定平均强度值等于 refGrayVal 的种子位置。指定种子位置的列索引和行索引（分别为 C 和 R）以及阈值级别 thresh，以便使用 imsegfmm 进行分割。

```julia
W = graydiffweight(I, refGrayVal)
BW = imsegfmm(W, C, R, thresh)
```

- 如果使用参考灰度强度掩码 mask 通过 graydiffweight 计算权重，请指定相同的掩码以及阈值级别 thresh，以便使用 imsegfmm 进行分割。

```julia
W = graydiffweight(I, mask)
BW = imsegfmm(W, mask, thresh)
```

- 如果使用参考像素的列索引和行索引（分别为 C 和 R）通过 graydiffweight 计算权重，请指定相同的列索引和行索引以及阈值级别 thresh，以便使用 imsegfmm 进行分割。

```julia
W = graydiffweight(I, C, R)
BW = imsegfmm(W, C, R, thresh)
```

  </div>
</div>

<div id="volume-segmentation" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>体积分割</summary>
</details>
<div class="details-content">

您可以将 graydiffweight 函数返回的权重用于通过 imsegfmm 函数进行体积分割。使用 imsegfmm 进行分割需要种子位置，这些位置由参考体素的列索引、行索引和平面索引提供。

- 如果使用参考体素的列索引、行索引和平面索引（分别为 C、R 和 P）通过 graydiffweight 计算权重，请指定相同的列索引、行索引和平面索引以及阈值级别 thresh，以便使用 imsegfmm 进行分割。

```julia
W = graydiffweight(V, C, R, P)
BW = imsegfmm(W, C, R, P, thresh)
```

  </div>
</div>

## 另请参阅
 [graydist](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/MeasurePropertiesofImages/graydist.html)
