import { LightningElement, wire, api } from 'lwc';
import getDefaultAppUserCount from '@salesforce/apex/NKS_DefaultUserApplicationController.getDefaultAppUserCount';
import getUsersDefaultApp from '@salesforce/apex/NKS_DefaultUserApplicationController.getUsersDefaultApp';
import { refreshApex } from '@salesforce/apex';

export default class NksDefaultUserApplication extends LightningElement {
    appUserCounts;
    searchQuery = '';
    __searchedAppName = '';
    __error;
    showModal = false;
    wiredAppUserCountsResult;

    appsToShow = [];
    @api appNamesToShow = '';

    connectedCallback() {
        if (this.appNamesToShow !== '') {
            this.appsToShow = this.appNamesToShow.split(',').map(name => name.trim());
        }
    }

    @wire(getDefaultAppUserCount)
    wiredAppUserCounts(result) {
        this.wiredAppUserCountsResult = result;
        if (result?.data) {
            this.appUserCounts = result.data;
            this.__error = undefined;
        } else if (result?.error) {
            this.__error = result.error;
            console.error('Error retrieving app user counts:', result.error);
        }
    }

    handleSearchQueryChange(event) {
        this.searchQuery = event.target.value;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    handleSearch() {
        getUsersDefaultApp({ userIdOrUsername: this.searchQuery })
            .then(result => {
                this.__searchedAppName = result;
                this.__error = undefined;
            })
            .catch(error => {
                this.__searchedAppName = undefined;
                this.__error = error;
                console.error('Error retrieving user default app:', error);
            });
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleRefresh(event) {
        refreshApex(this.wiredAppUserCountsResult);
        event.target.blur();
    }

    get appUserCountsArray() {
        if (this.appUserCounts) {
            const apps = this.appsToShow.map(appName => ({
                appName: appName,
                userCount: this.appUserCounts[appName] ? this.appUserCounts[appName] : 0
            }));
            return apps;
        }
        return [];
    }

    get appUserCountsArrayNotEmpty() {
        return this.appUserCountsArray.length > 0;
    }

    get searchedAppName() {
        return this.__searchedAppName;
    }

    get error() {
        return JSON.stringify(this.__error);
    }
}