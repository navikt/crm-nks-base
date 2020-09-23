@IsTest
private class NKS_NavUnitsControllerTest {
   
    @TestSetup
    private static void makeData(){
        NKS_TestDataFactory.createNavUnits(5);
    }

    @IsTest
    private static void testGetUnits(){
        String units=NKS_NavUnitsController.getUnits();
        System.assertEquals(4, units.length());
        //TODO: fix test. Feiler fordi units.length er lengde av string, ikke antall records
    }
}
