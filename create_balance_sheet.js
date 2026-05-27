const ExcelJS = require("exceljs");
const wb = new ExcelJS.Workbook();
wb.creator = "Road to Glory - Balance Team";
wb.created = new Date();

// ── 공통 스타일 ──────────────────────────────────────────────────────────────
const FONT = "Arial";
const C = {
  navy:   "FF1F3864", red:    "FFC00000", blue:   "FF2F5496",
  gray:   "FF595959", lgray:  "FFF2F2F2", mgray:  "FFD9D9D9",
  white:  "FFFFFFFF", green:  "FF375623", lgreen: "FFE2EFDA",
  yellow: "FFFFFF00", orange: "FFED7D31", lorange:"FFFFF2CC",
  lred:   "FFFFCCCC", lblue:  "FFE7F0FF",
};

function hdrFill(hex) { return { type:"pattern", pattern:"solid", fgColor:{argb:hex} }; }
function font(sz, bold, color) { return { name:FONT, size:sz||11, bold:!!bold, color:{argb:color||"FF000000"} }; }
function align(h, v) { return { horizontal:h||"left", vertical:v||"middle", wrapText:true }; }
function border() {
  const s = { style:"thin", color:{argb:"FFBFBFBF"} };
  return { top:s, bottom:s, left:s, right:s };
}

function applyHeader(row, cols) {
  cols.forEach((col, i) => {
    const cell = row.getCell(i+1);
    cell.value = col;
    cell.font = font(10, true, C.white);
    cell.fill = hdrFill(C.navy);
    cell.alignment = align("center");
    cell.border = border();
  });
}

function styleRow(row, fillArgb, fontArgb, bold) {
  row.eachCell(cell => {
    if (fillArgb) cell.fill = hdrFill(fillArgb);
    cell.font = font(10, bold||false, fontArgb||"FF000000");
    cell.border = border();
    cell.alignment = align("left", "middle");
  });
}

