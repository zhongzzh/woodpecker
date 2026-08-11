# 校正亮度不均匀问题并分析前景目标
---

<helpButton exampleUrl="/05 Graphics/04 Images/05_SegmentRiceGrains.jl">打开示例</helpButton>

此示例说明如何在图像分析前执行预处理。首先使用形态学开运算校正背景亮度不均匀问题，然后将图像转换为二值图像以识别前景中的米粒，最后计算各米粒的面积并分析面积分布。

## 步骤 1：读取并显示图像

使用 [imread](/Doc/TyImageProcessing/Import,Export,andConversion/ReadandWriteImageDatafromFiles/GenericFileImportandExport/imread.html) 读取灰度图像 `rice.png`，然后使用 [imshow](/Doc/TyImageProcessing/DisplayandExploration/BasicDisplay/DisplayImagesandImageSequences/imshow.html) 显示图像。

```julia
using TyImageProcessing
using TyPlot

I = imread("rice.png");
imshow(I)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img1.png')">

图像中心的背景亮度高于图像底部。为了可靠地分割米粒，需要先使背景亮度更加均匀。

## 步骤 2：估计不均匀背景

使用形态学开运算去除前景中的米粒，只保留缓慢变化的背景。首先使用 [strel](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/CreateStructuringElementsandConnectivityArrays/strel.html) 创建半径为 15 的盘形结构元素。该结构元素可以完全放入一粒米内，因此开运算能够去除比它小的明亮目标。

```julia
se = strel("disk", 15);
```

使用 [imopen](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imopen.html) 对图像执行形态学开运算，得到背景的近似图像。

```julia
background = imopen(I, se);
imshow(background)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img2.png')">

## 步骤 3：从原始图像中减去背景

使用 [imsubtract](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageArithmetic/imsubtract.html) 从原始图像中减去背景近似图像。处理后的图像具有更均匀的背景，但整体对比度仍然较低。

```julia
I2 = imsubtract(I, background);
imshow(I2)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img3.png')">

也可以使用 [imtophat](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html) 在一个步骤中完成开运算和背景相减。

```julia
I2 = imtophat(I, strel("disk", 15));
```

## 步骤 4：提高图像对比度

使用 [imadjust](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ContrastAdjustment/imadjust.html) 拉伸图像的强度范围，提高米粒与背景之间的对比度。

```julia
I3 = imadjust(I2);
imshow(I3)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img4.png')">

## 步骤 5：创建并清理二值图像

使用 [imbinarize](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html) 将增强后的灰度图像转换为二值图像。然后使用 [bwareaopen](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/bwareaopen.html) 删除面积小于 50 个像素的前景区域，以去除背景噪声。

```julia
bw = imbinarize(I3);
bw = bwareaopen(bw, 50);
imshow(bw)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img5.png')">

## 步骤 6：识别图像中的目标

使用 [bwconncomp](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/bwconncomp.html) 查找二值图像中的所有四连通分量。每个连通分量表示一个前景目标。相互接触的米粒可能被识别为同一个目标。

```julia
cc = bwconncomp(bw, 4);
println("目标数量：", cc.NumObjects)
```

```dataframe
目标数量：95
```

`PixelIdxList` 保存每个目标所包含像素的线性索引。下面创建一幅二值图像，单独显示第 50 个目标。

```julia
grain = falses(size(bw));
grain[Int64.(cc.PixelIdxList[50])] .= true;
imshow(grain)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img6.png')">

## 步骤 7：以不同颜色显示连通分量

使用 [labelmatrix](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/labelmatrix.html) 根据连通分量创建标签矩阵。矩阵中的零值表示背景，正整数表示不同的目标。

```julia
labeled = labelmatrix(cc);
println("type: ", typeof(labeled))
println("size: ", size(labeled))
```

```dataframe
type: Matrix{UInt8}
size: (256, 256)
```

使用 [label2rgb](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConvertBetweenImageTypes/label2rgb.html) 将标签矩阵转换为伪彩色 RGB 图像。不同标签被映射为不同颜色，背景显示为青色。

```julia
RGBLabel = label2rgb(labeled, TyPlot.spring(cc.NumObjects), "c", "shuffle");
imshow(RGBLabel)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img7.png')">

## 步骤 8：计算目标的面积

使用 [regionprops](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/MeasurePropertiesofImageRegions/regionprops.html) 计算每个连通分量的基本属性，包括面积、质心和边界框。

```julia
grainData = regionprops(cc, "basic");
grainAreas = [item.Area for item in grainData];
```

查看第 50 个米粒的面积。

```julia
println("第 50 个目标的面积：", grainAreas[50])
```

```dataframe
第 50 个目标的面积：194
```

使用 `findmin` 找到面积最小的目标及其索引，然后单独显示该目标。

```julia
minArea, idx = findmin(grainAreas);
println("最小面积：", minArea)

smallestGrain = falses(size(bw));
smallestGrain[Int64.(cc.PixelIdxList[idx])] .= true;
imshow(smallestGrain)
```

```dataframe
最小面积：61
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img8.png')">

## 步骤 9：分析目标面积的分布

使用 [histogram](/Doc/TyPlot/2Dand3DPlots/DataDistributionPlots/histogram.html) 绘制所有米粒面积的直方图。直方图可以帮助观察典型米粒的面积范围，以及发现可能由相互接触的米粒形成的较大连通区域。

```julia
figure()
histogram(grainAreas)
title("米粒面积直方图")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/correcting-nonuniform-illumination/img9.png')">

通过形态学背景校正、二值化、连通分量分析和区域属性测量，可以从亮度不均匀的图像中识别前景目标并计算统计量。结构元素大小、二值化阈值、最小目标面积和连通方式都会影响最终结果，应根据实际图像进行调整。

## 另请参阅

[strel](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/CreateStructuringElementsandConnectivityArrays/strel.html) | [imopen](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imopen.html) | [imtophat](/Doc/TyImageProcessing/ImageFilteringandEnhancement/MorphologicalOperations/PerformMorphologicalOperations/imtophat.html) | [imbinarize](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/imbinarize.html) | [bwconncomp](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/bwconncomp.html) | [regionprops](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/MeasurePropertiesofImageRegions/regionprops.html)
