# psnr
---
峰值信噪比 (PSNR)

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
peaksnr = psnr(A,ref)
```

## 说明

[peaksnr](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageQuality/FullReferenceQualityMetrics/psnr.html#peaksnr—PSNR) = psnr([A](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageQuality/FullReferenceQualityMetrics/psnr.html#x1c4d2137),[ref](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageQuality/FullReferenceQualityMetrics/psnr.html#x6d894674)) 以图像 ref 为参考，计算图像 A 的峰值信噪比 (PSNR)。PSNR 值越大，表示图像质量越好。[示例](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageQuality/FullReferenceQualityMetrics/psnr.html#b520f2b6)

## 示例

<div id="b520f2b6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>给定原始图像作为参考，计算含噪图像的 PSNR</summary>
</details>
<div class="details-content">

读取图像并创建一个添加了噪声的副本。原始图像作为参考图像。

```julia
using TyImageProcessing

ref = imread("pout.tif");
A = imnoise(ref, "salt & pepper", 0.02);
```

计算 PSNR。

```julia
peaksnr = psnr(A, ref);
print("The Peak-SNR value is ", peaksnr);
```

```dataframe
The Peak-SNR value is 22.712125923049275
```

  </div>
</div>

## 输入参数

<div id="x1c4d2137" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — 要分析的图像<div>数值数组</div></summary>
</details>
<div class="details-content">

要分析的图像，指定为任意维度的数值数组。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

<div id="x6d894674" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ref — 参考图像<div>数值矩阵</div></summary>
</details>
<div class="details-content">

参考图像，指定为数值数组。参考图像与图像 [A](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ImageQuality/FullReferenceQualityMetrics/psnr.html#x1c4d2137) 具有相同的大小和数据类型。

**数据类型：** UInt8 | UInt16 | Int16 | Float32 | Float64

  </div>
</div>

## 输出参数

<div id="peaksnr—PSNR" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>peaksnr — PSNR<div>数值标量</div></summary>
</details>
<div class="details-content">

以分贝为单位的 PSNR。

  </div>
</div>