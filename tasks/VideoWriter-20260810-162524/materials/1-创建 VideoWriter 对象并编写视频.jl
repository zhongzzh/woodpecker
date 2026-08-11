# 创建 VideoWriter 对象并编写视频

using TyImageProcessing

A = rand(Float64, 300, 300);

v = VideoWriter("newfile.avi", [size(A, 1) size(A, 2)]);
open(v)

writeVideo(v, A)

close(v)
