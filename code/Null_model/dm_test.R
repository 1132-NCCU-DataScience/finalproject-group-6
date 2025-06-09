# install.packages("forecast")  # 包含 dm.test

library(forecast)

# 讀入資料
df <- read.csv("code/Null_model/512_naive_2.csv", fileEncoding = "UTF-8")

# 計算誤差
e1 <- df$actual - df$naive       # naive 預測誤差
e2 <- df$actual - df$predicted   # 你的模型預測誤差

# 執行 Diebold-Mariano test
dm_result <- dm.test(e1, e2, h = 2, power = 3, alternative = "less")


# 查看結果
print(dm_result)

#############
# 讀入資料
df <- read.csv("code/Null_model/514_naive_2.csv", fileEncoding = "UTF-8")

# 計算誤差
e1 <- df$actual - df$naive       # naive 預測誤差
e2 <- df$actual - df$predicted   # 你的模型預測誤差

# 執行 Diebold-Mariano test
dm_result <- dm.test(e1, e2, h = 2, power = 2, alternative = "less")

# 查看結果
print(dm_result)
####################
# 讀入資料
df <- read.csv("code/Null_model/648_naive_2.csv", fileEncoding = "UTF-8")

# 計算誤差
e1 <- df$actual - df$naive       # naive 預測誤差
e2 <- df$actual - df$predicted   # 你的模型預測誤差

# 執行 Diebold-Mariano test
dm_result <- dm.test(e1, e2, h = 2, power = 2, alternative = "less")
# 查看結果
print(dm_result)




