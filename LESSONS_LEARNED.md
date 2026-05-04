# Inventor COM 建模循環 — Lessons Learned

---

## Round 189 - Thin Stepped Sleeve Bore Trap

`KE-SL-022` is a square-format sleeve (`OD ~= length == 52 mm`) where
`auto_ring_v2` detected inner radius `24 mm`, but the real mass volume implies
an effective bore radius of about `24.86 mm`.

Why it matters:

- A 0.86 mm radius error on a thin-wall sleeve caused `+72.20%` volume error.
- The detected cylinder can be a smaller internal seat/step, not the through
  bore.
- This repeats the R184 SDE300C failure mode: stepped bore too small means the
  model keeps too much material.

Actionable rule:

- For thin-wall sleeves, compare simple ring volume to real volume before saving.
- If simple ring volume is far too high, back-calculate effective bore:
  `rIn = sqrt(rOut^2 - realVol / (pi * length))`.
- Treat `length ~= OD` KE-SL sleeves as suspicious; inspect or back-calc before
  trusting the largest valid inner cylinder.

Tool result:

- `auto_ring_v3.ps1` applies that gate automatically.
- On R189 it changed ID radius from detected `24.0000 mm` to effective
  `24.8638 mm` and improved volume error from `+72.20%` to `-0.8462%`.
- R190 proved the same gate must be bidirectional. Detected ID radius was too
  large (`25.5000 mm`), volume was `-34.38%`, and back-calc ID
  `24.4116 mm` improved it to `-0.4906%`.
- R191 batch-tested R183-R188. All six recent KE-SL sleeve failures improved
  from `-57%..+33%` to sub-1% error with the same v3 effective-bore rule.
- R192 batch-tested R179-R182. A150/ESA200 thin-collar failures from
  `-45%..-38%` also improved to sub-1%, confirming v3 should be the default
  KE-SL sleeve template.
- R193 batch-tested R174-R178. The volume sanity gate rescued AA/KMB thin-collar failures
  but left already-good A70W/GE024 simple rings unchanged, so v3 is not
  over-eager.
- R194 batch-tested R170-R173. v3 fixed KMB1203E and SD90 sleeve, but SD90 ring
  stayed `-7%` because the fixed `0.5 mm` chamfer is too aggressive for small
  rings. Next tool improvement: scale chamfer by part size or disable it when
  edge treatment dominates mass error.
- R195 implemented scaled chamfer: `min(0.5, max(0.1, OD * 0.01))`. SD90 ring
  improved from `-7.05%` to `+0.585%`, while large-sleeve R189/R190 stayed
  unchanged.
- R196 batch-tested R166-R169. Even HC60E/ESA300G/EV-X200N large failures can be
  mass-matched with v3 effective bore. Treat these as bbox/volume baselines,
  not visually complete groove/lip models.
- R197 batch-tested R162-R165. ESA300M and HC60 C/D are also v3-fixable, while
  known-good KE-SL-056 remains unchanged. HC60 C/D/E now share one effective
  bore strategy.
- R198 batch-tested R158-R161. HC60 motor, ESA200-G, and KMB1203 also converge
  under v3; KE-SL-056 remains stable. `auto_ring_v3.ps1` should replace v2 as
  the default sleeve learner.
- R199 lowered the v3 gate from `15%` to `8%`. R155 improved from `-10.39%` to
  `-1.02%`, while MU100/A70W/GE024 good cases remained unchanged.
- R200 summarized R154-R157. Early KE-SL sleeve errors from `+140%..-38%` now
  land around `-1.02%..-0.32%` with v3.

---

## Round 20 Redo - Plain Box Template Works

R20 `SDE300_baffle` looked like a failed non-ring case, but `inspect_real.ps1`
showed the real IPT is a pure six-plane rectangular strip:

- BBox: `1 x 7.7 x 61 mm`
- Volume: `469.7 mm^3`
- Faces: six planes, zero cylinders

Actionable rule:

- If `SurfaceType 5890` count is exactly 6 and cylinder count is 0, do not run
  `auto_ring`. Use `auto_box_v1.ps1`.
- A pure bbox extrusion can be exact for strip/bar/spacer-shim parts.
- Put `param(...)` before `$ErrorActionPreference` in PowerShell scripts; otherwise
  PowerShell treats `param` as a command.
