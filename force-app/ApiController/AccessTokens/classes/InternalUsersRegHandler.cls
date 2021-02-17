global with sharing class InternalUsersRegHandler implements Auth.RegistrationHandler {
    /* get user based on email from ad */
    global User createUser(Id portalId, Auth.UserData data) {
        String email = data.attributeMap.get('email');
        List<User> users = new UsersSelector().selectByUsername(new Set<String>{ email });
        if (users.size() == 1) {
            return users[0];
        }
        return null;
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
    }
}
