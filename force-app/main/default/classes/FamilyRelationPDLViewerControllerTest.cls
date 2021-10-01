@isTest
private class FamilyRelationPDLViewerControllerTest {
    @isTest
    private static void queryRelationsFromPDL(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = FamilyRelationPDLViewerController.queryRelationsFromPDL('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }
    @isTest
    private static void getChildrenTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<FamilyRelationPDLViewerController.Relation> l = FamilyRelationPDLViewerController.getChildren(query.execute());
        System.assertEquals(1, l.size());
    }
    @isTest
    private static void getParentsTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<FamilyRelationPDLViewerController.Relation> l = FamilyRelationPDLViewerController.getParents(query.execute());
        System.assertEquals(0, l.size());
    }
    @isTest
    private static void queryChildTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = FamilyRelationPDLViewerController.queryChild('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }
    @isTest
    private static void getMaritalPersonTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response relations = new PDL_API_QueryHelper('12106519356').execute();
        List<FamilyRelationPDLViewerController.Relation> maritalPersonList = FamilyRelationPDLViewerController.getMaritalPerson(relations);
        System.assertEquals(0, maritalPersonList.size());
    }
    @isTest
    private static void queryMaritalPerosnTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = FamilyRelationPDLViewerController.queryMaritalPerson('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }
    @isTest
    private static void isUnauthorizedTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r =  new PDL_API_QueryHelper('12106519356').execute();
        System.assertEquals(false, FamilyRelationPDLViewerController.isUnauthorized(r));
    }
    @isTest
    private static void isShieldedTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r =  new PDL_API_QueryHelper('12106519356').execute();
        System.assertEquals(false, FamilyRelationPDLViewerController.isShielded(r));
    }
}
