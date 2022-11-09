@IsTest
private with sharing class CRM_SecurityQuestionTest {
    // public final static String parentJson = '{"data": {"errors": [{"message": "Fant ikke person","locations": [],"path": [],"extensions": {"code": "not_found","details": null,"classification": "ExecutionAborted"}}],"hentPerson": {"adressebeskyttelse": [],"bostedsadresse": [{"angittFlyttedato": null,"gyldigFraOgMed": null,"gyldigTilOgMed": null,"coAdressenavn": null,"vegadresse": {"matrikkelId": 448684135,"husnummer": "133","husbokstav": null,"bruksenhetsnummer": null,"adressenavn": "Gladsevegen","kommunenummer": "5006","bydelsnummer": null,"tilleggsnavn": null,"postnummer": "7730","koordinater": {"x": 613674.1,"y": 7113788.1,"z": 0.0,"kvalitet": null}},"matrikkeladresse": null,"utenlandskAdresse": null,"ukjentBosted": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "1965-10-12T00:00","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": null}],"deltBosted": [],"doedfoedtBarn": [],"doedsfall": [],"falskIdentitet": null,"foedsel": null,"folkeregisteridentifikator": null,"folkeregisterpersonstatus": null,"forelderBarnRelasjon": [{"relatertPersonsIdent": "09451451984","relatertPersonsRolle": "BARN","minRolleForPerson": "MOR","folkeregistermetadata": null,"metadata": null}],"foreldreansvar": null,"fullmakt": [],"identitetsgrunnlag": [],"kjoenn": [{"kjoenn": "MANN","folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "2021-09-02T10:17:35","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "6be1bb25-2731-489b-ac15-49a93730ea8e","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:35","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"kontaktadresse": [],"kontaktinformasjonForDoedsbo": [],"navn": [{"fornavn": "VAKKER","mellomnavn": "SLØVENDE","etternavn": "SNERK","forkortetNavn": "SNERK VAKKER SLØVENDE","originaltNavn": null,"gyldigFraOgMed": "2021-09-02","folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "2021-09-02T10:17:35","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "c38343b4-2781-4bff-aa26-dc78bc46ee4d","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:35","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"opphold": [],"oppholdsadresse": [],"sikkerhetstiltak": [],"sivilstand": [{"type": "UGIFT","gyldigFraOgMed": null,"relatertVedSivilstand": null,"bekreftelsesdato": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:36","gyldighetstidspunkt": "2021-09-02T10:17:36","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "69789195-317e-42f7-8c28-c2cdda73901f","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:36","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"statsborgerskap": [{"land": "NOR","bekreftelsesdato": null,"gyldigFraOgMed": "1965-10-12","gyldigTilOgMed": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "1965-10-12T00:00","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": {"opplysningsId": "dd35688f-febd-4626-a9b4-39ed732ad69a","master": "FREG","endringer": [{"type": "OPPRETT","registrert": "2021-09-02T10:17:35","registrertAv": "Folkeregisteret","systemkilde": "FREG","kilde": "Dolly"}],"historisk": false}}],"telefonnummer": [],"tilrettelagtKommunikasjon": [],"utenlandskIdentifikasjonsnummer": [],"innflyttingTilNorge": [],"utflyttingFraNorge": [],"vergemaalEllerFremtidsfullmakt": []},"hentIdenter": {"identer": [{"ident": "12106519356","gruppe": "FOLKEREGISTERIDENT","historisk": false},{"ident": "2762473496911","gruppe": "AKTORID","historisk": false}]}}}';
    // public final static String childJson = '';
    // public final static String marriedJson = '';

    private final static String PDL_UNMARRIED_PERSON_WITHOUT_KIDS = '{"data": {"hentPerson": {"bostedsadresse": [],"navn": [{"fornavn": "TRIVIELL","mellomnavn": null,"etternavn": "SKILPADDE","forkortetNavn": "SKILPADDE TRIVIELL","originaltNavn": null,"gyldigFraOgMed": "2021-06-24"}],"sivilstand": [{"type": "UGIFT","gyldigFraOgMed": null,"relatertVedSivilstand": null,"bekreftelsesdato": null}],"forelderBarnRelasjon": []}}}';
    private final static String PDL_MARRIED_PERSON_WITHOUT_KIDS = '{"data": {"hentPerson": {"bostedsadresse": [],"navn": [{"fornavn": "TRIVIELL","mellomnavn": null,"etternavn": "SKILPADDE","forkortetNavn": "SKILPADDE TRIVIELL","originaltNavn": null,"gyldigFraOgMed": "2021-06-24"}],"sivilstand": [{"type": "GIFT","gyldigFraOgMed": "2001-10-09","relatertVedSivilstand": "06107701476","bekreftelsesdato": null}],"forelderBarnRelasjon": []}}}';
    private final static String PDL_MARRIED_PERSON_WITH_KIDS = '{"data": {"hentPerson": {"bostedsadresse": [{"angittFlyttedato": null,"coAdressenavn": null,"gyldigFraOgMed": "2020-05-07T12:09:19","gyldigTilOgMed": null,"vegadresse": {"matrikkelId": null,"husbokstav": null,"husnummer": "100","adressenavn": "Almåsvegen","bruksenhetsnummer": null,"tilleggsnavn": null,"postnummer": "5109","kommunenummer": "4601","bydelsnummer": null,"koordinater": null},"matrikkeladresse": null,"ukjentBosted": null,"utenlandskAdresse": null}],"navn": [{"fornavn": "TRIVIELL","mellomnavn": null,"etternavn": "SKILPADDE","forkortetNavn": "SKILPADDE TRIVIELL","originaltNavn": null,"gyldigFraOgMed": "2021-06-24"}],"sivilstand": [{"type": "GIFT","gyldigFraOgMed": "2001-10-09","relatertVedSivilstand": "06107701476","bekreftelsesdato": null}],"forelderBarnRelasjon": [{"relatertPersonsIdent": "12345678901","relatertPersonsRolle": "BARN","minRolleForPerson": "MOR","relatertPersonUtenFolkeregisteridentifikator": null},{"relatertPersonsIdent": "12345678902","relatertPersonsRolle": "BARN","minRolleForPerson": "MOR","relatertPersonUtenFolkeregisteridentifikator": null},{"relatertPersonsIdent": "12345678903","relatertPersonsRolle": "BARN","minRolleForPerson": "MOR","relatertPersonUtenFolkeregisteridentifikator": null},{"relatertPersonsIdent": "12345678904","relatertPersonsRolle": "MOR","minRolleForPerson": "BARN","relatertPersonUtenFolkeregisteridentifikator": null}]}}}';
    private final static String PDL_CHILD_1 = '{"data": {"hentPerson": {"bostedsadresse": [{"angittFlyttedato": null,"coAdressenavn": null,"gyldigFraOgMed": "2020-05-07T12:09:19","gyldigTilOgMed": null,"vegadresse": {"matrikkelId": null,"husbokstav": null,"husnummer": "100","adressenavn": "Almåsvegen","bruksenhetsnummer": null,"tilleggsnavn": null,"postnummer": "5109","kommunenummer": "4601","bydelsnummer": null,"koordinater": null},"matrikkeladresse": null,"ukjentBosted": null,"utenlandskAdresse": null}],"deltBosted": [],"adressebeskyttelse": [],"foedsel": [{"foedselsdato": "2020-10-10"}],"doedsfall": [],"navn": [{"fornavn": "TEST1","mellomnavn": "1","etternavn": "BARN1"}]}}}';
    private final static String PDL_CHILD_2_NOT_SAME_ADDRESS = '{"data": {"hentPerson": {"bostedsadresse": [{"angittFlyttedato": null,"coAdressenavn": null,"gyldigFraOgMed": "2020-05-07T12:09:19","gyldigTilOgMed": null,"vegadresse": {"matrikkelId": null,"husbokstav": null,"husnummer": "222","adressenavn": "Almåsvegen","bruksenhetsnummer": null,"tilleggsnavn": null,"postnummer": "5109","kommunenummer": "4601","bydelsnummer": null,"koordinater": null},"matrikkeladresse": null,"ukjentBosted": null,"utenlandskAdresse": null}],"deltBosted": [],"adressebeskyttelse": [],"foedsel": [{"foedselsdato": "2020-10-10"}],"doedsfall": [],"navn": [{"fornavn": "TEST2","mellomnavn": "2","etternavn": "BARN2"}]}}}';
    private final static String PDL_CHILD_3_ABOVE_21 = '{"data": {"hentPerson": {"bostedsadresse": [{"angittFlyttedato": null,"coAdressenavn": null,"gyldigFraOgMed": "2020-05-07T12:09:19","gyldigTilOgMed": null,"vegadresse": {"matrikkelId": null,"husbokstav": null,"husnummer": "100","adressenavn": "Almåsvegen","bruksenhetsnummer": null,"tilleggsnavn": null,"postnummer": "5109","kommunenummer": "4601","bydelsnummer": null,"koordinater": null},"matrikkeladresse": null,"ukjentBosted": null,"utenlandskAdresse": null}],"deltBosted": [],"adressebeskyttelse": [],"foedsel": [{"foedselsdato": "2000-10-10"}],"doedsfall": [],"navn": [{"fornavn": "TEST3","mellomnavn": "3","etternavn": "BARN3"}]}}}';
    private final static String PDL_PARENT_OF_MARRIED_PERSON_WITH_KIDS = '{"data": {"hentPerson": {"bostedsadresse": [{"angittFlyttedato": null,"coAdressenavn": null,"gyldigFraOgMed": "2020-05-07T12:09:19","gyldigTilOgMed": null,"vegadresse": {"matrikkelId": null,"husbokstav": null,"husnummer": "100","adressenavn": "Almåsvegen","bruksenhetsnummer": null,"tilleggsnavn": null,"postnummer": "5109","kommunenummer": "4601","bydelsnummer": null,"koordinater": null},"matrikkeladresse": null,"ukjentBosted": null,"utenlandskAdresse": null}],"deltBosted": [],"adressebeskyttelse": [],"foedsel": [{"foedselsdato": "1950-10-10"}],"doedsfall": [],"navn": [{"fornavn": "TEST","mellomnavn": "","etternavn": "FORELDER"}]}}}';
    private final static String TPS_WITH_BANK_ACCOUNT_NUMBER = '{"endringstidspunkt":"2020-10-01","endretAv":null,"endringstype":null,"bankkontoUtland":null,"bankkontoNorge":{"bankkontonummer":"06279137416","banknavn":null}}}';
    private final static String TPS_WITHOUT_BANK_ACCOUNT_NUMBER = '{"endringstidspunkt":"2020-10-01","endretAv":null,"endringstype":null,"bankkontoUtland":null,"bankkontoNorge":null}}';
    private final static String KRR_EMPTY = '{"personer":{"additionalProp1":{"personident":"1234567890","aktiv":true,"kanVarsles":true,"reservert":false,"spraak":"string","spraakOppdatert":"2022-10-17T10:12:25.864Z","epostadresse": null,"epostadresseOppdatert":"2022-10-17T10:12:25.864Z","epostadresseVerifisert":"2022-10-17T10:12:25.864Z","mobiltelefonnummer":"+4799999999","mobiltelefonnummerOppdatert":"2022-10-17T10:12:25.864Z","mobiltelefonnummerVerifisert":"2022-10-17T10:12:25.864Z","sikkerDigitalPostkasse":{"adresse":"string","leverandoerAdresse":"string","leverandoerSertifikat":"string"}}}}';
    private final static String KRR_EMAIL = '{"personer":{"additionalProp1":{"personident":"1234567890","aktiv":true,"kanVarsles":true,"reservert":false,"spraak":"string","spraakOppdatert":"2022-10-17T10:12:25.864Z","epostadresse":"test@nav.no","epostadresseOppdatert":"2022-10-17T10:12:25.864Z","epostadresseVerifisert":"2022-10-17T10:12:25.864Z","mobiltelefonnummer":"+4799999999","mobiltelefonnummerOppdatert":"2022-10-17T10:12:25.864Z","mobiltelefonnummerVerifisert":"2022-10-17T10:12:25.864Z","sikkerDigitalPostkasse":{"adresse":"string","leverandoerAdresse":"string","leverandoerSertifikat":"string"}}}}';
    public final static String MASKINPORTEN_TOKEN_RESPONSE = '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}';

    private class Mock implements HttpCalloutMock {
        List<HTTPResponse> responses = new List<HTTPResponse>();

        public Mock addSuccessfullBody(String body) {
            HTTPResponse res = new HTTPResponse();
            res.setBody(body);
            res.setStatusCode(200);
            return addResponse(res);
        }

        public Mock addResponse(HTTPResponse resp) {
            responses.add(resp);
            return this;
        }

        public void activateMock() {
            Test.setMock(HttpCalloutMock.class, this);
        }

        public HTTPResponse respond(HTTPRequest req) {
            return responses.remove(0);
        }
    }

    @IsTest
    static void getQuestionsKrrWithoutEmail() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', KRR_EMPTY, null));

        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsKRR('1234567890');
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'Expected no results, got' + result);
    }

    @IsTest
    static void getQuestionsKrrWithEmail() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', KRR_EMAIL, null));
        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsKRR('1234567890');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one results, got' + result);
        System.assertEquals('test@nav.no', result[0].answer, 'Did not get the expected email');
    }

    @IsTest
    static void getQuestionsTpsWithBankaccount() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        new Mock().addSuccessfullBody(TPS_WITH_BANK_ACCOUNT_NUMBER).activateMock();
        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsTPS('1234567890');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected no results, got' + result);
        System.assertEquals('06279137416', result[0].answer, 'Did not get the expected bank account number');
    }

    @IsTest
    static void getQuestionsTpsWithoutBankaccount() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        new Mock().addSuccessfullBody(TPS_WITHOUT_BANK_ACCOUNT_NUMBER).activateMock();
        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsTPS('1234567890');
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'Expected no results, got' + result);
    }

    @IsTest
    static void getQuestionsPdlUnmarriedPersonWithoutKids() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        new Mock().addSuccessfullBody(PDL_UNMARRIED_PERSON_WITHOUT_KIDS).activateMock();
        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsPDL('1234567890');
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'Expected no results, got' + result);
    }

    @IsTest
    static void getQuestionsPdlMarriedPersonWithoutKids() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        new Mock().addSuccessfullBody(PDL_MARRIED_PERSON_WITHOUT_KIDS).activateMock();
        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsPDL('1234567890');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one result, got' + result);
        System.assertEquals(
            Date.valueOf('2001-10-09').format(),
            result[0].answer,
            'Did not get the expected marrige date'
        );
    }

    @IsTest
    static void getQuestionsPdlMarriedPersonWithKids() {
        List<CRM_SecurityQuestionPicker.SecurityQuestionWrapper> result;
        new Mock()
            .addSuccessfullBody(PDL_MARRIED_PERSON_WITH_KIDS)
            .addSuccessfullBody(PDL_CHILD_1)
            .addSuccessfullBody(PDL_CHILD_2_NOT_SAME_ADDRESS)
            .addSuccessfullBody(PDL_CHILD_3_ABOVE_21)
            .addSuccessfullBody(PDL_PARENT_OF_MARRIED_PERSON_WITH_KIDS)
            .activateMock();
        Test.startTest();
        result = CRM_SecurityQuestionPicker.getQuestionsPDL('1234567890');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Expected one result, got' + result);
        System.assertEquals(
            Date.valueOf('2001-10-09').format(),
            result[0].answer,
            'Did not get the expected marrige date'
        );
        System.assertEquals(
            'TEST1 1 BARN1' +
            '\n' +
            Date.valueOf('2020-10-10').format(),
            result[1].answer,
            'Did not get the expected answer'
        );
    }

    // @TestSetup
    // static void makeData() {
    //     List<Person__c> persons = NKS_TestDataFactory.createPersons(2);
    //     persons[0].INT_fnr__c = '12345678901';
    //     persons[0].INT_KrrEmail__c = 'test@gmail.com';
    //     persons[0].INT_LastUpdatedFromKRR__c = Date.today();
    //     persons[0].INT_ActorId__c = '12345678901';
    //     NKS_TestDataFactory.createPersonAccount(1, persons[0]);
    //     Account a1 = [SELECT Id FROM Account WHERE CRM_Person__c = :persons[0].Id LIMIT 1][0];
    //     persons[0].CRM_account__c = a1.Id;

    //     persons[1].INT_fnr__c = '12345678901';
    //     persons[1].INT_ActorId__c = '12345678902';
    //     NKS_TestDataFactory.createPersonAccount(1, persons[1]);
    //     Account a2 = [SELECT Id FROM Account WHERE CRM_Person__c = :persons[1].Id LIMIT 1][0];
    //     persons[1].CRM_account__c = a2.Id;
    //     update persons;
    // }

    // private class Mock implements HttpCalloutMock {
    //     public HTTPResponse respond(HTTPRequest req) {
    //         BodyWrapper body = (BodyWrapper) Json.deserialize(req.getBody(), BodyWrapper.class);
    //         if (body.variables.ident == '12345678902') {
    //             HTTPResponse res = new HTTPResponse();
    //             System.debug(parentJson);
    //             res.setBody(parentJson);
    //             res.setStatusCode(200);
    //             return res;
    //         } else if (body.variables.ident == '09451451984') {
    //             HTTPResponse res = new HTTPResponse();
    //             res.setBody(
    //                 '{"data": {"errors": [{"message": "Fant ikke person","locations": [],"path": [],"extensions": {"code": "not_found","details": null,"classification": "ExecutionAborted"}}],"hentPerson": {"adressebeskyttelse": [],"bostedsadresse": [{"angittFlyttedato": null,"gyldigFraOgMed": null,"gyldigTilOgMed": null,"coAdressenavn": null,"vegadresse": {"matrikkelId": 448684135,"husnummer": "133","husbokstav": null,"bruksenhetsnummer": null,"adressenavn": "Gladsevegen","kommunenummer": "5006","bydelsnummer": null,"tilleggsnavn": null,"postnummer": "7730","koordinater": {"x": 613674.1,"y": 7113788.1,"z": 0.0,"kvalitet": null}},"matrikkeladresse": null,"utenlandskAdresse": null,"ukjentBosted": null,"folkeregistermetadata": {"ajourholdstidspunkt": "2021-09-02T10:17:35","gyldighetstidspunkt": "1965-10-12T00:00","opphoerstidspunkt": null,"kilde": "Dolly","aarsak": null,"sekvens": null},"metadata": null}],"deltBosted": [],"doedfoedtBarn": [],"doedsfall": [],"falskIdentitet": null,"foedsel": [{"foedselsaar": null,"foedselsdato": "2014-05-09","foedeland": null,"foedested": null,"foedekommune": null,"folkeregistermetadata": null,"metadata": null}],"folkeregisteridentifikator": null,"folkeregisterpersonstatus": null,"forelderBarnRelasjon": null,"foreldreansvar": null,"fullmakt": [],"identitetsgrunnlag": [],"kjoenn": null,"kontaktadresse": [],"kontaktinformasjonForDoedsbo": [],"navn": [{"fornavn": "SEDAT","mellomnavn": null,"etternavn": "MULDVARP","forkortetNavn": null,"originaltNavn": null,"gyldigFraOgMed": null,"folkeregistermetadata": null,"metadata": null}],"opphold": [],"oppholdsadresse": [],"sikkerhetstiltak": [],"sivilstand": null,"statsborgerskap": null,"telefonnummer": [],"tilrettelagtKommunikasjon": [],"utenlandskIdentifikasjonsnummer": [],"innflyttingTilNorge": [],"utflyttingFraNorge": [],"vergemaalEllerFremtidsfullmakt": []},"hentIdenter": null}}'
    //             );
    //             res.setStatusCode(200);
    //             return res;
    //         } else if (body.variables.ident == '12345678901') {
    //             HTTPResponse res = new HTTPResponse();
    //             res.setBody(
    //                 '{"data": {"errors": [{"message": "Fant ikke person","locations": [],"path": [],"extensions": {"code": "not_found","details": null,"classification": "ExecutionAborted"}}],"hentPerson": {"adressebeskyttelse": [],"bostedsadresse": null,"deltBosted": [],"doedfoedtBarn": [],"doedsfall": [],"falskIdentitet": null,"foedsel": null,"folkeregisteridentifikator": null,"folkeregisterpersonstatus": null,"forelderBarnRelasjon": null,"foreldreansvar": null,"fullmakt": [],"identitetsgrunnlag": [],"kjoenn": null,"kontaktadresse": [],"kontaktinformasjonForDoedsbo": [],"navn": null,"opphold": [],"oppholdsadresse": [],"sikkerhetstiltak": [],"sivilstand": [{"type": "GIFT","gyldigFraOgMed": "2021-07-01","relatertVedSivilstand": null,"bekreftelsesdato": null,"folkeregistermetadata": null,"metadata": null}],"statsborgerskap": null,"telefonnummer": [],"tilrettelagtKommunikasjon": [],"utenlandskIdentifikasjonsnummer": [],"innflyttingTilNorge": [],"utflyttingFraNorge": [],"vergemaalEllerFremtidsfullmakt": []},"hentIdenter": null}}'
    //             );
    //             res.setStatusCode(200);
    //             return res;
    //         } else {
    //             System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
    //             return null;
    //         }
    //     }
    // }

    // private class BodyWrapper {
    //     Variables variables;
    // }

    // private class Variables {
    //     String ident;
    // }

    // @IsTest
    // static void testSecurityQuestionEmail() {
    //     Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678901' LIMIT 1][0];
    //     ApiMock.setTestMock('GET_TPS_BANKKONTO', 200, 'ok');
    //     List<Integer> usedQuestions = new List<Integer>{ 0, 2, 3 };
    //     Test.startTest();
    //     CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
    //         person.CRM_Account__c,
    //         usedQuestions
    //     );
    //     Test.stopTest();
    //     System.assertEquals('test@gmail.com', question.answer);
    //     System.assertEquals('Hva er e-posten din?', question.question);
    //     System.assert(question.usedQuestions.size() > 0);
    // }

    // @IsTest
    // static void testSecurityQuestionBankaccount() {
    //     Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678902' LIMIT 1][0];
    //     ApiMock.setTestMock('GET_TPS_BANKKONTO', 200, 'ok');
    //     List<Integer> usedQuestions = new List<Integer>{ 1, 2, 3 };
    //     Test.startTest();
    //     CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
    //         person.CRM_Account__c,
    //         usedQuestions
    //     );
    //     Test.stopTest();
    //     // Dette tallet kommer fra api mock settingen.
    //     System.assertEquals('06279137416', question.answer);
    //     System.assertEquals('Hva er bankkontonummeret ditt?', question.question);
    //     System.assert(question.usedQuestions.size() > 0);
    // }

    // @IsTest
    // static void testSecurityQuestionRepeat() {
    //     Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678902' LIMIT 1][0];
    //     List<Integer> usedQuestions = new List<Integer>{ 0, 1, 2, 3 };
    //     Test.startTest();
    //     CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
    //         person.CRM_Account__c,
    //         usedQuestions
    //     );
    //     Test.stopTest();
    //     System.assertEquals('Trykk på "Nytt"-knappen for å se tidligere spørsmål', question.answer);
    //     System.assertEquals('Ingen flere spørsmål', question.question);
    //     System.assert(question.usedQuestions == null);
    // }

    // @IsTest
    // static void testSecurityQuestionChildBirthday() {
    //     Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678902' LIMIT 1][0];
    //     Test.setMock(HttpCalloutMock.class, new Mock());
    //     List<Integer> usedQuestions = new List<Integer>{ 0, 1, 3 };
    //     Test.startTest();
    //     CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
    //         person.CRM_Account__c,
    //         usedQuestions
    //     );
    //     Test.stopTest();
    //     System.assertEquals('SEDAT MULDVARP\n09.05.2014', question.answer);
    //     System.assertEquals('Hva er fødselsdatoen til barnet ditt?', question.question);
    //     System.assert(question.usedQuestions.size() > 0);
    // }

    // @IsTest
    // static void testSecurityQuestionMarriage() {
    //     Person__c person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Int_ActorId__c = '12345678901' LIMIT 1][0];
    //     Test.setMock(HttpCalloutMock.class, new Mock());
    //     List<Integer> usedQuestions = new List<Integer>{ 0, 1, 2 };
    //     Test.startTest();
    //     CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
    //         person.CRM_Account__c,
    //         usedQuestions
    //     );
    //     Test.stopTest();
    //     System.assertEquals('01.07.2021', question.answer);
    //     System.assertEquals('Hvilken dato giftet du deg?', question.question);
    //     System.assert(question.usedQuestions.size() > 0);
    // }

    // @IsTest
    // static void testSecurityQuestionNoUser() {
    //     List<Integer> usedQuestions = new List<Integer>{ 0, 1, 2 };
    //     Test.startTest();
    //     CRM_SecurityQuestionPicker.SecurityQuestionWrapper question = CRM_SecurityQuestionPicker.getSecurityQuestion(
    //         '12345648975',
    //         usedQuestions
    //     );
    //     Test.stopTest();
    //     System.assertEquals('Fant ikke brukeren', question.question);
    //     System.assert(question.usedQuestions == null);
    // }
}