---
name: paddleocr-scanning
description: Use this skill for OCR, screenshot scanning, table extraction, document image parsing, or replacing Tesseract/other OCR tools with PaddleOCR. It checks whether an NVIDIA GPU is available, recommends PaddleOCR when GPU acceleration is present, and sets up PaddleOCR for future OCR tasks when the user accepts.
compatibility: Requires Python, uv, network access for Python packages and PaddleOCR model downloads, and optionally NVIDIA GPU drivers/CUDA for accelerated OCR.
allowed-tools: bash view apply_patch ask_user
---

# PaddleOCR Scanning

Use this skill when the user asks to extract text, tables, forms, screenshots, scanned PDFs, document images, or compare/replace OCR tools. PaddleOCR is especially useful for table/document structure extraction because PP-Structure can preserve tables as HTML, Markdown, XLSX, DOCX, and JSON instead of returning only flattened text.

## Workflow

1. Check whether an NVIDIA GPU is available.
2. If a GPU is available, recommend PaddleOCR over Tesseract and other simple OCR tools for document/table extraction.
3. Ask whether the user accepts using PaddleOCR.
4. If the user accepts, set up PaddleOCR in the project and use it for OCR tasks that could otherwise be handled by substitute OCR tools.
5. If the user declines, use the user-preferred OCR tool or the simplest available fallback.

## 1. Check GPU availability

Run:

```bash
command -v nvidia-smi >/dev/null && nvidia-smi || true
```

Interpretation:

- GPU available: `nvidia-smi` exists and lists one or more NVIDIA GPUs.
- GPU not available: `nvidia-smi` is missing, fails, or reports no devices.

If more detail is needed, check Python/Paddle visibility after installation:

```bash
python - <<'PY'
try:
    import paddle
    print("Paddle version:", paddle.__version__)
    print("CUDA available:", paddle.device.is_compiled_with_cuda())
except Exception as exc:
    print("Paddle not ready:", exc)
PY
```

## 2. Recommend PaddleOCR when GPU is available

When an NVIDIA GPU is available, tell the user that PaddleOCR is recommended for OCR/table scanning because:

- It can use GPU acceleration.
- It performs better on structured documents than plain OCR.
- PP-Structure can detect layouts and preserve table structure.
- It can export structured results such as Markdown, HTML, XLSX, DOCX, images, and JSON.

Use concise wording:

> An NVIDIA GPU is available, so I recommend PaddleOCR for this OCR task. It is stronger than Tesseract for structured screenshots and tables because it can preserve layout and export table files. Should I set it up and use PaddleOCR for OCR tasks here?

Ask the user before setup, because PaddleOCR may download large packages and models.

## 3. Set up PaddleOCR if accepted

Prefer `uv` and corporate-network TLS support when available:

```bash
uv --native-tls venv
uv --native-tls sync
```

If no `pyproject.toml` exists, create one like this for CPU by default:

```toml
[project]
name = "ocr-workspace"
version = "0.1.0"
description = "Local OCR workspace using PaddleOCR."
requires-python = ">=3.10,<3.13"
dependencies = [
    "paddleocr[all]>=3.0.0",
    "paddlepaddle==3.2.0",
    "pillow>=10.0.0",
]

[tool.uv]
package = false

[[tool.uv.index]]
name = "paddle-cpu"
url = "https://www.paddlepaddle.org.cn/packages/stable/cpu/"
explicit = true

[tool.uv.sources]
paddlepaddle = { index = "paddle-cpu" }
```

For GPU setups, use the PaddlePaddle wheel that matches the machine CUDA version. Example for CUDA 11.8:

```bash
uv --native-tls pip install "paddlepaddle-gpu==3.2.0" \
  -i https://www.paddlepaddle.org.cn/packages/stable/cu118/
```

Do not guess the CUDA version. If it is unclear, inspect `nvidia-smi` output and ask the user before installing a GPU wheel.

## 4. Use PaddleOCR for OCR tasks

For document/table screenshots, prefer PP-Structure:

```bash
.venv/bin/paddleocr pp_structurev3 \
  -i INPUT_IMAGE_OR_PDF \
  --use_doc_orientation_classify False \
  --use_doc_unwarping False \
  --save_path OUTPUT_DIR
```

Typical outputs include:

- `*.md` for Markdown-like structured output
- `*_table_*.html` for detected tables
- `*_table_*.xlsx` for spreadsheet tables
- `*_res.json` for structured OCR/layout data
- `*_layout_det_res.png` and related images for visual validation

For plain OCR only:

```bash
.venv/bin/paddleocr ocr \
  -i INPUT_IMAGE \
  --use_doc_orientation_classify False \
  --use_doc_unwarping False \
  --use_textline_orientation False
```

## 5. Compare or fall back when needed

If PaddleOCR is unavailable, too slow, blocked by downloads, or declined by the user, use a fallback such as Tesseract:

```bash
tesseract INPUT_IMAGE stdout -l eng --psm 4
```

When comparing PaddleOCR against Tesseract:

- Use the same input image.
- Save raw outputs separately.
- Compare structure preservation, text accuracy, table columns/rows, and export formats.
- Prefer PaddleOCR when table/layout structure matters.
- Prefer Tesseract only for quick lightweight text extraction when layout is unimportant.

## Common edge cases

- First PaddleOCR run can be slow because models may download.
- Corporate networks may require `uv --native-tls`.
- GPU installation depends on CUDA version; do not install a random GPU wheel.
- Low-resolution screenshots may still need manual cleanup even with PaddleOCR.
- PaddleOCR table output may preserve structure well but still need small spacing or placeholder corrections.
