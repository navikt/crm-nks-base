@IsTest
private with sharing class AdGroupServiceTest {
    
    @IsTest static void getAdGroupMembers_TestResponse() {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'NKS_API_MOCK_GET_GROUP_MEMBERS_200' LIMIT 1];
                

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', sr.Body.toString(),
        null);
        Test.setMock(HttpCalloutMock.class, httpMock);
        AdGroupResponse result;
        
        AdGroupService service = new AdGroupService();

        Test.startTest();
        result = service.getAdGroupMembers('abcdef');
        Test.stopTest();
        System.assertNotEquals(null,result);
        System.assertNotEquals(null,result.value);
        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(2, result.value.size(),'Expected to get two users');
        System.assertEquals('F_Z994586.E_Z994586@trygdeetaten.no', result.value[0].userPrincipalName, 'Expected to get F_Z994586.E_Z994586@trygdeetaten.no test user');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');
    }
}
