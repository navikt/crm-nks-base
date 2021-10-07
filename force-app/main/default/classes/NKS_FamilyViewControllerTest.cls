@isTest
private class NKS_FamilyViewControllerTest {
    @isTest
    private static void getMaritalPersonTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_FamilyViewController.Relation> l = NKS_FamilyViewController.getMaritalPerson(query.execute());
        System.assertEquals(1, l.size());
    }
    @isTest
    private static void getChildrenTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_FamilyViewController.Relation> l = NKS_FamilyViewController.getChildren(query.execute());
        System.assertEquals(0, l.size());
    }
    @isTest
    private static void getParentsTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_FamilyViewController.Relation> l = NKS_FamilyViewController.getParents(query.execute());
        System.assertEquals(0, l.size());
    }
    @isTest
    private static void queryRelationsFromPDL(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = NKS_FamilyViewController.queryRelationsFromPDL('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }
    @isTest
    private static void queryMaritalPerson(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = NKS_FamilyViewController.queryMaritalPerson('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }
    @isTest
    private static void hasSameAddressTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = NKS_FamilyViewController.queryRelationsFromPDL('12106519356');
        System.assertEquals(true, NKS_FamilyViewController.hasSameAddress(r,r));
    }
}
