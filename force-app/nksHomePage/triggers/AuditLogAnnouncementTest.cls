@isTest
public with sharing class AuditLogAnnouncementTest {
    //Test setup data
    @TestSetup
    static void setupData() {
        Id NewsRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('News')
            .getRecordTypeId();
        NKS_TestDataFactory.createAnnouncements(1, NewsRecordTypeId);
    }

    // Test method to test the trigger that prevents Audit Logs being deleted
    @isTest
    static void testAuditLogAnnouncementDeletion() {
        NKS_Announcement__c a = [
            SELECT Id, Name, NKS_TypeFormula__c
            FROM NKS_Announcement__c
            WHERE NKS_TypeFormula__c = 'Nyhet'
            LIMIT 1
        ];
        NKS_Audit_Log__c al = new NKS_Audit_Log__c(Announcement__c = a.Id, User__c = UserInfo.GetUserId());
        insert al;

        Test.startTest();
        Database.DeleteResult result = Database.delete(al, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals('You cannot delete Audit Logs.', result.getErrors()[0].getMessage());
    }
}
