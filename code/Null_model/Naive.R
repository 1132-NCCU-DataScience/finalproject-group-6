library(tidyverse)
library(lubridate)
library(xgboost)
library(caret)
library(dplyr)
library(showtext)
library(sysfonts)

# 載入 Google 的 Noto Sans TC（支援繁體中文）
font_add_google("Noto Sans TC", "noto")
showtext_auto()

# 設定 ggplot 預設字型
theme_set(theme_minimal(base_family = "noto"))

# 1. 讀取 CSV 檔案
cauliflower_data <- read.csv("data/cauliflower_cleaned.csv", fileEncoding = "UTF-8")
# week_data <- read.csv("data/weekly_veg_dataset.csv", fileEncoding = "UTF-8")

# 假設你的資料框叫 df，week 欄位是數字
cauliflower_data $week <- sprintf("%02d", cauliflower_data$week)

#####512 永靖鄉#####

# 篩選市場
df_market <- cauliflower_data %>%
  filter(市場 == "512 永靖鄉")

colnames(df_market)



# 合併 year 和 week 欄位，創建時間欄位
df <- df_market %>%
  mutate(date = paste(year, week, sep = "-"))

df_part1 <- df %>%
  filter(date >= "2022-41" & date <= "2023-40") %>%
  select(date, 平均價_元每公斤)

df_part2 <- df %>%
  filter(date >= "2022-41" & date <= "2023-18") %>%
  select(date, 平均價_元每公斤)

# 接在一起（保留順序與重複）
df_filtered <- bind_rows(df_part1, df_part2)
df_filtered

nrow(df_filtered)


pred_results <- read.csv("code/Null_model/512_pred_results.csv", fileEncoding = "UTF-8")

# 直接以順序填入 df_filtered 的值到 naive 欄位
# 確保兩個資料列數一致，否則會出錯
if (nrow(pred_results) == nrow(df_filtered)) {
  pred_results$naive <- df_filtered$`平均價_元每公斤`
} else {
  stop("資料列數不一致，無法直接填入。")
}


write.csv(pred_results, file = "code/Null_model/512_Naive_2.csv", row.names = FALSE)


#####514 溪湖鎮#####

# 篩選市場
df_market <- cauliflower_data %>%
  filter(市場 == "514 溪湖鎮")

colnames(df_market)



# 合併 year 和 week 欄位，創建時間欄位
df <- df_market %>%
  mutate(date = paste(year, week, sep = "-"))

df_part1 <- df %>%
  filter(date >= "2022-41" & date <= "2023-40") %>%
  select(date, 平均價_元每公斤)

df_part2 <- df %>%
  filter(date >= "2022-41" & date <= "2023-18") %>%
  select(date, 平均價_元每公斤)

# 接在一起（保留順序與重複）
df_filtered <- bind_rows(df_part1, df_part2)
df_filtered

nrow(df_filtered)


pred_results <- read.csv("code/Null_model/514_pred_results.csv", fileEncoding = "UTF-8")

# 直接以順序填入 df_filtered 的值到 naive 欄位
# 確保兩個資料列數一致，否則會出錯
if (nrow(pred_results) == nrow(df_filtered)) {
  pred_results$naive <- df_filtered$`平均價_元每公斤`
} else {
  stop("資料列數不一致，無法直接填入。")
}


write.csv(pred_results, file = "code/Null_model/514_Naive_2.csv", row.names = FALSE)

#####648 西螺鎮#####
# 篩選市場
# 篩選市場
df_market <- cauliflower_data %>%
  filter(市場 == "648 西螺鎮")

colnames(df_market)



# 合併 year 和 week 欄位，創建時間欄位
df <- df_market %>%
  mutate(date = paste(year, week, sep = "-"))

df_part1 <- df %>%
  filter(date >= "2022-41" & date <= "2023-40") %>%
  select(date, 平均價_元每公斤)

df_part2 <- df %>%
  filter(date >= "2022-41" & date <= "2023-18") %>%
  select(date, 平均價_元每公斤)

# 接在一起（保留順序與重複）
df_filtered <- bind_rows(df_part1, df_part2)
df_filtered

nrow(df_filtered)


pred_results <- read.csv("code/Null_model/648_pred_results.csv", fileEncoding = "UTF-8")

# 直接以順序填入 df_filtered 的值到 naive 欄位
# 確保兩個資料列數一致，否則會出錯
if (nrow(pred_results) == nrow(df_filtered)) {
  pred_results$naive <- df_filtered$`平均價_元每公斤`
} else {
  stop("資料列數不一致，無法直接填入。")
}


write.csv(pred_results, file = "code/Null_model/648_Naive_2.csv", row.names = FALSE)