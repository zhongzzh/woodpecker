# bwboundaries
---
跟踪二值图像中的对象边界

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
B, = bwboundaries(BW)
B, = bwboundaries(BW,conn)
B, = bwboundaries(___,options)
B, = bwboundaries(___;CoordinateOrder="yx")
B,n = bwboundaries(___, "holes")
B,L,n = bwboundaries(___, "noholes")
```

## 说明

[B](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#cbd624e7), = bwboundaries([BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x7eb92483)) 跟踪二值图像 BW 中对象的外边界以及这些对象内部孔洞的边界。bwboundaries 还跟踪父对象完全包围的子对象的外边界和孔洞边界。该函数返回由边界像素位置组成的数组 B。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x536f18a7)

***
[B](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#cbd624e7), = bwboundaries([BW](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x7eb92483),[conn](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#ce57ef95)) 指定跟踪对象边界时要使用的 conn 连通性。

***
[B](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#cbd624e7), = bwboundaries(___,[options](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x4a6d7018)) 跟踪对象的外边界，并通过将 options 设置为 "holes" 或 "noholes" 来指定是否包括孔洞的边界。

***
[B](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#cbd624e7), = bwboundaries(___;[CoordinateOrder](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x7620f2c1)="yx") 使用使用关键字参数 CoordinateOrder 指定跟踪样式和返回的顶点坐标的顺序。

***
[B](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#cbd624e7),[n](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x6f314323) = bwboundaries(___, "holes") 还返回 n（找到的对象数量）。

***
[B](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#cbd624e7),[L](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#fbc5099e),[n](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x6f314323) = bwboundaries(___, "noholes") 还返回标签矩阵 L，该矩阵用于标记对象和孔洞。（options 为 "noholes" 有效。）[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DisplayBoundaries/bwboundaries.html#x2573f5bf)

## 示例

<div id="x2573f5bf" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>在图像上叠加区域边界</summary>
</details>
<div class="details-content">

将灰度图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

I = imread("rice.png");
```

使用局部自适应阈值将灰度图像转换为二值图像。

```julia
BW = imbinarize(I);
```

计算图像中区域的边界，并在图像上叠加边界。

```julia
B, L, = bwboundaries(BW, "noholes");
imshow(L)
hold("on")
for i in 1:length(B)
    plot(
        B[i][:, 2],
        B[i][:, 1];
        marker="o",
        markersize=1,
        markerfacecolor="r",
        markeredgecolor="r",
    )
end
```

<img :src="$withBase('/TyImageProcessing/Images/bwboundaries/example1/example1.webp')">

  </div>
</div>

<div id="x536f18a7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>用红色显示对象边界，用绿色显示孔边界</summary>
</details>
<div class="details-content">

将二值图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

BW = imread("blobs.png");
```

计算边界。

```julia
B, N = bwboundaries(BW);
```

用红色显示对象边界，用绿色显示孔边界。

```julia
imshow(BW);
hold("on");
for k in 1:length(B)
    local boundary = B[k]
    if k > N
        plot(
            boundary[:, 2],
            boundary[:, 1];
            marker="o",
            markersize=1,
            markerfacecolor="g",
            markeredgecolor="g",
        )
    else
        plot(
            boundary[:, 2],
            boundary[:, 1];
            marker="o",
            markersize=1,
            markerfacecolor="r",
            markeredgecolor="r",
        )
    end
end
```

<img :src="$withBase('/TyImageProcessing/Images/bwboundaries/example3/example1.png')">

  </div>
</div>

## 输入参数

<div id="x7eb92483" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>BW - 输入二值图像<div>二维数值矩阵 | 二维逻辑矩阵</div></summary>
</details>
<div class="details-content">

二值输入图像，指定为二维逻辑或数值矩阵。BW 必须为二值图像，其中非零像素属于一个对象，零值像素构成背景。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64 | bool

  </div>
</div>

<div id="ce57ef95" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>conn - 像素连通性<div>8 （默认） | 4</div></summary>
</details>
<div class="details-content">

像素连通性，指定为下表中的值之一。（暂只支持 8 像素连通性）

| 值         | 意义                                                         |
| --------- | ------------------------------------------------------------ |
| 4     | 如果像素的边缘相互接触，则这些像素具有连通性。如果两个相邻像素都为 on 并在水平或垂直方向上连通，则它们是同一对象的一部分。                           |
| 8    | 如果像素的边缘或角相互接触，则这些像素具有连通性。如果两个相邻像素都为 on 并在水平、垂直或对角线方向上连通，则它们是同一对象的一部分。                           |

**数据类型：** Int64

  </div>
</div>

<div id="x4a6d7018" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>options - 确定是否同时搜索父对象边界和子对象边界<div>"holes" （默认） | "noholes"</div></summary>
</details>
<div class="details-content">

确定是否同时搜索父对象边界和子对象边界，指定为以下任一项：

| 选项         | 意义                                                         |
| ---------- | ------------------------------------------------------------ |
| "holes"     | 同时搜索对象和孔洞边界。这是默认设置。                           |
| "noholes"    | 仅搜索对象（父对象和子对象）边界。这可以提供更好的性能。                           |

**数据类型：** String

  </div>
</div>

<div id="x7620f2c1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>CoordinateOrder — 返回的顶点坐标的顺序<div>"yx" (默认) | "xy"</div></summary>
</details>
<div class="details-content">

返回的顶点坐标的顺序，指定为 "yx" 或 "xy"。

| 顺序         | 意义                                                         |
| ---------- | ------------------------------------------------------------ |
| "yx"     | 以 (y, x) 坐标形式返回边界顶点，返回顺序与 (row, column) 坐标的顺序相同                           |
| "xy"    | 以 (x, y) 坐标形式返回边界顶点                           |

**数据类型：** String

  </div>
</div>

## 输出参数

<div id="cbd624e7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>B - 边界像素的行和列坐标<div>p×1 矩阵</div></summary>
</details>
<div class="details-content">

边界像素的行和列坐标，以 p×1 矩阵形式返回，其中 p 是对象和孔洞的数量。数组中的每个元素都包含一个 q×2 矩阵。矩阵中的每行都包含一个边界像素的行和列坐标。q 是对应区域的边界像素的数量。

  </div>
</div>

<div id="fbc5099e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>L - 标签矩阵<div>非负整数的二维矩阵</div></summary>
</details>
<div class="details-content">

连续区域的标签矩阵，以由非负整数组成的二维矩阵形式返回。第 k 个区域包含 L 中所有具有 k 值的元素。由 L 表示的对象和孔洞的数量等于 max(L(:))。L 的零值元素构成背景。

**数据类型：** Float64

  </div>
</div>

<div id="x6f314323" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>n - 找到的对象的数量<div>非负整数</div></summary>
</details>
<div class="details-content">

找到的对象的数量，以非负整数形式返回。

**数据类型：** Int64

  </div>
</div>