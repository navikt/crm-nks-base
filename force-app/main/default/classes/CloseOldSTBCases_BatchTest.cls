@isTest
private class CloseOldSTBCases_BatchTest {
    @isTest
    static void testBatchExecution() {
        List<Thread__c> threads = new List<Thread__c>();
        for (Integer i = 0; i < 10; i++) {
            Thread__c thread = new Thread__c(
                CRM_Thread_Type__c = 'STB',
                CRM_Latest_Message_Datetime__c = System.now().addDays(-61),
                CRM_isActive__c = true
            );
            threads.add(thread);
        }
        insert threads;

        CloseOldSTBCases_Batch batch = new CloseOldSTBCases_Batch();

        Test.startTest();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();

        List<Thread__c> updatedThreads = [SELECT Id, CRM_isActive__c, CRM_Is_Closed__c FROM Thread__c];
        for (Thread__c thread : updatedThreads) {
            Assert.areEqual(
                false,
                thread.CRM_isActive__c,
                'The CRM_isActive__c field should be false after the batch job.'
            );
        }
    }

    @isTest
    static void testBatchWithNoValidRecords() {
        List<Thread__c> threads = new List<Thread__c>();
        for (Integer i = 0; i < 5; i++) {
            Thread__c thread = new Thread__c(
                CRM_Thread_Type__c = 'STB',
                CRM_Latest_Message_Datetime__c = System.now().addDays(-30), // Threads with messages within 60 days
                CRM_isActive__c = true
            );
            threads.add(thread);
        }
        insert threads;

        CloseOldSTBCases_Batch batch = new CloseOldSTBCases_Batch();
        Test.startTest();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();

        List<Thread__c> updatedThreads = [SELECT Id, CRM_isActive__c FROM Thread__c];
        for (Thread__c thread : updatedThreads) {
            Assert.areEqual(
                true,
                thread.CRM_isActive__c,
                'The CRM_isActive__c field should be true for threads within 60 days.'
            );
        }
    }
}
