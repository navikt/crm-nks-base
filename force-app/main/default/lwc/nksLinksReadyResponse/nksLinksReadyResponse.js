import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksLinksReadyResponse extends NavigationMixin(LightningElement) {
    @api showReadyResponse;
    @api titleInput;
    @api urlInput;

    isInitiated = false;
    titleList = [];
    urlList = [];

    connectedCallback() {
        this.isInitiated = true;
        this.titleList = this.titleInput.split(',');
        this.urlList = this.urlInput.split(',');
    }

    get records() {
        let records = [];
        for (var i = 0; i < this.titleList.length; i++) {
            let record = { title: this.titleList[i], url: this.urlList[i] };
            records.push(record);
        }
        return records;
    }
}
