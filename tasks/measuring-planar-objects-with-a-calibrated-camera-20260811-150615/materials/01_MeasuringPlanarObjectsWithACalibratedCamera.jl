# 使用经标定的相机测量平面目标

# 加载计算机视觉、图像处理、绘图和数值计算工具
using TyComputerVision
using TyImageProcessing
using TyPlot
using Statistics
using LinearAlgebra

# 读取相机标定所需的棋盘格图像
cvdir = pkgdir(TyComputerVision);
files = [
    joinpath(cvdir, "resources", "calibration", "slr", "image$(index).jpg")
    for index in 1:9
];

I = imread(files[1]);
imshow(I)
title("一幅标定图像")
 
# 检测棋盘格角点，并生成对应的世界坐标
imagePoints, patternDims, imagesUsed = detectCheckerboardPoints(files);

squareSize = 29.0;
worldPoints = patternWorldPoints("checkerboard", patternDims, squareSize);
imageSize = [size(I, 1), size(I, 2)];
 
# 根据图像点和世界点估计相机参数
cameraParams, imagesUsed, estimationErrors = estimateCameraParameters(
    imagePoints, worldPoints; ImageSize=imageSize, WorldUnits="mm"
);
 
# 计算每幅标定图像的平均重投影误差
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

 
# 读取包含待测硬币和棋盘格的图像
imOrig = imread(files[9]);
figure()
imshow(imOrig)
title("输入图像")


 
# 使用标定结果校正镜头畸变
im, newIntrinsics = undistortImage(
    imOrig, cameraParams; OutputView="full"
);

figure()
imshow(im)
title("去畸变图像")

 
# 根据 HSV 饱和度分割硬币区域
imHSV = rgb2hsv(im);
saturation = imHSV[:, :, 2];
t = graythresh(saturation);
coinMask = saturation .> t;

figure()
imshow(coinMask)
title("分割出的硬币")


 
# 移除与图像边界相连的背景区域，避免其被当作面积最大的硬币。
# 移除边界区域，并保留面积最大的两个连通区域
coinComponents = bwconncomp(imclearborder(coinMask));
stats = regionprops(coinComponents, "Area", "BoundingBox");

areas = [item.Area for item in stats];
order = sortperm(areas; rev=true);
coinIndices = order[1:2];
boxes = vcat([
    reshape(Float64.(stats[index].BoundingBox), 1, 4)
    for index in coinIndices
]...);


 
# 在图像中绘制检测到的硬币边界框
figure()
imshow(im)
hold("on")
for index in axes(boxes, 1)
    rectangle(position=boxes[index, :], edgecolor="yellow", linewidth=2)
end
hold("off")
title("检测到的硬币")

 
# 检测测量图像中的棋盘格，并估计相机外参
boardImagePoints, measuredPatternDims = detectCheckerboardPoints(im);

if measuredPatternDims != patternDims
    error("待测图像中的棋盘格尺寸与标定图像不一致。")
end

camExtrinsics = estimateExtrinsics(
    Float64.(boardImagePoints), Float64.(worldPoints), newIntrinsics
);

 
# 构造平面单应矩阵，将图像坐标转换为世界坐标
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
 
# 测量第一枚硬币的直径
box1 = boxes[1, :];
imagePoints1 = [
    box1[1]           box1[2]
    box1[1] + box1[3] box1[2]
];

worldPoints1 = imageToWorldOnPlane(imagePoints1, planeHomography);
delta1 = worldPoints1[2, :] - worldPoints1[1, :];
diameter1 = hypot(delta1[1], delta1[2]);
println("第一枚硬币的测量直径：", round(diameter1; digits=2), " mm")

 
# 测量第二枚硬币的直径
box2 = boxes[2, :];
imagePoints2 = [
    box2[1]           box2[2]
    box2[1] + box2[3] box2[2]
];

worldPoints2 = imageToWorldOnPlane(imagePoints2, planeHomography);
delta2 = worldPoints2[2, :] - worldPoints2[1, :];
diameter2 = hypot(delta2[1], delta2[2]);
println("第二枚硬币的测量直径：", round(diameter2; digits=2), " mm")

 
# 计算第一枚硬币到相机的空间距离
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
