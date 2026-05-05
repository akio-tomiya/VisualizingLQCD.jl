from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfgen.canvas import Canvas
from pathlib import Path

OUT = Path('VisualizingLQCD_improvement_report_v6_appendix.pdf')

pdfmetrics.registerFont(UnicodeCIDFont('HeiseiKakuGo-W5'))
pdfmetrics.registerFont(UnicodeCIDFont('HeiseiMin-W3'))

PAGE_W, PAGE_H = A4

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    name='JPTitle', fontName='HeiseiKakuGo-W5', fontSize=20, leading=26,
    alignment=TA_CENTER, spaceAfter=10, textColor=colors.HexColor('#23527c'), wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPSubtitle', fontName='HeiseiMin-W3', fontSize=12.5, leading=18,
    alignment=TA_CENTER, spaceAfter=20, textColor=colors.HexColor('#444444'), wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPH1', fontName='HeiseiKakuGo-W5', fontSize=15, leading=20,
    spaceBefore=12, spaceAfter=7, textColor=colors.HexColor('#23527c'), wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPH2', fontName='HeiseiKakuGo-W5', fontSize=12.5, leading=17,
    spaceBefore=9, spaceAfter=5, textColor=colors.HexColor('#683471'), wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPBody', fontName='HeiseiMin-W3', fontSize=9.7, leading=15.0,
    spaceAfter=5, wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPBodySmall', fontName='HeiseiMin-W3', fontSize=8.3, leading=12.2,
    spaceAfter=3, wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPTableHead', fontName='HeiseiKakuGo-W5', fontSize=8.2, leading=11.0,
    alignment=TA_CENTER, textColor=colors.white, wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPTable', fontName='HeiseiMin-W3', fontSize=7.2, leading=9.8,
    wordWrap='CJK'))
styles.add(ParagraphStyle(
    name='JPCode', fontName='Courier', fontSize=7.3, leading=9.2,
    leftIndent=5, rightIndent=5, backColor=colors.HexColor('#f8f8f8'), wordWrap='LTR'))
styles.add(ParagraphStyle(
    name='Note', fontName='HeiseiMin-W3', fontSize=8.8, leading=13.2,
    leftIndent=5, rightIndent=5, borderColor=colors.HexColor('#90a568'), borderWidth=0.7,
    borderPadding=5, backColor=colors.HexColor('#f1f7e8'), wordWrap='CJK'))


def P(text, style='JPBody'):
    return Paragraph(text, styles[style])


def code(text):
    # Escape XML special chars, preserve line breaks.
    text = text.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
    return Paragraph(text.replace('\n','<br/>'), styles['JPCode'])


def table(rows, widths, header=True, font_size=None):
    data = []
    for r_i, row in enumerate(rows):
        style = 'JPTableHead' if header and r_i == 0 else 'JPTable'
        data.append([P(str(cell), style) for cell in row])
    t = Table(data, colWidths=widths, repeatRows=1 if header else 0, hAlign='LEFT')
    ts = [
        ('GRID', (0,0), (-1,-1), 0.35, colors.HexColor('#b9b9b9')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 4),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ]
    if header:
        ts += [('BACKGROUND', (0,0), (-1,0), colors.HexColor('#23527c'))]
    for i in range(1 if header else 0, len(rows)):
        if i % 2 == 0:
            ts.append(('BACKGROUND', (0,i), (-1,i), colors.HexColor('#f7f7f7')))
    t.setStyle(TableStyle(ts))
    return t


def footer(canvas: Canvas, doc):
    canvas.saveState()
    canvas.setFont('HeiseiMin-W3', 8)
    canvas.setFillColor(colors.HexColor('#666666'))
    canvas.drawString(20*mm, 12*mm, 'VisualizingLQCD.jl 改良提案 v6 追補')
    canvas.drawRightString(PAGE_W-20*mm, 12*mm, f'{doc.page}')
    canvas.restoreState()

story = []
story.append(P('VisualizingLQCD.jl 改良提案 v6', 'JPTitle'))
story.append(P('追補: 現行コード構造と全関数I/O', 'JPSubtitle'))
story.append(P('この追補は、2026年5月4日に確認した GitHub main branch の現行コードを対象にする。v5 本文の改善案に対して、現状の file 構造、実行時 data flow、すべての関数の入力型・出力型・副作用を明記する。型は、Julia の宣言上の型と、実際の実装から期待される型を分けて記す。', 'Note'))
story.append(Spacer(1, 6))

