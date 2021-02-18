import { LightningElement, api, track, wire } from 'lwc';
import getContactInformation from '@salesforce/apex/NKS_NavUnitSingleController.getContactInformation';
export default class NksNavUnit extends LightningElement {
    @api navUnit; // The nav unit
    @api contactInformation; // The contact information of the NAV Unit
    @api allSectionsOpenOnLoad = false; // If all sections should be open when the component loads
    @api numCols = 2; // Number of columns for the displayed fields
    @track activeSections = []; // The active sections on component load

    connectedCallback() {
        if ('true' === this.allSectionsOpenOnLoad || true === this.allSectionsOpenOnLoad) {
            this.activeSections = ['UNIT_SERVICES', 'CONTACT_DETAILS'];
        }
    }

    get columnWidth() {
        return 12 / this.numCols;
    }
}
