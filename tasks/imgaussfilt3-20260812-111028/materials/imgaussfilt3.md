# imgaussfilt3
---
三维图像的三维高斯滤波

<h2>函数库: TyImageProcessing</h2>

## 语法

```julia
B = imgaussfilt3(A)
B = imgaussfilt3(A,sigma)
B = imgaussfilt3(___;Name=Value)
```

## 说明

[B](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x1e5f8a3b) = imgaussfilt3([A](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x2a7b9c4d)) 使用标准差为 0.5 的三维高斯平滑核对三维图像 A 进行滤波，并在 B 中返回滤波后的图像。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x3c8d0e1f)

***
[B](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x1e5f8a3b) = imgaussfilt3([A](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x2a7b9c4d),[sigma](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x4d9e0f1a)) 使用由 sigma 指定标准差的三维高斯平滑核对三维图像 A 进行滤波。

***
[B](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x1e5f8a3b) = imgaussfilt3(___;[Name=Value](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x8a1b2c3d)) 使用名称-值参量来控制滤波的各个方面。[示例](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x3c8d0e1f)

## 示例

<div id="x3c8d0e1f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用三维高斯滤波器对磁共振成像（MRI）体数据进行平滑处理</summary>
</details>
<div class="details-content">

加载 MRI 数据并显示。

```julia
using TyImageProcessing
using TyPlot
using TyBase

vol = load(pkgdir(TyImageProcessing) * "/resources/mri.mat");
figure()
montage(vol["D"])
title("Original image volume")
```

<img :src="$withBase('/TyImageProcessing/Images/imgaussfilt3/example1/imageVolume.png')">

用三维高斯滤波器对图像进行平滑处理。

```julia
siz = Int.(vol["siz"]);
vol = squeeze(vol["D"]);
sigma = 2;

volSmooth = imgaussfilt3(vol, sigma);

figure()
montage(reshape(volSmooth, siz[1], siz[2], 1, siz[3]))
title("Gaussian filtered image volume")
```

<img :src="$withBase('/TyImageProcessing/Images/imgaussfilt3/example1/GaussianFiltered.png')">

  </div>
</div>


## 输入参数

<div id="x2a7b9c4d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>A — 要滤波的图像<div>三维数值数组</div></summary>
</details>
<div class="details-content">

要滤波的图像，指定为三维数值数组。

**数据类型：** UInt8 | UInt16 | UInt32 | Int8 | Int16 | Int32 | Float32 | Float64

  </div>
</div>

<div id="x4d9e0f1a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sigma — 高斯分布的标准差<div>0.5 (默认) | 正数 | 由正数组成的三元向量</div></summary>
</details>
<div class="details-content">

高斯分布的标准差，指定为正数或由正数组成的三元向量。如果 sigma 是标量，则 imgaussfilt3 使用立方高斯核。

  </div>
</div>

## 名称-值参数

<span id="x8a1b2c3d" class="jump-target"></span>

将可选参量对组指定为 Name1=Value1,...,NameN=ValueN，其中 Name 是参量名称，Value 是对应的值。名称-值参量必须出现在其他参量之后，但对各个参量对组的顺序没有要求。

**示例：** volSmooth = imgaussfilt3(vol, sigma; Padding="circular") 指定圆形填充。

<div id="x5a0b1c2d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>FilterSize — 高斯滤波器的大小<div>正奇数 | 由正奇数组成的三元向量</div></summary>
</details>
<div class="details-content">

高斯滤波器的大小，指定为正奇数或由正奇数组成的三元向量。默认滤波器大小为 2 * ceil(2 * [sigma](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x4d9e0f1a)) .+ 1。

如果指定标量，则 imgaussfilt3 使用立方滤波器。

  </div>
</div>

<div id="x6b1c2d3e" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Padding — 图像填充<div>"replicate" (默认) | 数值标量 | "circular" | "symmetric"</div></summary>
</details>
<div class="details-content">

图像填充，指定为下表中的值之一。

| 值               | 描述                                                         | 示例                                                         |
| ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 数值标量，`X`    | 数组边界之外的输入数组值被赋予值 `X`。                       | <img :src="$withBase('/TyImageProcessing/Images/imgaussfilt3/Padding/X.png')">  显示使用值 2 的填充。 |
| `"symmetric" `   | 数组边界之外的输入数组值是通过沿数组边界对数组进行镜面反射得到。 | <img :src="$withBase('/TyImageProcessing/Images/imgaussfilt3/Padding/symmetric.png')"> |
| `"replicate"`    | 数组边界之外的输入数组值假定为等于最近的数组边界值。         | <img :src="$withBase('/TyImageProcessing/Images/imgaussfilt3/Padding/replicate.png')"> |
| `"circular"`    | 数组边界之外的输入数组值是通过隐式假设输入数组具有周期性来计算的。 | <img :src="$withBase('/TyImageProcessing/Images/imgaussfilt3/Padding/circular.png')"> |

**数据类型：** String | Float64

  </div>
</div>

<div id="x7c2d3e4f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>FilterDomain — 执行滤波的域<div>"auto" (默认) | "spatial" | "frequency"</div></summary>
</details>
<div class="details-content">

在空间域还是频率域执行滤波，指定为下列值之一。

| 值            | 说明                                                         |
| ------------- | ------------------------------------------------------------ |
| `"auto"`      | 使用内部启发式算法确定空间域和频率域哪个更快。              |
| `"spatial"`   | 使用空间域滤波。                                             |
| `"frequency"` | 使用频率域滤波。                                             |



  </div>
</div>

## 输出参数

<div id="x1e5f8a3b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>B — 滤波后的图像<div>数值数组</div></summary>
</details>
<div class="details-content">

滤波后的图像，以与输入图像 [A](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x2a7b9c4d) 大小和类相同的数值数组形式返回。

  </div>
</div>

## 提示

- 如果图像 [A](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x2a7b9c4d) 包含 Inf 或 NaN，则频域滤波的 imgaussfilt3 的行为会是未定义状态。如果将 [FilterDomain](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x7c2d3e4f) 参量设置为 "frequency"，或将其设置为 "auto" 并且 imgaussfilt3 使用频域滤波，就会发生这种情况。要以类似于 [imfilter](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imfilter.html) 的方式限制输出中 Inf 和 NaN 的传播，请考虑将 FilterDomain 参量设置为 "spatial"。

- 如果将 FilterDomain 参量设置为 "auto"，则 imgaussfilt3 使用内部启发式方法来确定是空间域更快还是频域滤波更快。这种启发式方法依赖于机器，可能因不同配置而异。为了获得最优性能，请尝试两个选项 "spatial" 和 "frequency"，以确定适合您的图像和核大小的最佳滤波域。

- 如果未指定 [Padding](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt3.html#x6b1c2d3e) 参量，则 imgaussfilt3 默认使用 "replicate" 填充，这与 [imfilter](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imfilter.html) 使用的默认填充不同。

## 另请参阅

[imgaussfilt](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imgaussfilt.html) | [imfilter](/Doc/TyImageProcessing/ImageFilteringandEnhancement/ImageFiltering/BasicImageFiltering/imfilter.html)
