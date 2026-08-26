"""任务卡：一次分析的全部输入。

在线新增函数（D8）：任务名 + 代码 MR + 文档 MR。
在线性能优化（D23~D28）：任务名 + 代码 MR；文档从本地既有文档仓库读取。
本地材料支持三种方式：函数名 + 函数库名 + 源分支自动同步定位，沿用代码/文档路径，
以及按文件名检查 Markdown 中的代码与代码文件是否一致。
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

from . import config


FUNCTION_NAME_PATTERN = r"[A-Za-z_][A-Za-z0-9_!]*"
PERFORMANCE_OPTIMIZATION_RE = re.compile(
    r"(?:函数)?性能优化|函数优化", re.IGNORECASE
)


def is_performance_optimization_title(text: str) -> bool:
    """Return whether a task title describes an existing-function optimization."""
    return bool(PERFORMANCE_OPTIMIZATION_RE.search(text or ""))


def has_performance_optimization_marker(text: str) -> bool:
    """Return whether the title explicitly contains the performance marker.

    The marker controls the branch/baseline summary algorithm.  Keep this
    separate from task classification so aliases such as ``函数优化`` can
    still use existing-document input without opting into that algorithm.
    """
    return "性能优化" in (text or "")


def extract_function_name(text: str) -> str:
    """从函数名或完整提测标题中提取 ASCII 函数标识符。"""
    value = text.strip()
    if re.fullmatch(FUNCTION_NAME_PATTERN, value):
        return value
    patterns = (
        rf"新增\s*(?P<func>{FUNCTION_NAME_PATTERN})\s*函数",
        rf"(?P<func>{FUNCTION_NAME_PATTERN})\s*(?:函数)?\s*性能优化",
        rf"(?P<func>{FUNCTION_NAME_PATTERN})\s*函数优化",
        rf"函数(?:性能)?优化\s*(?P<func>{FUNCTION_NAME_PATTERN})\b",
        rf"性能优化\s*(?P<func>{FUNCTION_NAME_PATTERN})\b",
        rf"函数(?:名称)?\s*[：:]?\s*(?P<func>{FUNCTION_NAME_PATTERN})\b",
        rf"(?P<func>{FUNCTION_NAME_PATTERN})\s*函数",
    )
    for pattern in patterns:
        match = re.search(pattern, value, re.IGNORECASE)
        if match:
            return match.group("func")
    return ""


@dataclass
class TaskCard:
    """任务输入 + 自动推导的任务类型、函数名与仓库信息。"""

    name: str          # 任务名，如 "新增 polydiv 函数"
    code_mr: str = ""  # 在线模式的代码 MR 链接
    doc_mr: str = ""   # 新增函数必填；性能优化从本地既有文档仓库读取
    func: str = ""     # 函数名；缺省时从任务名解析
    input_mode: str = "remote"  # remote / local
    local_code: str = ""        # 代码/单测文件或其母目录
    local_doc: str = ""         # 文档文件或其母目录
    local_library: str = ""     # 本地仓库模式的函数库名，如 TyImageProcessing
    local_branch: str = ""      # 代码源分支；本地无函数文档时也作为文档同步分支
    compare_doc_code: bool = False  # 本地文件名模式：检查文档代码与代码文件一致性
    task_type: str = field(init=False)

    def __post_init__(self) -> None:
        self.input_mode = self.input_mode.strip().lower() or "remote"
        self.compare_doc_code = bool(self.compare_doc_code)
        if self.input_mode not in ("remote", "local"):
            raise ValueError(f"不支持的材料来源：{self.input_mode!r}（应为 remote/local）")
        if self.compare_doc_code and not self.is_local:
            raise ValueError("文档代码一致性检查仅支持本地材料")

        if is_performance_optimization_title(self.name):
            self.task_type = "performance_optimization"
        elif re.search(r"新增\s*[A-Za-z_][A-Za-z0-9_!]*\s*函数", self.name):
            self.task_type = "new_function"
        elif self.is_local:
            self.task_type = "local_analysis"
        elif "提测" in self.name and extract_function_name(self.name):
            self.task_type = "new_function"
        else:
            raise ValueError(
                "无法从任务名识别任务类型；当前支持新增函数、函数性能优化和包含函数名的提测标题："
                f"{self.name!r}"
            )

        if self.func:
            self.func = extract_function_name(self.func) or self.func.strip()
        if not self.func:
            self.func = extract_function_name(self.name)

        if not self.func and self.is_local:
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_!]*", self.name.strip()):
                self.func = self.name.strip()
            elif self.local_doc.strip() and Path(self.local_doc.strip()).suffix:
                self.func = Path(self.local_doc.strip()).stem
            elif self.local_code.strip() and Path(self.local_code.strip()).suffix:
                self.func = Path(self.local_code.strip()).stem

        if not self.func and self.compare_doc_code:
            # 文件名模式不把输入当函数名；内部仍保留一个稳定的报告目录标识。
            self.func = Path(self.name.strip()).stem or self.name.strip()

        if not self.func:
            raise ValueError(f"无法从任务名解析函数名，请显式提供 --func：{self.name!r}")
        if self.is_local:
            repository_mode = bool(self.local_branch.strip()) and not self.compare_doc_code
            if repository_mode:
                if not self.local_library.strip():
                    raise ValueError("本地材料模式必须提供函数库名称")
            else:
                if not self.local_code.strip():
                    raise ValueError("本地材料模式必须提供代码/单测文件或目录")
                if not self.local_doc.strip():
                    raise ValueError("本地材料模式必须提供文档文件或目录")
        elif not self.code_mr.strip():
            raise ValueError("在线模式必须提供代码 MR 链接")
        elif self.task_type == "new_function" and not self.doc_mr.strip():
            raise ValueError("新增函数任务必须提供文档 MR 链接；性能优化任务可不提供")

    @property
    def is_local(self) -> bool:
        return self.input_mode == "local"

    @property
    def uses_local_repositories(self) -> bool:
        """本地材料是否由函数库名和分支自动获取。"""
        return self.is_local and not self.compare_doc_code and bool(self.local_branch.strip())

    @property
    def is_performance_optimization(self) -> bool:
        return self.task_type == "performance_optimization"

    @property
    def uses_optimization_summary(self) -> bool:
        """Whether performance results use the branch/baseline summary text."""
        return has_performance_optimization_marker(self.name)

    @property
    def is_new_function(self) -> bool:
        return self.task_type == "new_function"

    @property
    def is_doc_code_consistency(self) -> bool:
        """本地 Markdown 与代码文件的一致性检查模式。"""
        return self.compare_doc_code

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
            if self.uses_local_repositories:
                return self.local_library.strip()
            path = Path(self.local_code)
            return path.name if path.suffix else path.resolve().name
        return self.code_project.rsplit("/", 1)[-1]

    @property
    def doc_repo_name(self) -> str:
        if self.is_local:
            if self.uses_local_repositories:
                return config.DOCS_REPO_NAME
            return Path(self.local_doc).name
        return self.doc_project.rsplit("/", 1)[-1]

    # ---- 产出目录 --------------------------------------------------------
    def make_output_dir(self) -> Path:
        out = config.TASKS_DIR / f"{self.func}-{datetime.now():%Y%m%d-%H%M%S}"
        out.mkdir(parents=True, exist_ok=True)
        return out
