@isTest
public class NKS_QuickTextSearchController_Test {
    
    @TestSetup
    static void makeData(){
        NKS_TestDataFactory.createQuickTexts(3);
    }

    @isTest
    static void testsearchRecords() {
        string text = '1'; 
        Test.startTest();
            List<NKS_QuickTextSearchController.QuickTextMessage> qt = NKS_QuickTextSearchController.searchRecords(text); 
        Test.stopTest();

        System.assertEquals(1, qt.size());
    }
}