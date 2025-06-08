import requests
import pandas as pd
import time

# API設定
API_URL = "https://data.moa.gov.tw/api/v1/AgriProductsTransType/"
API_KEY = "A0ML7D9RCHA82XWDMOP6UWRKNK33CU"
START_TIME = "111.07.01"
END_TIME = "111.07.05"

# 手動輸入蔬菜名稱，用逗號分隔
crop_input = input("請輸入蔬菜名稱：\n")
crop_list = [name.strip() for name in crop_input.split(",") if name.strip()]

# 用來存全部的資料
all_data = []

# 對每一個蔬菜名稱進行查詢
for crop_name in crop_list:
    page = 1
    has_next = True
    
    print(f"開始查詢：{crop_name}")

    while has_next:
        params = {
            "Start_time": START_TIME,
            "End_time": END_TIME,
            "CropName": crop_name,
            "Page": page
        }
        headers = {
            "ApiKey": API_KEY
        }
        try:
            response = requests.get(API_URL, headers=headers, params=params, timeout=10)
            response.raise_for_status()
            result = response.json()

            # 儲存當頁的資料
            if "Data" in result and isinstance(result["Data"], list):
                all_data.extend(result["Data"])

            # 確認是否有下一頁
            has_next = result.get("Next", False)
            if has_next:
                page += 1
                time.sleep(0.3) 
            else:
                break
        except Exception as e:
            print(f"錯誤：{crop_name} 第 {page} 頁請求失敗，錯誤訊息: {e}")
            break

# 輸出成 CSV
if all_data:
    output_df = pd.DataFrame(all_data)
    output_df.to_csv("output.csv", index=False, encoding="utf-8-sig")
    print("✅ 爬蟲完成！已儲存到 output.csv")
else:
    print("⚠️ 沒有任何資料被儲存。")
