const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageNumber, PageBreak, LevelFormat,
  TableOfContents, UnderlineType
} = require("docx");
const fs = require("fs");

// ── 색상 상수 ──
const C = {
  navy:   "1F3864",
  red:    "C00000",
  blue:   "2F5496",
  gray:   "595959",
  lgray:  "F2F2F2",
  mgray:  "D9D9D9",
  white:  "FFFFFF",
  hdr:    "1F3864",
  hdr2:   "C00000",
  accent: "E7F0FF",
  border: "BFBFBF",
};

// ── 헬퍼 함수 ──
const sp = (before, after) => ({ spacing: { before, after } });

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    children: [new TextRun({ text, bold: true, size: 36, color: C.navy, font: "Arial" })],
    spacing: { before: 400, after: 120 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: C.red, space: 4 } },
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    children: [new TextRun({ text, bold: true, size: 28, color: C.red, font: "Arial" })],
    spacing: { before: 280, after: 80 },
  });
}

function h3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    children: [new TextRun({ text, bold: true, size: 24, color: C.blue, font: "Arial" })],
    spacing: { before: 200, after: 60 },
  });
}

function para(text, opts = {}) {
  return new Paragraph({
    children: [new TextRun({
      text,
      font: "Arial",
      size: opts.size || 22,
      color: opts.color || "000000",
      bold: opts.bold || false,
      italics: opts.italic || false,
    })],
    spacing: { before: opts.before || 0, after: opts.after || 100 },
    alignment: opts.align || AlignmentType.LEFT,
  });
}

function bullet(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "bullets", level },
    children: [new TextRun({ text, font: "Arial", size: 22 })],
    spacing: { before: 0, after: 60 },
  });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function divider() {
  return new Paragraph({
    children: [new TextRun("")],
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.mgray, space: 1 } },
    spacing: { before: 120, after: 120 },
  });
}

// ── 표 헬퍼 ──
const BORDER = { style: BorderStyle.SINGLE, size: 1, color: C.border };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };
const CELL_MARGIN = { top: 80, bottom: 80, left: 120, right: 120 };

function hdrCell(text, width) {
  return new TableCell({
    borders: BORDERS,
    width: { size: width, type: WidthType.DXA },
    shading: { fill: C.hdr, type: ShadingType.CLEAR },
    margins: CELL_MARGIN,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text, bold: true, color: C.white, font: "Arial", size: 20 })],
    })],
  });
}

function dataCell(text, width, opts = {}) {
  return new TableCell({
    borders: BORDERS,
    width: { size: width, type: WidthType.DXA },
    shading: opts.shading ? { fill: opts.shading, type: ShadingType.CLEAR } : undefined,
    margins: CELL_MARGIN,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: opts.align || AlignmentType.LEFT,
      children: [new TextRun({
        text,
        font: "Arial",
        size: 20,
        bold: opts.bold || false,
        color: opts.color || "000000",
      })],
    })],
  });
}

// ── 문서 본문 구성 ──

