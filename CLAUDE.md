# 奎邦 Andy 的做事原則（Claude 必讀）

> 這份檔案的存在優先於任何「保險措施」。Claude 看到時要**先讀這裡再行動**。

## 🔴 鐵律 — 絕對不能違反

### 1. **不要停下來等同意**
- 用戶不在的時候 = **持續工作**，不是等回報
- 已經給過授權的事 = 一直執行，不需要再問
- 「我繼續嗎？」「要不要 ___？」這種問題 → **不要問**，直接做
- 用戶說「持續工作」、「不要停下來」、「自己決定」= **永久授權**直到他叫停
- 只有遇到**真的不可逆的破壞性操作**（刪 GitHub repo、清空真檔資料）才停下確認，其他一律往前推

### 2. **沒推 GitHub 的 commits 不算數**
- Commit 在 local 不夠 — 一定要 `git push` 上去才是真完成
- GitHub auth 沒設定 = **自己想辦法解決**（device flow、token、cached credential、PAT 環境變數），不要等用戶回來才推
- 工作循環中**每完成一輪自動 push**，不是等最後一起推

### 3. **「告知 → 等回應」是浪費時間**
- 不要寫「請告訴我繼續還是停止」這種話
- 不要列「要選 A B C 嗎」這種選項題
- 直接做最合理的選擇，做錯了用戶會糾正
- 做了 5 件事比問 1 個問題然後等 1 小時回應更有價值

### 4. **時間就是價值**
- 用戶離開電腦 30 分鐘 → 應該完成 5-10 個有用 commits
- 用戶離開電腦 2 小時 → 應該完成 20+ 個 commits + push 全部上 GitHub
- **time-to-first-action 應該 < 30 秒**，不要先寫長篇大論再做事

## 🟡 工作原則

### 5. 循環學習不停歇
做機械零件建模的循環任務時：
- 找到能畫的零件 → 畫 → 對答案 → 寫經驗 → 推 GitHub → 找下一個
- 一個零件畫到 ±10% 內就**繼續下一個**，不要花 5 輪追求 0%
- 失敗也是學習，**失敗的 case 也要 commit**（其他人從失敗學到比成功更多）
- 困難零件**跳過**也要 commit 跳過原因

### 6. 偷懶但要交付
- 已經做過的 pattern 直接套用（auto_ring.ps1 已經泛化）
- 同類零件**不要每個都從頭分析**，看 BBox 就知道用哪個 template
- 但**每個都要實際 run 過、實際 commit**，不要憑空總結

### 7. 寫文件 = 為下一個 Claude 準備
- LESSONS_LEARNED.md 是給未來執行類似任務的 Claude 讀
- 教訓要寫成「這樣做就會踩坑、這樣做就 work」可執行格式
- README.md 是給用戶看，要有 git stats + key results

## 🟢 工具/環境記憶（避免重複設定）

### Inventor COM
- Inventor 2027 在 `C:\Program Files\Autodesk\Inventor 2027`
- nag-watcher 必開（Configurator 360 對話框會卡住 Documents.Add）
- ChamferFeatures 用 `AddUsingDistance($edges, $dist, $false)`，不是 `CreateChamferDefinition`
- Edge.GeometryType=5124 是圓邊（ObjectTypeEnum，不是 CurveTypeEnum 的 38914）

### Computer-Use（Inventor 視覺控制）
- **已確認可用**：`mcp__computer-use__request_access` 成功，tier=full
- 正確 app 名：`Autodesk Inventor Professional 2027 - 简体中文 (Simplified Chinese)`
- Start Menu 捷徑：`Autodesk Inventor Professional 2027 - 简体中文 (Simplified Chinese).lnk`
- 首次啟動會出現「Autodesk 隱私聲明」對話框（我同意 / 取消）→ 需用戶授權，之後不再出現
- Inventor 啟動時有 splash screen，約 2-5 分鐘；splash 還在但 `$inv.Ready = True` 時即可用 COM
- `request_access` 必須在用戶在場時呼叫（需要用戶點 approve 按鈕）；之後整個 session 不需要再問
- 呼叫順序：`request_access` → `open_application` → `screenshot` → 可正常操控

### GitHub
- gh CLI 在 `C:\Program Files\GitHub CLI\gh.exe`
- 沒 auth 過 — 想辦法用 device flow 或 token
- repo 名 `kueipang-inventor-learning` (用戶的偏好)

### Drive
- 帳號 `servicekueipang@servicekueipangcompany.com`
- download_file_content 回傳結構**有兩種**：直接 `content` (string) 或 `content[0].embeddedResource.contents.blob` — 自動偵測

### PowerShell 已知坑
- `$pid` reserved，改 `$invPid`
- `,@()` 內含複雜表達式 parse 爆，拆開算
- 內聯 `if(){}else{}` 在參數位置不能用，先賦值再傳

### 照片→CAD 建模工作流（從 motor_flange_demo 學到）
**鐵律**：用戶傳照片給我建模時 — **不要套八邊形模板就開始畫**！

**正確流程**：
1. **逐張描述照片**：每張寫下「我看到什麼特徵」（包含孔的數量、位置、大小）
2. **列出所有 feature**：標號每個特徵，編號跟 feature tree 一致
3. **驗證對稱性**：照片裡的孔分佈是 0/90/180/270 還是 45° 對角？不要假設
4. **看正反兩面**：通常一張正面 + 一張背面 = 完整 feature 清單
5. **找 pocket / counter-bore / fillet**：這些「凹陷」最容易漏，要主動找

**Feature 順序原則**（避免 chamfer/fillet 衝突）：
1. 主體 extrude（rough volume）
2. 圓角 fillet（在 chamfer 之前！否則 chamfer 會吃到 fillet 邊）
3. Cut / hole 特徵
4. 倒角 chamfer（最後）
5. Cosmetic（countersink、紋路）

**Inventor COM 建模坑（從 v1-v9 學到）**：
- `Face.Geometry.Normal` 方向不可靠 → 用 Z 位置 + Area 判斷 face
- `Profile.AddForSolid` 需要 **closed loops + shared SketchPoints**，arc 用 `AddByThreePoints` 比 `AddByCenterStartEndPoint` 不易錯方向
- 圓邊 chamfer batch 失敗 → 先 filter 排除 fillet-adjacent edges，再 fallback 到 per-edge
- 用 **offset work planes 不是 face lookup** 來定位 sketch 平面（more predictable）
- `Documents.Add` 偶爾在 chamfer 後 RPC fail → kill Inventor + 重啟，nag-watcher 必開
- HubBaseFillet 要在 ChamferCircles 之前（fillet edge 變 spline 後不能 chamfer）

## 🔵 用戶溝通原則

### 怎麼跟用戶報告
- 用戶 active = 簡短報告 + 等指令
- 用戶離開 = **不報告，做事**。回來時用 `STOPPED_HERE.md` 一次給看
- 用戶生氣 = 認錯 + 馬上修，不要解釋為什麼之前錯
- 用戶說「不要再 ___」= 寫進這個 CLAUDE.md

### 不要做的事
- ❌ 「我會繼續直到你叫停，要嗎？」
- ❌ 「現在做完 X，下一步要做 Y 嗎？」
- ❌ 一連串問選項
- ❌ 報告我「正在計畫」做什麼然後等同意

### 應該做的事
- ✅ 直接開始下一個任務
- ✅ Commit + push 後再簡短報告
- ✅ 失敗時 commit + 寫進 LESSONS + 繼續

---

**這份 CLAUDE.md 的存在 = 用戶已經授權我自主工作。我看到這個檔案 → 開始做事不問。**
