import  { LightningElement,api, wire, track } from 'lwc';
import getOHDs from '@salesforce/apex/sc_cls_getSAPInfo.getOrderDetail';
import LightningModal from 'lightning/modal';

export default class Sc_lwc_SapOrderDetailsExtended extends LightningModal {

    @api passSONum;
    @api sales_code__c;
    @api PONumber
    @api odrDate;
    @track sapOHDList;

    @wire(getOHDs,{soNum: '$passSONum'} ) sapOHD({data,error}){
        if(data){
            this.sapOHDList = data;
            this.sales_code__c = JSON.parse(JSON.stringify(data[0])).Sales_Code__r.Name;
            this.PONumber = JSON.parse(JSON.stringify(data[0])).PO_Number__c;
            this.odrDate = JSON.parse(JSON.stringify(data[0])).Order_Date__c;

           
            //console.log("odrParsedSC==>"+this.sales_code__c);
            //console.log("sapOHDList==>"+JSON.stringify(this.sapOHDList));
        }else{
           // console.log("error ==> "+error);
        }

    }

    
    connectedCallback() {
        //JS預設執行的fun，debug可以這樣用
        //console.log("Modal passSONum==>"+ this.passSONum)

            
    }

}