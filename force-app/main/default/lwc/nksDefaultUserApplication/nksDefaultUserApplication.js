import { LightningElement, wire } from 'lwc';
import getDefaultAppUserCount from '@salesforce/apex/NKS_DefaultUserApplicationController.getDefaultAppUserCount';
import getUsersDefaultApp from '@salesforce/apex/NKS_DefaultUserApplicationController.getUsersDefaultApp';

export default class NksDefaultUserApplication extends LightningElement {
    appUserCounts;
    searchQuery = '';
    __searchedAppName = '';
    error;
    showModal = false;

    // TODO: Add filter for what apps to show in component
    @wire(getDefaultAppUserCount)
    wiredAppUserCounts({ error, data }) {
        if (data) {
            this.appUserCounts = data;
        } else if (error) {
            this.error = error;
            console.error('Error retrieving app user counts:', error);
        }
    }

    handleSearchQueryChange(event) {
        this.searchQuery = event.target.value;
    }

    handleSearch() {
        if (this.searchQuery.toLowerCase() === 'raptor') {
            this.showModal = true;
            return;
        }
        getUsersDefaultApp({ userIdOrUsername: this.searchQuery })
            .then(result => {
                this.__searchedAppName = result;
            })
            .catch(error => {
                this.error = error;
                console.error('Error retrieving user default app:', error);
            });
    }

    handleCloseModal() {
        this.showModal = false;
    }

    get appUserCountsArray() {
        if (this.appUserCounts) {
            return Object.keys(this.appUserCounts).map(key => ({
                appName: key,
                userCount: this.appUserCounts[key]
            }));
        }
        return [];
    }

    get appUserCountsArrayNotEmpty() {
        return this.appUserCountsArray.length > 0;
    }

    get searchedAppName() {
        return this.__searchedAppName;
    }
}