library(tidyverse)
library(lubridate)
library(ranger)
library(Metrics)
library(zoo)
library(ggplot2)

# 設定工作目錄
setwd("C:/Users/l7475/NLP/DS_Final")
dir.create("plots/rf_slides_final", recursive = TRUE, showWarnings = FALSE)

# 載入與處理數據
cauliflower_daily_raw <- read_csv("vegdata/花椰菜 青梗.csv", locale = locale(encoding = "UTF-8"))
weather_daily_raw <- read_csv("weatherdata/daily_weather.csv", locale = locale(encoding = "UTF-8"))

# 處理花椰菜數據
cauliflower_processed <- cauliflower_daily_raw %>%
  mutate(
    market_code = str_extract(`市場`, "^[0-9A-Za-z]+"),
    market_name = str_replace(`市場`, "^[0-9A-Za-z]+\\s*", ""),
    crop_name_full = str_replace(`產品`, "^[^\\s]+\\s*", "")
  ) %>%
  filter(str_detect(crop_name_full, "花椰菜") & str_detect(crop_name_full, "青梗"))

# 清理數據
cauliflower_cleaned <- cauliflower_processed %>%
  rename(
    original_date_str = `日期`,
    price_upper = `上價`,
    price_middle = `中價`,
    price_lower = `下價`,
    avg_price = `平均價(元/公斤)`,
    transaction_volume = `交易量(公斤)`
  )

# 日期處理
cauliflower_cleaned <- cauliflower_cleaned %>%
  mutate(
    year_roc_str = str_sub(original_date_str, 1, str_locate(original_date_str, "/")[,1] - 1),
    month_day_str = str_sub(original_date_str, str_locate(original_date_str, "/")[,1] + 1),
    year_roc = as.integer(year_roc_str),
    year_ad = year_roc + 1911,
    month_str = str_sub(month_day_str, 1, str_locate(month_day_str, "/")[,1] - 1),
    day_str = str_sub(month_day_str, str_locate(month_day_str, "/")[,1] + 1),
    month = as.integer(month_str),
    day = as.integer(day_str),
    date = ymd(paste(year_ad, sprintf("%02d", month), sprintf("%02d", day), sep="-"), quiet = TRUE)
  ) %>%
  mutate(
    avg_price = as.numeric(avg_price),
    transaction_volume = as.numeric(transaction_volume),
    price_upper = as.numeric(price_upper),
    price_middle = as.numeric(price_middle),
    price_lower = as.numeric(price_lower),
    market_code = as.factor(market_code),
    market_name = as.factor(market_name)
  ) %>%
  distinct(date, market_name, .keep_all = TRUE)

# 清理天氣數據
weather_cleaned <- weather_daily_raw %>%
  rename(date = `觀測時間`) %>%
  select(
    date,
    `平均氣溫(℃)`, `最高氣溫(℃)`, `最低氣溫(℃)`,
    `平均相對溼度(%)`, `最低相對溼度(%)`,
    `累計雨量(mm)`
  ) %>%
  rename_with(
    ~ str_replace_all(., c("\\(℃\\)" = "_c", "\\(%\\)" = "_pct",
                           "\\(mm\\)" = "_mm",
                           "平均氣溫" = "temp_avg", "最高氣溫" = "temp_max", "最低氣溫" = "temp_min",
                           "平均相對溼度" = "rh_avg", "最低相對溼度" = "rh_min",
                           "累計雨量" = "precip_accumulated"))
  )

# 合併數據
merged_data <- left_join(cauliflower_cleaned, weather_cleaned, by = "date")

# 特徵工程與模型訓練
target_markets <- c("台中市", "豐原區", "永靖鄉", "溪湖鎮", "西螺鎮")
model_results_list <- list()