// ════════════════════════════════════════════════════════════════════════════
// 시트 1: 📋 개요
// ════════════════════════════════════════════════════════════════════════════
(function sheetOverview() {
  const ws = wb.addWorksheet("📋 개요", { tabColor:{argb:C.navy} });
  ws.columns = [
    {width:22},{width:35},{width:20},{width:20},{width:20}
  ];

  ws.mergeCells("A1:E1");
  const title = ws.getCell("A1");
  title.value = "Road to Glory — 밸런스 시트";
  title.font = font(18, true, C.navy);
  title.alignment = align("center");
  title.fill = hdrFill(C.lgray);

  ws.mergeCells("A2:E2");
  ws.getCell("A2").value = "v0.1  |  작성일: 2026-05-25  |  모든 수치는 플레이테스트 전 이론값";
  ws.getCell("A2").font = font(10, false, C.gray);
  ws.getCell("A2").alignment = align("center");

  ws.addRow([]);

  const sections = [
    ["시트명","설명","주요 변수","참조 시트"],
    ["📊 스탯 성장","티어별 스탯 목표값과 성장 공식","STR/AGI/STA/TEC/HP 목표치","전투 시뮬레이터"],
    ["⚔️ 전투 시뮬레이터","데미지 공식·상성·전략 배율 계산기","ATK, 상성 배율, 크리티컬율","스탯 성장"],
    ["🏃 활력 시스템","하루 시간/활력 예산 및 이동 비용 분석","이동 활력, 훈련 슬롯 수","집 장비 투자"],
    ["💰 경제 흐름","티어별 수입/지출 및 골드 흑자 분석","아르바이트, 멤버십, 식단","집 장비 투자"],
    ["🏠 집 장비 투자","집 장비 구매 ROI 시뮬레이션","장비 비용, 절약 활력, 회수 기간","경제 흐름"],
    ["🥊 스파링 비용","스킬포인트 획득 경로별 비용 비교","스파링 초청비, SP 획득량","경제 흐름"],
    ["📝 조정 이력","플레이테스트 후 수치 변경 기록","날짜, 항목, 변경 전후, 이유","—"],
  ];

  sections.forEach((row, i) => {
    const r = ws.addRow(row);
    if (i === 0) applyHeader(r, row);
    else styleRow(r, i%2===0 ? C.lgray : C.white);
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 2: 📊 스탯 성장
// ════════════════════════════════════════════════════════════════════════════
(function sheetStatGrowth() {
  const ws = wb.addWorksheet("📊 스탯 성장", { tabColor:{argb:C.blue} });
  ws.columns = [
    {width:18},{width:12},{width:14},{width:14},{width:14},{width:14},
    {width:20},{width:20}
  ];

  // 제목
  ws.mergeCells("A1:H1");
  ws.getCell("A1").value = "스탯 성장 목표값 (티어별)";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  ws.addRow([]);

  // 스탯 목표값 테이블
  const hdr = ws.addRow(["스탯","시작값","티어1 목표","티어2 목표","티어3 목표","티어4 목표","비고",""]);
  applyHeader(hdr, ["스탯","시작값","티어1 목표","티어2 목표","티어3 목표","티어4 목표","비고",""]);

  const stats = [
    ["STR (힘)",    10, 25, 45, 65, 85, "기본 데미지 영향"],
    ["AGI (민첩)",  10, 25, 45, 65, 85, "회피율·공격 속도"],
    ["STA (스태미나)", 10, 30, 50, 70, 90, "전투 지속·스킬 사용"],
    ["TEC (기술)",  10, 20, 40, 60, 80, "직업 스킬 계수·크리티컬"],
    ["HP (체력)",  100,150,220,300,380, "전투 생명력 (식단 관리로 상승)"],
    ["VIT (활력)",  100,100,100,100,100, "하루 행동 예산 — 매일 완전 회복"],
  ];

  stats.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i%2===0 ? C.lgray : C.white);
    r.getCell(1).font = font(10, true, "FF000000");
  });

  ws.addRow([]);

  // 스탯 감소율 테이블
  ws.mergeCells("A11:H11");
  ws.getCell("A11").value = "스탯 일일 감소율 (미훈련 시)";
  ws.getCell("A11").font = font(12, true, C.red);
  ws.getCell("A11").fill = hdrFill(C.lorange);

  const hdr2 = ws.addRow(["스탯","기본 감소/day","STA부족 감소/day","STA부족 기준","비고","","",""]);
  applyHeader(hdr2, ["스탯","기본 감소/day","STA부족 감소/day","STA부족 기준","비고","","",""]);

  const decay = [
    ["STR", -0.5, -1.0, "STA < 20", "STA 부족 시 2배"],
    ["AGI", -0.7, -1.4, "STA < 20", "STA 부족 시 2배"],
    ["TEC", -0.3, -0.6, "STA < 20", "STA 부족 시 2배"],
    ["HP",  0,    0,    "—",        "자연 감소 없음 (식단으로만 증가)"],
    ["VIT", 0,    0,    "—",        "매일 100으로 완전 회복"],
  ];

  decay.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i%2===0 ? C.lgray : C.white);
    if (row[1] < 0) r.getCell(2).font = font(10, true, "FFCC0000");
    if (row[2] < 0) r.getCell(3).font = font(10, true, "FFCC0000");
  });

  ws.addRow([]);

  // 수확 체감 공식 설명
  ws.mergeCells("A19:H19");
  ws.getCell("A19").value = "훈련 효율 — 수확 체감 공식";
  ws.getCell("A19").font = font(12, true, C.blue);
  ws.getCell("A19").fill = hdrFill(C.lblue);

  const formulaNote = ws.addRow(["실제 상승값 = 기본상승값 × (목표스탯 ÷ 현재스탯)^0.4","","","","","","",""]);
  ws.mergeCells(`A${formulaNote.number}:H${formulaNote.number}`);
  formulaNote.getCell(1).font = font(11, true, C.navy);
  formulaNote.getCell(1).alignment = align("center");

  // 예시 계산
  const exHdr = ws.addRow(["현재 STR","목표 STR","기본상승값","실제상승값(공식)","","","",""]);
  applyHeader(exHdr, ["현재 STR","목표 STR","기본상승값","실제상승값(공식)","","","",""]);

  [[10,80,3],[25,80,3],[40,80,3],[60,80,3],[75,80,3]].forEach((row, i) => {
    const r = ws.addRow([row[0], row[1], row[2], `=C${ws.lastRow.number+1}*(B${ws.lastRow.number+1}/A${ws.lastRow.number+1})^0.4`]);
    styleRow(r, i%2===0 ? C.lgray : C.white);
  });

  // 실제 행 번호로 수식 재설정
  let startRow = 22;
  [[10,80,3],[25,80,3],[40,80,3],[60,80,3],[75,80,3]].forEach((row, i) => {
    const r = ws.getRow(startRow + i);
    r.getCell(1).value = row[0];
    r.getCell(2).value = row[1];
    r.getCell(3).value = row[2];
    r.getCell(4).value = { formula: `=C${startRow+i}*(B${startRow+i}/A${startRow+i})^0.4` };
    r.getCell(4).numFmt = "0.00";
    styleRow(r, i%2===0 ? C.lgray : C.white);
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 3: ⚔️ 전투 시뮬레이터
// ════════════════════════════════════════════════════════════════════════════
(function sheetCombat() {
  const ws = wb.addWorksheet("⚔️ 전투 시뮬레이터", { tabColor:{argb:C.red} });
  ws.columns = [
    {width:22},{width:16},{width:16},{width:16},{width:16},{width:22}
  ];

  ws.mergeCells("A1:F1");
  ws.getCell("A1").value = "전투 데미지 시뮬레이터";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  // ── 입력 섹션 (파란 텍스트 = 수동 입력값)
  ws.addRow([]);
  ws.mergeCells("A3:F3");
  ws.getCell("A3").value = "▶ 입력값 (파란색 셀 수정)";
  ws.getCell("A3").font = font(11, true, C.blue);
  ws.getCell("A3").fill = hdrFill(C.lblue);

  const inputs = [
    ["내 STR",        50, "", "상대 STR",        45, ""],
    ["내 AGI",        45, "", "상대 AGI",        40, ""],
    ["내 TEC",        40, "", "상대 TEC",        35, ""],
    ["내 직업계수",   1.0,"", "상대 직업계수",   1.1,""],
    ["상성 관계",     "유리","(유리/중립/불리)", "","",""],
    ["전략 선택",     "균형","(공격적/균형/방어적)","","",""],
  ];

  const inputStartRow = 4;
  inputs.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("left","middle"); });
    r.getCell(1).font = font(10, true);
    r.getCell(4).font = font(10, true);
    // 파란 텍스트로 입력값 표시
    r.getCell(2).font = font(10, false, "FF0000FF");
    r.getCell(5).font = font(10, false, "FF0000FF");
    if (i%2===0) styleRow(r, C.lgray);
  });

  ws.addRow([]);

  // ── 계산 섹션
  ws.mergeCells(`A${inputStartRow+7}:F${inputStartRow+7}`);
  ws.getCell(`A${inputStartRow+7}`).value = "▶ 계산 결과 (검정 셀 = 자동 계산)";
  ws.getCell(`A${inputStartRow+7}`).font = font(11, true, "FF000000");
  ws.getCell(`A${inputStartRow+7}`).fill = hdrFill(C.mgray);

  // 상성 배율 lookup
  const calcHdr = ws.addRow(["계산 항목","내 수치","상대 수치","차이/비율","비고",""]);
  applyHeader(calcHdr, ["계산 항목","내 수치","상대 수치","차이/비율","비고",""]);

  // 행 번호 참조용
  const STR_ROW = 4, AGI_ROW = 5, TEC_ROW = 6, JOB_ROW = 7;
  const ADV_ROW = 8, STR_TYPE_ROW = 9;
  const CALC_START = inputStartRow + 8;

  const calcs = [
    ["기본 공격력 (ATK)",
      `=($B$${STR_ROW}*1.5+$B$${TEC_ROW}*0.5)*$B$${JOB_ROW}`,
      `=($E$${STR_ROW}*1.5+$E$${TEC_ROW}*0.5)*$E$${JOB_ROW}`,
      `=B${CALC_START}-C${CALC_START}`, "STR×1.5 + TEC×0.5 × 직업계수"],
    ["상성 배율",
      `=IF($B$${ADV_ROW}="유리",1.2,IF($B$${ADV_ROW}="불리",0.8,1.0))`,
      `=IF($B$${ADV_ROW}="유리",0.8,IF($B$${ADV_ROW}="불리",1.2,1.0))`,
      "","유리=1.2, 중립=1.0, 불리=0.8"],
    ["전략 공격 배율",
      `=IF($B$${STR_TYPE_ROW}="공격적",1.15,IF($B$${STR_TYPE_ROW}="방어적",0.85,1.0))`,
      1.0,"","공격적=1.15, 균형=1.0, 방어적=0.85"],
    ["최종 데미지",
      `=B${CALC_START}*B${CALC_START+1}*B${CALC_START+2}`,
      `=C${CALC_START}*C${CALC_START+1}*1.0`,
      `=B${CALC_START+3}-C${CALC_START+3}`, "ATK × 상성 × 전략"],
    ["회피율 (상대)",
      `=$B$${AGI_ROW}/($B$${AGI_ROW}+$E$${AGI_ROW})*0.6`,
      `=$E$${AGI_ROW}/($B$${AGI_ROW}+$E$${AGI_ROW})*0.6`,
      "","최대 40% 캡"],
    ["예상 유효 데미지",
      `=B${CALC_START+3}*(1-MIN(C${CALC_START+4},0.4))`,
      `=C${CALC_START+3}*(1-MIN(B${CALC_START+4},0.4))`,
      `=B${CALC_START+5}-C${CALC_START+5}`, "데미지 × (1 - 상대 회피율)"],
  ];

  calcs.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("right","middle"); });
    r.getCell(1).alignment = align("left","middle");
    r.getCell(1).font = font(10, true);
    if (i%2===0) { r.getCell(2).fill = hdrFill(C.lgreen); r.getCell(3).fill = hdrFill(C.lred); }
    [2,3,4].forEach(ci => {
      if (typeof r.getCell(ci).value === "number" || (r.getCell(ci).value && r.getCell(ci).value.formula)) {
        r.getCell(ci).numFmt = "0.00";
      }
    });
  });

  ws.addRow([]);

  // ── 상성 극복 분석
  ws.mergeCells(`A${CALC_START+8}:F${CALC_START+8}`);
  ws.getCell(`A${CALC_START+8}`).value = "상성 불리 극복 조건 분석";
  ws.getCell(`A${CALC_START+8}`).font = font(12, true, C.red);
  ws.getCell(`A${CALC_START+8}`).fill = hdrFill(C.lorange);

  const ov = ws.addRow(["티어","라이벌 스탯합","플레이어 목표 스탯합","필요 우위(%)","예상 승률","비고"]);
  applyHeader(ov, ["티어","라이벌 스탯합","플레이어 목표 스탯합","필요 우위(%)","예상 승률","비고"]);

  const tiers = [
    ["1. 길거리", 80,  90,  "12.5%", "~53%", "상성 -20%를 스탯으로 보완"],
    ["2. KFC",   160, 185, "15.6%", "~52%", ""],
    ["3. UFC",   250, 290, "16.0%", "~51%", ""],
    ["4. 챔피언",340, 395, "16.2%", "~50%", "라이벌은 항상 상성 불리"],
  ];

  tiers.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i%2===0 ? C.lgray : C.white);
    r.getCell(5).fill = hdrFill(C.lgreen);
    r.getCell(5).font = font(10, true, C.green);
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 4: 🏃 활력 시스템
// ════════════════════════════════════════════════════════════════════════════
(function sheetVitality() {
  const ws = wb.addWorksheet("🏃 활력 시스템", { tabColor:{argb:"FF4472C4"} });
  ws.columns = [
    {width:24},{width:16},{width:16},{width:16},{width:16},{width:24}
  ];

  ws.mergeCells("A1:F1");
  ws.getCell("A1").value = "활력(VIT) 시스템 — 하루 시간 예산";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  ws.addRow([]);

  // 기본 설정값
  ws.mergeCells("A3:F3");
  ws.getCell("A3").value = "▶ 기본 설정값";
  ws.getCell("A3").font = font(11, true, C.blue);
  ws.getCell("A3").fill = hdrFill(C.lblue);

  const vitConfig = [
    ["하루 최대 활력(VIT)", 100, "", "매일 아침 완전 회복"],
    ["집→체육관 이동 비용", 15,  "", "편도 활력 소모"],
    ["체육관→집 이동 비용", 15,  "", "편도 활력 소모"],
    ["이동 총 비용(왕복)",  "=B5+B6", "", "집 장비 있으면 0"],
    ["최대 훈련 가능 활력", "=B4-B7", "", "이동 후 남은 활력"],
  ];

  vitConfig.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("left","middle"); });
    r.getCell(1).font = font(10, true);
    r.getCell(2).font = font(10, false, "FF0000FF");
    if (typeof r.getCell(2).value === "string" && r.getCell(2).value.startsWith("=")) {
      r.getCell(2).value = { formula: r.getCell(2).value };
      r.getCell(2).font = font(10, false, "FF000000");
    }
    if (i%2===0) r.fill = hdrFill(C.lgray);
  });

  ws.addRow([]);

  // 행동별 활력 소모
  ws.mergeCells("A10:F10");
  ws.getCell("A10").value = "▶ 행동별 활력 소모";
  ws.getCell("A10").font = font(11, true, "FF000000");
  ws.getCell("A10").fill = hdrFill(C.mgray);

  const actHdr = ws.addRow(["행동","활력 소모","스탯 효과","비용(골드)","장소","비고"]);
  applyHeader(actHdr, ["행동","활력 소모","스탯 효과","비용(골드)","장소","비고"]);

  const actions = [
    ["집→체육관 이동",     -15, "없음",        0,   "이동", "집 장비 있으면 생략"],
    ["체육관→집 이동",     -15, "없음",        0,   "이동", "집 장비 있으면 생략"],
    ["웨이트 트레이닝",    -20, "STR +3",      0,   "체육관","멤버십 필요"],
    ["달리기",             -10, "AGI +2",      0,   "어디서나","무료"],
    ["줄넘기",             -8,  "AGI+1,VIT+2", 0,   "집/체육관",""],
    ["스파링",             -25, "TEC +3",    200,   "체육관", "상대 초청비 포함 / SP 1점 획득"],
    ["기술 훈련(미트)",    -18, "TEC +2",      0,   "체육관","멤버십 필요"],
    ["식단 관리",          -5,  "HP+10,VIT+5", 50,  "집/편의점",""],
    ["아르바이트",         -20, "없음",        "+75골드","어디서나",""],
    ["휴식",               +30, "STA 회복",    0,   "집",   "활력 회복 (최대 초과 불가)"],
  ];

  actions.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i%2===0 ? C.lgray : C.white);
    if (typeof row[1] === "number" && row[1] < 0) {
      r.getCell(2).font = font(10, true, "FFCC0000");
    } else {
      r.getCell(2).font = font(10, true, C.green);
    }
  });

  ws.addRow([]);

  // 시나리오 비교
  ws.mergeCells(`A${23}:F${23}`);
  ws.getCell("A23").value = "▶ 하루 일과 시나리오 비교";
  ws.getCell("A23").font = font(11, true, C.blue);
  ws.getCell("A23").fill = hdrFill(C.lblue);

  const scnHdr = ws.addRow(["시나리오","이동 소모","훈련 슬롯 수","훈련 가능 활력","스탯 성장 효율","경제 상황"]);
  applyHeader(scnHdr, ["시나리오","이동 소모","훈련 슬롯 수","훈련 가능 활력","스탯 성장 효율","경제 상황"]);

  const scenarios = [
    ["가난 (체육관, 이동O)", 30, 3, 70, "기본", "아르바이트 필요"],
    ["부자 (집 장비, 이동X)", 0, 4, 100, "140%","이동 비용 절감"],
    ["절충 (집 기초+체육관)", 15, 4, 85, "120%","집: STR/AGI, 체육관: TEC"],
  ];

  scenarios.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i===1 ? C.lgreen : (i%2===0 ? C.lgray : C.white));
    if (i===1) r.getCell(5).font = font(10, true, C.green);
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 5: 💰 경제 흐름
// ════════════════════════════════════════════════════════════════════════════
(function sheetEconomy() {
  const ws = wb.addWorksheet("💰 경제 흐름", { tabColor:{argb:"FF70AD47"} });
  ws.columns = [
    {width:22},{width:16},{width:16},{width:16},{width:16},{width:20}
  ];

  ws.mergeCells("A1:F1");
  ws.getCell("A1").value = "경제 흐름 분석 (티어별)";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  ws.addRow([]);

  ws.mergeCells("A3:F3");
  ws.getCell("A3").value = "▶ 주간 고정 비용";
  ws.getCell("A3").font = font(11, true, "FF000000");
  ws.getCell("A3").fill = hdrFill(C.mgray);

  const costHdr = ws.addRow(["지출 항목","비용(골드)","주기","월간 환산","비고",""]);
  applyHeader(costHdr, ["지출 항목","비용(골드)","주기","월간 환산","비고",""]);

  const costs = [
    ["체육관 멤버십", 300, "주간", "=B5*4", "7일마다 자동 차감"],
    ["식단(영양제×5)", 250, "주간", "=B6*4", "50골드×5회"],
    ["주간 고정 지출 합계", "=B5+B6", "주간", "=D5+D6", ""],
  ];

  costs.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); });
    r.getCell(1).font = font(10, true);
    [2,3,4].forEach(ci => {
      if (typeof r.getCell(ci).value === "string" && r.getCell(ci).value.startsWith("=")) {
        r.getCell(ci).value = { formula: r.getCell(ci).value };
        r.getCell(ci).numFmt = "#,##0";
      } else if (typeof r.getCell(ci).value === "number") {
        r.getCell(ci).numFmt = "#,##0";
        r.getCell(ci).font = font(10, false, "FF0000FF");
      }
    });
    if (i===2) styleRow(r, C.lorange);
    else if (i%2===0) styleRow(r, C.lgray);
  });

  ws.addRow([]);

  ws.mergeCells("A9:F9");
  ws.getCell("A9").value = "▶ 티어별 주간 수입 시뮬레이션";
  ws.getCell("A9").font = font(11, true, C.green);
  ws.getCell("A9").fill = hdrFill(C.lgreen);

  const incHdr = ws.addRow(["항목","티어1 길거리","티어2 KFC","티어3 UFC","티어4 챔피언","비고"]);
  applyHeader(incHdr, ["항목","티어1 길거리","티어2 KFC","티어3 UFC","티어4 챔피언","비고"]);

  const income = [
    ["아르바이트 (주 3회)", 225, 225, 225, 225, "75골드 × 3슬롯"],
    ["시합 승리 보너스", 200, 600, 1500, 3000, "티어별 보너스"],
    ["주간 총 수입", "=B12+B13","=C12+C13","=D12+D13","=E12+E13",""],
    ["주간 순이익 (지출 후)", "=B14-$B$7","=C14-$B$7","=D14-$B$7","=E14-$B$7",""],
  ];

  income.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("right","middle"); });
    r.getCell(1).alignment = align("left","middle");
    r.getCell(1).font = font(10, true);
    [2,3,4,5].forEach(ci => {
      if (typeof r.getCell(ci).value === "string" && r.getCell(ci).value.startsWith("=")) {
        r.getCell(ci).value = { formula: r.getCell(ci).value };
        r.getCell(ci).numFmt = "#,##0;(#,##0);-";
      } else if (typeof r.getCell(ci).value === "number") {
        r.getCell(ci).numFmt = "#,##0";
        if (i < 2) r.getCell(ci).font = font(10, false, "FF0000FF");
      }
    });
    if (i===2) styleRow(r, C.lorange);
    if (i===3) {
      r.eachCell(cell => { cell.fill = hdrFill(C.lgreen); cell.font = font(10, true, C.green); });
      r.getCell(1).font = font(10, true);
    }
    if (i%2===0 && i<2) styleRow(r, C.lgray);
  });

  ws.addRow([]);

  // 경제 설계 의도
  ws.mergeCells("A17:F17");
  ws.getCell("A17").value = "▶ 경제 설계 의도";
  ws.getCell("A17").font = font(11, true, C.navy);
  ws.getCell("A17").fill = hdrFill(C.lgray);

  const intents = [
    ["초반 (티어1)", "항상 빠듯하게 설계. 아르바이트 ↔ 훈련 트레이드오프가 핵심 긴장감"],
    ["중반 (티어2)", "시합 보너스 증가로 아르바이트 의존도 감소. 집 장비 구매 가능권 진입"],
    ["후반 (티어3+)", "돈보다 시간 효율 극대화가 더 중요. 스파링 비용도 부담 없는 수준"],
  ];

  intents.forEach((row, i) => {
    const r = ws.addRow(row);
    ws.mergeCells(`B${r.number}:F${r.number}`);
    r.getCell(1).font = font(10, true, C.blue);
    r.getCell(2).alignment = align("left","middle");
    r.eachCell(cell => { cell.border = border(); });
    if (i%2===0) r.fill = hdrFill(C.lgray);
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 6: 🏠 집 장비 투자
// ════════════════════════════════════════════════════════════════════════════
(function sheetHomeEquip() {
  const ws = wb.addWorksheet("🏠 집 장비 투자", { tabColor:{argb:"FFED7D31"} });
  ws.columns = [
    {width:26},{width:16},{width:16},{width:16},{width:16},{width:22}
  ];

  ws.mergeCells("A1:F1");
  ws.getCell("A1").value = "집 장비 투자 ROI 시뮬레이션";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  ws.addRow([]);

  ws.mergeCells("A3:F3");
  ws.getCell("A3").value = "▶ 장비별 효과 및 비용";
  ws.getCell("A3").font = font(11, true, "FF000000");
  ws.getCell("A3").fill = hdrFill(C.mgray);

  const eqHdr = ws.addRow(["장비명","구매 비용","절약 활력/일","제공 훈련","체육관 대체?","비고"]);
  applyHeader(eqHdr, ["장비명","구매 비용","절약 활력/일","제공 훈련","체육관 대체?","비고"]);

  const equips = [
    ["기본 덤벨 세트",   800,  30, "STR 기초",  "부분 (STR만)", "이동 생략 가능"],
    ["런닝머신",        1200,  30, "AGI 기초",  "부분 (AGI만)", "이동 생략 가능"],
    ["홈짐 풀세트",     3500,  30, "STR+AGI",  "부분 (TEC 불가)", "이동 완전 생략"],
    ["샌드백",           600,  15, "STR+TEC기초","부분","체육관 TEC 훈련은 여전히 필요"],
    ["※ 체육관 (비교용)",  0,   0, "STR+AGI+TEC","완전","코치·링 보유. 대체 불가"],
  ];

  equips.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i===4 ? C.lorange : (i%2===0 ? C.lgray : C.white));
    r.getCell(2).numFmt = "#,##0";
    r.getCell(2).font = font(10, false, "FF0000FF");
    if (i===4) {
      r.eachCell(cell => { cell.font = font(10, true, "FF595959"); });
      r.getCell(1).font = font(10, true, "FF595959");
    }
  });

  ws.addRow([]);

  ws.mergeCells("A11:F11");
  ws.getCell("A11").value = "▶ 투자 회수 기간 계산 (홈짐 풀세트 기준)";
  ws.getCell("A11").font = font(11, true, C.green);
  ws.getCell("A11").fill = hdrFill(C.lgreen);

  // 홈짐 ROI
  const roiData = [
    ["홈짐 구매 비용", 3500, "골드", ""],
    ["일일 절약 활력", 30, "VIT/일", "왕복 이동 생략"],
    ["활력 → 추가 훈련 슬롯", "=B13/20", "슬롯/일", "슬롯당 활력 20 기준"],
    ["슬롯 → 추가 스탯/일", "=B14*2.5", "스탯포인트/일","평균 2.5SP/슬롯"],
    ["아르바이트 대신 훈련 시", "절약", "기회비용", "75골드/슬롯 기회비용"],
    ["시합 보너스 증가 (성장↑)", "+15%", "예상 승률 향상",""],
    ["투자 회수 예상 (시합 기준)", "=B12/(300*0.15)", "회(시합)", "시합 보너스의 15% 기여로 계산"],
  ];

  roiData.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("left","middle"); });
    r.getCell(1).font = font(10, true);
    if (typeof r.getCell(2).value === "string" && r.getCell(2).value.startsWith("=")) {
      r.getCell(2).value = { formula: r.getCell(2).value };
      r.getCell(2).numFmt = "0.0";
      r.getCell(2).font = font(10, false, "FF000000");
    } else if (typeof r.getCell(2).value === "number") {
      r.getCell(2).numFmt = "#,##0";
      r.getCell(2).font = font(10, false, "FF0000FF");
    }
    if (i%2===0) styleRow(r, C.lgray);
  });

  ws.addRow([]);

  // 설계 의도 메모
  ws.mergeCells("A21:F21");
  ws.getCell("A21").value = "⚠ 설계 의도: 집 장비는 체육관을 완전히 대체하지 않는다";
  ws.getCell("A21").font = font(11, true, C.red);
  ws.getCell("A21").fill = hdrFill(C.lred);

  const memos = [
    ["STR/AGI 훈련은 집 장비로 가능 → 이동 비용 절감"],
    ["TEC (기술) 훈련은 체육관 코치·스파링 상대 필요 → 체육관 계속 방문해야 함"],
    ["결과: 집 장비 구매 = 이동 낭비 줄이기. 체육관 멤버십은 여전히 필요"],
  ];

  memos.forEach((row, i) => {
    const r = ws.addRow(row);
    ws.mergeCells(`A${r.number}:F${r.number}`);
    r.getCell(1).font = font(10, false, "FF000000");
    r.getCell(1).border = border();
    r.getCell(1).alignment = align("left","middle");
    if (i%2===0) r.getCell(1).fill = hdrFill(C.lgray);
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 7: 🥊 스파링 비용
// ════════════════════════════════════════════════════════════════════════════
(function sheetSparring() {
  const ws = wb.addWorksheet("🥊 스파링 비용", { tabColor:{argb:C.red} });
  ws.columns = [
    {width:26},{width:16},{width:16},{width:16},{width:16},{width:22}
  ];

  ws.mergeCells("A1:F1");
  ws.getCell("A1").value = "스킬포인트(SP) 획득 경로 분석";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  ws.addRow([]);
  ws.mergeCells("A3:F3");
  ws.getCell("A3").value = "▶ SP 획득 방법 비교";
  ws.getCell("A3").font = font(11, true, "FF000000");
  ws.getCell("A3").fill = hdrFill(C.mgray);

  const spHdr = ws.addRow(["방법","SP 획득","비용(골드)","활력 소모","빈도","비고"]);
  applyHeader(spHdr, ["방법","SP 획득","비용(골드)","활력 소모","빈도","비고"]);

  const spMethods = [
    ["공식 경기 승리",  2, 0,   0, "티어당 3~7회", "패배 시 0 (부상 위험)"],
    ["공식 경기 패배",  0, 0,   0, "—",           "SP 없음, 스탯 손실 가능"],
    ["스파링 (상대 초청)", 1, 200, 25, "제한 없음",  "안전, 반복 가능"],
    ["스파링 (팀 내부)", 1, 50,  25, "주 3회 제한", "팀 합류 후 가능 (중반 이후)"],
  ];

  spMethods.forEach((row, i) => {
    const r = ws.addRow(row);
    styleRow(r, i%2===0 ? C.lgray : C.white);
    r.getCell(3).numFmt = "#,##0";
    r.getCell(3).font = font(10, false, "FF0000FF");
    if (i===0) { r.getCell(2).fill = hdrFill(C.lgreen); r.getCell(2).font = font(10, true, C.green); }
  });

  ws.addRow([]);

  ws.mergeCells("A10:F10");
  ws.getCell("A10").value = "▶ 스파링 상대 초청 비용 (티어별)";
  ws.getCell("A10").font = font(11, true, C.blue);
  ws.getCell("A10").fill = hdrFill(C.lblue);

  const tierHdr = ws.addRow(["티어","초청 비용/회","SP 획득","SP당 비용","주간 최대 SP","주간 총 비용"]);
  applyHeader(tierHdr, ["티어","초청 비용/회","SP 획득","SP당 비용","주간 최대 SP","주간 총 비용"]);

  const spTiers = [
    ["1. 길거리", 100, 1, "=C12/B12", 3, "=B12*E12"],
    ["2. KFC",    200, 1, "=C13/B13", 4, "=B13*E13"],
    ["3. UFC",    400, 1, "=C14/B14", 5, "=B14*E14"],
    ["4. 챔피언", 700, 1, "=C15/B15", 5, "=B15*E15"],
  ];

  spTiers.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("right","middle"); });
    r.getCell(1).alignment = align("left","middle");
    r.getCell(1).font = font(10, true);
    [2,3,4,5,6].forEach(ci => {
      const v = r.getCell(ci).value;
      if (typeof v === "string" && v.startsWith("=")) {
        r.getCell(ci).value = { formula: v };
        r.getCell(ci).numFmt = "#,##0";
      } else if (typeof v === "number") {
        r.getCell(ci).numFmt = "#,##0";
        if (ci===2) r.getCell(ci).font = font(10, false, "FF0000FF");
      }
    });
    if (i%2===0) styleRow(r, C.lgray);
  });

  ws.addRow([]);

  // 스킬 트리 완성 비용
  ws.mergeCells("A17:F17");
  ws.getCell("A17").value = "▶ 스킬 트리 완성에 필요한 총 SP 및 비용 추산";
  ws.getCell("A17").font = font(11, true, C.red);
  ws.getCell("A17").fill = hdrFill(C.lred);

  const totalSP = [
    ["총 스킬 수",          9, "개", "3×3 트리"],
    ["스킬당 필요 SP",      1, "SP", "1스킬 = SP 1"],
    ["총 필요 SP",        "=B18*B19", "SP", ""],
    ["경기로 획득 SP",    "=3+4+5+2",  "SP", "티어1(3)+2(4)+3(5)+4방어(2)"],
    ["스파링으로 충당 SP","=B20-B21", "SP", ""],
    ["스파링 평균 비용",  200, "골드/회","티어 평균"],
    ["스파링 총 비용 추산","=B23*B24","골드","스파링만으로 채울 경우"],
  ];

  let sr = 18;
  totalSP.forEach((row, i) => {
    const r = ws.addRow(row);
    r.eachCell(cell => { cell.border = border(); cell.alignment = align("left","middle"); });
    r.getCell(1).font = font(10, true);
    const v = r.getCell(2).value;
    if (typeof v === "string" && v.startsWith("=")) {
      r.getCell(2).value = { formula: v };
      r.getCell(2).numFmt = "#,##0";
    } else if (typeof v === "number") {
      r.getCell(2).numFmt = "#,##0";
      r.getCell(2).font = font(10, false, "FF0000FF");
    }
    if (i%2===0) styleRow(r, C.lgray);
    sr++;
  });
})();

