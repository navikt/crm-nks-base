public with sharing class NKS_NewsPDFController {
    public string title { get; set; }
    public string author { get; set; }
    public String publishDate { get; set; }
    public string lastModifiedDate { get; set; }
    public string information { get; set; }
    public string imageURL { get; set; }

    public NKS_NewsPDFController() {
        string recordId = ApexPages.CurrentPage().getparameters().get('id');
        NKS_Announcement__c news = NKS_HomePageController.getNews(recordId);
        string userId = news.NKS_News_Author__c;

        title = news.Name;
        author = [SELECT Name FROM User WHERE Id = :userId].Name;
        publishDate = news.NKS_News_Publish_Date__c.format('dd. MMMMM yyyy, HH:mm');
        lastModifiedDate = news.LastModifiedDate.format('dd. MMMMM yyyy, HH:mm');
        information = news.NKS_Information__c;
        imageURL = news.NKS_ImageURL__c;
    }
}
