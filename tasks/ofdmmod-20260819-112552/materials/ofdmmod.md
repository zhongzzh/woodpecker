# ofdmmod
---
使用正交频分复用调制频域信号

<h2>函数库: TyCommunication</h2>



## 语法
```julia
ofdmSig = ofdmmod(inSym, nfft, cplen)
ofdmSig = ofdmmod(inSym, nfft, cplen, nullidx)
ofdmSig = ofdmmod(inSym, nfft, cplen, nullidx, pilotidx, pilots)
```

## 说明
[ofdmSig](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x44aab136)=ofdmmod([inSym](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x9deb01cb), [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098), [cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c)) 使用由 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098) 指定的 FFT 大小和由 [cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c) 指定的循环前缀长度，对频域输入数据子载波 [inSym](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x9deb01cb) 执行 [OFDM调制](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#b459444a)。有关详细信息，请参见[OFDM调制](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#b459444a)。

*****
[ofdmSig](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x44aab136)=ofdmmod([inSym](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x9deb01cb), [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098), [cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c), [nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5)) 在执行 [OFDM调制](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#b459444a) 之前，将空子载波插入到频域输入数据信号中。空子载波被插入到从 1 至 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098) 的索引位置处，由 [nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5) 指定。在此语法中，输入 [inSym](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x9deb01cb) 中的行数必须为 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)–length([nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5))。使用空载波来计算保护带和 DC 子载波。有关详细信息，请参见[子载波分配、保护频带和保护间隔](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x94ea1570)。

*****
[ofdmSig](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x44aab136)=ofdmmod([inSym](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x9deb01cb), [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098), [cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c), [nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5), [pilotidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x5795753d), [pilots](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#cb8d0a80)) 在执行 [OFDM调制](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#b459444a) 之前，将空和导频子载波插入到频域输入数据符号中。空子载波被插入到由 [nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5) 指定的索引位置处。导频子载波被插入到由 [pilotidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x5795753d) 指定的索引位置处。在此语法中，输入 [inSym](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x9deb01cb) 中的行数必须为[nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)–length([nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5))–length([pilotidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x5795753d))。该函数假设每个 OFDM 符号和发射天线的导频子载波位置相同。
[示例](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#f7294a3c)

## 示例

<div id="f7294a3c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>使用 OFDM 对 QPSK 信号进行调制</summary>
</details>
<div class="details-content">

```julia
using TyCommunication
using TyMath
rng = MT19937ar(1234)
nfft = 64
cplen = 16
nSym = 10
nullIdx = [1:6; 33; (64 - 4):64]
pilotIdx = [12, 26, 40, 54]
numDataCarrs = nfft - length(nullIdx) - length(pilotIdx)
dataIn = complex.(rand(rng, numDataCarrs, nSym), rand(rng, numDataCarrs, nSym))
pilots = repeat(pskmod(0:3, 4), 1, nSym)
y1 = ofdmmod(dataIn, nfft, cplen, nullIdx, pilotIdx, pilots)
```
```dataframe
y1 = 800×1 Matrix{ComplexF64}:
 -0.0035920552083258533 + 0.05767482472562613im
    0.10191094380955207 + 0.018085913554734677im
    0.04793400443119879 + 0.0346876050634579im
   -0.05284131278283773 + 0.024009951490491305im
   0.028441284709263638 - 0.07331178453203037im
   0.019997022707630333 - 0.042886909369422396im
                        ⋮
   0.006772744147504884 + 0.018737074939207794im
  -0.029824518661935296 + 0.07324505248891433im
    -0.0634429977439506 + 0.03632034748032531im
    0.04701729584572796 + 0.011569137024291807im
  -0.060582993442195573 - 0.16659198649520962im
    0.05410157850620686 + 0.08524503060301243im
```

  </div>
</div>


<div id="双天线OFDM调制" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>双天线 OFDM 调制</summary>
</details>
<div class="details-content">

将完全填充的输入通过两个发射天线进行 OFDM 调制。

初始化输入参数，生成随机数据，并执行 OFDM 调制。

```julia
using TyCommunication
using TyMath

rng = mt19937ar(5489)
nfft = 128
cplen = 16
nSym = 5
nt = 2
dataIn = complex.(randn(rng, nfft, nSym, nt), randn(rng, nfft, nSym, nt))

y1 = ofdmmod(dataIn, nfft, cplen)
```

```dataframe
y1 = 720×2 Matrix{ComplexF64}:
  0.0352134-0.104681im    -0.0404678-0.110088im
  -0.074193-0.00608088im   0.0640306+0.048841im
   0.198049-0.138684im     -0.159143+0.170702im
 -0.0277466+0.0773246im     0.109204+0.0811122im
  0.0161563+0.0710831im    0.0384327+0.0186888im
  -0.094474+0.0829262im     0.182989-0.0150121im
 -0.0369587+0.116678im     -0.071654+0.154917im
           ⋮
  0.0184413-0.00581332im   0.0106597-0.0393037im
 -0.0333602-0.0796215im   -0.0260914-0.0632237im
   0.101066+0.0249022im    -0.153844+0.0192972im
  0.0261679-0.0319655im      0.10652+0.101546im
  0.0966553+0.228319im     0.0552367+0.0141921im
 -0.0944979+0.221004im     -0.113709+0.0734353im
   0.102132-0.0576416im    -0.056282-0.205826im
```


  </div>
</div>



<div id="应用分配了空子载波的OFDM技术" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>应用分配了空子载波的 OFDM 技术</summary>
</details>
<div class="details-content">

应用 OFDM 调制，并分配为空子载波。

初始化输入参数并生成随机数据。

```julia
using TyCommunication
using TyMath

rng = mt19937ar(5489)
# 16QAM的调制阶数
M = 16
nfft = 64
cplen = 16
nSym = 10
nullIdx = [1:6; 33; (64 - 4):64]
numDataCarrs = nfft - length(nullIdx)
inSig = randi(rng, [0 M - 1], numDataCarrs, nSym)
```

对数据进行 QAM 调制。执行 OFDM 调制。

```julia
qamSym = qammod(inSig, M; UnitAveragePower=true)
outSig = ofdmmod(qamSym, nfft, cplen, nullIdx)
```

```dataframe
outSig = 800×1 Matrix{ComplexF64}:
  -0.10870329456828803 + 0.04941058844013093im
 -0.004941178018993984 + 0.07580281694186236im
   0.06861343860767222 + 0.02466276808664472im
   -0.1244936912063154 - 0.0405261157139469im
   0.05781652689588219 - 0.07666516121027711im
   0.08235092542315475 + 0.1569506593977588im
  -0.08761620916804938 + 0.2664525874537986im
                       ⋮
 0.0006532394858120606 + 0.05121256096151565im
  -0.06986913408583305 + 0.20087178415055484im
  -0.11337098000572922 - 0.09935421983430064im
   0.10010262241987826 - 0.26306345733805403im
  0.026013927864852186 + 0.033162563942699654im
  -0.02310253395550789 + 0.04048437727331649im
   0.18631823064733827 - 0.04568611161249919im
```

  </div>
</div>




<div id="执行每个符号循环前缀可变的OFDM调制" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>执行每个符号循环前缀可变的 OFDM 调制</summary>
</details>
<div class="details-content">

对输入频域数据信号执行 OFDM 调制，改变应用于每个符号的循环前缀长度。

初始化输入参数并生成随机数据。

```julia
using TyCommunication
using TyMath

rng = mt19937ar(5489)
# 调制阶数
M = 16
nfft = 64
cplen = [4 8 10 7 2 2 4 11 16 3]
nSym = 10
nullIdx = [1:6; 33; (64 - 4):64]'
numDataCarrs = nfft - length(nullIdx)
inSig = randi(rng, [0 M - 1], numDataCarrs, nSym)
```

对数据进行 QAM 调制。执行 OFDM 调制。

```julia
qamSym = qammod(inSig, M; UnitAveragePower=true)
outSig = ofdmmod(qamSym, nfft, cplen, nullIdx)
```

```dataframe
outSig = 707×1 Matrix{ComplexF64}:
   -0.0747200514111619 + 0.0288744730491094im
   0.10678404710287015 - 0.06822668818039233im
   0.09632465854181722 + 0.04838277742353422im
   0.07671773704107757 + 0.024767636157549178im
   0.03952847075210474 - 0.09882117688026185im
  -0.08530321775467817 - 0.03336597247597121im
  0.024256363367339315 - 0.07871804151614417im
                       ⋮
 0.0006532394858120606 + 0.05121256096151565im
  -0.06986913408583305 + 0.20087178415055484im
  -0.11337098000572922 - 0.09935421983430064im
   0.10010262241987826 - 0.26306345733805403im
  0.026013927864852186 + 0.033162563942699654im
  -0.02310253395550789 + 0.04048437727331649im
   0.18631823064733827 - 0.04568611161249919im
```

  </div>
</div>



## 输入参数
<div id="x9deb01cb" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>inSym - 输入数据子载波<div>3 维数组</div></summary>
</details>
<div class="details-content">

输入数据子载波，指定为 $N_D$×$N_{Sym}$×$N_T$ 符号数组。数据子载波数 $N_D$ 必须等于 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)–length([nullidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x285e4ad5))–length([pilotidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x5795753d))。$N_{Sym}$ 是每个发射天线的 OFDM 符号数，$N_T$ 是发射天线的数量。

OFDM 调制器的输入数据符号通常由基带数字调制器创建，例如 [qammod](/Doc/TyCommunication/PHYComponents/Modulation/qammod.html)。

**数据类型：** Float64

**复数支持：** 是

  </div>
</div>
<div id="x0ef55098" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>nfft - FFT 长度<div>大于或等于8的整数</div></summary>
</details>
<div class="details-content">

FFT 长度，指定为大于或等于 8 的整数。nfft 相当于调制过程中使用的子载波数。

**数据类型：** Int64

  </div>
</div>
<div id="e4246e7c" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>cplen - 循环前缀长度<div>标量 | 长度为Nsym的行向量</div></summary>
</details>
<div class="details-content">

循环前缀长度，指定为标量或长度为 $N_{Sym}$ 的行向量。

- 当将 cplen 指定为标量时，通过所有天线的所有符号的循环前缀长度都相同；

- 当将 cplen 指定为长度为 $N_{Sym}$ 的行向量时，循环前缀长度可以因符号而异，但通过所有天线保持相同的长度。

有关详细信息，请参见[子载波分配、保护频带和保护间隔](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x94ea1570)。

**数据类型：** Int64

  </div>
</div>
<div id="x285e4ad5" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>nullidx - 空子载波位置的索引<div>向量</div></summary>
</details>
<div class="details-content">

空子载波位置的索引，指定为元素值从 1 到 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098) 的向量。

**数据类型：** Int64

  </div>
</div>
<div id="x5795753d" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>pilotidx - 导频子载波位置的索引<div>列向量</div></summary>
</details>
<div class="details-content">

导频子载波位置的索引，指定为元素值从 1 到 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098) 的列向量。

**数据类型：** Int64

  </div>
</div>
<div id="cb8d0a80" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>pilots - 导频子载波<div>3维数组</div></summary>
</details>
<div class="details-content">

导频子载波，指定为 $N_{Pilot}$×$N_{Sym}$×$N_T$ 符号数组。$N_{Pilot}$ 必须等于 [pilotidx](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x5795753d) 的长度。$N_{Sym}$ 是每个发射天线的 OFDM 符号数。$N_T$ 是发射天线的数量。该函数假设导频子载波位置在每个 OFDM 符号和发射天线上是相同的。使用 comm_OFDMModulator 可以跨 OFDM 符号或天线改变导频子载波位置。

**数据类型：** Float64

  </div>
</div>

## 输出参数
<div id="x44aab136" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>ofdmSig - 调制的 OFDM 符号<div>复数符号的二维数组</div></summary>
</details>
<div class="details-content">

调制的 OFDM 符号，以复数符号的二维数组形式返回。

- 如果 [cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c) 是标量，则数组大小为 (([nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)+[cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c))×$N_{Sym}$)×$N_T$；

- 如果 [cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c) 是行向量，则数组大小为 (([nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)×$N_{Sym}$)+sum([cplen](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#e4246e7c)))×$N_T$。其中，$N_{Sym}$ 是每个发射天线的符号数，$N_T$ 是发射天线的数量。

**数据类型：** Float64

**复数支持：** 是

  </div>
</div>

## 详细信息
<div id="b459444a" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>OFDM 调制</summary>
</details>
<div class="details-content">

OFDM 属于多载波调制方案类。由于可以使用多个载波同时传输多个数据流，因此 OFDM 不会像单载波调制一样受到噪声的影响。

OFDM 操作通过将传输频带分解为 N 个连续的单独调制子载波，将高速率数据流划分为较低数据速率的子流。多个平行和正交的子载波以几乎与宽带信道相同的带宽承载样本。通过使用窄正交子载波，OFDM 信号在频率选择性衰落信道上获得了鲁棒性，并消除了相邻子载波干扰。因为较低数据速率子流的符号持续时间大于信道延迟扩展，所以降低了符号间干扰 (ISI)。

OFDM 波形中正交子载波的频域表示如下图所示：

<img :src="$withBase('/TyCommunication/PHYComponents/Modulation/ofdmmod/image1.webp')">

发射机一次对 N 个符号应用快速傅里叶逆变换 (IFFT)。IFFT 的输出是 N 个正交正弦波的总和：

$x(t)=\sum_{k=0}^{N-1} X_{k} e^{j 2 \pi k \Delta f t}, \quad 0 \leq t \leq T$

其中 {$X_k$} 是数据符号，T 是 OFDM 符号时间。数据符号 $X_k$ 通常很复杂，可以来自任何数字调制字母表（例如 QPSK、16-QAM、64-QAM）。

子载波间隔为 Δf=1/T，确保子载波在每个符号周期内都是正交的，如下所示：

$\frac{1}{T} \int_{0}^{T}\left(e^{j 2 \pi m \Delta f t}\right)^{*}\left(e^{j 2 \pi n \Delta f t}\right) d t=\frac{1}{T} \int_{0}^{T} e^{j 2 \pi(m-n) \Delta f t} d t=0 \quad \text { for } m \neq n$

OFDM 调制器由串并联转换和一组 N 个复调制器组成，分别对应于每一个 OFDM 子载波。

<img :src="$withBase('/TyCommunication/PHYComponents/Modulation/ofdmmod/image4.png')">

  </div>
</div>
<div id="x94ea1570" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>子载波分配、保护频带和保护间隔</summary>
</details>
<div class="details-content">

单独的 OFDM 子载波被分配为数据、导频或空子载波。

如下图所示，子载波被指定为数据、DC、导频或保护带子载波。

<img :src="$withBase('/TyCommunication/PHYComponents/Modulation/ofdmmod/image5.png')">

- 数据子载波传输用户数据；

- 导频子载波用于信道估计；

- 空子载波不传输数据。没有数据的子载波用于提供 DC 空值并用作 OFDM 资源块之间的缓冲区；

- 如果 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098) 是偶数，则空 DC 子载波是频带的中心，索引值为 ([nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)/2+1)，如果 [nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098) 是奇数，则为 (([nfft](/Doc/TyCommunication/PHYComponents/Modulation/ofdmmod.html#x0ef55098)+1)/2)；

- 保护带在连续的 OFDM 符号之间提供缓冲区，以通过减少符号间干扰来保护传输信号的完整性。

空子载波使用户能够针对特定标准（例如 802.11格式、LTE、WiMAX 或自定义分配）对保护带和 DC 子载波位置进行建模。用户可以通过分配空子载波索引向量来分配空值的位置。

在 OFDM 中，保护间隔与保护频带相似，通过减少码间干扰来保护传输信号的完整性。

保护间隔的分配类似于保护带的分配。用户可以对保护间隔进行建模以提供 OFDM 符号之间的时间间隔。保护间隔有助于在信号通过时间色散信道后保持符号间正交性。保护间隔是通过使用循环前缀创建的。循环前缀插入将 OFDM 符号的最后部分复制为 OFDM 符号的第一部分。

<img :src="$withBase('/TyCommunication/PHYComponents/Modulation/ofdmmod/image6.png')" style="width:300px;">

只要时间分散的跨度不超过循环前缀的持续时间，循环前缀插入的优势就保持不变。

因为循环前缀占用了可用于数据传输的带宽，所以插入循环前缀会导致用户数据吞吐量的部分减少。



  </div>
</div>

## 另请参阅
 [ofdmdemod](/Doc/TyCommunication/PHYComponents/Modulation/ofdmdemod.html) | [qammod](/Doc/TyCommunication/PHYComponents/Modulation/qammod.html) | [genqammod](/Doc/TyCommunication/PHYComponents/Modulation/genqammod.html)
