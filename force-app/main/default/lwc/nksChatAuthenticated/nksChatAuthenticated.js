import { LightningElement } from 'lwc';
import setStatusCompleted from '@salesforce/apex/ChatAuthController.setStatusCompleted';

export default class AuthenticationCompletedHandler extends LightningElement {

    connectedCallback() {

        const chatTranscriptId = this.getUrlParamValue(window.location.href, 'ctid');

        setStatusCompleted({ chatTranscriptId: chatTranscriptId })
            .then(result => {
                console.log(result);
            })
            .catch(error => {
                console.log(error);
            });


        setTimeout(function () {
            window.close();
        }, 5000);
    }


    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

}