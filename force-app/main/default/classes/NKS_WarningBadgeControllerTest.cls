@isTest
public with sharing class NKS_WarningBadgeControllerTest {
    @TestSetup
    static void makeData() {
        List<Person__c> persons = NKS_TestDataFactory.createPersons(1);
    }

    @isTest
    static void testGetBadges() {
        Person__c p = [
            SELECT
                Id,
                INT_Confidential__c,
                INT_SpokenLanguageIntepreter__c,
                CRM_Account__c
            FROM Person__c
            LIMIT 1
        ];
        p.INT_SpokenLanguageIntepreter__c = 'Interpereter';
        p.INT_Confidential__c = 'FORTROLIG';
        update p;
        Test.startTest();
        List<String> badges = NKS_WarningBadgeController.getBadges(
            p.CRM_Account__c
        );
        Test.stopTest();

        System.assertEquals(
            2,
            badges.size(),
            'Number of badges returnes should be 2'
        );
    }
}
