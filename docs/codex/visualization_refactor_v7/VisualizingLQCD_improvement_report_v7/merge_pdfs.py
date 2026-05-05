from pathlib import Path
from PyPDF2 import PdfReader, PdfWriter
base = Path('/mnt/data/VisualizingLQCD_improvement_report_v5/VisualizingLQCD_improvement_report_v5.pdf')
appendix = Path('/mnt/data/VisualizingLQCD_improvement_report_v6/VisualizingLQCD_improvement_report_v6_appendix.pdf')
out = Path('/mnt/data/VisualizingLQCD_improvement_report_v6/VisualizingLQCD_improvement_report_v6.pdf')
writer = PdfWriter()
for path in [base, appendix]:
    reader = PdfReader(str(path))
    for page in reader.pages:
        writer.add_page(page)
# Metadata
writer.add_metadata({
    '/Title': 'VisualizingLQCD.jl 改良提案 v6',
    '/Author': 'OpenAI GPT-5.5 Pro',
    '/Subject': '現行コード構造と全関数I/Oを追加した改良提案',
})
with out.open('wb') as f:
    writer.write(f)
print(out)