for (market_n in target_markets) {
  cat(paste("\n處理市場:", market_n, "\n"))
  
  # 篩選市場數據
  market_data <- merged_data %>%
    filter(market_name == market_n) %>%
    arrange(date)
  
  if(nrow(market_data) == 0) {
    cat("警告: 無法找到", market_n, "的花椰菜數據，跳過處理\n")
    next
  }
  
  # 添加特徵
  market_data <- market_data %>%
    mutate(
      year = year(date),
      month = month(date),
      day_of_week = wday(date, label = FALSE, week_start = 1),
      is_weekend = ifelse(day_of_week %in% c(6, 7), 1, 0)
    ) %>%
    arrange(date) %>%
    mutate(
      avg_price_lag_1 = lag(avg_price, 1),
      avg_price_lag_7 = lag(avg_price, 7),
      avg_price_lag_14 = lag(avg_price, 14),
      avg_price_lag_30 = lag(avg_price, 30),
      temp_avg_c_lag_7 = lag(temp_avg_c, 7),
      rh_avg_pct_lag_7 = lag(rh_avg_pct, 7),
      precip_accumulated_mm_lag_7 = lag(precip_accumulated_mm, 7),
      avg_price_roll_mean_7 = rollmean(avg_price, k=7, fill=NA, align="right"),
      avg_price_roll_mean_14 = rollmean(avg_price, k=14, fill=NA, align="right"),
      avg_price_roll_sd_7 = rollapply(avg_price, width=7, FUN=sd, fill=NA, align="right")
    ) %>%
    filter(!is.na(avg_price)) %>%
    mutate(across(contains(c("_lag_", "_roll_", "temp", "rh", "precip")), 
                  ~ifelse(is.na(.), median(., na.rm=TRUE), .)))
  
  # 分割數據
  train_ratio <- 0.8
  train_size <- floor(train_ratio * nrow(market_data))
  train_data <- market_data[1:train_size, ]
  test_data <- market_data[(train_size + 1):nrow(market_data), ]
  
  cat("訓練集行數:", nrow(train_data), ", 測試集行數:", nrow(test_data), "\n")
  
  # 定義三種不同特徵集
  weather_only_features <- c("year", "month", "day_of_week", "is_weekend", 
                             "temp_avg_c", "temp_max_c", "temp_min_c", "temp_avg_c_lag_7",
                             "rh_avg_pct", "rh_min_pct", "rh_avg_pct_lag_7",
                             "precip_accumulated_mm", "precip_accumulated_mm_lag_7")
  
  price_only_features <- c("year", "month", "day_of_week", "is_weekend", 
                           "avg_price_lag_1", "avg_price_lag_7", "avg_price_lag_14", "avg_price_lag_30",
                           "avg_price_roll_mean_7", "avg_price_roll_mean_14", "avg_price_roll_sd_7")
  
  combined_features <- c(weather_only_features, 
                         c("avg_price_lag_1", "avg_price_lag_7", "avg_price_lag_14", "avg_price_lag_30",
                           "avg_price_roll_mean_7", "avg_price_roll_mean_14", "avg_price_roll_sd_7"))
  
  # 確保特徵存在
  weather_only_features <- intersect(weather_only_features, colnames(train_data))
  price_only_features <- intersect(price_only_features, colnames(train_data))
  combined_features <- intersect(combined_features, colnames(train_data))
  
  # 訓練三個不同模型
  models <- list()
  performance <- list()
  
  # 1. 僅天氣特徵模型
  models$weather <- ranger(avg_price ~ ., 
                           data = train_data %>% select(avg_price, all_of(weather_only_features)),
                           num.trees = 500, importance = 'permutation', seed = 123)
  test_data$weather_pred <- predict(models$weather, data = test_data)$predictions
  
  # 2. 僅價格特徵模型  
  models$price <- ranger(avg_price ~ ., 
                         data = train_data %>% select(avg_price, all_of(price_only_features)),
                         num.trees = 500, importance = 'permutation', seed = 123)
  test_data$price_pred <- predict(models$price, data = test_data)$predictions
  
  # 3. 混合特徵模型
  models$combined <- ranger(avg_price ~ ., 
                            data = train_data %>% select(avg_price, all_of(combined_features)),
                            num.trees = 500, importance = 'permutation', seed = 123)
  test_data$combined_pred <- predict(models$combined, data = test_data)$predictions
  
  # 計算性能指標
  for(model_type in c("weather", "price", "combined")) {
    pred_col <- paste0(model_type, "_pred")
    rmse_val <- rmse(test_data$avg_price, test_data[[pred_col]])
    mae_val <- mae(test_data$avg_price, test_data[[pred_col]])
    mape_val <- mean(abs((test_data$avg_price - test_data[[pred_col]]) / test_data$avg_price), na.rm = TRUE) * 100
    r_squared <- 1 - sum((test_data$avg_price - test_data[[pred_col]])^2) / 
      sum((test_data$avg_price - mean(test_data$avg_price))^2)
    
    performance[[model_type]] <- list(rmse = rmse_val, mae = mae_val, mape = mape_val, r2 = r_squared)
    cat(paste(model_type, "模型 RMSE:", round(rmse_val, 2), "R²:", round(r_squared, 3), "\n"))
  }
  
  # 特徵重要性
  imp <- ranger::importance(models$combined)
  importance_df <- data.frame(Feature = names(imp), Importance = imp) %>% arrange(desc(Importance))
  
  # 儲存結果
  model_results_list[[market_n]] <- list(
    ranger = list(models = models, importance = imp, performance = performance),
    data_splits = list(train_data = train_data, test_data = test_data)
  )
  
  # 為永靖鄉生成簡報圖片
  if(market_n == "永靖鄉") {
    # 特徵重要性圖
    importance_df <- importance_df %>%
      mutate(
        Category = case_when(
          str_detect(Feature, "price|roll") ~ "價格相關",
          str_detect(Feature, "temp|rh|precip") ~ "天氣相關", 
          str_detect(Feature, "year|month|week|day") ~ "時間相關",
          TRUE ~ "其他"
        ),
        Feature_Clean = case_when(
          Feature == "avg_price_lag_1" ~ "價格滯後1天",
          Feature == "avg_price_roll_mean_7" ~ "價格7日均值",
          Feature == "avg_price_roll_mean_14" ~ "價格14日均值",
          Feature == "avg_price_lag_7" ~ "價格滯後7天",
          Feature == "temp_avg_c_lag_7" ~ "氣溫滯後7天",
          Feature == "temp_min_c" ~ "當日最低溫",
          Feature == "temp_avg_c" ~ "當日平均溫",
          Feature == "month" ~ "月份",
          TRUE ~ Feature
        )
      )
    
    # 特徵重要性圖
    p_importance <- ggplot(head(importance_df, 12), 
                           aes(x = reorder(Feature_Clean, Importance), y = Importance, fill = Category)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      geom_text(aes(label = round(Importance, 1)), hjust = -0.1, size = 3.5) +
      labs(title = "Random Forest自動特徵選擇",
           subtitle = "Permutation Importance排序識別關鍵預測因子",
           x = "特徵", y = "重要性分數") +
      theme_minimal() +
      theme(legend.position = "bottom") +
      scale_fill_brewer(palette = "Set2")
    
    ggsave("plots/rf_slides_final/slide2_feature_importance.png", 
           p_importance, width = 14, height = 10, dpi = 300, bg = "white")
    
    # 模型比較圖
    recent_train <- tail(train_data, 40)
    plot_data <- data.frame(
      time_index = 1:(nrow(recent_train) + nrow(test_data)),
      actual = c(recent_train$avg_price, test_data$avg_price),
      weather_pred = c(rep(NA, nrow(recent_train)), test_data$weather_pred),
      price_pred = c(rep(NA, nrow(recent_train)), test_data$price_pred),
      combined_pred = c(rep(NA, nrow(recent_train)), test_data$combined_pred)
    )
    
    # 比較圖
    p_compare <- ggplot(plot_data, aes(x = time_index)) +
      geom_line(aes(y = actual, color = "實際價格"), size = 1.2) +
      geom_line(aes(y = weather_pred, color = "僅天氣特徵"), size = 0.8, linetype = "dashed") +
      geom_line(aes(y = price_pred, color = "僅價格特徵"), size = 0.8, linetype = "dotted") +
      geom_line(aes(y = combined_pred, color = "混合特徵"), size = 0.8, linetype = "twodash") +
      geom_vline(xintercept = nrow(recent_train), color = "darkgray", linetype = "solid", alpha = 0.6) +
      labs(title = "三種Random Forest模型預測比較",
           subtitle = paste0("天氣R²:", round(performance$weather$r2, 3), 
                           " | 價格R²:", round(performance$price$r2, 3),
                           " | 混合R²:", round(performance$combined$r2, 3)),
           x = "時間序列", y = "價格 (元/公斤)") +
      theme_minimal() +
      theme(legend.position = "bottom") +
      scale_color_manual(values = c("實際價格" = "#2C3E50", "僅天氣特徵" = "#3498DB", 
                                   "僅價格特徵" = "#E74C3C", "混合特徵" = "#27AE60"))
    
    ggsave("plots/rf_slides_final/slide3_left_timeseries.png", 
           p_compare, width = 10, height = 6, dpi = 300, bg = "white")
    
    # 性能比較圖
    comparison_df <- data.frame(
      Model = c("僅天氣特徵", "僅價格特徵", "混合特徵"),
      R2 = c(performance$weather$r2, performance$price$r2, performance$combined$r2)
    )
    
    p_performance <- ggplot(comparison_df, aes(x = Model, y = R2, fill = Model)) +
      geom_bar(stat = "identity", width = 0.6) +
      geom_text(aes(label = paste0("R²=", round(R2, 3))), vjust = -0.3, size = 4, fontface = "bold") +
      labs(title = "模型性能比較",
           subtitle = "解決價格滯後特徵問題",
           x = "模型類型", y = "決定係數 (R²)") +
      theme_minimal() +
      theme(legend.position = "none") +
      scale_fill_manual(values = c("僅天氣特徵" = "#3498DB", "僅價格特徵" = "#E74C3C", "混合特徵" = "#27AE60")) +
      ylim(0, 1)
    
    ggsave("plots/rf_slides_final/slide3_right_performance.png", 
           p_performance, width = 8, height = 6, dpi = 300, bg = "white")
    
    # 殘差分析
    test_data$residuals <- test_data$avg_price - test_data$combined_pred
    test_data$time_index <- 1:nrow(test_data)
    
    # 殘差vs擬合值
    p1 <- ggplot(test_data, aes(x = combined_pred, y = residuals)) +
      geom_point(alpha = 0.6, color = "steelblue") +
      geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
      geom_smooth(method = "loess", se = TRUE, color = "orange", alpha = 0.3) +
      labs(title = "殘差 vs 擬合值", x = "預測價格", y = "殘差") +
      theme_minimal()
    
    # 殘差分布
    p2 <- ggplot(test_data, aes(x = residuals)) +
      geom_histogram(aes(y = ..density..), bins = 25, fill = "steelblue", alpha = 0.7) +
      geom_density(color = "red", size = 1) +
      labs(title = "殘差分布", x = "殘差", y = "密度") +
      theme_minimal()
    
    # 殘差時間序列
    p3 <- ggplot(test_data, aes(x = time_index, y = residuals)) +
      geom_line(color = "steelblue", alpha = 0.8) +
      geom_point(color = "steelblue", alpha = 0.6, size = 1) +
      geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
      labs(title = "殘差時間序列", x = "時間", y = "殘差") +
      theme_minimal()
    
    # Q-Q 圖
    p4 <- ggplot(test_data, aes(sample = residuals)) +
      stat_qq(color = "steelblue") +
      stat_qq_line(color = "red") +
      labs(title = "殘差 Q-Q 圖", x = "理論分位數", y = "樣本分位數") +
      theme_minimal()
    
    # 儲存診斷圖
    ggsave("plots/rf_slides_final/slide4_topleft_residuals.png", p1, width = 6, height = 4, dpi = 300, bg = "white")
    ggsave("plots/rf_slides_final/slide4_topright_distribution.png", p2, width = 6, height = 4, dpi = 300, bg = "white")
    ggsave("plots/rf_slides_final/slide4_bottomleft_timeseries.png", p3, width = 6, height = 4, dpi = 300, bg = "white")
    ggsave("plots/rf_slides_final/slide4_bottomright_qq.png", p4, width = 6, height = 4, dpi = 300, bg = "white")
    
    # 單一市場預測圖
    p_single <- ggplot(plot_data, aes(x = time_index)) +
      geom_rect(aes(xmin = 1, xmax = nrow(recent_train), ymin = -Inf, ymax = Inf), 
                fill = "lightblue", alpha = 0.2) +
      geom_rect(aes(xmin = nrow(recent_train), xmax = nrow(plot_data), ymin = -Inf, ymax = Inf), 
                fill = "mistyrose", alpha = 0.2) +
      geom_line(aes(y = actual, color = "實際價格"), size = 1.2) +
      geom_line(aes(y = combined_pred, color = "Random Forest預測"), size = 1, linetype = "dashed") +
      geom_vline(xintercept = nrow(recent_train), color = "gray30", linetype = "dotted", size = 0.8) +
      annotate("text", x = nrow(recent_train)/2, y = max(plot_data$actual, na.rm = TRUE) * 0.9, 
               label = "訓練期", size = 5, fontface = "bold") +
      annotate("text", x = nrow(recent_train) + nrow(test_data)/2, 
               y = max(plot_data$actual, na.rm = TRUE) * 0.9, 
               label = "預測期", size = 5, fontface = "bold") +
      labs(title = paste0(market_n, " Random Forest花椰菜價格預測"),
           subtitle = "RF極端值處理能力與波動捕捉效果展示",
           x = "時間序列", y = "價格 (元/公斤)",
           caption = "Random Forest對價格突變的敏感度分析") +
      theme_minimal() +
      theme(legend.position = "bottom") +
      scale_color_manual(values = c("實際價格" = "#2C3E50", "Random Forest預測" = "#E74C3C"))
    
    ggsave("plots/rf_slides_final/slide5_single_market.png", 
           p_single, width = 14, height = 10, dpi = 300, bg = "white")
  }
}

# 儲存模型結果
saveRDS(model_results_list, file = "models_saved/cauliflower_model_results.rds")
saveRDS(merged_data, file = "data_processed/cauliflower_merged_data.rds")

# 多市場比較分析
comparison_data <- data.frame()
for (market_n in names(model_results_list)) {
  if (!is.null(model_results_list[[market_n]][["ranger"]])) {
    market_row <- data.frame(
      Market = market_n,
      R2 = round(model_results_list[[market_n]][["ranger"]]$performance$combined$r2, 3),
      RMSE = round(model_results_list[[market_n]][["ranger"]]$performance$combined$rmse, 2),
      MAE = round(model_results_list[[market_n]][["ranger"]]$performance$combined$mae, 2),
      MAPE = round(model_results_list[[market_n]][["ranger"]]$performance$combined$mape, 2)
    )
    comparison_data <- rbind(comparison_data, market_row)
  }
}

# 繪製R²比較圖
p_r2 <- ggplot(comparison_data, aes(x = reorder(Market, -R2), y = R2, fill = Market)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = paste0("R²=", R2)), vjust = -0.3, size = 4, fontface = "bold") +
  labs(title = "各市場R²表現", x = "市場", y = "決定係數 (R²)") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set3") +
  ylim(0, 1)

