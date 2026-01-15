import { LightningElement ,api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Sc_lwc_sapShipmentExtended extends LightningModal {
    @api isSModalOpen;
    @api passSData ;
    @api isBModalOpen;
    @api passBData;

}