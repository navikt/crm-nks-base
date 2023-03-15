@isTest
public with sharing class NKS_HomePageNotifyOperationalUpdatesTest {
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
        Set<Id> res = NKS_HomePageNotifyOperationalUpdates.getUserIdsFromGroups(ids);
        Test.stopTest();

        System.assertEquals(0, res.size());
        System.assertEquals(2, members.size());
    }

    @istest
    static void testGetGroupMembers() {
        Set<Id> ids = new Set<Id>();
        Group g = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Group_Main'];
        ids.add(g.Id);

        Test.startTest();
        Set<Id> res = NKS_HomePageNotifyOperationalUpdates.getUserIdsFromGroups(ids);
        Test.stopTest();

        System.assertEquals(0, res.size());
    }

    @istest
    static void testNotifyUser() {
        Set<String> ids = new Set<String>();
        Group g = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Group_Main'];
        ids.add(g.Id);
        String testMessage = 'Test Message';
        Boolean throwsException = false;

        Test.startTest();
        try {
            NKS_HomePageNotifyOperationalUpdates.notifyUsers(ids, testMessage);
        } catch (Exception ex) {
            throwsException = true;
        }
        Test.stopTest();

        System.assertEquals(false, throwsException);
    }

    @istest
    static void testSendNotification() {
        Set<Id> ids = new Set<Id>();
        Group g = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Test_Group_Main'];
        ids.add(g.Id);
        List<String> strList = new List<String>();
        String testMessage = 'Test Message';
        strList.add(testMessage);
        Boolean throwsException = false;

        Test.startTest();
        Set<Id> IDSet = NKS_HomePageNotifyOperationalUpdates.getUserIdsFromGroups(ids);
        try {
            NKS_HomePageNotifyOperationalUpdates.sendNotification(strList);
        } catch (Exception ex) {
            throwsException = true;
        }
        Test.stopTest();

        System.assertNotEquals(null, IDSet);
        System.assert(IDSet.size() < 500);
        System.assertEquals(false, throwsException);
    }
}
