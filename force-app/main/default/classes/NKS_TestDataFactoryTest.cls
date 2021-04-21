@isTest
public class NKS_TestDataFactoryTest {
    @isTest
    static void testCreatePersons() {
        Integer beforePersons = [SELECT Id FROM Person__c].size();

        Test.StartTest();
        NKS_TestDataFactory.createPersons(1);
        Test.StopTest();

        Integer afterPersons = [SELECT Id FROM Person__c].size();

        System.assertEquals(1, afterPersons - beforePersons, 'New person should have been created');
    }

    @isTest
    static void testCreateQuickTexts() {
        Integer beforeQuickTexts = [SELECT Id FROM QuickText].size();

        Test.StartTest();
        NKS_TestDataFactory.createQuickTexts(1);
        Test.StopTest();

        Integer afterQuickTexts = [SELECT Id FROM QuickText].size();

        System.assertEquals(1, afterQuickTexts - beforeQuickTexts, 'New quicktext should have been created');
    }

    @isTest
    static void testCreateLiveChatVisitor() {
        Integer before = [SELECT Id FROM LiveChatVisitor].size();

        Test.StartTest();
        NKS_TestDataFactory.createLiveChatVisitor();
        Test.StopTest();

        Integer after = [SELECT Id FROM LiveChatVisitor].size();

        System.assertEquals(1, after - before, 'New LiveChatVisitor should have been created');
    }

    @isTest
    static void testCreateNavUnits() {
        Integer before = [SELECT Id FROM NavUnit__c].size();

        Test.StartTest();
        NKS_TestDataFactory.createNavUnits(5);
        Test.StopTest();

        Integer after = [SELECT Id FROM NavUnit__c].size();

        System.assertEquals(5, after - before, 'New NavUnit__c should have been created');
    }
}
