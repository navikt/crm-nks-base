@isTest
public with sharing class NKS_GetUserIDsControllerTest {

    @TestSetup
    static void makeData() {
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
        
        Group testGroup = new Group(Name = 'Test Group', DeveloperName = 'Test_Group_Main', Type = 'Regular');
        insert testGroup;

        Group subgroup = new Group(Name = 'Test Subgroup', DeveloperName = 'Test_Subgroup', Type = 'Regular');
        insert subgroup;

        GroupMember gm1 = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert gm1;

        GroupMember gm2 = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = subgroup.Id);
        insert gm2;

        GroupMember gm3 = new GroupMember(GroupId = subgroup.Id, UserOrGroupId = testUser.Id);
        insert gm3;
    }

    @isTest
    static void testGetUserIdsFromGroups() {
        Group mainGroup = [SELECT Id FROM Group WHERE DeveloperName = 'Test_Group_Main' LIMIT 1];
        Group subGroup = [SELECT Id FROM Group WHERE DeveloperName = 'Test_Subgroup' LIMIT 1];
        
        List<Id> inputGroupIds = new List<Id>{mainGroup.Id};

        Test.startTest();
        List<NKS_GetUserIDsController.Result> results = NKS_GetUserIDsController.getUserIdsFromGroups(inputGroupIds);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'There should be one result returned.');
        Assert.areEqual(0, results[0].userIds.size(), 'There should be no user ID in the result.');
    }
}