// 1. 표지
const coverPage = [
  new Paragraph({ children: [new TextRun("")], spacing: { before: 0, after: 2000 } }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "ROAD TO GLORY", bold: true, size: 72, color: C.navy, font: "Arial" })],
    spacing: { before: 0, after: 160 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Game Design Document", size: 32, color: C.gray, font: "Arial" })],
    spacing: { before: 0, after: 80 },
  }),
  divider(),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "MMA 격투가 육성 시뮬레이션 RPG", size: 24, color: C.blue, font: "Arial", italics: true })],
    spacing: { before: 80, after: 400 },
  }),
  new Paragraph({ children: [new TextRun("")], spacing: { before: 0, after: 2000 } }),

  // 메타 정보 표
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2400, 6626],
    rows: [
      new TableRow({ children: [hdrCell("항목", 2400), hdrCell("내용", 6626)] }),
      new TableRow({ children: [dataCell("버전", 2400, { shading: C.lgray, bold: true }), dataCell("v0.1 (초안)", 6626)] }),
      new TableRow({ children: [dataCell("작성일", 2400, { shading: C.lgray, bold: true }), dataCell("2026년 5월 25일", 6626)] }),
      new TableRow({ children: [dataCell("엔진", 2400, { shading: C.lgray, bold: true }), dataCell("Godot 4", 6626)] }),
      new TableRow({ children: [dataCell("레퍼런스", 2400, { shading: C.lgray, bold: true }), dataCell("Punch Club (Lazy Bear Games, 2016)", 6626)] }),
      new TableRow({ children: [dataCell("장르", 2400, { shading: C.lgray, bold: true }), dataCell("격투가 육성 시뮬레이션 RPG", 6626)] }),
      new TableRow({ children: [dataCell("세계관", 2400, { shading: C.lgray, bold: true }), dataCell("MMA / UFC", 6626)] }),
    ],
  }),
  pageBreak(),
];

// 2. 목차
const tocPage = [
  new TableOfContents("목차", {
    hyperlink: true,
    headingStyleRange: "1-3",
  }),
  pageBreak(),
];

// 3. 섹션 1 — 게임 개요
const section1 = [
  h1("1. 게임 개요"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2400, 6626],
    rows: [
      new TableRow({ children: [hdrCell("항목", 2400), hdrCell("내용", 6626)] }),
      new TableRow({ children: [dataCell("장르", 2400, { shading: C.lgray, bold: true }), dataCell("격투가 육성 시뮬레이션 RPG", 6626)] }),
      new TableRow({ children: [dataCell("플랫폼", 2400, { shading: C.lgray, bold: true }), dataCell("PC (Windows)", 6626)] }),
      new TableRow({ children: [dataCell("플레이 시간", 2400, { shading: C.lgray, bold: true }), dataCell("약 2~3시간 (엔딩 1회 기준)", 6626)] }),
      new TableRow({ children: [dataCell("핵심 판타지", 2400, { shading: C.lgray, bold: true }), dataCell("길거리 싸움꾼이 UFC 챔피언이 된다", 6626)] }),
    ],
  }),
  para(""),
  para("플레이어는 3가지 격투 스타일(복서 · 레슬러 · 주짓떼로) 중 하나를 선택하고, 일과 관리(훈련/휴식/아르바이트)를 통해 스탯을 키우며 4개 티어를 순서대로 정복한다. 각 티어에는 플레이어 직업과 상성상 불리한 라이벌이 기다린다.", { after: 200 }),
];