story.append(P('1. ファイル単位の構造', 'JPH1'))
story.append(P('現行の src directory には VisualizingLQCD.jl、configuration_generation.jl、constants.jl、header.jl、visualization.jl が置かれている。ただし package module が実際に include するのは configuration_generation.jl と visualization.jl の2ファイルだけである。header.jl と constants.jl は repository には残っているが、現行 module からは読まれない。configuration_generation.jl と visualization.jl の冒頭にも header/constants の include がコメントアウトされており、この2ファイルは旧 standalone 実行時代の補助 file と見るのが自然である。', 'JPBody'))
file_rows = [
    ['ファイル', '現行の役割', '注意点'],
    ['Project.toml', 'package 名、uuid、version、依存 package、compat を定義する。', 'Julia compat は 1.10。GLMakie、Gaugefields、Wilsonloop などが通常依存に入る。'],
    ['src/VisualizingLQCD.jl', 'module 本体。using 群を読み、configuration_generation.jl と visualization.jl を include する。', 'header.jl と constants.jl は include しない。'],
    ['src/visualization.jl', 'level 診断、lattice spacing 変換、ILDG 読み込み、plaquette 計算、対数変換、Makie 動画生成を持つ。', 'GLMakie.activate!() が include 時に実行される。create_animation が export される。'],
    ['src/configuration_generation.jl', 'SU(3) heatbath 更新、cold start からの4次元純ゲージ配位生成、gradient flow、binary save を持つ。', 'heatbathtest_4D が export される。heatbath_SU3! は非 export。'],
    ['src/header.jl', 'using 群を列挙する旧補助 file。', '現行 module からは読まれない。module 本体の using とほぼ重複する。'],
    ['src/constants.jl', 'demo 用の 24^3 x 32、beta=6.0、Nc=3、file 名を定義する旧補助 file。', '現行 module からは読まれない。top-level 変数であり const ではない。'],
    ['test/runtests.jl', 'test() を定義し、配位生成と動画生成をまとめて実行する。', '軽量な数値単体テストではなく、生成と rendering を含む統合 smoke test。'],
]
story.append(table(file_rows, [38*mm, 70*mm, 62*mm]))

story.append(P('2. 現行 module と public API', 'JPH1'))
story.append(P('VisualizingLQCD.jl は module 宣言、依存 package の using、2つの include、end だけで構成される。ここで Gaugefields、Wilsonloop、Makie、GLMakie、Plots、StatsBase などが一括で読み込まれるため、可視化だけを使う場合でも配位生成、描画 backend、統計処理が同じ namespace に入る。export 文から見る現行の public API は create_animation と heatbathtest_4D の2つである。automatic_level2、ln_a、calculate_a、heatbath_SU3! は module 内の非 export 関数である。', 'JPBody'))
story.append(code('module VisualizingLQCD\nusing Gaugefields\nusing Wilsonloop\n...\ninclude("configuration_generation.jl")\ninclude("visualization.jl")\nend'))

story.append(P('3. 実行時データフロー', 'JPH1'))
story.append(P('可視化経路は create_animation という1つの関数の中で完結する。入力は格子サイズ (NX,NY,NZ,NT)、Nc、動画 file 名、beta、ILDG file 名である。関数は Initialize_Gaugefields で入れ物を作り、ILDG(filename) と load_gaugefield! で file を読み、Wilsonline([(1,+1),(2,+1),(1,-1),(2,-1)]) を評価する。その後、各格子点で p12 = 1 - Re tr U12 / Nc を計算し、-log(p12 + 1e-7) を plaqs_t へ格納し、automatic_level2 の統計量から level 列を作り、GLMakie で動画を書き出す。', 'JPBody'))
story.append(P('配位生成経路は heatbathtest_4D が high-level driver である。関数は cold start のゲージ場を作り、heatbath_SU3! を20回呼び、5 sweep ごとに plaquette と Polyakov loop を表示し、最後に gradient flow を flow_steps_in 回かけて save_binarydata で保存する。このため、confname は出力 file であり、戻り値の plaq_t は最後に測った plaquette である。', 'JPBody'))
story.append(code('heatbathtest_4D(...) --> confname\nconfname + create_animation(...) --> videoname\ncreate_animation: load -> plaquette -> -log -> levels -> GLMakie.record'))

