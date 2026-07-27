"""任务卡：一次分析的全部输入。

在线新增函数（D8）：任务名 + 代码 MR + 文档 MR。
在线性能优化（D23~D28）：任务名 + 代码 MR；文档从本地既有文档仓库读取。
本地材料：任务名 + 本地代码/单测路径 + 本地文档路径；不访问 MR/Git。
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

from . import config


@dataclass
class TaskCard:
    """任务输入 + 自动推导的任务类型、函数名与仓库信息。"""

    name: str          # 任务名，如 "新增 polydiv 函数"
    code_mr: str = ""  # 在线模式的代码 MR 链接
    doc_mr: str = ""   # 新增函数必填；性能优化从本地既有文档仓库读取
    func: str = ""     # 函数名；缺省时从任务名解析
    input_mode: str = "remote"  # remote / local
    local_code: str = ""        # 本地代码/单测文件或目录
    local_doc: str = ""         # 本地文档文件
    task_type: str = field(init=False)

    def __post_init__(self) -> None:
        self.input_mode = self.input_mode.strip().lower() or "remote"
        if self.input_mode not in ("remote", "local"):
            raise ValueError(f"不支持的材料来源：{self.input_mode!r}（应为 remote/local）")

        if "性能优化" in self.name:
            self.task_type = "performance_optimization"
        elif re.search(r"新增\s*[A-Za-z_][A-Za-z0-9_!]*\s*函数", self.name):
            self.task_type = "new_function"
        elif self.is_local:
            self.task_type = "local_analysis"
        else:
            raise ValueError(
                "无法从任务名识别任务类型；当前支持“新增 xxx 函数”和“xxx 函数性能优化”："
                f"{self.name!r}"
            )

        if not self.func:
            # 完整周提测标题可能先出现库名，必须围绕任务关键词提取函数名，
            # 避免误把 TyDifferentialEquation 等库名当函数名。
            if self.task_type == "new_function":
                m = re.search(r"新增\s*([A-Za-z_][A-Za-z0-9_!]*)\s*函数", self.name)
            else:
                m = re.search(
                    r"([A-Za-z_][A-Za-z0-9_!]*)\s*函数?\s*性能优化", self.name
                )
            if m:
                self.func = m.group(1)

        if not self.func and self.is_local:
            if self.local_doc.strip():
                self.func = Path(self.local_doc.strip()).stem
            elif self.local_code.strip() and Path(self.local_code.strip()).suffix:
                self.func = Path(self.local_code.strip()).stem

        if not self.func:
            raise ValueError(f"无法从任务名解析函数名，请显式提供 --func：{self.name!r}")
        if self.is_local:
            if not self.local_code.strip():
                raise ValueError("本地材料模式必须提供代码/单测文件或目录")
            if not self.local_doc.strip():
                raise ValueError("本地材料模式必须提供文档文件")
        elif not self.code_mr.strip():
            raise ValueError("在线模式必须提供代码 MR 链接")
        elif self.task_type == "new_function" and not self.doc_mr.strip():
            raise ValueError("新增函数任务必须提供文档 MR 链接；性能优化任务可不提供")

    @property
    def is_local(self) -> bool:
        return self.input_mode == "local"

    @property
    def is_performance_optimization(self) -> bool:
        return self.task_type == "performance_optimization"

    @property
    def is_new_function(self) -> bool:
        return self.task_type == "new_function"

    # ---- 从 MR 链接推导 --------------------------------------------------
    @staticmethod
    def _project_path(mr_url: str) -> str:
        """https://host/<group>/<proj>/-/merge_requests/N → <group>/<proj>"""
        path = urlparse(mr_url).path
        if "/-/merge_requests/" not in path:
            raise ValueError(f"不是合法的 MR 链接：{mr_url}")
        return path.split("/-/merge_requests/")[0].strip("/")

    @property
    def code_project(self) -> str:
        if self.is_local:
            raise ValueError("本地材料模式没有代码 MR 项目")
        return self._project_path(self.code_mr)

    @property
    def doc_project(self) -> str:
        if self.is_local:
            raise ValueError("本地材料模式没有文档 MR 项目")
        if not self.doc_mr:
            return config.DOCS_REPO_PROJECT
        return self._project_path(self.doc_mr)

    @property
    def code_repo_name(self) -> str:
        """项目路径最后一段，即本地克隆目录名（如 TyMathCore.jl）。"""
        if self.is_local:
            path = Path(self.local_code)
            return path.name if path.suffix else path.resolve().name
        return self.code_project.rsplit("/", 1)[-1]

    @property
    def doc_repo_name(self) -> str:
        if self.is_local:
            return Path(self.local_doc).name
        return self.doc_project.rsplit("/", 1)[-1]

    # ---- 产出目录 --------------------------------------------------------
    def make_output_dir(self) -> Path:
        out = config.TASKS_DIR / f"{self.func}-{datetime.now():%Y%m%d-%H%M%S}"
        out.mkdir(parents=True, exist_ok=True)
        return out