// 4. 섹션 2 — 직업 시스템
const section2 = [
  h1("2. 직업 시스템"),
  h2("2.1 삼각 상성"),
  para("세 직업은 가위바위보 구조의 삼각 상성을 가진다.", { after: 80 }),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2255, 2255, 2258, 2258],
    rows: [
      new TableRow({ children: [hdrCell("직업", 2255), hdrCell("이기는 상대", 2255), hdrCell("지는 상대", 2258), hdrCell("판타지", 2258)] }),
      new TableRow({ children: [dataCell("복서 (Boxer)", 2255, { bold: true }), dataCell("주짓떼로", 2255, { shading: "E2EFDA" }), dataCell("레슬러", 2258, { shading: "FFE7E7" }), dataCell("빠른 타격으로 거리 유지", 2258)] }),
      new TableRow({ children: [dataCell("레슬러 (Wrestler)", 2255, { bold: true }), dataCell("복서", 2255, { shading: "E2EFDA" }), dataCell("주짓떼로", 2258, { shading: "FFE7E7" }), dataCell("태클로 타격가를 억누름", 2258)] }),
      new TableRow({ children: [dataCell("주짓떼로 (Jiu-Jitsu)", 2255, { bold: true }), dataCell("레슬러", 2255, { shading: "E2EFDA" }), dataCell("복서", 2258, { shading: "FFE7E7" }), dataCell("그래플링으로 레슬러를 역이용", 2258)] }),
    ],
  }),
  para(""),
  h3("상성 배율"),
  bullet("유리 매치업: 전투 최종 데미지 +20%"),
  bullet("불리 매치업: 전투 최종 데미지 -20%"),
  bullet("동일 직업: 배율 없음 (순수 스탯 싸움)"),
  para(""),
  h2("2.2 직업별 특화 스탯 및 고유 메카닉"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2255, 2255, 4516],
    rows: [
      new TableRow({ children: [hdrCell("직업", 2255), hdrCell("주력 스탯", 2255), hdrCell("고유 메카닉", 4516)] }),
      new TableRow({ children: [dataCell("복서", 2255, { bold: true }), dataCell("민첩(AGI), 스트라이킹", 2255), dataCell("콤보 카운터 — 연속 공격 시 데미지 누적 상승", 4516)] }),
      new TableRow({ children: [dataCell("레슬러", 2255, { bold: true }), dataCell("힘(STR), HP", 2255), dataCell("테이크다운 — 일정 확률로 상대를 넘어뜨려 추가 타격", 4516)] }),
      new TableRow({ children: [dataCell("주짓떼로", 2255, { bold: true }), dataCell("기술(TEC), 스태미나", 2255), dataCell("서브미션 게이지 — 누적 시 즉사에 가까운 피니시", 4516)] }),
    ],
  }),
  para(""),
];

// 5. 섹션 3 — 콘텐츠 진행 구조
const section3 = [
  h1("3. 콘텐츠 진행 구조 (4 티어)"),
  para("게임은 4개의 티어로 구성된 선형 진행 구조를 가진다. 각 티어에는 일반 대전 상대와 라이벌, 그리고 타이틀 보스가 존재한다.", { after: 120 }),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [1800, 2000, 1800, 1800, 1626],
    rows: [
      new TableRow({ children: [hdrCell("티어", 1800), hdrCell("배경", 2000), hdrCell("적 수준", 1800), hdrCell("일반전 수", 1800), hdrCell("보상", 1626)] }),
      new TableRow({ children: [dataCell("1. 길거리 파이터", 1800, { bold: true, shading: C.accent }), dataCell("골목 / 공터", 2000), dataCell("낮음, 무식한 싸움", 1800), dataCell("3명", 1800), dataCell("소액 + 도장 입문", 1626)] }),
      new TableRow({ children: [dataCell("2. KFC 파이터", 1800, { bold: true, shading: C.accent }), dataCell("소규모 링", 2000), dataCell("중간, 스타일 있음", 1800), dataCell("4명", 1800), dataCell("계약금 + 스폰서 장비", 1626)] }),
      new TableRow({ children: [dataCell("3. UFC 파이터", 1800, { bold: true, shading: C.accent }), dataCell("정식 옥타곤", 2000), dataCell("높음, 전문 파이터", 1800), dataCell("5명", 1800), dataCell("높은 파이트머니", 1626)] }),
      new TableRow({ children: [dataCell("4. UFC 챔피언", 1800, { bold: true, shading: C.accent }), dataCell("대형 이벤트", 2000), dataCell("최고, 라이벌 포함", 1800), dataCell("방어전 2회", 1800), dataCell("벨트 + 엔딩", 1626)] }),
    ],
  }),
  para(""),
];

