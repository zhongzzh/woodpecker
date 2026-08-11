# radon
---
拉东变换

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
R, = radon(I)
R, = radon(I,theta)
R,xp = radon(___)
```

## 说明

[R](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#x943f2d65), = radon([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#a9ed2167)) 返回二维灰度图像 I 的拉东变换 R，角度范围为 [0, 179] 度。拉东变换是图像强度沿特定角度的径向线的投影。

***
[R](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#x943f2d65), = radon([I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#a9ed2167),[theta](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#d15e4343)) 返回基于 theta 所指定角度的拉东变换。

***
[R](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#x943f2d65),[xp](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#x6953a533) = radon(___) 返回向量 xp，其中包含与图像的每行对应的径向坐标。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#x14630167)

## 示例

<div id="x14630167" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算拉东变换并显示绘图</summary>
</details>
<div class="details-content">

创建示例图像。

```julia
using TyImageProcessing
using TyPlot

I = zeros(100,100);
I[25:75, 25:75] .= 1;
```

计算拉东变换。

```julia
theta = 0:180;
R,xp = radon(I,theta);
```

显示该变换。

```julia
c = imshow(R,[])
xlabel("θ (degrees)")
ylabel("x'")
colormap(c,"hot")
colorbar(c)
```

<img :src="$withBase('/TyImageProcessing/Images/radon/example1/example1.png')">

  </div>
</div>

## 输入参数

<div id="a9ed2167" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>I — 灰度图像<div>二维数值矩阵</div></summary>
</details>
<div class="details-content">

灰度图像，指定为二维数值矩阵。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="d15e4343" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>theta — 投影角度<div>0:179 (默认) | 数值向量</div></summary>
</details>
<div class="details-content">

投影角度（以度为单位），指定为数值向量。

**数据类型：** Int64

  </div>
</div>

## 输出参数

<div id="x943f2d65" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>R — 拉东变换<div>数值矩阵</div></summary>
</details>
<div class="details-content">

图像 [I](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#a9ed2167) 的拉东变换。

  </div>
</div>

<div id="x6953a533" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>xp — 径向坐标<div>数值向量</div></summary>
</details>
<div class="details-content">

对应于 [R](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#x943f2d65) 的每行的径向坐标，以数值向量形式返回。径向坐标是沿 x' 轴的值，该值与 x 轴呈逆时针方向 [theta](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html#d15e4343) 度角。

  </div>
</div>