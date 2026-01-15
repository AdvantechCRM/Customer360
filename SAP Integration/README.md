# SAP Integration

此專案為 Salesforce Lightning Web Component (LWC)，用於在 Salesforce 的 Account 頁面中整合並顯示 SAP ERP 系統的相關資訊。

## 專案概述

SAP Integration 元件透過 API 串接 SAP 系統，在 Salesforce 平台上即時呈現客戶的 SAP 帳戶資訊、應收帳款 (AR)、訂單追蹤等關鍵業務數據，讓銷售人員能夠在單一介面中掌握完整的客戶資訊。

## 主要功能

### 1. SAP Account Info (SAP 帳戶資訊)
- 顯示客戶基本資訊：ERP ID、帳戶名稱、幣別
- 信用資訊：信用額度、已使用額度、可用額度、信用曝險
- 業務資訊：Sales Code、Secondary Sales Code、Payment Terms
- 客戶分類：ERP ID Type (Sold-to, Ship-to, Bill-to, End Customer)
- 附加資訊：Tax Number、Incoterms、CLA 有效期間、Internal Sales Note
- 狀態標記：Archiving Flags、Central Block

### 2. SAP Account Receivable (應收帳款)
- 顯示未結清的應收帳款清單
- 資訊包含：Billing No、Document No、金額、到期日、逾期天數
- 逾期帳款以紅色標示警示
- 依到期日排序顯示

### 3. SAP Order Tracking (訂單追蹤)
- 顯示近期訂單摘要：SO#、PO#、Sales Code、Status、Order Date
- 點擊可展開查看訂單明細
- 訂單明細包含：產品名稱、數量、價格、交期、出貨狀態

### 4. Backlog & Shipment (待出貨與出貨記錄)
- 顯示 Backlog 和 Shipment 詳細資訊
- 可透過 Modal 視窗檢視完整資料

## 技術架構

### Lightning Web Components (LWC)

| 元件名稱 | 說明 |
|----------|------|
| `sc_lwc_SAPComponent` | 主元件，整合所有 SAP 資訊顯示 |
| `sc_lwc_SapOrderDetailsExtended` | 訂單明細 Modal 元件 |
| `sc_lwc_sapBSExtended` | Backlog/Shipment Modal 元件 |

### Apex Classes

| Class 名稱 | 說明 |
|------------|------|
| `sc_cls_getSAPInfo` | 資料查詢類別，從 Salesforce 物件取得 SAP 資料 |
| `sc_callout_getSAPAccInfo` | API Callout 類別，呼叫 SAP 取得帳戶信用資訊 |
| `sc_callout_getSAPARInfo` | API Callout 類別，呼叫 SAP 取得應收帳款資訊 |
| `sc_callout_getSAPOrderInfo` | API Callout 類別，呼叫 SAP 取得訂單資訊 |

### Custom Objects (相關物件)

- `SAP_Account__c` - 儲存 SAP 帳戶資訊
- `SAP_Account_Receivable__c` - 儲存應收帳款資料
- `SAP_Order_Tracking__c` - 儲存訂單追蹤資料
- `Sales_Code__c` - 銷售代碼主檔

### Static Resources

- `toastCss` - 自訂 Toast 訊息樣式

## API 整合

本專案透過 Named Credential `SIS_Endpoint_CRM` 連接 SAP 系統，呼叫以下 API：

| API Endpoint | 功能 |
|--------------|------|
| `/ITD_ERP/GET_AccountCreditInfo` | 取得客戶信用資訊 |
| `/ITD_ERP/GET_AccountReceivable` | 取得應收帳款資訊 |
| `/ITD_ERP/GET_OrderDetail` | 取得訂單明細資訊 |

## 使用方式

1. 將此元件加入 Account Record Page
2. 元件會自動根據 Account 的 `ERP_ID__c` 欄位查詢相關 SAP 資訊
3. 點擊 Refresh 按鈕可即時呼叫 SAP API 更新資料

## 檔案結構

```
SAP Integration/
 force-app/
     main/
         default/
             classes/
                sc_cls_getSAPInfo.cls
                sc_cls_getSAPInfo_test.cls
                sc_callout_getSAPAccInfo.cls
                sc_callout_getSAPAccInfo_test.cls
                sc_callout_getSAPARInfo.cls
                sc_callout_getSAPARInfo_test.cls
                sc_callout_getSAPOrderInfo.cls
                sc_callout_getSAPOrderInfo_test.cls
             lwc/
                sc_lwc_SAPComponent/
                sc_lwc_SapOrderDetailsExtended/
                sc_lwc_sapBSExtended/
             staticresources/
                 toastCss.css
```

## 相依性

- Salesforce Lightning Experience
- Named Credential: `SIS_Endpoint_CRM`
- Custom Objects: SAP_Account__c, SAP_Account_Receivable__c, SAP_Order_Tracking__c

## 維護資訊

如有問題請聯繫：crm.acl@advantech.com.tw
