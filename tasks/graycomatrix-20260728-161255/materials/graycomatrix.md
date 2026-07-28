# graycomatrix
---
从图像创建灰度共生矩阵

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
glcm = graycomatrix(I)
glcm = graycomatrix(I; Name=Value)
glcm, SI = graycomatrix(___)
```

## 说明

[glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#xfe61206b) = graycomatrix([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#xcd09d6c3)) 从图像 [I](#xcd09d6c3) 创建灰度共生矩阵 (GLCM)。graycomatrix 通过计算灰度级值为 i 的像素与灰度级值为 j 的像素水平相邻的频率来创建 GLCM。[glcm](#xfe61206b) 中的每个元素 (i,j) 指定值为 i 的像素与值为 j 的像素水平相邻的次数。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#x3dc4ef8e)

[glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#xfe61206b) = graycomatrix([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#xcd09d6c3); [Name=Value](#名称-值参数)) 根据名称-值参数的值调整 GLCM 计算的各个方面。例如，您可以通过使用 [Offset](#xef8a2b3c) 参数为一个图像创建多个 GLCM。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#xc1e87e60)

[[glcm](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#xfe61206b), [SI](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#x1d6e31d9)] = graycomatrix(___) 还返回缩放图像 [SI](#x1d6e31d9)，用于计算 GLCM。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/TextureAnalysis/graycomatrix.html#x5f561ead)

## 示例

<div id="x3dc4ef8e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>为灰度图像创建灰度共生矩阵</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
using TyImageProcessing

I = imread("circuit.tif");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Images/graycomatrix/example1/graycomatrixExample1.png')">

计算灰度图像的灰度共生矩阵 (GLCM)。默认情况下，graycomatrix 基于像素的水平接近度 [0 1] 计算 GLCM。这是与感兴趣的像素位于同一行的下一个像素。此示例指定不同的偏移量：同一列上相隔两行。

```julia
glcm = graycomatrix(I; Offset=[2 0])
```

```dataframe
glcm = 
8×8 Matrix{Float64}:
 14205.0   2107.0    126.0      0.0      0.0      0.0      0.0      0.0
  2242.0  14052.0   3555.0    400.0      0.0      0.0      0.0      0.0
   191.0   3579.0   7341.0   1505.0     37.0      0.0      0.0      0.0
     0.0    683.0   1446.0   7184.0   1368.0      0.0      0.0      0.0
     0.0      7.0    116.0   1502.0  10256.0   1124.0      0.0      0.0
     0.0      0.0      0.0      2.0   1153.0   1435.0      0.0      0.0
     0.0      0.0      0.0      0.0      0.0      0.0      0.0      0.0
     0.0      0.0      0.0      0.0      0.0      0.0      0.0      0.0
```

  </div>
</div>

<div id="x5f561ead" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>创建返回缩放图像的灰度共生矩阵</summary>
</details>
<div class="details-content">

创建简单的 3×6 示例数组。

```julia
I = [1 1 5 6 8 8; 2 3 5 7 0 2; 0 2 3 5 6 7]
```

计算灰度共生矩阵 (GLCM)，并返回计算中使用的缩放图像。此示例使用输入图像中的最小和最大灰度值作为 GrayLimits。

```julia
glcm, SI = graycomatrix(I; NumLevels=9, GrayLimits=[])
```

```dataframe
glcm = 
9×9 Matrix{Float64}:
 0.0  0.0  2.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  2.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  2.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  2.0  1.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  1.0
 1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0

SI = 
3×6 Matrix{Float64}:
 2.0  2.0  6.0  7.0  9.0  9.0
 3.0  4.0  6.0  8.0  1.0  3.0
 1.0  3.0  4.0  6.0  7.0  8.0
```

  </div>
</div>

<div id="xc1e87e60" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用四个不同偏移量计算 GLCM</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
I = imread("cell.tif");
imshow（I）
```

<img :src="$withBase('/TyImageProcessing/Images/graycomatrix/example3/graycomatrixExample3.png')">

定义四个偏移量。

```julia
offsets = [0 1; -1 1; -1 0; -1 -1];
```

计算 GLCM，同时返回缩放后的图像。

```julia
glcms, SI = graycomatrix(I; Offset=offsets, NumLevels=8);
```

注意该函数如何返回三维数组 glcms，其中每一页对应一个偏移量的 GLCM。第三维的大小等于偏移量的数量。