// 6. 섹션 4 — 라이벌 시스템
const section4 = [
  h1("4. 라이벌 시스템"),
  h2("4.1 라이벌 배정 규칙"),
  para("플레이어가 직업을 선택하면 상성상 불리한 직업의 라이벌이 자동으로 배정된다.", { after: 80 }),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("플레이어 직업", 3008), hdrCell("라이벌 직업", 3009), hdrCell("라이벌 이름 (예시)", 3009)] }),
      new TableRow({ children: [dataCell("복서", 3008), dataCell("레슬러", 3009, { shading: "FFE7E7" }), dataCell('"마운틴" 김철수', 3009)] }),
      new TableRow({ children: [dataCell("레슬러", 3008), dataCell("주짓떼로", 3009, { shading: "FFE7E7" }), dataCell('"스네이크" 박지훈', 3009)] }),
      new TableRow({ children: [dataCell("주짓떼로", 3008), dataCell("복서", 3009, { shading: "FFE7E7" }), dataCell('"플래시" 이민준', 3009)] }),
    ],
  }),
  para(""),
  h2("4.2 라이벌 등장 패턴"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2800, 2000, 4226],
    rows: [
      new TableRow({ children: [hdrCell("등장 시점", 2800), hdrCell("상태", 2000), hdrCell("역할", 4226)] }),
      new TableRow({ children: [dataCell("티어 1 클리어 직전", 2800), dataCell("플레이어보다 강함", 2000, { shading: "FFE7E7" }), dataCell("패배 이벤트 → 동기부여 (\"언젠가 꼭 이긴다\")", 4226)] }),
      new TableRow({ children: [dataCell("티어 2 보스", 2800), dataCell("비슷한 수준", 2000, { shading: "FFFCE0" }), dataCell("플레이어 성장 확인 — 박빙의 승부", 4226)] }),
      new TableRow({ children: [dataCell("티어 3 도전자 결정전", 2800), dataCell("플레이어와 박빙", 2000, { shading: "E2EFDA" }), dataCell("극적인 승부 연출", 4226)] }),
      new TableRow({ children: [dataCell("티어 4 최종 보스", 2800), dataCell("최강 버전", 2000, { shading: "E2EFDA" }), dataCell("클라이맥스 — 상성 불리를 스탯으로 극복하는 순간", 4226)] }),
    ],
  }),
  para(""),
  h2("4.3 라이벌 성장 설계 의도"),
  bullet("라이벌도 티어에 따라 스탯이 올라가므로, 플레이어는 항상 상성 불이익(-20%)을 극복할 스탯 차이를 만들어야 한다"),
  bullet("상성 디버프를 뒤집으려면 스탯 총합 약 25% 이상 우위 필요 (밸런스 시트 참조)"),
  bullet("라이벌 티어가 올라갈수록 요구 우위가 소폭 증가 → 후반부 자연스러운 난이도 상승"),
  para(""),
];

// 7. 섹션 5 — 스탯 시스템
const section5 = [
  h1("5. 스탯 시스템"),
  h2("5.1 5가지 기본 스탯"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2000, 1000, 3526, 2500],
    rows: [
      new TableRow({ children: [hdrCell("스탯", 2000), hdrCell("기호", 1000), hdrCell("영향 범위", 3526), hdrCell("훈련 방법", 2500)] }),
      new TableRow({ children: [dataCell("힘 (Strength)", 2000), dataCell("STR", 1000), dataCell("기본 데미지", 3526), dataCell("웨이트 트레이닝", 2500)] }),
      new TableRow({ children: [dataCell("민첩 (Agility)", 2000), dataCell("AGI", 1000), dataCell("회피율, 공격 속도", 3526), dataCell("달리기, 줄넘기", 2500)] }),
      new TableRow({ children: [dataCell("스태미나 (Stamina)", 2000), dataCell("STA", 1000), dataCell("전투 지속 능력, 스킬 사용", 3526), dataCell("사이클, 수영", 2500)] }),
      new TableRow({ children: [dataCell("기술 (Technique)", 2000), dataCell("TEC", 1000), dataCell("직업 스킬 계수, 크리티컬", 3526), dataCell("스파링, 미트 훈련", 2500)] }),
      new TableRow({ children: [dataCell("체력 (HP)", 2000), dataCell("HP", 1000), dataCell("전투 생존력", 3526), dataCell("식단 관리", 2500)] }),
    ],
  }),
  para(""),
  h2("5.2 스탯 감소 시스템"),
  para("훈련하지 않으면 스탯이 매일 소폭 감소한다. 이는 Punch Club의 핵심 메카닉을 계승한 것으로, 플레이어에게 지속적인 훈련 동기를 부여한다.", { after: 80 }),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("스탯", 3008), hdrCell("기본 감소/day", 3009), hdrCell("STA 부족 시 감소/day", 3009)] }),
      new TableRow({ children: [dataCell("STR", 3008), dataCell("-0.5", 3009, { align: AlignmentType.CENTER }), dataCell("-1.0", 3009, { align: AlignmentType.CENTER, shading: "FFE7E7" })] }),
      new TableRow({ children: [dataCell("AGI", 3008), dataCell("-0.7", 3009, { align: AlignmentType.CENTER }), dataCell("-1.4", 3009, { align: AlignmentType.CENTER, shading: "FFE7E7" })] }),
      new TableRow({ children: [dataCell("TEC", 3008), dataCell("-0.3", 3009, { align: AlignmentType.CENTER }), dataCell("-0.6", 3009, { align: AlignmentType.CENTER, shading: "FFE7E7" })] }),
    ],
  }),
  para(""),
  para("STA 부족 기준: STA < 20 (전체 최대치의 약 22%)", { italic: true, color: C.gray }),
  para(""),
];

