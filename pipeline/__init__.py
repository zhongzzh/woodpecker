"""woodpecker 管线：任务卡 → 取数 → 定位 → AI 覆盖分析 + 性能判定 → 报告。

硬约束（docs/02 D18）：对被测仓库严格只读。本包中 repo 模块只封装
clone/fetch/checkout/pull/stash，不存在任何 push/commit 能力。
"""
