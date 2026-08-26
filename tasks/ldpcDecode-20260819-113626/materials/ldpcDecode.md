# ldpcDecode
---
二进制 LDPC 码解码

<h2>函数库: TyCommunication</h2>


## 语法
```julia
y, actualnumiter, finalparitychecks = ldpcDecode(llr, decodercfg, maxnumiter)
y, actualnumiter, finalparitychecks = ldpcDecode(llr, decodercfg, maxnumiter; Name=Value)
```
## 说明

ldpcDecode 函数使用四种算法中的一种对输入码字进行解码。LDPC 码是线性错误控制码，具有稀疏的校验矩阵和较长的块长度，性能接近香农极限。
***
[y](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#bcdc38ff), [actualnumiter](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#d00b11c2), [finalparitychecks](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#x2a398c85) = ldpcDecode([llr](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#a1971440), [decodercfg](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#x508b8494), [maxnumiter](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#x34e7fee8)) 使用输入的 ldpcDecoderConfig 配置对象 decodercfg 指定的 LDPC 矩阵，对输入的对数似然比（LLR）llr 进行解码。正 LLR 表示相应的比特更可能是 0。在输入 maxnumiter 指定的最大迭代次数内，当所有奇偶校验都满足要求时，解码结束。LDPC 码是线性误差控制码，具有稀疏的奇偶校验矩阵和较长的块长度，可达到接近香农极限的性能。
***
[y](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#bcdc38ff), [actualnumiter](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#d00b11c2), [finalparitychecks](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#x2a398c85) = ldpcDecode([llr](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#a1971440), [decodercfg](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#x508b8494), [maxnumiter](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecode.html#x34e7fee8); Name=Value) 使用一个或多个名值参数指定选项。例如，DecisionType="soft" 指定软决策解码并输出 LLR。



## 示例

<div id="解码速率3/4LDPC码字" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>解码速率 3/4 LDPC 码字</summary>
</details>
<div class="details-content" >

初始化原型矩阵和块大小的参数，以配置 IEEE® 802.11 规定的速率 3/4 LDPC 代码。使用 ldpcQuasiCyclicMatrix 函数创建奇偶校验矩阵。

```julia
using TyCommunication
using TyMath

P = [
    16 17 22 24 9 3 14 -1 4 2 7 -1 26 -1 2 -1 21 -1 1 0 -1 -1 -1 -1
    25 12 12 3 3 26 6 21 -1 15 22 -1 15 -1 4 -1 -1 16 -1 0 0 -1 -1 -1
    25 18 26 16 22 23 9 -1 0 -1 4 -1 4 -1 8 23 11 -1 -1 -1 0 0 -1 -1
    9 7 0 1 17 -1 -1 7 3 -1 3 23 -1 16 -1 -1 21 -1 0 -1 -1 0 0 -1
    24 5 26 7 1 -1 -1 15 24 15 -1 8 -1 13 -1 13 -1 11 -1 -1 -1 -1 0 0
    2 2 19 14 24 1 15 19 -1 21 -1 2 -1 24 -1 3 -1 2 1 -1 -1 -1 -1 0
]
blockSize = 27
pcmatrix = ldpcQuasiCyclicMatrix(blockSize, P)
```

创建 LDPC 编码器和解码器配置对象，显示其属性。

```julia
cfgLDPCEnc = ldpcEncoderConfig(pcmatrix)
```

```dataframe
cfgLDPCEnc = ldpcEncoderConfig — 属性 :
         ParityCheckMatrix :[162 x 648 SparseMatrixCSC{Int64, Int64}]
     Read-only properties:
               BlockLength :648
        NumInformationBits :486
        NumParityCheckBits :162
                  CodeRate :0.75
```

```julia
cfgLDPCDec = ldpcDecoderConfig(pcmatrix)
```

```dataframe
cfgLDPCDec = ldpcDecoderConfig — 属性 :
         ParityCheckMatrix :[162 x 648 SparseMatrixCSC{Int64, Int64}]
         Algorithm :bp
     Read-only properties:
               BlockLength :648
        NumInformationBits :486
        NumParityCheckBits :162
                  CodeRate :0.75
```

通过 AWGN 信道传输 LDPC 编码、QPSK 调制的比特流。解调信号，解码接收到的编码字，然后计算比特误差。使用嵌套 for 循环处理多个 SNR 设置和帧，对传输数据进行 LDPC 前向纠错 (FEC) 编码和不进行 LDPC 前向纠错 (FEC) 编码。

```julia
M = 4
maxnumiter = 10
snr = [3 6 20]
numframes = 10

ber = comm_ErrorRate()
ber2 = comm_ErrorRate()

for ii in 1:length(snr)
    errStats = zeros(1, 3)
    errStatsNoCoding = zeros(1, 3)
    for counter in 1:numframes
        rng = MT19937ar(1234)
        data = Int8.(randi(rng, (0, 1), cfgLDPCEnc.NumInformationBits, 1))
        # Transmit and receive with LDPC coding
        encodedData = ldpcEncode(data, cfgLDPCEnc)
        modSignal = pskmod(encodedData, M; InputType="bit")
        rxsig, noisevar = awgn(rng, modSignal, snr[ii]; nargout=2)
        demodSignal = pskdemod(rxsig, M; OutputType="approxllr", NoiseVariance=noisevar)
        rxbits, a, b = ldpcDecode(demodSignal, cfgLDPCDec, maxnumiter)
        errStats = step(ber, data, rxbits)
        #Transmit and receive with no LDPC coding
        noCoding = pskmod(data, M; InputType="bit")
        rxNoCoding = awgn(rng, noCoding, snr[ii])
        rxBitsNoCoding = pskdemod(rxNoCoding, M; OutputType="bit")
        errStatsNoCoding = step(ber2, data, Int8.(rxBitsNoCoding))
    end

    println(
        "SNR = $(snr[ii])\n  Coded: Error rate = $(errStats[1]), Number of errors =$(errStats[2])\n",
    )
    println(
        "Noncoded: Error rate = $(errStatsNoCoding[1]), Number of errors =$(errStatsNoCoding[2])\n",
    )
    
    reset(ber)
    reset(ber2)
end
```

```dataframe
SNR = 3
  Coded: Error rate = 0.10699588477366255, Number of errors =520.0

Noncoded: Error rate = 0.04526748971193416, Number of errors =220.0

SNR = 6
  Coded: Error rate = 0.0, Number of errors =0.0

Noncoded: Error rate = 0.01440329218106996, Number of errors =70.0

SNR = 20
  Coded: Error rate = 0.0, Number of errors =0.0

Noncoded: Error rate = 0.0, Number of errors =0.0
```


</div>
</div>

## 输入参数

<div id="a1971440" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>llr - 对数似然比<div>矩阵</div></summary>
</details>
<div class="details-content">

对数似然比矩阵，行数等于输入解码器的 BlockLength 属性。llr 的每一列对应一个编码词。该函数对每一列进行独立解码。正的 LLR 表示相应的比特更可能是 0。

</div>
</div>


<div id="x508b8494" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>decodercfg - LDPC 解码器配置<div>ldpcDecoderConfig 对象</div></summary>
</details>
<div class="details-content">

LDPC 解码器配置，指定为 ldpcDecoderConfig 对象。

</div>
</div>


<div id="x34e7fee8" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>maxnumiter - 解码迭代的最大次数<div>正标量</div></summary>
</details>
<div class="details-content">

解码迭代的最大次数，指定为正标量。

</div>
</div>


### 名称-值参数

以 Name1=Value1,...,NameN=ValueN 的形式指定可选的参数对，其中 Name 是参数名，Value 是相应的值。名称-值参数必须出现在其他参数之后，但参数对的顺序并不重要。

**示例：** Termination="max"

<div id="OutputFormat-输出格式" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>OutputFormat - 输出格式<div>"info"（默认） | "whole"</div></summary>
</details>
<div class="details-content">

输出格式，指定为这些值之一：

* "info" - 仅输出解码后的信息比特。函数输出的行数等于输入 decodercfg 的 NumInformationBitsproperty；

* "whole" - 输出所有已解码的 LDPC 码字位，包括信息位和奇偶校验位。函数输出的行数等于输入 decodercfg 的 BlockLength 属性。

</div>
</div>


<div id="DecisionType-决策类型" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>DecisionType - 决策类型<div>"hard"（默认） | "soft"</div></summary>
</details>
<div class="details-content">

LDPC 解码的判定类型，指定为以下值之一：

* "hard" - 执行硬解码，并以 int8 数据类型输出解码比特；

* "soft" - 执行软判定解码，输出与输入数据类型相同的 LLR。

</div>
</div>


<div id="MinSumScalingFactor-归一化最小和解码算法的缩放因子" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>MinSumScalingFactor - 归一化最小和解码算法的缩放因子<div>0.75（默认） | 范围为 (0, 1) 的标量</div></summary>
</details>
<div class="details-content">

归一化最小和解码算法的缩放因子，指定为 (0, 1] 范围内的标量。

**依赖关系**

要启用此属性，请将输入 decodercfg 的算法属性设置为 "norm-min-sum"。

</div>
</div>


<div id="MinSumOffset-最小和解码算法的偏移量" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>MinSumOffset - 最小和解码算法的偏移量<div>0.5（默认） | 标量</div></summary>
</details>
<div class="details-content">

最小和解码算法的偏移量，以标量形式指定。

**依赖关系**

要启用此属性，请将输入 decodercfg 的算法属性设置为 "offset-min-sum"。

</div>
</div>


<div id="Termination-解码终止标准" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Termination - 解码终止标准<div>"early"（默认） | "max"</div></summary>
</details>
<div class="details-content">

解码终止标准，指定为其中一个值：

* early" - 当所有奇偶校验都满足要求时终止解码迭代，最大迭代次数由输入的 maxnumiter 指定；

* "max" - 当最大迭代次数，maxnumiter，完成时终止解码。

</div>
</div>


<div id="Multithreaded-启用多线程执行" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>Multithreaded - 启用多线程执行<div>true（默认） | false</div></summary>
</details>
<div class="details-content">

启用多线程执行，指定为 true 或 false。在解释模式下运行并将此参数设置为 true 时，函数将使用多线程执行解码算法。

:::tip 提示

对于大型奇偶校验矩阵，多线程执行可大大减少 LDPC 解码的处理时间。

:::

**依赖关系**

要启用此属性，请在解释模式下运行。

</div>
</div>




## 输出参数

<div id="bcdc38ff" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>y - 编码码字<div>矩阵</div></summary>
</details>
<div class="details-content">

已解码码字，以矩阵形式返回，其中 K 行代表 llr(1:K,:) 的解码比特。K 等于输入 decodercfg 的 NumInformationBits 属性。在解码操作中，llr 的每一列对应一个编码词。函数对每一列进行独立解码。OutputFormat 名称-值参数指定输出是包含解码后的信息比特（默认）还是整个 LDPC 码元比特。DecisionType 名称-值参数指定并决定解码判定类型和输出的数据类型。

</div>
</div>


<div id="d00b11c2" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>actualnumiter - 解码迭代的实际次数<div>行向量</div></summary>
</details>
<div class="details-content">

解码迭代的实际次数，以行向量形式返回。如果一个码元的所有奇偶校验都满足要求，解码可以在达到最大迭代次数 maxnumiter 之前停止。此输出是一个行向量，表示函数对码字执行的实际迭代次数。

</div>
</div>


<div id="x2a398c85" class="jump-target"></div>
<div class="details-box">
<details open>
<summary>finalparitychecks - 每个码字的最终奇偶校验<div>矩阵</div></summary>
</details>
<div class="details-content">

每个码元的最终奇偶校验，以矩阵形式返回，行数等于输入 decodercfg 的 ParityCheckBits 属性。对于解码操作，该输出的每一列都是相应码元的最终奇偶校验。

</div>
</div>



## 参考文献

[1] IEEE Std 802.11™-2016 (Revision of IEEE Std 802.11-2012). "Part 11: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications." IEEE Standard for Information technology — Telecommunications and information exchange between systems. Local and metropolitan area networks — Specific requirements.

[2] Gallager, Robert G. Low-Density Parity-Check Codes. Cambridge, MA: MIT Press, 1963.

[3] Hocevar, D.E. "A reduced complexity decoder architecture via layered decoding of LDPC codes." In IEEE Workshop on Signal Processing Systems, 2004. SIPS 2004. doi: 10.1109/SIPS.2004.1363033

[4] Chen, Jinghu, R.M. Tanner, C. Jones, and Yan Li. "Improved min-sum decoding algorithms for irregular LDPC codes." In Proceedings. International Symposium on Information Theory, 2005. ISIT 2005. doi: 10.1109/ISIT.2005.1523374

## 另请参阅

<!-- Functions
ldpcEncode | ldpcQuasiCyclicMatrix | dvbs2ldpc
Objects
ldpcDecoderConfig | ldpcEncoderConfig | comm.gpu.LDPCDecoder -->

### 函数

[ldpcQuasiCyclicMatrix](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcQuasiCyclicMatrix.html) | [dvbs2ldpc](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/dvbs2ldpc.html)

### 对象

[ldpcEncoderConfig](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcEncoderConfig.html) | [ldpcDecoderConfig](/Doc/TyCommunication/PHYComponents/ErrorDetectionAndCorrection/ldpcDecoderConfig.html)