@isTest
public with sharing class NKS_CustomNotificationBatchTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> users = new List<User>();
        for (Integer i = 0; i < 5; i++) {
            User u = new User(
                LastName = 'TestUser' + i,
                Alias = 'tuser' + i,
                Email = 'testuser' + i + '@example.com',
                Username = 'testuser' + i + '@example.com' + System.currentTimeMillis(),
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            users.add(u);
        }
        insert users;

    }

    @isTest
    static void testBatchExecution() {
        List<User> testUsers = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
        List<Id> userIds = new List<Id>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }

        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'NKS_Announcement_Custom_Notification' LIMIT 1];
        Id notificationTypeId = notificationType.Id;

        NKS_CustomNotificationBatch batch = new NKS_CustomNotificationBatch(
            userIds,
            notificationTypeId,
            'Test Notification Title',
            'Test Notification Body',
            null,  
            '{"type": "standard__namedPage","attributes": {"pageName": "home","actionName": "view"}}'
        );

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        Assert.areEqual(1, jobs.size(), 'Batch job should have been enqueued');

    }
}
