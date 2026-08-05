# ztrans
---
Z 变换

<h2>函数库: TySymbolicMath</h2>

## 语法
<!-- DOC_CHECK:FUNCTION -->
[ztrans(f)](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#f1)

[ztrans(f,transVar)](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#f2)

[ztrans(f,var,transVar)](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#f3)

## 说明

<div id="f1" class="jump-target"></div>

ztrans([f](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#f)) 求 f 的 [Z 变换](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#b0875f38)。 默认情况下，自变量为 n，变换变量为 z。 如果 f 不包含 n，则 ztrans 使用 symvar。[示例](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#exp1)

---
<div id="f2" class="jump-target"></div>

ztrans([f](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#f),[transVar](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#transVar)) 使用变换变量 transVar 而不是 z。[示例](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#exp2)

---
<div id="f3" class="jump-target"></div>

ztrans([f](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#f),[var](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#var),[transVar](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#transVar)) 分别使用自变量 var 和变换变量 transVar 代替 n 和 z。[示例](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html#exp3)

## 示例

<div id="exp1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>符号表达式的 Z 变换</summary>
</details>
<div class="details-content">

计算 sin(n) 的 Z 变换。 默认情况下，变换以 z 为单位。

```julia
using TySymbolicMath
@variables n
f = sin(n);
ztrans(f)
```

```dataframe
TySymbolicMath.SymSum((z^(-n))*sin(n), n, 0, Inf)
```

</div>
</div>

<div id="exp2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>指定自变量和变换变量</summary>
</details>
<div class="details-content">

计算 exp(m+n) 的 Z 变换。 默认情况下，自变量为 n，变换变量为 z。

```julia
using TySymbolicMath
@variables m ,n
f = exp(m+n);
ztrans(f)
```

```dataframe
TySymbolicMath.PieceWise(TySymbolicMath.ExprCondPair(1 / (1 + -2.718281828459045 / z), (2.718281828459045 / abs(z)) < 1), TySymbolicMath.ExprCondPair(TySymbolicMath.SymSum((z^(-n))*exp(n), n, 0, Inf), true))*exp(m)
```

将变换变量指定为 y。 如果仅指定一个变量，则该变量就是转换变量。 自变量仍然是n。

```julia
@variables y
qq = ztrans(f,y)
```

```dataframe
qq = TySymbolicMath.SymSum((y^(-n))*exp(m + n), y, 0, Inf)
```

在第二个和第三个参数中分别将自变量和变换变量指定为 m 和 y。

```julia
qq2 = ztrans(f,m,y)
```

```dataframe
qq2 = TySymbolicMath.SymSum((y^(-m))*exp(m + n), y, 0, Inf)
```


</div>
</div>

<div id="exp3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>符号函数的 Z 变换</summary>
</details>
<div class="details-content">

计算符号函数的 Z 变换。 当第一个参数包含符号函数时，第二个参数必须是标量。

```julia
using TySymbolicMath
@variables x, f1(x), f2(x), a, b
f1 = exp(x);
f2 = x;
ztrans.([f1 f2],x,[a b])
```

```dataframe
ans = 1×2 Matrix{Num}:
 SymSum((a^(-x))*exp(x), a, 0, Inf)  SymSum(x*(b^(-x)), b, 0, Inf)
```

```julia
@variables n,f(n),z
f = 1/n;
F = ztrans(f,n,z)
```

```dataframe
F = TySymbolicMath.SymSum((z^(-n)) / n, z, 0, Inf)
```

</div>
</div>

## 输入参数

<div id="f" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>f - 输入<div>Num</div></summary>
</details>
<div class="details-content">

输入，指定为符号表达式、函数、向量或矩阵。

</div>
</div>

<div id="var" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>var - 自变量<div>n（默认） | 符号变量</div></summary>
</details>
<div class="details-content">

自变量，指定为符号变量。 该变量通常称为“离散时间变量”。 如果不指定变量，则 ztrans 使用 n。 如果 f 不包含 n，则 ztrans 使用函数 symvar。

</div>
</div>

<div id="transVar" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>transVar - 变换变量<div>z（默认） | Num</div></summary>
</details>
<div class="details-content">

变换变量，指定为符号变量、表达式、向量或矩阵。 该变量通常称为“复频率变量”。 默认情况下，ztrans 使用 z。 如果 z 是 f 的自变量，则 ztrans 使用 w。

</div>
</div>

## 详细信息

<div id="b0875f38" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Z - 变换</summary>
</details>
<div class="details-content">

表达式 $f = f(n)$ 相对于 $z$ 点处的变量 $n$ 的 $Z$ 变换 $F = F(z)$ 为：

$F(z) = \sum_{n=0}^{\infty } \frac{f(n)}{z^{n}}$

</div>
</div>

:::tip 提示

* 如果任何参数是数组，则 ztrans 按元素作用于数组的所有元素；

* 如果第一个参数包含符号函数，则第二个参数必须是标量；

* 要计算 Z 逆变换，请使用 iztrans。

:::

## 另请参阅

[fourier](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/fourier.html) | [ifourier](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ifourier.html) | [ilaplace](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ilaplace.html) | [iztrans](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html) | [laplace](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/laplace.html)



