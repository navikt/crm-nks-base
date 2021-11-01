@isTest
private class NKS_FamilyViewControllerTest {
    @isTest
    private static void getMaritalPersonTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_FamilyViewController.Relation> l = NKS_FamilyViewController.getMaritalPerson(query.execute(), new NKS_FamilyViewController.Relation());
        System.assertEquals('UGIFT', l[0].role);
        String giftPerson = 
            '{' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"sivilstand" : [ {' +
                    '"type" : "GIFT",' +
                    '"relatertVedSivilstand" : "02091379875",' +
                    '"gyldigFraOgMed" : "2021-09-02",' +
                    '"bekreftelsesdato" : null' +
                  '} ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(giftPerson, PDL_API_Response.class);
        l = NKS_FamilyViewController.getMaritalPerson(response,new NKS_FamilyViewController.Relation());
        System.assertEquals('GIFT', l[0].role);
    }
    @isTest
    private static void isOver21Test(){

             String personWithAge = 
            '{' +
              '"data" : {' +
                '"hentPerson" : {' +
             
             '"foedsel" : [ {' +
            '"foedselsdato" : "1965-10-12",' +
            '"foedselsaar" : 1965,' +
            '"foedested" : "Fødested i/på Gjemnes",' +
            '"foedeland" : "NOR",' +
            '"foedekommune" : null' +
          '} ]' +
             
                  
                '}' +
              '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(personWithAge, PDL_API_Response.class);
        System.assertEquals(true, NKS_FamilyViewController.isOver21(response));
        personWithAge = 
           '{' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"sivilstand" : [ {' +
                    '"type" : "GIFT",' +
                    '"relatertVedSivilstand" : "02091379875",' +
                    '"gyldigFraOgMed" : "2021-09-02",' +
                    '"bekreftelsesdato" : null' +
                  '} ]' +
                '}' +
              '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(personWithAge, PDL_API_Response.class);
        System.assertEquals(false, NKS_FamilyViewController.isOver21(response));
    }
    @isTest
    private static void getChildrenTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_FamilyViewController.Relation> l = NKS_FamilyViewController.getChildren(query.execute() ,new NKS_FamilyViewController.Relation());
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
        String PersonWithAddress = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"bostedsadresse" : [ {' +
                    '"vegadresse" : {' +
                      '"tilleggsnavn" : "abrakadabra",' +
                      '"postnummer" : "6636",' +
                      '"matrikkelId" : 130534152,' +
                      '"koordinater" : {' +
                        '"z" : 0.0,' +
                        '"y" : 6974511.0,' +
                        '"x" : 453529.0,' +
                        '"kvalitet" : null' +
                      '},' +
                      '"kommunenummer" : "1557",' +
                      '"husnummer" : "1",' +
                      '"husbokstav" : "A",' +
                      '"bydelsnummer" : "2435",' +
                      '"bruksenhetsnummer" : "555",' +
                      '"adressenavn" : "Plassavegen"' +
                    '}' +
                  '} ]' +
                '}' +
              '}' +
            '}';
            String PersonWithoutAddress = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"bostedsadresse" : [ {' +
                    '"vegadresse" : {' +
                      '"tilleggsnavn" : null,' +
                      '"postnummer" : null,' +
                      '"matrikkelId" : null,' +
                      '"kommunenummer" : null,' +
                      '"husnummer" : null,' +
                      '"husbokstav" : null,' +
                      '"bydelsnummer" : null,' +
                      '"bruksenhetsnummer" : null,' +
                      '"adressenavn" : null' +
                    '}' +
                  '} ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response wAddress = (PDL_API_Response) System.JSON.deserialize(PersonWithAddress, PDL_API_Response.class);
        PDL_API_Response woAddress = (PDL_API_Response) System.JSON.deserialize(PersonWithoutAddress, PDL_API_Response.class);
        System.assertEquals(false, NKS_FamilyViewController.hasSameAddress(wAddress,woAddress));
        System.assertEquals(false, NKS_FamilyViewController.hasSameAddress(woAddress,wAddress));
        System.assertEquals(false, NKS_FamilyViewController.hasSameAddress(woAddress,woAddress));
        System.assertEquals(true, NKS_FamilyViewController.hasSameAddress(wAddress,wAddress));

    }
    @isTest
    private static void getAnsvarligSetTest(){
        String responsiblePerson = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [ { "ansvarlig" : "12345678901" } ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response responsible = (PDL_API_Response) System.JSON.deserialize(responsiblePerson, PDL_API_Response.class);
        Set<String> responsibleSet = NKS_FamilyViewController.getAnsvarligSet(responsible);
        System.assertEquals(true, responsibleSet.contains('12345678901'));

        responsiblePerson = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [  ]' +
                '}' +
              '}' +
            '}';
        responsible = (PDL_API_Response) System.JSON.deserialize(responsiblePerson, PDL_API_Response.class);
        responsibleSet = NKS_FamilyViewController.getAnsvarligSet(responsible);
        System.assertEquals(null, responsibleSet);

        responsiblePerson = 
        '{' +
          '"errors" : null,' +
          '"data" : {' +
            '"hentPerson" : {' +
              '"bostedsadresse" : [  ]' +
            '}' +
          '}' +
        '}';
        responsible = (PDL_API_Response) System.JSON.deserialize(responsiblePerson, PDL_API_Response.class);
        responsibleSet = NKS_FamilyViewController.getAnsvarligSet(responsible);
        System.assertEquals(null, responsibleSet);
    }
    @isTest
    private static void getAnsvarssubjektSetTest(){
        String responsiblePerson = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [ { "ansvarssubjekt" : "12345678901" } ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response responsible = (PDL_API_Response) System.JSON.deserialize(responsiblePerson, PDL_API_Response.class);
        Set<String> responsibleSet = NKS_FamilyViewController.getAnsvarssubjektSet(responsible);
        System.assertEquals(true, responsibleSet.contains('12345678901'));

        responsiblePerson = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [  ]' +
                '}' +
              '}' +
            '}';
        responsible = (PDL_API_Response) System.JSON.deserialize(responsiblePerson, PDL_API_Response.class);
        responsibleSet = NKS_FamilyViewController.getAnsvarssubjektSet(responsible);
        System.assertEquals(null, responsibleSet);

        responsiblePerson = 
        '{' +
          '"errors" : null,' +
          '"data" : {' +
            '"hentPerson" : {' +
              '"bostedsadresse" : [  ]' +
            '}' +
          '}' +
        '}';
        responsible = (PDL_API_Response) System.JSON.deserialize(responsiblePerson, PDL_API_Response.class);
        responsibleSet = NKS_FamilyViewController.getAnsvarssubjektSet(responsible);
        System.assertEquals(null, responsibleSet);
    }
    @isTest
    private static void hasResponsibilityTest(){
        String parentString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [ { "ansvarssubjekt" : "12345678901" } ]' +
                '}' +
              '}' +
            '}';
        String childString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentIdenter" : {' +
                  '"identer" : [ { "ident" : "12345678901" } ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response parent = (PDL_API_Response) System.JSON.deserialize(parentString, PDL_API_Response.class);
        PDL_API_Response child = (PDL_API_Response) System.JSON.deserialize(childString, PDL_API_Response.class);
        System.assertEquals(true, NKS_FamilyViewController.hasResponsibility(parent,child));
        childString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [ { "ansvarlig" : "12345678901" } ]' +
                '}' +
              '}' +
            '}';
        parentString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentIdenter" : {' +
                  '"identer" : [ { "ident" : "12345678901" },{ "ident" : "111111111" } ]' +
                '}' +
              '}' +
            '}';
        parent = (PDL_API_Response) System.JSON.deserialize(parentString, PDL_API_Response.class);
        child = (PDL_API_Response) System.JSON.deserialize(childString, PDL_API_Response.class);
        System.assertEquals(true, NKS_FamilyViewController.hasResponsibility(parent,child));
        childString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : [ { "ansvarlig" : "12345678901" } ]' +
                '}' +
              '}' +
            '}';
        parentString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentIdenter" : {' +
                  '"identer" : [ { "ident" : "11111111111" } ]' +
                '}' +
              '}' +
            '}';
        parent = (PDL_API_Response) System.JSON.deserialize(parentString, PDL_API_Response.class);
        child = (PDL_API_Response) System.JSON.deserialize(childString, PDL_API_Response.class);
        System.assertEquals(false, NKS_FamilyViewController.hasResponsibility(parent,child));
        childString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"foreldreansvar" : []' +
                '}' +
              '}' +
            '}';
        parentString = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentIdenter" : {' +
                  '"identer" : [ { "ident" : "11111111111" } ]' +
                '}' +
              '}' +
            '}';
        parent = (PDL_API_Response) System.JSON.deserialize(parentString, PDL_API_Response.class);
        child = (PDL_API_Response) System.JSON.deserialize(childString, PDL_API_Response.class);
        System.assertEquals(false, NKS_FamilyViewController.hasResponsibility(parent,child));
    }
    @isTest
    private static void getDateOfDeathTest(){
        String deadPerson = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"doedsfall" : [ { "doedsdato" : "2021-09-02" } ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response dead = (PDL_API_Response) System.JSON.deserialize(deadPerson, PDL_API_Response.class);
        String r = NKS_FamilyViewController.getDateOfDeath(dead);
        System.assertEquals('02.09.2021', r);
        String deadNullPerson = 
            '{' +
              '"errors" : null,' +
              '"data" : {' +
                '"hentPerson" : {' +
                  '"doedsfall" : [ { "doedsdato" : null } ]' +
                '}' +
              '}' +
            '}';
        dead = (PDL_API_Response) System.JSON.deserialize(deadNullPerson, PDL_API_Response.class);
        r = NKS_FamilyViewController.getDateOfDeath(dead);
        System.assertEquals(null, r);
    }
    @isTest
    private static void fillRelationFromResponseTest(){
        NKS_FamilyViewController.Relation r = new NKS_FamilyViewController.Relation();
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(unauthorizedPerson, PDL_API_Response.class);
        NKS_FamilyViewController.fillRelationFromResponse(r,response);
        System.assertEquals(true, r.unauthorized);
        System.assertEquals(null, r.name);
        r = new NKS_FamilyViewController.Relation();
        response = (PDL_API_Response) System.JSON.deserialize(testPerson1, PDL_API_Response.class);
        NKS_FamilyViewController.fillRelationFromResponse(r,response);
        System.assertEquals('MANN', r.sex);
    }
    @isTest
    private static void getParentsTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(withParentsPerson, PDL_API_Response.class);
        List<NKS_FamilyViewController.Relation> parents = NKS_FamilyViewController.getParents(response, new NKS_FamilyViewController.Relation());
        System.assertEquals(1, parents.size());
    }
    @isTest
    private static void getStillBornsTest(){
        String hasStillBorn = 
            '{' +
              '"data" : {' +
                '"hentPerson" : {' +
                    '"doedfoedtBarn" : [ {' +
                        '"dato" : "2021-09-02"' +
                      '},' +
                      '{' +
                        '"dato" : "2020-09-02"' +
                    '} ]' +
                '}' +
              '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(hasStillBorn, PDL_API_Response.class);
        List<NKS_FamilyViewController.Relation> l = NKS_FamilyViewController.getStillBorns(response);
        System.assertEquals(2, l.size());
        hasStillBorn = 
            '{' +
              '"data" : {' +
                '"hentPerson" : {' +
                    '"doedfoedtBarn" : []' +
                '}' +
              '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(hasStillBorn, PDL_API_Response.class);
        l = NKS_FamilyViewController.getStillBorns(response);
        System.assertEquals(0, l.size());
        hasStillBorn = 
        '{' +
          '"data" : {' +
            '"hentPerson" : null' +
          '}' +
        '}';
    response = (PDL_API_Response) System.JSON.deserialize(hasStillBorn, PDL_API_Response.class);
    l = NKS_FamilyViewController.getStillBorns(response);
    System.assertEquals(0, l.size());
    }
    /*
    @isTest
    private static void testjson(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        String s = JSON.serializePretty(query.execute());
        System.debug(s);
    }
    */
static final String unauthorizedPerson = 
    '{' +
      '"errors" :[' +
        '{' +
          '"message": "Ikke tilgang til å se person",' +
          '"locations": [' +
            '{' +
              '"line": 2,' +
              '"column": 5' +
            '}' +
          '],' +
          '"path": [' +
            '"hentPerson"' +
          '],' +
          '"extensions": {' +
            '"code": "unauthorized",' +
            '"details": {' +
              '"type": "abac-deny",' +
              '"cause": "cause-0001-manglerrolle",' +
              '"policy": "adressebeskyttelse_strengt_fortrolig_adresse"' +
            '},' +
            '"classification": "ExecutionAborted"' +
          '}' +
        '}' +
      '],' +
      '"data" : {' +
        '"hentPerson" : {' +
          '"sikkerhetstiltak" : [ ],' +
          '"navn" : [ {' +
            '"mellomnavn" : "SLØVENDE",' +
            '"gyldigFraOgMed" : "2021-09-02",' +
            '"fornavn" : "VAKKER",' +
            '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
            '"etternavn" : "SNERK"' +
          '} ],' +
          '"folkeregisteridentifikator" : [ {' +
            '"type" : "FNR",' +
            '"status" : "I_BRUK",' +
            '"identifikasjonsnummer" : "12106519356"' +
          '} ],' +
          '"adressebeskyttelse" : [ ]' +
        '}' +
      '}' +
    '}';
    static final String emptyPerson = 
    '{' +
      '"errors" : null,' +
      '"data" : null' +
    '}';
    static final String testPerson1 = 
    '{' +
      '"errors" : null,' +
      '"data" : {' +
        '"hentPerson" : {' +
          '"sivilstand" : [ {' +
            '"type" : "UGIFT",' +
            '"relatertVedSivilstand" : null,' +
            '"gyldigFraOgMed" : null,' +
            '"bekreftelsesdato" : null' +
          '} ],' +
          '"sikkerhetstiltak" : [ ],' +
          '"oppholdsadresse" : [ ],' +
          '"opphold" : [ ],' +
          '"navn" : [ {' +
            '"mellomnavn" : "SLØVENDE",' +
            '"gyldigFraOgMed" : "2021-09-02",' +
            '"fornavn" : "VAKKER",' +
            '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
            '"etternavn" : "SNERK"' +
          '} ],' +
          '"kjoenn" : [ {' +
            '"kjoenn" : "MANN"' +
          '} ],' +
          '"foreldreansvar" : [ {' +
            '"ansvarssubjekt" : "02091379875",' +
            '"ansvarligUtenIdentifikator" : null,' +
            '"ansvarlig" : null,' +
            '"ansvar" : "far"' +
          '} ],' +
          '"forelderBarnRelasjon" : [ {' +
            '"relatertPersonsRolle" : "BARN",' +
            '"relatertPersonsIdent" : "02091379875",' +
            '"minRolleForPerson" : "FAR"' +
          '} ],' +
          '"folkeregisterpersonstatus" : [ {' +
            '"status" : "bosatt",' +
            '"forenkletStatus" : "bosattEtterFolkeregisterloven"' +
          '} ],' +
          '"folkeregisteridentifikator" : [ {' +
            '"type" : "FNR",' +
            '"status" : "I_BRUK",' +
            '"identifikasjonsnummer" : "12106519356"' +
          '} ],' +
          '"foedsel" : [ {' +
            '"foedselsdato" : "1965-10-12",' +
            '"foedselsaar" : 1965,' +
            '"foedested" : "Fødested i/på Gjemnes",' +
            '"foedeland" : "NOR",' +
            '"foedekommune" : null' +
          '} ],' +
          '"falskIdentitet" : null,' +
          '"doedsfall" : [ ],' +
          '"doedfoedtBarn" : [ ],' +
          '"deltBosted" : [ ],' +
          '"bostedsadresse" : [ {' +
            '"vegadresse" : {' +
              '"tilleggsnavn" : null,' +
              '"postnummer" : "6636",' +
              '"matrikkelId" : 130534152,' +
              '"koordinater" : {' +
                '"z" : 0.0,' +
                '"y" : 6974511.0,' +
                '"x" : 453529.0,' +
                '"kvalitet" : null' +
              '},' +
              '"kommunenummer" : "1557",' +
              '"husnummer" : "1",' +
              '"husbokstav" : null,' +
              '"bydelsnummer" : null,' +
              '"bruksenhetsnummer" : null,' +
              '"adressenavn" : "Plassavegen"' +
            '},' +
            '"utenlandskAdresse" : null,' +
            '"ukjentBosted" : null,' +
            '"matrikkeladresse" : null,' +
            '"gyldigTilOgMed" : null,' +
            '"gyldigFraOgMed" : "1965-10-12T00:00:00.000Z",' +
            '"coAdressenavn" : null,' +
            '"angittFlyttedato" : "1965-10-12"' +
          '} ],' +
          '"adressebeskyttelse" : [ ]' +
        '},' +
        '"hentIdenter" : {' +
          '"identer" : [ {' +
            '"ident" : "12106519356",' +
            '"historisk" : false,' +
            '"gruppe" : "FOLKEREGISTERIDENT"' +
          '}, {' +
            '"ident" : "2762473496911",' +
            '"historisk" : false,' +
            '"gruppe" : "AKTORID"' +
          '} ]' +
        '}' +
      '}' +
    '}';
    static final String withParentsPerson = 
    '{' +
      '"errors" : null,' +
      '"data" : {' +
        '"hentPerson" : {' +
          '"sivilstand" : [ {' +
            '"type" : "UGIFT",' +
            '"relatertVedSivilstand" : null,' +
            '"gyldigFraOgMed" : null,' +
            '"bekreftelsesdato" : null' +
          '} ],' +
          '"sikkerhetstiltak" : [ ],' +
          '"oppholdsadresse" : [ ],' +
          '"opphold" : [ ],' +
          '"navn" : [ {' +
            '"mellomnavn" : "SLØVENDE",' +
            '"gyldigFraOgMed" : "2021-09-02",' +
            '"fornavn" : "VAKKER",' +
            '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
            '"etternavn" : "SNERK"' +
          '} ],' +
          '"kjoenn" : [ {' +
            '"kjoenn" : "MANN"' +
          '} ],' +
          '"foreldreansvar" : [ {' +
            '"ansvarssubjekt" : "02091379875",' +
            '"ansvarligUtenIdentifikator" : null,' +
            '"ansvarlig" : null,' +
            '"ansvar" : "far"' +
          '} ],' +
          '"forelderBarnRelasjon" : [ {' +
            '"relatertPersonsRolle" : "FAR",' +
            '"relatertPersonsIdent" : "02091379875",' +
            '"minRolleForPerson" : "BARN"' +
          '} ],' +
          '"folkeregisteridentifikator" : [ {' +
            '"type" : "FNR",' +
            '"status" : "I_BRUK",' +
            '"identifikasjonsnummer" : "12106519356"' +
          '} ],' +
          '"foedsel" : [ {' +
            '"foedselsdato" : "2005-10-12",' +
            '"foedselsaar" : 2005,' +
            '"foedested" : "Fødested i/på Gjemnes",' +
            '"foedeland" : "NOR",' +
            '"foedekommune" : null' +
          '} ],' +
          '"falskIdentitet" : null,' +
          '"doedsfall" : [ ],' +
          '"doedfoedtBarn" : [ ],' +
          '"deltBosted" : [ ],' +
          '"bostedsadresse" : [ {' +
            '"vegadresse" : {' +
              '"tilleggsnavn" : null,' +
              '"postnummer" : "6636",' +
              '"matrikkelId" : 130534152,' +
              '"koordinater" : {' +
                '"z" : 0.0,' +
                '"y" : 6974511.0,' +
                '"x" : 453529.0,' +
                '"kvalitet" : null' +
              '},' +
              '"kommunenummer" : "1557",' +
              '"husnummer" : "1",' +
              '"husbokstav" : null,' +
              '"bydelsnummer" : null,' +
              '"bruksenhetsnummer" : null,' +
              '"adressenavn" : "Plassavegen"' +
            '},' +
            '"utenlandskAdresse" : null,' +
            '"ukjentBosted" : null,' +
            '"matrikkeladresse" : null,' +
            '"gyldigTilOgMed" : null,' +
            '"gyldigFraOgMed" : "1965-10-12T00:00:00.000Z",' +
            '"coAdressenavn" : null,' +
            '"angittFlyttedato" : "1965-10-12"' +
          '} ],' +
          '"adressebeskyttelse" : [ ]' +
        '},' +
        '"hentIdenter" : {' +
          '"identer" : [ {' +
            '"ident" : "12106519356",' +
            '"historisk" : false,' +
            '"gruppe" : "FOLKEREGISTERIDENT"' +
          '}, {' +
            '"ident" : "2762473496911",' +
            '"historisk" : false,' +
            '"gruppe" : "AKTORID"' +
          '} ]' +
        '}' +
      '}' +
    '}';
static final String testJsonString = 
'{' +
  '"errors" : null,' +
  '"data" : {' +
    '"hentPerson" : {' +
      '"vergemaalEllerFremtidsfullmakt" : [ ],' +
      '"utflyttingFraNorge" : [ ],' +
      '"utenlandskIdentifikasjonsnummer" : [ ],' +
      '"tilrettelagtKommunikasjon" : [ ],' +
      '"telefonnummer" : [ ],' +
      '"statsborgerskap" : [ {' +
        '"metadata" : {' +
          '"opplysningsId" : "dd35688f-febd-4626-a9b4-39ed732ad69a",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"land" : "NOR",' +
        '"gyldigTilOgMed" : null,' +
        '"gyldigFraOgMed" : "1965-10-12",' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "1965-10-12T00:00:00.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '},' +
        '"bekreftelsesdato" : null' +
      '} ],' +
      '"sivilstand" : [ {' +
        '"type" : "UGIFT",' +
        '"relatertVedSivilstand" : null,' +
        '"metadata" : {' +
          '"opplysningsId" : "69789195-317e-42f7-8c28-c2cdda73901f",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:36.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"gyldigFraOgMed" : null,' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:36.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:36.000Z",' +
          '"aarsak" : null' +
        '},' +
        '"bekreftelsesdato" : null' +
      '} ],' +
      '"sikkerhetstiltak" : [ ],' +
      '"oppholdsadresse" : [ ],' +
      '"opphold" : [ ],' +
      '"navn" : [ {' +
        '"originaltNavn" : null,' +
        '"metadata" : {' +
          '"opplysningsId" : "c38343b4-2781-4bff-aa26-dc78bc46ee4d",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"mellomnavn" : "SLØVENDE",' +
        '"gyldigFraOgMed" : "2021-09-02",' +
        '"fornavn" : "VAKKER",' +
        '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '},' +
        '"etternavn" : "SNERK"' +
      '} ],' +
      '"kontaktinformasjonForDoedsbo" : [ ],' +
      '"kontaktadresse" : [ ],' +
      '"kjoenn" : [ {' +
        '"metadata" : {' +
          '"opplysningsId" : "6be1bb25-2731-489b-ac15-49a93730ea8e",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"kjoenn" : "MANN",' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '}' +
      '} ],' +
      '"innflyttingTilNorge" : [ ],' +
      '"identitetsgrunnlag" : [ ],' +
      '"fullmakt" : [ ],' +
      '"foreldreansvar" : [ {' +
        '"metadata" : {' +
          '"opplysningsId" : "4b47f1b0-9316-49bf-820b-3c5b0080b895",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:37.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:37.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:37.000Z",' +
          '"aarsak" : null' +
        '},' +
        '"ansvarssubjekt" : "02091379875",' +
        '"ansvarligUtenIdentifikator" : null,' +
        '"ansvarlig" : null,' +
        '"ansvar" : "far"' +
      '} ],' +
      '"forelderBarnRelasjon" : [ {' +
        '"relatertPersonsRolle" : "BARN",' +
        '"relatertPersonsIdent" : "02091379875",' +
        '"minRolleForPerson" : "FAR",' +
        '"metadata" : {' +
          '"opplysningsId" : "8c713184-ebe2-4dbe-8c6e-cff4760273d6",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:36.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:36.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:36.000Z",' +
          '"aarsak" : null' +
        '}' +
      '} ],' +
      '"folkeregisterpersonstatus" : [ {' +
        '"status" : "bosatt",' +
        '"metadata" : {' +
          '"opplysningsId" : "affd81b7-665c-4e82-88fb-a36181b6cb65",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"forenkletStatus" : "bosattEtterFolkeregisterloven",' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '}' +
      '} ],' +
      '"folkeregisteridentifikator" : [ {' +
        '"type" : "FNR",' +
        '"status" : "I_BRUK",' +
        '"metadata" : {' +
          '"opplysningsId" : "33be3e25-ccd5-4f97-8f21-bbac3c444877",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "srvdolly"' +
          '} ]' +
        '},' +
        '"identifikasjonsnummer" : "12106519356",' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "srvdolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '}' +
      '} ],' +
      '"foedsel" : [ {' +
        '"metadata" : {' +
          '"opplysningsId" : "20e8b676-568e-4eee-b5ce-b57156f850f5",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '},' +
        '"foedselsdato" : "1965-10-12",' +
        '"foedselsaar" : 1965,' +
        '"foedested" : "Fødested i/på Gjemnes",' +
        '"foedeland" : "NOR",' +
        '"foedekommune" : null' +
      '} ],' +
      '"falskIdentitet" : null,' +
      '"doedsfall" : [ ],' +
      '"doedfoedtBarn" : [ ],' +
      '"deltBosted" : [ ],' +
      '"bostedsadresse" : [ {' +
        '"vegadresse" : {' +
          '"tilleggsnavn" : null,' +
          '"postnummer" : "6636",' +
          '"matrikkelId" : 130534152,' +
          '"koordinater" : {' +
            '"z" : 0.0,' +
            '"y" : 6974511.0,' +
            '"x" : 453529.0,' +
            '"kvalitet" : null' +
          '},' +
          '"kommunenummer" : "1557",' +
          '"husnummer" : "1",' +
          '"husbokstav" : null,' +
          '"bydelsnummer" : null,' +
          '"bruksenhetsnummer" : null,' +
          '"adressenavn" : "Plassavegen"' +
        '},' +
        '"utenlandskAdresse" : null,' +
        '"ukjentBosted" : null,' +
        '"metadata" : {' +
          '"opplysningsId" : "53a9f29d-0980-42a3-8e18-13ae0b01b3d7",' +
          '"master" : "FREG",' +
          '"historisk" : false,' +
          '"endringer" : [ {' +
            '"type" : "OPPRETT",' +
            '"systemkilde" : "FREG",' +
            '"registrertAv" : "Folkeregisteret",' +
            '"registrert" : "2021-09-02T10:17:35.000Z",' +
            '"kilde" : "Dolly"' +
          '} ]' +
        '},' +
        '"matrikkeladresse" : null,' +
        '"gyldigTilOgMed" : null,' +
        '"gyldigFraOgMed" : "1965-10-12T00:00:00.000Z",' +
        '"folkeregistermetadata" : {' +
          '"sekvens" : null,' +
          '"opphoerstidspunkt" : null,' +
          '"kilde" : "Dolly",' +
          '"gyldighetstidspunkt" : "1965-10-12T00:00:00.000Z",' +
          '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
          '"aarsak" : null' +
        '},' +
        '"coAdressenavn" : null,' +
        '"angittFlyttedato" : "1965-10-12"' +
      '} ],' +
      '"adressebeskyttelse" : [ ]' +
    '},' +
    '"hentIdenter" : {' +
      '"identer" : [ {' +
        '"ident" : "12106519356",' +
        '"historisk" : false,' +
        '"gruppe" : "FOLKEREGISTERIDENT"' +
      '}, {' +
        '"ident" : "2762473496911",' +
        '"historisk" : false,' +
        '"gruppe" : "AKTORID"' +
      '} ]' +
    '}' +
  '}' +
'}';

}