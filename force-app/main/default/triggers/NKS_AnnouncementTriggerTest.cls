@isTest
public with sharing class NKS_AnnouncementTriggerTest {
    @TestSetup
    static void setupData() {
        Id NewsRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('News')
            .getRecordTypeId();
        NKS_TestDataFactory.createAnnouncements(1, NewsRecordTypeId);
    }

    @isTest
    static void testAnnouncementTrigger() {
        NKS_Announcement__c a = [
            SELECT Id, Name, NKS_TypeFormula__c
            FROM NKS_Announcement__c
            WHERE NKS_TypeFormula__c = 'Nyhet'
            LIMIT 1
        ];

        Test.startTest();
        Database.DeleteResult result = Database.delete(a, false);
        Test.stopTest();

        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals('Du kan ikke slette nyhetsartikler.', result.getErrors()[0].getMessage());
    }
}
