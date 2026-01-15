import { LightningElement , wire, track,api } from 'lwc';
import { getRecord, getFieldValue ,updateRecord } from "lightning/uiRecordApi";
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import getAccounts from '@salesforce/apex/sc_cls_getSAPInfo.getSAPAcc';
import getARs from '@salesforce/apex/sc_cls_getSAPInfo.getSAPAR';
import getOHs from '@salesforce/apex/sc_cls_getSAPInfo.getOrderHead';
import getBSList from '@salesforce/apex/sc_cls_getSAPInfo.getBSList';
import calloutSAPAcc from '@salesforce/apex/sc_callout_getSAPAccInfo.calloutSAPAcc';
import calloutSAPAR from '@salesforce/apex/sc_callout_getSAPARInfo.calloutSAPAR';
import calloutSAPOrdr from '@salesforce/apex/sc_callout_getSAPOrderInfo.calloutSAPOrder';
import getERPID from "@salesforce/schema/Account.ERP_ID__c";
import getSalesCode from "@salesforce/schema/Account.Sales_Code__c";
import getSalesOrg from "@salesforce/schema/Account.Sales_Code__r.Sales_Org__c";
import getCreditSeg from "@salesforce/schema/Account.Sales_Code__r.Credit_Segment__c";
import myModal  from 'c/sc_lwc_SapOrderDetailsExtended'; 
import bsModal  from 'c/sc_lwc_sapBSExtended'; 
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import customCSS from '@salesforce/resourceUrl/toastCss';
import TIME_ZONE from '@salesforce/i18n/timeZone';


const fields = [getERPID,getSalesOrg,getCreditSeg,getSalesCode];
const ERP_TYPE_LABELS = {
    Z001: 'Sold-to',
    Z002: 'Ship-to',
    Z003: 'Bill-to',
    Z150: 'End Customer'
};
const statusPriority = {
    'OPEN': 2,
    'PARTIAL': 1,
    'COMPLETE': 0  
};


export default class Sc_lwc_SAPComponent extends LightningElement {

    @api recordId;
    @api erpID__c;
    @api salesOrg__c;
    @api creditSeg__c;
    @api salescode__c;
    @api oh_sc__c;
    @track sapAccountList;
    @track sapArsList;
    @track sapOHList;
    @track sapBList;
    @track sapSList;
    @track arResultMsg;
    @track accResultMsg;
    @track ordrResultMsg;
    @track accapiSuccess ;
    @track arapiSuccess = false;
    @track ordrapiSuccess = false;
    @track apiResID;
    @track showSection = true;
    wireSAPData ;
    wireSAPDataAR;
    wireSAPDataOrdr;
    wireSAPBSList;
    isAccWait = true;
    isARWait = true;
    isOrdrWait = true;
    isAccInfoShown = false;
    isARInfoShown = false;
    isOrderInfoShown = false;
    isBacklogShown = false;
    isShipmentShown = false;
    @track isSModalOpen = false;
    @track isBModalOpen = false;
    @track isCSSLoaded = false; 
    @track timeZone = TIME_ZONE;  
    @track sectionName;
    @track sectionsExpanded = {
        accinfo: false,
        arinfo: false,
        odrinfo: false,
        backloginfo: false,
        shipmentinfo: false
    };
    @track bsModalColumns = [
        { label: 'SO#', fieldName: 'SO_Number__c', type: 'text',hideDefaultActions: true },
        { label: 'PO#', fieldName: 'PO_Number__c', type: 'text' ,hideDefaultActions: true},
        { label: 'Effective Date', fieldName: 'First_Date__c', type: 'text' ,hideDefaultActions: true},
        { label: 'Order Date', fieldName: 'Order_Date__c', type: 'text' ,hideDefaultActions: true},
        { label: 'Product', fieldName: 'Product_Name__c', type: 'text',hideDefaultActions: true },
        { label: 'Order QTY', fieldName: 'Order_QTY__c', type: 'text',hideDefaultActions: true },
        { label: 'Bill QTY', fieldName: 'Bill_QTY__c', type: 'text',hideDefaultActions: true },
        { label: 'Amount', fieldName: 'Item_Amount__c', type: 'number' ,typeAttributes: {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
        useGrouping: true 
    },hideDefaultActions: true},
        { label: 'Currency', fieldName: 'CurrencyIsoCode', type: 'text',hideDefaultActions: true },
        { label: 'Sales Code', fieldName: 'Sales_Code_Text__c', type: 'text',hideDefaultActions: true }
    ];

