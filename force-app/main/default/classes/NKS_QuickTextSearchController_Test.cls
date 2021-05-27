@isTest
public class NKS_QuickTextSearchController_Test {
    @TestSetup
    static void makeData() {
        NKS_TestDataFactory.createQuickTexts(3);
        UTIL_TestDataFactory.createRecord(new QuickText(Name = 'Abb', nksAbbreviationKey__c = '01048800153', nksType__c = 'Abbreviation'));
    }

    @isTest
    static void testsearchRecords() {
        string text = '1';
        Test.startTest();
        List<NKS_QuickTextSearchController.QuickTextMessage> qt = NKS_QuickTextSearchController.searchRecords(text);
        Test.stopTest();

        System.assertEquals(1, qt.size());
    }
    @isTest
    static void testgetabbreviations(){
        Test.startTest();
        List<QuickText> qtList = NKS_QuickTextSearchController.getQuicktexts();
        Test.stopTest();
        System.assertEquals(qtList.size(), 1);
    }
}
