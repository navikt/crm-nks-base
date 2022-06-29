@isTest
public with sharing class NKS_HomePageGroupMemberFinderTest {
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
        List<Id> ids = new List<Id>();
        Group g1 = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Subgroup'];
        Group g2 = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Group_Main'];
        ids.add(g1.Id);
        List<GroupMember> members = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :g2.Id];

        Test.startTest();
        Set<Id> res = NKS_HomePageGroupMemberFinder.getUserIdsFromGroups(ids);
        Test.stopTest();

        System.assertEquals(res.size(), 0);
        System.assertEquals(members.size(), 2);
    }

    @isTest
    static void testGetGroupMembers() {
        List<Id> ids = new List<Id>();
        Group g = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Group_Main'];
        ids.add(g.Id);
        Test.startTest();
        List<List<Id>> res = NKS_HomePageGroupMemberFinder.getGroupMembers(ids);
        Test.stopTest();

        System.assertEquals(res.size(), 1);
    }
}
