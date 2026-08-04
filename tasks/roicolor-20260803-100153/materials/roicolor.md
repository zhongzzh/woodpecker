# roicolor
---
基于颜色选择感兴趣区域（ROI）

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
BW = roicolor(I, low, high)
BW = roicolor(I, v)
```

## 说明

[BW](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#b8a1e3f2) = roicolor([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#d3c7a9b1), [low](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#e5f2c8d4), [high](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#a7d4b6e9)) 返回一个 ROI，选择图像 I 中位于范围 [low, high] 内的像素。返回值 BW 是一个二值图像，ROI 外部为 false，内部为 true。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#f1c4a2e8)

***
[BW](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#b8a1e3f2) = roicolor([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#d3c7a9b1), [v](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/FilterImageUsingROI/roicolor.html#c9e6b5a3)) 返回一个 ROI，选择图像 I 中与向量 v 中的值匹配的像素。

## 示例

<div id="f1c4a2e8" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>基于颜色选择感兴趣区域</summary>
</details>
<div class="details-content">

加载索引图像并显示它。

```julia
using TyImageProcessing
using TyBase

X = load(pkgdir(TyImageProcessing) * "/resources/trees_tif_X.mat")["X"];
map = load(pkgdir(TyImageProcessing) * "/resources/trees_tif_map.mat")["map"];
imshow(X, map)
```

<img :src="$withBase('/TyImageProcessing/Images/roicolor/example1/trees.png')">

基于颜色创建一个二值掩膜图像。该掩膜对于索引在 [10, 20] 范围内的像素为 true，对于该范围外的像素为 false。

```julia
BW = roicolor(X, 10, 20);
```

显示二值掩膜。

```julia
imshow(BW)
```

<img :src="$withBase('/TyImageProcessing/Images/roicolor/example1/roicolor.png')">

  </div>
</div>

## 输入参数

<div id="d3c7a9b1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 索引或灰度图像<div>m×n 数值矩阵</div></summary>
</details>
<div class="details-content">

索引或灰度图像，指定为 m×n 数值矩阵。

  </div>
</div>

<div id="e5f2c8d4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>low — 最小值<div>数值标量</div></summary>
</details>
<div class="details-content">

ROI 中包含的最小值，指定为数值标量。

  </div>
</div>

<div id="a7d4b6e9" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>high — 最大值<div>数值标量</div></summary>
</details>
<div class="details-content">

ROI 中包含的最大值，指定为数值标量。

  </div>
</div>

<div id="c9e6b5a3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>v — 一组值<div>数值向量</div></summary>
</details>
<div class="details-content">

ROI 中包含的一组值，指定为数值向量。

  </div>
</div>

## 输出参数

<div id="b8a1e3f2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW — 二值图像<div>m×n 逻辑矩阵</div></summary>
</details>
<div class="details-content">

二值图像，以 m×n 逻辑矩阵形式返回。

**数据类型：** Bool

  </div>
</div>

## 提示

- 您可以将返回的图像用作掩膜，通过 [roifilt2](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/roifilt2.html) 进行掩膜滤波。

- 如果您指定颜色图范围 [low, high]，则 BW = (I .>= low) .& (I .<= high)。

- 如果您指定一组颜色图值 v，则 roicolor 生成的掩膜等效于对 v 中的每个值检查 I 中是否匹配。

## 另请参阅

[roifilt2](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/roifilt2.html) | [roipoly](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ROI-BasedProcessing/CreateMaskfromROI/roipoly.html)