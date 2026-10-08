"""Run the bundled DOCX renderer while using PyMuPDF for PDF rasterization.

The bundled renderer imports ``pdf2image`` (and therefore Poppler).  This
workspace already provides PyMuPDF, so this wrapper injects a compatible
two-function shim and then executes the bundled renderer unchanged.
"""

from __future__ import annotations

import os
import runpy
import sys
import types
from pathlib import Path

import pymupdf


WORKSPACE = Path(__file__).resolve().parents[1]
LIBREOFFICE_BIN = WORKSPACE / ".work" / "qa" / "libreoffice" / "program"
BUNDLED_RENDERER = Path(
    r"C:\Users\Laptop\.codex\plugins\cache\openai-primary-runtime\documents"
    r"\26.1007.11041\skills\documents\render_docx.py"
)


def pdfinfo_from_path(pdf_path: str, *args, **kwargs) -> dict[str, object]:
    with pymupdf.open(pdf_path) as document:
        if document.page_count == 0:
            raise RuntimeError("PDF has no pages")
        rect = document[0].rect
        return {
            "Pages": document.page_count,
            "Page size": f"{rect.width:g} x {rect.height:g} pts",
        }


def convert_from_path(
    pdf_path: str,
    *,
    dpi: int = 150,
    fmt: str = "png",
    output_folder: str | None = None,
    paths_only: bool = False,
    output_file: str = "page",
    **kwargs,
):
    if fmt.lower() != "png":
        raise ValueError("This shim supports PNG output only")
    if not paths_only:
        raise ValueError("This shim supports paths_only=True only")

    destination = Path(output_folder or ".").resolve()
    destination.mkdir(parents=True, exist_ok=True)
    scale = dpi / 72.0
    matrix = pymupdf.Matrix(scale, scale)
    rendered: list[str] = []

    with pymupdf.open(pdf_path) as document:
        for page_number, page in enumerate(document, start=1):
            pixmap = page.get_pixmap(matrix=matrix, alpha=False)
            output_path = destination / f"{output_file}0001-{page_number:02d}.png"
            pixmap.save(output_path)
            rendered.append(str(output_path))

    return rendered


def main() -> None:
    if not (LIBREOFFICE_BIN / "soffice.exe").exists():
        raise FileNotFoundError(LIBREOFFICE_BIN / "soffice.exe")
    if not BUNDLED_RENDERER.exists():
        raise FileNotFoundError(BUNDLED_RENDERER)

    os.environ["PATH"] = str(LIBREOFFICE_BIN) + os.pathsep + os.environ.get("PATH", "")
    shim = types.ModuleType("pdf2image")
    shim.convert_from_path = convert_from_path
    shim.pdfinfo_from_path = pdfinfo_from_path
    sys.modules["pdf2image"] = shim
    runpy.run_path(str(BUNDLED_RENDERER), run_name="__main__")


if __name__ == "__main__":
    main()
