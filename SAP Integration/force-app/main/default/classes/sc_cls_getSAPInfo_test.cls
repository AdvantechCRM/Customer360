@isTest
public class sc_cls_getSAPInfo_test {
    
	@isTest static String myUnitTest() {
        
    	Account acc = sc_cls_TestDataFactory.createAccount(true);
        String ERPID = acc.ERP_ID__c;

        SAP_Account__c sacc = sc_cls_TestDataFactory.createSAPAcc(ERPID);
        List<SAP_Account_Receivable__c> sar = sc_cls_TestDataFactory.createSAPAr(ERPID,sacc.id);
        //List<Order_Tracking__c> soh = sc_cls_TestDataFactory.createSAPOT(ERPID);
        
        
        return ERPID;
	}
    
    @isTest static void testWarmTemp() {
        List<SAP_Account__c> test1 = sc_cls_getSAPInfo.getSAPAcc(myUnitTest());
        List<SAP_Account_Receivable__c> test2 = sc_cls_getSAPInfo.getSAPAR(myUnitTest());
        List<AggregateResult> test3 = sc_cls_getSAPInfo.getOrderHead(myUnitTest());
        List<SAP_Order_Tracking__c> test4 = sc_cls_getSAPInfo.getOrderDetail('YMCA0001');
        List<SAP_Order_Tracking__c> result = sc_cls_getSAPInfo.getBSList('ERP123');

    } 
    
}