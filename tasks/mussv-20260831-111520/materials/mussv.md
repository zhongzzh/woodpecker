# mussv
---
计算结构奇异值 (μ) 的上下界

<h2>函数库: TyRobustControl</h2>

## 语法

``` julia
Bounds = mussv(M,BlockStructure)
Bounds,MuInfo = mussv(M,BlockStructure)
Bounds,MuInfo = mussv(M,BlockStructure,Options)
```
## 说明

Bounds = mussv(M,BlockStructure) 计算指定结构的结构奇异值 µ 的上下界。M 指定为数值数组或 **FRD** 模型。
如果 M 指定为 3 维或更高维数组，那么计算将沿第 3 维或更高维度逐点进行。如果 M 指定为 **FRD** 模型，则按频率（以及任何数组维度）进行点式运算。

BlockStructure 是指定扰动块结构的矩阵。块结构有2列，和扰动结构中的不确定性块一样多的行。BlockStructure 的第 i 行定义了第 i 个扰动块的尺寸。

- BlockStructure[i, :] = [-r, 0] -> 第 i 个模块是一个 r × r 重复的对角实标量微扰;
- BlockStructure[i, :] = [r, 0] -> 第 i 个模块是一个 r × r 重复的对角复标量微扰;
- BlockStructure[i, :] = [r, c] -> 第 i 个模块是一个 r × c 的复全块摄动。
- 如果省略 BlockStructure，则其默认值为 ones(size(M,1)，2)，这意味着所有 1 × 1 复杂块的扰动结构。在这种情况下，如果size(M,1)不等于size(M,2)，则会报错。

如果 M 指定为 2 维矩阵，则返回的 Bounds 为 1 × 2 的矩阵，两个元素分别是 M 结构奇异值的上界和下界。对于所有具有 BlockStructure 所定义的块对角线结构且范数小于 1/Bounds[1] 的矩阵 Delta，矩阵 I - M×Delta 非奇异。另外，存在一个由 BlockStructure 定义的具有块对角结构的矩阵 DeltaS，其范数等于 1/Bounds[2]，对于该矩阵，I - M×DeltaS 是奇异的。

如果 M 指定为 N 维数组（N≥3）或者 **FRD** 模型，则结构奇异值的上下界沿着第 3 和更高数组维度逐点计算（对于**FRD** 模型，则按频率逐点计算)。例如，假设 M 大小为 $r×c×d_1×\cdots×d_F$，那么返回的 Bounds 大小为 $1×2×d_1×\cdots×d_F$，Bounds[1,1,i] 是 M[:,:,i] 结构奇异值的上界，Bounds[1,2,i] 则是 M[:,:,i] 结构奇异值的下界（i 可以在 1 和 $d_1·d_2·\cdots·d_F$ 之间任意取值）。

---
Bounds,MuInfo = mussv(M,BlockStructure,Options) 指定计算选项。Options 是一个字符向量，目前支持包含以下字符及其任意组合:

|选择|含义|
|-|-|
|"f"|强制快速上界计算（严谨性通常低于默认计算方法）|
|"U"|“仅”计算上界（下界计算使用快速算法）|
|"i"|重新初始化每个新矩阵的下界计算（仅适用于 M 是多维数组或 **FRD** 模型）|
|"mN"|随机重新初始化多次下界迭代。N 是 1 到 9 之间的整数。例如，"m7" 代表随机重新初始化下界迭代 7 次。较大的数字通常计算成本更高，但通常给出更好的下界。|
|"p"|采用幂次迭代法计算下界。当 BlockStructure 至少存在 1 个复数不确定模块，则默认采用 "p" 方法。|
|"s"|关闭进度信息|   
|"d"|显示警告信息|
|"x"|减少下界计算的迭代次数(相比默认方法速度更快，但严谨性降低)|

---
Bounds,MuInfo = mussv(M,BlockStructure) 返回 MuInfo ，一个包含更多详细信息的结构体。MuInfo 中的信息必须使用 ```mussvextract``` 提取。

:::warning 注意
```mussv``` 的返回值根据机器不同可能存在一些波动。
:::

## 示例
<div class="details-box">
<details open><summary>结构化奇异值（μ 分析）在 5×5 复矩阵与自定义块结构下的计算</summary></details>
<div class="details-content">


有关结构化奇异值的详细示例，请参见 [mussvextract](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/mussvextract.html)。

构造一个随机 5 × 5 复矩阵 M，块结构 BlockStructure 是一个不确定实参数 δ1、一个不确定实参数 δ2、一个不确定复参数 δ3，以及一个重复两次的不确定复参数 δ4。

``` Julia
using TyRobustControl

M = [0.5377 + 1.0347im  -1.3077 + 0.8884im  -1.3499 + 1.4384im  -0.2050 - 0.1022im   0.6715 - 0.0301im;
1.8339 + 0.7269im  -0.4336 - 1.1471im   3.0349 + 0.3252im  -0.1241 - 0.2414im  -1.2075 - 0.1649im;
-2.2588 - 0.3034im   0.3426 - 1.0689im   0.7254 - 0.7549im   1.4897 + 0.3192im   0.7172 + 0.6277im;
0.8622 + 0.2939im   3.5784 - 0.8095im  -0.0631 + 1.3703im   1.4090 + 0.3129im  1.6302 + 1.0933im;
0.3188 - 0.7873im   2.7694 - 2.9443im   0.7147 - 1.7115im   1.4172 - 0.8649im   0.4889 + 1.1093im];
BlockStructure = [-1 0;-1 0;1 1;2 0];
Bounds,_ = mussv(M,BlockStructure);
Bounds
```

``` dataframe
1×2 Matrix{Float64}:
 5.2319  4.86933
```
</div>
</div>

## 另请参阅
[mussvextract](/Doc/TyRobustControl/UncertainSystemAnalysis/RobustnessAndWorst-CaseAnalysis/mussvextract.html)




