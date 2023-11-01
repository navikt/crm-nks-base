import { LightningElement, api, track } from 'lwc';

export default class NksSurvey extends LightningElement {
    @track emojis = [
        {
            icon: 'utility:like',
            label: 'like',
            class: ''
        },
        {
            icon: 'utility:dislike',
            label: 'dislike',
            class: ''
        }
        //add more icons if you need
    ];

    show = true;

    /**
     * Note: All functions are for test
     */
    handleCloseClick() {
        this.show = false;
    }

    handleEmojiClick(event) {
        console.log(event.target.dataset.id);
    }
}
