# jaccard
---
用于图像分割的杰卡德相似系数

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
similarity = jaccard(BW1,BW2)
similarity = jaccard(L1,L2)
```

## 说明

[similarity](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#similarity—Jaccard) = jaccard([BW1](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x5cd22beb),[BW2](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x49c57558)) 计算二值图像 BW1 和 BW2 的交集除以并集，也称为杰卡德指数。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#bd3c3914)

***
[similarity](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#similarity—Jaccard) = jaccard([L1](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x2491228e),[L2](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x2146855)) 计算标签图像 L1 和 L2 中每个标签的杰卡德指数。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x44798b79)

## 示例

<div id="bd3c3914" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算二值分割的杰卡德相似系数</summary>
</details>
<div class="details-content">

读取包含待分割对象的图像。将图像转换为灰度图，并显示结果。

```julia
using TyImageProcessing
using TyPlot

A = imread("hands1.jpg");
I = im2gray(A);
figure()
imshow(I)
title("Original Image")
```

<img :src="$withBase('/TyImageProcessing/Images/jaccard/example1/originalImage.png')">

使用主动轮廓 (snakes) 方法分割手部。

```julia
mask = falses(size(I));
mask[25:(end - 25), 25:(end - 25)] .= true;
BW = activecontour(I, mask, 300);
```

读入用于比较分割结果的地面真实掩膜。计算此分割的杰卡德指数。

```julia
BW_groundTruth = imread("hands1-mask.png");
BW_groundTruth = BW_groundTruth .!= 0;

similarity = jaccard(BW, BW_groundTruth);
```

将掩膜叠加显示。颜色表示掩膜中的差异。

```julia
figure()
imshowpair(BW, BW_groundTruth)
title("Jaccard Index = $(similarity)")
```

<img :src="$withBase('/TyImageProcessing/Images/jaccard/example1/JaccardIndex.png')">

  </div>
</div>

<div id="x44798b79" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算多区域分割的杰卡德相似系数</summary>
</details>
<div class="details-content">

此示例说明如何将图像分割成多个区域，然后计算每个区域的杰卡德相似系数。

读入具有多个待分割区域的图像。

```julia
using TyImageProcessing
using TyPlot
using TyBase

RGB = imread("yellowlily.jpg");
```

为三个区域创建涂鸦，区分其典型颜色特征。第一个区域分类黄色花朵。第二个区域分类绿色茎叶。最后一个区域分类图像中两个独立斑块中的棕色泥土。区域由 4 元素向量指定，其元素指示 ROI 左上角的 x 坐标和 y 坐标、ROI 的宽度以及 ROI 的高度。

```julia
region1 = [350 700 425 120]; # [x y w h] format
BW1 = falses(size(RGB, 1), size(RGB, 2));
BW1[region1[2]:(region1[2] + region1[4]), region1[1]:(region1[1] + region1[3])] .= true;

region2 = [800 1124 120 230];
BW2 = falses(size(RGB, 1), size(RGB, 2));
BW2[region2[2]:(region2[2] + region2[4]), region2[1]:(region2[1] + region2[3])] .= true;

region3 = [20 1320 480 200; 1010 290 180 240];
BW3 = falses(size(RGB, 1), size(RGB, 2));
BW3[
    region3[1, 2]:(region3[1, 2] + region3[1, 4]),
    region3[1, 1]:(region3[1, 1] + region3[1, 3]),
] .= true;
BW3[
    region3[2, 2]:(region3[2, 2] + region3[2, 4]),
    region3[2, 1]:(region3[2, 1] + region3[2, 3]),
] .= true;
```

在图像上叠加显示种子区域。

```julia
figure()
imshow(RGB)
title("Seed Regions")
```

<img :src="$withBase('/TyImageProcessing/Images/jaccard/example2/SeedRegions.png')">

加载预计算的分割标签图像和地面真实分割图像。

```julia
L = load(pkgdir(TyImageProcessing) * "/resources/jaccard_exp2_L.mat")["L"]

L_groundTruth = Float64.(imread("yellowlily-segmented.png")[1]);
```

将分割结果与地面真实结果进行视觉比较。

```julia
figure()
imshowpair(label2rgb(Int.(L)), label2rgb(Int.(L_groundTruth)), "montage")
title("Comparison of Segmentation Results (Left) and Ground Truth (Right)")
```

<img :src="$withBase('/TyImageProcessing/Images/jaccard/example2/ComparisonofSegmentation.png')">

计算每个分割区域的杰卡德相似指数。

```julia
similarity = jaccard(L, L_groundTruth)
```

```dataframe
3×1 Matrix{Float64}:
 0.8860582755901776
 0.5682683096342769
 0.8413679276319701
```

Jaccard 相似指数在第二区域明显较小。这一结果与分割结果的视觉比较一致，后者错误地将图像右下角的污垢归类为叶子。

  </div>
</div>

## 输入参数

<div id="x5cd22beb" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW1 — 第一个二值图像<div>逻辑数组</div></summary>
</details>
<div class="details-content">

第一个二值图像，指定为任意维度的逻辑数组。

**数据类型：** Bool

  </div>
</div>

<div id="x49c57558" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW2 — 第二个二值图像<div>逻辑数组</div></summary>
</details>
<div class="details-content">

第二个二值图像，指定为与 [BW1](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x5cd22beb) 大小相同的逻辑数组。

**数据类型：** Bool

  </div>
</div>

<div id="x2491228e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>L1 — 第一个标签图像<div>非负整数数组</div></summary>
</details>
<div class="details-content">

第一个标签图像，指定为任意维度的非负整数数组。

**数据类型：** Int64

  </div>
</div>

<div id="x2146855" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>L2 — 第二个标签图像<div>非负整数数组</div></summary>
</details>
<div class="details-content">

第二个标签图像，指定为与 [L1](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageSegmentation/EvaluateSegmentationAccuracy/jaccard.html#x2491228e) 大小相同的非负整数数组。

**数据类型：** Int64

  </div>
</div>

## 输出参数

<div id="similarity—Jaccard" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>similarity — 杰卡德相似系数<div>数值标量 | 数值向量</div></summary>
</details>
<div class="details-content">

杰卡德相似系数，以数值标量或数值向量形式返回，值在 [0, 1] 范围内。similarity 为 1 表示两个图像中的分割完全匹配。如果输入数组是：

- 二值图像，则 similarity 为标量。
- 标签图像，则 similarity 为向量，其中第一个系数是标签 1 的杰卡德指数，第二个系数是标签 2 的杰卡德指数，依此类推。

**数据类型：** Float64

  </div>
</div>

## 详细信息

### 杰卡德相似系数

两个集合 A 和 B 的杰卡德相似系数（也称为交并比即 IoU）表示为：

$$jaccard(A,B) = \frac{|intersection(A,B)|}{|union(A,B)|}$$

其中 |A| 表示集合 A 的基数。杰卡德指数也可以用真正例 (TP)、假正例 (FP) 和假反例 (FN) 表示为：

$$jaccard(A,B) = \frac{TP}{TP + FP + FN}$$

杰卡德指数与索伦森-戴斯指数满足如下关系：

$$jaccard(A,B) = \frac{dice(A,B)}{2 - dice(A,B)}$$