```dataframe
glcms =
8×8×4 Array{Float64, 3}:
[:, :, 1] =
 0.0    4.0    0.0      0.0     0.0    0.0   0.0  0.0
 4.0  221.0   83.0      0.0     0.0    0.0   0.0  0.0
 0.0   80.0  714.0    262.0     1.0    0.0   0.0  0.0
 0.0    3.0  257.0  26287.0   303.0    6.0   0.0  0.0
 0.0    0.0    3.0    306.0  1058.0  127.0   1.0  0.0
 0.0    0.0    0.0      1.0   133.0  266.0  30.0  0.0
 0.0    0.0    0.0      0.0     0.0   31.0  29.0  0.0
 0.0    0.0    0.0      0.0     0.0    0.0   0.0  0.0

[:, :, 2] =
 1.0    3.0    0.0      0.0    0.0    0.0   0.0  0.0
 3.0  193.0  101.0     11.0    0.0    0.0   0.0  0.0
 0.0  105.0  582.0    314.0   46.0    2.0   0.0  0.0
 0.0    7.0  360.0  25930.0  390.0   21.0   0.0  0.0
 0.0    0.0   14.0    404.0  914.0  141.0   2.0  0.0
 0.0    0.0    0.0      7.0  144.0  242.0  25.0  0.0
 0.0    0.0    0.0      0.0    1.0   24.0  33.0  0.0
 0.0    0.0    0.0      0.0    0.0    0.0   0.0  0.0

[:, :, 3] =
 0.0    4.0    0.0      0.0    0.0    0.0   0.0  0.0
 4.0  194.0  105.0      5.0    0.0    0.0   0.0  0.0
 0.0  105.0  615.0    305.0   24.0    0.0   0.0  0.0
 0.0    5.0  330.0  26173.0  348.0   10.0   0.0  0.0
 0.0    0.0    7.0    331.0  994.0  143.0   0.0  0.0
 0.0    0.0    0.0     10.0  123.0  257.0  28.0  0.0
 0.0    0.0    0.0      0.0    6.0   20.0  32.0  0.0
 0.0    0.0    0.0      0.0    0.0    0.0   0.0  0.0

[:, :, 4] =
 0.0    4.0    0.0      0.0    0.0    0.0   0.0  0.0
 3.0  146.0  140.0     19.0    0.0    0.0   0.0  0.0
 1.0  138.0  484.0    381.0   44.0    1.0   0.0  0.0
 0.0   20.0  418.0  25823.0  429.0   18.0   0.0  0.0
 0.0    0.0   14.0    409.0  856.0  192.0   4.0  0.0
 0.0    0.0    1.0     29.0  149.0  196.0  43.0  0.0
 0.0    0.0    0.0      5.0   17.0   23.0  13.0  0.0
 0.0    0.0    0.0      0.0    0.0    0.0   0.0  0.0
```

  </div>
</div>

<div id="x6a8c2b1f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算灰度图像的对称 GLCM</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
I = imread("circuit.tif");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Images/graycomatrix/example4/graycomatrixExample4.png')">

使用 Symmetric 选项计算 GLCM，同时返回缩放图像。当您将 Symmetric 设置为 true 时创建的 GLCM 是关于其对角线对称的，等效于 Haralick (1973) 描述的 GLCM。

```julia
glcm, SI = graycomatrix(I; Offset=[2 0], Symmetric=true)
```

```dataframe
glcm = 
8×8 Matrix{Float64}:
 28410.0   4349.0    317.0      0.0      0.0      0.0      0.0      0.0
  4349.0  28104.0   7134.0   1083.0      7.0      0.0      0.0      0.0
   317.0   7134.0  14682.0   2951.0    153.0      0.0      0.0      0.0
     0.0   1083.0   2951.0  14368.0   2870.0      2.0      0.0      0.0
     0.0      7.0    153.0   2870.0  20512.0   2277.0      0.0      0.0
     0.0      0.0      0.0      2.0   2277.0   2870.0      0.0      0.0
     0.0      0.0      0.0      0.0      0.0      0.0      0.0      0.0
     0.0      0.0      0.0      0.0      0.0      0.0      0.0      0.0
```

  </div>
</div>

## 输入参数

<div id="xcd09d6c3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I - 灰度图像<div>二维数值矩阵 | 二维逻辑矩阵</div></summary>
</details>
<div class="details-content">

输入图像，指定为二维数值矩阵或二维逻辑矩阵。

**数据类型：** Float64 | UInt8 | UInt16 | Int16 | Bool

  </div>
</div>

## 名称-值参数

使用 Name=Value 语法指定可选参数对组。名称-值参数必须出现在其他参数之后，但对各个参数对组的顺序没有要求。

示例: glcm = graycomatrix(I,Offset=[2 0]) 指定行偏移量为 2，列偏移量为 0。

<div id="xab7f3d2e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>GrayLimits - 用于将输入图像缩放为灰度级的范围<div>二元向量 | []</div></summary>
</details>
<div class="details-content">

