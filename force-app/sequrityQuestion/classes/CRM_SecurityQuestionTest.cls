@IsTest
public with sharing class CRM_SecurityQuestionTest {
    public final static String parentJson = '{"data": {"errors": [{"message": "Fant ikke person","locations": [],"path": [],"extensions": {"code": "not_found","details": null,"classification": "ExecutionAborted"}}],"hentPerson": {"adressebeskyttelse": [],"bostedsadresse": [{"angittFlyttedato": null,"gyldigFraOgMed": null,"gyldigTilOgMed": null,"coAdressenavn": null,"vegadresse": {"matrikkelId": 448684135,"husnummer": "133","husbokstav": null,"bruksenhetsnummer": null,"adressenavn": "Gladsevegen","kommunenummer": "5006","bydelsnummer": null,"tilleggsnavn": null,"postnummer": "7730","koordinater": {"x": 613674.1,"y": 7113788.1,"z": 0.0,"kvalitet": null}},"matrikkeladresse": null,"utenlandskAdresse": null,"ukjentBosted": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "1965-10-12T00:00","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": null}],"deltBosted": [],"doedfoedtBarn": [],"doedsfall": [],"falskIdentitet": null,"foedsel": null,"folkeregisteridentifikator": null,"folkeregisterpersonstatus": null,"forelderBarnRelasjon": [{"relatertPersonsIdent": "09451451984","relatertPersonsRolle": "BARN","minRolleForPerson": "MOR","folkeregistermetadata": null,"metadata": null}],"foreldreansvar": null,"fullmakt": [],"identitetsgrunnlag": [],"kjoenn": [{"kjoenn": "MANN","folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "2021-09-02T10:17:35","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "6be1bb25-2731-489b-ac15-49a93730ea8e","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:35","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"kontaktadresse": [],"kontaktinformasjonForDoedsbo": [],"navn": [{"fornavn": "VAKKER","mellomnavn": "SLØVENDE","etternavn": "SNERK","forkortetNavn": "SNERK VAKKER SLØVENDE","originaltNavn": null,"gyldigFraOgMed": "2021-09-02","folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "2021-09-02T10:17:35","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "c38343b4-2781-4bff-aa26-dc78bc46ee4d","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:35","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"opphold": [],"oppholdsadresse": [],"sikkerhetstiltak": [],"sivilstand": [{"type": "UGIFT","gyldigFraOgMed": null,"relatertVedSivilstand": null,"bekreftelsesdato": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:36","gyldighetstidspunkt": "2021-09-02T10:17:36","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "69789195-317e-42f7-8c28-c2cdda73901f","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:36","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"statsborgerskap": [{"land": "NOR","bekreftelsesdato": null,"gyldigFraOgMed": "1965-10-12","gyldigTilOgMed": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "1965-10-12T00:00","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "dd35688f-febd-4626-a9b4-39ed732ad69a","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:35","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"telefonnummer": [],"tilrettelagtKommunikasjon": [],"utenlandskIdentifikasjonsnummer": [],"innflyttingTilNorge": [],"utflyttingFraNorge": [],"vergemaalEllerFremtidsfullmakt": []},"hentIdenter": {"identer": [{"ident": "12106519356","gruppe": "FOLKEREGISTERIDENT","historisk": false},{"ident": "2762473496911","gruppe": "AKTORID","historisk": false}]}}}';
    public final static String childJson = '';
    public final static String marriedJson = '';

    @TestSetup
    static void makeData() {
        List<Person__c> persons = NKS_TestDataFactory.createPersons(2);
        persons[0].INT_fnr__c = '12345678901';
        persons[0].INT_KrrEmail__c = 'test@gmail.com';
        persons[0].INT_LastUpdatedFromKRR__c = Date.today();
        persons[0].INT_ActorId__c = '12345678901';
        NKS_TestDataFactory.createPersonAccount(1, persons[0]);
        Account a1 = [SELECT Id FROM Account WHERE CRM_Person__c = :persons[0].Id LIMIT 1][0];
        persons[0].CRM_account__c = a1.Id;

        persons[1].INT_fnr__c = '12345678901';
        persons[1].INT_ActorId__c = '12345678902';
        NKS_TestDataFactory.createPersonAccount(1, persons[1]);
        Account a2 = [SELECT Id FROM Account WHERE CRM_Person__c = :persons[1].Id LIMIT 1][0];
        persons[1].CRM_account__c = a2.Id;
        update persons;
    }

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            BodyWrapper body = (BodyWrapper) Json.deserialize(req.getBody(), BodyWrapper.class);
            if (body.variables.ident == '12345678902') {
                HTTPResponse res = new HTTPResponse();
                System.debug(parentJson);
                res.setBody(parentJson);
                res.setStatusCode(200);
                return res;
            } else if (body.variables.ident == '09451451984') {
                HTTPResponse res = new HTTPResponse();
                res.setBody(
                    '{"data": {"errors": [{"message": "Fant ikke person","locations": [],"path": [],"extensions": {"code": "not_found","details": null,"classification": "ExecutionAborted"}}],"hentPerson": {"adressebeskyttelse": [],"bostedsadresse": [{"angittFlyttedato": null,"gyldigFraOgMed": null,"gyldigTilOgMed": null,"coAdressenavn": null,"vegadresse": {"matrikkelId": 448684135,"husnummer": "133","husbokstav": null,"bruksenhetsnummer": null,"adressenavn": "Gladsevegen","kommunenummer": "5006","bydelsnummer": null,"tilleggsnavn": null,"postnummer": "7730","koordinater": {"x": 613674.1,"y": 7113788.1,"z": 0.0,"kvalitet": null}},"matrikkeladresse": null,"utenlandskAdresse": null,"ukjentBosted": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "1965-10-12T00:00","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": null}],"deltBosted": [],"doedfoedtBarn": [],"doedsfall": [],"falskIdentitet": null,"foedsel": [{"foedselsaar": null,"foedselsdato": "2014-05-09","foedeland": null,"foedested": null,"foedekommune": null,"folkeregistermetadata": null,"metadata": null}],"folkeregisteridentifikator": null,"folkeregisterpersonstatus": null,"forelderBarnRelasjon": null,"foreldreansvar": null,"fullmakt": [],"identitetsgrunnlag": [],"kjoenn": null,"kontaktadresse": [],"kontaktinformasjonForDoedsbo": [],"navn": [{"fornavn": "SEDAT","mellomnavn": null,"etternavn": "MULDVARP","forkortetNavn": null,"originaltNavn": null,"gyldigFraOgMed": null,"folkeregistermetadata": null,"metadata": null}],"opphold": [],"oppholdsadresse": [],"sikkerhetstiltak": [],"sivilstand": null,"statsborgerskap": null,"telefonnummer": [],"tilrettelagtKommunikasjon": [],"utenlandskIdentifikasjonsnummer": [],"innflyttingTilNorge": [],"utflyttingFraNorge": [],"vergemaalEllerFremtidsfullmakt": []},"hentIdenter": null}}'
                );
                res.setStatusCode(200);
                return res;
            } else if (body.variables.ident == '12345678901') {
                HTTPResponse res = new HTTPResponse();
                res.setBody(
                    '{"data": {"errors": [{"message": "Fant ikke person","locations": [],"path": [],"extensions": {"code": "not_found","details": null,"classification": "ExecutionAborted"}}],"hentPerson": {"adressebeskyttelse": [],"bostedsadresse": null,"deltBosted": [],"doedfoedtBarn": [],"doedsfall": [],"falskIdentitet": null,"foedsel": null,"folkeregisteridentifikator": null,"folkeregisterpersonstatus": null,"forelderBarnRelasjon": null,"foreldreansvar": null,"fullmakt": [],"identitetsgrunnlag": [],"kjoenn": null,"kontaktadresse": [],"kontaktinformasjonForDoedsbo": [],"navn": null,"opphold": [],"oppholdsadresse": [],"sikkerhetstiltak": [],"sivilstand": [{"type": "GIFT","gyldigFraOgMed": "2021-07-01","relatertVedSivilstand": null,"bekreftelsesdato": null,"folkeregistermetadata": null,"metadata": null}],"statsborgerskap": null,"telefonnummer": [],"tilrettelagtKommunikasjon": [],"utenlandskIdentifikasjonsnummer": [],"innflyttingTilNorge": [],"utflyttingFraNorge": [],"vergemaalEllerFremtidsfullmakt": []},"hentIdenter": null}}'
                );
                res.setStatusCode(200);
                return res;
            } else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }
        }
    }

    private class BodyWrapper {
        Variables variables;
    }

    private class Variables {
        String ident;
    }

    @IsTest
    static void testSecurityQuestionEmail() {
        Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678901' LIMIT 1][0];
        ApiMock.setTestMock('GET_TPS_BANKKONTO', 200, 'ok');
        List<Integer> usedQuestions = new List<Integer>{ 0, 2, 3 };
        Test.startTest();
        CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
            person.CRM_Account__c,
            usedQuestions
        );
        Test.stopTest();
        System.assertEquals('test@gmail.com', question.answer);
        System.assertEquals('Hva er e-posten din?', question.question);
        System.assert(question.usedQuestions.size() > 0);
    }

    @IsTest
    static void testSecurityQuestionBankaccount() {
        Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678902' LIMIT 1][0];
        ApiMock.setTestMock('GET_TPS_BANKKONTO', 200, 'ok');
        List<Integer> usedQuestions = new List<Integer>{ 1, 2, 3 };
        Test.startTest();
        CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
            person.CRM_Account__c,
            usedQuestions
        );
        Test.stopTest();
        // Dette tallet kommer fra api mock settingen.
        System.assertEquals('06279137416', question.answer);
        System.assertEquals('Hva er bankkontonummeret ditt?', question.question);
        System.assert(question.usedQuestions.size() > 0);
    }

    @IsTest
    static void testSecurityQuestionRepeat() {
        Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678902' LIMIT 1][0];
        List<Integer> usedQuestions = new List<Integer>{ 0, 1, 2, 3 };
        Test.startTest();
        CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
            person.CRM_Account__c,
            usedQuestions
        );
        Test.stopTest();
        System.assertEquals('Trykk på "Nytt"-knappen for å se tidligere spørsmål', question.answer);
        System.assertEquals('Ingen flere spørsmål', question.question);
        System.assert(question.usedQuestions == null);
    }

    @IsTest
    static void testSecurityQuestionChildBirthday() {
        Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678902' LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new Mock());
        List<Integer> usedQuestions = new List<Integer>{ 0, 1, 3 };
        Test.startTest();
        CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
            person.CRM_Account__c,
            usedQuestions
        );
        Test.stopTest();
        System.assertEquals('SEDAT MULDVARP\n09.05.2014', question.answer);
        System.assertEquals('Hva er fødselsdatoen til barnet ditt?', question.question);
        System.assert(question.usedQuestions.size() > 0);
    }

    @IsTest
    static void testSecurityQuestionMarriage() {
        Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678901' LIMIT 1][0];
        Test.setMock(HttpCalloutMock.class, new Mock());
        List<Integer> usedQuestions = new List<Integer>{ 0, 1, 2 };
        Test.startTest();
        CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
            person.CRM_Account__c,
            usedQuestions
        );
        Test.stopTest();
        System.assertEquals('01.07.2021', question.answer);
        System.assertEquals('Hvilken dato giftet du deg?', question.question);
        System.assert(question.usedQuestions.size() > 0);
    }

    @IsTest
    static void testSecurityQuestionNoUser() {
        List<Integer> usedQuestions = new List<Integer>{ 0, 1, 2 };
        Test.startTest();
        CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
            '12345648975',
            usedQuestions
        );
        Test.stopTest();
        System.assertEquals('Fant ikke brukeren', question.question);
        System.assert(question.usedQuestions == null);
    }
}
