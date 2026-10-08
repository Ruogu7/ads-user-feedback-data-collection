from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Polygon


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / ".work" / "assets"
OUT.mkdir(parents=True, exist_ok=True)

plt.rcParams.update(
    {
        "font.sans-serif": ["Microsoft YaHei", "Noto Sans CJK SC", "SimHei", "DejaVu Sans"],
        "axes.unicode_minus": False,
        "figure.facecolor": "white",
        "axes.facecolor": "white",
        "axes.edgecolor": "#D7E0E8",
        "text.color": "#172033",
        "axes.labelcolor": "#5D6B7A",
        "xtick.color": "#667085",
        "ytick.color": "#667085",
    }
)


def save(fig: plt.Figure, name: str) -> None:
    fig.savefig(OUT / name, dpi=220, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def region_distribution() -> None:
    fig, ax = plt.subplots(figsize=(10, 5.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.axis("off")

    # Schematic silhouette only. It deliberately avoids representing official
    # administrative boundaries; the production note requires a standard map.
    outline = [
        (1.0, 4.2), (1.9, 5.1), (3.2, 5.4), (4.4, 5.0), (5.8, 5.2),
        (7.0, 4.6), (8.5, 4.2), (9.1, 3.4), (8.5, 2.7), (7.4, 2.3),
        (6.6, 1.4), (5.2, 1.0), (4.2, 1.4), (3.0, 1.3), (2.4, 2.2),
        (1.3, 2.7),
    ]
    ax.add_patch(Polygon(outline, closed=True, facecolor="#EAF4F8", edgecolor="#8EB9C7", linewidth=1.8))

    points = [
        (6.7, 4.4, "东北", 7676),
        (5.5, 4.1, "华北", 13420),
        (7.1, 3.3, "华东", 28360),
        (5.5, 3.0, "华中", 15120),
        (6.2, 2.0, "华南", 18970),
        (3.9, 2.3, "西南", 11650),
        (2.8, 3.8, "西北", 7290),
    ]
    max_value = max(v for _, _, _, v in points)
    for x, y, label, value in points:
        size = 650 + 1900 * value / max_value
        ax.scatter([x], [y], s=size, color="#1B718E", alpha=0.86, edgecolor="white", linewidth=2.2)
        ax.text(x, y + 0.08, label, ha="center", va="center", color="white", fontsize=11, fontweight="bold")
        ax.text(x, y - 0.2, f"{value:,}", ha="center", va="center", color="white", fontsize=8.5)

    ax.set_title("地域分布模拟", loc="left", fontsize=18, fontweight="bold", pad=10)
    ax.text(0, 5.72, "气泡面积代表有效答卷数量 · 数据仅用于界面和报告版式演示", fontsize=10.5, color="#667085")
    ax.text(0, 0.18, "注：本图为区域气泡示意，不表示行政边界；正式上线应接入带审图号的国家标准地图服务。", fontsize=9.2, color="#7A5260")
    save(fig, "figure_01_region_distribution.png")


def cumulative_trend() -> None:
    months = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月"]
    values = [3200, 8100, 15600, 24700, 36500, 49800, 64600, 79200, 93100, 102486]
    fig, ax = plt.subplots(figsize=(10, 4.8))
    ax.plot(months, values, color="#183B66", linewidth=3, marker="o", markersize=7, markerfacecolor="#16A3B6")
    ax.fill_between(range(len(months)), values, color="#16A3B6", alpha=0.12)
    ax.grid(axis="y", color="#E4EAF0", linewidth=0.8)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_title("月度累计记录模拟", loc="left", fontsize=18, fontweight="bold")
    ax.set_ylabel("累计答卷数量")
    ax.set_ylim(0, 112000)
    ax.text(9, values[-1] + 4000, f"{values[-1]:,}", ha="right", color="#183B66", fontweight="bold")
    fig.text(0.125, 0.02, "模拟数据，仅用于说明横轴按月、纵轴显示累计记录总数的呈现方式。", fontsize=9.5, color="#667085")
    save(fig, "figure_02_cumulative_trend.png")


def brand_ranking() -> None:
    brands = [f"品牌{i:02d}" for i in range(1, 26)]
    shares = [12.8, 10.9, 9.8, 8.7, 7.9, 7.2, 6.4, 5.8, 5.1, 4.6, 4.2, 3.8, 3.4, 3.0, 2.7, 2.4, 2.1, 1.9, 1.7, 1.5, 1.3, 1.1, 0.9, 0.7, 0.5]
    total = sum(shares)
    shares = [v * 100 / total for v in shares]
    fig, ax = plt.subplots(figsize=(11, 5.2))
    ax.plot(range(1, 26), shares, color="#1C668C", linewidth=2.6, marker="o", markersize=5)
    ax.fill_between(range(1, 26), shares, color="#5EC4CF", alpha=0.14)
    ax.set_xticks(range(1, 26), brands, rotation=55, ha="right", fontsize=8)
    ax.set_ylabel("答卷占比")
    ax.set_title("25 个主要品牌占比排序模拟", loc="left", fontsize=18, fontweight="bold")
    ax.grid(axis="y", color="#E4EAF0", linewidth=0.8)
    ax.spines[["top", "right"]].set_visible(False)
    fig.subplots_adjust(bottom=0.27)
    for idx in range(5):
        ax.text(idx + 1, shares[idx] + 0.25, f"{shares[idx]:.1f}%", ha="center", fontsize=8.5, color="#183B66")
    fig.text(0.125, 0.01, "品牌名称与比例均为模拟值；正式统计应按有效答卷去重、统一品牌字典后计算。", fontsize=9.5, color="#667085")
    save(fig, "figure_03_brand_ranking.png")


def er_diagram() -> None:
    fig, ax = plt.subplots(figsize=(13.5, 8.4))
    ax.set_xlim(0, 13.5)
    ax.set_ylim(0, 8.4)
    ax.axis("off")

    boxes = {
        "app_user": (0.5, 5.95, "账户与权限\napp_user\napp_role\napp_user_role", "#E8F0F8"),
        "survey": (4.0, 5.95, "问卷定义\nsurvey\nsurvey_version", "#E7F8FA"),
        "question": (7.3, 5.95, "题目结构\nsurvey_section\nsurvey_question\nquestion_option", "#E7F8FA"),
        "response": (4.0, 3.05, "匿名答卷\nsurvey_response\n5 个预留 VARCHAR 字段", "#FFF4D8"),
        "answer": (7.3, 3.05, "答案与事件\nsurvey_answer\nincident_detail", "#FFF4D8"),
        "contact": (10.4, 3.05, "分离保存\nfollowup_contact\n联系方式密文", "#FCEBEC"),
        "custom": (4.0, 0.35, "字段扩展\ncustom_field_definition\nresponse_custom_field", "#F0EBFA"),
        "ops": (8.2, 0.35, "运维审计\nexport_task\nadmin_audit_log", "#F0EBFA"),
    }

    coords = {}
    for key, (x, y, text, color) in boxes.items():
        width = 2.65 if key != "question" else 2.8
        height = 1.45
        coords[key] = (x, y, width, height)
        ax.add_patch(FancyBboxPatch((x, y), width, height, boxstyle="round,pad=0.03,rounding_size=0.12", facecolor=color, edgecolor="#8EA2B5", linewidth=1.4))
        ax.text(x + width / 2, y + height / 2, text, ha="center", va="center", fontsize=10.5, linespacing=1.45, fontweight="bold" if "\n" not in text else "normal")

    def center(key: str, side: str) -> tuple[float, float]:
        x, y, w, h = coords[key]
        if side == "left":
            return x, y + h / 2
        if side == "right":
            return x + w, y + h / 2
        if side == "top":
            return x + w / 2, y + h
        return x + w / 2, y

    def link(a: str, aside: str, b: str, bside: str, label: str = "") -> None:
        x1, y1 = center(a, aside)
        x2, y2 = center(b, bside)
        ax.annotate("", xy=(x2, y2), xytext=(x1, y1), arrowprops=dict(arrowstyle="-|>", color="#6B8094", lw=1.5, shrinkA=3, shrinkB=3, connectionstyle="arc3,rad=0"))
        if label:
            ax.text((x1 + x2) / 2, (y1 + y2) / 2 + 0.12, label, ha="center", va="center", fontsize=8.5, color="#5B6E7F", backgroundcolor="white")

    link("app_user", "right", "survey", "left", "创建与管理")
    link("survey", "right", "question", "left", "1 对多")
    link("survey", "bottom", "response", "top", "版本锁定")
    link("question", "bottom", "answer", "top", "题目引用")
    link("response", "right", "answer", "left", "1 对多")
    link("answer", "right", "contact", "left", "主答卷分离")
    link("response", "bottom", "custom", "top", "扩展值")
    link("answer", "bottom", "ops", "top", "导出与审计")

    ax.text(0.5, 8.05, "问卷调查系统数据库结构图", fontsize=20, fontweight="bold")
    ax.text(0.5, 7.62, "核心原则：版本化问卷、匿名主答卷、联系方式分表加密、管理员操作可审计", fontsize=11, color="#667085")
    ax.text(0.5, 0.08, "关系图为逻辑层示意；完整字段、索引、外键与校验约束见随附 MySQL 8 管理脚本。", fontsize=9.5, color="#667085")
    save(fig, "figure_04_database_er.png")


if __name__ == "__main__":
    region_distribution()
    cumulative_trend()
    brand_ranking()
    er_diagram()
    for path in sorted(OUT.glob("*.png")):
        print(f"{path.name}\t{path.stat().st_size}")

