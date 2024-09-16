@isTest
public with sharing class NKS_CustomNotificationControllerTest {

    @isTest
    static void testSendNotification() {
        List<Id> userIds = new List<Id>();
        List<User> users = [SELECT Id FROM User];
        for (User user : users) {
            userIds.add(user.Id);
        }

        List<NKS_CustomNotificationController.Request> requests = new List<NKS_CustomNotificationController.Request>();
        NKS_CustomNotificationController.Request req = new NKS_CustomNotificationController.Request();
        req.userIds = userIds;
        req.notificationTypeId = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'NKS_Announcement_Custom_Notification'
            LIMIT 1
        ].Id;
        req.notificationTitle = 'Test Notification';
        req.notificationBody = 'Test Body';

        requests.add(req);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            NKS_CustomNotificationController.sendNotification(requests);
        } catch (Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  e.getMessage().length() != null; 
            Assert.areEqual(true, expectedExceptionThrown, e.getMessage()); 
        }
        Test.stopTest();

        Assert.isTrue (req.userIds.size() > 0, 'User IDs list should be populated with users.');
        Assert.isTrue (!exceptionThrown, 'No Exception should be thrown.');
        Assert.isTrue (requests.size() == 1, 'Requests list should have one request.');
    }
}