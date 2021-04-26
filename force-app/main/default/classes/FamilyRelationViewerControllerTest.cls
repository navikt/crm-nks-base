@isTest
public with sharing class FamilyRelationViewerControllerTest {
    @TestSetup
    static void makeData() {
        List<Person__c> people = NKS_TestDataFactory.createPersons(5);
        //add relations
        people[0]
            .INT_FamilyRelations__c = '[{"relatertPersonsRolle":"BARN","relatertPersonsIdent":"12345678901","minRolleForPerson":"MOR"},{"relatertPersonsRolle":"BARN","relatertPersonsIdent":"12345678902","minRolleForPerson":"MOR"},{"relatertPersonsRolle":"BARN","relatertPersonsIdent":"12345678903","minRolleForPerson":"MOR"},{"relatertPersonsRolle":"BARN","relatertPersonsIdent":"12345678904","minRolleForPerson":"MOR"}]'; //mom of two children
        people[1]
            .INT_FamilyRelations__c = '[{"relatertPersonsRolle":"MOR","relatertPersonsIdent":"12345678900","minRolleForPerson":"BARN"}]'; //child 1
        people[2]
            .INT_FamilyRelations__c = '[{"relatertPersonsRolle":"MOR","relatertPersonsIdent":"12345678900","minRolleForPerson":"BARN"}]'; //child 2
        people[3]
            .INT_FamilyRelations__c = '[{"relatertPersonsRolle":"MOR","relatertPersonsIdent":"12345678900","minRolleForPerson":"BARN"}]'; //child 3
        people[4]
            .INT_FamilyRelations__c = '[{"relatertPersonsRolle":"MOR","relatertPersonsIdent":"12345678900","minRolleForPerson":"BARN"}]'; //child 3

        //add birthdates
        people[0].INT_DateOfBirth__c = String.valueOf((Date.today().addYears(-45))); //mom
        people[1].INT_DateOfBirth__c = String.valueOf((Date.today().addYears(-15))); //child under 21
        people[2].INT_DateOfBirth__c = String.valueOf((Date.today().addYears(-20))); //child under 21
        people[3].INT_DateOfBirth__c = String.valueOf((Date.today().addYears(-25))); //child older than 21
        people[4].INT_DateOfBirth__c = String.valueOf((Date.today().addYears(-12))); //child under 21
        people[4].INT_Confidential__c = 'STRENGT_FORTROLIG';
        people[0].INT_MaritalRelation__c = '12345678901';
        people[1].INT_Sex__c = 'Kvinne';
        people[2].INT_Sex__c = 'Mann';
        update people;
    }

    @isTest
    static void getRelatedPersonsWithConfidential() {
        Account mom = NKS_TestDataFactory.getAccount('Test0');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest();
        relations = FamilyRelationViewerController.getRelatedPersons(mom.Id, 'Account');
        Test.stopTest();
        Account a = [SELECT Name FROM Account WHERE INT_PersonIdent__c = '12345678904' LIMIT 1];

        System.assertEquals(
            4,
            relations.size(),
            'Mom has 3 children under 21, and 1 over, 1 is confidential. Add 1 for marital status. 4 should be returned'
        );
        System.assertEquals('IKKE TILGJENGELIG', a.Name, 'Child is confidential. Name should be "IKKE TILGJENGELIG"');
    }

    @isTest
    static void getRelatedPersonsForMomTest() {
        Account mom = NKS_TestDataFactory.getAccount('Test0');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest();
        relations = FamilyRelationViewerController.getRelatedPersons(mom.Id, 'Account');
        Test.stopTest();
        System.assertEquals(
            4,
            relations.size(),
            'Mom has 3 children under 21, and 1 over, 1 is confidential. Add 1 for marital status. 4 should be returned'
        );
    }

    @isTest
    static void getRelatedPersonsForChildTest() {
        Account child = NKS_TestDataFactory.getAccount('Test1');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest();
        relations = FamilyRelationViewerController.getRelatedPersons(child.Id, 'Account');
        Test.stopTest();

        System.assertEquals(
            2,
            relations.size(),
            'Child has 1 parent and 0 children. Add 1 for marital status. 2 chould be returned'
        );
    }

    @isTest
    static void getRelatedPersonsForChildOver21Test() {
        Account child = NKS_TestDataFactory.getAccount('Test3');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest();
        relations = FamilyRelationViewerController.getRelatedPersons(child.Id, 'Account');
        Test.stopTest();

        System.assertEquals(
            1,
            relations.size(),
            'Child has 1 parent and 0 children. Parent should be hidden. Add 1 for marital status. 1 chould be returned'
        );
    }

    @isTest
    static void getRelatedPersonsForMomOnCaseTest() {
        Case c = NKS_TestDataFactory.createCase('Test0');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest();
        relations = FamilyRelationViewerController.getRelatedPersons(c.Id, 'Case');
        Test.stopTest();

        System.assertEquals(
            4,
            relations.size(),
            'Mom has 3 children under 21, and 1 over, 1 is confidential. Add 1 for marital status. 4 should be returned'
        );
    }
}
