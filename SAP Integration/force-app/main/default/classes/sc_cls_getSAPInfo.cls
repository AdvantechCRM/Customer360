public with sharing class sc_cls_getSAPInfo {

    @AuraEnabled(cacheable=true)
    public static List<SAP_Account__c> getSAPAcc(String ERPID) {
     
     List<SAP_Account__c> accInfo = [ Select Id,Name,ERP_ID__c,Credit_Segment__c,Sales_Code__c, Sales_Code__r.name , Sales_Code__r.type__c,Credit_Exposure__c,Credit_Exposure_Currency__c,Credit_Lim_Used__c, Credit_Limit__c, CurrencyIsoCode, Payment_Terms__c,LastModifiedDate,Credit_Available__c, Tax_Number__c, Incoterms__c, ERP_ID_Type__c, Archiving_Flags__c, Central_Block__c, Internal_Sales_Note__c, Vertical__c, Inside_Sales__c, Secondary_Sales_Code__c,Secondary_Sales_Code__r.Name, CLA_Number__c, CLA_Valid_From__c, CLA_Valid_To__c FROM SAP_Account__c WHERE ERP_ID__c =: ERPID LIMIT 1 ];
   
        return accInfo;

    }
    
     @AuraEnabled(cacheable=true)
    public static List<SAP_Account_Receivable__c> getSAPAR(String ERPID) {
     
     List<SAP_Account_Receivable__c> arInfo = [ Select Id,Amount__c,Arrears__c,Billing_No__c,Document_No__c,  Due_Date__c,Shipment_Date__c, Status__c,createddate,LastModifiedDate FROM SAP_Account_Receivable__c WHERE SAP_Account__r.ERP_ID__c =: ERPID and Status__c != 'Cleared'order by  Due_Date__c Asc limit 10 ];
     
        return arInfo;

    }
    
     @AuraEnabled(cacheable=true)
     public static List<AggregateResult> getOrderHead(String ERPID) {
     
     AggregateResult[]  OH = [ Select SO_Number__c,PO_Number__c,sales_code__c,Sales_Code__r.ExID__c,Status__c,Order_Date__c FROM SAP_Order_Tracking__c WHERE SAP_Account__r.ERP_ID__c =: ERPID group by SO_Number__c,PO_Number__c,sales_code__c,Sales_Code__r.ExID__c,Status__c,Order_Date__c order by  Order_Date__c Desc Limit 10];
     
        return OH;

    }
    
     @AuraEnabled(cacheable=true)
     public static List<SAP_Order_Tracking__c> getOrderDetail(String soNum) {
     
     List<SAP_Order_Tracking__c>  OTD = [ Select Line__c,Product_Name__c,Order_QTY__c,Net_Price__c,PO_Number__c,Pint__c,Order_Date__c,First_Date__c,Status__c,Sales_Code__c,Sales_Code__r.Name,Bill_QTY__c FROM SAP_Order_Tracking__c WHERE SO_Number__c =: soNum  order by Line__c, First_Date__c  ];
     
        return OTD;

    }


    
    @AuraEnabled(cacheable=true)
     public static List<SAP_Order_Tracking__c> getBSList(String ERPID) {
     
     List<SAP_Order_Tracking__c>  BSL = [ Select Line__c,Product_Name__c,Item_Amount__c,Order_QTY__c,Net_Price__c,SO_Number__c,PO_Number__c,Pint__c,Order_Date__c,First_Date__c,Status__c,Sales_Code__c,Sales_Code__r.Name,Bill_QTY__c,Sales_Code_Text__c,CurrencyIsoCode,Total_Amount__c FROM SAP_Order_Tracking__c WHERE SAP_Account__r.ERP_ID__c =: ERPID  order by Line__c,Order_Date__c Desc limit 100 ];
     
        return BSL;

    }
 
}