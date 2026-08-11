# VideoWriter
---
创建对象以写入视频文件

<h2>函数库: TyImageProcessing</h2>

## 描述

使用 VideoWriter 对象根据数组或 Syslab 影片创建一个视频文件。该对象包含有关视频的信息以及控制输出视频的属性。您可以使用 VideoWriter 函数创建 VideoWriter 对象，指定其属性，然后使用对象函数写入视频。

## 创建对象

### 语法

```
v = VideoWriter(filename,[width height])
v = VideoWriter(filename,[width height],frameRate)
v = VideoWriter(filename,profile)
v = VideoWriter(___;profile) 
```

### 说明

v = VideoWriter([filename](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#d1653645),[[width height]](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#[widthheight]-视频帧宽高尺寸)) 创建一个 VideoWriter 对象以将视频数据写入采用 Motion JPEG 压缩技术的 AVI 文件。[示例](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#x52b42275)

v = VideoWriter([filename](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#d1653645),[[width height]](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#[widthheight]-视频帧宽高尺寸),[frameRate](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#x00e10960)) 还设置视频播放的速率。

v = VideoWriter([filename](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#d1653645),[profile](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#x52c41f60)) 创建一个 VideoWriter 对象并应用一组适合特定文件格式（例如 "MPEG-4" 或 "Motion JPEG AVI"）的属性。视频帧宽高尺寸由后续 writeVideo 写入的第一帧自动确定。

v = VideoWriter(___;[profile](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/VideoWriter.html#x52c41f60)) 还应用一组适合特定文件格式的预定义设置。

### 输入参数

<div id="d1653645" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>filename — 文件名<div>字符串标量</div></summary>
</details>
<div class="details-content">

文件名，指定为字符向量或字符串标量。VideoWriter 创建该文件。

VideoWriter 仅支持 .avi 文件扩展名。

如果未指定有效的文件扩展名，VideoWriter 将追加扩展名 .avi。

**数据类型：** String

  </div>
</div>

<div id="[widthheight]-视频帧宽高尺寸" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>[width height] - 视频帧宽高尺寸<div>1x2 数值矩阵</div></summary>
</details>
<div class="details-content">

视频帧宽高尺寸指定为 1x2 数值矩阵。

**数据类型：** Int64

  </div>
</div>

<div id="x00e10960" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>frameRate — 视频播放的速率<div>30 (默认) | 正数</div></summary>
</details>
<div class="details-content">

视频的播放速率（每秒帧数），指定为正数。

**数据类型：** Real

  </div>
</div>

<div id="x52c41f60" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>profile — 文件类型<div>"Motion JPEG AVI" (默认) | "MPEG-4"</div></summary>
</details>
<div class="details-content">

文件类型，指定为下列值之一。

| profile 的值      | 描述                             |
| ------------------- | -------------------------------- |
| "Motion JPEG AVI" | 使用 Motion JPEG 编码的 AVI 文件 |
| "MPEG-4"          | 使用 H.264 编码的 MPEG-4 文件    |

profile 设置视频属性（例如 VideoCompressionMethod）的默认值。

**数据类型：** String

  </div>
</div>

## 属性

VideoWriter 对象包含控制输出视频的属性。您可以使用 VideoWriter 函数创建一个 VideoWriter 对象。例如，您可以使用 Motion JPEG AVI 描述文件创建一个 VideoWriter 对象并为 Quality 属性赋值。

```julia
v = VideoWriter('newfile.avi',[320 320]);
v.Quality = 95;
```

对 VideoWriter 对象调用 open 函数后，将无法更改属性的值。因此，请在打开视频文件进行写入之前修改属性值。

<div id="ColorChannels—颜色通道数" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ColorChannels — 颜色通道数<div>正整数</div></summary>
</details>
<div class="details-content">

此属性为只读。

每个输出视频帧中的颜色通道数，指定为正整数：

- 未压缩的 AVI、Motion JPEG AVI 和 MPEG-4 文件具有三个颜色通道;

- 索引和灰度 AVI 文件具有一个颜色通道;

- 对于 Motion JPEG 2000 文件，通道数取决于 writeVideo 函数的输入数据：单色数据为一个通道，彩色数据为三个通道。

**数据类型：** Int64

  </div>
</div>

<div id="Duration—输出文件的持续时间" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Duration — 输出文件的持续时间<div>标量值</div></summary>
</details>
<div class="details-content">

此属性为只读。

输出文件的持续时间（以秒为单位），指定为标量值。

**数据类型：** Float64

  </div>
</div>

<div id="Filename—文件名" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Filename — 文件名<div>字符串标量</div></summary>
</details>
<div class="details-content">

此属性为只读。

文件的名称，指定为字符向量或字符串标量。

  </div>
</div>

<div id="FrameCount—帧数" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>FrameCount — 帧数<div>整数</div></summary>
</details>
<div class="details-content">

此属性为只读。

写入视频文件的帧数，指定为整数。

**数据类型：** UInt64

  </div>
</div>

<div id="FrameRate—视频播放的速率" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>FrameRate — 视频播放的速率<div>30 (默认) | 正数</div></summary>
</details>
<div class="details-content">

视频的播放速率（每秒帧数），指定为正数。

调用 open 之后，无法更改 FrameRate 值。

**数据类型：** Real

  </div>
</div>

<div id="Height—每个视频帧的高度" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Height — 每个视频帧的高度<div>标量</div></summary>
</details>
<div class="details-content">

此属性为只读。

每个视频帧的高度（以像素为单位），指定为标量。writeVideo 方法基于第一帧的尺寸设置 Height 和 Width 的值。

**数据类型：** Int64

  </div>
</div>

<div id="Path—视频文件的完整路径" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Path — 视频文件的完整路径<div>字符串标量</div></summary>
</details>
<div class="details-content">

此属性为只读。

视频文件的完整路径，指定为字符向量或字符串标量。

  </div>
</div>

<div id="Quality—视频质量" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Quality — 视频质量<div>75 (默认) | 范围 [0,100] 内的整数</div></summary>
</details>
<div class="details-content">

视频质量，指定为 [0,100] 范围内的整数。数字越大，视频质量越高，文件越大。质量数越小，则视频质量越低且文件大小越小。

调用 open 之后，无法更改 Quality 值。

**数据类型：** Int64

  </div>
</div>

<div id="VideoBitsPerPixel—每像素位数" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>VideoBitsPerPixel — 每像素位数<div>数值标量</div></summary>
</details>
<div class="details-content">

此属性为只读。

每个输出视频帧中每像素的位数，指定为数值标量。

**数据类型：** Int64

  </div>
</div>

<div id="VideoCompressionMethod—视频压缩的类型" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>VideoCompressionMethod — 视频压缩的类型<div>"H.264" | "Motion JPEG" </div></summary>
</details>
<div class="details-content">

此属性为只读。

视频压缩的类型。 

  </div>
</div>

<div id="VideoFormat—视频格式的Syslab表示" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>VideoFormat — 视频格式的 Syslab 表示<div>字符串标量</div></summary>
</details>
<div class="details-content">

此属性为只读。

视频格式的 Syslab 表示形式，指定为字符串标量。

  </div>
</div>

<div id="Width—每个视频帧的宽度" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Width — 每个视频帧的宽度<div>数值标量</div></summary>
</details>
<div class="details-content">

此属性为只读。

每个视频帧的宽度（以像素为单位），指定为数值标量。writeVideo 函数基于第一帧的尺寸设置 Height 和 Width 的值。

**数据类型：** Int64

  </div>
</div>

## 对象函数

| 函数                                                         | 作用                                   |
| ------------------------------------------------------------ | -------------------------------------- |
| [open](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/open.html) | 打开文件以写入视频数据                 |
| [close](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/close.html) | 写入视频数据之后关闭文件               |
| [writeVideo](/Doc/TyImageProcessing/DataImportandAnalysis/DataImportandExport/StandardFileFormats/AudioandVideoData/ReadorWriteVideo/writeVideo.html) | 将视频数据写入到文件                   |

## 示例

<div id="x52b42275" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>创建 VideoWriter 对象并编写视频</summary>
</details>
<div class="details-content">

按以下步骤将视频写入文件：创建一个随机数据数组，为输出文件创建 VideoWriter 对象，然后将该数组写入视频。

创建一个 300×300 的数据矩阵。

```julia
using TyImageProcessing

A = rand(Float64, 300, 300);
```

创建一个 VideoWriter 对象以写入名为 newfile.avi 的文件，然后打开该对象以进行写入。

```julia
v = VideoWriter("newfile.avi", [size(A, 1) size(A, 2)]);
open(v)
```

将数据矩阵 A 写入视频文件。

```julia
writeVideo(v, A)
```

关闭 VideoWriter 对象。

```julia
close(v)
```

  </div>
</div>

<div id="为未压缩的AVI指定描述文件并写入视频" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>为未压缩的 AVI 指定描述文件并写入视频</summary>
</details>
<div class="details-content">

使用指定的描述文件创建一个视频对象，创建包含一个 RGB 图像的数组，然后将该数组写入视频文件。

为 RGB24 视频的新的未压缩 AVI 文件创建一个 VideoWriter 对象。

```julia
using TyImageProcessing

v = VideoWriter("newfile.avi",[512 384]);
```

打开要写入的文件。

```julia
open(v)
```

创建一个包含来自示例静态图像 peppers.png 的数据的数组。将 A 中的图像写入视频文件。

```julia
A = imread("peppers.png");
writeVideo(v, A)
```

关闭 VideoWriter 对象。

```julia
close(v)
```

  </div>
</div>
