@isTest(SeeAllData=True) 
public class sc_callout_getSAPARInfo_test {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{    "Message": "Success",    "MessageCode": "8000",    "Data": [        {            "BILLING": "0095000374",            "COMP_CODE": "EU10",            "CUSTOMER": "EDDETR29",            "DOC_NO": "0095000374",            "AMOUNT": "34540.00",            "CURRENCY": "EUR",            "BILLING_DATE": "2023-10-06",            "DUEDATE": "2023-11-30",            "OVDUE_DAYS": "          2-",            "STATUS": "NotDue"        },        {            "BILLING": "0095000375",            "COMP_CODE": "EU10",            "CUSTOMER": "EDDETR29",            "DOC_NO": "0095000375",            "AMOUNT": "5500.00",            "CURRENCY": "EUR",            "BILLING_DATE": "2023-10-06",            "DUEDATE": "2023-11-30",            "OVDUE_DAYS": "          2-",            "STATUS": "NotDue"        }],    "Error": []}');
            return res;        
        }
	}
    
    @isTest static void testCalloutSuccess() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        SAP_Account__c sapAcc = sc_cls_TestDataFactory.createSAPAcc(acc.ERP_ID__c);
        List<SAP_Account_Receivable__c> arlist = sc_cls_TestDataFactory.createSAPAr(sapAcc.ERP_ID__c,sapAcc.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        sc_callout_getSAPARInfo.calloutSAPAR(acc.ERP_ID__c ,'EU10',sapAcc.id);
        Test.stopTest();
        
    }
    
    public class MockHttpResponseGeneratorEx implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('{    "Message": "Not Found Error, please check error message",    "MessageCode": "2002",    "Data": {},    "Error": [        {            "Title": "No Data Found Error",            "Message": [                "No Data Found"            ]        }    ]}');
            return res;        
        }
	}
    
    @isTest static void testCalloutEx() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        SAP_Account__c sapAcc = sc_cls_TestDataFactory.createSAPAcc(acc.ERP_ID__c);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorEx());
        sc_callout_getSAPARInfo.calloutSAPAR(acc.ERP_ID__c ,sc.Sales_Org__c,sapAcc.id);
        Test.stopTest();
        
    }
    public class MockHttpResponseGeneratorEx2 implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(406);
            res.setBody('{    "Message": "Service Error",    "MessageCode": "9999",    "Data": {},    "Error": [        {            "Title": "Service Error",            "Message": [                "Can not parse Json."            ]        }    ]}');
            return res;        
        }
	}
    
    @isTest static void testCalloutEx2() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        SAP_Account__c sapAcc = sc_cls_TestDataFactory.createSAPAcc(acc.ERP_ID__c);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorEx2());
        sc_callout_getSAPARInfo.calloutSAPAR(acc.ERP_ID__c ,sc.Sales_Org__c,sapAcc.id);
        Test.stopTest();
        
    }
    public class MockHttpResponseGeneratorEx3 implements HttpCalloutMock {
  
         public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{    "Message": "Success",    "MessageCode": "8000",    "Data": [        {            "BILLING": "0095000374",            "COMP_CODE": "EU10",            "CUSTOMER": "00000000",            "DOC_NO": "0095000374",            "AMOUNT": "34540.00",            "CURRENCY": "EUR",            "BILLING_DATE": "2023-10-06",            "DUEDATE": "2023-11-30",            "OVDUE_DAYS": "          2-",            "STATUS": "NotDue"        },        {            "BILLING": "0095000375",            "COMP_CODE": "EU10",            "CUSTOMER": "00000000",            "DOC_NO": "0095000375",            "AMOUNT": "5500.00",            "CURRENCY": "EUR",            "BILLING_DATE": "2023-10-06",            "DUEDATE": "2023-11-30",            "OVDUE_DAYS": "          2-",            "STATUS": "NotDue"        }],    "Error": []}');
            return res;        
        }
	}
    
    @isTest static void testCalloutEx3() {
        Sales_Code__c sc = sc_cls_TestDataFactory.createSC();
        Account acc = sc_cls_TestDataFactory.createAccount(true);
        SAP_Account__c sapAcc = sc_cls_TestDataFactory.createSAPAcc(acc.ERP_ID__c);
        List<SAP_Account_Receivable__c> arlist = sc_cls_TestDataFactory.createSAPAr(sapAcc.ERP_ID__c,sapAcc.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorEx3());
        sc_callout_getSAPARInfo.calloutSAPAR(acc.ERP_ID__c ,sc.Sales_Org__c,'00000000');
        Test.stopTest();
        
    }

}