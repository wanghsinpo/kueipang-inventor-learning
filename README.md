# Inventor COM 自動建模 — 學習日誌

## Latest Codex Continuation - Round 189

- Captured `round189_KE-SL-022/result.md` from the prior unfinished run.
- Real part: square sleeve `52 x 52 x 52 mm`, volume `9441.3 mm^3`.
- `auto_ring_v2` overestimated volume by `+72.20%` because it detected an
  internal stepped-seat radius (`24 mm`) instead of the effective bore
  (`~24.86 mm`).
- Added `auto_ring_v3.ps1`; on R189 it back-calculated ID radius `24.8638 mm`
  and improved the error to `-0.8462%`.
- R190 validated the bidirectional version: detected bore was too large, and
  back-calc improved `-34.38%` to `-0.4906%`.
- R191 batch-tested v3 on R183-R188: six recent failures from `-57%..+33%`
  all improved to sub-1% volume error.
- R192 batch-tested R179-R182: four A150/ESA200 failures from `-45%..-38%`
  all improved to sub-1% volume error.
- R193 batch-tested R174-R178: AA/KMB failures improved to sub-1%, while
  already-good A70W/GE024 cases were left unchanged.
- R194 batch-tested R170-R173: KMB1203E/SD90 sleeve improved to sub-1%, but
  small SD90 ring stayed at `-7%`, pointing to over-large generic chamfers.
- R195 scaled chamfer by OD; SD90 ring improved from `-7.05%` to `+0.585%`
  without changing large-sleeve results.
- R196 batch-tested R166-R169: HC60E/ESA300G/EV-X200N failures moved to
  roughly sub-0.5% volume error; MU100 stayed around 1%.
- New rule: thin-wall KE-SL sleeves need a volume sanity gate and effective bore
  back-calculation before trusting detected cylinder radii.

## Latest Codex Continuation - Round 20 Redo

- Added `auto_box_v1.ps1` for pure six-plane rectangular parts.
- Re-inspected `round20_SDE300_baffle/real.ipt`: bbox `1 x 7.7 x 61 mm`,
  volume `469.7 mm^3`, zero cylinder faces.
- Generated `round20_SDE300_baffle/my_attempt_box_v1.ipt` with `0.0000%`
  volume error.
- Current Drive connector profile is `andy30383917@gmail.com`, not the
  service account recorded in `AGENTS.md`; searches for `KE-SP`, `EV-L200`,
  and `Inventor` did not expose new part files in this session.

> Claude 透過 Inventor COM API 從 PDF / 照片 / 真檔 .ipt 學習機械零件建模的循環學習實驗。
> 每輪：拿真檔工程圖 → 用 PowerShell COM 自動畫 → 跟真檔對答案 → 總結經驗 → 改進下輪。

## 進度速覽

| 輪次 | 零件 | 結果 | 主要學到 |
|---|---|---|---|
| 1 | EV-L200-MP Flinger | Vol +106% | 內腔 vs 外形誤判 |
| 2 (v1) | EV-L200 培林座 | -43% + 形狀全錯 | BBox 預估必做 |
| 3 | 58.4×17×5.2 N52 磁鐵 | **+0.07%** ✓ | enum 5124 是 ObjectType |
| 4 (v1→v3) | EV-L200-BP Flinger | +167% → +3.6% | top-hat 不是錐形 |
| 5 | EV-L200-BP 小間隔環 | +2.7% | 流程驗證穩定 |
| 6 (v1→v6) | EV-L200 培林座（重做）| -43% → +6.7% | 4 個槽不貫穿、chord cut 在 NW |
| 7 | KE-BH-069 (左鏡像) | **+5.89%** 第一輪 | 鏡像零件複用 R6 結構 |
| 8 | KE-BH-071 X200N | **+10.29%** 第一輪 | 頂底槽 90° 垂直新 pattern |
| 9 | KE-SP-018 大間隔環 | +14% | 軸 Z=0 = 徑向銷孔 |
| 10 | KE-SP-019 EVM 間隔環 | +10% | 通用 auto_ring 工具誕生 |
| 11 | KE-BH-062 X100 G | (跳過) | 多軸承座法蘭超出當前能力 |
| 12 | R1 重做 (MP Flinger) | +103% | top-hat 結構解讀仍困難 |
| 13 | KE-SP-003 ESR100 | **🎯 0.00%** | auto_ring 完美對 |
| 14 | KE-SP-004 (誤抓 P2 子件) | +300% | auto_ring 在複雜件失效 |

