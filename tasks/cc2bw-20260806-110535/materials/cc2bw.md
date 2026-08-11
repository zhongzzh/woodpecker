# cc2bw
---
将连通分量转换为二值图像

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
BW = cc2bw(CC)
BW = cc2bw(CC,ObjectsToKeep=objectsToKeep)
```

## 说明

[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m12a3b4c5) = cc2bw([CC](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m01a2b3c4)) 根据 CC 中的连通分量（对象）创建二值图像。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m23b4c5d6)

***
[BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m12a3b4c5) = cc2bw([CC](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m01a2b3c4),ObjectsToKeep=[objectsToKeep](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m34c5d6e7)) 根据 objectsToKeep 指定的连通分量子集创建二值图像。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/cc2bw.html#m45d6e7f8)

## 示例

<div id="m23b4c5d6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>基于多个图像属性进行筛选</summary>
</details>
<div class="details-content">

读取并显示图像。

```julia
using TyImageProcessing
using TyPlot

I = imread("blobs.png");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Images/cc2bw/example1/blobs.png')">

创建连通分量结构体。

```julia
CC = bwconncomp(I);
```

筛选结构体，保留圆形对象。显示筛选后的图像。

```julia
CC = bwpropfilt(CC,"Circularity",[0.7, 1]);
imshow(cc2bw(CC))
```

<img :src="$withBase('/TyImageProcessing/Images/cc2bw/example1/Circularity.png')">

再次筛选结构体，保留大对象。显示筛选后的图像。

```julia
CC = bwpropfilt(CC,"Area",[20, Inf]);
imshow(cc2bw(CC))
```

<img :src="$withBase('/TyImageProcessing/Images/cc2bw/example1/Area.png')">

  </div>
</div>

<div id="m45d6e7f8" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>创建包含筛选对象子集的二值图像</summary>
</details>
<div class="details-content">

读取二值图像并检测连通分量。

```julia
using TyImageProcessing
using TyBase

BW = imread("text.png");
BW = BW .!= 0;
CC = bwconncomp(BW);
```

测量每个连通分量的面积。

```julia
p = regionprops(CC, "Area");

area = Float64[]
for i in 1:length(p)
    global area = vcat(area, p[i].Area)
end
```

按面积降序排序，获取排序后的索引。

```julia
_, idx = ty_sort(area, "descend"; nargout=2);
```

创建仅包含第 2 到第 10 大连通分量的二值图像。显示结果。

```julia
BWfilt = cc2bw(CC; ObjectsToKeep=idx[2:10]);
imshow(BWfilt)
```

<img :src="$withBase('/TyImageProcessing/Images/cc2bw/example2/cc2bwText.png')">

  </div>
</div>

<div id="m56e7f8g9" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>隔离垂直方向区域</summary>
</details>
<div class="details-content">

读取米粒的灰度图像，然后将图像转换为二值图像。

```julia
using TyImageProcessing

I = imread("rice.png");
BW = imbinarize(I);
imshow(BW)
```

<img :src="$withBase('/TyImageProcessing/Images/cc2bw/example3/rice.png')">

测量每个区域的面积和边界框。

```julia
CC = bwconncomp(BW);
stats = regionprops(CC, "Area", "BoundingBox");
```

选择满足以下条件的区域：

- 面积大于 50 像素
- 边界框宽度小于 15 像素且高度大于等于 20 像素

```julia
area = Float64[]
for i in 1:length(stats)
    global area = vcat(area, stats[i].Area)
end
bbox = []
for i in 1:length(stats)
    global bbox = vcat(bbox, stats[i].BoundingBox)
end
selection = (area .> 50) .& (bbox[:, 3] .< 15) .& (bbox[:, 4] .>= 20);
BW2 = cc2bw(CC; ObjectsToKeep=selection);
```

显示筛选后的图像。

```julia
imshow(BW2)
```

<img :src="$withBase('/TyImageProcessing/Images/cc2bw/example3/cc2bwRice.png')">

  </div>
</div>

## 输入参数

<div id="m01a2b3c4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>CC — 连通分量<div>结构体</div></summary>
</details>
<div class="details-content">

连通分量（对象），以具有四个字段的结构体形式指定。

| 字段         | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| Connectivity     | 连通分量（对象）的连通性                           |
| ImageSize    | 二值图像的大小                           |
| NumObjects    | 二值图像中连通分量（对象）的数量                           |
| PixelIdxList    | 1×NumObjects 矩阵，其中，矩阵中的第 k 个元素是包含第 k 个连通分量中像素的线性索引的向量。                           |

  </div>
</div>

<div id="m34c5d6e7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>objectsToKeep — 要保留的对象<div>正整数 | 正整数向量 | 逻辑向量</div></summary>
</details>
<div class="details-content">

要保留的对象，指定为下列值之一。

  - 正整数或正整数向量 — 保留索引包含在 objectsToKeep 中的对象。objectsToKeep 的长度小于等于 CC.NumObjects。
  - 逻辑向量 — 保留 objectsToKeep 中对应元素为 true 的对象。objectsToKeep 的长度必须等于 CC.NumObjects。

  </div>
</div>

## 输出参数

<div id="m12a3b4c5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW — 二值图像<div>逻辑数组</div></summary>
</details>
<div class="details-content">

二值图像，以与 CC.ImageSize 大小相同的逻辑数组形式返回。

**数据类型：** Bool

  </div>
</div>

## 另请参阅

[bwconncomp](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/bwconncomp.html) | [bwpropfilt](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/FilteringByPropertyCharacteristics/bwpropfilt.html) | [regionprops](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/MeasurePropertiesofImageRegions/regionprops.html)