import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksHomePageHighlightPanelBottom extends NavigationMixin(LightningElement) {
    get links() {
        return [
            {
                title: 'Grensesnitt NKS',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/SitePages/Opplaering-Grensesnitt.aspx'
            },
            {
                title: 'Norsk-engelsk ordliste',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/SitePages/Ordliste-Norsk-Engelsk.aspx'
            },
            {
                title: 'Saker om NAV i media',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/_layouts/15/news.aspx?title=Aktuelle%20saker%20om%20NAV%20i%20media&newsSource=1&instanceId=6d6f51bb-16a5-4252-a768-c17eddb46ee5&webPartId=8c88f208-6c77-4bdb-86a0-0c47b4316588&serverRelativeUrl=%2Fsites%2Fenhet-kontaktsenter&pagesListId=2d647005-2136-4182-b05f-7b79da33b739'
            },
            {
                title: 'Sikkerhetsrutinen',
                custom: true
            },
            {
                title: 'Teknisk hjelp - IT',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/SitePages/Teknisk-hjelp---Prosjektgruppe.aspx'
            },
            {
                title: 'Video- og webinarbibliotek',
                url: 'https://navno.sharepoint.com/sites/fag-og-ytelser/SitePages/Video--og-webinarbibliotek.aspx'
            }
        ];
    }

    navigateToKnowledge() {
        this[NavigationMixin.Navigate]({
            type: 'standard__knowledgeArticlePage',
            attributes: {
                actionName: 'view',
                articleType: 'Knowledge',
                urlName: encodeURIComponent('Felles-Trussel-trakassering-og-sjikane')
            }
        });
    }
}
