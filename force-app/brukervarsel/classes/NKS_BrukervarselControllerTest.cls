@IsTest
private with sharing class NKS_BrukervarselControllerTest {
    @IsTest
    static void importBrukervarselNotificationsSuccess() {
        ApiMock.setTestMock('GET_VARSEL_FROM_BRUKER_ID', 200, 'OK');
        List<NKS_BrukervarslingBestilling> result;
        Test.startTest();
        result = NKS_BrukervarselController.getBrukerVarselFromActorId('100003000120');
        Test.stopTest();

        System.assertEquals(6, result.size(), 'Excpected three items in list');
    }

    @IsTest
    static void importBrukervarselNotificationsError() {
        ApiMock.setTestMock('GET_VARSEL_FROM_BRUKER_ID', 500, 'Error');

        Test.startTest();
        try {
            NKS_BrukervarselController.getBrukerVarselFromActorId('100003000120');
        } catch (AuraHandledException ex) {
            System.assert(true, 'Correct exception');
        } catch (Exception ex) {
            System.assert(false, 'Wrong exception');
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected an error logged');
    }

    // @IsTest
    // static void importBrukervarselNotificationsSuccess() {
    //     Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(
    //         new Person__c(
    //             INT_ActorId__c = '100003000120',
    //             INT_Confidential__c = 'UGRADERT',
    //             INT_FirstName__c = 'Harry',
    //             INT_IsNavEmployee__c = true,
    //             INT_LastName__c = 'Potter'
    //         ),
    //         true
    //     );

    //     ApiMock.setTestMock('GET_VARSEL_FROM_BRUKER_ID', 200, 'OK');

    //     Test.startTest();
    //     NKS_BrukervarselController.doBrukervarselSynch(p.Id);
    //     Test.stopTest();

    //     System.assertEquals(4, [SELECT Id FROM UserNotification__c].size(), 'Excpected three records');
    // }

    // @IsTest
    // static void importBrukervarselNotificationsError() {
    //     Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(
    //         new Person__c(
    //             INT_ActorId__c = '100003000120',
    //             INT_Confidential__c = 'UGRADERT',
    //             INT_FirstName__c = 'Harry',
    //             INT_IsNavEmployee__c = true,
    //             INT_LastName__c = 'Potter'
    //         ),
    //         true
    //     );

    //     ApiMock.setTestMock('GET_VARSEL_FROM_BRUKER_ID', 500, 'Error');

    //     Test.startTest();
    //     try {
    //         NKS_BrukervarselController.doBrukervarselSynch(p.Id);
    //     } catch (AuraHandledException ex) {
    //         System.assert(true, 'Correct exception');
    //     } catch (Exception ex) {
    //         System.assert(false, 'Wrong exception');
    //     }
    //     Test.stopTest();

    //     System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected an error logged');
    // }
}
