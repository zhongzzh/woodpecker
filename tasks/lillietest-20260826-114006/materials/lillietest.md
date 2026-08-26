# lillietest
---
Lilliefors 检验

<h2>函数库: TyStatistics</h2>

## 语法

<!-- DOC_CHECK:FUNCTION -->
[ h,p,kstat,critval = lillietest(x,alpha=0.05,dist="normal",mctol=[]) ](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#f1)

## 说明

<div id="f1" class="jump-target"></div>

[h](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#h),[p](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#p),[kstat](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#kstat),[critval](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#critval) = lillietest([x](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#x)，[alpha](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#alpha)=0.05,[dist](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#dist)="normal",[mctol](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#mctol)=[]) 使用 Lilliefors 检验返回零假设的检验决策，即向量 x 中的数据来自正态分布族中的分布，而不是它不来自此类分布的备选方案。如果检验在 5% 的显着性水平拒绝原假设，则结果 h 为 1，否则为 0。您还可以针对不同的分布系列测试数据、更改显着性水平或使用蒙特卡罗近似计算。还返回 p 值、测试统计量 kstat 和临界值 critval。 [示例](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#exp1)


## 示例

<div id="exp1" class="jump-target"></div>
<div class="details-box">
<details open><summary>正态分布检验</summary></details>
<div class="details-content">
加载示例数据。 

```julia
using TyMath
using TyStatistics
pkg_dir = pkgdir(TyStatistics)
source_path = pkg_dir * "/examples/HypothesisTests/DistributionTests/lillietest/lillietest_data_1.jl"
include(source_path)
```

检验原假设，即汽车行驶里程（以英里/加仑 (MPG) 为单位）在不同品牌的汽车中服从正态分布。

```julia
MPG;
h,p,k,c = lillietest(MPG)
```

```dataframe
Warning: P 小于表中的最小值，返回 0.001。

h = true
p = 0.001
k = 0.07887911046438467
c = 0.04512460745336841
```

检验统计量 k 大于临界值 c，因此 lillietest 返回结果 h = true，表示在默认的 5% 显着性水平下拒绝原假设。该警告表示返回的 p 值小于预先计算值表中的最小值。要找到更准确的 p 值，请使用 mctol 运行蒙特卡罗近似。详细信息，请参见[使用蒙特卡罗近似法确定 p 值](/Doc/TyStatistics/HypothesisTests/DistributionTests/lillietest.html#exp5)。

</div>
</div>

<div id="exp2" class="jump-target"></div>
<div class="details-box">
<details open><summary>在不同的显着性水平检验假设</summary></details>
<div class="details-content">
加载示例数据。 

```julia
using TyMath
using TyStatistics
pkg_dir = pkgdir(TyStatistics)
source_path = pkg_dir * "/examples/HypothesisTests/DistributionTests/lillietest/lillietest_data_2.jl"
include(source_path)
```

创建一个包含学生考试成绩数据第一列的向量。

```julia
grades;
x = grades[:,1]
```

检验零假设，即样本数据来自 1% 显着性水平的正态分布。

```julia
h,p,kstat,critval = lillietest(x,alpha = 0.01)
```

```dataframe
h = false
p =  0.03477149968269883
```

h = false 的返回值表示 lillietest 在 1% 的显着性水平下不拒绝原假设。

</div>
</div>

<div id="exp3" class="jump-target"></div>
<div class="details-box">
<details open><summary>指数分布检验</summary></details>
<div class="details-content">
加载示例数据。

```julia
using TyMath
using TyStatistics
pkg_dir = pkgdir(TyStatistics)
source_path = pkg_dir * "/examples/HypothesisTests/DistributionTests/lillietest/lillietest_data_1.jl"
include(source_path)
``` 

检验零假设，即汽车行驶里程（以英里/加仑 (MPG) 为单位）在不同品牌的汽车中服从指数分布。

```julia
MPG;
h, = lillietest(MPG,alpha = 0.05,dist = "exponential")
```

```dataframe
Warning: P 小于表中的最小值，返回 0.001。
(true, 0.001, 0.39202806575992033, 0.054331381150922446)
```

h = true 的返回值表示 lillietest 在默认的 5% 显着性水平下拒绝原假设。

</div>
</div>

<div id="exp4" class="jump-target"></div>
<div class="details-box">
<details open><summary>威布尔分布检验</summary></details>
<div class="details-content">
生成两个样本数据集，一个来自 Weibull 分布，另一个来自对数正态分布。执行 Lilliefors 测试以评估每个数据集是否来自 Weibull 分布。通过使用 Weibull 概率图 (wblplot) 进行视觉比较来确认测试决策。

从 Weibull 分布生成样本。

```julia
using TyPlot
using TyMath
using TyStatistics
rng = MT19937ar(5489)
data1 = wblrnd(rng,2,0.5,500)
```

使用 lillietest 执行 Lilliefors 测试。要测试 Weibull 分布的数据，请测试数据的对数是否具有极值分布。

```julia
h1, = lillietest(log.(data1),alpha = 0.05,dist = "ev")
```

```dataframe
Warning: P 大于表中的最大值，返回 0.50

(false, 0.5, 0.022630716766478987, 0.03967230816353632)
```

h1 = false 的返回值表示 lillietest 未能在默认的 5% 显着性水平下拒绝原假设。 

使用 Weibull 概率图确认测试决策。

```julia
wblplot(data1)
```

<img :src="$withBase('/TyStatistics/HypothesisTests/DistributionTests/lillietest/figure1.png')">

该图表明数据服从 Weibull 分布。

从对数正态分布生成样本。

```julia
rng = MT19937ar(5489)
data2 = lognrnd(rng,5,2,500)
```

执行 Lilliefors 测试。

```julia
h2, = lillietest(log.(data2),alpha = 0.05,dist = "ev")
```

```dataframe
Warning: P 小于表中的最小值，返回 0.001。

(true, 0.001, 0.07542413322210312, 0.03967230816353632)
```

h2 = true 的返回值表示 lillietest 在默认的 5% 显着性水平下拒绝原假设。使用 Weibull 概率图确认测试决策。

```julia
figure();
wblplot(data2)
```

<img :src="$withBase('/TyStatistics/HypothesisTests/DistributionTests/lillietest/figure2.png')">

该图表明数据不服从 Weibull 分布。

</div>
</div>

<div id="exp5" class="jump-target"></div>
<div class="details-box">
<details open><summary>使用蒙特卡洛近似确定 p 值</summary></details>
<div class="details-content">
加载示例数据。 检验原假设，即汽车行驶里程（以英里/加仑 (MPG) 为单位）在不同品牌的汽车中服从正态分布。使用最大蒙特卡罗标准误差为 1e-4 的蒙特卡罗近似确定 p 值。

```julia
using TyStatistics
pkg_dir = pkgdir(TyStatistics)
source_path = pkg_dir * "/examples/HypothesisTests/DistributionTests/lillietest/lillietest_data_1.jl"
include(source_path)
h,p,kstat,critval = lillietest(MPG,alpha = 0.05,dist = "normal",mctol=1e-4)
```

```dataframe
h = true
p = 0.0
```

h = true 的返回值表示 lillietest 拒绝原假设，即数据来自 5% 显着性水平的正态分布。

</div>
</div>

## 输入参数

<div id="x" class="jump-target"></div>
<div class="details-box">
<details open><summary>x - 样本数据
<div>向量</div>
</summary></details>
<div class="details-content">
样本数据，指定为向量。

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | Int128 | UInt8 | UInt16 | UInt32 | UInt64 | UInt128

</div>
</div>

<div id="alpha" class="jump-target"></div>
<div class="details-box">
<details open><summary>alpha - 显著性水平
<div>0.05（默认） | 范围 (0,1) 中的标量值</div>
</summary></details>
<div class="details-content">
假设检验的显着性水平，指定范围 (0,1) 中的标量值。

* 如果不使用 mctol，Alpha 必须在 [0.001,0.50] 范围内；

* 如果使用 mctol，Alpha 必须在 (0,1) 范围内。

**示例：** 0.01

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | Int128 | UInt8 | UInt16 | UInt32 | UInt64 | UInt128

</div>
</div>

<div id="dist" class="jump-target"></div>
<div class="details-box">
<details open><summary>dist - 分布族
<div>"normal"（默认） | "exponential" | "ev" | "extreme value"</div>
</summary></details>
<div class="details-content">
假设检验的分布族，指定为以下项之一。

<table>
<tr>
<td>"normal"</td>
<td>正态分布</td>
</tr>
<tr>
<td>"exponential"</td>
<td>指数分布</td>
</tr>
<tr>
<td>"ev"、"extreme value"</td>
<td>极值分布</td>
</tr>
</table>

* 要测试 x 是否服从对数正态分布，请测试 log(x) 是否服从正态分布；

* 要检验 x 是否服从 Weibull 分布，请检验 log(x) 是否具有极值分布。

**示例：** "exponential"

</div>
</div>

<div id="mctol" class="jump-target"></div>
<div class="details-box">
<details open><summary>mctol - 最大蒙特卡洛标准误差
<div>范围 (0,1) 中的标量值</div>
</summary></details>
<div class="details-content">
p 的最大蒙特卡洛标准误差，测试的 p 值，指定为范围 (0,1) 中的标量值。

**示例：** 0.001

**数据类型：** Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | Int128 | UInt8 | UInt16 | UInt32 | UInt64 | UInt128

</div>
</div>

## 输出参数

<div id="h" class="jump-target"></div>
<div class="details-box">
<details open><summary>h - 假设检验结果
<div>true | false</div>
</summary></details>
<div class="details-content">
假设检验结果，返回 true 或 false。

* 如果 h = true，这表示在 Alpha 显着性水平拒绝原假设；

* 如果 h = false，则表示未能在 Alpha 显着性水平拒绝原假设。

</div>
</div>

<div id="p" class="jump-target"></div>
<div class="details-box">
<details open><summary>p - p值
<div>范围 (0,1) 中的标量值</div>
</summary></details>
<div class="details-content">
测试的 p 值，以范围 (0,1) 中的标量值形式返回。p 是在原假设下观察到的检验统计量与观察值一样极端或更极端的概率。p 值小会使原假设的有效性产生疑问。

* 如果未使用 mctol，则使用逆插值法计算 p 到临界值表中，并作为 [0.001,0.50] 范围内的标量值返回；

* 如果使用 mctol，lillietest 会进行蒙特卡罗模拟以计算更准确的 p 值，并且 p 将作为范围 (0,1) 中的标量值返回。

</div>
</div>

<div id="kstat" class="jump-target"></div>
<div class="details-box">
<details open><summary>kstat - 测试统计
<div>非负标量值</div>
</summary></details>
<div class="details-content">
测试统计量，以非负标量值形式返回。

</div>
</div>

<div id="critval" class="jump-target"></div>
<div class="details-box">
<details open><summary>critval - 临界值
<div>非负标量值</div>
</summary></details>
<div class="details-content">
假设检验的临界值，以非负标量值形式返回。

</div>
</div>

## 详细信息

<div id="kstat" class="jump-target"></div>
<div class="details-box">
<details open><summary>Lilliefors检验</summary></details>
<div class="details-content">
Lilliefors 检验是一种双侧拟合优度检验，适用于零分布的参数未知且必须进行估计的情况。这与单样本 Kolmogorov-Smirnov 检验相反，后者要求完全指定零分布。

Lilliefors 检验统计量为：
$
D^{*}=\max _{x}|\widehat{F}(x)-G(x)|
$
其中 $\widehat{F}(x)$ 是样本数据的ecdf，G(x) 是估计参数等于样本参数的假设分布的 cdf。

lillietest 可用于测试数据向量 x 是否具有对数正态分布或 Weibull 分布，方法是对数据向量应用变换并运行适当的 Lilliefors 检验：

* 要测试 x 是否服从对数正态分布，请测试 log(x) 是否服从正态分布；

* 要检验 x 是否服从 Weibull 分布，请检验 log(x) 是否具有极值分布。

当原假设不是位置尺度分布族时，不能使用 Lilliefors 检验。

</div>
</div>

<div id="kstat" class="jump-target"></div>
<div class="details-box">
<details open><summary>蒙特卡洛标准误差</summary></details>
<div class="details-content">
蒙特卡洛标准误差是由于模拟 p 值而产生的误差。

蒙特卡洛标准误差计算如下：
$
SE=\sqrt{\frac{(\hat{p})(1-\hat{p})}{\text { mcreps }}},
$
其中 $\hat{p}$ 是假设检验的估计 p 值，mcreps 是执行的蒙特卡洛复制次数。

确定蒙特卡罗重复次数 mcreps，使 $\hat{p}$ 的蒙特卡罗标准误差小于为 mctol 指定的值。

</div>
</div>

## 算法

为了计算假设检验的临界值，lillietest 将内插到一张临界值表中，该临界值是使用 Monte Carlo 模拟针对小于 1000 的样本量和 0.001 到 0.50 之间的显着性水平预先计算的。lillietest 使用的表格比 Lilliefors 最初引入的表格更大、更准确。如果需要更准确的 p 值，或者如果所需的显着性水平小于 0.001 或大于 0.50，则 mctol 输入参数可用于运行蒙特卡罗模拟以更准确地计算 p 值。

当检验统计量的计算值大于临界值时，lillietest 在显着性水平 alpha 拒绝零假设。

lillietest 将 x 中的 NaN 值视为缺失值并忽略它们。

## 另请参阅

[kstest](/Doc/TyStatistics/HypothesisTests/DistributionTests/kstest.html) 
