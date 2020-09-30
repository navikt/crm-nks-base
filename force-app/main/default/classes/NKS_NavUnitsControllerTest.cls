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
        String unitsJson=NKS_NavUnitsController.getUnits();
        List<NKS_NavUnitsController.PicklistValue> pickListValues =(List<NKS_NavUnitsController.PicklistValue>) JSON.deserialize(unitsJson, List<NKS_NavUnitsController.PicklistValue>.class);
        System.assertEquals(4, pickListValues.size());
    }
}
