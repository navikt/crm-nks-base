@IsTest
private class NKS_NavUnitsControllerTest {
   
    @TestSetup
    private static void makeData(){
        NKS_TestDataFactory.createNavUnits(5);
    }

    @IsTest
    private static void testGetUnits(){
        String unitsJson=NKS_NavUnitsController.getUnits();
        List<NKS_NavUnitsController.PicklistValue> pickListValues =(List<NKS_NavUnitsController.PicklistValue>) JSON.deserialize(unitsJson, List<NKS_NavUnitsController.PicklistValue>.class);
        System.assertEquals(4, pickListValues.size());
    }
}
