# 使用经标定的相机测量平面目标
---

<helpButton exampleUrl="/05 Graphics/03 ComputerVison/01_MeasuringPlanarObjectsWithACalibratedCamera.jl">打开示例</helpButton>

此示例说明如何标定单目相机，并使用标定结果以毫米为单位测量平面目标。示例测量两枚硬币的直径以及其中一枚硬币到相机的距离。同样的方法可用于传送带零件的尺寸测量和质量控制。

## 步骤 1：准备标定图像

相机标定用于估计相机内参、镜头畸变和不同标定图像中的相机外参。标定时需要从不同角度拍摄多幅棋盘格图像；标定板应保持平整，并尽量放置在与待测目标相近的工作距离处。

本示例使用 TyComputerVision.jl 中的 9 张 SLR 标定图像。实际应用通常建议拍摄 10 至 20 幅覆盖不同位置和姿态的清晰图像。

```julia
using TyComputerVision
using TyImageProcessing
using TyPlot
using Statistics
using LinearAlgebra

cvdir = pkgdir(TyComputerVision);
files = [
    joinpath(cvdir, "resources", "calibration", "slr", "image$(index).jpg")
    for index in 1:9
];

I = imread(files[1]);
imshow(I)
title("一幅标定图像")
```

<img :src="$withBase('/TyComputerVision/Examples/GetStarted/measuring-planar-objects-with-a-calibrated-camera/calibration-image.png')">

## 步骤 2：估计相机参数

使用 [detectCheckerboardPoints](/Doc/TyComputerVision/CalibrateCameras/detectCheckerboardPoints.html) 检测全部标定图像中的棋盘格角点。然后使用 [patternWorldPoints](/Doc/TyComputerVision/CalibrateCameras/patternWorldPoints.html) 根据棋盘格尺寸和方格边长生成世界坐标。示例中的方格边长为 29 毫米。

```julia
imagePoints, patternDims, imagesUsed = detectCheckerboardPoints(files);

squareSize = 29.0;
worldPoints = patternWorldPoints("checkerboard", patternDims, squareSize);
imageSize = [size(I, 1), size(I, 2)];
```

使用 [estimateCameraParameters](/Doc/TyComputerVision/CalibrateCameras/estimateCameraParameters.html) 估计相机参数。

```julia
cameraParams, imagesUsed, estimationErrors = estimateCameraParameters(
    imagePoints, worldPoints; ImageSize=imageSize, WorldUnits="mm"
);
```

通过每幅图像的平均重投影误差检查标定质量。重投影误差是检测到的角点与对应世界点重新投影到图像后的位置之差。

```julia
errors = cameraParams.ReprojectionErrors;
numViews = size(errors, 3);
meanErrors = [
    mean(sqrt.(sum(errors[:, :, view].^2; dims=2))) for view in 1:numViews
];

figure()
bar(1:numViews, meanErrors)
hold("on")
overallMeanError = mean(meanErrors)
meanLine = plot([0.5, numViews + 0.5], fill(overallMeanError, 2), "r--"; LineWidth=1.5)
legend(meanLine, "总体平均误差: $(round(overallMeanError; digits=4))")
hold("off")
xlabel("图像编号")
ylabel("平均误差（像素）")
title("重投影误差")
```

<img :src="$withBase('/TyComputerVision/Examples/GetStarted/measuring-planar-objects-with-a-calibrated-camera/mean-reprojection-errors.png')">

误差越小，检测到的角点与标定模型越一致。如果误差较大，应检查角点检测结果、方格尺寸以及标定图像的清晰度和姿态覆盖范围。

## 步骤 3：读取待测图像

待测图像必须包含与硬币位于同一平面上的标定板。也可以分别拍摄标定板和目标，但相机必须固定，并且两者必须处于同一测量平面。

```julia
imOrig = imread(files[9]);
figure()
imshow(imOrig)
title("输入图像")
```

