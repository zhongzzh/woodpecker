# imtophat
---
顶帽滤波

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
J = imtophat(I,SE)
```

## 说明

[J](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html#x151cc094) = imtophat([I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html#x6ed26b3e),[SE](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html#a67311dd)) 使用结构元素 SE 对灰度或二值图像 I 执行形态学顶帽滤波。顶帽滤波计算图像的形态学开运算（使用 [imopen](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imopen.html)），然后从原始图像中减去结果。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html#d6189111)

## 示例

<div id="d6189111" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用顶帽滤波校正不均匀的亮度</summary>
</details>
<div class="details-content">

此示例说明如何使用具有盘形结构元素的顶帽滤波从具有暗背景的图像中去除不均匀的背景亮度。

读取一个图像并显示它。

```julia
using TyImageProcessing
using TyPlot

original = imread("rice.png");
imshow(original)
```

<img :src="$withBase('/TyImageProcessing/Images/imtophat/example1/example1.webp')">

创建该结构元素。

```julia
se = strel("disk",12);
```

执行顶帽滤波并显示图像。

```julia
tophatFiltered = imtophat(original,se);
figure()
imshow(tophatFiltered)
```

<img :src="$withBase('/TyImageProcessing/Images/imtophat/example1/example2.webp')">

  </div>
</div>

## 输入参数

<div id="x6ed26b3e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 输入图像<div>灰度图像 | 二值图像</div></summary>
</details>
<div class="details-content">

输入图像，指定为任意维度的灰度图像或二值图像。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64 | Bool

  </div>
</div>

<div id="a67311dd" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>SE — 结构元素<div>数值矩阵 | 逻辑矩阵</div></summary>
</details>
<div class="details-content">

结构元素，数值矩阵或逻辑矩阵。

**数据类型：** UInt8 | Bool

  </div>
</div>

## 输出参数

<div id="x151cc094" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>J — 顶帽滤波后的图像<div>灰度图像 | 二值图像</div></summary>
</details>
<div class="details-content">

经过顶帽滤波的图像，以灰度图像或二值图像形式返回。J 与输入图像 [I](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html#x6ed26b3e) 具有相同的数据类型。

  </div>
</div>