// 8. 섹션 6 — 훈련 시스템
const section6 = [
  h1("6. 훈련 시스템"),
  h2("6.1 하루 시간 슬롯 구조"),
  para("하루는 3개 슬롯(아침 / 오후 / 저녁)으로 구성되며, 각 슬롯에 1가지 행동을 배치한다.", { after: 80 }),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2500, 2800, 1726, 2000],
    rows: [
      new TableRow({ children: [hdrCell("행동", 2500), hdrCell("효과", 2800), hdrCell("비용", 1726), hdrCell("비고", 2000)] }),
      new TableRow({ children: [dataCell("웨이트 트레이닝", 2500), dataCell("STR +3, STA -5", 2800), dataCell("도장 멤버십", 1726), dataCell("", 2000)] }),
      new TableRow({ children: [dataCell("달리기", 2500), dataCell("AGI +2, STA +1", 2800), dataCell("무료", 1726), dataCell("", 2000)] }),
      new TableRow({ children: [dataCell("줄넘기", 2500), dataCell("AGI +1, STA +2", 2800), dataCell("무료", 1726), dataCell("", 2000)] }),
      new TableRow({ children: [dataCell("스파링", 2500), dataCell("TEC +3, STA -8, HP -5", 2800), dataCell("도장 멤버십", 1726), dataCell("", 2000)] }),
      new TableRow({ children: [dataCell("식단 관리", 2500), dataCell("HP +10, STA 회복 +5", 2800), dataCell("50골드", 1726), dataCell("", 2000)] }),
      new TableRow({ children: [dataCell("아르바이트", 2500), dataCell("골드 +75 (평균)", 2800), dataCell("무료", 1726), dataCell("스탯 향상 없음", 2000)] }),
      new TableRow({ children: [dataCell("휴식", 2500), dataCell("STA 대폭 회복 +15", 2800), dataCell("무료", 1726), dataCell("", 2000)] }),
    ],
  }),
  para(""),
  h2("6.2 훈련 효율 (수확 체감 공식)"),
  para("스탯이 낮을수록 훈련 효율이 높고, 목표 수치에 가까워질수록 효율이 감소한다.", { after: 60 }),
  para("실제 +값 = 기본 +값 × (목표스탯 ÷ 현재스탯)^0.4", { bold: true, after: 60 }),
  para("예) 현재 STR=40 → 3 × (80÷40)^0.4 ≈ +4.0 / 현재 STR=75 → 3 × (80÷75)^0.4 ≈ +3.1", { italic: true, color: C.gray }),
  para(""),
];