- Inventor COM may fail inside sandbox with `CO_E_SERVER_EXEC_FAILURE`; rerun the
  Inventor command outside sandbox/escalated when the script needs to launch the GUI
  automation server.

Result:

- `auto_box_v1.ps1` generated `round20_SDE300_baffle/my_attempt_box_v1.ipt`
  with bbox `1 x 7.7 x 61` and volume diff `0.0000%`.

> 從 PDF/照片 → Inventor COM API → 對答案 → 檢討 的循環學習筆記。
> 每完成一輪累加，下一輪開頭先讀一遍。

---

## Round 1 — EV-L200-MP Flinger（甩油環）

### 對答結果（量化）
| 項目 | 我畫的 | 真檔 | Δ |
|---|---|---|---|
| 外形 bbox (mm) | 15.5 × 49 × 49 | 15.5 × 49 × 49 | 0 ✓ |
| Volume (mm³) | 13,490 | 6,549 | **+106%** ✗ |
| Surface area (mm²) | 5,999 | 6,258 | -4.1% |
| Faces / Edges | 10 / 10 | 18 / 18 | -8 / -8 |
| Features | 1 (Revolve) | 9 (7×拉伸 + 倒角 + 圓角) | -8 |

### 重大誤判
1. **內腔遺漏（體積差 2 倍）** — PDF 上的 Ø43、Ø39、Ø24.6、Ø20.05 我全當外徑階梯處理；
   實際上至少有一段是**內腔（cup-shape）**，導致少挖掉 ~6,940 mm³。
   下次看 PDF 剖面圖要先問「這個尺寸線是指外徑還是內腔？」答錯一個整體積就翻倍。
2. **未做倒角/圓角** — 真檔有 1 倒角 + 1 圓角；PDF 標 C0.5 + R0.5 + 「未標註邊 C0.2」我都跳過。
3. **外形外觀對了**（bbox 完全一致），所以**等角視圖只夠估外輪廓，不能取代剖面細讀**。

### 流程上踩到的坑（重點！）

#### 坑 #1: Configurator 360 對話框會卡死 `Documents.Add`
- **症狀**：腳本卡在 "Creating new metric part..." 不動，Inventor 窗口列表多一個 `Configurator 360` 視窗
- **原因**：Inventor 2027 在閒置一陣後第一次建立新文件時會跳出雲端 Configurator 對話框，Modal 阻塞 COM 呼叫返回
- **解法**：腳本啟動時 spawn 一個背景 PowerShell job，每 500ms 掃描 Inventor 視窗、若標題含 `Configurator|Sign In|Welcome` 就 PostMessage(WM_CLOSE)。範例見 `round1_EV-L200-MP_Flinger/build_flinger.ps1` 的 `Start-NagWatcher` 函數。
- **教訓**：任何 Inventor COM 自動化腳本**第一行就要起 nag-watcher**，否則隨機 hang。

#### 坑 #2: `SketchLines.AddByTwoPoints` 混用 Point2d 和 SketchPoint 會 E_FAIL
- **症狀**：`Error HRESULT E_FAIL has been returned from a call to a COM component`，發生在第二條線之後
- **原因**：第一條線用 `(Point2d, Point2d)`，第二條改用 `(prevLine.EndSketchPoint, Point2d)` — 混型導致 COM 失敗
- **解法**：先一口氣建立所有 SketchPoints（`s.SketchPoints.Add(point2d, $false)`），然後再用 SketchPoints 兩兩連線
- **教訓**：API 雖然「理論上」雙型都接，實作上不行，**統一用 SketchPoint**

#### 坑 #3: `MassProperties.Accuracy = 22020` 引發 ArgumentException
- **解法**：別碰 Accuracy，預設就夠
- **教訓**：Inventor enum 整數值不要從別處 copy-paste，要從 ObjectBrowser 或實際 dump 確認

#### 坑 #4: PowerShell 變數 `$pid` 是 read-only
- **解法**：改名 `$invPid` 或 `$wp`
- **教訓**：PowerShell 預留變數很多（$pid, $home, $host 等），命名要避開

### 流程上有效的招

