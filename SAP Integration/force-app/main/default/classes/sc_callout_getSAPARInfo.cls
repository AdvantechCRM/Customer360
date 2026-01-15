public without sharing class sc_callout_getSAPARInfo {
    public class SapARRes{
               
        public String Message {get;set;} 
        public String MessageCode {get;set;} 
        public List<Data> Data {get;set;}
        public List<Error> Error {get;set;} 
    }
     
    public class Data {
        public String BILLING {get;set;} 
        public String COMP_CODE {get;set;} 
        public String CUSTOMER {get;set;} 
        public String CURRENCY_Z {get;set;} // in json: CURRENCY
        public String DOC_NO {get;set;} 
        public String AMOUNT {get;set;} 
        public String BILLING_DATE {get;set;} 
        public String DUEDATE {get;set;} 
        public String OVDUE_DAYS {get;set;} 
        public String STATUS {get;set;} 
    }

    public class Error{
        
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
    public static responseWrapper calloutSAPAR(String passErpID, String passSalesOrg,String passSfdcErpID) {
        
        system.debug('passErpID==>'+passErpID);
        system.debug('passSalesOrg==>'+passSalesOrg);
         
        CRMLogHandler log = new CRMLogHandler();
        responseWrapper responseJSON = new responseWrapper();
        responseJSON.isSuccess = false;
        //String authorizationHeader;
        String sandboxName = DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName();
		Boolean isSandbox = !String.isEmpty(sandboxName);
        String endpoint;
        //if (isSandbox) {
    	//	System.debug('>>>>>>Sandbox>>>>>'+ sandboxName);
        //    endpoint = 'callout:SIS_Endpoint_CRM_Dev/ITD_ERP/GET_AccountReceivable';
		//} else {
    		System.debug('Production');
            endpoint = 'callout:SIS_Endpoint_CRM/ITD_ERP/GET_AccountReceivable'; 
		//}
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);

        String requestBody = '{"ERPID": "' + passErpID + '", "SALES_ORG": "' + passSalesOrg + '"}'; 
        //request.setHeader('APIkey', authorizationHeader);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST'); 
        request.setBody(requestBody);
        system.debug('requestBody==>'+requestBody);
        
        try{
            HttpResponse response = http.send(request);
             
            system.debug('response.getStatusCode()==>'+response.getStatusCode());
			system.debug('response.getBody()==>'+response.getBody());
            
            switch on response.getStatusCode() {
                
                when 200{
                    try{
                        List<SAP_Account_Receivable__c> clearedARInfo = [ Select Id, Status__c FROM SAP_Account_Receivable__c WHERE SAP_Account__c =: passSfdcErpID and Status__c != 'Cleared'];
                   
                        if(clearedARInfo.size()>0){
                        List<SAP_Account_Receivable__c> updateArList = new List<SAP_Account_Receivable__c>();
                   
                        for(SAP_Account_Receivable__c ar:clearedARInfo){
                            SAP_Account_Receivable__c arToupdate = new SAP_Account_Receivable__c();
                            arToupdate.Id = ar.Id;
                            arToupdate.Status__c = 'Cleared';
                            updateArList.add(arToupdate);
                        }
                    
                        update updateArList;
                        }
                
               		}catch(Exception e1){
                
                    	system.debug('responseJSON.message  e1===> error!!');
                        CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                 
               		}            
               		SapARRes getSAPAR = (SapARRes)JSON.deserialize(response.getBody().replace('"CURRENCY"','"CURRENCY_Z"'), SapARRes.class);
                    system.debug('getSAPAR==>'+getSAPAR);
                              
                    List<Data> clsData = getSAPAR.Data;
                    system.debug('clsData==>'+clsData);
                    //Map<String, Account_Receivable__c> arMap = new Map<String, Account_Receivable__c>();
                    
                    List<SAP_Account_Receivable__c> upsertArList = new List<SAP_Account_Receivable__c>();
                    
                    for(Data objClsData: clsData){
                        if(objClsData.Billing != ''|| objClsData.DOC_NO != ''){
                            String externalId = (objClsData.Billing == '')? objClsData.CUSTOMER+'_'+objClsData.DOC_NO : objClsData.CUSTOMER+'_'+objClsData.Billing ;
                            SAP_Account_Receivable__c arToUpsert = new SAP_Account_Receivable__c();
                                arToUpsert.External_Id__c = externalId;
                                arToUpsert.Billing_No__c =  objClsData.Billing;
                            	arToUpsert.Document_No__c =  objClsData.DOC_NO;
                                arToUpsert.Amount__c = decimal.valueOf(objClsData.AMOUNT);
                                arToUpsert.Arrears__c = objClsData.OVDUE_DAYS;
                                arToUpsert.CurrencyIsoCode = objClsData.CURRENCY_Z;
                                arToUpsert.Due_Date__c = date.valueOf(objClsData.DUEDATE);
                                arToUpsert.SAP_Account__c = passSfdcErpID; 
                                arToUpsert.Shipment_Date__c = date.valueOf(objClsData.BILLING_DATE);
                                arToUpsert.Status__c = objClsData.STATUS;

                            system.debug('currEXID===>'+externalId);
                            upsertArList.add(arToUpsert);
                            
                        }
                    }
                    Database.UpsertResult[] results = Database.upsert(upsertArList, SAP_Account_Receivable__c.External_Id__c, false);
                    system.debug('Database.UpsertResult[]===>'+results);
                    
                    responseJSON.isSuccess = true;
                    responseJSON.message = 'SAP AR data update successfully!';
                    CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                }when 404{
                    responseJSON.message = 'There is currently no available AR data for ERPID '+ passErpID;
                    CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                }when else{
                	responseJSON.message = 'An unexpected error occured, please contact crm.acl@advantech.com.tw';
                    CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
	            }
            }
            
        }catch(Exception e){
            
            responseJSON.message = String.valueOf(e.getmessage());
            CRMLogHandler.writeLog(requestBody,log.className, log.methodName, responseJSON.message,responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
        }

        return responseJSON;
    }
    
}