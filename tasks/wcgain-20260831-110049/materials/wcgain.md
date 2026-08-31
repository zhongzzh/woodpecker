# wcgain
---
不确定系统的最坏情况增益

<h2>函数库: TyRobustControl</h2>

## 语法

``` julia
wcg,wcu,info = wcgain(usys)
wcg,wcu,info = wcgain(usys,opts)
wcg,wcu,info = wcgain(usys,focus)
wcg,wcu,info = wcgain(usys,focus,opts)
wcg,wcu,info = wcgain(usys,w)
wcg,wcu,info = wcgain(usys,w,opts)
```

## 说明


[wcg](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#wcg),[wcu](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#wcu),[info](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#info) = wcgain([usys](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#usys)) 计算不确定系统 usys 的最坏情况峰值增益。

峰值增益指的是频率上的最大增益（H∞ 范数）。对于多输入多输出（MIMO）系统，增益指的是频率响应矩阵的最大奇异值。（有关奇异值的更多信息，请参见 sigma）输出 wcg 存储最坏情况增益的上界和下界，以及下限达到峰值的临界频率。输出 wcu 存储导致最坏情况峰值增益的不确定元素的具体值。

------------------------------------

wcg,wcu,info = wcgain(usys, [opts](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#opts)) 指定计算的附加选项。使用 [wcOptions](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcOptions.html) 创建选项。

------------------------------------

wcg,wcu,info = wcgain(usys, [focus](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#focus)) 将峰值搜索限制在指定频率范围内。

------------------------------------

wcg,wcu,info = wcgain(usys, [w](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html#w)) 只在指定频率向量上计算最坏情况增益。此语法不搜索频率点之间的峰值。

## 示例

<div class="details-box">
<details open><summary>闭环系统最坏情况峰值增益</summary></details>
<div class="details-content">

为了检查不确定控制系统的最坏情况性能，创建一个具有积分器标称模型的被控对象，并包括水平为 0.4 的附加未建模动态不确定性（等同于在 2.5 rad/s 时存在 100% 的模型不确定性）。然后设计比例控制器 K1，使标称闭环带宽为 0.8 rad/s。在比标称闭环带宽高 25 倍的频率处衰减 K1。对控制器 K2 进行相同设计，使标称闭环带宽为 2.0 rad/s。每种情况下构造一次闭环灵敏度函数。

``` julia
using TyRobustControl
using TyControlSystems

P = uss(tf(1,[1, 0])) + ultidyn("delta",[1, 1],Bound=0.4);
BW1 = 0.8;
K1 = tf(BW1,[1/(25*BW1) 1]);
S1 = feedback(uss(1),P*K1);
BW2 = 2.0;
K2 = tf(BW2,[1/(25*BW2) 1]);
S2 = feedback(uss(1),P*K2);
```
评估闭环灵敏度函数的最坏情况增益：
``` julia
maxgain1,wcunc1,info1 = wcgain(S1);
maxgain2,wcunc2,info2 = wcgain(S2);
maxgain1
```
``` dataframe
Dict{String, Float64} with 3 entries:
  "LowerBound"        => 1.50703
  "CriticalFrequency" => 5.20411
  "UpperBound"        => 1.50703
```
``` julia
maxgain2
```
``` dataframe
Dict{String, Float64} with 3 entries:
  "LowerBound"        => 5.10417
  "CriticalFrequency" => 10.6082
  "UpperBound"        => 5.10417
```
计算结果表明控制器 K1 的最坏情况性能优于 K2。

</div>
</div>

## 输入参数

<div id="usys" class="jump-target"></div>
<div class="details-box">
<details open><summary>usys - 不确定的动态系统<div>
USS 模型
</div></summary></details>
<div class="details-content">

具有不确定性的动态系统，指定为包含不确定元素的 **USS** 模型。

</div>
</div>

<div id="focus" class="jump-target"></div>
<div class="details-box">
<details open><summary>focus - 峰值搜索频率范围<div>
二元实数元组
</div></summary></details>
<div class="details-content">

峰值搜索的频率范围，指定为 `(wmin,wmax)`。频率必须满足 `0 <= wmin < wmax`，单位为 rad/TimeUnit。连续时间系统允许 `wmax=Inf`；离散时间系统的上限不能超过奈奎斯特频率。

**数据类型：** Tuple{Real,Real}

</div>
</div>

<div id="w" class="jump-target"></div>
<div class="details-box">
<details open><summary>w - 指定计算频率<div>
非负实数向量
</div></summary></details>
<div class="details-content">

计算最坏情况增益的频率点，单位为 rad/TimeUnit。输入频率会去重并按升序排列。此语法仅计算指定点，不能保证捕获频率点之间的峰值。

**数据类型：** AbstractVector{&lt;:Real}

</div>
</div>

<div id="opts" class="jump-target"></div>
<div class="details-box">
<details open><summary>opts - 计算差值的选项<div>
WCOptions
</div></summary></details>
<div class="details-content">

最坏情况计算的选项，指定为使用 ```wcOptions``` 创建的对象。可用的选项包括以下设置:
- 提取频率相关的最差情况增益；
- 检查最坏情况增益对每个不确定元素的敏感性；
- 通过为底层的 ```mussv``` 计算设置某些选项来改进最坏情况增益计算的结果。

详细信息，请参阅 [wcOptions](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcOptions.html)。

</div>
</div>

## 输出参数
<div id="wcg" class="jump-target"></div>
<div class="details-box">
<details open><summary>wcg - 最坏峰值增益和临界频率<div>
Dict
</div></summary></details>
<div class="details-content">

最坏情况峰值增益和临界频率，返回包含以下键的字典：

- "LowerBound" - 模型的实际最坏情况峰值增益的下界，作为标量值返回。这个值是与最坏摄动 wcu 相对应的峰值增益。确切的最坏情况峰值增益保证不小于 LowerBound；
- "UpperBound" - 模型的实际最坏情况峰值增益的上界，作为标量值返回。确切的最坏情况峰值增益保证不大于上限；
- "CriticalFrequency" - 最坏情况峰值增益发生的频率，单位为 rad/TimeUnit，其中 TimeUnit 是 usys 的 TimeUnit 属性。

</div>
</div>

<div id="wcu" class="jump-target"></div>
<div class="details-box">
<details open><summary>wcu - 最坏情况扰动<div>
Dict
</div></summary></details>
<div class="details-content">

不确定元素的最坏情况扰动，以结构形式返回，其字段为 usys 中不确定元素的名称。每个字段都包含 usys 中相应不确定元素在发生最坏情况峰值增益时的实际值。例如，如果 usys 包含一个不确定矩阵 M 和 SISO 不确定动力学 delta，那么 wcu["M"] 是一个数值矩阵，而 wcu["delta"] 是一个 SISO 状态空间模型。

</div>
</div>

<div id="info" class="jump-target"></div>
<div class="details-box">
<details open><summary>info - 关于最坏情况值的附加信息<div>
Dict
</div></summary></details>
<div class="details-content">

关于最坏情况值的附加信息，作为具有以下键的字典返回:

- "Model": 最坏情况峰值增益最大的模型索引值（适用于模型阵列 usys）;
- "Frequency": ```wcgain``` 计算结果对应的频率点，以实数向量形式返回：
  - 如果 **WCOptions** 的 VaryFrequency 选项为 false，则 Info["Frequency"] 返回最坏情况增益下界和上界对应的关键频率；二者相同时仅返回一个频率；
  - 如果 **WCOptions** 的 VaryFrequency 选项为 true，则 Info["Frequency"] 返回基础频率曲线以及自适应峰值搜索得到的证书频率；
  - 如果输入频率向量 w，则 Info["Frequency"] 返回去重、排序后的指定频率。

  VaryFrequency 选项适用于 **USS** 模型。
- "Bounds": 模型实际最坏情况增益的上下界，以数组形式返回。Info["Bounds"][:,1] 包含 Info["Frequency"] 中每个对应频率的下界，而 Info["Bounds"][:,2] 则包含相应的上界；
- "WorstPerturbation": 与 wcg["LowerBound"] 和 wcg["CriticalFrequency"] 对应的最坏情况扰动，内容与输出 wcu 相同；
- "Sensitivity": 每个不确定元素对最坏情况增益的灵敏度，当 **WCOptions** 的 Sensitivity 选项为 true 时，以字典形式返回。Info["Sensitivity"] 的键是 usys 中不确定元素的名称。每个键包含一个百分比，表示相应元素的不确定性对最坏情况增益的影响程度。例如，如果 Info["Sensitivity"]["p"] 为 50，则 p 的不确定范围的某一分数变化将导致最坏情况增益发生一半大小的分数变化。

  如果 **WCOptions** 的 Sensitivity 选项为 false（默认设置），则 Info["Sensitivity"] 返回 NaN。

</div>
</div>


## 算法

计算特定频率下的最坏增益等同于计算某个适当块结构的结构奇异值 μ（μ 分析）。

对于 **USS** 模型，```wcgain``` 先根据系统动态范围建立基础频率网格，再在最坏情况增益下界的峰值邻域执行自适应局部搜索。仅当 μ 上下界间隙明显时，算法才执行额外的双向上界下降。

当指定频率向量 w 时，```wcgain``` 在每个给定频率上独立计算 μ 下界和上界，不进行自适应峰值搜索。因此，如果系统存在尖锐共振，应提供足够密集的频率点。

## 另请参阅
[mussv](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/mussv.html)
| [wcOptions](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcOptions.html)
| [robstab](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/robstab.html)