    timeOptions = {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        second: 'numeric',
        hour12: false,
        timeZone: this.timeZone,
        timeZoneName: 'shortOffset'
    }

    formatAmount(amount) {
    if (amount === null || amount === undefined) return '';
    return Number(amount).toLocaleString('en-US', { minimumFractionDigits: 2 });
}
    
    @wire(getRecord,{recordId:'$recordId',fields}) 
    account( {error, data }){
        if (data) {
            this.salesOrg__c = getFieldValue(data, getSalesOrg);
            this.erpID__c = getFieldValue(data, getERPID);
            this.creditSeg__c = getFieldValue(data, getCreditSeg);
            this.salescode__c = getFieldValue(data, getSalesCode);
          
        } else if (error) {
        }
    }

    @wire(getAccounts,{ERPID: '$erpID__c'} ) sapAccount(wireResult){
        const {data,error} = wireResult;
        this.wireSAPData = wireResult;
        if(wireResult.data){
            this.isAccWait = false;
            let accParsedData = JSON.parse(JSON.stringify(data));
            accParsedData.forEach(acc => {
                const dateTime = new Date(acc.LastModifiedDate);
                const vfrom = acc.CLA_Valid_From__c;
                const vto   = acc.CLA_Valid_To__c;
                const format = d => new Date(d).toLocaleDateString('en-CA');
                Archiving_Flags__c: acc.Archiving_Flags__c || false
                Central_Block__c: acc.Central_Block__c || false
                this.formattedDateTime = dateTime.toLocaleString(undefined, this.timeOptions);
                
                if(acc.Sales_Code__r.Type__c =='Power User'){
                    acc.Sales_Code__c = 'None';
                    
                }else{
                    acc.Sales_Code__c=acc.Sales_Code__r.Name;
                }
                if(acc.Secondary_Sales_Code__c == null){
                    acc.Secondary_Sales_Code__c = 'None';
                    
                }else{
                    acc.Secondary_Sales_Code__c = acc.Secondary_Sales_Code__r.Name;
                }
                acc.ERP_ID_Type_Label = ERP_TYPE_LABELS[acc.ERP_ID_Type__c] || acc.ERP_ID_Type__c;
                
                if (!vfrom && !vto) {
                    acc.claValidRange = 'No available CLA valid date';
                } else if (vfrom && vto) {
                    acc.claValidRange = `${format(vfrom)} to ${format(vto)}`;
                }
            });
            this.sapAccountList = accParsedData;
            if(this.sapAccountList.length >0) {
                this.isAccInfoShown = true;
            }
        }else{
            this.isAccWait = false;
        }

    }

    @wire(getARs,{ERPID: '$erpID__c'} ) sapARs(wireARResult){
        const {data,error} = wireARResult;
        var styleColor;
        this.wireSAPDataAR = wireARResult;
        if(wireARResult.data){
            this.isARWait = false;
            this.sapArsList = data.map(obj=>({ ...obj, cssClass: obj.Arrears__c > 1? 'red-color' : 'black-color',
                formattedAmount: this.formatAmount(obj.Amount__c)
             }))

            if(this.sapArsList.length>0) this.isARInfoShown = true;
        }else{
            this.isARWait = false;
        }

    }

