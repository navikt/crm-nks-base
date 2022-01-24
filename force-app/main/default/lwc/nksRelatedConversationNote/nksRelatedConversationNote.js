import { api, LightningElement, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/NKS_RelatedListController.getRelatedList';
import { NavigationMixin } from 'lightning/navigation';

export default class NksRelatedConversationNote extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    listTitle = 'Relaterte referat';
    iconName = 'utility:archive';
    relatedObjectApiName = 'Conversation_Note__c';
    relationField = 'CRM_Henvendelse_BehandlingskjedeId__c';
    parentRelationField = 'CRM_Henvendelse_BehandlingskjedeId__c';
    columnLabels =
        'CRM_Timeline_User__c, CRM_Theme__c, CRM_Is_Read_Formula__c, CRM_Conversation_Note__c, CRM_Journal_Status_Formula__c';
    filterConditions = '';
    relatedRecords;
    extraFields = 'CRM_Henvendelse_BehandlingskjedeId__c, CRM_Henvendelse_BehandlingsId__c';

    behandlingskjedeId;
    behandlingsId;
    dataFetched = false;
    masterUrl;

    connectedCallback() {
        this.getList();
    }

    _master = null;

    get isMaster() {
        return (
            this._master ??
            (this.trustworthyData && this.relatedRecords && this.relatedRecords.length > 0 && !this.isDetail)
        );
    }

    set isMaster(value) {
        this._master = value;
    }

    _detail = null;

    get isDetail() {
        return this._detail ?? (this.trustworthyData && this.behandlingsId != this.behandlingskjedeId);
    }

    set isDetail(value) {
        this._detail = value;
    }

    get trustworthyData() {
        return this.dataFetched && this.behandlingsId != null && this.behandlingskjedeId != null;
    }

    get masterRecordId() {
        const master = this.relatedRecords.find(
            (record) =>
                record.CRM_Henvendelse_BehandlingsId__c == record.CRM_Henvendelse_BehandlingskjedeId__c &&
                record.CRM_Henvendelse_BehandlingsId__c != null
        );
        if (!master) this.isMaster = false;
        return master?.Id;
    }

    //Calls apex to retrieve related records
    getList() {
        getRelatedList({
            extraFields: this.extraFields,
            parentId: this.recordId,
            objectApiName: this.relatedObjectApiName,
            relationField: this.relationField,
            parentRelationField: this.parentRelationField,
            parentObjectApiName: this.objectApiName,
            filterConditions: this.filterConditions
        })
            .then((data) => {
                const recordIndex = data.findIndex((record) => record.Id == this.recordId);
                const ownRecord = data[recordIndex];
                data.splice(recordIndex, 1);
                this.behandlingskjedeId = ownRecord.CRM_Henvendelse_BehandlingskjedeId__c;
                this.behandlingsId = ownRecord.CRM_Henvendelse_BehandlingsId__c;
                this.relatedRecords = data && data.length > 0 ? data : null;
                this.dataFetched = true;
            })
            .catch((error) => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }

    get icon() {
        return this.iconName ?? null;
    }

    navigateToMaster(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.masterRecordId,
                objectApiName: this.relatedObjectApiName,
                actionName: 'view'
            }
        });
    }
}