story.append(P('4. 全関数の入出力型一覧', 'JPH1'))
story.append(P('現行コードの多くの関数は、Julia の signature 上では型注釈を持たない。宣言上の型がない引数は Any として受け取られるが、内部の配列確保、loop、Gaugefields API、Makie API により、実用上は Int、Float64、String、Gaugefields の field 型が期待される。戻り値についても、明示 return がない関数は side effect を主目的とし、戻り値に API 契約を置かない方が安全である。', 'JPBody'))

func_rows_1 = [
    ['関数', '入力', '出力', '副作用・注意点'],
    ['automatic_level2(plaqs_t)', '宣言上は plaqs_t::Any。実用上は AbstractArray{<:Real}。minimum, maximum, mean, mode, std が定義されている必要がある。', '(level, isorange, min_val, max_val)。実用上は実数 tuple。level=mean, isorange=std。', '統計量を println で表示する。空配列や非数値配列では失敗する。level selection と診断表示が同じ関数に混ざっている。'],
    ['ln_a(beta::Float64)::Float64', 'beta は厳密に Float64。', 'Float64。log(a/r0) の fit 値。', 'beta が [5.7,6.57] の外なら ArgumentError。Int や Float32 には method がない。'],
    ['calculate_a(beta::Float64)::Float64', 'beta は厳密に Float64。', 'Float64。a = r0 exp(ln a) を fm 単位で返す。', 'ln_a に依存するため、同じ beta 範囲制限を持つ。'],
    ['create_animation(NX,NY,NZ,NT,NC,videoname; beta=6.1, flow_steps_in=200, filename="conf_00000100.ildg")', '宣言上は全 positional 引数と keyword が型なし。実用上は NX,NY,NZ,NT,NC::Int、videoname::AbstractString、beta::Float64、filename::AbstractString。', '明示 return はない。最後の式は Makie の record(...) なので、戻り値は現在の Makie 実装に依存し、API 契約にしない方がよい。', 'ILDG file を読み、mp4 などを videoname に書く。GLMakie figure を作る。flow_steps_in と scale_factor は現行関数内では使われない。levels[1] が空 level に弱い。'],
]
story.append(table(func_rows_1, [41*mm, 56*mm, 42*mm, 49*mm]))
story.append(Spacer(1, 6))
func_rows_2 = [
    ['関数', '入力', '出力', '副作用・注意点'],
    ['heatbath_SU3!(U,NC,temps,beta)', '宣言上は全引数が型なし。実用上、U は4方向の Gaugefields gauge-link collection、NC::Int、temps は長さ5以上で similar(U[1]) 型の作業 field 群、beta::Real。', 'Nothing と扱うのが自然。主出力は mutation された U。', 'U[mu] を even/odd で破壊的に更新する。temps[5] を staple 作業領域として使う。loops_staple、SU3update_matrix!、evaluate_gaugelinks_evenodd!、map_U! に依存する。'],
    ['heatbathtest_4D(NX,NY,NZ,NT,beta,NC,flow_steps_in,confname)', '宣言上は全引数が型なし。実用上は NX,NY,NZ,NT,NC,flow_steps_in::Int、beta::Real、confname::AbstractString。', 'plaq_t。実用上は最後に測った normalized plaquette の実数値。', 'cold start から配位を生成し、heatbath 20 sweeps、gradient flow、save_binarydata(U, confname) を実行する。標準出力に plaquette、Polyakov loop、progress を表示する。'],
    ['test() in test/runtests.jl', '入力なし。', '明示 return はない。create_animation の戻り値に依存しない smoke test と見るべきである。', '12^3 x 16 配位を生成し、ILDG/binary file と mp4 を作る。GUI/backend と動画 encoder に依存するため通常 CI では重い。'],
]
story.append(table(func_rows_2, [41*mm, 56*mm, 42*mm, 49*mm]))