<img :src="$withBase('/TyComputerVision/Examples/GetStarted/measuring-planar-objects-with-a-calibrated-camera/measurement-image.png')">

## 步骤 4：校正镜头畸变

使用 [undistortImage](/Doc/TyComputerVision/CalibrateCameras/undistortImage.html) 消除镜头畸变。`OutputView="full"` 保留全部有效像素，因此输出图像边缘可能出现少量黑色区域。函数同时返回与输出图像坐标系对应的新相机内参。

```julia
im, newIntrinsics = undistortImage(
    imOrig, cameraParams; OutputView="full"
);

figure()
imshow(im)
title("去畸变图像")
```

<img :src="$withBase('/TyComputerVision/Examples/GetStarted/measuring-planar-objects-with-a-calibrated-camera/undistorted-image.png')">

即使原图中的畸变不明显，也应在精确测量前执行去畸变。广角镜头和低成本摄像头通常会产生更明显的测量偏差。

## 步骤 5：分割并检测硬币

硬币具有较高的颜色饱和度，而桌面背景接近白色。将图像转换为 HSV 颜色空间，提取饱和度通道并使用 [graythresh](/Doc/TyImageProcessing/Import,Export,andConversion/ImageTypeConversion/ConverttoBinaryImageUsingThresholding/graythresh.html) 计算全局阈值。

```julia
imHSV = rgb2hsv(im);
saturation = imHSV[:, :, 2];
t = graythresh(saturation);
coinMask = saturation .> t;

figure()
imshow(coinMask)
title("分割出的硬币")
```

<img :src="$withBase('/TyComputerVision/Examples/GetStarted/measuring-planar-objects-with-a-calibrated-camera/coin-mask.png')">

使用 [bwconncomp](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/Find,Select,andLabelObjectsinBinaryImages/bwconncomp.html) 查找连通分量，并使用 [regionprops](/Doc/TyImageProcessing/ImageSegmentationandAnalysis/RegionandImageProperties/MeasurePropertiesofImageRegions/regionprops.html) 计算面积和边界框。按照面积降序排列后，保留最大的两个目标。这里移除与图像边界相连的背景区域，避免其被当作面积最大的硬币。

```julia
coinComponents = bwconncomp(imclearborder(coinMask));
stats = regionprops(coinComponents, "Area", "BoundingBox");

areas = [item.Area for item in stats];
order = sortperm(areas; rev=true);
coinIndices = order[1:2];
boxes = vcat([
    reshape(Float64.(stats[index].BoundingBox), 1, 4)
    for index in coinIndices
]...);
```

在去畸变图像上绘制检测到的边界框。

```julia
figure()
imshow(im)
hold("on")
for index in axes(boxes, 1)
    rectangle(position=boxes[index, :], edgecolor="yellow", linewidth=2)
end
hold("off")
title("检测到的硬币")
```

<img :src="$withBase('/TyComputerVision/Examples/GetStarted/measuring-planar-objects-with-a-calibrated-camera/detected-coins.png')">

## 步骤 6：计算相机外参

检测去畸变图像中的棋盘格角点，并使用 [estimateExtrinsics](/Doc/TyComputerVision/CalibrateCameras/estimateExtrinsics.html) 计算从标定板世界坐标系到相机坐标系的刚体变换。因为检测点来自去畸变后的完整视图，所以这里使用 `newIntrinsics`。

```julia
boardImagePoints, measuredPatternDims = detectCheckerboardPoints(im);

if measuredPatternDims != patternDims
    error("待测图像中的棋盘格尺寸与标定图像不一致。")
end

camExtrinsics = estimateExtrinsics(
    Float64.(boardImagePoints), Float64.(worldPoints), newIntrinsics
);
```

使用 [cameraProjection](/Doc/TyComputerVision/CalibrateCameras/cameraProjection.html) 构造 3×4 投影矩阵。由于所有待测点都位于标定板平面 `Z=0` 上，可以从投影矩阵中取得第 1、2、4 列，形成平面单应矩阵，并将图像坐标反算为世界坐标。

