@isTest(SeeAllData=True) 
public class sc_callout_getSAPAccInfo_test {
    
     public class MockHttpResponseGenerator implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{  "Message": "Success",  "MessageCode": "8000",  "Data": {    "AMOUNT": "49875.00",    "CREDIT_LIMIT": "100000.00",    "CREDIT_LIMIT_USED": "49.9",    "CURRENCY": "TWD",    "CUSTOMER_CURRENCY": "TWD",    "CUSTOMER_ID": "T27285346",    "CUSTOMER_NAME": "科毅科技股份有限公司",    "SALES_ID": "11236002",    "TERMS": "T030"  },  "Error": []}');
            return res;        
        }
	}
    public class MockHttpResponseGeneratorEx implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{  "Message": "Success",  "MessageCode": "8000",  "Data": {    "AMOUNT": "0.00",    "CREDIT_LIMIT": "0.00",    "CREDIT_LIMIT_USED": "0.0",    "CURRENCY": "",    "CUSTOMER_CURRENCY": "TWD",    "CUSTOMER_ID": "T27285346",    "CUSTOMER_NAME": "科毅科技股份有限公司",    "SALES_ID": "1123002",    "TERMS": "T030"  },  "Error": []}');
            return res;        
        }
	}
    
    public class MockHttpResponseGeneratorErr implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('{  "Message": "Not Found Error, please check error message",  "MessageCode": "2002",  "Data": {},  "Error": [    {      "Title": "No Data Found Error",      "Message": [        "No Data Found"      ]    }  ]}');
            return res;        
        }
	}
    
    public class MockHttpResponseGeneratorErr2 implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('err');
            return res;        
        }
	}

    
    @isTest static void testCalloutSuccess() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        sc_callout_getSAPAccInfo.calloutSAPAcc(acc.ERP_ID__c ,sc.Sales_Org__c,sc.Credit_Segment__c,sc.id);
        Test.stopTest();
        
    }
    @isTest static void testCalloutException() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorEx());
        sc_callout_getSAPAccInfo.calloutSAPAcc(acc.ERP_ID__c,sc.Sales_Org__c,sc.Credit_Segment__c,'123');
        Test.stopTest();
        
    }
    
    @isTest static void testCalloutException2() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorEx());
        sc_callout_getSAPAccInfo.calloutSAPAcc(acc.ERP_ID__c,sc.Sales_Org__c,sc.Credit_Segment__c,sc.id);
        Test.stopTest();
        
    }
    @isTest static void testCalloutErr() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorErr());
        sc_callout_getSAPAccInfo.calloutSAPAcc('T2728534',sc.Sales_Org__c,sc.Credit_Segment__c,sc.id);
        Test.stopTest();
        
    }
    @isTest static void testCalloutErr2() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorErr2());
        sc_callout_getSAPAccInfo.calloutSAPAcc('T2728534',sc.Sales_Org__c,sc.Credit_Segment__c,sc.id);
        Test.stopTest();
        
    }
    

}