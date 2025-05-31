# 載入所需的套件
library(shiny)
library(shinydashboard)
library(DT)
library(ranger)
library(lubridate)
library(dplyr)

# 定義UI
ui <- dashboardPage(
  dashboardHeader(title = "中部市場蔬菜價格預測"),
  
  # 側邊面板
  dashboardSidebar(
    # 組別與組員資訊
    div(style = "padding: 10px; text-align: center; color: #b8c7ce; font-size: 0.9em;",
        tags$hr(style = "border-top: 1px solid #444; margin: 15px 0;"), # 加一條分隔線
        p(strong("組別:"), " Group 6"), # 組別名稱
        p(strong("組員:")), # 組員
        p("凃冠英, 宋岷叡, 陳芎月"),
        p("宋庭萱, 呂欣蓉, 吳彥勳")
    ),
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("ARIMA", tabName = "arima", icon = icon("chart-line")),
      menuItem("XGBoost", tabName = "xgboost", icon = icon("project-diagram")),
      menuItem("RandomForest", tabName = "randomforest", icon = icon("tree")),
      menuItem("相關係數", tabName = "correlation", icon = icon("ruler-combined")) 
    )
  ),
  
  # 主要內容區域
  dashboardBody(
    # 添加自定義CSS樣式
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .market-select-container {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 25px;
          border-radius: 15px;
          margin-bottom: 25px;
          box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        .market-select-container h3 {
          margin: 0 0 15px 0;
          font-weight: 600;
          font-size: 18px;
        }
        .market-select-container .form-group {
          margin-bottom: 0;
        }
        .market-select-container select {
          background-color: rgba(255,255,255,0.9);
          border: none;
          border-radius: 8px;
          padding: 10px 15px;
          font-size: 14px;
          color: #333;
        }
        .evaluation-section {
          background: white;
          padding: 20px;
          border-radius: 12px;
          margin-bottom: 25px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          border-left: 4px solid #3c8dbc;
        }
        .evaluation-section h4 {
          color: #3c8dbc;
          margin: 0 0 15px 0;
          font-weight: 600;
          font-size: 16px;
        }
        .evaluation-table {
          width: 100%;
          border-collapse: collapse;
        }
        .evaluation-table th {
          background-color: #f8f9fa;
          padding: 12px;
          text-align: left;
          border-bottom: 2px solid #dee2e6;
          font-weight: 600;
          color: #495057;
        }
        .evaluation-table td {
          padding: 10px 12px;
          border-bottom: 1px solid #dee2e6;
        }
        .evaluation-table tr:hover {
          background-color: #f8f9fa;
        }
        .image-container {
          background: white;
          border-radius: 12px;
          padding: 20px;
          margin-bottom: 25px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
        }
        .image-container img {
          width: 100%;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          transition: transform 0.3s ease;
        }
        .image-container img:hover {
          transform: scale(1.02);
        }
        .home-intro {
          background: linear-gradient(135deg, #74b9ff 0%, #0984e3 100%);
          color: white;
          padding: 30px;
          border-radius: 15px;
          margin-bottom: 25px;
          box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        .home-intro h3 {
          margin-top: 0;
          font-weight: 600;
        }
        .home-features {
          background: white;
          padding: 25px;
          border-radius: 12px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
        }
        .feature-list {
          list-style: none;
          padding: 0;
        }
        .feature-list li {
          padding: 8px 0;
          border-bottom: 1px solid #eee;
        }
        .feature-list li:last-child {
          border-bottom: none;
        }
        .feature-list li strong {
          color: #3c8dbc;
        }
        .prediction-form {
          background: white;
          padding: 25px;
          border-radius: 12px;
          margin-bottom: 25px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          border-left: 4px solid #28a745; /* Green border for prediction form */
        }
        .prediction-form h4 {
          color: #28a745;
          margin-top: 0;
          margin-bottom: 20px;
          font-weight: 600;
        }
        .prediction-form .form-row {
          display: flex;
          flex-wrap: wrap;
          gap: 20px;
          margin-bottom: 15px;
        }
        .prediction-form .form-col {
          flex: 1;
          min-width: 280px; /* Adjust as needed for smaller screens */
        }
        .prediction-form .form-group {
          margin-bottom: 0;
        }
        .prediction-form .form-control {
          border-radius: 8px;
          border: 1px solid #ddd;
          padding: 10px 15px;
          box-shadow: inset 0 1px 3px rgba(0,0,0,0.05);
        }
        .predict-btn {
          background-color: #28a745;
          color: white;
          border: none;
          padding: 12px 30px;
          border-radius: 8px;
          font-size: 16px;
          font-weight: bold;
          cursor: pointer;
          transition: background-color 0.3s ease, transform 0.2s ease;
          box-shadow: 0 4px 10px rgba(40, 167, 69, 0.2);
        }
        .predict-btn:hover {
          background-color: #218838;
          transform: translateY(-2px);
        }
        .prediction-result {
          background: #e9f7ef; /* Light green for successful prediction */
          padding: 25px;
          border-radius: 12px;
          margin-top: 25px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          text-align: center;
          border: 1px solid #28a745;
          color: #333;
        }
        .prediction-result h3 {
          color: #1e7e34; /* Darker green for result heading */
          margin-top: 0;
          margin-bottom: 15px;
          font-weight: 700;
        }
        .prediction-result p {
          font-size: 16px;
          margin-bottom: 8px;
        }
        .prediction-result .result-price {
          font-size: 2.5em;
          font-weight: bold;
          color: #007bff; /* Blue for the price */
          margin: 20px 0;
          padding: 10px;
          background-color: #f8f9fa;
          border-radius: 10px;
          display: inline-block;
          min-width: 200px;
        }
      "))
    ),
    
    tabItems(
      # Home 頁面
      tabItem(tabName = "home",
              fluidRow(
                column(width = 12,
                       div(class = "home-intro",
                           h3("主題簡介"),
                           p("本組探討氣候因素對蔬果價格的影響，透過分析氣溫、降雨量、日照時數等資料，建立價格預測模型。希望找出影響價格波動的關鍵天氣因素，協助消費者、農民與產業做出更有效的決策。")
                       )
                )
              ),
              fluidRow(
                column(width = 6,
                       div(class = "home-features",
                           h4("預測模型"),
                           p("此平台提供三種預測模型之價格預測圖與相關結果："),
                           tags$ul(class = "feature-list",
                                   tags$li(strong("ARIMA"), " - 時間序列分析模型"),
                                   tags$li(strong("XGBoost"), " - eXtreme Gradient Boosting模型"),
                                   tags$li(strong("Random Forest"), " - 隨機森林模型")
                           )
                       )
                ),
                column(width = 6,
                       div(class = "home-features",
                           h4("使用說明"),
                           p("1. 點擊左側選單選擇您想要查看的模型"),
                           p("2. 各模型頁面中可以選擇不同的市場"),
                           p("3. 查看模型結果圖表和相關資訊")
                       )
                )
              )
      ),
      
      # ARIMA 頁面
      tabItem(tabName = "arima",
              # 市場選擇區塊
              fluidRow(
                column(width = 12,
                       div(class = "market-select-container",
                           h3("市場選擇"),
                           selectInput("arima_market", 
                                       label = NULL,
                                       choices = list(
                                         "512永靖鄉" = "512",
                                         "514溪湖鎮" = "514",
                                         "648西螺鎮" = "648"
                                       ),
                                       selected = "512")
                       )
                )
              ),
              # 模型評估結果
              fluidRow(
                column(width = 12,
                       div(class = "evaluation-section",
                           h4("模型評估結果"),
                           tableOutput("arima_params")
                       )
                )
              ),
              # 圖片顯示區域
              uiOutput("arima_images")
      ),
      
      # XGBoost 頁面
      tabItem(tabName = "xgboost",
              # 市場選擇區塊
              fluidRow(
                column(width = 12,
                       div(class = "market-select-container",
                           h3("市場選擇"),
                           selectInput("xgboost_market", 
                                       label = NULL,
                                       choices = list(
                                         "512永靖鄉" = "512",
                                         "514溪湖鎮" = "514",
                                         "648西螺鎮" = "648"
                                       ),
                                       selected = "512")
                       )
                )
              ),
              # 模型評估結果
              fluidRow(
                column(width = 12,
                       div(class = "evaluation-section",
                           h4("模型評估結果"),
                           tableOutput("xgboost_features")
                       )
                )
              ),
              # 圖片顯示區域
              uiOutput("xgboost_images")
      ),
      
      # Random Forest 頁面
      tabItem(tabName = "randomforest",
              # 市場選擇區塊
              fluidRow(
                column(width = 12,
                       div(class = "market-select-container",
                           h3("市場選擇"),
                           selectInput("rf_market", 
                                       label = NULL,
                                       choices = list(
                                         "400台中市" = "400",
                                         "420豐原區" = "420",
                                         "512永靖鄉" = "512",
                                         "514溪湖鎮" = "514",
                                         "648西螺鎮" = "648"
                                       ),
                                       selected = "400")
                       )
                )
              ),
              # 模型評估結果
              fluidRow(
                column(width = 12,
                       div(class = "evaluation-section",
                           h4("模型評估結果"),
                           tableOutput("rf_stats")
                       )
                )
              ),
              # 圖片顯示區域
              uiOutput("rf_images"),
              
              # 預測參數設定 
              fluidRow(
                column(width = 12,
                       div(class = "prediction-form",
                           h4("預測參數設定"),
                           div(class = "form-row",
                               div(class = "form-col",
                                   dateInput("predict_date", "預測日期:", 
                                             value = Sys.Date() + 7, 
                                             min = Sys.Date() + 1,
                                             format = "yyyy-mm-dd")
                               ),
                               div(class = "form-col",
                                   numericInput("predict_temp_avg", "平均氣溫 (°C):", 
                                                value = 25, min = 5, max = 40, step = 0.1)
                               ),
                               div(class = "form-col",
                                   numericInput("predict_temp_max", "最高氣溫 (°C):", 
                                                value = 30, min = 5, max = 45, step = 0.1)
                               )
                           ),
                           div(class = "form-row",
                               div(class = "form-col",
                                   numericInput("predict_temp_min", "最低氣溫 (°C):", 
                                                value = 20, min = 3, max = 30, step = 0.1)
                               ),
                               div(class = "form-col",
                                   numericInput("predict_rh_avg", "平均相對濕度 (%):", 
                                                value = 80, min = 47, max = 100, step = 1)
                               ),
                               div(class = "form-col",
                                   numericInput("predict_rh_min", "最低相對濕度 (%):", 
                                                value = 55, min = 14, max = 100, step = 1)
                               )
                           ),
                           div(class = "form-row",
                               div(class = "form-col",
                                   numericInput("predict_precip", "累計雨量 (mm):", 
                                                value = 3.5, min = 0, max = 385, step = 0.1)
                               ),
                               div(class = "form-col",
                                   numericInput("predict_last_price", "最近一次價格 (元/公斤):", 
                                                value = 30, min = 2, max = 165, step = 0.1)
                               )
                           ),
                           div(style = "text-align: center; margin-top: 20px;",
                               actionButton("run_prediction", "執行預測", class = "predict-btn")
                           )
                       )
                )
              ),
              # 預測結果顯示 
              fluidRow(
                column(width = 12,
                       uiOutput("prediction_result")
                )
              )
      ),
      
      # 相關係數頁面
      tabItem(tabName = "correlation",
              fluidRow(
                column(width = 12,
                       div(class = "evaluation-section",
                           h4("各變數與價格相關係數圖"),
                           uiOutput("correlation_images")
                       )
                )
              )
      )
    )
  )
)

# 定義Server
server <- function(input, output, session) {
  
  # 載入預訓練的 ranger 模型與歷史資料
  model_results <- readRDS("models_saved/cauliflower_model_results.rds")
  historical_data <- readRDS("data_processed/cauliflower_merged_data.rds")
  
  # 市場代碼對應表
  market_mapping <- list(
    "400" = "台中市",
    "420" = "豐原區", 
    "512" = "永靖鄉",
    "514" = "溪湖鎮",
    "648" = "西螺鎮"
  )
  
  # 實際的預測函數
  predict_price <- function(market_code, predict_date, weather_params, last_price) {
    market_name <- market_mapping[[market_code]]
    
    if (!market_name %in% names(model_results)) {
      return(list(error = paste("無法找到", market_name, "的模型")))
    }
    
    ranger_model <- model_results[[market_name]]$ranger$model
    
    if (!inherits(ranger_model, "ranger")) {
      return(list(error = paste("模型格式錯誤，類別為", class(ranger_model))))
    }
    
    market_historical <- historical_data %>%
      filter(market_name == !!market_name) %>%
      arrange(date)
    
    recent_data <- tail(market_historical, 30)
    
    # 檢查 recent_data 是否有足夠的行數來計算 lag features
    if (nrow(recent_data) < 30) {
      return(list(error = "歷史資料不足，無法計算完整的滯後特徵。請檢查資料。"))
    }
    
    pred_year <- year(predict_date)
    pred_month <- month(predict_date)
    pred_day_of_week <- wday(predict_date, label = FALSE, week_start = 1)
    pred_is_weekend <- ifelse(pred_day_of_week %in% c(6, 7), 1, 0)
    
    # 確保 lag features 在沒有足夠歷史資料時有預設值，或進行NA處理
    avg_price_lag_1 <- ifelse(!is.null(last_price) && !is.na(last_price), last_price, 
                              ifelse(length(tail(recent_data$avg_price, 1)) > 0, tail(recent_data$avg_price, 1), NA))
    avg_price_lag_7 <- ifelse(length(tail(recent_data$avg_price, 7)) == 7, mean(tail(recent_data$avg_price, 7), na.rm = TRUE), NA)
    avg_price_lag_14 <- ifelse(length(tail(recent_data$avg_price, 14)) == 14, mean(tail(recent_data$avg_price, 14), na.rm = TRUE), NA)
    avg_price_lag_30 <- ifelse(length(tail(recent_data$avg_price, 30)) == 30, mean(tail(recent_data$avg_price, 30), na.rm = TRUE), NA)
    avg_price_roll_mean_7 <- ifelse(length(tail(recent_data$avg_price, 7)) == 7, mean(tail(recent_data$avg_price, 7), na.rm = TRUE), NA)
    avg_price_roll_mean_14 <- ifelse(length(tail(recent_data$avg_price, 14)) == 14, mean(tail(recent_data$avg_price, 14), na.rm = TRUE), NA)
    avg_price_roll_sd_7 <- ifelse(length(tail(recent_data$avg_price, 7)) == 7, sd(tail(recent_data$avg_price, 7), na.rm = TRUE), 0) # 標準差可能為 NA
    
    # 針對氣象參數的 lag 7 天，在自定義預測時，直接使用輸入的當天氣象參數
    temp_avg_c_lag_7 <- weather_params$temp_avg 
    rh_avg_pct_lag_7 <- weather_params$rh_avg
    precip_accumulated_mm_lag_7 <- weather_params$precip
    
    pred_data <- data.frame(
      year = pred_year,
      month = pred_month,
      day_of_week = pred_day_of_week,
      is_weekend = pred_is_weekend,
      avg_price_lag_1 = avg_price_lag_1,
      avg_price_lag_7 = avg_price_lag_7,
      avg_price_lag_14 = avg_price_lag_14,
      avg_price_lag_30 = avg_price_lag_30,
      avg_price_roll_mean_7 = avg_price_roll_mean_7,
      avg_price_roll_mean_14 = avg_price_roll_mean_14,
      avg_price_roll_sd_7 = ifelse(is.na(avg_price_roll_sd_7), 0, avg_price_roll_sd_7), # 處理可能為NA的標準差
      temp_avg_c = weather_params$temp_avg,
      temp_max_c = weather_params$temp_max,
      temp_min_c = weather_params$temp_min,
      temp_avg_c_lag_7 = temp_avg_c_lag_7,
      rh_avg_pct = weather_params$rh_avg,
      rh_min_pct = weather_params$rh_min,
      rh_avg_pct_lag_7 = rh_avg_pct_lag_7,
      precip_accumulated_mm = weather_params$precip,
      precip_accumulated_mm_lag_7 = precip_accumulated_mm_lag_7
    )
    
    # 將所有 NA 值替換為 0
    pred_data[is.na(pred_data)] <- 0 
    
    tryCatch({
      predicted_price <- predict(ranger_model, data = pred_data)$predictions
      return(list(prediction = round(predicted_price, 2), error = NULL))
    }, error = function(e) {
      return(list(error = paste("預測錯誤:", e$message)))
    })
  }
  
  # 自定義預測功能 
  observeEvent(input$run_prediction, {
    # 確保預測的市場是 RandomForest 頁面所選的市場
    selected_market_code <- input$rf_market 
    
    weather_params <- list(
      temp_avg = input$predict_temp_avg,
      temp_max = input$predict_temp_max,
      temp_min = input$predict_temp_min,
      rh_avg = input$predict_rh_avg,
      rh_min = input$predict_rh_min,
      precip = input$predict_precip
    )
    
    result <- predict_price( # 將結果存在 result 變數
      market_code = selected_market_code, # 使用 RandomForest 頁面選擇的市場
      predict_date = input$predict_date,
      weather_params = weather_params,
      last_price = input$predict_last_price
    )
    
    # 更新預測結果
    output$prediction_result <- renderUI({ # 使用 renderUI 而非 renderText 以便呈現 HTML 結構
      market_names <- list(
        "400" = "台中市",
        "420" = "豐原區", 
        "512" = "永靖鄉",
        "514" = "溪湖鎮",
        "648" = "西螺鎮"
      )
      
      market_name <- market_names[[selected_market_code]] # 使用 RandomForest 頁面選擇的市場名稱
      
      if (!is.null(result$error)) {
        div(class = "prediction-result",
            h3("預測錯誤"),
            p(paste("錯誤訊息:", result$error))
        )
      } else if (!is.null(result$prediction) && is.numeric(result$prediction)) {
        div(class = "prediction-result",
            h3("預測結果"),
            p(paste("市場:", market_name)),
            p(paste("預測日期:", format(input$predict_date, "%Y年%m月%d日"))),
            div(class = "result-price", paste0(result$prediction, " 元/公斤")),
            p("*預測結果僅供參考，實際價格可能受多種因素影響")
        )
      } else {
        div(class = "prediction-result",
            h3("預測失敗"),
            p("請檢查模型或輸入資料。")
        )
      }
    })
  })
  
  # arima 圖片列表
  arima_images_list <- list(
    "512" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/arima/512fit%20data%20price%E8%B6%A8%E5%8B%A2.jpg",
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/arima/512%E5%B8%82%E5%A0%B4%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_arima.jpg"
    ),
    "514" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/arima/514fit%20data%20price%E8%B6%A8%E5%8B%A2.jpg",
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/arima/514%E5%B8%82%E5%A0%B4%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_arima.jpg"
    ),
    "648" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/arima/648fit%20data%20price%E8%B6%A8%E5%8B%A2.jpg",
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/arima/648%E5%B8%82%E5%A0%B4%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_arima.jpg"
    )
  )
  
  # XGBoost 圖片列表
  xgboost_images_list <- list(
    "512" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/xgboost/512%E5%B8%82%E5%A0%B4%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_xgboost.jpg"
    ),
    "514" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/xgboost/514%E5%B8%82%E5%A0%B4%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_xgboost.jpg"
    ),
    "648" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/xgboost/648%E5%B8%82%E5%A0%B4%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_xgboost.jpg"
    )
  )
  
  # Random Forest 圖片列表
  rf_images_list <- list(
    "400" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/ranger/400%E5%B8%82%E5%A0%B4%E8%8A%B1%E6%A4%B0%E8%8F%9C%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_ranger.png"
    ),
    "420" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/ranger/420%E5%B8%82%E5%A0%B4%E8%8A%B1%E6%A4%B0%E8%8F%9C%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_ranger.png"
    ),
    "512" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/ranger/512%E5%B8%82%E5%A0%B4%E8%8A%B1%E6%A4%B0%E8%8F%9C%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_ranger.png"
    ),
    "514" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/ranger/514%E5%B8%82%E5%A0%B4%E8%8A%B1%E6%A4%B0%E8%8F%9C%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_ranger.png"
    ),
    "648" = c(
      "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/results/ranger/648%E5%B8%82%E5%A0%B4%E8%8A%B1%E6%A4%B0%E8%8F%9C%E5%83%B9%E6%A0%BC%E9%A0%90%E6%B8%AC_ranger.png"
    )
  )
  
  # 相關係數圖片列表 
  correlation_images_list <- c(
    "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/code/coefficient/400_%E5%8F%B0%E4%B8%AD%E5%B8%82_w-6.jpg",
    "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/code/coefficient/420_%E8%B1%90%E5%8E%9F%E5%8D%80_w-6.jpg",
    "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/code/coefficient/512_%E6%B0%B8%E9%9D%96%E9%84%89_w-4.jpg",
    "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/code/coefficient/514_%E6%BA%AA%E6%B9%96%E9%8E%AE_w-3.jpg",
    "https://raw.githubusercontent.com/1132-NCCU-DataScience/finalproject-group-6/main/code/coefficient/648_%E8%A5%BF%E8%9E%BA%E9%8E%AE_w-3.jpg"
  )
  
  # arima 圖片輸出 - 一列一張圖
  output$arima_images <- renderUI({
    req(input$arima_market)
    
    imgs <- arima_images_list[[input$arima_market]]
    if (is.null(imgs)) {
      return(tags$p("尚無此市場的圖片資料。"))
    }
    
    # 每張圖片獨立一列
    lapply(imgs, function(img_url) {
      fluidRow(
        column(width = 12,
               div(class = "image-container",
                   tags$img(src = img_url)
               )
        )
      )
    })
  })
  
  # XGBoost 圖片輸出 - 一列一張圖
  output$xgboost_images <- renderUI({
    req(input$xgboost_market)
    
    imgs <- xgboost_images_list[[input$xgboost_market]]
    if (is.null(imgs)) {
      return(tags$p("尚無此市場的圖片資料。"))
    }
    
    # 每張圖片獨立一列
    lapply(imgs, function(img_url) {
      fluidRow(
        column(width = 12,
               div(class = "image-container",
                   tags$img(src = img_url)
               )
        )
      )
    })
  })
  
  # Random Forest 圖片輸出 - 一列一張圖
  output$rf_images <- renderUI({
    req(input$rf_market)
    
    imgs <- rf_images_list[[input$rf_market]]
    if (is.null(imgs)) {
      return(tags$p("尚無此市場的圖片資料。"))
    }
    
    # 每張圖片獨立一列
    lapply(imgs, function(img_url) {
      fluidRow(
        column(width = 12,
               div(class = "image-container",
                   tags$img(src = img_url)
               )
        )
      )
    })
  })
  
  # 相關係數圖片輸出 
  output$correlation_images <- renderUI({
    imgs <- correlation_images_list
    if (is.null(imgs) || length(imgs) == 0) {
      return(tags$p("尚無相關係數圖片資料。"))
    }
    
    lapply(imgs, function(img_url) {
      fluidRow(
        column(width = 12,
               div(class = "image-container",
                   tags$img(src = img_url)
               )
        )
      )
    })
  })
  
  # ARIMA 評估指標表格
  output$arima_params <- renderTable({
    data.frame(
      評估指標 = c("RMSE", "MAE", "R-squared"),
      值 = c("12.8866", "8.4518", "0.3552")
    )
  }, class = "evaluation-table", hover = TRUE, striped = FALSE)
  
  # XGBoost 評估指標表格
  output$xgboost_features <- renderTable({
    data.frame(
      評估指標 = c("RMSE", "MAE", "R-squared"),
      值 = c("12.8895", "8.874705", "0.3549066")
    )
  }, class = "evaluation-table", hover = TRUE, striped = FALSE)
  
  # Random Forest 評估指標表格
  output$rf_stats <- renderTable({
    data.frame(
      評估指標 = c("RMSE", "MAE", "MAPE", "R-squared"),
      值 = c("9.89", "7.1", "21.83%", "0.690241")
    )
  }, class = "evaluation-table", hover = TRUE, striped = FALSE)
  
  # 初始化預測結果為空 (移到 server 內部，確保在應用啟動時被設定)
  output$prediction_result <- renderUI({
    div(style = "text-align: center; padding: 40px; color: #666;",
        h4("請設定預測參數並點擊「執行預測」按鈕"),
        icon("arrow-up", style = "font-size: 2em; margin-top: 20px;")
    )
  })
}

# 運行應用程式
shinyApp(ui = ui, server = server)