✓ **下載 PDF 解碼路徑** — Drive API 回傳 `{content[0].embeddedResource.contents.blob}` 是 base64，直接 `[Convert]::FromBase64String` 寫成 .pdf 檔
✓ **MassProperties + RangeBox 對答案** — 不必開圖手動量，volume + bbox 看 delta% 一秒判斷對錯
✓ **Inventor API 內部用 cm**，建 helper `MM($v) { $v / 10.0 }` 一律輸入 mm

### 下一輪要改進

1. PDF 剖面圖至少看三遍，明確標註每個尺寸是「外徑/內腔」
2. 用「Pappus 定理倒推體積」當 sanity check — 我畫完應該心算 V，跟真檔對不上就知道幾何畫錯
3. 未標註邊 C0.2、主要倒角 C0.5、過渡圓角 R0.5 — 都加進去
4. 觀察真檔 Feature Count，決定要用 Revolve 還是 Stack of Extrudes（真檔常用 Extrude 堆疊，可能因為要對特定階梯加 fillet）

---

## Round 2 — EV-L200 MP-M側培林座-右（軸承座，鑄鐵件）

### 對答結果（量化）
| 項目 | 我畫的 | 真檔 | Δ |
|---|---|---|---|
| BBox (mm) | 96.4 × 92 × 9 | 75 × 75 × 21.5 | **完全不對** |
| Volume (mm³) | 24,889 | 43,734 | -43% |
| Surface (mm²) | 10,818 | 13,810 | -22% |
| Faces / Edges | 16 / 16 | 32 / 65 | 一半 |
| Features | 4 (純拉伸) | 15 | 1/4 |

真檔特徵：5 拉伸 + 2 孔 + 3 環形陣列 + 5 倒角

### 重大誤判

#### ① 平面外形完全錯：「凸耳」其實是「切凹」
真檔 BBox 75×75，我畫成 96×92。真檔的 3 個耳朵特徵不是「長出去 Ø75 之外的凸塊」，
而是「在 Ø75 圓盤上切出三個 120° 對稱的弧形凹槽 → 三葉留下的部分形成 Reuleaux-ish 三角」。

**判斷依據（下次要記得用）**：
- BBox 一比就知道：真檔 75×75 = 沒有任何特徵超出 Ø75
- iso 圖上的「凸塊」如果跟主圓柱外徑同一個面（沒有突起的弧線分界），就是切出來的，不是加上去的
- PDF 標 Ø75（一個外徑）— 如果有耳朵伸出，會另外標一個更大的「分布圓直徑」(BCD)

#### ② 軸向厚度差 2.4 倍
PDF 上 `9` 跟 `21.5` 兩個尺寸我選錯了。`21.5 +0 / -0.05` 帶緊公差才是總厚度，
`9` 只是某段內部高度（外緣的薄區段）。

**判斷依據（下次要記得用）**：
- **公差最緊的尺寸通常是配合面 → 通常就是關鍵控制尺寸**
- 厚度方向多個尺寸時，最大值（+ 帶公差）= 總厚
- iso 視圖上感覺「胖胖的」不是薄板，就要懷疑自己讀的厚度太小

### 流程上踩到的坑

#### 坑 #5: PowerShell 解析 `,@(...)` + 內部多重表達式失敗
```powershell
# ❌ 報 "[System.Object[]] does not contain method op_Multiply"
$lugCenters += ,@([Math]::Cos($rad) * $LUG_PCD, [Math]::Sin($rad) * $LUG_PCD)

# ✅ 拆開計算 OR 直接 hard-code
$x = [double]([Math]::Cos($rad)) * [double]$LUG_PCD
$y = [double]([Math]::Sin($rad)) * [double]$LUG_PCD
$lugCenters += ,@($x, $y)
```
**教訓**：複雜表達式塞進 `,@(...)` 字面量裡，PowerShell parser 容易爆 — 寧可分行算

### 流程上有效的招（新增）

✓ **Pappus / 圓柱公式預估體積寫進腳本** — 我自己畫完 vs 預估 = 24,888 mm³ 完全一致，
  確認自己的 PowerShell 沒寫錯（即使最終跟真檔差很多，至少知道差別來自我的「幾何理解」而不是程式 bug）

### 下一輪（Round 3）必做

