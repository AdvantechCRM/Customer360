public without sharing class sc_callout_getSAPAccInfo {
    
    public class SapAccountRes{
        
        public Data Data {get;set;} 
        public String Message {get;set;} 
        public String MessageCode {get;set;} 
        public List<Error> Error  ; 
    }
    
    public class Data {
            public String AMOUNT {get;set;} 
            public String CREDIT_LIMIT {get;set;} 
            public String CREDIT_LIMIT_USED {get;set;} 
            public String CURRENCY_Z {get;set;} 
            public String CUSTOMER_CURRENCY {get;set;} 
            public String CUSTOMER_ID {get;set;} 
            public String CUSTOMER_NAME {get;set;} 
            public String TERMS {get;set;}
        	public String SALES_ID {get;set;}
        	public String TAXNUM {get;set;} 
            public String INCO1 {get;set;} 
            public String INCO2_L {get;set;} 
            public String KTOKD {get;set;} 
            public String XDELE {get;set;} 
            public String XBLCK {get;set;} 
            public String TEXT_0001 {get;set;} 
            public String KATR9 {get;set;}
        	public String Z2 {get;set;}
        	public String Z3 {get;set;} 
            public String ZCLA {get;set;} 
            public String BDATE {get;set;}
        	public String EDATE {get;set;}
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
     public static responseWrapper calloutSAPAcc(String passErpID, String passSalesOrg, String passCreditSeg,String passSalesCode) {
        system.debug('passErpID==>'+passErpID);
        system.debug('passSalesOrg==>'+passSalesOrg);
        system.debug('passCreditSeg==>'+passCreditSeg);
         
        CRMLogHandler log = new CRMLogHandler();
        responseWrapper responseJSON = new responseWrapper();
        responseJSON.isSuccess = false;
        responseJSON.Id = '';
        //String authorizationHeader;
        String sandboxName = DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName();
		Boolean isSandbox = !String.isEmpty(sandboxName);
        String endpoint;
        //if (isSandbox) {
    	//	System.debug('>>>>>>Sandbox>>>>>'+ sandboxName);
        //    endpoint = 'callout:SIS_Endpoint_CRM_Dev/ITD_ERP/GET_AccountCreditInfo';
		//} else {
    		System.debug('Production');
            endpoint = 'callout:SIS_Endpoint_CRM/ITD_ERP/GET_AccountCreditInfo';
		//}
        String erpId;
        String accOnwerId;
        String accSalesCode;
        String accScndSalesCode;
         
        Http http = new Http();
        HttpRequest request = new HttpRequest();
       
        String requestBody = '{"ERPID": "' + passErpID + '", "SALES_ORG": "' + passSalesOrg + '", "CREDIT_SGMNT": "' + passCreditSeg + '"}'; 
        //request.setHeader('APIkey', authorizationHeader);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST'); 
        request.setEndpoint(endpoint);
        request.setBody(requestBody);
         system.debug('requestBody==>'+requestBody);
        try{
            HttpResponse response = http.send(request);
            
            system.debug('response.getStatusCode()==>'+response.getStatusCode());
			system.debug('response.getBody()==>'+response.getBody());
            
            
             switch on response.getStatusCode() {
                when 200{
                    SapAccountRes getSAPAccount = (SapAccountRes)JSON.deserialize(response.getBody().replaceAll('"CURRENCY"','"CURRENCY_Z"'), SapAccountRes.class);
                    //system.debug('getSAPAccount==>'+getSAPAccount);
                    //system.debug('getSAPAccountMessage==>'+getSAPAccount.Message);
                    if(getSAPAccount.Data.SALES_ID !='00000000' || getSAPAccount.Data.CUSTOMER_CURRENCY == 'CNY'){
                    try{
                        List<Sales_Code__c> scList = [SELECT Id,Parent_RBU__c , ownerid from Sales_code__c where EXID__C =: getSAPAccount.Data.SALES_ID ];
                        String tmp;
                        if(scList.isEmpty()){
                            List<Sales_Code__c> getCurrSCList; 
                            if(getSAPAccount.Data.SALES_ID =='00000000' && getSAPAccount.Data.CUSTOMER_CURRENCY == 'CNY'){
                                tmp = 'ACN System Use';         
                            } else{
                            	getCurrSCList = [SELECT parent_RBU__c from Sales_code__c where id =: passSalesCode]; 
                                tmp = getCurrSCList[0].parent_RBU__c+' System Use'; 
                            }
                           
                            //system.debug('tmp==>'+tmp);
                            List<Account> getDefAccount = [SELECT ownerid,sales_code__c from Account where Name =: tmp] ;
                            accOnwerId = getDefAccount[0].ownerid;
                            accSalesCode = getDefAccount[0].sales_code__c;
                        }else{
                        	accOnwerId = scList[0].ownerid;
                        	accSalesCode = scList[0].Id;
                        }
                        
                    }catch(Exception e1){
                        responseJSON.message = e1.getMessage() ;
                        CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                    }
                        
                    if(getSAPAccount.Data.Z3 !='00000000' || getSAPAccount.Data.CUSTOMER_CURRENCY == 'CNY'){
                        try{
                            List<Sales_Code__c> scListScnd = [SELECT Id,Parent_RBU__c , ownerid from Sales_code__c where EXID__C =: getSAPAccount.Data.Z3 ];
                            if(!scListScnd.isEmpty()){
                                accScndSalesCode = scListScnd[0].Id;
                            }else{
                                accScndSalesCode = null;
                            }
                            
                        }catch(exception e){
                            responseJSON.message = e.getMessage() ;
                       	 	CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                        }
                        
                            
                    }
                    	//system.debug('You are in 200');
                        //system.debug('accSalesCode==>'+accSalesCode);
                        SAP_Account__c[] sapAccs = new SAP_Account__c[]{}; 
                        SAP_Account__c sapAcc = new SAP_Account__c(
                            Name = getSAPAccount.Data.CUSTOMER_NAME,
                            ERP_ID__c = getSAPAccount.Data.CUSTOMER_ID,
                            Credit_Exposure__c = decimal.valueOf(getSAPAccount.Data.AMOUNT),
                            Credit_Exposure_Currency__c = getSAPAccount.Data.CURRENCY_Z,
                            Credit_Lim_Used__c =  getSAPAccount.Data.CREDIT_LIMIT_USED + '%',
                            Credit_Limit__c = decimal.valueOf(getSAPAccount.Data.CREDIT_LIMIT) ,                
                            Credit_Segment__c = passCreditSeg ,  
                            CurrencyIsoCode = getSAPAccount.Data.CUSTOMER_CURRENCY ,
                            Payment_Terms__c =   getSAPAccount.Data.TERMS,
                            Tax_Number__c = getSAPAccount.Data.TAXNUM,
                            Incoterms__c = getSAPAccount.Data.INCO1+ ' '+ getSAPAccount.Data.INCO2_L,
                            ERP_ID_Type__c = getSAPAccount.Data.KTOKD,
                            Archiving_Flags__c = (getSAPAccount.Data.XDELE == 'X'? true:false),
                            Central_Block__c = (getSAPAccount.Data.XBLCK == 'X'? true:false),
                            Vertical__c = getSAPAccount.Data.KATR9,
                            Inside_Sales__c = getSAPAccount.Data.Z2,
                            Secondary_Sales_Code__c = accScndSalesCode,
                            CLA_Number__c = getSAPAccount.Data.ZCLA,
                            CLA_Valid_From__c = (getSAPAccount.Data.BDATE == '0000-00-00'? null:date.valueOf(getSAPAccount.Data.BDATE)),
                            CLA_Valid_To__c = (getSAPAccount.Data.EDATE == '0000-00-00'? null:date.valueOf(getSAPAccount.Data.EDATE)),
                            ownerid = accOnwerId,
                            Sales_Code__c = accSalesCode);
                        sapAccs.add(sapAcc);
                        Database.UpsertResult[] results = Database.upsert(sapAccs, SAP_Account__c.ERP_ID__c);
                        try {
                             if(results[0].isSuccess()) {
                                if(results[0].isCreated()) {
                                    System.debug(sapAccs[0].ERP_ID__c +' was created');
                                   
                                } else {
                                    System.debug(sapAccs[0].ERP_ID__c +' was updated');
                                }
                                erpId = results[0].getId();
                                System.debug('SFDC erpID===>'+results[0].getId() );
                                responseJSON.isSuccess = true;
                    			responseJSON.message = 'SAP Account Information update successfully!';
                    			responseJSON.Id = results[0].getId();
                            }
                            
                        } catch (DmlException e2) {
                            
                            responseJSON.message = e2.getMessage() ;
                            System.debug(e2.getMessage());
                            CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                        }
                    }else{
                        responseJSON.message = 'There is currently no available SAP data for ERPID '+ passErpID;
                    }
                 }when 404{
                    system.debug('You are in 404');
                    responseJSON.message = 'There is currently no available SAP data for ERPID '+ passErpID;
                     CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
                }when else{
                	responseJSON.message = 'An unexpected error occured, please contact crm.acl@advantech.com.tw';
                    CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
	            }
                
            }
            
            CRMLogHandler.writeLog(requestBody,log.className, log.methodName, response.getBody(),responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
         } catch (exception e){
            system.debug('exception==>'+e.getMessage());
            responseJSON.message = e.getMessage() ;
            CRMLogHandler.writeLog(requestBody,log.className, log.methodName, responseJSON.message,responseJSON.ID,'APEX','User',responseJSON.isSuccess,'3-Medium','');
         }
		
        return responseJSON;
    }

}