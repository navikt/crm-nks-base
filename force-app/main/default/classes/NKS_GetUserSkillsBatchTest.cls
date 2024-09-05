@isTest
public with sharing class NKS_GetUserSkillsBatchTest {

    @TestSetup
    static void setupTestData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Username =  'testuser' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = profile.Id,
            IsActive = true
        );
        insert testUser;
    }

    @isTest
    static void testBatchExecution() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Set<Id> userIds = new Set<Id>{testUser.Id};

        Test.startTest();
        Database.executeBatch(new NKS_GetUserSkillsBatch(userIds), 1); 
        Test.stopTest();

        Assert.areNotEqual(null, NKS_GetUserSkillsBatch.userSkillsMap.get(testUser.Id));
    }
}