#!/usr/bin/env bash
set -euo pipefail
latexmk -r .latexmkrc -pdfdvi main.tex
cp main.pdf VisualizingLQCD_improvement_report_v7.pdf
