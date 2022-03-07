@isTest
public class NKS_HistorikkViewController_Test {
    @isTest
    static void testFullmaktData() {
        Person__c p = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestName',
            INT_FirstName__c = 'TestLastname'
        );
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');

        Test.startTest();
        List<NKS_HistorikkViewController.Historikk> hData = NKS_HistorikkViewController.getHistorikk(a.Id, 'Account');
        Test.stopTest();

        System.debug(hData);
        System.assertEquals(false, hData.isEmpty());
    }

    @isTest
    static void testFullmaktDataCase() {
        Person__c p = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestName',
            INT_FirstName__c = 'TestLastname'
        );
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        Case c = new Case(Origin = 'Phone', Subject = 'TEST PHONE', AccountId = a.Id);
        insert c;
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');

        Test.startTest();
        List<NKS_HistorikkViewController.Historikk> hData = NKS_HistorikkViewController.getHistorikk(c.Id, 'Case');
        Test.stopTest();
        System.debug(hData);
    }

    @isTest
    private static void nullTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_HistorikkViewController.Historikk> l = NKS_HistorikkViewController.getFullmakt(query.execute());
        String fullmaktPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"fullmakt" : [ {' +
            '"motpartsPersonident" : null,' +
            '"motpartsRolle" : null,' +
            '"omraader" :null,' +
            '"gyldigFraOgMed" : null,' +
            '"gyldigTilOgMed" : null' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(fullmaktPerson, PDL_API_Response.class);
        l = NKS_HistorikkViewController.getFullmakt(response);
        System.assertEquals(false, l.isEmpty());
    }
}
