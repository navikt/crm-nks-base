@isTest
public class NKS_SecurityMeasuresControllerTest {
    @TestSetup
    static void makeData() {
        List<Person__c> persons = NKS_TestDataFactory.createPersons(1);
        NKS_TestDataFactory.createSecurityMeasures(1, persons[0]);
    }

    @isTest
    static void testGetSecurityMeasures() {
        String parentid = [SELECT Id FROM Account LIMIT 1].Id;
        String parentobject = 'Account';
        Test.startTest();
        List<NKS_SecurityMeasuresController.SecurityMeasure> sm = NKS_SecurityMeasuresController.getSecurityMeasures(
            parentid,
            '',
            parentobject
        );
        Test.stopTest();

        System.assertEquals(1, sm.size());
    }

    @isTest
    static void getSecurityMeasuresRelated() {
        String parentid = [SELECT Id FROM Account LIMIT 1].Id;

        LiveChatTranscript transcript = NKS_TestDataFactory.createLiveChatTranscripts(
            1
        )[0];
        transcript.AccountId = parentId;
        update transcript;

        String parentobject = 'Account';
        Test.startTest();
        List<NKS_SecurityMeasuresController.SecurityMeasure> sm = NKS_SecurityMeasuresController.getSecurityMeasures(
            transcript.Id,
            'AccountId',
            'LiveChatTranscript'
        );
        Test.stopTest();

        System.assertEquals(1, sm.size());
    }
}