# 繪製誤差指標比較圖
error_metrics <- comparison_data %>%
  select(Market, RMSE, MAE, MAPE) %>%
  pivot_longer(cols = c(RMSE, MAE, MAPE), names_to = "Metric", values_to = "Value")

p_errors <- ggplot(error_metrics, aes(x = Market, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  labs(title = "各市場誤差指標", x = "市場", y = "誤差值") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_fill_brewer(palette = "Set2")

# 保存多市場比較圖
ggsave("plots/rf_slides_final/slide6_left_r2.png", p_r2, width = 8, height = 6, dpi = 300, bg = "white")
ggsave("plots/rf_slides_final/slide6_right_errors.png", p_errors, width = 8, height = 6, dpi = 300, bg = "white")

# 特徵工程圖
feature_types <- data.frame(
  Type = c("價格歷史特徵", "時間特徵", "天氣當前特徵", "天氣滯後特徵", "滾動統計特徵"),
  Count = c(4, 4, 6, 3, 3),
  Description = c(
    "lag_1, lag_7, lag_14, lag_30",
    "year, month, day_of_week, weekend",
    "溫度、濕度、降雨量當前值",
    "7天前天氣滯後效應",
    "移動平均、標準差"
  )
)

p_feature_eng <- ggplot(feature_types, aes(x = reorder(Type, Count), y = Count, fill = Type)) +
  geom_bar(stat = "identity", width = 0.7) +
  coord_flip() +
  geom_text(aes(label = paste0(Count, "個特徵")), hjust = -0.1, size = 5) +
  labs(title = "Random Forest 多層次特徵工程",
       subtitle = "使用多元特徵整合取代單一外生變數方法",
       x = "特徵類別", y = "特徵數量",
       caption = "Random Forest直接處理非平穩數據，無需去趨勢預處理") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(type = "qual", palette = "Set3") +
  ylim(0, max(feature_types$Count) * 1.3)

ggsave("plots/rf_slides_final/slide1_feature_engineering.png", 
       p_feature_eng, width = 14, height = 10, dpi = 300, bg = "white")

cat("\n花椰菜價格預測模型訓練和所有簡報圖片生成完成！\n")
