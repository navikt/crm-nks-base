import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LANG from '@salesforce/i18n/lang';
import MOMENT_JS from '@salesforce/resourceUrl/moment';
import getRecords from '@salesforce/apex/NKS_TimelineController.getRecords';
import labels from './labels';

export default class NksTimeline extends LightningElement {
    @api headerIcon = 'custom:custom18';
    @api headerTitleNorwegian;
    @api headerTitleEnglish;
    @api objectApiName;
    @api recordId;
    @api timelineParentField = 'Id';
    @api parentRecordId;
    @api amountOfMonths = 3;
    @api amountOfMonthsToLoad = 3;
    @api amountOfMonthsToOpen = 2;
    @api amountOfRecords = 3;
    @api amountOfRecordsToLoad = 3;
    @api amountOfRecordsToOpen;
    @api initialQueryLimit = 5;
    @api customEmptySubtitle = '';
    @api logEvent = false;
    @api filterIsActive = false;
    @api picklistFilter1Label;
    @api picklistFilter2Label;
    @api showHideLabel;
    @api includeAmountInTitle = false;

    MAX_QUERY_LIMIT = 30; // Maximum allowed query limit to prevent performance issues
    MAX_RECORDS_PER_LOAD = 30; // Maximum records to load per "Load More" click
    data;
    deWireResult;
    allRecordsLoaded = false;
    recordPages = [];
    openAccordionSections = [];
    allSections = [];
    labels = labels;
    filterProperties;
    header;
    error = false;
    errorMsg;
    empty = false;
    loading = true;
    finishedLoading = false;
    loadingStyle = 'height:5rem;width:24rem';
    accordionsAreSet = false;
    collapsed = false;
    collapseIcon = 'utility:justify_text';
    collapseText = labels.collapse;
    masterData;
    isPicklistFiltered = false;
    filterInitialized = false;
    currentQueryLimit; // Current SOQL LIMIT (grows with Load More)

