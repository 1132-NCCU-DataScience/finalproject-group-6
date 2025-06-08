[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/HR2Xz9sU)
# [Group-6] 中部市場蔬菜作物價格預測
本研究探討氣候因素對蔬果價格的影響，透過分析氣溫、降雨量、日照時數等資料，建立價格預測模型。希望找出影響價格波動的關鍵天氣因素，協助消費者、農民與產業做出更有效的決策。

## Contributors
|組員|系級|學號|工作分配|
|-|-|-|-|
|凃冠瑛|資訊碩一|114753209|蔬菜價格資料集、簡報|
|呂欣蓉|統計三|110405098|蔬菜價格資料集、demo、簡報|
|吳彥勳|金融四|110207317|天氣資料集、簡報|
|宋岷叡|哲學四|108104049|RandomForest模型、海報、簡報|
|陳芎月|資訊四|110703057|ARIMA模型、xgboost模型、海報、簡報|
|宋庭萱|統計四|110304032|ARIMA模型、xgboost模型、海報、簡報|


## Quick start
Please provide an example command or a few commands to reproduce your analysis, such as the following R script:
```R
Rscript code/your_script.R --input data/training --output results/performance.tsv
```
本專案使用 ARIMA 、 XGboost 與隨機森林模型 (Ranger)預測台灣各市場花椰菜價格，並透過 Shiny App 視覺化展示預測結果。

### 系統需求 

- 作業系統：Windows / macOS / Linux
- R 版本：4.0 以上（建議使用 4.3.0 或以上）
- 記憶體：建議至少 4GB
- 網路連線：用於安裝 R 套件與下載資料

> 若使用 RStudio，請確認已安裝最新版，以支援 Shiny App 執行。

### 1. 下載專案

請先使用 Git 將專案克隆到本地端：
```bash
git clone https://github.com/1132-NCCU-DataScience/finalproject-group-6.git
cd finalproject-group-6
```

### 2. 套件安裝

請先安裝必要套件：

```r
install.packages(c("tidyverse", "lubridate", "ranger", "Metrics","zoo","ggplot2",
                   "shiny", "shinydashboard", "DT", "dplyr"))

```
### 3. 資料與目錄結構

請確保您有以下目錄結構：
```
finalproject-group-6/
├── code/
│   ├── Brocoli_predict_Renger(Random Forest).R     # 隨機森林模型
│   ├── app.R                                       # Shinyapp
├── data/
│   ├── 花椰菜 青梗.csv                   # 花椰菜交易資料
│   ├── daily_weather.csv                # 天氣資料
├── results/
│   ├── 400市場花椰菜價格預測_ranger.png           
│   ├── 420市場花椰菜價格預測_ranger.png
│   ├── 512市場花椰菜價格預測_ranger.png
│   ├── 514市場花椰菜價格預測_ranger.png          
│   ├── 648市場花椰菜價格預測_ranger.png      
├── README.md
```
### 4. 執行模型訓練與預測

請使用以下指令執行主程式，並將結果輸出為圖片檔：

```bash
Rscript code/Brocoli_predict_Renger(Random Forest).R \
  --input1 data/花椰菜 青梗.csv \
  --input2 data/daily_weather.csv  \
  --output_dir results/
```
### 5. 啟動 Shiny App
```bash
shiny::runApp("shiny/")
```

## Folder organization and its related description
idea by Noble WS (2009) [A Quick Guide to Organizing Computational Biology Projects.](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424) PLoS Comput Biol 5(7): e1000424.

### docs
* Presentation, 1132_DS-FP_group6.ppt
* Data Integration
* Poster of Innofest
* Any related document for the project, i.e.,
  * discussion log
  * software user guide

