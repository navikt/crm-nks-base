@isTest
public with sharing class NKS_CustomNotificationControllerTest {

    @TestSetup
    static void makeData() {
        Group testGroup = new Group();
        testGroup.Name = 'testGroup';
        testGroup.DeveloperName = 'Test_Group_Main';
        insert testGroup;

        Group subgroup = new Group();
        subgroup.Name = 'testSubgroup';
        subgroup.DeveloperName = 'Test_Subgroup';
        insert subgroup;

        User testUser = new User(Id = UserInfo.getUserId());
        testUser.IsActive = true;

        List<GroupMember> testMembers = new List<groupMember>();

        GroupMember gm1 = new GroupMember();
        gm1.GroupId = testGroup.Id;
        gm1.UserOrGroupId = testUser.Id;
        insert gm1;

        GroupMember gm2 = new GroupMember();
        gm2.GroupId = testGroup.Id;
        gm2.UserOrGroupId = subgroup.Id;
        insert gm2;
    }

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

    @isTest
    static void testSendNotification() {
        List<NKS_CustomNotificationController.Request> requests = new List<NKS_CustomNotificationController.Request>();

        NKS_CustomNotificationController.Request req = new NKS_CustomNotificationController.Request();
        req.groupDeveloperName = 'Test_Group_Main';
        req.notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'NKS_Announcement_Custom_Notification' LIMIT 1].Id;
        req.notificationTitle = 'Test Notification';
        req.notificationBody = 'Test Body';

        requests.add(req);

        Test.startTest();
        NKS_CustomNotificationController.sendNotification(requests);
        Test.stopTest();

    }
}