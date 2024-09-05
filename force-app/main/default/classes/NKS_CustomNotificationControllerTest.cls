@isTest
public with sharing class NKS_CustomNotificationControllerTest {

    /*
    @isTest
    static void testGetUserIdsFromGroups() {
        Set<Id> ids = new Set<Id>();
        Group g1 = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Subgroup'];
        Group g2 = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Group_Main'];
        ids.add(g1.Id);
        List<GroupMember> members = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :g2.Id];

        Test.startTest();
        Set<Id> res = NKS_CustomNotificationController.getUserIdsFromGroups(ids);
        Test.stopTest();

        Assert.areEqual(0, res.size());
        Assert.areEqual(2, members.size());
    }
        */

    @isTest
    static void testSendNotification() {
        List<Id> userIds = new List<Id>();
        List<User> users = [SELECT Id FROM User];
        for (User user : users ) {
            userIds.add(user.Id);
        }

        List<NKS_CustomNotificationController.Request> requests = new List<NKS_CustomNotificationController.Request>();

        NKS_CustomNotificationController.Request req = new NKS_CustomNotificationController.Request();
        req.userIds = userIds;
        req.notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'NKS_Announcement_Custom_Notification' LIMIT 1].Id;
        req.notificationTitle = 'Test Notification';
        req.notificationBody = 'Test Body';

        requests.add(req);

        Test.startTest();
        NKS_CustomNotificationController.sendNotification(requests);
        Test.stopTest();

    }
}