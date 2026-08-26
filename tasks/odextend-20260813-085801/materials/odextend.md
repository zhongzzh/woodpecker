# odextend
---
扩展 ODE 的解

<h2>函数库: TyMath</h2>

## 语法 
<!-- DOC_CHECK:FUNCTION -->
[solext = odextend(sol,odefun,tfinal)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#f1)

[solext = odextend(sol,[],tfinal)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#f2)

[solext = odextend(sol,odefun,tfinal,y0)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#f3)

[solext = odextend(sol,odefun,tfinal,y0,options)](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#f4)

## 说明

<div id="f1" class="jump-target"></div>

[solext](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#solext) = odextend([sol](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#sol),[odefun](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#odefun),[tfinal](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#tfinal))扩展解 sol，其方式是使用创建 sol 的同一个 ODE 求解器，对 odefun 求从 sol.x[end] 至 [tfinal] 的积分。函数 odefun 可能不同于用于计算 sol 的原始函数。solext 中自变量的下界与 sol 中一致，即 sol.x[1]。默认情况下，odextend 使用：

+ 后续积分的初始条件 y = sol.y[:,end]。

+ ODE 求解器原本用来计算 sol 的相同的积分属性和额外输入参数。此信息存储在解结构体 sol 中，之后返回到 solext 中。除非您要更改这些值，否则不必将其传递给 odextend。[示例](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#eg1)

---

<div id="f2" class="jump-target"></div>

[solext](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#solext) = odextend([sol](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#sol),[],[tfinal](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#tfinal))将解扩展为用于求取 sol 的同一 ODE 函数。

---

<div id="f3" class="jump-target"></div>

[solext](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#solext) = odextend([sol](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#sol),[odefun](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#odefun),[tfinal](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#tfinal),[y0](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#y0))为扩展的积分指定新的初始条件 y0，而不是使用 sol.y[:,end]。

对于 ode15i 求解器：y0 必须是一个 m×2 矩阵 y0 = [yinit ypinit]，其中包含解分量及其导数的初始条件列向量。

---

<div id="f4" class="jump-target"></div>

[solext](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#solext) = odextend([sol](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#sol),[odefun](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#odefun),[tfinal](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#tfinal),[y0](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#y0),[options](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend.html#options))使用由 options（使用 odeset 函数创建的参数）定义的积分选项。指定的选项将覆盖 ODE 求解器原来计算 sol 所用的选项。您可以选择指定 y0 = [] 使用默认的初始条件。

## 示例

<div id="eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>计算和扩展解结构体</summary>
</details>
<div class="details-content">

van der Pol 方程为二阶 ODE

${y_1}'' - μ(1-{y_1}^2){y_1}' + y_1 = 0$

使用 ode45 以及 $μ=1$ 解算 van der Pol 方程。函数 vdp1 随 Syslab 一起提供，用于对方程进行编码。指定单个输出以返回包含解信息（如求解器和计算点）的结构体。

```julia
using TyMath
using TyPlot
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

使用 LinRange 在区间 [0 20] 内生成 250 个点。使用 deval 计算在这些点上的解。

```julia
x = LinRange(0,20,250);
y, = deval(sol,x);
```

绘制解的第一个分量。

```julia
plot(x,y[1,:])
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend/odextend_1.svg')">

使用 odextend 将解扩展到 $t_f=35$，并将结果添加到原始图中。

```julia
sol_new = odextend(sol,vdp1,35);
x = LinRange(20, 35, 350);
y, = deval(sol_new,x);
hold("on")
plot(x,y[1,:],"r")
```

<img :src="$withBase('/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/odextend/odextend_2.svg')">

</div>
</div>

## 输入参数

<div id="sol" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>sol — 解结构体<div>结构体</div></summary>
</details>
<div class="details-content">

解结构体，指定为由 ODE 求解器返回的结构体。当调用带有单个输出参数的 ODE 求解器时，它会返回解结构体。

**示例：** sol = ode45(myode,tspan,y0;output_sol=true)

**数据类型：** OdeSol

</div>
</div>

<div id="odefun" class="jump-target"></div>
<div class="details-box">
  <details open>
  <summary>odefun — 要求解的函数<div>[] | Function</div></summary>
  </details>
  <div class="details-content">

要解算的函数，指定为函数句柄。使用此输入可通过新的或修改后的 ODE 函数扩展解。要继续使用原来创建解结构体 sol 所用的 ODE 函数，请将 odefun 指定为空输入 []。

**数据类型：** Function

</div>
</div>

<div id="tfinal" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>tfinal — 最终积分时间<div>标量</div></summary>
</details>
<div class="details-content">

最终积分时间，指定为标量。

**数据类型：**  Int | Float

</div>
</div>

<div id="y0" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>y0 — 初始条件<div>[] | 标量 | 向量 | 矩阵</div></summary>
</details>
<div class="details-content">

初始条件，指定为标量、向量或矩阵。默认情况下，odextend 使用初始条件 y = sol.y[:,end] 来扩展积分。使用此输入为扩展积分指定新的初始条件。

对于 ode15i 求解器：y0 必须是一个 m×2 矩阵 y0 = [yinit ypinit]，其中包含解分量及其导数的初始条件列向量。

**数据类型：**  Int | Float

</div>
</div>

<div id="options" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>options - options 结构体<div>OdeOption</div></summary>
</details>
<div class="details-content">

odptions 结构体。默认情况下，odextend 使用的选项和附加输入与 ODE 求解器原来用于计算 sol 的相同。使用此输入指定新的 options 结构体，以覆盖用来创建 sol 的选项。

使用 [odeset](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeset.html) 函数创建或修改 ODE options 结构体。

**数据类型：**  OdeOption

</div>
</div>

## 输出参数

<div id="solext" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>solext — 扩展的解<div>结构体</div></summary>
</details>
<div class="details-content">

扩展的解，以结构体形式返回。此结构体与 [deval](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/deval.html) 函数一起使用，用于计算区间 [t0 tf] 内任何点的解。solext 结构体数组始终包括下列字段：

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

## 另请参阅

[odeget](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeget.html) | [odeset](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/Get-SetOptions/odeset.html) | [deval](/Doc/TyMath/DifferentialEquations/OrdinaryDifferentialEquations/EvaluateandExtendSolution/deval.html)