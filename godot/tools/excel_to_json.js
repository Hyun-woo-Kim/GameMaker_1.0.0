/**
 * excel_to_json.js
 * Excel 밸런스 시트 → Godot용 JSON 변환기
 *
 * 사용법:
 *   node excel_to_json.js
 *   node excel_to_json.js --file "docs/balance/Balance_Sheet_Road_to_Glory.xlsx"
 *
 * 출력: godot/data/json/ 폴더에 JSON 파일 자동 생성
 */

const ExcelJS = require("exceljs");
const fs      = require("fs");
const path    = require("path");

const ROOT       = path.resolve(__dirname, "../../");
const EXCEL_PATH = path.join(ROOT, "docs/balance/Balance_Sheet_Road_to_Glory.xlsx");
const JSON_OUT   = path.join(ROOT, "godot/data/json/");

// 커맨드라인 인자 처리
const args = process.argv.slice(2);
const fileArg = args.indexOf("--file");
const excelPath = fileArg >= 0 ? path.resolve(args[fileArg + 1]) : EXCEL_PATH;

async function main() {
  console.log("=== Excel → JSON 변환 시작 ===");
  console.log("입력:", excelPath);
  console.log("출력:", JSON_OUT);

  if (!fs.existsSync(excelPath)) {
    console.error("오류: Excel 파일을 찾을 수 없습니다 →", excelPath);
    process.exit(1);
  }

  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(excelPath);

  const results = {};

  // ── 시트별 변환 처리 ────────────────────────────────────────────────────

  // 📊 스탯 성장 시트 → stat_targets.json
  results["stat_targets"] = extractStatTargets(wb.getWorksheet("📊 스탯 성장"));

  // 🏃 활력 시스템 시트 → vitality_config.json
  results["vitality_config"] = extractVitalityConfig(wb.getWorksheet("🏃 활력 시스템"));

  // 💰 경제 흐름 시트 → economy_balance.json
  results["economy_balance"] = extractEconomyBalance(wb.getWorksheet("💰 경제 흐름"));

  // 🥊 스파링 비용 시트 → sparring_costs.json
  results["sparring_costs"] = extractSparringCosts(wb.getWorksheet("🥊 스파링 비용"));

  // ── JSON 파일 저장 ──────────────────────────────────────────────────────
  let savedCount = 0;
  for (const [name, data] of Object.entries(results)) {
    if (!data || Object.keys(data).length === 0) {
      console.warn("⚠ 변환 데이터 없음 →", name);
      continue;
    }
    const outPath = path.join(JSON_OUT, `${name}.json`);
    fs.writeFileSync(outPath, JSON.stringify(data, null, 2), "utf8");
    console.log("✓ 저장:", outPath);
    savedCount++;
  }

  console.log(`\n=== 완료: ${savedCount}개 파일 생성 ===`);
}

// ── 추출 함수들 ────────────────────────────────────────────────────────────

function extractStatTargets(ws) {
  if (!ws) return {};
  const data = { targets: {}, decay: {} };

  // 4행부터 스탯 목표값 읽기 (헤더: 스탯/시작값/티어1/티어2/티어3/티어4)
  ws.eachRow((row, rowNum) => {
    if (rowNum < 4 || rowNum > 9) return;
    const statName = cellVal(row, 1);
    if (!statName || statName.startsWith("※")) return;
    const key = statName.split(" ")[0];
    data.targets[key] = {
      start: numVal(row, 2),
      tier1: numVal(row, 3),
      tier2: numVal(row, 4),
      tier3: numVal(row, 5),
      tier4: numVal(row, 6),
    };
  });

  // 12행부터 감소율 읽기
  ws.eachRow((row, rowNum) => {
    if (rowNum < 13 || rowNum > 17) return;
    const statName = cellVal(row, 1);
    if (!statName) return;
    data.decay[statName] = {
      base:     numVal(row, 2),
      sta_low:  numVal(row, 3),
    };
  });

  return data;
}

function extractVitalityConfig(ws) {
  if (!ws) return {};
  const data = {};

  ws.eachRow((row, rowNum) => {
    if (rowNum < 4 || rowNum > 8) return;
    const key = cellVal(row, 1);
    if (!key) return;
    const keyMap = {
      "하루 최대 활력(VIT)": "vitality_max",
      "집→체육관 이동 비용": "travel_cost_one_way",
      "체육관→집 이동 비용": "travel_cost_return",
      "이동 총 비용(왕복)":  "travel_cost_total",
      "최대 훈련 가능 활력": "max_training_vit",
    };
    const jsonKey = keyMap[key];
    if (jsonKey) data[jsonKey] = numVal(row, 2);
  });

  // 행동별 활력 소모 (12행부터)
  data.action_costs = {};
  ws.eachRow((row, rowNum) => {
    if (rowNum < 12 || rowNum > 22) return;
    const action = cellVal(row, 1);
    if (!action || action.includes("이동")) return;
    data.action_costs[action] = {
      vit_cost:   numVal(row, 2),
      stat_effect: cellVal(row, 3),
      gold_cost:   cellVal(row, 4),
      location:    cellVal(row, 5),
    };
  });

  return data;
}

function extractEconomyBalance(ws) {
  if (!ws) return {};
  const data = {
    weekly_costs: {},
    match_rewards: { tier1: {}, tier2: {}, tier3: {}, tier4: {} },
  };

  // 고정 비용 (5~7행)
  ws.eachRow((row, rowNum) => {
    if (rowNum < 5 || rowNum > 7) return;
    const item = cellVal(row, 1);
    if (!item) return;
    data.weekly_costs[item] = numVal(row, 2);
  });

  return data;
}

function extractSparringCosts(ws) {
  if (!ws) return {};
  const data = { by_tier: {}, sp_sources: [] };

  // SP 획득 방법 (5~9행)
  ws.eachRow((row, rowNum) => {
    if (rowNum < 5 || rowNum > 8) return;
    const method = cellVal(row, 1);
    if (!method) return;
    data.sp_sources.push({
      method,
      sp_gain:     numVal(row, 2),
      gold_cost:   numVal(row, 3),
      vit_cost:    numVal(row, 4),
      frequency:   cellVal(row, 5),
    });
  });

  // 티어별 스파링 비용 (12~15행)
  ws.eachRow((row, rowNum) => {
    if (rowNum < 12 || rowNum > 15) return;
    const tier = cellVal(row, 1);
    if (!tier) return;
    const tierKey = "tier" + rowNum - 11;
    data.by_tier[tierKey] = {
      label:       tier,
      invite_cost: numVal(row, 2),
      sp_per_session: numVal(row, 3),
    };
  });

  return data;
}

// ── 유틸리티 ───────────────────────────────────────────────────────────────
function cellVal(row, col) {
  const cell = row.getCell(col);
  const v = cell.value;
  if (v === null || v === undefined) return null;
  if (typeof v === "object" && v.result !== undefined) return v.result;
  if (typeof v === "object" && v.text !== undefined) return v.text;
  return String(v).trim();
}

function numVal(row, col) {
  const v = cellVal(row, col);
  if (v === null) return 0;
  const n = parseFloat(String(v).replace(/,/g, ""));
  return isNaN(n) ? 0 : n;
}

main().catch(e => { console.error(e); process.exit(1); });
