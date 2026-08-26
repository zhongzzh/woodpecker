# imregmtb
---
使用中值阈值位图对二维图像进行配准

<h2>函数库: TyImageProcessing</h2>

## 语法

```
R1,R2,...,Rn,shift = imregmtb(M1,M2,...,Mn,F)
```

## 说明

[R1,R2,...,Rn](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#x1234abcd),[shift](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#x5678ef01) = imregmtb([M1,M2,...,Mn](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#xb1a2c3d4),[F](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#xe5f6a7b8)) 使用中值阈值位图技术，对任意数量的移动图像 M1,M2,...,Mn 相对于固定（参考）图像 F 进行配准。配准后的图像返回在 R1,R2,...,Rn 中，配准图像的估计位移返回在 shift 中。

中值阈值位图技术对具有可变曝光的图像配准非常有效。imregmtb 仅考虑平移变换，不考虑旋转或其他类型的几何变换。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#x6cd53c4e)

## 示例

<div id="x6cd53c4e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用中值阈值位图配准存在抖动偏移的图像</summary>
</details>
<div class="details-content">

读取一系列具有不同曝光的图像。

```julia
using TyImageProcessing
using TyPlot
using TyRandom

I1 = imread("office_1.jpg");
I2 = imread("office_2.jpg");
I3 = imread("office_3.jpg");
I4 = imread("office_4.jpg");
I5 = imread("office_5.jpg");
I6 = imread("office_6.jpg");
```

这些图像是从固定相机拍摄的，场景中不存在移动物体。本示例通过将每张图像在水平和垂直方向上平移 [-30, 30] 像素范围内的随机量来模拟相机运动（抖动）。将五张移动图像的所有平移值存储在 5×2 矩阵 t 中。将第六张图像 I6 指定为固定（参考）图像，不对此图像应用抖动。

```julia
r = MT19937ar(5489);
t = Float64.(rand(r, -30:30, 5, 2));
I1 = imtranslate(I1, t[1, :])
I2 = imtranslate(I2, t[2, :])
I3 = imtranslate(I3, t[3, :])
I4 = imtranslate(I4, t[4, :])
I5 = imtranslate(I5, t[5, :])
```

为了比较图像位置，显示每张图像中心的感兴趣区域 (ROI)。向量 roi 指定左上角的 x 和 y 坐标，以及 ROI 的宽度和高度。

```julia
roi = [140 260 200 200]
montage([imcrop(I1, roi), imcrop(I2, roi), imcrop(I3, roi),
    imcrop(I4, roi), imcrop(I5, roi), imcrop(I6, roi)])
title("Misaligned Images")
```
<img :src="$withBase('/TyImageProcessing/Images/imregmtb/example1/Misaligned.png')">
使用中值阈值位图对空间平移后的图像进行配准。显示每张图像中心的 ROI。

```julia
R1, R2, R3, R4, R5, shift = imregmtb(I1, I2, I3, I4, I5, I6)
montage([imcrop(R1, roi), imcrop(R2, roi), imcrop(R3, roi),
    imcrop(R4, roi), imcrop(R5, roi), imcrop(I6, roi)])
title("Registered Images")
```
<img :src="$withBase('/TyImageProcessing/Images/imregmtb/example1/Registered.png')">

图像看起来良好对齐。

检查每张移动图像相对于固定图像的估计位移 shift。shift 表示为了使移动图像与固定图像对齐而需要应用的估计变换。

```julia
shift
```

```dataframe
5×2 Matrix{Float64}:
 -26.0   25.0
 -25.0   14.0
  23.0   -3.0
 -25.0  -28.0
  -8.0  -28.0
```

将估计位移与实际位移进行比较。回想一下，变换 t 应用于固定图像以模拟每张移动图像的抖动。因此，变换 -t 类似于 shift 返回的变换。

```julia
-t
```

```dataframe
5×2 Matrix{Float64}:
5×2 Matrix{Float64}:
 -19.0   25.0
 -25.0   14.0
  23.0   -3.0
 -25.0  -28.0
  -8.0  -28.0
```

imregmtb 函数很好地估计了每帧的位移。

  </div>
</div>

## 输入参数

<div id="xb1a2c3d4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>M1,M2,...,Mn — 移动图像<div>灰度图像 | RGB 图像</div></summary>
</details>
<div class="details-content">

移动图像，指定为一系列具有相同或可变曝光的灰度图像或 RGB 图像。所有图像必须具有相同的尺寸和数据类型。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

<div id="xe5f6a7b8" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>F — 固定图像<div>灰度图像 | RGB 图像</div></summary>
</details>
<div class="details-content">

固定（参考）图像，指定为灰度图像或 RGB 图像。F 必须与移动图像 [M1,M2,...,Mn](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#xb1a2c3d4) 具有相同的尺寸和数据类型。

**数据类型：** Float32 | Float64 | UInt8 | UInt16

  </div>
</div>

## 输出参数

<div id="x1234abcd" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>R1,R2,...,Rn — 配准后的图像<div>灰度图像 | RGB 图像</div></summary>
</details>
<div class="details-content">

配准后的图像，以一系列灰度图像或 RGB 图像的形式返回。配准后的图像与移动图像 [M1,M2,...,Mn](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/ImageRegistration/AutomaticRegistration/imregmtb.html#xb1a2c3d4) 具有相同的尺寸和数据类型。

  </div>
</div>

<div id="x5678ef01" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>shift — 估计位移<div>n×2 数值矩阵</div></summary>
</details>
<div class="details-content">

每个配准图像在水平和垂直方向上的估计位移，以 n×2 数值矩阵的形式返回。

**数据类型：** Float64

  </div>
</div>

## 另请参阅

[imtranslate](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imtranslate.html) 
