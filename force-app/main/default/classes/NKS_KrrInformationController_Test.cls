@isTest
public class NKS_KrrInformationController_Test {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new Person__c(Name = '01048800153'));
    }

    @isTest
    static void testKrrUpdate() {
        setMockResponse();

        Test.startTest();
        NKS_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1]
            .INT_KRR_Reservation__c
        );
    }

    @isTest
    static void testKrrUpdateNull() {
        setMockResponseNull();

        Test.startTest();
        NKS_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1]
            .INT_KRR_Reservation__c
        );
    }

    private static void setMockResponse() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            LIMIT 1
        ];

        // Construct mock responses for all callouts that will be performed
        SingleRequestMock maskinPortenResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        SingleRequestMock krrResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"JA","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","epostadresse_sist_verifisert":"2020-01-14T17:57:58+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2020-01-14T17:57:58+01"}}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put('https://difiKrrExampleEndpoint.no', krrResponse);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(mockResponseByEndpoint);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
    }

    private static void setMockResponseNull() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            LIMIT 1
        ];

        // Construct mock responses for all callouts that will be performed
        SingleRequestMock maskinPortenResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        SingleRequestMock krrResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"JA","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","mobiltelefonnummer":"+4799999999"}}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put('https://difiKrrExampleEndpoint.no', krrResponse);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(mockResponseByEndpoint);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
    }
}
