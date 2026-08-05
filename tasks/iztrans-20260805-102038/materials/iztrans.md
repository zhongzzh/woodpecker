<MLangFuncTag></MLangFuncTag>

# iztrans
---
Z 逆变换

## 语法

```matlab
iztrans(F)
iztrans(F,transVar)
iztrans(F,var,transVar)
```

## 说明

iztrans([F](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#F)) 求 F 的逆 Z 变换。 返回 F 的逆 Z 变换。默认情况下，自变量为 z，变换变量为 n。 如果 F 不包含 z，则 iztrans 使用函数 symvar。[示例](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#exp1)

---

iztrans([F](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#F),[transVar](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#transVar)) 使用变换变量 transVar 而不是 n。[示例](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#exp2)

---

iztrans([F](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#F),[var](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#var),[transVar](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#transVar)) 分别使用自变量 var 和变换变量 transVar 代替 z 和 n。[示例](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#exp4)

## 示例

<div id="exp1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>符号表达式的 Z 逆变换</summary>
</details>
<div class="details-content">

计算 2*z/(z-2)^2 的 Z 逆变换。 默认情况下，逆变换以 n 为单位。

```matlab
syms z
F = 2*z/(z-2)^2;
iztrans(F)
```

```dataframe
ans =

    2^n + (-1 + n)*(2^n)
```

</div>
</div>

<div id="exp2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>指定自变量和变换变量</summary>
</details>
<div class="details-content">

计算 1/(a*z) 的 Z 逆变换。 默认情况下，自变量和变换变量分别为 z 和 n。

```matlab
syms z a
F = 1/(a*z);
iztrans(F)
```

```dataframe
ans = 

    (1/a)TySymbolicMath.kroneckerDelta(-1 + n, 0)
```

将变换变量指定为 m。 如果仅指定一个变量，则该变量就是转换变量。 自变量仍然是 z。

```matlab
syms m
iztrans(F,m)
```

```dataframe
ans = 

    (1/a)TySymbolicMath.kroneckerDelta(-1 + m, 0)
```

在第二个和第三个参数中分别将自变量和变换变量指定为 a 和 m。

```matlab
iztrans(F,a,m)
```

```dataframe
ans = 

    (1/z)TySymbolicMath.kroneckerDelta(-1 + m, 0)
```

</div>
</div>

<div id="exp3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>涉及克罗内克 δ 函数的 Z 逆变换</summary>
</details>
<div class="details-content">

计算下列表达式的 Z 逆变换。结果涉及克罗内克 δ 函数。

```matlab
syms n z
iztrans(1/z,z,n)
```

```dataframe
ans = 

    TySymbolicMath.kroneckerDelta(-1 + n, 0)
```

```matlab
f = (z^3 + 3*z^2)/z^5;
iztrans(f,z,n)
```

```dataframe
ans = 

    TySymbolicMath.kroneckerDelta(-2 + n, 0) + 3TySymbolicMath.kroneckerDelta(-3 + n, 0)
```

</div>
</div>

<div id="exp4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>阵列输入的 Z 逆变换</summary>
</details>
<div class="details-content">

求矩阵 M 的 Z 逆变换。使用相同大小的矩阵为每个矩阵元素指定独立变量和变换变量。当参数为非标量时，iztrans 会按元素方式对其执行运算。

```matlab
syms a b c d w x y z
M = [exp(x) 1; sin(y) i*z];
vars = [w x; y z];
transVars = [a b; c d];
iztrans(M,vars,transVars)
```

```dataframe
ans = 

    "TySymbolicMath.kroneckerDelta(a, 0)*exp(x)"    "TySymbolicMath.kroneckerDelta(b, 0)"
          "TySymbolicMath.iZtrans(sin(y), y, c)"     "im*TySymbolicMath.iZtrans(z, z, d)"
```

若使用标量参数和非标量参数同时调用 iztrans，该函数会通过标量扩展将标量参数扩展至与非标量参数匹配的维度。所有非标量参数必须具有相同的大小。

```matlab
syms w x y z a b c d
iztrans(x,vars,transVars)
```

```dataframe
ans = 

    "x*TySymbolicMath.kroneckerDelta(a, 0)"          "TySymbolicMath.iZtrans(x, x, b)"
    "x*TySymbolicMath.kroneckerDelta(c, 0)"    "x*TySymbolicMath.kroneckerDelta(d, 0)"
```

</div>
</div>

<!--
<div id="exp5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>符号函数的 Z 逆变换</summary>
</details>
<div class="details-content">

计算符号函数的 Z 逆变换。当第一个参数包含符号函数时，第二个参数必须为标量。

```matlab
syms f1(x) f2(x) a b
f1(x) = exp(x);
f2(x) = x;
iztrans([f1, f2],x,[a, b])
```

```dataframe

```

</div>
</div>
-->
<!--
<div id="exp6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>若无法求得 Z 逆变换</summary>
</details>
<div class="details-content">

若 iztrans 无法计算逆变换，则返回未计算的调用表达式。

```matlab
syms F(z) n
F(z) = exp(z);
f = iztrans(F,z,n)
```

</div>
</div>
-->
## 输入参数

<div id="F" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>F - 输入<div>符号表达式 | 符号向量 | 符号矩阵</div></summary>
</details>
<div class="details-content">

输入，指定为符号表达式、<!--函数、-->向量或矩阵。

</div>
</div>

<div id="var" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>var - 自变量<div>x（默认） | 符号变量 | 符号表达式 | 符号向量 | 符号矩阵</div></summary>
</details>
<div class="details-content">

自变量，指定为符号变量、表达式、向量或矩阵。该变量通常称为“复频率变量”。如果您不指定变量，则 iztrans 使用 z。如果 F 不包含 z，则 iztrans 使用函数 symvar。

</div>
</div>

<div id="transVar" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>transVar - 变换变量<div>x（默认） | t | 符号变量 | 符号表达式 | 符号向量 | 符号矩阵</div></summary>
</details>
<div class="details-content">

变换变量，指定为符号变量、表达式、向量或矩阵。它通常被称为“时间变量”或“空间变量”。默认情况下，iztrans 使用 n。 如果 n 是 [F](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/iztrans.html#F) 的自变量，则 iztrans 使用 k。

</div>
</div>

## 详细信息

<div class="details-box">
<details open>
<summary>Z 逆变换</summary>
</details>
<div class="details-content">

若存在正数 $R$，使得函数 $F = F(z)$ 在圆 $|z| = R$ 上及圆外解析，则其Z反变换为

$f(n) = \frac{1}{2\pi i}\oint_{|z|=R}F(z)z^{n-1}\ dz, n=0,1,2...$

</div>
</div>

## 提示

* 如果任何参数是数组，则 iztrans 对数组的所有元素按元素进行操作；

* 如果第一个参数包含符号函数，则第二个参数必须是标量；

* 要计算直接 Z 变换，请使用 ztrans。


## 另请参阅

<!--[fourier]() | [ifourier]() | -->
[ilaplace](/Doc/MultiLanguage/TyMLang/Functions/SymbolicMathToolbox/Mathematics/ilaplace.html)<!-- | [kroneckerDelta]() | [laplace]() | [ztrans]()-->

