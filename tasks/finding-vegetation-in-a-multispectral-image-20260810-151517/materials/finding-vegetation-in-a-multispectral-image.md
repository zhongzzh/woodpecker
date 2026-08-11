# 在多光谱图像中查找植被
---

<helpButton exampleUrl="/05 Graphics/04 Images/04_FindingVegetationInAMultispectralImage.jl">打开示例</helpButton>

此示例说明如何使用数组运算处理多光谱图像并绘制图像数据。示例比较可见红光与近红外（NIR）波段的反射率，计算归一化植被指数（NDVI），并识别包含显著植被的区域。

## 步骤 1：从多光谱图像文件导入彩色红外波段

示例数据 `paris.lan` 是一幅覆盖法国巴黎部分地区的 LANDSAT 专题制图仪图像。该 Erdas LAN 文件包含一幅 512×512、具有 7 个波段的图像。文件开头为 128 字节的头信息，后面是按照逐行波段交错（BIL）顺序存储的 `UInt8` 像素值。

本示例假定 `paris.lan` 位于当前工作目录。使用 Julia 的文件读取功能跳过头信息，然后根据 BIL 布局重排数据。

```julia
using TyImageProcessing
using TyPlot

rows, cols, bands = 512, 512, 7;

rawData = open("paris.lan", "r") do io
    seek(io, 128)
    read(io, rows * cols * bands)
end;

bilData = reshape(rawData, cols, bands, rows);
multispectral = permutedims(bilData, (3, 1, 2));
```

波段 4、3、2 分别覆盖近红外、可见红光和可见绿光。按照这一顺序将它们映射到 RGB 图像的红、绿、蓝通道，构造标准彩色红外（CIR）合成图。

```julia
CIR = multispectral[:, :, [4, 3, 2]];
imshow(CIR)
title("CIR 合成图")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/cir-composite.png')">

`CIR` 是一个 512×512×3 的 `UInt8` 数组。在这幅假彩色图像中，红色通道表示近红外波段，绿色通道表示可见红光波段，蓝色通道表示可见绿光波段。水体通常很暗，而健康植被对近红外光具有较高反射率，因此在 CIR 合成图中显示为红色。

## 步骤 2：比较近红外与可见红光波段

从 CIR 合成图中提取近红外和可见红光通道。使用 [im2single](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConvertBetweenDataTypes/im2single.html) 将 `UInt8` 数据转换为范围在 0 到 1 之间的 `Float32` 数据，以便进行后续除法运算。

```julia
NIR = im2single(CIR[:, :, 1]);
redBand = im2single(CIR[:, :, 2]);
```

分别显示可见红光波段和近红外波段。

```julia
imshow(redBand)
title("可见红光波段")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/visible-red-band.png')">

```julia
figure()
imshow(NIR)
title("近红外波段")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/near-infrared-band.png')">

使用 [plot](/Doc/TyPlot/2Dand3DPlots/LinePlots/plot.html) 创建光谱散点图。每个点对应一个像素，其横坐标为可见红光强度，纵坐标为近红外强度。

```julia
figure()
plot(redBand[:], NIR[:], "+b")
xlim([0 1])
ylim([0 1])
axis("square")
xlabel("可见红光强度")
ylabel("近红外强度")
title("近红外与可见红光散点图")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/nir-vs-red-scatter-plot.png')">

散点图对角线附近的像素具有相近的近红外和可见红光强度，通常对应道路、屋顶等表面。位于对角线上方且偏左的像素具有明显更高的近红外反射率，主要对应绿色植被。

## 步骤 3：计算归一化植被指数

归一化植被指数使用近红外与可见红光波段之差，并除以两者之和：

```text
NDVI = (NIR - Red) / (NIR + Red)
```

逐像素执行数组运算。对于两个波段均为零的像素，分母为零，因此将产生的非有限值设置为零。

```julia
ndvi = (NIR - redBand) ./ (NIR + redBand);
ndvi[.!isfinite.(ndvi)] .= 0;
```

`ndvi` 是一个 `Float32` 二维数组，理论取值范围为 [-1, 1]。使用 [imshow](/Doc/TyImageProcessing/DisplayandExploration/BasicDisplay/DisplayImagesandImageSequences/imshow.html) 指定该显示范围。

```julia
figure()
imshow(ndvi, [-1 1])
title("归一化植被指数")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/ndvi.png')">

在 NDVI 图像中，塞纳河等水体显示为深色，而左侧的大面积公园显示为较亮区域。较高的 NDVI 通常表示更茂密、更健康的植被。

## 步骤 4：对 NDVI 图像进行阈值分割

应用简单阈值，选出最可能包含显著植被的像素。

```julia
threshold = 0.4;
vegetationMask = ndvi .> threshold;
```

计算所选像素占图像全部像素的百分比。

```julia
vegetationPercent = 100 * count(identity, vegetationMask) / length(vegetationMask);
println("植被像素比例：", vegetationPercent, "%")
```

```dataframe
植被像素比例：5.2204132080078125%
```

显示二值植被掩膜。白色区域表示 NDVI 高于阈值的像素。

```julia
imshow(vegetationMask)
title("应用阈值后的 NDVI")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/vegetation-mask.png')">

阈值越高，选择的区域越倾向于近红外反射率显著高于可见红光反射率的茂密植被；阈值越低，则会包含更多稀疏植被，同时也可能增加误检。

## 步骤 5：关联光谱信息和空间位置

将超过阈值的像素以绿色叠加到光谱散点图上，并在旁边显示使用相同蓝绿色方案的植被掩膜。这样可以直观看到植被像素的光谱特征及其空间分布。

```julia
figure()

subplot(1, 2, 1)
plot(redBand[:], NIR[:], "+b")
hold("on")
plot(redBand[vegetationMask], NIR[vegetationMask], "g+")
hold("off")
xlim([0 1])
ylim([0 1])
axis("square")
xlabel("可见红光强度")
ylabel("近红外强度")
title("近红外与可见红光散点图")

maskAxes = subplot(1, 2, 2)
imshow(vegetationMask)
colormap(maskAxes, [0 0 1; 0 1 0])
title("应用阈值后的 NDVI")
```

<img :src="$withBase('/TyImageProcessing/Examples/GetStarted/finding-vegetation-in-a-multispectral-image/vegetation-spectral-and-spatial.png')">

散点图中高于 NDVI 阈值的绿色像素集中在其余像素的左上方。这些点对应 CIR 合成图中的红色区域，也对应二值掩膜中的植被区域。通过这种方式，可以把波段之间的光谱差异与图像中的实际空间目标联系起来。

## 另请参阅

[im2single](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConvertBetweenDataTypes/im2single.html) | [imshow](/Doc/TyImageProcessing/DisplayandExploration/BasicDisplay/DisplayImagesandImageSequences/imshow.html) | [plot](/Doc/TyPlot/2Dand3DPlots/LinePlots/plot.html) | [subplot](/Doc/TyPlot/FormattingandAnnotation/AxesAppearance/subplot.html) | [colormap](/Doc/TyPlot/FormattingandAnnotation/Colormaps/colormap.html)