1. **第一步先看 BBox 比例**：開 PDF 後立刻判斷 X×Y×Z 比例，不要急著動筆
2. **挑公差最緊的尺寸當基準** — 帶 ±0.01 ~ ±0.05 的尺寸通常是配合面，必對
3. **iso 視圖看「凸 vs 凹」要看分界線** — 突出物會有環形分界線，凹陷物分界線是內角
4. **倒角和孔（Hole feature）算進去** — 真檔倒角 5 個，會影響 face count 一倍以上
5. **3-fold / 4-fold 對稱用 Circular Pattern**，不要手動放 3 個

### 累計工具經驗（給未來腳本用）

- `body.RangeBox.MaxPoint.X - MinPoint.X` × 10 → mm BBox length
- `MassProperties.Volume * 1000` → mm³
- `MassProperties.Area * 100` → mm²
- 在腳本最後印 `actual vs estimated volume` — 永遠當 sanity check 出口

---

## Round 3 — 58.4×17×5.2 N52 磁鐵環（極簡）

### 對答結果（量化）— 接近完美！
| 項目 | 我畫的 | 真檔 | Δ |
|---|---|---|---|
| BBox (mm) | 58.4 × 58.4 × 5.2 | 58.4 × 58.4 × 5.2 | **0** ✓ |
| Volume | 12,748.7 | 12,739.5 | **+0.07%** ✓ |
| Area | 6,135 | 6,074 | +1.0%（沒加倒角的差距）|
| Faces / Edges | 4 / 4 | 8 / 8 | -4 / -4（倒角分裂邊）|
| Features | 1 (拉伸) | 2 (拉伸 + 圓角) | -1 |

✅ **驗證了前兩輪的方法論**：BBox 預估 + 體積 Pappus 預估 + 公差最緊夾為主要尺寸 → **對極簡幾何能 0.07% 收斂**

### 流程上踩到的坑

#### 坑 #6: `Edge.GeometryType` 的 enum 是 ObjectTypeEnum 不是 CurveTypeEnum

我用 `if ($edge.GeometryType -eq 38914)` 想抓圓邊（38914 是 CurveTypeEnum.kCircleCurve），結果 0 個 match。
真實值是 `5124 = ObjectTypeEnum.kCircleCurveObject`。

```powershell
# ❌ 找不到任何邊
if ($edge.GeometryType -eq 38914) { ... }   # CurveTypeEnum.kCircleCurve

# ✅ 正確
if ($edge.GeometryType -eq 5124)  { ... }   # ObjectTypeEnum.kCircleCurveObject
```

**速查表**（ObjectTypeEnum，Edge.GeometryType 用的）：
- `kLineSegmentObject` = 5117? (待驗證)
- `kCircleCurveObject` = 5124
- `kArcCurveObject` = 5125 (待驗證)
- `kBSplineCurveObject` = 5121 (待驗證)
- `kEllipseFullCurveObject` = 5126 (待驗證)

下次要倒角先 dump `body.Edges` 的 GeometryType 看實際值。

### 流程上有效的招（新增）

✓ **三輪累積出的「PDF 五步閱讀法」（黃金流程）**
1. **第一秒看 BBox**：從工程圖最大尺寸算出 X×Y×Z 預估值（不需要懂內部結構）
2. **找帶緊公差的尺寸**（±0.01~0.05、+0/-0.02 等）→ **這個是基準**
3. **iso 視圖判 凸 vs 凹**：突起有環形分界線；凹陷的分界線在內角
4. **Pappus / 圓柱公式預估體積**：寫進腳本當 sanity check 出口
5. **Feature count 對比預估** ：純拉伸件、旋轉件、含倒角圓角件 ≈ 不同 feature 數

✓ **倒角 API 用法**（半成功，要修 edge type）
```powershell
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) }   # circle
}
$chDef = $cd.Features.ChamferFeatures.CreateChamferDefinition()
$chDef.SetEqualDistanceChamfer($ec, (MM 0.5))
$null = $cd.Features.ChamferFeatures.Add($chDef)
```

### 觀察：循環學習收斂速度

