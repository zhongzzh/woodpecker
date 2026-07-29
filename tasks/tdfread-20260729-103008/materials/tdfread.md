# tdfread
---
读取分隔文本文件并按列创建变量

<h2>函数库: TyStatistics</h2>

## 语法

```julia
tdfread(filename)
tdfread(filename, delimiter)
s = tdfread(filename; toworkspace=Val(false))
s = tdfread(filename, delimiter; toworkspace=Val(false))
```

## 说明

tdfread([filename](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_inp1)) 读取 filename 指定的制表符分隔文本文件。文件的第一行必须包含变量名称，其余各行包含对应的列值。默认情况下，tdfread 在 `Main` 中为每一列创建一个变量，显示导入变量的摘要，并返回 `nothing`。[示例](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_eg1)

如果一列中所有非空值都能计算为数值，则该列转换为数值向量，其中空字段转换为 `NaN`；否则该列返回为字符串向量。

---

tdfread([filename](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_inp1), [delimiter](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_inp2)) 使用 delimiter 指定的字段分隔符读取文件。

---

[s](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_oup1) = tdfread(filename, delimiter; [toworkspace](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_inp3)=Val(false)) 不在 `Main` 中创建变量，而是返回一个命名元组。命名元组的字段名称来自文件第一行的变量名称。[示例](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tdfread.html#jump_eg2)

## 示例

<div id="jump_eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>从文本文件创建工作区变量</summary>
</details>
<div class="details-content">

创建一个逗号分隔的数据文件。第一行包含变量名称。

```julia
using TyStatistics

temp_dir = mktempdir()
filename = joinpath(temp_dir, "sat2.dat")
write(
    filename,
    "Test,Gender,Score\n" *
    "Verbal,Male,470\n" *
    "Verbal,Female,530\n" *
    "Quantitative,Male,520\n" *
    "Quantitative,Female,480\n",
)
print(read(filename, String))
```

```dataframe
Test,Gender,Score
Verbal,Male,470
Verbal,Female,530
Quantitative,Male,520
Quantitative,Female,480
```

因为文件使用逗号分隔，所以将 `"comma"` 指定为分隔符。tdfread 在工作区中创建 `Gender`、`Score` 和 `Test` 变量。

```julia
tdfread(filename, "comma")
```

```dataframe
  Name    Size  Bytes  Type

  Gender  (4,)    124  Vector{String}
  Score   (4,)     32  Vector{Float64}
  Test    (4,)    140  Vector{String}
```

</div>
</div>

<div id="jump_eg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>将各列返回为命名元组</summary>
</details>
<div class="details-content">

将 `toworkspace` 指定为 `Val(false)`，使 tdfread 返回命名元组而不在 `Main` 中创建变量。

```julia
using TyStatistics

temp_dir = mktempdir()
filename = joinpath(temp_dir, "sat2.dat")
write(
    filename,
    "Test,Gender,Score\n" *
    "Verbal,Male,470\n" *
    "Verbal,Female,530\n" *
    "Quantitative,Male,520\n" *
    "Quantitative,Female,480\n",
)
s = tdfread(filename, ','; toworkspace=Val(false))
```

```dataframe
(Test = ["Verbal", "Verbal", "Quantitative", "Quantitative"],
 Gender = ["Male", "Female", "Male", "Female"],
 Score = [470.0, 530.0, 520.0, 480.0])
```

使用字段名称访问导入的列。

```julia
s.Score
```

```dataframe
4-element Vector{Float64}:
 470.0
 530.0
 520.0
 480.0
```

</div>
</div>

## 输入参数

<div id="jump_inp1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>filename — 文件名<div>字符串</div></summary>
</details>
<div class="details-content">

要读取的文件名，指定为字符串。filename 可以是当前目录中的文件名，也可以包含绝对路径或相对路径。

文件第一行中的字段用作变量名称。名称中的空白字符转换为下划线；不能直接作为 Julia 标识符的名称会转换为有效标识符；重复名称会添加数字后缀。

**数据类型**：AbstractString

</div>
</div>

<div id="jump_inp2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>delimiter — 字段分隔符<div>"tab"（默认） | 字符 | 字符串 | 符号</div></summary>
</details>
<div class="details-content">

字段分隔符，指定为字符、字符串或符号。可以直接指定分隔字符，也可以指定对应的名称。

| 分隔符 | 等效名称 | 说明 |
| --- | --- | --- |
| `'\t'` | `"tab"` | 制表符（默认） |
| `' '` | `"space"` | 空格 |
| `','` | `"comma"` | 逗号 |
| `';'` | `"semi"` | 分号 |
| `'|'` | `"bar"` | 垂直条 |

对于表中未列出的字符串，tdfread 使用字符串的第一个字符作为分隔符并显示警告。

**示例**：`','`、`"comma"`、`'\t'`、`"tab"`

**数据类型**：Char | String | Symbol

</div>
</div>

<div id="jump_inp3" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>toworkspace — 是否在工作区中创建变量<div>Val(true)（默认） | Val(false)</div></summary>
</details>
<div class="details-content">

是否在 `Main` 中为每一列创建变量：

- `Val(true)`：在 `Main` 中创建变量、显示变量摘要并返回 `nothing`。
- `Val(false)`：不创建工作区变量，将各列作为命名元组返回。

**数据类型**：Val{true} | Val{false}

</div>
</div>

## 输出参数

<div id="jump_oup1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>s — 导入的列<div>命名元组</div></summary>
</details>
<div class="details-content">

导入的列，返回为命名元组。仅当 `toworkspace=Val(false)` 时返回此输出。每个字段对应输入文件中的一列；字段值为数值向量或 `Vector{String}`。

只包含实数表达式的列返回 `Vector{Float64}`，包含复数表达式的列返回 `Vector{ComplexF64}`。数值列中的空字段返回为 `NaN`。

</div>
</div>

## 另请参阅

[tblread](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/tblread.html) | [caseread](/Doc/TyStatistics/DescripitiveStatisticsandVisualization/DescriptiveStatistics/TabulationandGroupData/caseread.html) | [readtable](/Doc/TyBase/DataTypes/Tables/readtable.html)
