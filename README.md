# Inventor COM 自動建模 — 學習日誌

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

## 主要結論

**簡單零件（環、磁鐵）** 第一輪就能 < 3% 收斂；
**複雜鑄件（培林座）** 需要多輪迭代 + 真檔幾何 dump 才能 < 10%；
**Flinger 類旋轉件** 容易誤判 top-hat 結構成連續錐。

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

🤖 Built with [Claude Code](https://claude.com/claude-code)
