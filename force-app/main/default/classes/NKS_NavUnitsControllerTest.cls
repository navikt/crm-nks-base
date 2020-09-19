@IsTest
private class NKS_NavUnitsControllerTest {
   
    @TestSetup
    private static void makeData(){
        List<NavUnit__c> units=new List<NavUnit__c>();
        for(Integer i=1;i<=5;i++){
            units.add(new NavUnit__c(Name='Unit ' + i, CRM_QueueId__c='00G1X000003htJh'));
        }
        units[0].CRM_QueueId__c=null;
        insert units;
    }

    @IsTest
    private static void testGetUnits(){
        String units=NKS_NavUnitsController.getUnits();
        System.assertEquals(4, units.length());
    }
}
