# polydiv
---
多项式长除法

<h2>函数库: TyMath</h2>

## 语法

```julia
q, r = polydiv(b, a)
```

## 说明

[q](/Doc/TyMath/ElementaryMath/Polynomials/polydiv.html#q), [r](/Doc/TyMath/ElementaryMath/Polynomials/polydiv.html#r) = polydiv([b](/Doc/TyMath/ElementaryMath/Polynomials/polydiv.html#b), [a](/Doc/TyMath/ElementaryMath/Polynomials/polydiv.html#a)) 将系数向量 b 表示的多项式除以系数向量 a 表示的多项式，返回商 q 和余数 r，使得 b = conv(a, q) + r。[示例](/Doc/TyMath/ElementaryMath/Polynomials/polydiv.html#eg01)
---
当 length(a) > length(b) 时，q = 0 且 r = b。

## 示例

<div id="eg01" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>两个多项式相除</summary>
</details>
<div class="details-content">

创建两个行向量，分别包含多项式 2x^3+7x^2+4x+9 和 x^2+1 的系数。将第一个多项式除以第二个多项式，得到对应于 2x+7 的商系数和对应于 2x+2 的余数系数。

```julia
using TyMath
b = [2 7 4 9]
a = [1 0 1]
q, r = polydiv(b, a)
```

```dataframe
q = 1×2 Matrix{Float64}:
 2.0  7.0

r = 1×4 Matrix{Float64}:
 0.0  0.0  2.0  2.0
```

要检查除法，可以使用 [conv](/Doc/TyMath/FourierAnalysisandFiltering/Convolution/conv.html) 和 vec 根据除数、商和余数重构原始被除数多项式。

```julia
bOrig = reshape(conv(vec(a), vec(q)) + vec(r), 1, :)
```

```dataframe
bOrig = 1×4 Matrix{Float64}:
 2.0  7.0  4.0  9.0
```

</div>
</div>

## 输入参数

<div id="b" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>b - 被除数多项式系数<div>行或列向量</div></summary>
</details>
<div class="details-content">

被除数多项式系数，指定为行或列向量，系数按降幂排列。

**数据类型：** Int | Float

**复数支持：** 是

</div>
</div>

<div id="a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>a - 除数多项式系数<div>行或列向量</div></summary>
</details>
<div class="details-content">

除数多项式系数，指定为行或列向量，系数按降幂排列。

当 a 的长度大于 b 时，q = 0 且 r = b。

**数据类型：** Int | Float

**复数支持：** 是

</div>
</div>

## 输出参数

<div id="q" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>q - 商多项式系数<div>行或列向量</div></summary>
</details>
<div class="details-content">

商多项式系数，以行或列向量形式返回。

**数据类型：** Int | Float

**复数支持：** 是

</div>
</div>

<div id="r" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>r - 余数多项式系数<div>行或列向量</div></summary>
</details>
<div class="details-content">

余数多项式系数，以行或列向量形式返回。

**数据类型：** Int | Float

**复数支持：** 是

</div>
</div>

## 另请参阅

[conv](/Doc/TyMath/FourierAnalysisandFiltering/Convolution/conv.html)
| [deconv](/Doc/TyMath/FourierAnalysisandFiltering/Convolution/deconv.html)
| [polyval](/Doc/TyMath/ElementaryMath/Polynomials/polyval.html)
| [residue](/Doc/TyMath/ElementaryMath/Polynomials/residue.html)