    connectedCallback() {
        this.currentQueryLimit = Math.min(this.initialQueryLimit, this.MAX_QUERY_LIMIT);
        this.loadMomentJs();
        this.initializeHeader();
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    handleRecordWire({ data, error }) {
        if (data) {
            if (this.timelineParentField === 'Id') {
                this.parentRecordId = this.recordId;
            } else {
                const fieldApiName = `${this.objectApiName}.${this.timelineParentField}`;
                this.parentRecordId = getFieldValue(data, fieldApiName);
            }
        } else if (error) {
            this.handleError('Error fetching record field', error);
        }
    }

    @wire(getRecords, {
        recordId: '$parentRecordId',
        recordLimit: '$currentQueryLimit'
    })
    handleTimelineRecords(result) {
        this.deWireResult = result;
        const { data, error } = result;
        if (data) {
            this.processTimelineData(data);
        } else if (error) {
            this.handleError('Error fetching timeline data', error);
        }
    }

    loadMomentJs() {
        loadScript(this, MOMENT_JS)
            .then(() => moment.locale(this.labels.MomentJsLanguage))
            .catch((error) => this.handleError('Error loading Moment.js', error));
    }

    initializeHeader() {
        this.header =
            LANG === 'no' && this.headerTitleNorwegian
                ? this.headerTitleNorwegian
                : LANG === 'en-US' && this.headerTitleEnglish
                  ? this.headerTitleEnglish
                  : this.labels.activities;
    }

    processTimelineData(data) {
        this.masterData = structuredClone(data.groups);
        this.recordPages = data.recordPages;

        if (this.filterIsActive) {
            this.setFilterProperties(this.masterData);
            if (this.filterInitialized) {
                this.handleFilter();
            } else {
                this.applyInitialFilter();
                this.filterInitialized = true;
            }
        } else {
            this.updateData(this.masterData);
        }

        this.setParams();
        this.setupAccordions(this.data);
        this.updateAllSections(this.data);
    }

    setParams() {
        this.loading = false;
        this.finishedLoading = true;
        this.loadingStyle = '';
        this.empty = this.data.length === 0;
    }

    updateData(groups) {
        const showCallLogs =
            !this.filterIsActive ||
            groups.some((group) => group.models.some((model) => model.record.sObjectKind === 'NKS_Call_Log__c'));
        const visiblePages = this.recordPages.filter((page) => page.sObjectType !== 'NKS_Call_Log__c' || showCallLogs);
        const pendingPages = visiblePages.filter((page) => page.hasMore);
        // Preserve chronological completeness, but only let visible record types set the boundary.
        const cutoff = Math.max(...pendingPages.map((page) => new Date(page.oldestDate).getTime()));
        const completeGroups = groups
            .map((group) => {
                const models = group.models.filter((model) => new Date(model.record.dateValueDb).getTime() >= cutoff);
                return { ...group, models, size: models.length };
            })
            .filter((group) => group.models.length > 0);

        this.allRecordsLoaded = pendingPages.length === 0 && completeGroups.length <= this.amountOfMonths;
        this.data = completeGroups.slice(0, this.amountOfMonths);
        this.empty = this.data.length === 0;
    }

    setFilterProperties(data) {
        this.filterProperties = data.flatMap(({ models }) => models.map(({ filter }) => filter));
    }

    applyInitialFilter() {
        const groups = this.masterData
            .map((group) => ({
                ...group,
                models: group.models.filter((model) => !model.filter?.shown),
                size: group.models.filter((model) => !model.filter?.shown).length
            }))
            .filter((group) => group.models.length > 0); // Remove empty groups
        this.updateData(groups);
    }

    setupAccordions(data) {
        if (this.accordionsAreSet) return;

        const maxSectionsToOpen = this.amountOfMonthsToOpen;
        for (let index = 0; index < Math.min(maxSectionsToOpen, data.length); index++) {
            const group = data[index];
            if (group?.id) {
                this.openAccordionSections.push(group.id);
            }
        }

        this.accordionsAreSet = true;
    }

    resetAccordions() {
        setTimeout(() => {
            this.openAccordionSections = [];
            this.accordionsAreSet = false;
            this.setupAccordions(this.data);
        });
    }

    // Sync allSections with the currently visible month group IDs so collapseAccordions()
    // can expand all sections by setting openAccordionSections = allSections.
    updateAllSections(data) {
        this.allSections = data.map((record) => record.id);
    }

    expandCheck = (groupIndex, itemIndex) => {
        const totalModelsBeforeGroup = this.data
            .slice(0, groupIndex)
            .reduce((total, group) => total + group.models.length, 0);

        return (
            totalModelsBeforeGroup <= this.amountOfRecordsToLoad &&
            totalModelsBeforeGroup + itemIndex < this.amountOfRecordsToOpen
        );
    };

    handleError(message, error) {
        console.error(message, error);
        this.errorMsg = error.body?.message || error.message || 'An unknown error occurred.';
        this.error = true;
    }

    loadMore() {
        this.loading = true;
        this.allRecordsLoaded = false;
        this.isPicklistFiltered = false;
        const filterTemplate = this.template.querySelector('c-timeline-filter');
        if (filterTemplate) filterTemplate.resetPicklistFilters();
        this.amountOfMonths = this.amountOfMonths + this.amountOfMonthsToLoad;
        const increment = Math.min(this.amountOfRecordsToLoad, this.MAX_RECORDS_PER_LOAD);
        this.currentQueryLimit = this.currentQueryLimit + increment;
        //this.publishAmplitudeEvent('Load more (months)');
    }

    refreshData() {
        this.error = false;
        this.loading = true;
        return refreshApex(this.deWireResult)
            .then(() => {
                this.loading = false;
            })
            .catch((error) => this.handleError('Error refreshing timeline data', error));
    }

    collapseAccordions() {
        this.openAccordionSections = this.collapsed ? this.allSections : [];
        this.collapsed = !this.collapsed;
        //this.publishAmplitudeEvent('Collapse/open accordions');
    }

    handleSectionToggle(event) {
        this.openAccordionSections = event.detail.openSections;

        if (this.openAccordionSections.length === 0) {
            this.collapseIcon = 'utility:filter';
            this.collapseText = this.labels.expand;
            this.collapsed = true;
        } else {
            this.collapseIcon = 'utility:justify_text';
            this.collapseText = this.labels.collapse;
            this.collapsed = false;
        }
        //this.publishAmplitudeEvent('Toggle expand section');
    }

    handleFilter() {
        const filterTemplate = this.template.querySelector('c-timeline-filter');
        if (!filterTemplate) {
            this.applyInitialFilter();
            return;
        }

        this.updateData(filterTemplate.filterRecords(structuredClone(this.masterData)));
        this.isPicklistFiltered = filterTemplate.isPicklistFilterActive;

        this.updateAllSections(this.data);
        this.resetAccordions();
    }

    /*publishAmplitudeEvent(eventType) {
        if (this.logEvent) {
            publishToAmplitude('Timeline', { type: eventType });
        }
    }*/

    get hasMoreDataToLoad() {
        return !this.allRecordsLoaded;
    }

    get isGrouped() {
        return this.filterIsActive;
    }

    get emptySubtitle() {
        return this.customEmptySubtitle || this.labels.emptySubtitle;
    }

    get headerClass() {
        return `slds-grid custom-container${this.empty ? '' : ' border-bottom'}`;
    }

    get recordFields() {
        if (!this.objectApiName || !this.timelineParentField) {
            return [];
        }
        return [`${this.objectApiName}.${this.timelineParentField}`];
    }
}
