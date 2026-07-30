# imresize
---
调整图像大小

<h2>函数库: TyImageProcessing</h2>

## 语法

```
B = imresize(A,scale)
B = imresize(A,[numrows, numcols])
___ = imresize(___;method)
___ = imresize(___;Name=Value)
```

## 说明

[B](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x626fc852) = imresize([A](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x5a24ee3f),[scale](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x01d52010))返回图像 B，它是将 A 的长宽大小缩放图像 scale 倍之后的图像。输入图像 A 可以是灰度图像、RGB 图像、二值图像或分类图像。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x5f5599df)

***
[B](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x626fc852) = imresize([A](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x5a24ee3f),[[numrows, numcols](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x9522304f)])返回图像 B，其行数和列数由二元素向量 [numrows, numcols] 指定。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x7b0adb3e)

***
___ = imresize(___;[method](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#a944a023)) 指定使用的插值方法。[示例](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#x7dc33273)

***
___ = imresize(___;[Name=Value](/Doc/TyImageProcessing/GeometricTransformationandImageRegistration/CommonGeometricTransformations1/imresize.html#b124027a)) 返回调整大小后的图像，其中名称-值参数控制大小调整操作的各个方面。在所有其他输入参数之后指定名称-值参数。（暂不支持）


## 示例

<div id="x5f5599df" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用默认插值方法将图像的长宽缩小二分之一</summary>
</details>
<div class="details-content">

将图像加载到工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("ngc6543a.jpg");
```

将图像的长宽缩小二分之一。

```julia
J = imresize(I, 0.5);
```

显示原始图像和调整大小后的图像。

```julia
figure(),image(I),figure(),image(J)
```

<img :src="$withBase('/TyImageProcessing/Images/imresize/example1/example1.webp')">

<img :src="$withBase('/TyImageProcessing/Images/imresize/example1/example2.webp')">

  </div>
</div>

<div id="x7dc33273" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用最近邻点插值缩小图像</summary>
</details>
<div class="details-content">

将图像加载到工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("ngc6543a.jpg");
```

使用最近邻点插值将图像缩小到原始大小的 40%。这是最快的方法，但质量最差。

```julia
J = imresize(I, 0.4; method="nearest");
```

显示原始图像和调整大小后的图像。

```julia
image(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/imresize/example2/example1.webp')">

```julia
image(J)
title("Resized Image Using Nearest Neighbor Interpolation")
```

<img :src="$withBase('/TyImageProcessing/Images/imresize/example2/example2.webp')">

  </div>
</div>

<div id="x7b0adb3e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>通过指定输出图像的大小调整 RGB 图像的大小</summary>
</details>
<div class="details-content">

将 RGB 图像读取到工作区。

```julia
using TyImageProcessing
using TyPlot

RGB = imread("peppers.png");
```

将 RGB 图像的大小调整为 64 行, 64 列。

```julia
RGB2 = imresize(RGB, [64, 64]);
```

获取调整大小后的图像的大小。

```julia
sz = size(RGB2)
```

```dataframe
sz = 
(64, 64, 3)
```

显示原始图像和调整大小后的图像。

```julia
image(RGB);
title("Original Image");
```

<img :src="$withBase('/TyImageProcessing/Images/imresize/example3/example1.webp')">

```julia
image(RGB2)
title("Resized Image with 64 Rows");
```

<img :src="$withBase('/TyImageProcessing/Images/imresize/example3/example2.png')">


  </div>
</div>

## 输入参数
<div id="x5a24ee3f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — 要调整大小的图像<div>实数非稀疏数值数组</div></summary>
</details>
<div class="details-content">

要调整大小的图像，指定为实数非稀疏数值数组。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="x01d52010" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>scale — 大小调整因子<div>正数</div></summary>
</details>
<div class="details-content">

大小调整因子，指定为正数。imresize 对行和列维度应用相同的缩放因子。

**数据类型：** Float64

  </div>
</div>

<div id="x9522304f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>[numrows, numcols] — 输出图像的行和列维度<div>由正值组成的二元素数值向量</div></summary>
</details>
<div class="details-content">

输出图像的行和列维度，指定为由正数组成的二元素向量。

**数据类型：** Int64 | Float64

  </div>
</div>

<div id="a944a023" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>method — 插值方法<div>字符串标量</div></summary>
</details>
<div class="details-content">

插值方法，指定为字符串标量。
| 方法   | 说明   |
| ------ | ----------- |
| "nearest"    | 最近邻插值     |
| "bilinear"    | 双线性插值     |
| "bicubic"    | 双三次插值     |
| "area"    | 区域插值     |
| "lanczos"    | Lanczos 插值     |

**数据类型：** String

  </div>
</div>

<div id="b124027a" class="jump-target"></div>

### 名称-值参数
将可选的参量对组指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参量名称，Value 是对应的值。名称-值参量必须出现在其他参量之后，但参量对组的顺序无关紧要。

**示例：** I2 = imresize(I,0.5,method="bilinear");

## 输出参数

<div id="x626fc852" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>B — 调整大小后的图像<div>实数非稀疏数值数组</div></summary>
</details>
<div class="details-content">

调整大小后的图像，返回为与输入图像 A 的数据类型相同的数值或分类数组。

  </div>
</div>