# writeVideo
---
将视频数据写入到文件

<h2>函数库: TyImageProcessing</h2>

## 语法

```
writeVideo(v,img)
```

## 说明

writeVideo([v](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/writeVideo.html#fa637a1c),[img](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/writeVideo.html#x7e142e7b)) 将数据从数组写入与 v 相关联的视频文件。

必须先调用 open(v)，然后再调用 writeVideo。

## 示例

<div id="将图像写入MotionJPEG2000文件" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>将图像写入 Motion JPEG 2000 文件</summary>
</details>
<div class="details-content">

将一个 RGB 图像写入采用无损压缩的 Motion JPEG 2000 文件。

创建一个包含来自示例静态图像 peppers.png 的数据的数组。

```julia
using TyImageProcessing

A = imread("peppers.png");
```

为新视频文件创建一个 VideoWriter 对象。

```julia
v = VideoWriter("myFile", [size(A, 2) size(A, 1)]);
```

验证新文件的视频压缩类型。

```julia
v.VideoCompressionMethod
```

```dataframe
ans = 
"Motion JPEG"
```

打开 VideoWriter 对象进行写入，并将 A 中的图像数据写入文件。

```julia
open(v)
writeVideo(v, A)
```

关闭 VideoWriter 对象。

```julia
close(v)
```

  </div>
</div>

<div id="将MPEG-4转换为AVI文件" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>将 MPEG-4 转换为 AVI 文件</summary>
</details>
<div class="details-content">

创建要读取的对象并写入一个示例视频，然后打开 AVI 文件进行写入。

```julia
using TyImageProcessing
using TyBase

pkg_dir = pkgdir(TyImageProcessing)
source_path = pkg_dir * "/resources/xylophone_video.mp4"
reader = VideoReader(source_path);
writer = VideoWriter("transcoded_xylophone.avi", [reader.Width reader.Height]);

writer.FrameRate = reader.FrameRate;
open(writer);
```

读取和写入每一帧。

```julia
while hasFrame(reader)
    local img = readFrame(reader)
    writeVideo(writer, img)
end
```

清除 VideoReader 对象并关闭 VideoWriter 对象。

```julia
clear(:reader)
close(writer)
```

  </div>
</div>

## 输入参数

<div id="fa637a1c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>v — 输入 VideoWriter 对象<div>VideoWriter 对象</div></summary>
</details>
<div class="details-content">

输入 VideoWriter 对象。使用 [VideoWriter](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html) 创建该对象。

  </div>
</div>

<div id="x7e142e7b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>img — 表示灰度或 RGB 彩色图像的值<div>二维数组 | 三维数组 | 四维数组</div></summary>
</details>
<div class="details-content">

表示灰度或 RGB 彩色图像的值，指定为二维、三维或四维数组：

- 对于单一灰度图像、单色图像或索引图像，img 必须是二维的：高×宽；

- 对于单一真彩色 (RGB) 图像，img 是三维的：高×宽×3；

- 对于一系列灰度图像，img 是四维的：高×宽×1×帧数。文件中所有帧的高和宽必须一致；

- 对于一系列 RGB 图像，img 是四维的：高×宽×3×帧数。文件中所有帧的高和宽必须一致。

创建 AVI 文件时：

- img 是 Float32、Float64 或 uint8 值的数组，代表一个或多个灰度或 RGB 彩色图像，writeVideo 将这些图像作为一个或多个 RGB 视频帧写入；

- Float32 或 Float64 类型的数据必须位于范围 [0,1] 中，写入索引 AVI 文件时除外。

创建 Motion JPEG 2000 文件时：

- img 是 UInt8、Int8、UInt16 或 Int16 值的数组，表示一个或多个单色或 RGB 彩色图像。

**数据类型：** Float32 | Float64 | Int16 | UInt8 | UInt16

  </div>
</div>