# graycoprops
---
灰度共生矩阵（GLCM）的特性

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
stats = graycoprops(glcm)
stats = graycoprops(glcm, properties)
```

## 说明

[stats](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#xf7e3a1b2) = graycoprops([glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x4a8b1c2d)) 计算灰度共生矩阵 [glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x4a8b1c2d) 的所有四个统计特性：对比度（Contrast）、相关性（Correlation）、能量（Energy）和同质性（Homogeneity）。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x3e5f6a7b)

[stats](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#xf7e3a1b2) = graycoprops([glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x4a8b1c2d), [properties](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x5c6d7e8f)) 计算 properties 指定的统计特性。properties 可以是以逗号分隔的字符串列表、字符串数组、以空格分隔的字符串，或 "all"（默认）。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x8f9a0b1c)

graycoprops 将灰度共生矩阵（GLCM）归一化，使其元素之和等于 1。归一化后的 GLCM 中每个元素 (*r*, *c*) 是图像中具有特定空间关系的像素对取灰度值 *R* 和 *C* 的联合概率。graycoprops 使用归一化的 GLCM 计算统计特性。

## 示例

<div id="x3e5f6a7b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>从灰度共生矩阵计算统计量</summary>
</details>
<div class="details-content">

创建简单的样本 GLCM。

```julia
glcm = [0 1 2 3; 1 1 2 3; 1 0 2 0; 0 0 0 3]
```

计算 GLCM 的统计特性。

```julia
stats = graycoprops(glcm)
```

```dataframe
包含以下字段的 struct:

        Contrast: %{1}Union{DataType, Real}[2.894736842105263;;]
     Correlation: %{1}Union{DataType, Real}[0.0782698249721149;;]
          Energy: %{1}Union{DataType, Real}[0.1191135734072022;;]
     Homogeneity: %{1}Union{DataType, Real}[0.5657894736842105;;]
```

  </div>
</div>

<div id="x8f9a0b1c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>从多个 GLCM 计算对比度和同质性</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
using TyImageProcessing

I = imread("circuit.tif");
```

从图像创建两个灰度共生矩阵 (GLCM)，指定不同的偏移量。

```julia
glcm, = graycomatrix(I; Offset=[2 0; 0 2]);
```

```dataframe
glcm =
8×8×2 Array{Float64, 3}:
[:, :, 1] =
 14205.0   2107.0   126.0     0.0      0.0     0.0  0.0  0.0
  2242.0  14052.0  3555.0   400.0      0.0     0.0  0.0  0.0
   191.0   3579.0  7341.0  1505.0     37.0     0.0  0.0  0.0
     0.0    683.0  1446.0  7184.0   1368.0     0.0  0.0  0.0
     0.0      7.0   116.0  1502.0  10256.0  1124.0  0.0  0.0
     0.0      0.0     0.0     2.0   1153.0  1435.0  0.0  0.0
     0.0      0.0     0.0     0.0      0.0     0.0  0.0  0.0
     0.0      0.0     0.0     0.0      0.0     0.0  0.0  0.0

[:, :, 2] =
 13938.0   2615.0   204.0     4.0     0.0     0.0  0.0  0.0
  2406.0  14062.0  3311.0   630.0    23.0     0.0  0.0  0.0
   145.0   3184.0  7371.0  1650.0   133.0     0.0  0.0  0.0
     2.0    371.0  1621.0  6905.0  1706.0     0.0  0.0  0.0
     0.0      0.0   116.0  1477.0  9974.0  1173.0  0.0  0.0
     0.0      0.0     0.0     1.0  1161.0  1417.0  0.0  0.0
     0.0      0.0     0.0     0.0     0.0     0.0  0.0  0.0
     0.0      0.0     0.0     0.0     0.0     0.0  0.0  0.0
```

从 GLCM 获取图像的对比度和同质性统计信息。

