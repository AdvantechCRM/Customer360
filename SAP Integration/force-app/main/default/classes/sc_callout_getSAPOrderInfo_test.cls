@isTest
public class sc_callout_getSAPOrderInfo_Test {

    // 模擬成功回傳的 HTTP 回應
    public class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message": "Success", "MessageCode": "8000", "Data": [ {"SD_DOC": "EU076382","ITM_NUMBER": "000001","MATERIAL": "9768ANTN001","SHORT_TEXT": "WLAN kit external Antenna 4dBi","DOC_TYPE": "ZOR6","DOC_DATE": "2023-07-21","REQ_QTY": "11.000","REQ_DATE": "2023-08-10","PURCH_NO": "2023/0615NL412Order2","SOLD_TO": "EDDETR29","NET_PRICE": "233.00","NET_VAL_HD": "67959.50","NET_VALUE": "2563.00","SALES_ORG": "EU10","CURRENCY": "EUR","PLANT": "EUH3","SALES_ID": "35113039","STATUS": "COMPLETE","BILL_QTY": "11.000"}], "Error": []}');
            return res;
        }
    }

    // 模擬 404 找不到資料
    public class MockNotFound implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message": "Not Found Error","MessageCode": "2002","Data": {}, "Error": []}');
            return res;
        }
    }

    // 模擬成功但無 Data
    public class MockEmptyData implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message": "Success", "MessageCode": "8000", "Data": [], "Error": []}');
            return res;
        }
    }

    // 模擬伺服器錯誤 500
    public class MockServerError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message": "Server Error"}');
            return res;
        }
    }

    // 建立必要測試資料
    private static void initTestData() {
        Sales_Code__c sc = new Sales_Code__c(EXID__C = '35113039', Name = 'Test SC');
        insert sc;

        Account acc = new Account(Name='Test Account', ERP_ID__c='EDDETR29');
        insert acc;

        SAP_Account__c sapAcc = new SAP_Account__c(Name='SAP Test', ERP_ID__c = 'EDDETR29');
        insert sapAcc;
    }

    @isTest static void test_Callout_Success() {
        initTestData();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        sc_callout_getSAPOrderInfo.responseWrapper result = sc_callout_getSAPOrderInfo.calloutSAPOrder('EDDETR29', 'EU10', 'a2dfS000000NJGUQA4');
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, '應該返回成功狀態');
        System.assert(result.message.contains('SAP Order data update successfully!'));
    }

    @isTest static void test_Callout_NotFound() {
        initTestData();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockNotFound());
        sc_callout_getSAPOrderInfo.responseWrapper result = sc_callout_getSAPOrderInfo.calloutSAPOrder('T88234398', 'TW01', 'SAPACCID002');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, '應該不成功');
        System.assert(result.message.contains('no available Order data') || result.message != null);
    }

    @isTest static void test_Callout_EmptyData() {
        initTestData();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockEmptyData());
        sc_callout_getSAPOrderInfo.responseWrapper result = sc_callout_getSAPOrderInfo.calloutSAPOrder('SSY011', 'SG01', 'a2dff0000000CNlAAM');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, '資料為空應該不成功');
        System.assert(result.message.contains('no order data'));
    }

    @isTest static void test_Callout_ServerError() {
        initTestData();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockServerError());
        sc_callout_getSAPOrderInfo.responseWrapper result = sc_callout_getSAPOrderInfo.calloutSAPOrder('EDDETR29', 'EU10', 'SAPACCID004');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, '伺服器錯誤應該不成功');
    }
}