# imrotate
---
旋转图像

<h2>函数库: TyImageProcessing</h2>

## 语法

```
J = imrotate(I,angle)
J = imrotate(I,angle,method)
J = imrotate(I,angle,method,bbox)
```

## 说明

[J](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x986aa91f) = imrotate([I](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x3f21b3a4),[angle](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x8948d4f2)) 将图像 I 围绕其中心点逆时针方向旋转 angle 度。要顺时针旋转图像，请为 angle 指定负值。imrotate 使输出图像 J 足够大，可以包含整个旋转图像。默认情况下，imrotate 使用最近邻点插值，对于数值图像，将 J 中位于旋转后的图像外的像素的值设置为 0；对于分类图像，设置为 missing。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#c6135530)

***
[J](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x986aa91f) = imrotate([I](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x3f21b3a4),[angle](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x8948d4f2),[method](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#bb1be29d)) 使用 method 指定的插值方法旋转图像 I。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#c6135530)

***
[J](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x986aa91f) = imrotate([I](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x3f21b3a4),[angle](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x8948d4f2),[method](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#bb1be29d),[bbox](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x0ce6a80b)) 还使用 bbox 参量来定义输出图像的大小。您可以将输出裁剪到与输入图像相同的大小，或返回整个旋转后的图像。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#c6135530)

## 示例

<div id="c6135530" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>顺时针旋转图像以实现更好的水平对齐</summary>
</details>
<div class="details-content">

将一个图像读入工作区，并将其转换为灰度图像。

```julia
using TyImageProcessing
using TyPlot
using TyBase

pkg_dir = pkgdir(TyImageProcessing)
source_path = pkg_dir * "/resources/solarspectra_fts_rescale.mat"
load(source_path)
```

显示原始图像。

```julia
figure()
imshow(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imrotate/example1/example1.webp')">

将图像顺时针旋转 1 度，以实现更好的水平对齐。该示例指定双线性插值，并要求将结果裁剪到与原始图像相同的大小。

```julia
J = imrotate(I, -1, "bilinear", "crop");
```

显示旋转后的图像。

```julia
figure()
imshow(J)
title("Rotated Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imrotate/example1/example2.webp')">

  </div>
</div>

## 输入参数
<div id="x3f21b3a4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 要旋转的图像<div>数值数组</div></summary>
</details>
<div class="details-content">

要旋转的图像，指定为数值数组。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="x8948d4f2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>angle — 旋转量（以度为单位）<div>数值标量</div></summary>
</details>
<div class="details-content">

旋转量（以度为单位），指定为数值标量。

**数据类型：** Real

  </div>
</div>

<div id="bb1be29d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>method — 插值方法<div>"nearest"(默认) | "bilinear" | "lanczos" | "bicubic"</div></summary>
</details>
<div class="details-content">

插值方法，指定为下列值之一：

| 值   | 说明   |
| ------ | ----------- |
| "nearest"    | 最近邻插值(默认)       |
| "bilinear"    | 双线性插值       |
| "lanczos"    | Lanczos插值    |
| "bicubic"    | 双三次插值    |

**数据类型：** String

  </div>
</div>

<div id="x0ce6a80b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>bbox — 定义输出图像大小的边界框<div>"loose" (默认) | "crop"</div></summary>
</details>
<div class="details-content">

定义输出图像大小的边界框，指定为下列值之一：

| 值   | 说明   |
| ------ | ----------- |
| "loose"    | 不裁剪(默认)       |
| "crop"    | 裁剪       |

**数据类型：** String

  </div>
</div>

## 输出参数

<div id="x986aa91f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 旋转后的图像<div>数值数组 | 分类数组</div></summary>
</details>
<div class="details-content">

旋转后的图像，以与输入图像 [I](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imrotate.html#x3f21b3a4) 具有相同数据类型的数值或分类数组形式返回。

  </div>
</div>