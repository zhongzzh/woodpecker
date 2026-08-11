<MLangFuncTag></MLangFuncTag>

# writeVideo
---
将视频数据写入到文件

## 语法
```matlab
writeVideo(v, img)
writeVideo(v, frame)(暂不支持)
```

## 说明
writeVideo([v](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/writeVideo.html#v-inputvideowriterobject), [img](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/writeVideo.html#img-imagedata)) 将数据从数组写入与 v 相关联的视频文件。必须先调用 open(v)，然后再调用 writeVideo。

<!-- writeVideo([v](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/writeVideo.html#v-inputvideowriterobject), [frame](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/writeVideo.html#frame-framedata)) 写入通常由 getframe 函数返回的一个或多个影片帧。[示例](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/writeVideo.html#createavifilefromanimation) -->

## 示例

<div id="writeimagetomotionjpeg2000file" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>将图像写入 Motion JPEG 2000 文件</summary>
</details>
<div class="details-content">
将 RGB 图像写入无损压缩的 Motion JPEG 2000 文件：
创建一个包含来自示例静态图像 peppers.png 的数据的数组。

```matlab
A = imread('peppers.png');
```
为新视频文件创建一个 VideoWriter 对象。使用 'Archival' 描述文件指定一个采用无损压缩的 Motion JPEG 2000 文件。
```matlab
v = VideoWriter('myFile',[size(A,2) size(A,1)]);
```
验证压缩类型
```matlab
v.VideoCompressionMethod 
```
```dataframe
ans = 
'Motion JPEG 2000'

打开要写入的视频文件。然后，将 A 中的图像数据写入该文件。
```
```matlab
open(v);
writeVideo(v, A);
```
关闭视频文件。
```matlab
close(v);
```
</div>
</div>


<div id="convertmpeg4toavifile" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>将 MPEG-4 转换为 AVI 文件</summary>
</details>
<div class="details-content">
将示例文件 xylophone.mp4 转换为未压缩的 AVI 文件。

创建要读取的对象并写入视频，然后打开 AVI 文件进行写入。

```matlab
reader = VideoReader('xylophone.mp4');
writer = VideoWriter('transcoded_xylophone.avi', [reader.Width reader.Height],...
                        'Uncompressed AVI');

writer.FrameRate = reader.FrameRate;
open(writer);
```
读取和写入每一帧。

```matlab
while hasFrame(reader)
    img = readFrame(reader);
    writeVideo(writer,img);
end

close(writer);
```



</div>
</div>

<!-- 
<div id="createavifilefromanimation" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>从动画创建 AVI 文件</summary>
</details>
<div class="details-content">

按以下步骤将一组帧写入压缩的 AVI 文件：生成一组帧，为要写入的文件创建视频对象，然后将帧写入视频文件。

设置坐标区和图窗属性，以生成视频帧。

```matlab
Z = peaks;
surf(Z); 
axis tight manual 
set(gca,'nextplot','replacechildren'); 
```
为输出视频文件创建 VideoWriter 对象并打开该对象以进行写入。

```matlab
v = VideoWriter('peaks.avi');
open(v);
```
生成一组帧，从图窗中获取帧，然后将每一帧写入文件。

```matlab
for k = 1:20 
   surf(sin(2*pi*k/20)*Z,Z)
   frame = getframe(gcf);
   writeVideo(v,frame);
end
```
close(v);

</div>
</div> -->

## 输入参数

<div id="v-inputvideowriterobject" class="jump-target"></div>
<div class="details-box">
<details open>
<summary><strong>v</strong> - 输入 VideoWriter 对象<div>VideoWriter 对象</div></summary>
</details>
<div class="details-content">
使用 VideoWriter 创建该对象。
</div>
</div>

<div id="img-imagedata" class="jump-target"></div>
<div class="details-box">
<details open>
<summary><strong>img</strong> - 表示灰度或 RGB 彩色图像的值<div>二维数组 | 三维数组 | 四维数组</div></summary>
</details>
<div class="details-content">

表示灰度或 RGB 彩色图像的值，指定为二维、三维或四维数组：

* 对于单一灰度图像、单色图像或索引图像，img 必须是二维的：高×宽；

* 对于单一真彩色 (RGB) 图像，img 是三维的：高×宽×3；

* 对于一系列灰度图像，img 是四维的：高×宽×1×帧数。文件中所有帧的高和宽必须一致；

* 对于一系列 RGB 图像，img 是四维的：高×宽×3×帧数。文件中所有帧的高和宽必须一致；

创建 AVI 时：

* img 是 single、double 或 uint8 值的数组，代表一个或多个灰度或 RGB 彩色图像，writeVideo 将这些图像作为一个或多个 RGB 视频帧写入；

* single 或 double 类型的数据必须位于范围 [0,1] 中，写入索引 AVI 文件时除外；

创建 Motion JPEG 2000 文件时：

* img 是 uint8、int8、uint16 或 int16 值的数组，表示一个或多个单色或 RGB 彩色图像。


<strong>数据类型</strong>： single | double | int8 | int16 | uint8 | uint16

</div>
</div>

<!-- <div id="frame-framedata" class="jump-target"></div>
<div class="details-box">
<details open>
<summary><strong>frame</strong> - 帧数据<div>1×1 结构体数组 | 1×F 结构体数组</div></summary>
</details>
<div class="details-content">

帧数据，指定为表示单个帧的 1×1 结构体数组，或表示多个帧的 1×F 结构体数组。每个帧都包含两个字段：cdata 和 colormap。frame 数组通常由 getframe 函数返回。

如果 colormap 不为空，则 cdata 的每个元素应为二维（高×宽）数组。文件中所有帧的高和宽必须一致。

colormap 最多可包含 256 个条目。colormap 的每个元素必须在 [0,1] 范围内。

当您创建一个 VideoWriter 对象时，profile 输入和 cdata 的大小确定 writeVideo 如何使用 frame。

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; width: 100%;">
  <thead>
    <tr style="background-color: #f0f0f0;">
      <th>VideoWriter 对象的 profile</th>
      <th>cdata 的每个元素的大小</th>
      <th>writeVideo 的行为</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>'Indexed AVI'</td>
      <td>二维（高×宽）</td>
      <td>使用所提供的帧。</td>
    </tr>
    <tr>
      <td>'Grayscale AVI'</td>
      <td>二维（高×宽）</td>
      <td>使用所提供的帧。colormap 应为空。</td>
    </tr>
    <tr>
      <td rowspan="2">所有其他描述文件</td>
      <td>二维（高×宽）</td>
      <td>使用 colormap 字段构造 RGB 图像帧</td>
    </tr>
    <tr>
      <td>三维（高×宽×3）</td>
      <td>忽略 colormap 字段。使用 cdata 字段构造 RGB 图像帧</td>
    </tr>
  </tbody>
</table>
<strong>数据类型</strong>： struct
</div>
</div> -->


## 另请参阅 
[close](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/close.html) | 
<!-- [getframe](/Doc/TyImageProcessing/Graphics/2-Dand3-DPlots/Animation/getframe.html) |  -->
[open](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/open.html) | 
[VideoWriter](/Doc/MultiLanguage/TyMLang/Functions/DataImportandAnalysis/DataImportandExport/VideoWriter.html)