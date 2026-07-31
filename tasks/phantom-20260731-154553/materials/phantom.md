# phantom
---
创建头部幻影图像

<h2>函数库: TyImageProcessing</h2>

## 语法

```
P = phantom(def, n)
P = phantom(E, n)
P, E = phantom(___)
```

## 说明

[P](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x0f5021d2) = phantom([def](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x2239a1e4),[n](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x8c8f2725)) 生成一个头部幻影图像，可用于测试 radon 和 iradon 或其他二维重建算法的数值精度。P 是一个灰度图像，由一个代表大脑的大椭圆和内部若干个代表大脑特征的小椭圆组成。def 指定要生成的头部幻影类型，n 指定幻影图像中的行数和列数。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#ba8d27eb)

***
[P](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x0f5021d2) = phantom([E](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#ebd574e6),[n](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x8c8f2725)) 生成一个用户自定义的幻影图像，其中矩阵 E 的每一行指定图像中的一个椭圆。E 有六列，每列包含椭圆的不同参数。

***
[[P](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x0f5021d2),[E](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#ebd574e6)] = phantom(___) 返回用于生成幻影图像的矩阵 E。

## 示例

<div id="ba8d27eb" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>创建 Modified Shepp-Logan 头部幻影图像</summary>
</details>
<div class="details-content">

创建 Modified Shepp-Logan 头部幻影图像并显示它。

```julia
using TyImageProcessing
using TyPlot

P, = phantom("Modified Shepp-Logan", 200);
imshow(P)
```

<img :src="$withBase('/TyImageProcessing/Images/phantom/example1/Shepp-Logan.png')">

  </div>
</div>

## 输入参数

<div id="x2239a1e4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>def - 头部幻影类型<div>"Modified Shepp-Logan"（默认） | "Shepp-Logan"</div></summary>
</details>
<div class="details-content">

要生成的头部幻影类型，指定为下列字符串之一（不区分大小写）：

- `"Shepp-Logan"` — 断层扫描研究人员广泛使用的测试图像

- `"Modified Shepp-Logan"` — Shepp-Logan 幻影的变体，其中对比度经过改进以获得更好的视觉效果

**数据类型：** String

  </div>
</div>

<div id="x8c8f2725" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>n - 行数和列数<div>256（默认） | 正整数</div></summary>
</details>
<div class="details-content">

幻影图像中的行数和列数，指定为正整数。

**数据类型：** Integer

  </div>
</div>

<div id="ebd574e6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>E - 椭圆定义<div>e×6 数值矩阵</div></summary>
</details>
<div class="details-content">

定义幻影的椭圆，指定为 e×6 数值矩阵，定义 e 个椭圆。E 的六列是椭圆参数。

| 列 | 参数 | 含义 |
|:---|:---|:---|
| 第 1 列 | `A` | 椭圆的加性强度值 |
| 第 2 列 | `a` | 椭圆水平半轴的长度 |
| 第 3 列 | `b` | 椭圆垂直半轴的长度 |
| 第 4 列 | `x0` | 椭圆中心的 x 坐标 |
| 第 5 列 | `y0` | 椭圆中心的 y 坐标 |
| 第 6 列 | `phi` | 椭圆水平半轴与图像 x 轴之间的夹角（度） |

x 轴和 y 轴的定义域为 [-1, 1]。第 2 列到第 5 列必须在此范围内指定。

**数据类型：** Float64

  </div>
</div>

## 输出参数

<div id="x0f5021d2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>P - 幻影图像<div>n×n 数值矩阵</div></summary>
</details>
<div class="details-content">

幻影图像，以 [n](/Doc/TyImageProcessing/Import,Export,andConversion/SyntheticImages/phantom.html#x8c8f2725)×n 数值矩阵形式返回。

**数据类型：** Float64

  </div>
</div>

## 提示

对于输出图像中的任意像素，其值等于该像素所属的所有椭圆的加性强度值之和。如果某个像素不属于任何椭圆，则其值为 0。

椭圆的加性强度值 A 可以为正或负；如果为负，则椭圆将比周围像素更暗。请注意，根据 A 的取值，某些像素的值可能超出 [0, 1] 范围。

## 参考

[1] Jain, Anil K., *Fundamentals of Digital Image Processing*, Englewood Cliffs, NJ, Prentice Hall, 1989, p. 439.

## 另请参阅

[radon](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectLines/radon.html)