# iztrans
---
Z 逆变换

<h2>函数库: TySymbolicMath</h2>

## 语法
<!-- DOC_CHECK:FUNCTION -->
[iztrans(F)](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#f1)

[iztrans(F,transVar)](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#f2)

[iztrans(F,var,transVar)](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#f3)

## 说明

<div id="f1" class="jump-target"></div>

iztrans([F](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#F)) 求 F 的逆 Z 变换。 返回 F 的逆 Z 变换。默认情况下，自变量为 z，变换变量为 n。 如果 F 不包含 z，则 iztrans 使用函数 symvar。[示例](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#exp1)

---
<div id="f2" class="jump-target"></div>

iztrans([F](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#F),[transVar](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#transVar)) 使用变换变量 transVar 而不是 n。[示例](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#exp2)

---
<div id="f3" class="jump-target"></div>

iztrans([F](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#F),[var](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#var),[transVar](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#transVar)) 分别使用自变量 var 和变换变量 transVar 代替 z 和 n。

## 示例

<div id="exp1" class="jump-target"></div>

**符号表达式的 Z 逆变换**

计算 2*z/(z-2)^2 的 Z 逆变换。 默认情况下，逆变换以 n 为单位。

```julia
using TySymbolicMath
@variables z
F = 2*z/(z-2)^2;
A = iztrans(F)
```

```dataframe
A = 2^n + (-1 + n)*(2^n)
```

<div id="exp2" class="jump-target"></div>

**指定自变量和变换变量**

计算 1/(a*z) 的 Z 逆变换。 默认情况下，自变量和变换变量分别为 z 和 n。

```julia
using TySymbolicMath
@variables z a
F = 1/(a*z);
iztrans(F)
```

```dataframe
TySymbolicMath.kroneckerDelta(-1 + n, 0) / a
```

将变换变量指定为 m。 如果仅指定一个变量，则该变量就是转换变量。 自变量仍然是 z。

```julia
@variables m
qq1 = iztrans(F,m)
```

```dataframe
qq1 =  TySymbolicMath.kroneckerDelta(-1 + m, 0) / a
```

在第二个和第三个参数中分别将自变量和变换变量指定为 a 和 m。

```julia
qq2 = iztrans(F,a,m)
```

```dataframe
TySymbolicMath.kroneckerDelta(-1 + m, 0) / z
```


</div>
</div>


## 输入参数

<div id="F" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>F - 输入<div>Num</div></summary>
</details>
<div class="details-content">

输入，指定为符号表达式、函数、向量或矩阵。

</div>
</div>

<div id="var" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>var - 自变量<div>x（默认） | 符号变量</div></summary>
</details>
<div class="details-content">

自变量，指定为符号变量、表达式、向量或矩阵。 该变量通常称为“复频率变量”。 如果您不指定变量，则 iztrans 使用 z。 如果 F 不包含 z，则 iztrans 使用函数 symvar。

</div>
</div>

<div id="transVar" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>transVar - 变换变量<div>x（默认） | t | Num</div></summary>
</details>
<div class="details-content">

变换变量，指定为符号变量、表达式、向量或矩阵。 它通常被称为“时间变量”或“空间变量”。 默认情况下，iztrans 使用 n。 如果 n 是 [F](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/iztrans.html#F) 的自变量，则 iztrans 使用 k。

</div>
</div>


## 提示

* 如果任何参数是数组，则 iztrans 对数组的所有元素按元素进行操作；

* 如果第一个参数包含符号函数，则第二个参数必须是标量；

* 要计算直接 Z 变换，请使用 ztrans。


## 另请参阅

[fourier](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/fourier.html) | [ifourier](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ifourier.html) | [ilaplace](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ilaplace.html) | [laplace](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/laplace.html) | [ztrans](/Doc/TySymbolicMath/SymbolicMath/Calculus/Transforms/ztrans.html)

