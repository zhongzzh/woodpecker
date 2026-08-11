# edge
---
查找二维灰度图像中的边缘

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
BW = edge(I;fig)
BW = edge(I,method;fig)
BW = edge(I,method;fig,threshold)
BW = edge(I,method;fig,threshold,direction)
BW = edge(I,method;fig,threshold,sigma)
BW,threshOut = edge(___)

# 用法示例
BW,threshOut = edge(I,"Canny";fig = false,threshold=[0.1 0.3],sigma=1.3)
edge(I,"Canny";fig = true,threshold=[0.1 0.3],sigma=1.3)
BW = edge(I,"Prewitt";fig = false,direction="both")
edge(I,"Prewitt";fig = true,direction="both")
BW = edge(I,"Sobel";fig = false,direction="both")
edge(I,"Sobel";fig = true,direction="both")
BW = edge(I,"Roberts";fig = false,direction="both")
edge(I,"Roberts";fig = true,direction="both")
BW = edge(I,"log";fig = false)
edge(I,"log";fig = true)
BW = edge(I,"zerocross";fig = false)
edge(I,"zerocross";fig = true)
```

## 说明

[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#cd1e0142) = edge([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x1cfebab7);fig = false) 返回二值图像 BW，其中的值 1 对应于灰度或二值图像 I 中函数找到边缘的位置，值 0 对应于其他位置。默认情况下，edge 使用索贝尔边缘检测方法。关键字 fig 为 Bool 变量，当 fig 为 true 时，自动绘图，否则，返回变量 BW。

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#cd1e0142) = edge([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x1cfebab7),[method](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#a872a3fe);fig) 使用 method 指定的边缘检测算法检测图像 I 中的边缘。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x462cf8d3)

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#cd1e0142) = edge([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x1cfebab7),[method](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#a872a3fe);fig,[threshold](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x075d40e3)) 返回强度高于 threshold 的所有边缘。

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#cd1e0142) = edge([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x1cfebab7),[method](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#a872a3fe);fig,[threshold](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x075d40e3),[direction](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x2c9426ef)) 指定要检测的边缘的方向。索贝尔和普瑞维特方法可以检测垂直方向和/或水平方向的边缘。罗伯茨方法可以检测与水平方向成 45 度角和/或 135 度角的边缘。仅当 method 是 "Sobel"、"Prewitt" 或 "Roberts" 时，此语法才有效。

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#cd1e0142) = edge([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x1cfebab7),[method](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#a872a3fe);fig,[threshold](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x075d40e3),[sigma](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x0afecc4c)) 指定 sigma，即滤波器的标准差。仅当 method 是 "Canny" 时，此语法才有效。

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#cd1e0142),[threshOut](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x81be8d04) = edge(___;fig=false) 还返回阈值。

## 示例

<div id="x462cf8d3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>比较使用坎尼和普瑞维特方法的边缘检测结果</summary>
</details>
<div class="details-content">

将灰度图像读入工作区并显示它。

```julia
using TyImageProcessing
using TyPlot

I = imread("circuit.tif");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Images/edge/example1/example1.webp')">

使用坎尼方法查找边缘。

```julia
BW1, = edge(I, "Canny"; fig=false);
```

使用普瑞维特方法查找边缘。

```julia
BW2 = edge(I, "Prewitt"; fig=false);
```

将两个结果并排显示。

```julia
imshowpair(BW1, BW2, "montage")
```

<img :src="$withBase('/TyImageProcessing/Images/edge/example1/example2.png')">

  </div>
</div>

## 输入参数

<div id="x1cfebab7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 输入图像<div>二维灰度图像 | 二维二值图像</div></summary>
</details>
<div class="details-content">

输入图像，指定为二维灰度图像或二维二值图像。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64 | Bool

  </div>
</div>

<div id="a872a3fe" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>method — 边缘检测方法<div>"Sobel" (默认) | "Prewitt" | "Roberts" | "log" | "zerocross" | "Canny"</div></summary>
</details>
<div class="details-content">

边缘检测方法，指定为下列方法之一。

