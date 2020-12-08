import { LightningElement, api, track } from 'lwc';

export default class NksNavUnitOpeningHours extends LightningElement {
    @api title;
    @track openingHours = [];
    columns = ['Dag', 'Åpent', 'Åpningstid', 'Kommentar'];

    _norgOpeningHours;
    _viewWeekDays = false;

    connectedCallback() {
        this.setOpeningHours();
    }

    @api
    set viewWeekDays(value) {
        this._viewWeekDays = ('true' == value);
    }

    get viewWeekDays() {
        return this._viewWeekDays;
    }

    @api
    set norgOpeningHours(value) {
        this._norgOpeningHours = value ? value : [];
    }

    get norgOpeningHours() {
        return this._norgOpeningHours;
    }

    get hasOpeningHours() {
        return this.openingHours && 0 < this.openingHours.length;
    }

    setOpeningHours() {

        let formatedOpeningHours = [];
        this._norgOpeningHours.forEach(norgOpeningHour => {
            if ((true === this._viewWeekDays && null == norgOpeningHour.dag) || (false === this._viewWeekDays && null == norgOpeningHour.dato)) {
                return;
            }

            let weekDay = {};

            let fra = this.cleanStringValue(norgOpeningHour.fra);
            let til = this.cleanStringValue(norgOpeningHour.til);

            weekDay.id = norgOpeningHour.id;
            weekDay.openingHours = (fra + til) ? fra + ' - ' + til : '';
            weekDay.status = norgOpeningHour.stengt ? 'Stengt' : 'Åpent';
            weekDay.comments = this.cleanStringValue(norgOpeningHour.kommentar);

            weekDay.day = norgOpeningHour.dag ? this.capitalize(norgOpeningHour.dag) : norgOpeningHour.dato;
            switch (norgOpeningHour.dag) {
                case 'MANDAG':
                    weekDay.dayOfWeek = 1;
                    break;
                case 'TIRSDAG':
                    weekDay.dayOfWeek = 2;
                    break;
                case 'ONSDAG':
                    weekDay.dayOfWeek = 3;
                    break;
                case 'TORSDAG':
                    weekDay.dayOfWeek = 4;
                    break;
                case 'FREDAG':
                    weekDay.dayOfWeek = 5;
                    break;
                case 'LØRDAG':
                    weekDay.dayOfWeek = 6;
                    break;
                case 'SØNDAG':
                    weekDay.dayOfWeek = 7;
                    break;
                default:
                    weekDay.dayOfWeek = -1;
                    break;
            }

            formatedOpeningHours.push(weekDay);

        });

        formatedOpeningHours.sort((a, b) => a.dayOfWeek - b.dayOfWeek);

        if (false === this._viewWeekDays) {
            formatedOpeningHours.sort((a, b) => a.date < b.date);
        }

        this.openingHours = formatedOpeningHours;
    }

    cleanStringValue(value) {
        return value ? value : '';
    }

    capitalize(value) {
        return value.charAt(0).toUpperCase() + value.slice(1).toLowerCase();
    }
}