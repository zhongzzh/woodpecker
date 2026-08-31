# wcOptions
---
最坏情况分析选项集

<h2>函数库: TyRobustControl</h2>

## 语法

``` julia
opts = wcOptions()
opts = wcOptions(Name=Value,...)
```

## 说明
opts = wcOptions() 返回用于最坏情况分析命令（例如 [wcgain](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html)）的默认选项集。

---
opts = wcOptions(Name=Value,...) 用一个或多个 [Name=value](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcOptions.html#x76f61a5c) 参数对指定的选项创建一个选项集。

## 示例

<div class="details-box">
<details open><summary>设置最坏情况峰值增益计算选项</summary></details>
<div class="details-content">

创建一个选项集来计算最坏情况增益，同时允许不确定参数比模型中指定的范围多变化 20%。此外，将选项配置为在计算中包含逐元素的灵敏度分析。

``` julia
using TyRobustControl

opts = wcOptions(ULevel=1.2,VaryFrequency=true,Sensitivity=true);
```
或者，创建一个默认的选项集，并使用点符号设置特定选项的值。

``` julia
opts = wcOptions();
opts.ULevel = 1.2;
opts.VaryFrequency = true;
opts.Sensitivity = true;
```

</div>
</div>

## 输入参数

<div id="x76f61a5c" class="jump-target"></div>

### 名称-值参数
<div id="ULevel" class="jump-target"></div>
<div class="details-box">
<details open><summary>ULevel - 不确定性水平<div>
1 (默认) | 正实数
</div></summary></details>
<div class="details-content">

用于最坏情况计算的不确定性水平，这一选项将根据指定的因子对归一化的不确定性进行缩放。这样的缩放允许您在不改变模型中不确定性水平的情况下，考察较小或较大不确定性范围的影响。例如，要查看将所有不确定参数范围翻倍的效果，可以设置 ULevel = 2。要查看缩小范围的效果，可以设置 ULevel = 0.5。默认值 1 对应于模型中指定的不确定性量。

**默认值：** 1

</div>
</div>

<div id="Display" class="jump-target"></div>
<div class="details-box">
<details open><summary>Display - 显示计算进度和摘要报告<div>
false (默认) | true
</div></summary></details>
<div class="details-content">

指定最坏情况分析命令是否显示 mussv 计算进度的字符串。
- false - 不显示进度；
- true - 显示进度。此设置覆盖 Mussv 参数的关闭显示（"s"）选项。

**默认值：** false

</div>
</div>

<div id="Sensitivity" class="jump-target"></div>
<div class="details-box">
<details open><summary>Sensitivity - 计算最坏情况增益灵敏度<div>
false (默认) | true
</div></summary></details>
<div class="details-content">

计算模型中每个不确定元素对最坏情况增益的灵敏度，以由关键字 Sensitivity 和 false 或 true 组成的逗号分隔对指定。

每个不确定元素以耦合的方式对总体最坏情况做出贡献。将此选项设置为 true 以估算每个元素的敏感度。这种逐个元素的敏感度估计可以指示哪些元素造成的影响最大。在在最坏情况计算命令的 Info 输出中访问敏感度估计。

**默认值：** false

</div>
</div>

<div id="VaryFrequency" class="jump-target"></div>
<div class="details-box">
<details open><summary>VaryFrequency - 返回频率相关结果<div>
false (默认) | true
</div></summary></details>
<div class="details-content">

指定 Info["Frequency"] 和 Info["Bounds"] 是否返回频率曲线。
- false - 只返回最坏情况增益下界和上界对应的关键频率；
- true - 返回基础频率曲线以及自适应峰值搜索得到的证书频率。

**默认值：** false

</div>
</div>

<div id="SensitivityPercent" class="jump-target"></div>
<div class="details-box">
<details open><summary>SensitivityPercent - 灵敏度计算的不确定性变化百分比<div>
25 (默认) | 正实数
</div></summary></details>
<div class="details-content">

计算敏感度时不确定性的百分比变化。通过有限差分计算估算特定不确定元素的灵敏度。该计算增加此元素上的（归一化）不确定性量一定百分比，计算得到的最坏情况增益，然后计算百分比变化的比率。此选项指定应用于每个元素的不确定性水平的百分比增量。默认值为 25%。

**默认值：** 25

</div>
</div>

<div id="VaryUncertainty" class="jump-target"></div>
<div class="details-box">
<details open><summary>VaryUncertainty - 兼容性选项<div>
false (默认) | true
</div></summary></details>
<div class="details-content">

为兼容已有代码保留的布尔字段。当前 ```wcgain``` 计算不使用此字段；灵敏度有限差分的变化百分比由 SensitivityPercent 指定。

**默认值：** false

</div>
</div>

<div id="MussvOptions" class="jump-target"></div>
<div class="details-box">
<details open><summary>MussvOptions - 结构奇异值 mussv 计算选项<div>
"" (默认) | 字符串
</div></summary></details>
<div class="details-content">

用于最坏情况计算中底层 ```mussv``` 计算的选项字符串。Display=false 时，```wcgain``` 会在内部启用静默选项；Display=true 时会移除静默选项。详细信息，请参见 [mussv](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/mussv.html)。

**默认值：** ""

</div>
</div>

## 输出参数
<div id="opts" class="jump-target"></div>
<div class="details-box">
<details open><summary>opts - 选项集<div>
WCOptions
</div></summary></details>
<div class="details-content">

用于最坏情况计算的选项集。

**数据类型：** WCOptions

</div>
</div>

## 另请参阅
[wcgain](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/wcgain.html)
