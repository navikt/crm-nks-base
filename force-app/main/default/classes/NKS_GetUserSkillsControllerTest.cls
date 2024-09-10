@isTest
public with sharing class NKS_GetUserSkillsControllerTest {

    @TestSetup
    static void setupTestData() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name LIKE 'Standard User'
            LIMIT 1
        ];

        User user1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Alias = 'tuser1',
            Username = 'testuser1' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser1@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = profile.Id,
            IsActive = true
        );

        User user2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Alias = 'tuser2',
            Username = 'testuser2' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser2@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = profile.Id,
            IsActive = true
        );
        
        insert new List<User>{user1, user2};
    }

    @isTest
    static void testGetUsersToNotify_WithMatchingSkills() {
        User user1 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User1'
            LIMIT 1
        ];
        User user2 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User2'
            LIMIT 1
        ];
        List<User> users = new List<User>{user1, user2};

        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user1.Id, new Set<String>{'Arbeid', 'Helse'});
        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user2.Id, new Set<String>{'Familie'});

        NKS_GetUserSkillsController.Request request = new NKS_GetUserSkillsController.Request();
        request.userIds = new List<Id>{users[0].Id, users[1].Id};
        request.newsSkills = 'Arbeid;Familie';

        Test.startTest();
        List<NKS_GetUserSkillsController.Result> results = NKS_GetUserSkillsController.getUsersToNotify(new List<NKS_GetUserSkillsController.Request>{request});
        Test.stopTest();

        Assert.AreEqual(1, results.size(), 'There should be one result returned.');
        Assert.AreEqual(2, results[0].userIds.size(), 'Both users should be notified because they have matching skills.');
        Assert.isTrue(results[0].userIds.contains(users[0].Id), 'User1 should be in the notification list.');
        Assert.isTrue(results[0].userIds.contains(users[1].Id), 'User2 should be in the notification list.');
    }

    @isTest
    static void testGetUsersToNotify_WithNoMatchingSkills() {
        User user1 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User1'
            LIMIT 1
        ];
        User user2 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User2'
            LIMIT 1
        ];
        List<User> users = new List<User>{user1, user2};

        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user1.Id, new Set<String>{'Arbeid', 'Helse'});
        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user2.Id, new Set<String>{'Familie'});

        NKS_GetUserSkillsController.Request request = new NKS_GetUserSkillsController.Request();
        request.userIds = new List<Id>{users[0].Id, users[1].Id};
        request.newsSkills = 'Pensjon';

        Test.startTest();
        List<NKS_GetUserSkillsController.Result> results = NKS_GetUserSkillsController.getUsersToNotify(new List<NKS_GetUserSkillsController.Request>{request});
        Test.stopTest();

        Assert.AreEqual(1, results.size(), 'There should be one result returned.');
        Assert.AreEqual(0, results[0].userIds.size(), 'No users should be notified because there are no matching skills.');
    }

    @isTest
    static void testGetUsersToNotify_WithBlankNewsSkills() {
        User user1 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User1'
            LIMIT 1
        ];
        User user2 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User2'
            LIMIT 1
        ];
        List<User> users = new List<User>{user1, user2};

        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user1.Id, new Set<String>{'Arbeid', 'Helse'});
        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user2.Id, new Set<String>{'Familie'});

        NKS_GetUserSkillsController.Request request = new NKS_GetUserSkillsController.Request();
        request.userIds = new List<Id>{users[0].Id, users[1].Id};
        request.newsSkills = '';

        Test.startTest();
        List<NKS_GetUserSkillsController.Result> results = NKS_GetUserSkillsController.getUsersToNotify(new List<NKS_GetUserSkillsController.Request>{request});
        Test.stopTest();

        Assert.AreEqual(1, results.size(), 'There should be one result returned.');
        Assert.AreEqual(2, results[0].userIds.size(), 'All users should be notified since skills are blank.');
        Assert.isTrue(results[0].userIds.contains(users[0].Id), 'User1 should be in the notification list.');
        Assert.isTrue(results[0].userIds.contains(users[1].Id), 'User2 should be in the notification list.');
    }

    @isTest
    static void testGetUsersToNotify_WithBlankUseSkills() {
        User user1 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User1'
            LIMIT 1
        ];
        User user2 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User2'
            LIMIT 1
        ];
        List<User> users = new List<User>{user1, user2};

        NKS_GetUserSkillsController.cachedUserSkillsMap.put(user2.Id, new Set<String>{'Familie'});

        NKS_GetUserSkillsController.Request request = new NKS_GetUserSkillsController.Request();
        request.userIds = new List<Id>{users[0].Id, users[1].Id};
        request.newsSkills = 'Sosiale tjenester';

        Test.startTest();
        List<NKS_GetUserSkillsController.Result> results = NKS_GetUserSkillsController.getUsersToNotify(new List<NKS_GetUserSkillsController.Request>{request});
        Test.stopTest();

        Assert.AreEqual(1, results.size(), 'There should be one result returned.');
        Assert.AreEqual(1, results[0].userIds.size(), 'Only User1 should be notified since she has no skills.');
        Assert.isTrue(results[0].userIds.contains(users[0].Id), 'User1 should be in the notification list.');
        Assert.isFalse(results[0].userIds.contains(users[1].Id), 'User2 should not be in the notification list.');
    }

    @isTest
    public static void testInitializeUserSkillsMap() {
        User user1 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User1'
            LIMIT 1
        ];
        User user2 = [
            SELECT Id
            FROM User
            WHERE LastName = 'User2'
            LIMIT 1
        ];
        Set<Id> userIds = new Set<Id>{user1.Id, user2.Id};

        Test.startTest();
        NKS_GetUserSkillsController.initializeUserSkillsMap(userIds);
        Test.stopTest();

        Assert.AreEqual(2, NKS_GetUserSkillsController.cachedUserSkillsMap.size(), 'The user skills map should have two users.');
        Assert.isTrue(NKS_GetUserSkillsController.cachedUserSkillsMap.keySet().containsAll(userIds), 'The user skills map should contain User1 and User2.');
    }
}