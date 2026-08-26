# hdrread
---
读取高动态范围(HDR)图像

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
HDR = hdrread(filename)
```

## 说明

[HDR](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/hdrread.html#x7fc8391f) = hdrread([filename](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/hdrread.html#x44aff7be)) 从 filename 指定的文件读取高动态范围 (HDR) 图像。对于场景参考数据集，像素值通常是场景照度的辐射单位。[示例](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/hdrread.html#x167a5fc9)

## 示例

<div id="x167a5fc9" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>读取和显示高动态范围图像</summary>
</details>
<div class="details-content">

将高动态范围图像读入工作区。

```julia
using TyImageProcessing
using TyPlot

HDR = hdrread("office.hdr");
```

hdrread 返回 m×n×3 数组 HDR。

要将 HDR 图像转换为适合显示的较低动态范围，使用 localtonemap 函数。

```julia
RGB = localtonemap(HDR);
```

显示图像。

```julia
figure()
imshow(RGB)
```

<img :src="$withBase('/TyImageProcessing/Images/hdrread/example1/example1.png')">

  </div>
</div>

## 输入参数

<div id="x44aff7be" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>filename — 文件名<div>字符串标量</div></summary>
</details>
<div class="details-content">

HDR 图像的文件名，指定为字符串标量。

**示例：** "office.hdr"

**数据类型：** String

  </div>
</div>

## 输出参数

<div id="x7fc8391f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>HDR — 高动态范围图像<div>m×n×3 数值数组</div></summary>
</details>
<div class="details-content">

高动态范围图像，作为 m×n×3 数值数组返回，其值范围为 [0, Inf)。

**数据类型：** Float32

  </div>
</div>

## 提示

要显示 HDR 图像，请使用合适的色调映射函数，例如 [localtonemap](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html)。

## 参考文献

[1] Larson, Greg W. "Radiance File Formats". *http://radsite.lbl.gov/radiance/refer/filefmts.pdf*

## 另请参阅

[localtonemap](/Doc/TyImageProcessing/Import,Export,andConversion/HighDynamicRangeImages/localtonemap.html)
