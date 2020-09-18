@isTest
public class NKS_QuickTextSearchController_Test {
    
    @TestSetup
    static void makeData(){
        QuickText qt = new QuickText(Name = 'Test', Message = 'Dette er en melding');
        insert qt;
    }

    @isTest
    static void testsearchRecords() {
        string text = 'Test'; 
        Test.startTest();
            List<QuickText> qt = NKS_QuickTextSearchController.searchRecords(text); 
        Test.stopTest();

        System.assertEquals(1, qt.size());
    }
}