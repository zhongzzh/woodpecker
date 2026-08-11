# 在多光谱图像中查找植被

using TyImageProcessing
using TyPlot

# 读取 7 波段 BIL 格式的巴黎多光谱图像
rows, cols, bands = 512, 512, 7;
rawData = open(joinpath(@__DIR__, "paris.lan"), "r") do io
    seek(io, 128)
    read(io, rows * cols * bands)
end;

bilData = reshape(rawData, cols, bands, rows);
multispectral = permutedims(bilData, (3, 1, 2));

# 使用近红外、红光和绿光波段构建彩色红外合成图像
CIR = multispectral[:, :, [4, 3, 2]];
figure();
imshow(CIR)
title("CIR 合成图")

# 分别提取近红外和可见红光波段，并转换为单精度浮点数
NIR = im2single(CIR[:, :, 1]);
redBand = im2single(CIR[:, :, 2]);

figure();
imshow(redBand)
title("可见红光波段")

figure();
imshow(NIR)
title("近红外波段")

# 绘制近红外强度与可见红光强度的散点图
figure();
plot(redBand[:], NIR[:], "+b")
xlim([0, 1])
ylim([0, 1])
axis("square")
xlabel("可见红光强度")
ylabel("近红外强度")
title("近红外与可见红光散点图")

# 计算归一化植被指数（NDVI）
ndvi = (NIR - redBand) ./ (NIR + redBand);
ndvi[.!isfinite.(ndvi)] .= 0;

figure();
imshow(ndvi, [-1, 1])
title("归一化植被指数")

# 依据 NDVI 阈值创建植被掩膜并输出植被比例
threshold = 0.4;
vegetationMask = ndvi .> threshold;
vegetationPercent = 100 * count(identity, vegetationMask) / length(vegetationMask);
println("植被像素比例：", vegetationPercent, "%")

figure();
imshow(vegetationMask)
title("应用阈值后的 NDVI")

# 在散点图中高亮植被像素，并显示掩膜
figure();
subplot(1, 2, 1)
plot(redBand[:], NIR[:], "+b")
hold("on")
plot(redBand[vegetationMask], NIR[vegetationMask], "g+")
hold("off")
xlim([0, 1])
ylim([0, 1])
axis("square")
xlabel("可见红光强度")
ylabel("近红外强度")
title("近红外与可见红光散点图")

maskAxes = subplot(1, 2, 2);
imshow(vegetationMask)
colormap(maskAxes, [0 0 1; 0 1 0])
title("应用阈值后的 NDVI")