## 主要結論（14 輪後）

**簡單環類零件**：用 `round10_KE-SP-019_EVM/auto_ring.ps1` 通用工具，從真檔讀 BBox + 兩個圓柱半徑直接建模 → **0-3% 收斂**（R3, R5, R10, R13）

**中等複雜鑄件（培林座）**：第一輪能到 +5-10%（R7, R8）— 套用 R6 的「BBox + 真檔幾何 dump + chord cut + 不貫穿槽」黃金模板

**複雜旋轉件（Flinger）**：top-hat 結構容易誤判成連續錐 → R1, R4, R12 都踩坑

**多軸承座法蘭**：超出當前能力，需要不同建模策略（R11 跳過）

## 技術棧

- Inventor 2027 + COM API
- PowerShell 5.1 自動化
- Google Drive MCP 抓 PDF + .ipt
- 對答工具：MassProperties + RangeBox + 多視圖渲染（SaveAsBitmap）

## 重要文件

- `LESSONS_LEARNED.md` — 完整經驗庫（7 大概念教訓 + 10+ 工具坑 + 流程黃金規則）
- `round{N}_*/` — 各輪原始檔案（PDF + 我畫的 .ipt + 真檔 .ipt + 比對腳本）
- `build_part.ps1` — 第 0 輪用照片建的 demo（軸承座，從手機照片估尺寸）

## 黃金 5 步流程

1. **看 iso 視圖判斷整體形狀**（top-hat / 旋轉體 / 平板 / 圓柱 ...）
2. **算 BBox 預估**（從 PDF 最大尺寸 + 厚度算 X×Y×Z）
3. **找帶緊公差的尺寸**（±0.01～0.05 = 配合面 = 必對）
4. **看剖面 + Pappus 預估體積**（寫進腳本當 sanity gate）
5. **跟真檔幾何 dump 對答**（圓柱 R + axis、平面 root + normal、面積 → 反推每個特徵）

## 工具坑速查

| # | 坑 | 解 |
|---|---|---|
| 1 | Configurator 360 對話框卡死 Documents.Add | 起背景 nag-watcher PostMessage(WM_CLOSE) |
| 2 | SketchLines.AddByTwoPoints 混 Point2d/SketchPoint E_FAIL | 先建 SketchPoints 再連線 |
| 3 | Edge.GeometryType=5124 是 ObjectTypeEnum | 圓邊用 5124，不是 38914 |
| 4 | ChamferFeatures.CreateChamferDefinition 不存在 (2027) | 用 AddUsingDistance |
| 5 | Camera.ViewOrientationType 直接賦值 fail | 用 Eye/Target/UpVector |
| 6 | PowerShell `,@()` 內含複雜表達式 parser 爆 | 拆分行算或 hard-code |
| 7 | PowerShell `$pid` reserved | 改名 `$invPid` |
| 8 | 內聯 `if(){}else{}` 在參數位置不能用 | 先賦值給變數 |
| 9 | GDrive download 結構 | `content[0].embeddedResource.contents.blob` (base64) |
| 10 | 從 face 切入方向 | 用 sketch face normal 判斷 material 在哪邊 |

---

## 你回來時推上 GitHub 的步驟

```powershell
cd "$env:USERPROFILE\Desktop\test"
& "C:\Program Files\GitHub CLI\gh.exe" auth login   # 跟著瀏覽器登入
& "C:\Program Files\GitHub CLI\gh.exe" repo create kueipang-inventor-learning --public --source . --push
```

或如果你想私人 repo：把 `--public` 改成 `--private`。

---

🤖 Built with [Claude Code](https://claude.com/claude-code)