story.append(P('5. 局所関数と匿名関数', 'JPH1'))
story.append(P('heatbath_SU3! の内部には mapfunc!(A,B) = SU3update_matrix!(A,B,beta,NC,temps2,temps3,ITERATION_MAX) という局所関数がある。入力 A と B は Gaugefields の map_U! から渡される link/staple 型の値であり、mapfunc! は beta、Nc、作業行列、反復上限を closure として捕捉する。出力は SU3update_matrix! の戻り値に依存するが、実質的な主出力は A の破壊的更新である。', 'JPBody'))
story.append(P('create_animation の内部には record(fig, videoname, 1:t_end; framerate=framerate) do i ... end の匿名関数がある。入力 i は frame index であり、現行コードでは t = i % NT + 1 によって第4方向 slice を選ぶ。出力値は使われず、主な副作用は既存 contour object の削除、新しい contour の描画、title 更新、動画 frame の記録である。ここは off-by-one を直す PR 0 の直接対象であり、slice4 = (i - 1) % NT + 1 にすれば最初の frame が slice 1 になる。', 'JPBody'))

story.append(P('6. top-level 定数と実行時副作用', 'JPH1'))
story.append(P('visualization.jl は include 時に GLMakie.activate!() を実行し、さらに LtoSec=10/3、myxlabel、myylabel、myzlabel、r0=0.48 を top-level 定数として定義する。このうち LtoSec は yoctosecond 表示を作るための値なので、時間表示廃止後は legacy default として隔離する。r0 と ln_a の多項式係数は物理単位換算に関わるため、ScaleSpec に移し、metadata に source と一緒に保存するのがよい。', 'JPBody'))
story.append(P('constants.jl は NX=24、NY=24、NZ=24、NT=32、beta=6.0、NC=3、flow_steps_in=200、confname、videoname を top-level 変数として定義する。現行 module からは使われていないため、PR では削除よりも examples/ へ移す方が安全である。header.jl も同様に、module 本体が同じ依存を読むため、現行 package API には影響しない旧補助 file として扱う。', 'JPBody'))

story.append(P('7. I/O 型から見える改修方針', 'JPH1'))
story.append(P('この I/O 棚卸しから、最初に直すべき点は3つに絞れる。第一に、create_animation の戻り値を曖昧な record 依存にせず、AnimationResult または NamedTuple として、video_path、metadata_path、levels、raw_equivalent_levels を返す。第二に、heatbathtest_4D は GenerationResult を返し、plaq_t だけでなく confname、final_plaquette、final_polyakov、flow_steps を記録する。第三に、automatic_level2 は表示をやめ、LevelStats か named tuple を返す純粋関数へ変える。', 'JPBody'))
story.append(P('型注釈は過剰に付ける必要はないが、API 境界では最低限の validation を入れるべきである。格子サイズは正の整数、Nc は正の整数、beta は Real を受けて内部で Float64 へ変換する、入力 file は存在確認する、出力 file の拡張子と backend は整合性を確認する。この validation を入れるだけで、現行の「深い依存関数の中で失敗する」挙動を減らせる。', 'JPBody'))
story.append(P('推奨する新しい戻り値の形', 'JPH2'))
story.append(code('AnimationResult(video_path, metadata_path, levels, raw_equivalent_levels, frame_map)\nGenerationResult(conf_path, final_plaquette, final_polyakov, flow_steps, beta)\nLevelStats(mean, mode, std, min, max, quantiles)'))

story.append(P('8. 参照元', 'JPH1'))
refs = [
    'VisualizingLQCD.jl src tree: https://github.com/akio-tomiya/VisualizingLQCD.jl/tree/main/src',
    'VisualizingLQCD.jl module: https://github.com/akio-tomiya/VisualizingLQCD.jl/blob/main/src/VisualizingLQCD.jl',
    'visualization.jl: https://github.com/akio-tomiya/VisualizingLQCD.jl/blob/main/src/visualization.jl',
    'configuration_generation.jl: https://github.com/akio-tomiya/VisualizingLQCD.jl/blob/main/src/configuration_generation.jl',
    'header.jl: https://github.com/akio-tomiya/VisualizingLQCD.jl/blob/main/src/header.jl',
    'constants.jl: https://github.com/akio-tomiya/VisualizingLQCD.jl/blob/main/src/constants.jl',
    'test/runtests.jl: https://github.com/akio-tomiya/VisualizingLQCD.jl/blob/main/test/runtests.jl',
]
for r in refs:
    story.append(P('• ' + r, 'JPBodySmall'))

doc = SimpleDocTemplate(
    str(OUT), pagesize=A4,
    rightMargin=14*mm, leftMargin=14*mm,
    topMargin=15*mm, bottomMargin=18*mm,
    title='VisualizingLQCD.jl improvement report v6 appendix',
    author='OpenAI GPT-5.5 Pro'
)
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
