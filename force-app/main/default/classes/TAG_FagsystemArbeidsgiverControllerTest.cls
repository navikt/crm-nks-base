@isTest
public with sharing class TAG_FagsystemArbeidsgiverControllerTest {       
    @isTest
    static void getAccountId() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '973113631');
        insert acc;

        Test.startTest();
        String result = TAG_FagsystemerArbeidsgiverController.getAccount(acc.id);
        Test.stopTest();

        System.assertEquals(result, acc.id);
        }

        @isTest
        static void testError() {
            Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '973113631');
            insert acc;

            String wrongId = 'adhfk67h6kjs78df46';
            Exception capturedException;
    
            Test.startTest();
            try {
                String result = TAG_FagsystemerArbeidsgiverController.getAccount(wrongId);
            } catch (Exception e) {
                capturedException = e;
            }
            Test.stopTest();
    
            System.assertNotEquals(null, capturedException, 'Exception should be thrown');
            }

}