| 方法         | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| "Sobel"     | 使用导数的 Sobel 逼近，通过寻找图像 I 的梯度最大的那些点来查找边缘。                           |
| "Prewitt"    | 使用导数的 Prewitt 逼近，通过寻找 I 的梯度最大的那些点来查找边缘。                           |
| "Roberts"     | 使用导数的 Roberts 逼近，通过寻找 I 的梯度最大的那些点来查找边缘。                           |
| "log"    | 使用高斯拉普拉斯 (LoG) 滤波器对 I 进行滤波后，通过寻找过零点来查找边缘。                           |
| "zerocross"     | 使用您指定的滤波器 h 对 I 进行滤波后，通过寻找过零点来查找边缘。                           |
| "Canny"    | 通过寻找 I 的梯度的局部最大值来查找边缘。edge 函数使用高斯滤波器的导数计算梯度。此方法使用双阈值来检测强边缘和弱边缘，如果弱边缘与强边缘连通，则将弱边缘包含到输出中。通过使用双阈值，Canny 方法相对其他方法不易受噪声干扰，更可能检测到真正的弱边缘。                           |

  </div>
</div>

<div id="x075d40e3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>threshold — 敏感度阈值<div>数值标量 | 二元素向量</div></summary>
</details>
<div class="details-content">

敏感度阈值，指定为数值标量（对于一般 method）或二元素向量（对于 "Canny" 方法）。edge 忽略所有强度不大于 threshold 的边缘。

- 如果不指定 threshold 或指定空数组 ([])，则 edge 会自动选择一个或多个值。

- 对于 "log" 和 "zerocross" 方法，如果您指定阈值 0，则输出图像具有闭合轮廓，因为它包括输入图像中的所有过零点。

- "Canny" 方法使用两个阈值。edge 忽略边缘强度低于下阈值的所有边缘，保留边缘强度高于上阈值的所有边缘。您可以将 threshold 指定为 [low high] 形式的二元素向量，其中 low 和 high 值在范围 [0, 1] 内。您还可以将 threshold 指定为数值标量，edge 将其分配给上阈值。在这种情况下，edge 使用 threshold*0.4 作为下阈值。

**数据类型：** Float64

  </div>
</div>

<div id="x2c9426ef" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>direction — 要检测的边缘的方向<div>"both" (默认) | "horizontal" | "vertical"</div></summary>
</details>
<div class="details-content">

要检测的边缘的方向，指定为 "horizontal"、"vertical" 或 "both"。仅当 [method](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#a872a3fe) 是 "Sobel"、"Prewitt" 或 "Roberts" 时，direction 参数才有效。

**数据类型：** String

  </div>
</div>

<div id="x0afecc4c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sigma — 滤波器的标准差<div>数值标量</div></summary>
</details>
<div class="details-content">

滤波器的标准差，指定为数值标量。仅 "Canny" 和 "log" 方法支持 sigma 参数。

| 方法         | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| "Canny"     | 标量值，指定高斯滤波器标准差。默认值为 sqrt(2)。edge 根据 sigma 自动选择滤波器的大小。                           |
| "log"（高斯拉普拉斯）    | 标量值，指定高斯拉普拉斯滤波器标准差。默认值为 2。滤波器的大小为 n×n，其中 n=ceil(sigma*3)*2+1。                           |

**数据类型：** Float64

  </div>
</div>

## 输出参数

<div id="cd1e0142" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW — 输出二值图像<div>数值数组</div></summary>
</details>
<div class="details-content">

输出二值图像，以与 [I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectEdgesandGradients/edge.html#x1cfebab7) 大小相同的 UInt8 形式返回，值 1 对应于 I 中函数找到边缘的位置，值 0 对应于其他位置。

  </div>
</div>

<div id="x81be8d04" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>threshOut — 计算的阈值<div>二元素向量</div></summary>
</details>
<div class="details-content">

在运算中使用的计算的阈值，以二元素向量形式（仅对于 "Canny" method 方法生效）形式返回。

  </div>
</div>