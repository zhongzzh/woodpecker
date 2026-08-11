# 分割并测量米粒

using TyImageProcessing
using TyPlot

path = normpath(@__DIR__, "..", "..", "00 Resources")

# 读取并显示原始米粒图像
I = imread(joinpath(path, "rice.png"));
figure();
imshow(I)

# 使用形态学开运算估计图像背景
se = strel("disk", 15);
background = imopen(I, se);
figure();
imshow(background)

# 去除背景、增强对比度，并进行二值化
I2 = imsubtract(I, background);
I3 = imadjust(I2);
bw = imbinarize(I3);
bw = bwareaopen(bw, 50);
figure();
imshow(bw)

# 标记连通区域并报告米粒总数
cc = bwconncomp(bw, 4);
println("目标数量：", cc.NumObjects)

# 提取并显示第 50 个米粒
grain = falses(size(bw));
grain[Int64.(cc.PixelIdxList[50])] .= true;
figure();
imshow(grain)

# 对所有米粒着色并计算其面积
labeled = labelmatrix(cc);
RGBLabel = label2rgb(labeled, TyPlot.spring(cc.NumObjects), "c", "shuffle");
figure();
imshow(RGBLabel)

grainData = regionprops(cc, "basic");
grainAreas = [item.Area for item in grainData];
println("第 50 个目标的面积：", grainAreas[50])

# 查找、显示面积最小的米粒，并绘制面积分布直方图
minArea, idx = findmin(grainAreas);
println("最小面积：", minArea)

smallestGrain = falses(size(bw));
smallestGrain[Int64.(cc.PixelIdxList[idx])] .= true;
figure();
imshow(smallestGrain)

figure();
histogram(grainAreas)
title("米粒面积直方图")
