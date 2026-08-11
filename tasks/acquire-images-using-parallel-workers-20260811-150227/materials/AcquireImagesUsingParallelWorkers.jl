# 使用并行工作进程采集并保存图像

# 加载 Julia 分布式计算功能，并启动一个本地工作进程
using Distributed

worker_ids = addprocs(1)
worker_id = only(worker_ids)

# 在所有进程上加载采集工具，并定义图像采集函数
@everywhere begin
    using TyImageAcquisition
    using TyImageProcessing

    function capture_video(device_id, frame_count, output_dir)
        # 创建输出目录并连接指定的 USB 摄像头
        mkpath(output_dir)
        video = videoinput("USB", device_id)
        video.FramesPerTrigger = frame_count
        start(video)

        try
            # 采集指定数量的图像帧及其时间戳
            frames, timestamps = getdata(video, frame_count)
            frame_dimension = ndims(frames) == 4 ? 4 : 3

            # 逐帧提取图像，并按顺序保存为 PNG 文件
            for index in axes(frames, frame_dimension)
                frame = copy(selectdim(frames, frame_dimension, index))
                filename = joinpath(output_dir, "img_$(lpad(string(index), 4, '0')).png")
                imwrite(frame, filename)
            end

            return (frame_count=length(timestamps), timestamps=timestamps)
        finally
            # 无论采集是否成功，都确保停止摄像头
            stop(video)
        end
    end
end

# 在工作进程中异步启动图像采集任务
output_dir = abspath("data")
future = remotecall(capture_video, worker_id, 0, 120, output_dir)

# 主进程可在采集期间继续执行其他计算
main_result = sum(abs2, 1:1_000_000)
println("主进程计算结果：", main_result)

isready(future)

# 等待采集完成并输出采集结果
result = fetch(future)
println("已保存帧数：", result.frame_count)
println("相对时间戳：", result.timestamps)

# 关闭本示例创建的工作进程
rmprocs(worker_ids)
