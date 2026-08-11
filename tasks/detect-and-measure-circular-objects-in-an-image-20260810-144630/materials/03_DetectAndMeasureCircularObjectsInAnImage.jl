# 检测并测量图像中的圆形物体

using TyImageProcessing
using TyPlot

path = normpath(@__DIR__, "..", "..", "00 Resources")

# 读取并显示彩色圆片图像
rgb = imread(joinpath(path, "coloredChips.png"));
figure();
imshow(rgb)

# 转换为灰度图像，便于观察圆形边缘
grayImage = im2gray(rgb);
figure();
imshow(grayImage)

# 根据圆片的近似尺寸检测暗圆形
radiusRange = [20, 30];
centersDark, radiiDark = imfindcircles(
    rgb, radiusRange; ObjectPolarity="dark", Sensitivity=0.94
);

# 在原图上叠加暗圆形的检测结果
figure();
imshow(rgb)
viscircles(centersDark, radiiDark; Color="r")

# 检测亮圆形并以蓝色叠加显示
centersBright, radiiBright = imfindcircles(
    rgb, radiusRange; ObjectPolarity="bright", Sensitivity=0.95
);

figure();
imshow(rgb)
viscircles(centersDark, radiiDark; Color="r")
viscircles(centersBright, radiiBright; Color="b")
