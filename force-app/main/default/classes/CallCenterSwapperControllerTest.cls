@isTest
private class CallCenterSwapperControllerTest {
    private static final String DEMO_CC_NAME = 'Demo Call Center Adapter';

    @isTest
    static void testGetCallCenters() {
        Test.startTest();
        Map<String, String> callCenters = CallCenterSwapperController.getCallCenters();
        Test.stopTest();

        System.assertNotEquals(null, callCenters, 'Call centers map should not be null');
        System.assert(callCenters.containsKey(DEMO_CC_NAME), 'Should contain Demo call center');
    }

    @isTest
    static void testGetCallCentersReturnsIds() {
        CallCenter demoCC = [SELECT Id FROM CallCenter WHERE Name = :DEMO_CC_NAME LIMIT 1];

        Test.startTest();
        Map<String, String> callCenters = CallCenterSwapperController.getCallCenters();
        Test.stopTest();

        System.assertEquals(demoCC.Id, callCenters.get(DEMO_CC_NAME), 'Demo CC ID should match');
    }

    @isTest
    static void testSwapCallCenter() {
        CallCenter demoCC = [SELECT Id, Name FROM CallCenter WHERE Name = :DEMO_CC_NAME LIMIT 1];
        User currentUser = [SELECT Id, CallCenterId FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.CallCenterId = null;
        update currentUser;

        Test.startTest();
        CallCenterSwapperController.swapCallCenter(demoCC.Id);
        Test.stopTest();

        User updatedUser = [SELECT CallCenterId FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(demoCC.Id, updatedUser.CallCenterId, 'Call center should be updated to Demo');
        System.assertNotEquals(null, updatedUser.CallCenterId, 'Call center should have changed');
    }

    @isTest
    static void testGetCurrentCallCenter() {
        CallCenter demoCC = [SELECT Id FROM CallCenter WHERE Name = :DEMO_CC_NAME LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.CallCenterId = demoCC.Id;
        update currentUser;

        Test.startTest();
        String currentCallCenterId = CallCenterSwapperController.getCurrentCallCenter();
        Test.stopTest();

        System.assertEquals(demoCC.Id, currentCallCenterId, 'Should return current user call center ID');
    }

    @isTest
    static void testGetCallCenterName() {
        CallCenter demoCC = [SELECT Id, Name FROM CallCenter WHERE Name = :DEMO_CC_NAME LIMIT 1];

        Test.startTest();
        String ccName = CallCenterSwapperController.getCallCenterName(demoCC.Id);
        Test.stopTest();

        System.assertEquals(DEMO_CC_NAME, ccName, 'Should return correct call center name');
    }

    @isTest
    static void testSwapToCallCenter() {
        CallCenter demoCC = [SELECT Id FROM CallCenter WHERE Name = :DEMO_CC_NAME LIMIT 1];

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.CallCenterId = demoCC.Id;
        update currentUser;

        Test.startTest();
        CallCenterSwapperController.swapCallCenter(demoCC.Id);
        Test.stopTest();

        User updatedUser = [SELECT CallCenterId FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(demoCC.Id, updatedUser.CallCenterId, 'Call center should remain the same');
    }
}
