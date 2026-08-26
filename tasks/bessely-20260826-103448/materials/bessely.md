# bessely

---

第二类 Bessel 函数

<h2>函数库: TyMath</h2>

## 语法

```julia
Y = bessely(nu,z)
Y = bessely(nu,z,scale)
```

## 说明

Y = bessely([nu](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#c9f62467),[z](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#a9693705)) 为 z 计算[第二类 Bessel 函数](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#x08e2f228) $Y_v(z)$。[示例](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#x31564474)

---

Y = bessely([nu](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#c9f62467),[z](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#a9693705),[scale](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#x559f8046)) 指定是否呈指数缩放[第二类 Bessel 函数](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#x08e2f228)以避免溢出或精度损失。如果 scale 为 1，则 bessely 的输出按因子 $exp(-abs(imag(z)))$ 进行缩放。[示例](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely.html#eg2)

## 示例

<div id="x31564474" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>绘制第二类 Bessel 函数图</summary>
</details>
<div class="details-content">

定义域。

```julia
using TyMath
using TyPlot
z = 0:0.1:20
```

计算前五个第二类 Bessel 函数。Y 的每一行包含在 z 中的点上计算的某阶函数的值。

```julia
Y = zeros(5,201)
for i = 0:4
Y[i+1,:] = bessely.(i,z)
end
```

在同一图窗中绘制所有函数。

```julia
hold("on")
for i = 1:5
plot(z,Y[i,:])
end
axis([-0.1 20.2 -2 0.6])
grid("on")
legend([raw"$Y_0$",raw"$Y_1$",raw"$Y_2$",raw"$Y_3$",raw"$Y_4$"])
title("v∈[0,4]的第二类Bessel函数")
xlabel("z")
ylabel(raw"$Y_v(z)$")
hold("off")
```

<img :src="$withBase('/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely/bessely1.svg')">

</div>
</div>



<div id="eg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算呈指数缩放的 Bessel 函数</summary>
</details>
<div class="details-content">

为 z 的复数值计算未缩放的 (Y) 和经过缩放的 (Ys) 第二类 Bessel 函数 $Y_2(Z)$。

```julia
using TyMath
using TyPlot
x = [-10:0.35:10...]'
y = x'
z = x .+ 1im * y
scale = 1
Y = bessely.(2, z)
Ys = bessely.(2, z, scale)
```

比较经过缩放的函数和未缩放函数的虚部图。对于 $abs(imag(z))$ 的大值，未缩放的函数很快上溢超出双精度的限制，不再可计算。经过缩放的函数从计算中消除了这种占主导状态的指数行为，因此与未缩放的函数相比，具有更大的可计算性范围。

```julia
X1,Y1 = meshgrid2(vec(collect(x)),y)
surf(X1,Y1,imag.(Y))
title("第二类bessel函数")
xlabel("real(z)")
ylabel("imag(z)")
```

<img :src="$withBase('/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely/bessely2.webp')">

```julia
surf(X1,Y1,imag.(Ys))
title("缩放的第二类bessel函数")
xlabel("real(z)")
ylabel("imag(z)")
```

<img :src="$withBase('/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/bessely/bessely3.webp')">

</div>
</div>



## 输入参数

<div id="c9f62467" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>nu - 方程的阶<div>标量 | 向量 | 矩阵 | N 维数组</div></summary>
</details>
<div class="details-content">

方程的阶，指定为标量、向量、矩阵或多维数组。nu 指定 Hankel 函数的阶。nu 和 x 的大小必须相同，或者其中一个可以为标量。

**示例：** bessely.(3,0:5)

**数据类型：** Int64 | Int32 | Int16 | Int128 | Float64 | Float32 | Float16 | UInt

</div>
</div>



<div id="a9693705" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>z - 函数的域<div>标量 | 向量 | 矩阵 | N 维数组</div></summary>
</details>
<div class="details-content">

函数的域，指定为标量、向量、矩阵或多维数组。nu 和 Z 的大小必须相同，或者其中一个可以为标量。

**示例：** bessely.(1,[1-1im 1+0im 1+1im])

**数据类型：** Int64 | Int32 | Int16 | Int128 | Float64 | Float32 | Float16 | UInt8 | UInt16 | UInt32 | UInt64 | UInt128 | Complex

**复数支持：** 是

</div>
</div>



<div id="x559f8046" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>scale - 切换到缩放函数<div>0（默认） | 1</div></summary>
</details>
<div class="details-content">

切换到缩放函数，指定为下列值之一：

+ 0（默认值） - 无缩放；
+ 1 - 按因子 $exp((-abs(z)))$ 缩放 bessely 的输出。

在复平面上，bessely 的模随着 $abs(imag(z))$ 的值增加而快速增长，因此呈指数缩放输出对于 abs(imag(z)) 的大值很有用；如果不这样处理，结果会很快损失精度或上溢超出双精度的限制。

**示例**：bessely.(3,0:5,1)

</div>
</div>


## 详细信息

<div id="x08e2f228" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Bessel 函数</summary>
</details>
<div class="details-content">

以下微分方程（其中 ν 是实数常量）称为 Bessel 方程：

$z^2\dfrac{d^2y}{dz^2} + z\dfrac{dy}{dz} + (z^2 - v^2)y = 0$

它的解称为 Bessel 函数。

第一类 Bessel 函数（表示为$J_v(z) \text{和} J_{-v}(z)$ ）构成非整数v的 Bessel 方程的一组基本解。$J_v(z)$ 通过以下方式定义：

$J_v(z) = (\dfrac{z}{2}) ^ v \sum\limits_{k = 0}^{\infty} \dfrac{(\dfrac{-z^2}{4})^k}{k!\Gamma(v+k+1)}$

您可以使用 [besselj](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/besselj.html) 计算第一类Bessel函数

第二类 Bessel 函数（表示为$Y_v(z)$）构成了 Bessel 方程的另一个解，与 $J_v(z)$ 线性无关。$Y_v(z)$ 通过以下方程定义：

$Y_v(z) = \dfrac{J_v(z)cos(v\pi) - J_{-v}(z)}{sin(v\pi)}$

</div>
</div>


## 提示

Bessel 函数与 Hankel 函数相关，也称为第三类 Bessel 函数，

$H_v^{(1)}(z) = J_v(z) + iY_v(z)$

$H_v^{(2)}(z) = J_v(z) - iY_v(z)$

$H_v^{(k)}(z)$ 是 besselh，$J_v(z)$是 bessely，$Y_v(z)$ 是 bessely。Hankel 函数同样构成 Bessel 方程的一组基本解（请参见 [besselh](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/besselh.html)）。

## 另请参阅

[besselh](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/besselh.html)
| [besseli](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/besseli.html)
| [besselj](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/besselj.html)
| [besselk](/Doc/TyMath/ElementaryMath/SpecialFunctions/BesselFunctions/besselk.html)
