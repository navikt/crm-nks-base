import { LightningElement, api } from 'lwc';

export default class NksPersonHenvendelse extends LightningElement {
    @api thread;

    showDetails = false;

    get showMessageList() {
        return this.hasMessageList && this.showDetails === true;
    }

    get hasMessageList() {
        return this.thread.henvendelseList && this.thread.henvendelseList.length > 0 ? true : false;
    }

    get getDate() {
        return this.thread.lastMessageTime
            ? new Date(this.thread.lastMessageTime).toLocaleDateString('no-NO', {
                  year: 'numeric',
                  month: '2-digit',
                  day: '2-digit'
              })
            : null;
    }

    onShowHide() {
        this.showDetails = !this.showDetails;
    }
}
