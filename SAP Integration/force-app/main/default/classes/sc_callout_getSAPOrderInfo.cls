public without sharing class sc_callout_getSAPOrderInfo {
    public class SapOrderRes{
        public List<Data> Data {get;set;}
    }
     
    public class Data {
        public String SD_DOC {get;set;} 
        public String ITM_NUMBER {get;set;} 
        public String MATERIAL {get;set;} 
        public String CURRENCY_Z {get;set;} // in json: CURRENCY
        public String SHORT_TEXT {get;set;} 
        public String DOC_DATE {get;set;} //Order Date
        public String REQ_QTY {get;set;} //Order Qty
        public String REQ_DATE {get;set;} //First Date
        public String PURCH_NO {get;set;} //PO#
        public String NET_PRICE {get;set;} 
        public String NET_VAL_HD {get;set;} //Total Amount
        public String NET_VALUE {get;set;} //Amount
        public String PLANT {get;set;} 
        public String SALES_ID {get;set;} 
        public String STATUS {get;set;} 
        public String BILL_QTY {get;set;} 
        public String SOLD_TO {get;set;}
        
    }
    
    public class responseWrapper
    {
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String message {get;set;}
    }

    @AuraEnabled
    public static responseWrapper calloutSAPOrder(String passErpID, String passSalesOrg,String passSfdcErpID) {
        
        //system.debug('passErpID==>'+passErpID);
        //system.debug('passSalesOrg==>'+passSalesOrg);
         
        CRMLogHandler log = new CRMLogHandler();
        responseWrapper responseJSON = new responseWrapper();
        responseJSON.isSuccess = false;
        
        String endpoint;
        endpoint = 'callout:SIS_Endpoint_CRM/ITD_ERP/GET_OrderDetail';
        
        Datetime dStart = Datetime.now();
		String startString = dStart.format('yyyy/MM/dd');
		Datetime dEnd = Datetime.now().addDays(-90);
        String endString = dEnd.format('yyyy/MM/dd');
        
        String requestBody = '{"ERPID": "' + passErpID + '", "SALES_ORG": "' + passSalesOrg + '", "DOCUMENT_DATE": "' + endString + '", "DOCUMENT_DATE_TO": "' + startString + '", "CHANGE_DATE": "x"}'; 
        // requestBody2: "CHANGE_DATE": ""
        String requestBody2 = '{"ERPID": "' + passErpID + '", "SALES_ORG": "' + passSalesOrg + '", "DOCUMENT_DATE": "' + endString + '", "DOCUMENT_DATE_TO": "' + startString + '", "CHANGE_DATE": ""}'; 
        
        HttpRequest request = createHttpRequest(endpoint, requestBody);
        HttpResponse response;
        String currentRequestBody = requestBody;

        try{
            response = new Http().send(request);
            //system.debug('response.getStatusCode() (1st attempt)==>'+response.getStatusCode());
			//system.debug('response.getBody() (1st attempt)==>'+response.getBody());

            if(response.getStatusCode() == 200) {

                return handleSuccessfulResponse(response, passSfdcErpID, log, currentRequestBody, responseJSON);
                
            } else if (response.getStatusCode() == 404) {

                responseJSON.message = 'First attempt 404. Retrying with different request body...';
                
                currentRequestBody = requestBody2; 
                request = createHttpRequest(endpoint, currentRequestBody); 
                
                response = new Http().send(request); 
                //system.debug('response.getStatusCode() (2nd attempt)==>'+response.getStatusCode());
			    //system.debug('response.getBody() (2nd attempt)==>'+response.getBody());

                if(response.getStatusCode() == 200) {

                    return handleSuccessfulResponse(response, passSfdcErpID, log, currentRequestBody, responseJSON);
                    
                } else if (response.getStatusCode() == 404) {
                    responseJSON.message = 'There is currently no available Order data for ERPID '+ passErpID;
                    CRMLogHandler.writeLog(currentRequestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                    
                } else {
                    responseJSON.message = 'An unexpected error occured on retry, please contact crm.acl@advantech.com.tw';
                    CRMLogHandler.writeLog(currentRequestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                }
                
            } else {
                responseJSON.message = 'An unexpected error occured, please contact crm.acl@advantech.com.tw';
                CRMLogHandler.writeLog(currentRequestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
            }
            
            if (response.getBody() != null) {
                 if(response.getBody().length() < 131000){
                    CRMLogHandler.writeLog(currentRequestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                }else{
                    CRMLogHandler.writeLog(currentRequestBody,log.className, log.methodName, 'Response body too large, check body size',responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                }
            }
            
            
        }catch(Exception e){
            responseJSON.message = e.getmessage();
            CRMLogHandler.writeLog(currentRequestBody,log.className, log.methodName, responseJSON.message,responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');

        }
        
        return responseJSON;
    }
    
    private static HttpRequest createHttpRequest(String endpoint, String requestBody) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST'); 
        request.setBody(requestBody);
        //system.debug('requestBody==>'+requestBody);
        return request;
    }

    private static responseWrapper handleSuccessfulResponse(HttpResponse response, String passSfdcErpID, CRMLogHandler log, String requestBody, responseWrapper responseJSON) {
        
        // 1. Deserialize and check data
        SapOrderRes getSAPOrdr = (SapOrderRes)JSON.deserialize(response.getBody().replace('"CURRENCY"','"CURRENCY_Z"'), SapOrderRes.class);
        //system.debug('getSAPOrdr==>'+getSAPOrdr);

        if(getSAPOrdr.Data == null || getSAPOrdr.Data.isEmpty()){
            responseJSON.message = 'Successfully connected but no order data returned from SAP.';
            if(response.getBody().length() < 131000){
                CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
            }else{
                CRMLogHandler.writeLog(requestBody,log.className, log.methodName, 'No order data returned.',responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
            }
            return responseJSON;
        }
        
        // 2. Collect unique SALES_ID for SOQL
        Set<String> uqSCset = new Set<String>(); 
        List<Data> clsData = getSAPOrdr.Data;
        for(Data d :clsData){ 
            uqSCset.add(d.SALES_ID); 
        } 
        //system.debug('uqSCset==>'+uqSCset);
        
        // 3. Query Sales_Code__c and map by EXID__C
        Map<String, Sales_code__c> aMap = new Map<String, Sales_code__c>();
        // Note: Using a single query with WHERE IN is more efficient than a loop of queries.
        for(Sales_code__c objSC : [SELECT Id, ownerid,Parent_rbu__c,Sector__c,Territory__c,Sales_Team__c,EXID__C from Sales_code__c where EXID__C IN :uqSCset]){
            aMap.put(objSC.EXID__C, objSC);
        }
        //system.debug('aMap==>'+aMap);
        
        // 4. Prepare SAP_Order_Tracking__c records for Upsert
        List<SAP_Order_Tracking__c> upsertOrdrList = new List<SAP_Order_Tracking__c>();
        
        for(Data objClsData: clsData){
            String externalId = objClsData.SOLD_TO+'_'+objClsData.SD_DOC+'_'+objClsData.ITM_NUMBER ;
            SAP_Order_Tracking__c ordrToUpsert = new SAP_Order_Tracking__c();
            ordrToUpsert.External_Id__c = externalId;
            ordrToUpsert.SO_Number__c = objClsData.SD_DOC;
            ordrToUpsert.Product_Name__c = objClsData.MATERIAL;
            try {
                ordrToUpsert.Order_Date__c = Date.valueOf(objClsData.DOC_DATE);
            } catch (System.TypeException e) {
                 //system.debug('Error parsing DOC_DATE: ' + objClsData.DOC_DATE + ' for SO: ' + objClsData.SD_DOC + ' Message: ' + e.getMessage());
            }
            ordrToUpsert.CurrencyIsoCode = objClsData.CURRENCY_Z;
            ordrToUpsert.Order_QTY__c = decimal.valueOf(objClsData.REQ_QTY);
            ordrToUpsert.Bill_QTY__c = decimal.valueOf(objClsData.BILL_QTY);
            
            try {
                ordrToUpsert.First_Date__c = Date.valueOf(objClsData.REQ_DATE);
            } catch (System.TypeException e) {
                //system.debug('Error parsing REQ_DATE: ' + objClsData.REQ_DATE + ' for SO: ' + objClsData.SD_DOC + ' Message: ' + e.getMessage());
            }
            
            ordrToUpsert.PO_Number__c = objClsData.PURCH_NO;
            ordrToUpsert.SAP_Account__c = passSfdcErpID;
            ordrToUpsert.Net_Price__c = decimal.valueOf(objClsData.NET_PRICE);
            ordrToUpsert.Total_Amount__c = decimal.valueOf(objClsData.NET_VAL_HD);
            ordrToUpsert.Item_Amount__c = decimal.valueOf(objClsData.NET_VALUE);
            ordrToUpsert.Line__c = objClsData.ITM_NUMBER;
            
            if (aMap.containsKey(objClsData.SALES_ID)){
                Sales_code__c scObj = aMap.get(objClsData.SALES_ID);
                ordrToUpsert.Sales_Code__c = scObj.Id;  
                ordrToUpsert.Ownerid =  scObj.ownerid;
                ordrToUpsert.RBU_Text__c =  scObj.Parent_rbu__c;
                ordrToUpsert.Sales_Team_Text__c =  scObj.Sales_Team__c;
                ordrToUpsert.Territory_Text__c =  scObj.Territory__c;
                ordrToUpsert.Sector_Text__c =  scObj.Sector__c;
                ordrToUpsert.Sales_Code_Text__c =  scObj.EXID__C;
            }
            
            ordrToUpsert.Pint__c = objClsData.PLANT;
            ordrToUpsert.Status__c = objClsData.STATUS;
            
            //system.debug('currEXID===>'+externalId);
            upsertOrdrList.add(ordrToUpsert);
            // Check if sales code was found before logging
            if(aMap.containsKey(objClsData.SALES_ID)){
                //system.debug('currSales_Code_Text__c===>'+aMap.get(objClsData.SALES_ID).EXID__C);
            } else {
               // system.debug('Sales Code not found for ID: ' + objClsData.SALES_ID);
            }
        }
        
        // 5. Upsert Records
        Database.UpsertResult[] results = Database.upsert(upsertOrdrList, SAP_Order_Tracking__c.External_Id__c, false);
        //system.debug('Database.UpsertResult[]===>'+results);
        
        responseJSON.isSuccess = true;
        responseJSON.message = 'SAP Order data update successfully!';
        
        // 6. Log successful response
        if(response.getBody().length() < 131000){
            CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
        }else{
            CRMLogHandler.writeLog(requestBody,log.className, log.methodName, 'Order data update successfully!',responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
        }
        
        return responseJSON;
    }
    
    
}