```julia
projectionMatrix = cameraProjection(newIntrinsics, camExtrinsics);
planeHomography = projectionMatrix[:, [1, 2, 4]];

function imageToWorldOnPlane(imagePoints, homography)
    points = Float64.(imagePoints);
    imageHomogeneous = hcat(points, ones(size(points, 1)))';
    worldHomogeneous = homography \ imageHomogeneous;
    scales = reshape(worldHomogeneous[3, :], 1, :);
    worldPoints = worldHomogeneous[1:2, :] ./ scales;
    return permutedims(worldPoints)
end
```

## 步骤 7：测量硬币直径

将第一枚硬币边界框的左上角和右上角转换为世界坐标，然后计算两点之间的欧几里得距离。美国一美分硬币的实际直径为 19.05 毫米。

```julia
box1 = boxes[1, :];
imagePoints1 = [
    box1[1]           box1[2]
    box1[1] + box1[3] box1[2]
];

worldPoints1 = imageToWorldOnPlane(imagePoints1, planeHomography);
delta1 = worldPoints1[2, :] - worldPoints1[1, :];
diameter1 = hypot(delta1[1], delta1[2]);
println("第一枚硬币的测量直径：", round(diameter1; digits=2), " mm")
```

```dataframe
第一枚硬币的测量直径：19.0 mm
```

按照相同方法测量第二枚硬币。

```julia
box2 = boxes[2, :];
imagePoints2 = [
    box2[1]           box2[2]
    box2[1] + box2[3] box2[2]
];

worldPoints2 = imageToWorldOnPlane(imagePoints2, planeHomography);
delta2 = worldPoints2[2, :] - worldPoints2[1, :];
diameter2 = hypot(delta2[1], delta2[2]);
println("第二枚硬币的测量直径：", round(diameter2; digits=2), " mm")
```

```dataframe
第二枚硬币的测量直径：18.86 mm
```

参考示例中两次测量的结果约为 19.0 毫米和 18.86 毫米，与硬币的实际尺寸接近。

## 步骤 8：测量硬币到相机的距离

首先将第一枚硬币的图像中心转换为标定板平面上的世界坐标。`estimateExtrinsics` 返回从世界坐标系到相机坐标系的变换，因此相机在世界坐标系中的位置为 `-R' * t`。

```julia
centerImage = reshape(
    [box1[1] + box1[3] / 2, box1[2] + box1[4] / 2], 1, 2
);
centerWorld2D = imageToWorldOnPlane(centerImage, planeHomography);
centerWorld = [centerWorld2D[1, 1], centerWorld2D[1, 2], 0.0];

translation = vec(camExtrinsics.Translation);
cameraLocation = -(camExtrinsics.R' * translation);
distanceToCamera = norm(centerWorld - cameraLocation);

println(
    "第一枚硬币到相机的距离：",
    round(distanceToCamera; digits=2),
    " mm",
)
```

```dataframe
第一枚硬币到相机的距离：719.53 mm
```

参考示例中的测量距离约为 719.52 毫米。测量精度取决于相机标定质量、标定板方格尺寸、目标分割结果，以及目标与标定板是否严格位于同一平面。

## 另请参阅

[detectCheckerboardPoints](/Doc/TyComputerVision/CalibrateCameras/detectCheckerboardPoints.html) | [patternWorldPoints](/Doc/TyComputerVision/CalibrateCameras/patternWorldPoints.html) | [estimateCameraParameters](/Doc/TyComputerVision/CalibrateCameras/estimateCameraParameters.html) | [undistortImage](/Doc/TyComputerVision/CalibrateCameras/undistortImage.html) | [estimateExtrinsics](/Doc/TyComputerVision/CalibrateCameras/estimateExtrinsics.html) | [cameraProjection](/Doc/TyComputerVision/CalibrateCameras/cameraProjection.html)
