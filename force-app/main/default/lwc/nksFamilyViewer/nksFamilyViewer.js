import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getRelations from '@salesforce/apex/NKS_FamilyViewController.getRelations';
import nksFamilyViewerV2HTML from './nksFamilyViewerV2.html';
import nksFamilyViewerHTML from './nksFamilyViewer.html';

export default class nksFamilyViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api useNewDesign;
    @track errorMessage;
    wireFields;
    isLoaded = false;

    render() {
        return this.useNewDesign ? nksFamilyViewerV2HTML : nksFamilyViewerHTML;
    }

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ data }) {
        if (data) {
            refreshApex(this.relations).then(() => {
                this.isLoaded = true;
            });
        }
    }

    @wire(getRelations, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    relations;

    filterRelationsByType(isMarital) {
        return this.relations.data.filter((relation) => {
            const isMaritalType = relation.recordType === 'marital';
            const maritalRolesWithLessInfo = ['UGIFT', 'UOPPGITT', 'SKILT', 'SKILT_PARTNER'];
            const hasMaritalRoleWithLessInfo = maritalRolesWithLessInfo.includes(relation.role);

            return isMarital === (isMaritalType && hasMaritalRoleWithLessInfo);
        });
    }

    getRole(relation) {
        if (relation.role === 'UGIFT') {
            return 'Ugift';
        }
        if (relation.role === 'UOPPGITT') {
            return 'Uoppgitt';
        }
        if (relation.role === 'SKILT') {
            return 'Skilt';
        }
        if (relation.role === 'SKILT_PARTNER') {
            return 'Skilt partner';
        }
        return relation.role;
    }

    get divider() {
        return this.useNewDesign ? '' : 'slds-has-dividers_top-space';
    }

    get maritalRelationsWithLessInfo() {
        if (this.relations.data) {
            return this.filterRelationsByType(true).map((relation) => ({
                ...relation,
                roleLabel: this.getRole(relation)
            }));
        }
        return [];
    }

    get otherRelations() {
        if (this.relations.data) {
            return this.filterRelationsByType(false);
        }
        return [];
    }

    get isError() {
        if (!this.relations.data) {
            this.errorMessage = 'Kunne ikke hente relasjoner';
            return true;
        }
        const errorRelation = this.relations.data.find((relation) => relation.recordType === 'ERROR');

        if (errorRelation) {
            this.errorMessage = errorRelation.name ? errorRelation.name : '';
            return true;
        }
        return false;
    }
}
