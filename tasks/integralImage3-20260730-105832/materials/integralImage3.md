# integralImage3
---
计算三维积分图像

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = integralImage3(I)
```

## 说明

在积分图像中，每个像素表示对应输入像素及其上方、左方和前方所有像素的累积和。

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/IntegralImageDomainFiltering/integralImage3.html#J) = integralImage3([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/IntegralImageDomainFiltering/integralImage3.html#I)) 从灰度体积图像 I 计算积分图像。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/IntegralImageDomainFiltering/integralImage3.html#eg1)

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算三维输入图像的积分图像</summary>
</details>
<div class="details-content">

创建一个三维输入图像。

```julia
using TyImageProcessing
using TyMath

I = reshape(collect(1:125), 5, 5, 5)
```

```dataframe
I =
5x5x5 Array{Int64, 3}:
[:, :, 1] =
  1   6  11  16  21
  2   7  12  17  22
  3   8  13  18  23
  4   9  14  19  24
  5  10  15  20  25

[:, :, 2] =
  26  31  36  41  46
  27  32  37  42  47
  28  33  38  43  48
  29  34  39  44  49
  30  35  40  45  50

[:, :, 3] =
  51  56  61  66  71
  52  57  62  67  72
  53  58  63  68  73
  54  59  64  69  74
  55  60  65  70  75

[:, :, 4] =
  76  81  86  91  96
  77  82  87  92  97
  78  83  88  93  98
  79  84  89  94  99
  80  85  90  95 100

[:, :, 5] =
  101  106  111  116  121
  102  107  112  117  122
  103  108  113  118  123
  104  109  114  119  124
  105  110  115  120  125
```

定义一个 3×3×3 的子体积，格式为 [startRow, startCol, startPlane, endRow, endCol, endPlane]。

```julia
sR, sC, sP, eR, eC, eP = 2, 2, 2, 4, 4, 4;
```

从输入图像创建积分图像，并计算 I 中 3×3×3 子体积的总和。

```julia
J = integralImage3(I);
regionSum = J[eR+1, eC+1, eP+1] - J[eR+1, eC+1, sP] - J[eR+1, sC, eP+1] - J[sR, eC+1, eP+1] + J[sR, sC, eP+1] + J[sR, eC+1, sP] + J[eR+1, sC, sP] - J[sR, sC, sP]
```

```dataframe
regionSum =
1701.0
```

验证像素总和是否正确。

```julia
directSum = sum(I[sR:eR, sC:eC, sP:eP])
```

```dataframe
directSum =
1701
```

  </div>
</div>

## 输入参数

<div id="I" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 灰度体积<div>三维数值数组</div></summary>
</details>
<div class="details-content">

灰度体积，指定为三维数值数组。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32

  </div>
</div>

## 输出参数

<div id="J" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 积分图像<div>数值数组</div></summary>
</details>
<div class="details-content">

积分图像，以数值数组形式返回。该函数在顶部、左侧和沿第一个平面进行零填充，因此 size(J) = size(I) + 1。输出的数据类型为 Float64。这样的尺寸设置有助于沿所有图像边界计算像素和。积分图像 J 本质上是值 cumsum(cumsum(cumsum(I; dims=1); dims=2); dims=3) 的填充版本。

**数据类型：** Float64

  </div>
</div>

## 更多关于

<div id="integral-image" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>积分图像</summary>
</details>
<div class="details-content">

在积分图像中，每个像素表示其上方、左方和前方所有像素的累积和。使用积分图像，您可以快速计算图像子区域的总和。积分图像的使用由 Viola-Jones 算法推广开来。积分图像有助于像素求和，并且可以在常数时间内完成，无论邻域大小如何。

  </div>
</div>

## 另请参阅
 [integralImage](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/IntegralImageDomainFiltering/integralImage.html)
