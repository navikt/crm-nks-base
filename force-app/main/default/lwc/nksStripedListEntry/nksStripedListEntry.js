import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class NksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;
    @api lastIndex;

    recordUrl;
    theme;

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordUrl = url;
        });
        this.getTheme();
    }

    get className() {
        let cssClass = 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem';
        if (this.index % 2 == 0) {
            cssClass += ' isEven';
        }
        if (this.index == 0) {
            cssClass += ' isFirst';
        }
        if (this.index == this.lastIndex) {
            cssClass += ' isLast';
        }
        return cssClass;
    }

    navigateToPage(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        });
    }

    getTheme() {
        if (this.record.objectName === 'LiveChatTranscript') {
            let list = this.record.name.split(' ');
            if (list[0].toLowerCase() === 'chat') {
                list.removeChild(list[0]);
            }
            this.theme = list.join(' ');
        } else if (this.record.objectName === 'Case') {
            this.theme = this.record.name;
        } else {
            this.theme = '';
            console.log('Theme is not found!');
        }
    }
}