### data
* 農產品價格資料
  * Source: 🔗 [農產品批發市場交易行情站](https://amis.afa.gov.tw/veg/VegProdDayTransInfo.aspx)
  * Duration: 2015/01/01 ~ 2025/04/30
  * Items: 花椰菜（青梗）、茼蒿、甜豌豆
  * Format:
    | 欄位名稱    | 資料型態                |            單位                  |
    |---------|---------------------------|-------------------------------------|
    | 日期  |           時間           |            每天/每週               |
    | 市場    |       類別型          |    台中市，豐原區，永靖鄉，溪湖鎮，南投市，西螺鎮     |
    | 上價  |      數值型       | 元 / 公斤     |
    | 中價  |      數值型       | 元 / 公斤     |
    | 下價  |      數值型       | 元 / 公斤     |
    | 平均價  | 數值型(目標)   | 元 / 公斤     |
    | 增減%  |     數值型   | 元 / 公斤     |
    | 交易量  |    數值型   | 公斤     |
    | 增減%  |   數值型   |   公斤     |
  * size:

    | 品種    | 日資料筆數 | 週資料筆數 |
    |---------|------------|-------------|
    | 花椰菜  | 14,983     | 764         |
    | 茼蒿    | 4,091      | 764         |
    | 甜豌豆  | 4,228      | 764         |

* 天氣觀測資料
  * Source: 🔗 [農業氣象觀測網監測系統](https://agr.cwa.gov.tw/history/station_day)
  * Duration: 2014/10/01 ~ 2025/04/30
  * Format:
    | 品種    | 觀測站地點                | 生育日數 |
    |---------|---------------------------|-----------|
    | 花椰菜  | 台中農改、南改斗南分場   | 60 天     |
    | 茼蒿    | 台中農改、南改斗南分場   | 45 天     |
    | 甜豌豆  | 台中農改、南改斗南分場   | 90 天     |
  * 產地與觀測站分布圖: 🔗[點此查看地理分布互動地圖](https://www.google.com/maps/d/u/0/edit?mid=1ReIEOk9rDv4Jogp6OP7GNVv825XCBh0&usp=sharing)

* 檔案說明
  - `data.ipynb`：資料整合與處理過程紀錄
  - `summary_merged_daily_lagged.csv`：每日整合資料摘要
  - `summary_merged_weekly_lagged.csv`：每週整合資料摘要

#### 氣象資料處理流程說明

1. **資料來源與選用原則**

   * 氣象資料來自 [農業氣象觀測網監測系統](https://agr.cwa.gov.tw/history/station_day)。
   * 選擇**中部產地鄰近、2014 年至今資料完整的農業氣象觀測站**（雲林：南改斗南分場，彰化：台中農改等），確保與蔬菜產地配對。

2. **原始資料處理**

   * 資料期間設定為**2014/10/01–2025/04/30**，涵蓋蔬果價格期間及生育前置期。
   * 主要欄位包含：氣壓、氣溫、濕度、露點、風速、降雨、日照、地溫等指標之**每日數據**。

3. **異常值與缺值處理**

   * 針對不合理極值（如\*\*最低氣溫出現-39.6°C、相對濕度0%\*\*等明顯錯誤）直接設為 NA。
   * **交叉比對兩觀測站資料**：同一日兩站差異過大（如氣溫相差超過 10°C）也判為異常，設 NA。
   * 部分變數大量缺失者直接剔除（例：地溫等），其餘欄位如遇單日缺失，採**雙向補值（取前後日均值）**。

4. **多站資料合併邏輯**

   * 若僅單站有數據，直接採用。
   * 兩站皆有資料時：**平均型欄位取平均值、極值欄位取最大/最小值**。
   * 兩站皆缺時保留為 NA，後續週資料處理時再進行插補。

5. **每日資料轉換為每週資料**

   * 週統計時，**累積型變數（如降雨量、日照時數）要求一週至少有六天有值**，否則該週欄位記為 NA。
   * 極值欄位取該週極值，平均型欄位取平均。
   * 缺值週資料視情況以插值補齊。

6. **與蔬果價格資料合併**

   * 以蔬菜每週價格資料為主軸，將當週（w）及**往前 12 週**之天氣變數合併進同一筆資料。
   * 結合後每筆樣本包含高達 283 個天氣相關欄位。

7. **品質檢查與統計**

   * 詳細記錄各氣象變數缺值狀況與補值後比例，確保分析基礎資料品質。
   * 篩選缺失過多的變數（如最大60分鐘降水量等）避免影響模型效能。

  
### code
* Analysis steps
* Which method or package do you use?
* How do you perform training and evaluation?
  * Cross-validation, or extra separated data
* What is a null model for comparison?

### RandomForest模型分析流程

#### Analysis steps
1. **數據預處理**：
   - 整合農產品價格數據與天氣觀測數據
   - 處理日期格式並確保時間序列連續性
   - 移除或填補缺失值（價格缺失日期剔除，特徵缺失值使用中位數填充）

2. **特徵工程**：
   - 時間特徵：年、月、星期幾、週末標記
   - 價格滯後特徵：1天、7天、14天、30天前價格
   - 價格滾動統計：7天和14天移動平均，7天移動標準差
   - 天氣特徵：當日平均/最高/最低溫度、相對濕度、降雨量
   - 天氣滯後特徵：7天前的溫度、濕度、降雨量數據

3. **模型建構與評估**：
   - 時間序列分割（前80%訓練，後20%測試）
   - 模型訓練與預測
   - 性能評估與殘差分析
   - 特徵重要性評估
   - 跨市場驗證

#### Packages used
- **核心模型**：`ranger`（Random Forest的高效實現版本）
- **數據處理**：`tidyverse`、`lubridate`（日期處理）
- **時間序列特徵**：`zoo`（滾動統計計算）
- **評估指標**：`Metrics`（計算RMSE、MAE等）
- **可視化**：基礎R繪圖函數與`ggplot2`

#### Training and evaluation methodology
- **數據分割**：採用時間順序分割（temporal split），保留最後20%數據作為測試集
- **無交叉驗證**：由於數據具時間序列性質，採用單一時間向前分割而非交叉驗證，避免數據洩漏
- **參數設定**：
  - 樹數量：500棵
  - 特徵重要性計算：permutation method
  - 隨機種子：123（確保結果可重現）
- **評估指標**：
  - RMSE（均方根誤差）
  - MAE（平均絕對誤差）
  - MAPE（平均絕對百分比誤差）
  - R²（決定係數）


### results
* image
  ```css
  image/
  ├── 512永靖鄉每週批發價格趨勢圖.jpg
  ├── 514溪湖鎮每週批發價格趨勢圖.jpg
  ├── 648西螺鎮每週批發價格趨勢圖.jpg
  ├── 不同市場每周平均價格趨勢.jpg
  ├── 不同市場每周平均價格趨勢2.jpg
  ├── xgboost/
  │   ├── 512市場價格預測_xgboost.jpg
  │   ├── 514市場價格預測_xgboost.jpg
  │   └── 648市場價格預測_xgboost.jpg
  └── arima/
  │   ├── [512系列圖]
  │   ├── [514系列圖]
  │   └── [648系列圖]
  └── ranger/
      ├── 400台中市甜豌豆市場價格預測_ranger.png
      ├── 420豐原區甜豌豆市場價格預測_ranger.png
      ├── 514溪湖鎮甜豌豆市場價格預測_range.png
      ├── 400台中市茼蒿市場價格預測_ranger.png
      ├── 420豐原區茼蒿市場價格預測_ranger.png
      └── 648西螺鎮茼蒿市場價格預測_range.png
  ```
* Is the improvement significant?
* [Shinyapp](https://hsinjunglu.shinyapps.io/code/)
  
  <img width="949" alt="image" src="https://github.com/user-attachments/assets/a11f4ee8-b73d-498f-b27b-4bea73730d89" />

   頁面說明:
   * Home : 主題簡介與使用說明。
   * ARIMA : 選擇不同市場觀看模型評估結果、價格趨勢圖以及價格預測圖。
   * XGBoost : 選擇不同市場觀看模型評估結果以及價格預測圖。
   * RandomForest : 選擇不同市場觀看模型評估結果以及價格預測圖。另外可自行選擇預測日期以及參數數值進行預測。
   * 相關係數 : 不同市場之特徵變數與蔬菜平均交易價的相關係數圖。


## References
* Packages we use
   * `readxl`
   * `dplyr`
   * `lubridate`
   * `tools`
   * `shiny`
   * `shinydashboard` 
   * `DT`
   * `ranger`
   * `tidyverse`
   * `zoo`
   * `Metrics`
   * `ggplot2`
     
* Related publications

| 主題             | 連結 |
|------------------|------|
| 食農教育資訊整合平台 | [點此前往](https://fae.moa.gov.tw/map/county_agri.php) |
| 花椰菜產地說明     | [台中區農改場](https://www.tcdares.gov.tw/theme_data.php?theme=news&sub_theme=event&id=13643) |
| 茼蒿產地說明      | [美食網](https://food.ltn.com.tw/article/1282) |
| 豌豆產地報導      | [農傳媒](https://www.agriharvest.tw/archives/73963) |
