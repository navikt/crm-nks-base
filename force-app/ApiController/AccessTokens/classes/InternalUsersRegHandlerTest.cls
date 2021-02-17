@IsTest
private class InternalUsersRegHandlerTest {
    @IsTest
    private static void createUser() {
        TestDataFactory.getUsers(1, 'Standard Platform User', false, true);

        Map<String, String> attributeMap = new Map<String, String>();
        attributeMap.put('email', 'user1@nav.apextest');
        Auth.UserData userData = new Auth.UserData(
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            attributeMap
        );
        Test.startTest();
        InternalUsersRegHandler regHandler = new InternalUsersRegHandler();
        User user = regHandler.createUser(null, userData);
        Test.stopTest();
        System.assertNotEquals(null, user, 'Match one user');
        System.assertEquals(
            'user1@nav.apextest',
            user.Username,
            'username match with email address in auth user data'
        );
    }

    @IsTest
    private static void createUser_whenUserDoesNotExist() {
        TestDataFactory.getUsers(1, 'Standard Platform User', false, true);

        Map<String, String> attributeMap = new Map<String, String>();
        attributeMap.put('email', 'user2@nav.apextest');
        Auth.UserData userData = new Auth.UserData(
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            attributeMap
        );
        Test.startTest();
        InternalUsersRegHandler regHandler = new InternalUsersRegHandler();
        User user = regHandler.createUser(null, userData);
        Test.stopTest();
        System.assertEquals(null, user, 'No user found');
    }

    @IsTest
    private static void updateUser() {
        Map<String, String> attributeMap = new Map<String, String>();
        attributeMap.put('email', 'name@test.com');
        Auth.UserData userData = new Auth.UserData(
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            attributeMap
        );

        Test.startTest();
        InternalUsersRegHandler regHandler = new InternalUsersRegHandler();
        regHandler.updateUser(null, null, userData);
        Test.stopTest();
    }
}
