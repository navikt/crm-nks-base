global class NKS_ArticleArchiveCurrentScheduler extends NKS_ArticleArchiveBaseScheduler {
    public NKS_ArticleArchiveCurrentScheduler() {
        this.query = 'SELECT Id, Name, toLabel(Skills__c), NKS_News_Publish_Date__c, RecordType.DeveloperName FROM NKS_Announcement__c WHERE RecordType.DeveloperName=\'Current_In_NAV_Contact_Center\' AND NKS_News_Archive__c=TRUE AND NKS_News_Delete_Date__c=TOMORROW AND NKS_News_Status__c=\'Published\'';
        this.settingName = 'Websak_NKS_Current_Setting__mdt';
        this.journalPostType = 'Aktuelt NKS';
    }

    public NKS_ArticleArchiveCurrentScheduler(String query) {
        super(query, 'Websak_NKS_Current_Setting__mdt', 'Aktuelt NKS');
    }
}
