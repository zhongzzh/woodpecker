# 检测和测量图像中的圆形目标
---

<helpButton exampleUrl="/05 Graphics/04 Images/03_DetectAndMeasureCircularObjectsInAnImage.jl">打开示例</helpButton>

此示例说明如何使用圆形霍夫变换自动检测图像中的圆形目标、估计圆心和半径，并将检测结果绘制在原始图像上。

## 步骤 1：读取并显示图像

使用 [imread](/Doc/TyImageProcessing/Import,Export,andConversion/ReadandWriteImageDatafromFiles/GenericFileImportandExport/imread.html) 读取包含多种彩色圆形塑料片的图像。图中既有与背景对比明显的红色、蓝色塑料片，也有与背景对比不明显的黄色塑料片。此外，一些塑料片彼此重叠或几乎接触，这些情况都会增加圆检测的难度。

```julia
using TyImageProcessing
using TyPlot

rgb = imread("coloredChips.png");
imshow(rgb)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/colored-chips.png')">

## 步骤 2：确定要搜索的半径范围

使用 `imdistline` 函数找到合适的圆半径范围。在塑料片的近似直径上绘制一条线。

```julia
d = imdistline()
setLabelVisible(d, false)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/measure-radius-range.png')">

线 ROI 的长度就是塑料片的直径。通常的塑料片的直径在 40 到 50 个像素的范围内。

```julia
pos = getPosition(d)
diffPos = diff(pos; dims=1)
diameter = hypot(diffPos[1, 1], diffPos[1, 2])
```

```dataframe
45
```

## 步骤 3：判断圆形目标的极性

使用 [im2gray](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConvertBetweenImageTypes/im2gray.html) 将彩色图像转换为灰度图像，以便比较塑料片与背景的亮度。

```julia
grayImage = im2gray(rgb);
imshow(grayImage)
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/grayscale-chips.png')">

背景整体较亮，大多数红色和蓝色塑料片比背景暗。因此，调用 [imfindcircles](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectCircles/imfindcircles.html) 时，将 `ObjectPolarity` 指定为 `"dark"`。

```julia
centers, radii = imfindcircles(rgb, radiusRange; ObjectPolarity="dark");
```

`centers` 是一个 P×2 矩阵，每行依次给出一个圆心的 x、y 坐标；`radii` 是对应的估计半径向量。P 为检测到的圆的数量。

## 步骤 4：提高检测敏感度

`Sensitivity` 控制圆检测器的敏感度，其取值范围为 0 到 1，默认值为 0.7。增大该值通常会检测到更多圆，但也可能增加误检。

```julia
centers, radii = imfindcircles(rgb, radiusRange;
    ObjectPolarity="dark", Sensitivity=0.7);
```

使用 [viscircles](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectCircles/viscircles.html) 将检测到的圆绘制在原始图像上。

```julia
imshow(rgb)
viscircles(centers, radii; Color="r")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/dark-circles.png')">

## 步骤 5：进一步检测较弱的暗圆

仍有一些暗色塑料片未被检测到。将 `Sensitivity` 进一步提高到 0.94，然后重新绘制检测结果。

```julia
centersDark, radiiDark = imfindcircles(rgb, radiusRange;
    ObjectPolarity="dark", Sensitivity=0.94);

imshow(rgb)
viscircles(centersDark, radiiDark; Color="r")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/dark-circles-high-sensitivity.png')">

提高敏感度后，检测器能够找到更多圆。即使部分塑料片受到遮挡，只要仍保留足够的圆周边缘，也可以估计其圆心和半径。

## 步骤 6：检测比背景亮的圆

灰度图像表明，一些黄色塑料片的亮度与背景接近，甚至比背景更亮。仅搜索暗圆时无法找到这些目标。将 `ObjectPolarity` 改为 `"bright"`，单独搜索亮圆。

```julia
centersBright, radiiBright = imfindcircles(rgb, radiusRange;
    ObjectPolarity="bright", Sensitivity=0.95);

imshow(rgb)
viscircles(centersBright, radiiBright; Color="b")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/bright-circles.png')">

蓝色圆周标出了检测到的亮圆。对于与背景对比度较低的目标，圆周边缘较弱，检测结果会对 `Sensitivity` 的设置更加敏感。

## 步骤 7：同时显示暗圆和亮圆

分别检测暗圆和亮圆后，将两组结果叠加到同一幅图像上。这里使用红色表示暗圆，蓝色表示亮圆。

```julia
imshow(rgb)
viscircles(centersDark, radiiDark; Color="r")
viscircles(centersBright, radiiBright; Color="b")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/detect-and-measure-circular-objects-in-an-image/dark-and-bright-circles.png')">

通过分别指定对象极性，可以检测同一图像中具有不同对比度的圆形目标。实际应用中应根据图像质量调整半径范围和敏感度，在检测率与误检率之间取得平衡。

## 另请参阅

[imread](/Doc/TyImageProcessing/Import,Export,andConversion/ReadandWriteImageDatafromFiles/GenericFileImportandExport/imread.html) | [im2gray](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConvertBetweenImageTypes/im2gray.html) | [imfindcircles](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectCircles/imfindcircles.html) | [viscircles](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/ObjectAnalysis/DetectCircles/viscircles.html)
