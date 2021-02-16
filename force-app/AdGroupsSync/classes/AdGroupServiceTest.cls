@IsTest
private with sharing class AdGroupServiceTest {
    
    @IsTest static void getAdGroupMembers_TestResponse() {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'NKS_API_MOCK_GET_GROUP_MEMBERS_200' LIMIT 1];
                

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', sr.Body.toString(),
        null);
        Test.setMock(HttpCalloutMock.class, httpMock);
        AdGroupService.AdGroupResponse result;
        
        AdGroupService service = new AdGroupService();

        Test.startTest();
        result = service.getAdGroupMembers('abcdef');
        Test.stopTest();
        System.assertNotEquals(null,result);
        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertNotEquals(null, result.usernames, 'Expected to get usernames');
        System.assertEquals(2, result.usernames.size(),'Expected to get two users');
        System.assertEquals('F_Z994586.E_Z994586@trygdeetaten.no', result.usernames[0], 'Expected to get F_Z994586.E_Z994586@trygdeetaten.no test user');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');
    }

    @IsTest 
    static void getAdGroupMembers_GroupNotFound() {
        SingleRequestMock httpMock = new SingleRequestMock(400, 'Bad Request', '{"field": null, "message": "Invalid object identifier \'\'{0}\'\'."}',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        AdGroupService.AdGroupResponse result;
        
        AdGroupService service = new AdGroupService();

        Test.startTest();
        result = service.getAdGroupMembers('invalidGroupId');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected to get a failure');
        System.assertEquals(null, result.usernames, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }

    @IsTest 
    static void getAdGroupMembers_EndpointNotFound() {
        SingleRequestMock httpMock = new SingleRequestMock(404, 'Not Found', '',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        AdGroupService.AdGroupResponse result;
        
        AdGroupService service = new AdGroupService();

        Test.startTest();
        result = service.getAdGroupMembers('groupId');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected to get a failure');
        System.assertEquals(null, result.usernames, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }

    @IsTest 
    static void getAdGroupMembers_InternalServerError() {
        SingleRequestMock httpMock = new SingleRequestMock(500, 'Internal Server Error', '',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        AdGroupService.AdGroupResponse result;
        
        AdGroupService service = new AdGroupService();

        Test.startTest();
        result = service.getAdGroupMembers('groupId');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected to get a failure');
        System.assertEquals(null, result.usernames, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }
}