    @wire(getOHs,{ERPID: '$erpID__c'} ) sapOH(wireOrdrResult){
        const {data,error} = wireOrdrResult;
        this.wireSAPDataOrdr = wireOrdrResult;
        if(wireOrdrResult.data){
            this.isOrdrWait = false;
            let odrParsedData = JSON.parse(JSON.stringify(data));
            odrParsedData.forEach(odr => {
                odr.sales_code__c=odr.ExID__c;
  
            });
            const soMap = new Map();
            odrParsedData.forEach(odr => {
                if (!soMap.has(odr.SO_Number__c)) {
                    soMap.set(odr.SO_Number__c, odr);
                }else {
                    const current = soMap.get(odr.SO_Number__c);
                    if ((statusPriority[odr.Status__c] || 0) > (statusPriority[current.Status__c] || 0)) {
                        soMap.set(odr.SO_Number__c, odr);
                    }
                }   
            });
            this.sapOHList = Array.from(soMap.values());

            if(this.sapOHList.length>0) this.isOrderInfoShown = true;
            
        }else{
            this.isOrdrWait = false;
        }

    }

    @wire(getBSList,{ERPID: '$erpID__c'} ) getBSList(wireBSResult){
        const {data,error} = wireBSResult;
        this.wireSAPBSList = wireBSResult;
        this.isOrdrWait = false;
        if(wireBSResult.data){
            let bsParsedData = JSON.parse(JSON.stringify(data));
            bsParsedData.forEach(odr => {
                odr.sales_code__c=odr.ExID__c;
                odr.formattedAmount = this.formatAmount(odr.Item_Amount__c);
  
            });
            const filteredBData = bsParsedData.filter(odr => 
            Number(odr.Bill_QTY__c) < Number(odr.Order_QTY__c)
            );
            const filteredSData = bsParsedData.filter(odr => 
             Number(odr.Bill_QTY__c) ===  Number(odr.Order_QTY__c)
            );
            this.sapBList = filteredBData;
            this.sapSList = filteredSData;
           
            if(this.sapBList.length>0) {
                this.isOrderInfoShown = true;
                this.isBacklogShown = true;
            }
                
            if(this.sapSList.length>0) {
                this.isOrderInfoShown = true;
                this.isShipmentShown = true;
            }
            
            
        }else{
            this.isOrdrWait = false;
        }

    }

    handleRowClick(event) {
        const clickedRowName = event.currentTarget.dataset.value;
        event.preventDefault(); 

        myModal.open({
            
            size: 'large',
            passSONum:clickedRowName,
            label: "Modal Heading" 
            
            }

          ); 
        
    }