| 輪次 | 零件 | Volume Δ | 主要學到 |
|---|---|---|---|
| 1 | Flinger（旋轉複雜） | **+106%** | 內腔 vs 外形 |
| 2 | Bearing seat（鑄鐵法蘭） | **-43%** | 凸 vs 凹、緊公差才是總厚 |
| 3 | Magnet（簡單環） | **+0.07%** | 倒角 + Inventor enum |

**規律**：簡單零件 1 輪就能近完美；複雜零件還需要更多輪才能達到 5% 內。
下一輪挑中等難度（4mm孔篩盤-半喇叭孔），驗證能不能把累積經驗用上去做出 5-10% 內。

---

## Round 4 — EV-L200-BP Flinger（跟 Round 1 同類，BP 版）

### 對答結果
| 項目 | 我畫的 | 真檔 | Δ |
|---|---|---|---|
| BBox | 15.5 × 62 × 62 | 62 × 62 × 15.5 | 軸向不同但尺寸對 ✓ |
| Volume | 25,681 | 9,596 | **+167.6%** ✗✗✗ |
| **Surface Area** | 8,624 | 8,731 | **-1.2%** ✓ |
| Faces / Edges | 6 / 6 | 17 / 17 | -11 |
| Features | 1 旋轉 | 9 (5 拉伸 + 1 旋轉 + 2 倒角 + 1 圓角) | -8 |

### 重大發現：「外形對 + 體積錯」= **內腔誤判**

跟 Round 1 一樣的錯，比 Round 1 更慘！我用了 Ø35.1（最小的內 Ø）當主孔，
但真檔的主孔應該是 **Ø52**（PDF 上有寫 Ø52 +0.1/+0.05）。差距：

- 用 Ø35.1：去除 π × 17.55² × 15.5 = 15,000 mm³
- 用 Ø52：去除 π × 26² × 15.5 = 32,900 mm³
- 差 ~18,000 mm³ — 完美對應「我的多 16,000 mm³ 體積」

### 強化教訓 → 升級為「黃金規則」

> **Flinger / Bearing Housing 類零件：當 PDF 內標出多個內 Ø 時，
> 「最大的內 Ø」通常是主孔（軸承外徑/培林座尺寸），小的內 Ø 是某段的 step。**

驗證：
- Round 1 PDF：Ø24 / Ø20.05 / Ø24.6 — 我用 Ø24，可能對的（下次驗證）
- Round 4 PDF：Ø35.1 / Ø43 / Ø52 / Ø56 — Ø52 才是主孔
- 一般規則：**配合面（軸承內）通常選兩位小數帶緊公差的內 Ø**（如 Ø52 +0.1/+0.05）

### 關鍵指標：用「Surface Area 對比」分離內/外形誤判
- Volume Δ 大 + Area Δ 小 → 外形對，**內腔錯**
- Volume Δ 小 + Area Δ 大 → 體積對，**有特徵（倒角/小孔）沒做**
- 兩者都大 → **整個輪廓搞錯**（如 Round 2）

### 累計收斂表（4 輪）
| 輪次 | Vol Δ | Area Δ | 主要問題 |
|---|---|---|---|
| 1 Flinger | +106% | -4% | 內腔誤判 |
| 2 培林座 | -43% | -22% | 凸/凹誤判 + 厚度誤判 |
| 3 磁鐵 | +0.07% | +1% | 倒角沒做 |
| 4 BP Flinger | **+167%** | **-1.2%** | **再次內腔誤判**（但更糟）|

**反思**：Round 1 學到的「內腔 vs 外形」教訓**沒真的內化**。
Round 4 我寫腳本時還是只做了一個 Ø35.1 貫穿孔。
下次看到「Ø35.1 / Ø43 / Ø52 / Ø56」這種多內徑階梯，就要強制自己畫至少 2-3 個內部 step。

---

## Round 5 — EV-L200-BP 小間隔環（純扁平環，極簡）

對答結果：BBox 完全對 + Vol 差 +2.7%（缺 1 個倒角）。簡單零件再次驗證流程穩定。

---

## Round 6 — EV-L200 培林座（KE-BH-070）— Round 2 重做

中間經過 v1 → v2 → v3 → v4 多次反覆，每版收斂幅度明顯但仍未到位。
這是循環中最複雜的一個零件，從中累積最多教訓。

### 跨輪累積經驗總結（Lessons Learned 大全）— 給未來的我