// 9. 섹션 7 — 전투 시스템
const section7 = [
  h1("7. 전투 시스템"),
  h2("7.1 전투 방식"),
  para("Punch Club과 동일한 자동 진행 방식. 플레이어는 전투 시작 전 전략만 선택하며, 이후 전투는 스탯과 상성에 따라 자동으로 계산된다.", { after: 120 }),
  h2("7.2 전투 전 전략 선택"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("전략", 3008), hdrCell("공격 배율", 3009), hdrCell("방어 배율", 3009)] }),
      new TableRow({ children: [dataCell("공격적 (Aggressive)", 3008), dataCell("×1.15", 3009, { shading: "E2EFDA", align: AlignmentType.CENTER }), dataCell("×0.85", 3009, { shading: "FFE7E7", align: AlignmentType.CENTER })] }),
      new TableRow({ children: [dataCell("균형 (Balanced)", 3008), dataCell("×1.00", 3009, { align: AlignmentType.CENTER }), dataCell("×1.00", 3009, { align: AlignmentType.CENTER })] }),
      new TableRow({ children: [dataCell("방어적 (Defensive)", 3008), dataCell("×0.85", 3009, { shading: "FFE7E7", align: AlignmentType.CENTER }), dataCell("×1.15", 3009, { shading: "E2EFDA", align: AlignmentType.CENTER })] }),
    ],
  }),
  para(""),
  h2("7.3 전투 데미지 공식"),
  para("기본 공격력 (ATK) = (STR × 1.5 + TEC × 0.5) × 직업 계수", { bold: true, after: 60 }),
  para("최종 데미지 = ATK × 상성 배율 × 전략 배율 × 크리티컬 배율", { bold: true, after: 60 }),
  para("회피율 = 상대 AGI ÷ (내 AGI + 상대 AGI) × 0.6  [최대 40% 캡]", { bold: true, after: 120 }),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("직업", 3008), hdrCell("직업 계수", 3009), hdrCell("특성", 3009)] }),
      new TableRow({ children: [dataCell("복서", 3008), dataCell("1.0 (AGI 보너스 추가)", 3009), dataCell("빠른 공격 횟수 우위", 3009)] }),
      new TableRow({ children: [dataCell("레슬러", 3008), dataCell("1.1 (STR 비중 ↑)", 3009), dataCell("느리지만 1타 데미지 강함", 3009)] }),
      new TableRow({ children: [dataCell("주짓떼로", 3008), dataCell("0.9 (서브미션으로 보완)", 3009), dataCell("게이지 누적으로 피니시", 3009)] }),
    ],
  }),
  para(""),
  h2("7.4 전투 흐름"),
  para("3라운드 제도. 1라운드 = 실제 약 30~45초.", { after: 60 }),
  bullet("라운드 시작 → 양측 공격 교환 (AGI 기반 공격 순서 결정)"),
  bullet("특수 메카닉 발동 체크 (콤보 카운터 / 테이크다운 / 서브미션 게이지)"),
  bullet("HP 0 또는 STA 0 → KO / 서브미션 패배"),
  bullet("3라운드 종료 시 판정승 (누적 데미지 비교)"),
  para(""),
];

