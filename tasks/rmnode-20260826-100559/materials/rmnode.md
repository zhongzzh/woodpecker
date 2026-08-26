# rmnode
---
从图中删除节点

<h2>函数库: TyMath</h2>

## 语法

```julia
H = rmnode(G,nodeIDs)
rmnode!(G, nodeIDs)
```

## 说明

[H](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_outp1) = rmnode([G](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_inp1), [nodeID](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_inp2)) 从图 G 中删除 nodeIDs 指定的节点。与 nodeIDs 中的节点相连的任何边也将删除。rmnode 会更新 H 中节点的编号，这样，如果您删除了节点 k，则节点 1:k-1 在 H 中具有相同的节点编号，并且 G 中的节点 k+1:numnodes(G) 成为 H 中的 k:numnodes(H)。[示例](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_eg1)

---

rmnode!([G](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_inp1), [nodeID](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_inp2)) 直接在图 G 中原地删除 nodeIDs 指定的节点。[示例](/Doc/TyMath/TyGraphTheory/Modify/rmnode.html#jump_eg2)

## 示例

<div id="jump_eg1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>确定命名节点的索引</summary>
</details>
<div class="details-content">

创建一个图。

```julia
using TyMath
s = [1, 1, 1, 2, 2, 3];
t = [2, 3, 4, 3, 4, 4];
G = Graph(s, t);
```

从图中删除节点 1。新图中的节点会自动重新编号。

```julia
H = rmnode(G,1);
```

 </div>
</div>

<div id="jump_eg2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>从图中删除若干命名节点</summary>
</details>
<div class="details-content">

创建一个具有命名节点的图。

```julia
using TyMath
s = [1, 1, 1, 1, 2, 2, 3, 3, 3, 5, 5];
t = [2, 3, 4, 6, 1, 5, 4, 5, 6, 4, 6];
names = ["New York", "Los Angeles", "Washington D.C.", "Pittsburgh", "Denver", "Austin"];
G = DiGraph(s, t, Float64[], names);
```

从该图中删除节点 "New York" 和 "Pittsburgh"。

```julia
rmnode!(G,["New York","Pittsburgh"]);
```

 </div>
</div>

## 输入参数

<div id="jump_inp1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>G - 输入图<div>Graph 对象 | DiGraph 对象</div></summary>
</details>
<div class="details-content">

输入图，指定为 Graph 或 DiGraph 对象。可使用 [Graph](/Doc/TyMath/TyGraphTheory/Construction/Graph.html) 创建一个无向图，或使用 [DiGraph](/Doc/TyMath/TyGraphTheory/Construction/DiGraph.html) 创建一个有向图。

**示例：** G = Graph(1,2)

**示例：** G = DiGraph([1,2],[2,3])

</div>
</div>

<div id="jump_inp2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>nodeID - 节点标识符<div>节点索引 | 节点名称</div></summary>
</details>
<div class="details-content">

节点标识符，指定为一个或多个节点索引或节点名称。

下表显示通过数值节点索引或节点名称引用一个或多个节点的不同方法。

<div class="table-responsive">
 <table class="table table-condensed">
  <colgroup>
   <col class="tcol1" width="33%">
   <col class="tcol2" width="33%">
   <col class="tcol3" width="33%">
  </colgroup>
  <thead>
   <tr>
    <th>形式</th>
    <th>单一节点</th>
    <th>多个节点</th>
   </tr>
  </thead>
  <tbody>
   <tr>
    <td>节点索引</td>
    <td>标量<br><strong>示例：</strong>1</td>
    <td>向量<br><strong>示例：</strong>[1,2,3]</td>
   </tr>
   <tr>
    <td>节点名称</td>
    <td>字符串标量<br><strong>示例：</strong>"A"</td>
    <td>字符串数组<br><strong>示例：</strong>["A","B","C"]</td>
   </tr>
  </tbody>
 </table>
</div>

* 示例： rmnode(G,[1,2]) 从图 G 中删除节点 1 和节点 2。

</div>
</div>

## 输出参数

<div id="jump_outp1" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>H - 输出图<div>Graph 对象 | DiGraph 对象</div></summary>
</details>
<div class="details-content">

输出图，以 [Graph](/Doc/TyMath/TyGraphTheory/Construction/Graph.html) 或 [DiGraph](/Doc/TyMath/TyGraphTheory/Construction/DiGraph.html) 对象形式返回。

  </div>
</div>

## 另请参阅

[numnodes](/Doc/TyMath/TyGraphTheory/Modify/numnodes.html)
| [findedge](/Doc/TyMath/TyGraphTheory/Modify/findedge.html)
| [Graph](/Doc/TyMath/TyGraphTheory/Construction/Graph.html)
| [DiGraph](/Doc/TyMath/TyGraphTheory/Construction/DiGraph.html)
