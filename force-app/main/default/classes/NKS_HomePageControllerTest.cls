@isTest
public with sharing class NKS_HomePageControllerTest {
    @TestSetup
    static void makeData(){
        NKS_TestDataFactory.createAnnouncements(1); 
    }

    @isTest
    static void testGetField() {
        Test.startTest();
            String info = NKS_HomePageController.getField('Tips');
        Test.stopTest();

        System.assertEquals(5, info.length());
    }
}
