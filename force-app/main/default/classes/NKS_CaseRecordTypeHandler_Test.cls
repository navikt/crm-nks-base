@isTest
public class NKS_CaseRecordTypeHandler_Test {
    private static final Id PHONE_CASE_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('NKS_Phone_Case')
        .getRecordTypeId();

    @isTest
    static void testSetRecordType() {
        Case phoneCase = new Case(Origin = 'Phone', Subject = 'TEST PHONE');
        Case webCase = new Case(Origin = 'Web', Subject = 'TEST WEB');

        Test.startTest();
        UTIL_TestDataFactory.createRecordList(new List<Case>{ phoneCase, webCase });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Case WHERE RecordTypeId = :PHONE_CASE_TYPE] == 1);
    }
}
