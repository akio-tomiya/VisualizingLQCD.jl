PDF=VisualizingLQCD_improvement_report_v7.pdf
TEX=main.tex

all: $(PDF)

$(PDF): $(TEX)
	latexmk -r .latexmkrc -pdfdvi $(TEX)
	cp main.pdf $(PDF)

clean:
	latexmk -C -r .latexmkrc $(TEX)
	rm -f *.aux *.bbl *.blg *.dvi *.fls *.fdb_latexmk *.log *.out *.toc *.xdv *.synctex.gz main.pdf

.PHONY: all clean
