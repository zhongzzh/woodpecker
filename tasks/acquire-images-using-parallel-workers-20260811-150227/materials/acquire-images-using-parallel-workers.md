# 使用并行工作进程采集图像
---

<helpButton exampleUrl="/05 Graphics/05 ImageAcquisition/AcquireImagesUsingParallelWorkers.jl">打开示例</helpButton>

此示例说明如何结合 Julia 的分布式计算功能与图像采集工具箱，在独立工作进程中采集并保存图像。这样可以减小采集任务对主进程的影响，使主进程能够同时执行其他计算，并有助于保持连续采集过程的稳定性。

:::tip 硬件和软件要求
运行此示例需要一台可用的 USB 摄像头，并需要安装 TyImageAcquisition 和 TyImageProcessing；Distributed 随 Julia 一同提供。示例使用设备编号 `0`；如果计算机连接了多台摄像头，请先使用 [cameralist](/Doc/TyImageAcquisition/DeviceConnection/cameralist.html) 查看设备列表并调整编号。
:::

## 设置图像采集

加载 `Distributed`，添加一个本地工作进程。`addprocs` 返回新增工作进程的 ID，后续使用该 ID 指定图像采集任务的运行位置。

```julia
using Distributed

worker_ids = addprocs(1)
worker_id = only(worker_ids)
```

在所有进程中加载图像采集和图像处理工具箱，然后定义 `capture_video` 函数。该函数在执行它的工作进程中创建 [videoinput](/Doc/TyImageAcquisition/CreatingCustomAdaptors/videoinput.html) 对象，采集指定数量的图像帧，并依次将各帧写入输出文件夹。

```julia
@everywhere begin
    using TyImageAcquisition
    using TyImageProcessing

    function capture_video(device_id, frame_count, output_dir)
        mkpath(output_dir)
        video = videoinput("USB", device_id)
        video.FramesPerTrigger = frame_count
        start(video)

        try
            frames, timestamps = getdata(video, frame_count)
            frame_dimension = ndims(frames) == 4 ? 4 : 3

            for index in axes(frames, frame_dimension)
                frame = copy(selectdim(frames, frame_dimension, index))
                filename = joinpath(output_dir, "img_$(lpad(string(index), 4, '0')).png")
                imwrite(frame, filename)
            end

            return (frame_count=length(timestamps), timestamps=timestamps)
        finally
            stop(video)
        end
    end
end
```

视频输入对象包含摄像头连接状态等进程本地资源，因此应当在工作进程内创建、使用和关闭，而不要先在主进程中创建对象再将其传递给工作进程。

## 在工作进程上启动采集

在当前工作目录中准备 `data` 文件夹。使用 `remotecall` 将采集任务异步提交到指定工作进程。该调用会立即返回一个 `Future` 对象，主进程不必等待采集完成。

```julia
output_dir = abspath("data")
future = remotecall(capture_video, worker_id, 0, 120, output_dir)
```

此时可在主进程中执行其他工作。例如，下面的计算与摄像头采集同时进行。

```julia
main_result = sum(abs2, 1:1_000_000)
println("主进程计算结果：", main_result)
```

调用 `isready` 可以非阻塞地检查采集任务是否已经完成。

```julia
isready(future)
```

## 等待采集完成

如果后续操作依赖采集结果，请调用 `fetch`。该函数会等待工作进程完成任务，并返回采集的帧数和相对时间戳。

```julia
result = fetch(future)
println("已保存帧数：", result.frame_count)
println("相对时间戳：", result.timestamps)
```

采集的图像按 `img_0001.png`、`img_0002.png` 等名称保存在当前工作目录的 `data` 文件夹中。

## 关闭工作进程

完成采集后，移除本示例添加的工作进程并释放相应资源。

```julia
rmprocs(worker_ids)
```

如果采集过程中发生错误，`fetch(future)` 会在主进程中报告远程异常；`capture_video` 中的 `finally` 代码块仍会调用 [stop](/Doc/TyImageAcquisition/ImageDataAcquisition/AcquisitionUsingAnyHardware/stop.html) 释放摄像头。

## 另请参阅

[videoinput](/Doc/TyImageAcquisition/CreatingCustomAdaptors/videoinput.html) | [cameralist](/Doc/TyImageAcquisition/DeviceConnection/cameralist.html) | [start](/Doc/TyImageAcquisition/ImageDataAcquisition/AcquisitionUsingAnyHardware/start.html) | [getdata](/Doc/TyImageAcquisition/ImageDataAcquisition/AcquisitionUsingAnyHardware/getdata.html) | [stop](/Doc/TyImageAcquisition/ImageDataAcquisition/AcquisitionUsingAnyHardware/stop.html) | [addprocs](/Doc/ParallelComputing/APIUsage/Single-MachineMulti-ProcessComputing/addprocs.html) | [Future](/Doc/ParallelComputing/APIUsage/DistributedComputing/Future.html) | [remotecall](/Doc/ParallelComputing/APIUsage/DistributedComputing/remotecall.html)