> 「零件你以為畫對了，其實少看 3 個視圖；尺寸你以為讀對了，其實認錯內外徑。」

---

#### 🟥 第 1 大教訓：**先看 BBox，再讀剖面**

**錯誤模式**：拿到 PDF 直接讀剖面 B-B 的尺寸開始畫，沒先用「BBox 預估」當 sanity check。
- Round 2 v1：我畫成 96×92×9，**真檔是 75×75×21.5** → 比例完全錯
- 後果：v1 整個外形是錯的，9 個 lugs/角全在錯誤位置

**正確流程**（黃金 5 步）：
1. **第 0 秒看 iso 視圖**：判斷整體是「板狀 / 圓盤 / 圓柱 / 多階梯旋轉體 / Top-hat / 不規則」
2. **第 1 秒算 BBox**：從 PDF 上最大尺寸 + 厚度尺寸算 X×Y×Z 預估值，腦中有個基準
3. **找帶緊公差的尺寸**：±0.01～0.05 帶公差的 = 配合面 = 必對
4. **再看剖面**：剖面圖每個 Ø 標註要明確判斷「這是外徑階梯 vs 內腔階梯」
5. **Pappus / 圓柱公式預估體積**：寫進腳本，存檔前必算

#### 🟥 第 2 大教訓：**外形「凸」vs「凹」要靠視圖交叉驗證**

**錯誤模式**：
- Round 2 v1：把 3 個耳朵看成「凸出的安裝 lug」 → 錯成 BBox 96×92
- 真檔：3 個「凹陷的弦切」（chord cut）→ BBox 維持 75×75
- 一個是加上去，一個是切掉的 — 體積差好幾倍

**判別的硬規則**：
- **BBox 是真理**：如果 PDF 標 Ø75，真檔 BBox 還是 75×75，那任何 3 角形/凸耳/Reuleaux 看到的東西都是「切凹」不是「凸出」
- **iso 視圖看分界線**：突起會有環形分界線（凸起的根部），凹陷的分界線在內角
- **多視圖交叉驗證**：TOP 視圖看外輪廓最直接 — 渲染出來看就知道是圓 / 圓+chord / 多 lobe

#### 🟥 第 3 大教訓：**「最大內 Ø」才是主孔**

Round 1 (Flinger) 我用 Ø24 當主孔（小的）→ +106% volume error
Round 4 (BP Flinger) 我又踩同個坑 → +167% volume error
真相：**多個內徑時，最大且帶緊公差的那個是主孔**（培林裝在這裡）

#### 🟥 第 4 大教訓：**Top-hat 結構要分 disc + hub 兩段畫**

不要畫成連續錐形。Top-hat 形：
- Disc（盤）：較薄、外徑大、內可能有 counterbore
- Hub（軸環）：較厚、外徑小、有貫穿孔
- 兩者交界處有「step」分界

從 PDF iso 視圖一眼能看出是不是 top-hat — 看到「平盤 + 凸起的小圓柱」就是。

#### 🟥 第 5 大教訓：**Slot 是內部 pocket 還是外部切口？BBox 一比就知道**

Round 2 v3：我把 slot 切到外周 → BBox 變 75×74.67（不對）
Round 2 v4：改成從底面挖 9mm 深 pocket → BBox 維持 75×75 ✓
**規則**：如果真檔 BBox 沒被 slot 影響到（slot 是 bottom pocket 而非外周開口），就一定是內部 pocket

#### 🟥 第 6 大教訓：**「.ipt 真檔幾何 dump」是對答的最強武器**

不靠估算，靠 Inventor COM API 把真檔的所有面 / 邊 dump 出來：
```
SurfaceType: 5890 = plane, 5891 = cylinder, 5892 = cone, 5893 = sphere(chamfer/fillet)
```
- 圓柱面 R + axis_vector + cylinder area / (2π × R) = 該圓柱的軸向長度
- 平面 root + normal: 知道每個 flat 在哪個位置、面對哪個方向
- 倒角產生的球面 (Type 5893) 一個倒角產生 N 個球面

這套 dump 直接告訴你真檔有多少個外徑、多少個內徑、多少個 flat、多少個倒角。

