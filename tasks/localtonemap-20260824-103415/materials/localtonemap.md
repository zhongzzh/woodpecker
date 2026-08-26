# localtonemap
---
在增强局部对比度的同时渲染 HDR 图像以供查看

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
RGB = localtonemap(HDR)
RGB = localtonemap(HDR; Name=Value)
```

## 说明

[RGB](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html#x540339d2) = localtonemap([HDR](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html#x2fd8b1e7)) 将高动态范围 (HDR) 图像 HDR 转换为适合显示的低动态范围 (LDR) 图像 RGB。localtonemap 使用一种称为色调映射的处理过程，同时保留图像的局部对比度。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html#e3536fd5)

***
[RGB](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html#x540339d2) = localtonemap([HDR](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html#x2fd8b1e7); [Name=Value](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html#dafb1454)) 使用名称-值参数控制色调映射的各个方面。

## 示例

<div id="e3536fd5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>压缩 HDR 图像的动态范围以供查看</summary>
</details>
<div class="details-content">

读取一幅高动态范围图像。

```julia
using TyImageProcessing
using TyPlot

HDR = hdrread("office.hdr");
```

应用局部色调映射，并进行少量的动态范围压缩。

```julia
RGB = localtonemap(HDR; RangeCompression=0.1);
```

显示生成的色调映射图像。

```julia
figure()
imshow(RGB)
```

<img :src="$withBase('/TyImageProcessing/Images/localtonemap/example1/example1.png')">

重复该操作，但这一次增强图像中的细节。

```julia
RGBEnhanced = localtonemap(HDR; RangeCompression=0.1, EnhanceContrast=0.5);
```

显示出带有更高细节的色调映射图像。

```julia
figure()
imshow(RGBEnhanced)
```

<img :src="$withBase('/TyImageProcessing/Images/localtonemap/example1/example2.png')">

  </div>
</div>

## 输入参数

<div id="x2fd8b1e7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>HDR — HDR 图像<div>m×n 矩阵 | m×n×3 数组</div></summary>
</details>
<div class="details-content">

HDR 图像，指定为非负数的 m×n 矩阵或 m×n×3 数组。

**数据类型：** Float32

  </div>
</div>

<div id="dafb1454" class="jump-target"></div>

## 名称-值参数
指定可选的参数对作为 Name1=Value1,...,NameN=ValueN，其中 Name 是参数名称，Value 是相应的值。名称-值参数必须出现在其他参数之后，但是对这些对的顺序不重要。

**示例：** RGB = localtonemap(HDR; RangeCompression=0.5); 将范围压缩设置为 0.5。

<div id="RangeCompression—压缩量" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RangeCompression — 压缩量<div>1（默认） | [0, 1] 范围内的数字</div></summary>
</details>
<div class="details-content">

应用于 HDR 图像动态范围的压缩量，指定为 [0, 1] 范围内的数字。

| 值 | 说明 |
| --- | --- |
| `0` | 最小压缩，仅将中间 99% 的强度重新映射到 100:1 的动态范围，然后进行指数为 1/2.2 的伽马校正。 |
| `1` | 使用局部拉普拉斯滤波的最大压缩。 |

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

<div id="EnhanceContrast—局部对比度增强量" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>EnhanceContrast — 局部对比度增强量<div>0（默认） | [0, 1] 范围内的数字</div></summary>
</details>
<div class="details-content">

局部对比度增强量，指定为 [0, 1] 范围内的数字。

| 值 | 说明 |
| --- | --- |
| 0 | 不改变局部对比度 |
| 1 | 最大局部对比度增强 |

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64

  </div>
</div>

## 输出参数

<div id="x540339d2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>RGB — 低动态范围图像<div>数值数组</div></summary>
</details>
<div class="details-content">

低动态范围图像，作为与输入图像 HDR 相同大小的数值数组返回。

**数据类型：** Float32

  </div>
</div>

## 算法

localtonemap 在对数空间中使用局部拉普拉斯滤波来压缩 HDR 图像的动态范围，同时保留或增强其局部对比度。然后将压缩图像的中间 99% 强度重新映射到固定的 100:1 动态范围，使输出图像具有一致的外观。localtonemap 随后应用伽马校正以生成用于显示的最终图像。
