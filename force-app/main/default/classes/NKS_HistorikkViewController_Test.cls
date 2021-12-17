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

        //System.assert(!histTestData.isEmpty());
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
        //System.assertEquals(false, hData.isEmpty());
    }

    @isTest
    private static void nullFraDatoTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_HistorikkViewController.Historikk> l = NKS_HistorikkViewController.getFullmakt(query.execute());
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
        String fullmaktPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"fullmakt" : [ {' +
            '"motpartsPersonident" : "27036012345",' +
            '"motpartsRolle" : "Fullmektig",' +
            '"omraader" :["Pensjon","Familie","Arbeid"],' +
            '"gyldigFraOgMed" : null,' +
            '"gyldigTilOgMed" : "2020-10-12"' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(fullmaktPerson, PDL_API_Response.class);
        l = NKS_HistorikkViewController.getFullmakt(response);
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
    }

    @isTest
    private static void nullRolleTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_HistorikkViewController.Historikk> l = NKS_HistorikkViewController.getFullmakt(query.execute());
        System.assertEquals('27036012345', l[0].motpartsPersonident);
        String fullmaktPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"fullmakt" : [ {' +
            '"motpartsPersonident" : "27036012345",' +
            '"motpartsRolle" : null,' +
            '"omraader" :["Pensjon","Familie","Arbeid"],' +
            '"gyldigFraOgMed" : "2019-10-12",' +
            '"gyldigTilOgMed" : "2020-10-12"' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(fullmaktPerson, PDL_API_Response.class);
        l = NKS_HistorikkViewController.getFullmakt(response);
        System.assertEquals('27036012345', l[0].motpartsPersonident);
    }

    @isTest
    private static void nullPersonidentTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_HistorikkViewController.Historikk> l = NKS_HistorikkViewController.getFullmakt(query.execute());
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
        String fullmaktPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"fullmakt" : [ {' +
            '"motpartsPersonident" : null,' +
            '"motpartsRolle" : "Fullmektig",' +
            '"omraader" :["Pensjon","Familie","Arbeid"],' +
            '"gyldigFraOgMed" : "2019-10-12",' +
            '"gyldigTilOgMed" : "2020-10-12"' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(fullmaktPerson, PDL_API_Response.class);
        l = NKS_HistorikkViewController.getFullmakt(response);
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
    }

    @isTest
    private static void nullOmraadeTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_HistorikkViewController.Historikk> l = NKS_HistorikkViewController.getFullmakt(query.execute());
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
        String fullmaktPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"fullmakt" : [ {' +
            '"motpartsPersonident" : "27036012345",' +
            '"motpartsRolle" : "Fullmektig",' +
            '"omraader" :null,' +
            '"gyldigFraOgMed" : "2019-10-12",' +
            '"gyldigTilOgMed" : "2020-10-12"' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(fullmaktPerson, PDL_API_Response.class);
        l = NKS_HistorikkViewController.getFullmakt(response);
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
    }

    @isTest
    private static void nullTilDatoTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_HistorikkViewController.Historikk> l = NKS_HistorikkViewController.getFullmakt(query.execute());
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
        String fullmaktPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"fullmakt" : [ {' +
            '"motpartsPersonident" : "27036012345",' +
            '"motpartsRolle" : "Fullmektig",' +
            '"omraader" :["Pensjon","Familie","Arbeid"],' +
            '"gyldigFraOgMed" : "2019-10-12",' +
            '"gyldigTilOgMed" : null' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(fullmaktPerson, PDL_API_Response.class);
        l = NKS_HistorikkViewController.getFullmakt(response);
        System.assertEquals('FULLMEKTIG', l[0].motpartsRolle);
    }
}