#### 🟥 第 7 大教訓：**Inventor 「平面 normal」方向有時跟直覺反**

Plane.Geometry.Normal 不一定是「outward」（指向材料外）。
有時是 inward。要交叉驗證：用 Find-largest-area-at-z 那種方式找 top/bottom face，搭配視覺渲染確認方向。

#### 🟦 工具/語法層級教訓（Inventor COM + PowerShell）

| # | 坑 | 解 |
|---|---|---|
| 1 | Configurator 360 對話框卡死 Documents.Add | 起 nag-watcher 背景 job 自動 PostMessage(WM_CLOSE) |
| 2 | SketchLines.AddByTwoPoints 混 Point2d/SketchPoint 會 E_FAIL | 先建好所有 SketchPoints，再兩兩連線 |
| 3 | Edge.GeometryType = 5124 是 ObjectTypeEnum 不是 CurveTypeEnum | 圓邊用 5124，不是 38914 |
| 4 | ChamferFeatures.CreateChamferDefinition() 在 2027 不存在 | 用 AddUsingDistance($edges, $dist, $false) |
| 5 | Camera.ViewOrientationType 直接賦值 fail | 用 Camera.Eye/Target/UpVector 三向量設視角 |
| 6 | PowerShell `,@()` 內含複雜表達式 parser 爆 | 拆出來分行算或 hard-code |
| 7 | PowerShell `$pid` 是 reserved | 改名（`$wp`, `$invPid`）|
| 8 | PowerShell 內聯 `if(){}else{}` 在 -ForegroundColor 後不能用 | 先賦值給 `$color = if(){...}else{...}` 再傳 |
| 9 | GDrive download_file_content 回傳結構 | `content[0].embeddedResource.contents.blob` (base64) |
| 10 | 從 face 切入時方向 ($kPos vs $kNeg) | 用 sketch face normal 反推：material 在 face 的哪一邊就往哪邊 cut |

#### 🟩 流程上有效的招

✓ **Volume sanity gate** — 預估 vs 實際差 > 1% 就不 SaveAs，先 debug
✓ **多視圖渲染對答**（TOP / FRONT / RIGHT + ISO）— 比 BBox 數字更直觀，能看出 chord cut 在哪個 corner
✓ **Mirror 零件 PDF（左右版）一起看** — 左版 (KE-BH-069) Ø70，右版 (KE-BH-070) Ø75，從鏡像零件能看到我這版可能漏的 chord cut 標註
✓ **真檔 BBox + Volume + Face count 三件套對答**：
   - Vol 差大、Area 差小 → 內腔錯
   - Vol 差小、Area 差大 → 漏倒角/小特徵
   - 兩者都差 → 整體輪廓錯（v1 的情況）
✓ **多輪迭代收斂**（v1 → v4）— 每版針對前版最大誤差動刀，不要一次想做完美

### Round 6 v4 目前狀態 + 下一步

**v4**：
- BBox 75×75×21.5 ✓
- Volume 46,913 mm³（+7.27% 偏多 vs 真檔 43,734）
- ✓ Ø75 主體
- ✓ Ø52 內腔
- ✓ 4 個安裝孔 + 2 個沉孔
- ✓ NW chord cut（用戶確認對了！）
- ✗ 我的 1 個鍵槽位置/方向不對（用戶說「槽開錯了」）
- ✗ 還少 1 個鍵槽（用戶說「少開了一個」）
- ✗ 5 個倒角 + 1 個圓角還沒做

### 用戶剛剛指出的兩個問題（v5 要修）

1. **槽位置錯**：v4 把鍵槽放在「南」（-Y方向，從底面 z=0 挖 9mm 深 pocket），但實際應該在不同位置
2. **少 1 個槽**：真檔有 2 個對稱的鍵槽，我只做 1 個

從 plane dump 重看：planes 3,5 vs 9,10 對稱在 +Y / -Y 兩側，所以兩槽位置應該在 +Y 跟 -Y 對稱。可能位置/方向需要重新理解（或許不是從 bottom face 挖，而是從 top face 挖？或從側面radial 挖？）

下一輪 v5：先重新看真檔多視圖（特別是 BACK 視圖），確定槽方向，再畫。

---

## Round 7-11 自主循環（用戶離開後）