将输入图像缩放到灰度级所使用的范围，指定为 [low high] 形式的二元向量。范围 [low high] 划分为 [NumLevels](#xcd7e4f1a) 个等宽的 bin，并且一个 bin 中的灰度值映射到单个灰度级。小于或等于 low 的灰度值将映射到 1。大于或等于 high 的灰度值将映射到 [NumLevels](#xcd7e4f1a)。

如果 [GrayLimits](#xab7f3d2e) 设置为 []，则 graycomatrix 使用 [I](#xcd09d6c3) 中的最小和最大灰度值作为限值 [min(I(:)) max(I(:))]。例如，对于数据类型为 double 的范围为 [0, 1]，而数据类型为 int16 的范围为 [-32768, 32767]。

  </div>
</div>

<div id="xcd7e4f1a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>NumLevels - 灰度级的数量<div>正整数</div></summary>
</details>
<div class="details-content">

灰度级的数量，指定为正整数。例如，如果 NumLevels 为 8，则 graycomatrix 将 I 中的值缩放为 1 到 8 之间的整数。灰度级的数量确定 GLCM 的大小。

  </div>
</div>

<div id="xef8a2b3c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Offset - 感兴趣的像素与其邻点之间的偏移量<div>[0 1] (默认) | 由整数组成的 p×2 矩阵</div></summary>
</details>
<div class="details-content">

感兴趣的像素与其邻点之间的偏移量，指定为由整数组成的 p×2 矩阵。矩阵中的每行均为一个二元向量，即 [row_offset col_offset]，它指定一对像素的空间关系。row_offset 是关注的像素与其邻点之间的行数。col_offset 是感兴趣的像素与其邻点之间的列数。

由于偏移量通常以角度表示，下表列出了在给定像素距离 D 时与常见角度对应的偏移值。

|角度|偏移量|
|:---|:---|
|0|[0 D]|
|45|[-D D]|
|90|[-D 0]|
|135|[-D -D]|

下图显示距离感兴趣像素 1 的四个偏移量。您将使用矩阵 [0 1; -1 1; -1 0; -1 -1] 来指定这些偏移量。

<img :src="$withBase('/TyImageProcessing/Images/graycomatrix/offset/PIxelofInterest.png')">

  </div>
</div>

<div id="xf0a1b5c6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Symmetric - 考虑值的顺序<div>false (默认) | true</div></summary>
</details>
<div class="details-content">

考虑值的顺序，指定为 true 或 false。当 [Symmetric](#xf0a1b5c6) 设置为 true 时，graycomatrix 在计算值 1 与值 2 相邻的次数时，会将 1,2 和 2,1 对组都进行计数。当 [Symmetric](#xf0a1b5c6) 设置为 false 时，graycomatrix 根据 [Offset](#xef8a2b3c) 的值仅对 1,2 或 2,1 对组进行计数。

**数据类型：** Bool

  </div>
</div>

## 输出参数

<div id="xfe61206b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>glcm - 灰度共生矩阵<div>数值数组</div></summary>
</details>
<div class="details-content">

灰度共生矩阵，以 [NumLevels](#xcd7e4f1a)×[NumLevels](#xcd7e4f1a) 数组形式返回（单个偏移量时），或以 [NumLevels](#xcd7e4f1a)×[NumLevels](#xcd7e4f1a)×p 数组形式返回，其中 p 是 [Offset](#xef8a2b3c) 中偏移量的数目。

**数据类型：** Float64

  </div>
</div>

<div id="x1d6e31d9" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>SI - 用于 GLCM 计算的缩放图像<div>数值矩阵</div></summary>
</details>
<div class="details-content">

用于 GLCM 计算的缩放图像，以与输入图像大小相同的数值矩阵形式返回。[SI](#x1d6e31d9) 中的值介于 1 和 [NumLevels](#xcd7e4f1a) 之间。

**数据类型：** Float64

  </div>
</div>

## 算法

graycomatrix 根据缩放后的图像计算 GLCM。默认情况下，如果 [I](#xcd09d6c3) 是二值图像，则 graycomatrix 将图像缩放到两个灰度级。如果 [I](#xcd09d6c3) 是灰度图像，则 graycomatrix 将图像缩放到八个灰度级。您可以通过使用 [NumLevels](#xcd7e4f1a) 名称-值参数来指定 graycomatrix 用于缩放图像的灰度级的数量。您可以使用 [GrayLimits](#xab7f3d2e) 名称-值参数来调整 graycomatrix 缩放值的方式。

如果像素对组中有任一像素包含 NaN，则 graycomatrix 忽略该像素对组，并用值 [NumLevels](#xcd7e4f1a) 替换正的 Inf，用值 1 替换负的 Inf。如果对应的相邻像素位于图像边界之外，则 graycomatrix 忽略边界像素。

当 [Symmetric](#xf0a1b5c6) 设置为 true 时创建的 GLCM 是关于其对角线对称的，等效于 Haralick (1973) 描述的 GLCM。在 [Symmetric](#xf0a1b5c6) 设置为 true 时由以下语法生成的 GLCM

```julia
graycomatrix(I; Offset=[0 1], Symmetric=true)
```

等效于在 Symmetric 设置为 false 时由以下语句生成的两个 GLCM 的总和。

```julia
graycomatrix(I; Offset=[0 1], Symmetric=false) + graycomatrix(I; Offset=[0 -1], Symmetric=false)
```

## 参考

[1] Haralick, R. M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.

[2] Haralick, R. M., and L. G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.