// 10. 섹션 8 — 경제 시스템
const section8 = [
  h1("8. 경제 시스템"),
  h2("8.1 수입 원천"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 2509, 3509],
    rows: [
      new TableRow({ children: [hdrCell("수입", 3008), hdrCell("금액 범위", 2509), hdrCell("조건", 3509)] }),
      new TableRow({ children: [dataCell("아르바이트", 3008), dataCell("50~100골드/슬롯", 2509), dataCell("슬롯 사용", 3509)] }),
      new TableRow({ children: [dataCell("시합 승리 보너스", 3008), dataCell("100~5,000골드", 2509), dataCell("티어 비례", 3509)] }),
      new TableRow({ children: [dataCell("스폰서 계약", 3008), dataCell("500골드 (1회)", 2509), dataCell("티어 2 진입 시 자동 지급", 3509)] }),
    ],
  }),
  para(""),
  h2("8.2 지출 항목"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 2509, 3509],
    rows: [
      new TableRow({ children: [hdrCell("지출", 3008), hdrCell("금액", 2509), hdrCell("주기", 3509)] }),
      new TableRow({ children: [dataCell("도장 멤버십", 3008), dataCell("300골드", 2509), dataCell("주간 (7일마다)", 3509)] }),
      new TableRow({ children: [dataCell("식단 (영양제)", 3008), dataCell("50~150골드", 2509), dataCell("구매 시 즉시 소모", 3509)] }),
      new TableRow({ children: [dataCell("장비 업그레이드", 3008), dataCell("500~2,000골드", 2509), dataCell("1회성 (영구 효과)", 3509)] }),
    ],
  }),
  para(""),
  h2("8.3 티어별 시합 보너스"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2255, 2255, 2258, 2258],
    rows: [
      new TableRow({ children: [hdrCell("티어", 2255), hdrCell("일반전 승리", 2255), hdrCell("라이벌전 승리", 2258), hdrCell("보스전 승리", 2258)] }),
      new TableRow({ children: [dataCell("1. 길거리", 2255), dataCell("100", 2255, { align: AlignmentType.CENTER }), dataCell("200", 2258, { align: AlignmentType.CENTER }), dataCell("300", 2258, { align: AlignmentType.CENTER })] }),
      new TableRow({ children: [dataCell("2. KFC", 2255), dataCell("300", 2255, { align: AlignmentType.CENTER }), dataCell("600", 2258, { align: AlignmentType.CENTER }), dataCell("1,000", 2258, { align: AlignmentType.CENTER })] }),
      new TableRow({ children: [dataCell("3. UFC", 2255), dataCell("800", 2255, { align: AlignmentType.CENTER }), dataCell("1,500", 2258, { align: AlignmentType.CENTER }), dataCell("2,500", 2258, { align: AlignmentType.CENTER })] }),
      new TableRow({ children: [dataCell("4. 챔피언", 2255), dataCell("1,500", 2255, { align: AlignmentType.CENTER }), dataCell("—", 2258, { align: AlignmentType.CENTER }), dataCell("5,000", 2258, { align: AlignmentType.CENTER })] }),
    ],
  }),
  para(""),
  h2("8.4 경제 루프 설계 의도"),
  bullet("초반: 아르바이트와 훈련 사이 시간 트레이드오프가 핵심 긴장감 (항상 돈이 빠듯하게 설계)"),
  bullet("중반: 시합 보너스로 아르바이트 의존도 감소 → 훈련 집중 가능"),
  bullet("후반: 돈보다 시간 효율 극대화가 더 중요한 자원이 됨"),
  para(""),
];

// 11. 섹션 9 — 스킬 트리
const section9 = [
  h1("9. 스킬 트리"),
  para("각 직업당 9개 스킬 (3×3 트리 구조). 스킬 포인트는 시합 승리 시 획득.", { after: 120 }),
  h2("9.1 복서 스킬 트리"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("1열 (기초)", 3008), hdrCell("2열 (중급)", 3009), hdrCell("3열 (고급)", 3009)] }),
      new TableRow({ children: [dataCell("잽 마스터", 3008), dataCell("원투 콤보", 3009), dataCell("스웨이 백", 3009)] }),
      new TableRow({ children: [dataCell("풋워크", 3008), dataCell("훅 파워업", 3009), dataCell("더킹", 3009)] }),
      new TableRow({ children: [dataCell("바디샷", 3008), dataCell("어퍼컷", 3009), dataCell("KO 피니셔", 3009)] }),
    ],
  }),
  para(""),
  h2("9.2 레슬러 스킬 트리"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("1열 (기초)", 3008), hdrCell("2열 (중급)", 3009), hdrCell("3열 (고급)", 3009)] }),
      new TableRow({ children: [dataCell("싱글렉 테이크다운", 3008), dataCell("더블렉 테이크다운", 3009), dataCell("슬램", 3009)] }),
      new TableRow({ children: [dataCell("클린치 그라운드", 3008), dataCell("마운트 포지션", 3009), dataCell("그라운드 앤 파운드", 3009)] }),
      new TableRow({ children: [dataCell("철벽 방어", 3008), dataCell("스태미나 강화", 3009), dataCell("아이언 바디", 3009)] }),
    ],
  }),
  para(""),
  h2("9.3 주짓떼로 스킬 트리"),
  new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [3008, 3009, 3009],
    rows: [
      new TableRow({ children: [hdrCell("1열 (기초)", 3008), hdrCell("2열 (중급)", 3009), hdrCell("3열 (고급)", 3009)] }),
      new TableRow({ children: [dataCell("가드 포지션", 3008), dataCell("암바", 3009), dataCell("트라이앵글 초크", 3009)] }),
      new TableRow({ children: [dataCell("스위프", 3008), dataCell("백 테이크", 3009), dataCell("리어 네이키드 초크", 3009)] }),
      new TableRow({ children: [dataCell("카운터 타이밍", 3008), dataCell("서브미션 가속", 3009), dataCell("퍼펙트 피니셔", 3009)] }),
    ],
  }),
  para(""),
];