```julia
stats = graycoprops(Int.(glcm), ["Contrast", "Homogeneity"])
```

```dataframe
包含以下字段的 struct:

        Contrast: %{1}Union{DataType, Real}[0.3420440118493441 0.3566798941798942]
     Correlation: %{1}Union{DataType, Real}[0.9243386294487047 0.9212335891338432]
          Energy: %{1}Union{DataType, Real}[0.11519660544248875 0.1125089915595868]
     Homogeneity: %{1}Union{DataType, Real}[0.8567443839046409 0.8513172398589065]
```

  </div>
</div>

## 输入参数

<div id="x4a8b1c2d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>glcm - 灰度共生矩阵<div>非负整数矩阵 | 非负整数数组</div></summary>
</details>
<div class="details-content">

灰度共生矩阵，指定为以下之一。您可以使用 [graycomatrix](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html) 函数创建 GLCM。

- 单个 GLCM 的 m×n 非负整数矩阵
- *p* 个有效 GLCM 的 m×n×p 非负整数数组

**数据类型：** Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64 | Float32 | Float64

  </div>
</div>

<div id="x5c6d7e8f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>properties - 统计特性<div>"all" (默认) | 字符串标量的逗号分隔列表 | 字符串数组 | 以空格分隔的字符串</div></summary>
</details>
<div class="details-content">

从 GLCM 推导出的图像统计特性，指定为字符串标量的逗号分隔列表、字符串数组、以空格分隔的字符串，或 `"all"`。您可以指定下表中所列的任何特性名称。

| 特性 | 说明 | 公式 |
|:---|:---|:---|
| `"Contrast"` | 衡量整幅图像中像素与其相邻像素之间强度对比度的指标。取值范围：[0, (size(GLCM,1)−1)²]。对于恒定图像，对比度为 0。也称为方差 (variance) 和惯性 (inertia)。 | $\sum_{i,j} \|i-j\|^2 p(i,j)$ |
| `"Correlation"` | 衡量整幅图像中像素与其相邻像素之间相关程度的指标。取值范围：[-1, 1]。对于完全正相关或负相关的图像，相关性为 1 或 -1。对于恒定图像，相关性为 NaN。 | $\frac{\sum_{i,j} (i-\mu_i)(j-\mu_j) p(i,j)}{\sigma_i \sigma_j}$ |
| `"Energy"` | 返回 GLCM 中元素的平方和。取值范围：[0, 1]。对于恒定图像，能量为 1。也称为均匀性 (uniformity)、能量均匀性 (uniformity of energy) 和角二阶矩 (angular second moment)。 | $\sum_{i,j} p(i,j)^2$ |
| `"Homogeneity"` | 衡量 GLCM 中元素分布与 GLCM 对角线接近程度的指标。取值范围：[0, 1]。对于对角 GLCM，同质性为 1。 | $\sum_{i,j} \frac{p(i,j)}{1+\|i-j\|}$ |

**示例：** `"Contrast"`,`"Homogeneity"` 以逗号分隔列表形式指定两个特性

**示例：** `["Contrast","Homogeneity"]` 以字符串数组形式指定两个特性

**示例：** `"Contrast Homogeneity"` 以空格分隔字符串形式指定两个特性

**数据类型：** String

  </div>
</div>

## 输出参数

<div id="xf7e3a1b2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>stats - 从 GLCM 推导出的统计量<div>结构体</div></summary>
</details>
<div class="details-content">

从 GLCM 推导出的统计量，以结构体形式返回，其字段由 [properties](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x5c6d7e8f) 指定。每个字段包含一个 1×*p* 的数组，其中 *p* 是 [glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x4a8b1c2d) 中 GLCM 的数量。例如，如果 [glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycoprops.html#x4a8b1c2d) 是 8×8×3 数组且 properties 为 "Energy"，则 stats 是包含字段 Energy 的结构体，该字段包含一个 1×3 的数组。

  </div>
</div>
