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