// 12. 섹션 10 — MVP
const section10 = [
  h1("10. 개발 우선순위 (MVP 정의)"),
  h2("10.1 MVP (최소 제출 가능 버전)"),
  bullet("직업 선택 3종 (복서 / 레슬러 / 주짓떼로)"),
  bullet("하루 3슬롯 시간 관리 시스템"),
  bullet("스탯 훈련 + 매일 감소 시스템"),
  bullet("자동 전투 + 상성 배율 적용"),
  bullet("티어 1~2 콘텐츠 (라이벌 포함)"),
  bullet("기본 경제 루프 (아르바이트 / 도장비 / 식단)"),
  para(""),
  h2("10.2 추가 목표 (완성도 향상)"),
  bullet("티어 3~4 콘텐츠 전체"),
  bullet("스킬 트리 27개 스킬 구현"),
  bullet("스폰서 / 장비 업그레이드 시스템"),
  bullet("라이벌 스토리 대화 및 연출"),
  bullet("UI 애니메이션 및 폴리싱"),
  para(""),
  divider(),
  para("다음 문서: 밸런스 시트 (balance/balance_sheet.md)", { italic: true, color: C.gray, align: AlignmentType.RIGHT }),
];

// ── 문서 조립 ──
const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{
          level: 0,
          format: LevelFormat.BULLET,
          text: "•",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } },
        }],
      },
    ],
  },
  styles: {
    default: {
      document: { run: { font: "Arial", size: 22 } },
    },
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      },
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          children: [
            new TextRun({ text: "Road to Glory — Game Design Document", font: "Arial", size: 18, color: C.gray }),
            new TextRun({ text: "\tv0.1", font: "Arial", size: 18, color: C.gray }),
          ],
          tabStops: [{ type: "right", position: 8600 }],
          border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.mgray, space: 1 } },
        })],
      }),
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [
            new TextRun({ text: "— ", font: "Arial", size: 18, color: C.gray }),
            new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 18, color: C.gray }),
            new TextRun({ text: " —", font: "Arial", size: 18, color: C.gray }),
          ],
          border: { top: { style: BorderStyle.SINGLE, size: 4, color: C.mgray, space: 1 } },
        })],
      }),
    },
    children: [
      ...coverPage,
      ...tocPage,
      ...section1,
      ...section2,
      ...section3,
      ...section4,
      ...section5,
      ...section6,
      ...section7,
      ...section8,
      ...section9,
      ...section10,
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("E:\\GameDesignGYM\\docs\\GDD_Road_to_Glory.docx", buffer);
  console.log("GDD_Road_to_Glory.docx 생성 완료!");
}).catch(err => {
  console.error("오류:", err);
  process.exit(1);
});
