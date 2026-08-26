# ode45
---
求解非刚性微分方程 - 中阶方法

<h2>函数库: TyMath</h2> 

## 语法
<!-- DOC_CHECK:FUNCTION -->
[t,y, = ode45(odefun,tspan,y0)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#f1)

[t,y, = ode45(odefun,tspan,y0,options)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#f2)

[t,y,te,ye,ie = ode45(odefun,tspan,y0,options)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#f3)

[sol = ode45(___;output_sol=true)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#f4)

## 说明

<div id="f1" class="jump-target"></div>

[t](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#t),[y](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#y), = ode45([odefun](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#odefun),[tspan](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#tspan),[y0](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#y0))（其中 tspan = [t0 tf]）求微分方程组 $y′=f(t,y)$ 从 t0 到 tf 的积分，初始条件为 y0。解数组 y 中的每一行都与列向量 t 中返回的值相对应。

所有 ODE 求解器都可以解算 y′=f(t,y) 形式的方程组，或涉及质量矩阵 M(t,y)y′=f(t,y) 的问题。求解器都使用类似的语法。ode23s 求解器只能解算质量矩阵为常量的问题。ode15s 和 ode23t 可以解算具有奇异质量矩阵的问题，称为微分代数方程 (DAE)。使用 [odeset](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeset.html) 的 :mass 选项指定质量矩阵。

ode45 是一个通用型 ODE 求解器，是您解算大多数问题时的首选。[示例](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#eg1)

---

<div id="f2" class="jump-target"></div>

[t](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#t),[y](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#y), = ode45([odefun](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#odefun),[tspan](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#tspan),[y0](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#y0),[options](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#options)) 还使用由 options（使用 odeset 函数创建的参数）定义的积分设置。例如，使用 :abstol 和 :reltol 选项指定绝对误差容限和相对误差容限，或者使用 :mass 选项提供质量矩阵。[示例](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#eg5)

---

<div id="f3" class="jump-target"></div>

[t](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#t),[y](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#y),[te](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#te),[ye](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#ye),[ie](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#ie) = ode45([odefun](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#odefun),[tspan](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#tspan),[y0](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#y0),[options](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#options)) 还求 (t,y) 的函数（称为事件函数）在何处为零。在输出中，te 是事件的时间，ye 是事件发生时的解，ie 是触发的事件的索引。

对于每个事件函数，应指定积分是否在零点处终止以及过零方向是否重要。为此，请将 :events 属性设置为函数（例如 myEventFcn），并创建一个对应的函数： myEventFcn = (t,y) -> (value,isterminal,direction)。

---

<div id="f4" class="jump-target"></div>

[sol](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#sol) = ode45(___;output_sol=true) 返回一个结构体，您可以将该结构体与 deval 结合使用来计算区间 [t0 tf] 中任意点位置的解。您可以使用上述语法中的任何输入参数组合。[示例](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#eg6)



## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>具有一个解分量的 ODE</summary>
</details>
<div class="details-content">

在对求解器的调用中，可将只有一个解分量的简单 ODE 指定为匿名函数。该匿名函数必须同时接受两个输入 (t,y)，即使在该函数中一个输入未使用也是如此。

解算 ODE。

$y' = 2t$

指定时间区间 [0 5] 和初始条件 y0 = 0。

```julia
using TyMath
using TyPlot
tspan = [0 5];
y0 = 0;
t,y, = ode45((t,y)->2*t, tspan, y0);
```

对解绘图。

```julia
plot(t,y,"-o")
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45/ode45_1.svg')">

</div>
</div>

<div id="eg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>解算非刚性方程</summary>
</details>
<div class="details-content">

van der Pol 方程为二阶 ODE：

${y_1}'' - μ(1-{y_1}^2){y_1}' + y_1 = 0$

其中 $μ>0$ 为标量参数。通过执行 ${y_1}' = y_2$ 代换，将此方程重写为一阶 ODE 方程组。生成的一阶 ODE 方程组为：

${y_1}' = y_2$

${y_2}' = μ(1-{y_1}^2)y_2 - y_1$

函数 vdp1 代表使用 $μ=1$ 的 van der Pol 方程。变量 $y_1$ 和 $y_2$ 是二元素 $dydt$ 的项 y[1] 和 y[2]。

```julia
using TyMath
using TyPlot
function vdp1(t,y)
    dydt = [y[2]; (1-y[1]^2)*y[2]-y[1]]
    return dydt
end
```

使用 ode45 函数、时间区间 [0 20] 和初始值 [2 0] 来解算该 ODE。生成的输出即为时间点 t 的列向量和解数组 y。y 中的每一行都与 t 的相应行中返回的时间相对应。y 的第一列与 $y_1$ 相对应，第二列与 $y_2$ 相对应。

```julia
t,y, = ode45(vdp1,[0 20],[2; 0]);
```

绘制 $y_1$ 和 $y_2$ 的解对 t 的图。


```julia
plot(t,y[:,1],"-o",t,y[:,2],"-o")
title(raw"$Solution of van der Pol Equation (\mu = 1) with ode45$");
xlabel("Time t");
ylabel("Solution y");
legend(raw"$y_1$",raw"$y_2$")
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45/ode45_2.svg')">

</div>
</div>

<div id="eg3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>向 ODE 函数传递额外的参数</summary>
</details>
<div class="details-content">

ode45 仅适用于使用两个输入参数（t 和 y）的函数。但是，通过在函数外部定义参数并在指定函数句柄时传递这些参数，可以传入额外参数。

解算 ODE。

$y'' = \frac{A}{B}ty$

将该方程重写为一阶方程组可以得到：

${y_1}' = y_2$

${y_2}' = \frac{A}{B}t{y_1}$

此示例部函数 odefcn 将此方程组表示为接受四个输入参数（t、y、A 和 B）的函数。

```julia
using TyMath
using TyPlot
function odefcn(t, y, A, B)
    dydt = [y[2]; (A/B)*t.*y[1]]
    return dydt
end
```

使用 ode45 解算 ODE。指定函数句柄，使其将 A 和 B 的预定义值传递给 odefcn。

```julia
A = 1;
B = 2;
tspan = [0 5];
y0 = [0 0.01];
t,y, = ode45((t,y)->odefcn(t,y,A,B), tspan, y0);
```

绘制结果。

```julia
plot(t,y[:,1],"-o",t,y[:,2],"-.")
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45/ode45_3.svg')">

</div>
</div>

<div id="eg4" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>求解具有多个初始条件的 ODE</summary>
</details>
<div class="details-content">

对于只有一个方程的简单 ODE 方程组，可以将 y0 指定为一个包含多个初始条件的向量。此方法通过标量扩展创建一个由独立方程组成的方程组，每个初始值对应一个方程，ode45 求解该方程组以针对每个初始值生成结果。

创建一个匿名函数来表示方程 $f(t,y)=−2y+2 cos(t)sin(2t)$。该函数必须接受分别对应于 t 和 y 的两个输入。

```julia
using TyMath
using TyPlot
yprime = (t,y)->-2*y .+ 2*cos(t).*sin(2*t);
```

创建一个由范围 [−5, 5] 内的不同初始条件组成的向量。

```julia
y0 = -5:5;
```

使用 ode45 计算方程在时间区间 [0,3] 内针对每个初始条件的解。

```julia
tspan = [0 3];
t,y, = ode45(yprime,tspan,y0);
```

绘制结果。

```julia
plot(t,y)
grid("on")
xlabel("t")
ylabel("y")
title("Solutions of "*raw"$y'' = -2y + 2 cos(t)sin(2t), y(0) = -5,-4,...,4,5$")
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45/ode45_4.svg')">

此方法对于求解具有多个初始条件的简单 ODE 非常有用。然而，该方法也有一些折衷：

+ 您无法求解具有多个初始条件的方程组。该方法仅适用于求解一个具有多个初始条件的方程。

+ 求解器在每步选择的时间步基于方程组中需要采取最小步长的方程。这意味着求解器可以采取小步长来满足一个初始条件的方程，但其他方程如果单独求解的话将使用不同步长。尽管如此，同时针对多个初始条件进行求解通常比使用 for 循环分别求解方程更快。

</div>
</div>

<div id="eg5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>带有时间依赖项的 ODE</summary>
</details>
<div class="details-content">

请考虑以下带有时间依赖参数的 ODE：

$y'(t) + f(t)y(t) = g(t)$

初始条件为 $y_0 = 1$。函数 f(t) 由在时间 ft 时计算的 n×1 向量 f 定义。函数 g(t) 由在时间 gt 时计算的 m×1 向量 g 定义。

创建向量 f 和 g。

```julia
using TyMath
using TyPlot
ft = LinRange(0,5,25);
f = ft.^2 .- ft .- 3;

gt = LinRange(1, 6, 25);
g = 3*sin.(gt.-0.25);
```

编写名为 myode 的函数，该函数通过对 f 和 g 进行插值获取时间依赖项在指定时间的值。将函数保存到您当前的文件夹中，以运行示例的其余部分。

myode 函数接受额外的输入参数以计算每个时间步的 ODE，但 ode45 只使用前两个输入参数 t 和 y。

```julia
function myode(t,y,ft,f,gt,g)
    f = interp1(ft,f,t) 
    g = interp1(gt,g,t)
    dydt = -f.*y .+ g
    return dydt
end
```

使用 ode45 计算方程在时间区间 [1 5] 内的解。使用函数句柄指定函数，从而使 ode45 只使用 myode 的前两个输入参数。此外，使用 odeset 放宽误差阈值。

```julia
tspan = [1 5];
ic = 1;
opts = odeset(reltol=1e-2,abstol=1e-4);
t,y, = ode45((t,y)->myode(t,y,ft,f,gt,g), tspan, ic, opts);
```

绘制解 y 对时间点 t 的函数图。

```julia
plot(t,y)
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45/ode45_5.svg')">

</div>
</div>

<div id="eg6" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算和扩展解结构体</summary>
</details>
<div class="details-content">

van der Pol 方程为二阶 ODE：

${y_1}'' - μ(1-{y_1}^2){y_1}' + y_1 = 0$

使用 ode45 以及 $μ=1$ 解算 van der Pol 方程。函数 vdp1 随 Syslab 一起提供，用于对方程进行编码。指定单个输出以返回包含解信息（如求解器和计算点）的结构体。

```julia
using TyMath
function vdp1(t,y)
    dydt = [y[2]; (1-y[1]^2)*y[2]-y[1]]
    return dydt
end
```

```julia
tspan = [0 20];
y0 = [2 0];
sol = ode45(vdp1,tspan,y0,output_sol=true)
```

```dataframe
┌ Warning: output_sol传入Bool类型会导致函数类型不稳定，推荐使用ReturnTuple代替false，ReturnStruct代替true。
└ @ TyDifferentialEquation.__Internal__.OrdinaryDifferentialEquations.NonStiffSolver D:\数学库GitLab\TyDifferentialEquation.jl\src\ODEGeneral\utils.jl:369
 solver: ode45
extdata: TyDifferentialEquation.__Internal__.ExtData{TyDifferentialEquation.__Internal__.OrdinaryDifferentialEquations.NonStiffSolver.var"#1#2"{typeof(vdp1), Tuple{}}, Tuple{}}
      x: Matrix{Float64}
      y: Matrix{Float64}
  stats: TyDifferentialEquation.__Internal__.DDEStats
  idata: TyDifferentialEquation.__Internal__.OdeIdata{TyDifferentialEquation.__Internal__.Ode45}
```

</div>
</div>

<div id="eg7" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>y0 的类型需要和 odefun 函数返回类型保持一致</summary>
</details>
<div class="details-content">



```julia
using TyMath
odefun=(t,y)->1im*y
t,y, = ode45(odefun, [0,1], 1 + 0im);
```
我们看到当 odefun 的输出类型和 y0 相同时可以正常运行。

```julia
t,y, = ode45(odefun, [0,1], 1 );
```
```dataframe
ERROR: InexactError: Float64(0.9996875165527344 + 0.02499739956998698im)
```
当 odefun 的输出类型和 y0 不同时就会报错。

</div>
</div>

## 输入参数

<div id="odefun" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>odefun - 要求解的函数<div>函数</div></summary>
</details>
<div class="details-content">

要求解的函数，指定为指向待积分器的句柄。

对于标量 t 和列向量 y 来说，函数 odefun = (t,y) -> dydt 必须返回列向量 dydt，该列向量对应于 f(t,y)。odefun 必须同时接受输入参数 t 和 y，即使其中一个参数未在函数中使用也是如此。

例如，要解算 $y′=5y−3$，请使用此函数：

```julia
function odefun(t,y)
    return 5*y .- 3
end
```

对于方程组，odefun 的输出为向量。向量中的每个元素是一个方程的解。例如，要求解

${y_1}'=y_1 + 2y_2$

${y_2}'=3y_1 + 2y_2$

使用函数：

```julia
function odefun(t,y)
    dydt = [y[1]+2*y[2];3*y[1]+2*y[2]]
    return dydt
end
```

**示例：**  myFcn

**数据类型：**  Function

</div>
</div>

<div id="tspan" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>tspan - 积分区间<div>向量</div></summary>
</details>
<div class="details-content">

积分区间，指定为向量。至少，tspan 必须是指定初始时间和最终时间的二元素向量 [t0 tf]。要获取 t0 到 tf 之间的特定时间的解，请使用 [t0,t1,t2,...,tf] 形式的长向量。tspan 中的元素必须单调递增或单调递减。

求解器在初始时间 tspan[1] 施加由 y0 给出的初始条件，然后求 tspan[1] 到 tspan[end] 的积分：

+ 如果 tspan 有两个元素 [t0 tf]，求解器将返回在该区间内的每个内部积分步计算的解；

+ 如果 tspan 包含两个以上的元素，[t0,t1,t2,...,tf]，求解器将返回在给定点处计算的解。但是，求解器不会精确步进到 tspan 中指定的每个点。此时，求解器使用自己的内部积分步来计算解，然后在 tspan 中请求的各点处计算解。在指定点处生成的解与在每个内部积分步计算的解具有相同的准确度级别。

指定多个中间点对计算效率影响甚微，但对于大型系统可能会影响内存管理。

求解器使用 tspan 的值计算 InitialStep 和 MaxStep 的合适值：

+ 如果 tspan 包含多个中间点 [t0,t1,t2,...,tf]，则指定的点表示了问题的规模，这可能影响求解器使用的 :initialstep 的值。因此，根据您是将 tspan 指定为二元素向量还是包含中间点的向量，求解器获得的解可能有所不同；

+ tspan 中的初始值和最终值用于计算最大步长 :maxstep。因此，更改 tspan 中的初始值或最终值可能导致求解器使用不同步长序列，从而可能会更改解。

**示例：** [1 10]

**示例：**  [1 3 5 7 9 10]

**数据类型：**  Int | Float

</div>
</div>

<div id="y0" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>y0 - 初始条件<div>向量</div></summary>
</details>
<div class="details-content">

初始条件，指定为向量。y0 的长度必须与 odefun 的向量输出相同，使 y0 为 odefun 中定义的每个方程包含一个初始条件。

::: warning 注意 
y0 的类型需要和 odefun 函数返回类型保持一致。[示例](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#eg7)

:::

**数据类型：**  Int | Float

</div>
</div>

<div id="options" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>options - options 结构体<div>OdeOption</div></summary>
</details>
<div class="details-content">

options 结构体，指定为结构体数组。使用 [odeset](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeset.html) 函数创建或修改 options 结构体。


**示例：**  options = odeset(reltol=1e-5,stats=:on) 指定 1e-5 的相对误差容限、打开求解器统计信息的显示。

**数据类型：**  OdeOption

</div>
</div>

## 输出参数

<div id="t" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>t - 求值点<div>列向量</div></summary>
</details>
<div class="details-content">

计算点，以列向量形式返回。

+ 如果 tspan 包含两个元素 [t0 tf]，则 t 包含用于执行积分的内部计算点；

+ 如果 tspan 包含两个以上元素，则 t 与 tspan 相同。

**数据类型：**  Int | Float

</div>
</div>

<div id="y" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>y - 解<div>数组</div></summary>
</details>
<div class="details-content">

解，以数组形式返回。y 中的每一行都与 t 的相应行中返回的值处的解相对应。

**数据类型：**  Int | Float

</div>
</div>

<div id="te" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>te - 事件的时间<div>列向量</div></summary>
</details>
<div class="details-content">

事件的时间，以列向量形式返回。te 中的事件时间对应于 ye 中返回的解，而 ie 指定发生了哪个事件。

**数据类型：**  Int | Float

</div>
</div>

<div id="ye" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ye - 事件时间处的解<div>数组</div></summary>
</details>
<div class="details-content">

事件时间的解，以数组形式返回。te 中的事件时间对应于 ye 中返回的解，而 ie 指定发生了哪个事件。

**数据类型：**  Int | Float

</div>
</div>

<div id="ie" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ie - 触发的事件函数的索引<div>列向量</div></summary>
</details>
<div class="details-content">

触发的事件函数的索引，以列向量形式返回。te 中的事件时间对应于 ye 中返回的解，而 ie 指定发生了哪个事件。

**数据类型：**  Int 

</div>
</div>

<div id="sol" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sol - 用于计算的结构体<div>结构体</div></summary>
</details>
<div class="details-content">

用于计算的结构体，以结构体数组形式返回。

|结构体字段|说明|
|--|--|
|sol.x|求解器选择的步的行向量。|
|sol.y|解。每列 sol.y[:,i] 包含时间 sol.x[i] 处的解。|
|sol.solver|求解器名称。|

此外，如果指定了 odeset 的 :events 选项并且检测到事件，则 sol 的下列字段不为nothing：

|结构体字段|说明|
|--|--|
|sol.xe|事件发生的点。sol.xe[end] 包含终止事件（如果有）的确切点。|
|sol.ye|与 sol.xe 中的事件相对应的解。|
|sol.ie|:events 选项中指定的函数所返回的向量的索引。这些值指示求解器检测到的事件。|

  </div>
</div>

## 算法

ode45 基于显式 Runge-Kutta (4,5) 公式 Dormand-Prince 对。这是一种单步求解器 – 在计算 y(tn) 时，该求解器仅需要最靠近该时间点的前一时间点处的解 y(tn-1) [[1]](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#ref1), [[2]](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode45.html#ref2)。

## 参考文献

<div id="ref1" class="jump-target"></div>

[1] Dormand, J. R. and P. J. Prince, “A family of embedded Runge-Kutta formulae,” J. Comp. Appl. Math., Vol. 6, 1980, pp. 19–26.

<div id="ref2" class="jump-target"></div>

[2] Shampine, L. F. and M. W. Reichelt, “The MATLAB ODE Suite,” SIAM Journal on Scientific Computing, Vol. 18, 1997, pp. 1–22.

## 另请参阅

[ode23](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode23.html) | [ode78](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode78.html) | [ode89](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode89.html) | [ode113](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/NonStiffSolvers/ode113.html) | [ode15s](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/StiffSolvers/ode15s.html) | [odeset](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeset.html) | [odeget](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeget.html)