// ════════════════════════════════════════════════════════════════════════════
// 시트 8: 📝 조정 이력
// ════════════════════════════════════════════════════════════════════════════
(function sheetLog() {
  const ws = wb.addWorksheet("📝 조정 이력", { tabColor:{argb:C.gray} });
  ws.columns = [
    {width:14},{width:22},{width:18},{width:18},{width:30},{width:16}
  ];

  ws.mergeCells("A1:F1");
  ws.getCell("A1").value = "밸런스 조정 이력 — 플레이테스트 후 기록";
  ws.getCell("A1").font = font(14, true, C.navy);
  ws.getCell("A1").alignment = align("center");
  ws.getCell("A1").fill = hdrFill(C.lgray);

  ws.addRow([]);

  const logHdr = ws.addRow(["날짜","조정 항목","변경 전 값","변경 후 값","변경 이유","담당"]);
  applyHeader(logHdr, ["날짜","조정 항목","변경 전 값","변경 후 값","변경 이유","담당"]);

  // 샘플 첫 행
  const sample = ws.addRow(["2026-05-25","(초기값 설정)","—","v0.1 전체","GDD 기반 초기값 입력","기획팀"]);
  styleRow(sample, C.lgray);

  // 빈 행 10개 (추후 기록용)
  for (let i=0; i<10; i++) {
    const r = ws.addRow(["","","","","",""]);
    r.eachCell(cell => { cell.border = border(); });
    if (i%2===0) styleRow(r, C.lgray);
  }

  ws.addRow([]);
  ws.mergeCells(`A${17}:F${17}`);
  ws.getCell("A17").value = "※ 플레이테스트 후 수치를 변경할 때마다 이 시트에 기록하세요. 밸런스 기획 포트폴리오의 핵심 증거입니다.";
  ws.getCell("A17").font = font(10, true, C.red);
  ws.getCell("A17").fill = hdrFill(C.lorange);
  ws.getCell("A17").alignment = align("left","middle");
  ws.getCell("A17").border = border();
})();

// ── 저장
wb.xlsx.writeFile("E:\\GameDesignGYM\\docs\\balance\\Balance_Sheet_Road_to_Glory.xlsx")
  .then(() => console.log("Balance_Sheet_Road_to_Glory.xlsx 생성 완료!"))
  .catch(e => { console.error(e); process.exit(1); });
