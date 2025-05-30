# csv
# 載入必要套件
library(readxl)
library(dplyr)
library(lubridate)
library(tools)

# 自訂函數：處理單一檔案並輸出 CSV
process_file <- function(file_path) {
  data_raw <- read_excel(file_path, col_names = FALSE)
  data_cleaned <- data_raw[-c(1:4), ]
  data_cleaned <- data_cleaned[, -ncol(data_cleaned)]
  colnames(data_cleaned) <- as.character(unlist(data_cleaned[1, ]))
  data <- data_cleaned[-1, ]
  
  # 命名欄位
  colnames(data) <- c("日期", "市場", "產品", "上價", "中價", "下價", 
                      "平均價_元每公斤", "平均價增減百分比", "交易量_公斤", "交易量增減百分比")
  
  # ✅ 1. 移除增減欄位
  before_rows <- nrow(data)
  data <- data %>% select(-`平均價增減百分比`, -`交易量增減百分比`) %>% na.omit()
  after_rows <- nrow(data)
  deleted_rows <- before_rows - after_rows
  message("檔案 ", basename(file_path), " 中共刪除 ", deleted_rows, " 筆含 NA 的資料。")
  
  # 日期轉換函數
  convert_to_ad <- function(date_string) {
    tryCatch({
      parts <- unlist(strsplit(as.character(date_string), "/"))
      ad_year <- as.integer(parts[1]) + 1911
      as.Date(paste(ad_year, parts[2], parts[3], sep = "-"))
    }, error = function(e) NA)
  }
  
  # 數值清理函數
  clean_numeric <- function(x) {
    cleaned <- gsub("[^0-9.-]", "", x)
    cleaned[cleaned == "-"] <- NA
    suppressWarnings(as.numeric(cleaned))
  }
  
  # 日期與週次欄位處理
  data <- data %>%
    mutate(
      日期 = as.Date(sapply(日期, convert_to_ad)),
      week = isoweek(日期),
      year = year(日期)
    )
  
  # ✅ 2. 計算每週統計值（價格用 mean，交易量用 sum）
  weekly_summary <- data %>%
    mutate(across(c(上價, 中價, 下價, 平均價_元每公斤, 交易量_公斤), clean_numeric)) %>%
    group_by(市場, year, week) %>%
    summarise(
      上價 = mean(上價, na.rm = TRUE),
      中價 = mean(中價, na.rm = TRUE),
      下價 = mean(下價, na.rm = TRUE),
      平均價_元每公斤 = mean(平均價_元每公斤, na.rm = TRUE),
      交易量_公斤 = sum(交易量_公斤, na.rm = TRUE),
      .groups = "drop"
    )
  
  # 驗證資料中無缺失值
  if (anyNA(weekly_summary)) {
    stop(paste("錯誤：檔案", basename(file_path), "處理後仍含有缺失值，請檢查原始資料。"))
  }
  
  # 輸出 CSV
  file_base <- file_path_sans_ext(basename(file_path))
  output_name <- paste0(file_base, "_周彙總資料.csv")
  write.csv(weekly_summary, output_name, row.names = FALSE, fileEncoding = "big5")
}

# 檔案清單
file_list <- c("茼蒿.xls", "豌豆 甜豌豆.xls", "花椰菜 青梗.xls")

# 執行
for (file in file_list) {
  process_file(file)  
}

# xls
library(readxl)
library(dplyr)
library(lubridate)
library(writexl)
library(tools)

process_file <- function(file_path) {
  data_raw <- read_excel(file_path, col_names = FALSE)
  data_cleaned <- data_raw[-c(1:4), ]
  data_cleaned <- data_cleaned[, -ncol(data_cleaned)]
  colnames(data_cleaned) <- as.character(unlist(data_cleaned[1, ]))
  data <- data_cleaned[-1, ]
  
  # 命名欄位
  colnames(data) <- c("日期", "市場", "產品", "上價", "中價", "下價", 
                      "平均價_元每公斤", "平均價增減百分比", "交易量_公斤", "交易量增減百分比")
  
  # ✅ 1. 一開始就移除增減欄位
  before_rows <- nrow(data)
  data <- data %>% select(-`平均價增減百分比`, -`交易量增減百分比`) %>% na.omit()
  after_rows <- nrow(data)
  deleted_rows <- before_rows - after_rows
  message("檔案 ", basename(file_path), " 中共刪除 ", deleted_rows, " 筆含 NA 的資料。")
  
  
  # 日期轉換
  convert_to_ad <- function(date_string) {
    tryCatch({
      parts <- unlist(strsplit(as.character(date_string), "/"))
      ad_year <- as.integer(parts[1]) + 1911
      as.Date(paste(ad_year, parts[2], parts[3], sep = "-"))
    }, error = function(e) NA)
  }
  
  # 數值清理
  clean_numeric <- function(x) {
    cleaned <- gsub("[^0-9.-]", "", x)
    cleaned[cleaned == "-"] <- NA
    suppressWarnings(as.numeric(cleaned))
  }
  
  # 日期與週次處理
  data <- data %>%
    mutate(
      日期 = as.Date(sapply(日期, convert_to_ad)),
      week = isoweek(日期),
      year = year(日期)
    )
  
  # ✅ 2. 價格用 mean、交易量用 sum
  weekly_summary <- data %>%
    mutate(across(c(上價, 中價, 下價, 平均價_元每公斤, 交易量_公斤), clean_numeric)) %>%
    group_by(市場, year, week) %>%
    summarise(
      上價 = mean(上價, na.rm = TRUE),
      中價 = mean(中價, na.rm = TRUE),
      下價 = mean(下價, na.rm = TRUE),
      平均價_元每公斤 = mean(平均價_元每公斤, na.rm = TRUE),
      交易量_公斤 = sum(交易量_公斤, na.rm = TRUE),
      .groups = "drop"
    )
  
  if (anyNA(weekly_summary)) {
    stop(paste("錯誤：檔案", basename(file_path), "處理後仍含有缺失值，請檢查原始資料。"))
  }
  
  # 輸出 Excel 檔案
  file_base <- file_path_sans_ext(basename(file_path))
  output_name <- paste0(file_base, "_周彙總資料.xlsx")
  write_xlsx(weekly_summary, output_name)
}

# 檔案清單
file_list <- c("茼蒿.xls", "豌豆 甜豌豆.xls", "花椰菜 青梗.xls")

# 執行
for (file in file_list) {
  process_file(file)
}
