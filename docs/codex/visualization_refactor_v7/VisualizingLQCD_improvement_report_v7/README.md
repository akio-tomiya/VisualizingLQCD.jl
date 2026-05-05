# VisualizingLQCD.jl improvement report v7

This directory contains a Japanese LaTeX report and a small code skeleton for a refined improvement plan for `VisualizingLQCD.jl`. Version 7 expands the current-code inventory with call graphs, local-variable tables, external dependency maps, failure modes, result contracts, proposed signatures, and metadata fields that can already be written out from the current implementation.

## Build

```bash
make
```

or

```bash
./build.sh
```

The build uses `uplatex` and `dvipdfmx`. The generated PDF is `VisualizingLQCD_improvement_report_v7.pdf`. A Dockerfile using `texlive/texlive:latest` is included as a reproducible build sketch.

## Contents

- `main.tex`: LaTeX source, including the v7 chapters on current code structure, function I/O, local variables, dependency maps, validation, result contracts, and metadata.
- `references.bib`: BibTeX reference notes for convenience.
- `Makefile`, `.latexmkrc`, `build.sh`: local build files.
- `Dockerfile`: reproducible build environment sketch.
- `VisualizingLQCD_improvement_report_v7.pdf`: generated PDF copy.
- `code_skeleton/`: non-production Julia design skeleton showing module boundaries and current-code reference defaults.
- `patch_notes/`: PR-oriented implementation notes, including magic-number and current-code-structure reference memos.
