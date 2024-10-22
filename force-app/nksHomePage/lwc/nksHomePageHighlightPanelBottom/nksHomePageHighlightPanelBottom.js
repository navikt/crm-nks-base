import { LightningElement } from 'lwc';
export default class NksHomePageHighlightPanelBottom extends LightningElement {
    get links() {
        return [
            {
                title: 'Norsk-engelsk ordliste',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/SitePages/Ordliste-Norsk-Engelsk.aspx'
            },
            {
                title: 'Kontaktsenterportalen',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/'
            },
            {
                title: 'Teknisk hjelp - IT',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/SitePages/Teknisk-hjelp---Prosjektgruppe.aspx'
            }
        ];
    }
}