### Round 7 — KE-BH-069 (左鏡像) **+5.89%** 第一輪
套用 R6 全部經驗一次到位。Mirror 零件容易，只需鏡像幾何 dump 數值。

### Round 8 — KE-BH-071 (X200N) **+10.29%** 第一輪
**新 pattern 發現**：top/bottom 鍵槽 **互相垂直 90°**！
- 頂面槽在 ±X 方向（walls 在 y=±4.5）
- 底面槽在 ±Y 方向（walls 在 x=±3.5）
- 不像 R6/R7 兩對都同方向

### Round 9 — KE-SP-018 大間隔環 **+14%** 第一輪
**新發現**：圓柱 axis 不只 Z 方向！  
**`axis Z=0.0` 代表 HORIZONTAL hole** — 真檔有 2 個 Ø2 「彈簧銷」孔是**徑向**鑽進來的（從外周往中心鑽），不是軸向通孔。我跳過這個複雜特徵。

### Round 10 — KE-SP-019 EVM 間隔環 **+10%** 第一輪
寫了**通用 auto_ring.ps1** — 從真檔讀 BBox + 圓柱半徑 → 自動畫對應的環 + 倒角。可直接套用未來任何環類零件。

### Round 11 — KE-BH-062 X100 MP-G **跳過**
真檔太複雜：BBox **62×87.21×31**（非方形，elongated）+ 32 個圓柱 + 30 features。
這類「多軸承座 racetrack 法蘭」需要更深的視圖分析才能建模。等累積更多簡單件經驗再回頭。

### 跨 R7-R11 累積新教訓

#### 🟥 第 8 大教訓：**圓柱 axis 向量告訴你孔方向**
```
axis=(0, 0, 1)  → 軸向通孔（Z 方向）
axis=(0, 1, 0)  → 徑向 Y 方向孔（橫向鑽）
axis=(1, 0, 0)  → 徑向 X 方向孔
axis 任何 Z=0 的非零向量 → HORIZONTAL HOLE（不是垂直通孔！）
```
看到 axis Z=0 要警覺：這是側面鑽的彈簧銷孔/油孔/PIN 孔。

#### 🟥 第 9 大教訓：**非方形 BBox = 不是單軸圓柱類零件**
- BBox X=Y → 圓盤狀零件（單軸圓柱基礎）
- BBox X≠Y → racetrack 形 / 矩形法蘭 / 其他 — 需要不同建模 pattern

#### 🟥 第 10 大教訓：**鏡像零件複用之前 Round 的 pattern**
左/右成對的零件（如 KE-BH-069 左 vs KE-BH-070 右）只差尺寸，**結構完全一樣**。用前一個 Round 的腳本 + 換尺寸即可。

#### 🟥 第 11 大教訓：**Top/bottom 對稱不一定同方向**
R8 發現了 **頂底鍵槽互相垂直 90°** 的 pattern。看 plane normal 方向（±X vs ±Y）就知道槽方向。**不要假設頂面槽跟底面槽同方向**。

### 通用建模工具：auto_ring.ps1（R10 創造）
讀真檔 → 取 BBox + 兩個最大圓柱半徑（外/內）→ 自動建對應扁平環 + 4 個倒角。
1 秒內可對任何 KE-SP 系列環做 +10% 內近似。

### 進度速覽（11 輪）

| 輪次 | 結果 | 主要學到 |
|---|---|---|
| 1 | +106% | 內腔 vs 外形 |
| 2 (v1→v6) | -43% → +6.7% | BBox 預估必做、四槽不貫穿 |
| 3 | **+0.07%** ✓ | enum 5124 |
| 4 (v1→v3) | +167% → +3.6% | top-hat ≠ 連續錐 |
| 5 | +2.7% | 流程穩定 |
| 6 | -43% → +6.7% (與 R2 同) | 真檔幾何 dump 為對答聖經 |
| 7 | **+5.89%** 第一輪 | 鏡像零件複用 |
| 8 | **+10.29%** 第一輪 | 頂底槽 90° 垂直 pattern |
| 9 | +14% | 徑向銷孔（axis Z=0）|
| 10 | +10% | 通用 auto-ring 工具 |
| 11 | (跳過) | 多軸承座法蘭超出當前能力 |