    handleClick(){
        this.isAccWait = true;
        this.isARWait = true;
        this.isOrdrWait = true;
        this.sectionsExpanded.accinfo = true;
        this.sectionsExpanded.arinfo = true;
        this.sectionsExpanded.odrinfo = true;
        this.sectionsExpanded.backloginfo = true;
        this.sectionsExpanded.shipmentinfo = true;
        calloutSAPAcc(
            
            {   passErpID: this.erpID__c, 
                passSalesOrg: this.salesOrg__c, 
                passCreditSeg: this.creditSeg__c,
                passSalesCode: this.salescode__c })
            .then((result) => {
                this.isAccWait = false;

                this.accResultMsg = JSON.stringify(result.message).replaceAll('\"','');
                this.apiResID =  result.Id;
                if(result.isSuccess){
                    this.accapiSuccess = true;
                    
                    refreshApex(this.wireSAPData);
                    
                        calloutSAPAR(
                            {   passErpID: this.erpID__c, 
                                passSalesOrg: this.salesOrg__c,
                                passSfdcErpID : this.apiResID   }
                                )
                            .then((result) => {
                                this.isARWait = false;
                                this.arResultMsg = JSON.stringify(result.message).replaceAll('\"','');
                                if(result.isSuccess){
                                    this.arapiSuccess = true;                                    
                                    
                                }

                                refreshApex(this.wireSAPDataAR);
                                

                                calloutSAPOrdr(
                                    {   passErpID: this.erpID__c, 
                                        passSalesOrg: this.salesOrg__c,
                                        passSfdcErpID : this.apiResID})
                                    .then((result) => {
                                        this.isOrdrWait = false;
                                        this.ordrResultMsg = JSON.stringify(result.message).replaceAll('\"','');
                                        if(result.isSuccess){
                                            this.ordrapiSuccess = true;
                                            
                                        }
                                        this.ordrresultdis = this.ordrResultMsg;
                                       
                                        if(this.accapiSuccess && this.arapiSuccess && this.ordrapiSuccess){
                                            this.dispatchEvent(
                                                new ShowToastEvent({
                                                title: 'Success',
                                                message: 'All SAP Data Update Successfully!',
                                                variant: 'Success'
                                            })
                                            )
                                        }else{
                                            this.dispatchEvent(
                                                new ShowToastEvent({
                                                title: 'Success',
                                                message: this.accResultMsg+"\n"+this.arResultMsg+"\n"+this.ordrResultMsg ,
                                                variant: 'Success'
                                            })
                                            )
                                        }
                        
                                        refreshApex(this.wireSAPDataOrdr);
                                        refreshApex(this.wireSAPBSList);
                                    })
                                    .catch(error => {
                                        this.isOrdrWait = false;
                                        this.dispatchEvent(
                                        ShowToastEvent({
                                            title: 'Error',
                                            message: error,
                                            variant: 'error'
                                        }))
                                    });
                            })
                            .catch(error => {
                                this.isARWait = false;
                                this.dispatchEvent(ShowToastEvent({
                                    title: 'Error',
                                    message: error,
                                    variant: 'error'
                                }))
                            });
      
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: this.accResultMsg.replaceAll('\"',''),
                            variant: 'Success'
                        })
                        )
                        this.isARWait = false;
                        this.isOrdrWait = false;
    
                }

            })
            .catch(error => {
                this.isAccWait = false;
                this.isARWait = false;
                this.isOrdrWait = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error'
                }))
            
            }
            );

            
    }

    handleShipmentClick(){
        if (this.sapSList && this.sapSList.length > 0) {
            this.isSModalOpen = true; 
        } 
        const transferData =  {
            passSData : this.sapSList,
            isSModalOpen: this.isSModalOpen 
        }
        bsModal.open(
                transferData
              ).then((result) => {
                  //console.log("result==>"+result);
                  
              }); 

                
    }
    
    handleBacklogClick(){
        if (this.sapBList && this.sapBList.length > 0) {
            this.isBModalOpen = true; 
        }         
        const transferData =  {
            passBData : this.sapBList,
            isBModalOpen: this.isBModalOpen 
        }
        bsModal.open(
                transferData
              ).then((result) => {
                  //console.log("result==>"+result);
                  
              }); 
    }
    closeModal() {
        this.isSModalOpen = false;
        this.isBModalOpen = false;
    }
    
    renderedCallback() {

        if (this.isCSSLoaded) return;
        this.isCSSLoaded = true;
        loadStyle(this, customCSS).then(() => {
        }).catch(error => {
        });
        

    }

    toggleSection(event) {
        this.sectionName = event.target.dataset.section;
        this.sectionsExpanded[this.sectionName] = !this.sectionsExpanded[this.sectionName];
    }

    get accinfoIconName() {
        return this.sectionsExpanded['accinfo'] ? 'utility:chevrondown' : 'utility:chevronright';
    }
    
    get arIconName() {
        return this.sectionsExpanded['arinfo'] ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get odrIconName() {
        return this.sectionsExpanded['odrinfo'] ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get backlogIconName() {
        return this.sectionsExpanded['backloginfo'] ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get shipmentIconName() {
        return this.sectionsExpanded['shipmentinfo'] ? 'utility:chevrondown' : 'utility:chevronright';
    }
    

    
}