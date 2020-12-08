@isTest
public with sharing class FamilyRelationViewerControllerTest {
    @TestSetup
    static void makeData(){
        List<Person__c> people = NKS_TestDataFactory.createPersons(3); 
        people[0].INT_FamilyRelations__c = '[{"relatertPersonsRolle":"BARN","relatertPersonsIdent":"12345678900","minRolleForPerson":"MOR"},{"relatertPersonsRolle":"BARN","relatertPersonsIdent":"12345678901","minRolleForPerson":"MOR"}]'; //mom of two children
        people[1].INT_FamilyRelations__c = '[{"relatertPersonsRolle":"MOR","relatertPersonsIdent":"12345678902","minRolleForPerson":"BARN"}]'; //child 1 
        people[2].INT_FamilyRelations__c = '[{"relatertPersonsRolle":"MOR","relatertPersonsIdent":"12345678902","minRolleForPerson":"BARN"}]'; //child 2
        update people; 
        
    }

    @isTest
    static void getRelatedPersonsForMomTest() {
        Account mom = NKS_TestDataFactory.getAccount('Test0');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest(); 
            relations = FamilyRelationViewerController.getRelatedPersons(mom.Id, 'Account'); 
        Test.stopTest(); 

        System.assertEquals(2, relations.size(), 'Number of relations ');
    }

    @isTest
    static void getRelatedPersonsForChild1Test() {
        Account child = NKS_TestDataFactory.getAccount('Test1');
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest(); 
            relations = FamilyRelationViewerController.getRelatedPersons(child.Id, 'Account'); 
        Test.stopTest(); 

        System.assertEquals(1, relations.size(), 'Number of relations ');

    }

    @isTest
    static void getRelatedPersonsForMomOnCaseTest() {
        Case c = NKS_TestDataFactory.createCase('Test0'); 
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest(); 
            relations = FamilyRelationViewerController.getRelatedPersons(c.Id, 'Case'); 
        Test.stopTest(); 

        System.assertEquals(2, relations.size(), 'Number of relations ');
    }

    //TODO: Add test for gradert 
   
    
    //TODO: Add test for under 21 
    /*@isTest
    public getRelatedPersonsUnder21Test() {
        List<FamilyRelationViewerController.Relation> relations = new List<FamilyRelationViewerController.Relation>();
        Test.startTest(); 
            relations = (FamilyRelationViewerController.Relation) FamilyRelationViewerController.getRelatedPersons(RECORDID, 'Account'); 
        Test.stopTest(); 
    }*/

}


