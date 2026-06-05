@isTest
private class NKS_NewsArticlePdfGeneratorTest {
    @isTest
    static void testGetPdf() {
        NKS_Announcement__c a = new NKS_Announcement__c();
        a.Name = 'News Article';
        a.Skills__c = 'Arbeid';
        a.NKS_News_Status__c = 'Published';
        a.NKS_News_Archive__c = true;
        a.NKS_News_Publish_Date__c = Datetime.now().addDays(-1); //yesterday
        a.NKS_News_Delete_Date__c = Date.today().addDays(1); //tomorrow
        a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;
        insert a;

        Test.startTest();
        Blob pdfBlob = NKS_NewsArticlePdfGenerator.getPdf(a.Id);
        Test.stopTest();

        Assert.areNotEqual(null, pdfBlob);
    }
}
