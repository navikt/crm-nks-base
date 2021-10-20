public with sharing class NKS_FamilyViewController {

    public class Relation{

        @AuraEnabled
        public String personId; //link to Person__c object
        @AuraEnabled
        public String accountId; //link to Account object
        @AuraEnabled
        public String personIdent; //personal identification number(FNR/DNR)
        @AuraEnabled
        public String recordType; //record type marital/child/parent/stillborn/error
        @AuraEnabled
        public String role; //(GIFT/UGIFT...), (BARN), (FAR,MOR...), -
        @AuraEnabled
        public String name; //related person name
        @AuraEnabled
        public String birthDate;
        @AuraEnabled
        public String dateOfDeath;
        @AuraEnabled
        public Boolean deceased = false;
        @AuraEnabled
        public String eventDate; //date if separated/ stillborn date
        @AuraEnabled
        public String ageString;
        public Integer age;
        @AuraEnabled
        public String sex;
        @AuraEnabled
        public Boolean responsibility = false;
        @AuraEnabled
        public Boolean livesWith = false;
        @AuraEnabled
        public Boolean unauthorized = false;
        @AuraEnabled
        public Boolean confidential = false;
        @AuraEnabled
        public String confidentialStatus; //fortrolig/strengt_fortrolig
    }

    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelations(Id recordId, String objectApiName){
        Id personId;
        if (objectApiName == 'Case')
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        else if (objectApiName == 'Account')
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;

        List<Relation> relations = new List<Relation>();

        Id userId = UserInfo.getUserId();
        Boolean access = [
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :userId AND RecordId = :personId
        ]
        .HasReadAccess;
        if (!access){
            Relation r = new Relation();
            r.recordType = 'ERROR';
            r.name = 'Ikke tilgang til å se relasjoner.';
            relations.add(r);
            return relations;
        }
        String personIdent = [SELECT Id, Name FROM Person__c WHERE Id = :personId]?.Name;
        if(personIdent == null){
            Relation r = new Relation();
            r.recordType = 'ERROR';
            r.name = 'Person Ident ikke funnet.';
            relations.add(r);
            return relations;
        }

        PDL_API_Response relationsData = queryRelationsFromPDL(personIdent);

        if(relationsData?.data?.hentPerson == null){
            Relation r = new Relation();
            r.recordType = 'ERROR';
            if(relationsData?.errors != null && !relationsData.errors.isEmpty()){
                r.name = relationsData.errors[0].message;
            }
            relations.add(r);
            return relations;
        }

        relations.addAll(getMaritalPerson(relationsData));
        relations.addAll(getStillBorns(relationsData));
        relations.addAll(getChildren(relationsData));
        relations.addAll(getParents(relationsData));

        return relations;
    }
    @TestVisible
    private static List<Relation> getStillBorns(PDL_API_Response relationsData){
        List<Relation> stillBorns = new List<Relation>();
        if(relationsData?.data?.hentPerson?.doedfoedtBarn == null){
            return stillBorns;
        }
        if(relationsData.data.hentPerson.doedfoedtBarn.isEmpty()){
            return stillBorns;
        }
        for(PDL_DoedfoedtBarn relation : relationsData.data.hentPerson.doedfoedtBarn){
            Relation stillBorn = new Relation();
            stillBorn.recordType = 'stillborn';
            stillBorn.role = 'DØDFØDT BARN';
            stillBorn.eventDate = formatDate(relation.dato);
            stillBorns.add(stillBorn);
        }
        return stillBorns;
    }
    @TestVisible
    private static PDL_API_Response queryRelationsFromPDL(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.selectAll();
        query.hentPerson.forelderbarnrelasjon.selectAll();
        query.hentPerson.doedfoedtBarn.selectAll();
        query.hentPerson.foreldreansvar.ansvar = true;
        query.hentPerson.foreldreansvar.ansvarssubjekt = true;
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.foedsel.foedselsaar = true;
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        return query.execute();
    }
    @TestVisible
    private static List<Relation> getParents(PDL_API_Response relationsData){
        List<Relation> parents = new List<Relation>();
        if(getAge(relationsData) >= 21){
            return parents;
        }
        if(relationsData?.data?.hentPerson?.forelderbarnrelasjon == null){
            return parents;
        }
        Set<String> uniqRelations = new Set<String>();
        for(PDL_Forelderbarnrelasjon relation : relationsData.data.hentPerson.forelderbarnrelasjon){
            if(parentTypes.contains(relation.relatertpersonsrolle)){
                Relation parent = new Relation();
                parent.recordType = 'parent';
                parent.role = relation.relatertpersonsrolle.name();
                if(relation.relatertpersonsident != null){
                    if(!uniqRelations.add(relation.relatertpersonsident)){
                        continue;
                    }
                    PDL_API_Response parentResponse = queryChild(relation.relatertpersonsident);
                    if(isConfidentialRelation(relationsData,parentResponse)){
                        parent.unauthorized = true;
                        parents.add(parent);
                        continue;
                    }
                    fillRelationFromResponse(parent, parentResponse);
                    // parent.personIdent = relation.relatertPersonsIdent;
                    parent.livesWith = hasSameAddress(parentResponse, relationsData);
                    parent.responsibility = hasResponsibility(parentResponse, relationsData);
                    /*
                    List<String> childIdents = getIdentsList(relationsData);
                    if(parentResponse?.data?.hentPerson?.foreldreansvar != null && childIdents != null){
                        for(PDL_Foreldreansvar foreldreansvar : parentResponse.data.hentPerson.foreldreansvar){
                            if(foreldreansvar.ansvarssubjekt != null && childIdents.contains(foreldreansvar.ansvarssubjekt)){
                                parent.responsibility = true;
                            }
                        }
                    }
                    */
                }
                parents.add(parent);
            }
        }
        return parents;
    }
    @TestVisible
    private static List<Relation> getChildren(PDL_API_Response relationsData){
        List<Relation> children = new List<Relation>();
        if(relationsData?.data?.hentPerson?.forelderbarnrelasjon == null){
            return children;
        }
        Set<String> uniqRelations = new Set<String>();
        for(PDL_Forelderbarnrelasjon relation : relationsData.data.hentPerson.forelderbarnrelasjon){
            if(relation.relatertpersonsrolle == PDL_ForelderBarnRelasjonRolle.BARN){
                Relation child = new Relation();
                child.recordType = 'child';
                child.role = relation.relatertpersonsrolle.name();
                if(relation.relatertpersonsident != null){
                    if(!uniqRelations.add(relation.relatertpersonsident)){
                        continue;
                    }
                    PDL_API_Response childResponse = queryChild(relation.relatertpersonsident);
                    if(isConfidentialRelation(relationsData,childResponse)){
                        child.unauthorized = true;
                        children.add(child);
                        continue;
                    }
                    fillRelationFromResponse(child,childResponse);
                    // child.personIdent = relation.relatertPersonsIdent;
                    if(isOver21(child)){
                        continue;
                    }
                    child.livesWith = hasSameAddress(relationsData, childResponse);
                    child.responsibility = hasResponsibility(relationsData, childResponse);
                    /*
                    List<String> parentIdents = getIdentsList(relationsData);
                    if(childResponse?.data?.hentPerson?.foreldreansvar != null && parentIdents != null){
                        for(PDL_Foreldreansvar foreldreansvar : childResponse.data.hentPerson.foreldreansvar){
                            if(foreldreansvar.ansvarlig != null && parentIdents.contains(foreldreansvar.ansvarlig)){
                                child.responsibility = true;
                            }
                        }
                    }
                    */
                }
                children.add(child);
            }
        }
        return children;
    }
    private static PDL_API_Response queryChild(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        query.hentPerson.foedsel.foedselsaar = true;
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.kjoenn.kjoenn = true;
        query.hentPerson.doedsfall.doedsdato = true;
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentPerson.foreldreansvar.ansvarlig = true;
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        query.hentPerson.deltBosted.vegadresse.selectAll();
        query.hentPerson.deltBosted.matrikkeladresse.selectAll();
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }
    @TestVisible
    private static List<Relation> getMaritalPerson(PDL_API_Response relationsData){
        List<Relation> maritalPersonList = new List<Relation>();
        Relation r = new Relation ();
        r.recordType = 'marital';
        List<PDL_Sivilstand> sivilstand = relationsData?.data?.hentPerson?.sivilstand;
        if(sivilstand == null || sivilstand.isEmpty()){
            r.role = PDL_Sivilstandstype.UOPPGITT.name();
        }else if(sivilstand[0].type == PDL_Sivilstandstype.UOPPGITT ||
        sivilstand[0].type == PDL_Sivilstandstype.UGIFT){
            r.role = sivilstand[0].type.name();
        }else if(sivilstand[0].type == PDL_Sivilstandstype.SKILT ||
        sivilstand[0].type == PDL_Sivilstandstype.SKILT_PARTNER){
            r.role = sivilstand[0].type.name();
            if(sivilstand[0].gyldigFraOgMed != null){
                r.eventDate = formatDate(sivilstand[0].gyldigFraOgMed);
            }
        }else if(maritalStatusOfInterest.contains(sivilstand[0].type)){
            if(sivilstand[0].relatertVedSivilstand != null){
                PDL_API_Response response = queryMaritalPerson(sivilstand[0].relatertVedSivilstand);
                if(isConfidentialRelation(relationsData, response)){
                    r.unauthorized = true;
                }else{
                    fillRelationFromResponse(r,response);
                }
            }
            r.role = sivilstand[0].type.name();
            if(sivilstand[0].gyldigFraOgMed != null){
                r.eventDate =formatDate(sivilstand[0].gyldigFraOgMed);
            }

        }
        maritalPersonList.add(r);
        return maritalPersonList;
    }
    @TestVisible
    private static PDL_API_Response queryMaritalPerson(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        query.hentPerson.foedsel.foedselsaar = true;
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.kjoenn.kjoenn = true;
        query.hentPerson.doedsfall.doedsdato = true;
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }
    @TestVisible
    private static void fillRelationFromResponse(Relation relation, PDL_API_Response response){
        if(relation == null || response == null) return;
        
        if(isUnauthorized(response)){
            relation.unauthorized = true;
            return;
        }

        relation.name = getFullName(response);
        relation.birthdate = getBirthdate(response);
        relation.age = getAge(response);
        relation.ageString = getAgeString(response);
        relation.sex = getSex(response);
        relation.dateOfDeath = getDateOfDeath(response);
        relation.deceased = (relation.dateOfDeath != null) ? true : false;
        relation.confidentialStatus = getConfidentialStatus(response);
        relation.confidential = isConfidential(relation.confidentialStatus);
        if(!relation.confidential){
            relation.personId = getPersonIdFromIdents(getIdentsList(response));
            relation.accountId = getAccountIdFromPersonId(relation.personId);
            relation.personIdent = getPersonIdent(response);
        }
        return;
    }
    private static String getFullName(PDL_API_Response response){
        List<PDL_Navn> navn = response.data?.hentPerson?.navn;
        if(navn == null || navn.isEmpty()){
            return null;
        }
        List<String> nameParts = new List<String>();
        if(navn[0]?.fornavn != null){
            nameParts.add(navn[0].fornavn);
        }
        if(navn[0]?.mellomnavn != null){
            nameParts.add(navn[0].mellomnavn);
        }
        if(navn[0]?.etternavn != null){
            nameParts.add(navn[0].etternavn);
        }
        if(nameParts.isEmpty()){
            return null;
        }
        String fullName = String.join(nameParts, ' ');
        if(String.isBlank(fullName)){
            return null;
        }
        return fullName;
    }
    private static String getBirthdate(PDL_API_Response response){
        List<PDL_Foedsel> foedsel = response.data?.hentPerson?.foedsel;
        if(foedsel == null || foedsel.isEmpty()){
            return null;
        }
        if(foedsel[0]?.foedselsdato == null){
            return null;
        }
        return formatDate(foedsel[0].foedselsdato);
    }
    @TestVisible
    private static String getDateOfDeath(PDL_API_Response response){
        List<PDL_Doedsfall> doedsfall = response.data?.hentPerson?.doedsfall;
        if(doedsfall == null || doedsfall.isEmpty()){
            return null;
        }
        if(doedsfall[0]?.doedsdato == null){
            return null;
        }
        return formatDate(doedsfall[0].doedsdato);
    }
    private static Date getAgeDate(PDL_API_Response response){
        Date birthDate;
        List<PDL_Foedsel> foedsel = response.data?.hentPerson?.foedsel;
        if(foedsel == null || foedsel.isEmpty()){
            return null;
        }
        if(foedsel[0]?.foedselsdato != null){
            birthDate = foedsel[0].foedselsdato;
        }else if(foedsel[0]?.foedselsaar != null){
            birthDate = Date.newInstance(foedsel[0].foedselsaar, 1, 1);
        }else{
            return null;
        }
        List<PDL_Doedsfall> doedsfall = response.data?.hentPerson?.doedsfall;
        Date d;
        if(doedsfall != null && !doedsfall.isEmpty() && doedsfall[0]?.doedsdato != null){
            d = doedsfall[0].doedsdato;
        }else {
            d = Date.today();
        }
        // dates starts form 0001.01.01, so doing some math
        return d
                .addDays(-birthDate.day()+1)
                .addMonths(-birthDate.month()+1)
                .addYears(-birthDate.year()+1);
    }
    private static Integer getAge(PDL_API_Response response){
        Date d = getAgeDate(response);
        if(d == null){
            return null;
        }
        return d.year()-1;
    }
    private static String getAgeString(PDL_API_Response response){
        Date d = getAgeDate(response);
        if(d == null){
            return null;
        }
        if((d.year()-1) > 0){
            return String.valueOf(d.year()-1) + 'år';
        }
        if((d.month()-1) > 0){
            return String.valueOf(d.month()-1) + 'mnd';
        }
        return String.valueOf(d.day()-1) + 'd';
    }
    private static String getSex(PDL_API_Response response){
        List<PDL_Kjoenn> kjoenn = response.data?.hentPerson?.kjoenn;
        if(kjoenn == null || kjoenn.isEmpty()){
            return null;
        }
        if(kjoenn[0]?.kjoenn == null){
            return null;
        }
        return kjoenn[0].kjoenn.name();
    }
    private static Boolean isOver21(Relation r){
        if(!r.deceased && r.age >= 21){
            return true;
        }
        return false;
    }
    private static String getConfidentialStatus(PDL_API_Response response){
        List<PDL_Adressebeskyttelse> adressebeskyttelse = response.data?.hentPerson?.adressebeskyttelse;
        if(adressebeskyttelse == null || adressebeskyttelse.isEmpty()){
            return null;
        }
        if(adressebeskyttelse[0]?.gradering != null){
            return adressebeskyttelse[0].gradering.name();
        }
        return null;
    }
    private static Boolean isConfidential(String status){
        if(status == null || status == 'UGRADERT'){
            return false;
        }
        return true;
    }
    private static Boolean isUnauthorized(PDL_API_Response response){
        if(response.errors != null){
            for(PDL_Error error : response.errors){
                if(error.extensions?.code == 'unauthorized'){
                    return true;
                }
            }
        }
        if(isNavEmployee(response) == true){
            return true;
        }
        return false;
    }
    private static Boolean isConfidentialRelation(PDL_API_Response person, PDL_API_Response relation){
        Integer personGrade = 0;
        if(person?.data?.hentPerson?.adressebeskyttelse != null 
            && !person.data.hentPerson.adressebeskyttelse.isEmpty()
            && person.data.hentPerson.adressebeskyttelse[0].gradering != null){
            personGrade = gradeWeight.get(person.data.hentPerson.adressebeskyttelse[0].gradering);
        }
        Integer relationGrade = 0;
        if(relation?.data?.hentPerson?.adressebeskyttelse != null 
            && !relation.data.hentPerson.adressebeskyttelse.isEmpty()
            && relation.data.hentPerson.adressebeskyttelse[0].gradering != null){
            relationGrade = gradeWeight.get(relation.data.hentPerson.adressebeskyttelse[0].gradering);
        }
        if(personGrade < relationGrade){
            return true;
        }
        return false;
    }
    private static Boolean isNavEmployee(PDL_API_Response response){
        Set<String> idents = getIdentsList(response);
        if(idents == null){
            return null;
        }
        return [SELECT Id, INT_IsNavEmployee__c FROM Person__c WHERE Name IN :idents LIMIT 1]?.INT_IsNavEmployee__c;
    }
    private static String formatDate(Date d){
        if(d == null){
            return null;
        }
        return DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
    }
    private static String getAccountIdFromPersonId(String personId){
        if(personID == null){
            return null;
        }
        return [SELECT Id FROM Account WHERE CRM_Person__c = :personId LIMIT 1]?.Id;
    }
    private static String getPersonIdent(PDL_API_Response response){
        if(response.data?.hentIdenter?.identer == null){
            return null;
        }
        List<String> idents = new List<String>();
        for(PDL_IdentInformasjon ident : response.data.hentIdenter.identer){
            if(ident.ident != null && ident.historisk != true && ident.gruppe == PDL_IdentGruppe.FOLKEREGISTERIDENT){
                idents.add(
                    //typeOfId(ident.ident).name() +
                    //': ' + 
                    ident.ident
                );
            }
        }
        if(!idents.isEmpty()){
            return String.join(idents, ', ');
        }
        return null;
    }
    private static PDL_IdentType typeOfId(String ident){
        if(ident == null) {return null;}
        return (4 <= Integer.valueOf(ident.left(1))) ? PDL_IdentType.DNR : PDL_IdentType.FNR;
    }
    private static String getPersonIdFromIdents(Set<String> idents){
        if(idents == null){
            return null;
        }
        return [SELECT Id FROM Person__c WHERE Name IN :idents LIMIT 1]?.Id;
    }
    private static Set<String> getIdentsList(PDL_API_Response response){
        if(response.data?.hentIdenter?.identer == null){
            return null;
        }
        Set<String> identer = new Set<String>();
        for(PDL_IdentInformasjon ident : response.data.hentIdenter.identer){
            if(ident?.ident != null){
                identer.add(ident.ident);
            }
        }
        if(identer.isEmpty()){
            return null;
        }
        return identer;
    }
    @TestVisible
    private static Boolean hasResponsibility(PDL_API_Response parent, PDL_API_Response child){
        Set<String> responsibleSet = getAnsvarligSet(child);
        Set<String> idents = getIdentsList(parent);
        if(responsibleSet != null && idents != null){
            responsibleSet.retainAll(idents);
            if(!responsibleSet.isEmpty()){
                return true;
            }
        }
        responsibleSet = getAnsvarssubjektSet(parent);
        idents = getIdentsList(child);
        if(responsibleSet != null && idents != null){
            responsibleSet.retainAll(idents);
            if(!responsibleSet.isEmpty()){
                return true;
            }
        }
        return false;
    }
    @TestVisible
    private static Set<String> getAnsvarligSet(PDL_API_Response response){
        if(response?.data?.hentPerson?.foreldreansvar == null){
            return null;
        }
        Set<String> ansvarligSet = new Set<String>();
        for(PDL_Foreldreansvar foreldreansvar : response.data.hentPerson.foreldreansvar){
            if(foreldreansvar.ansvarlig != null){
                ansvarligSet.add(foreldreansvar.ansvarlig);
            }
        }
        if(ansvarligSet.isEmpty()){
            return null;
        }
        return ansvarligSet;
    }
    @TestVisible
    private static Set<String> getAnsvarssubjektSet(PDL_API_Response response){
        if(response?.data?.hentPerson?.foreldreansvar == null){
            return null;
        }
        Set<String> ansvarssubjektSet = new Set<String>();
        for(PDL_Foreldreansvar foreldreansvar : response.data.hentPerson.foreldreansvar){
            if(foreldreansvar.ansvarssubjekt != null){
                ansvarssubjektSet.add(foreldreansvar.ansvarssubjekt);
            }
        }
        if(ansvarssubjektSet.isEmpty()){
            return null;
        }
        return ansvarssubjektSet;
    }
    @TestVisible
    private static Boolean hasSameAddress(PDL_API_Response parent, PDL_API_Response child){
        if(parent?.data?.hentPerson?.bostedsadresse == null || parent.data.hentPerson.bostedsadresse.isEmpty()){
            return false;
        }
        PDL_Vegadresse parentAddress = parent.data.hentPerson.bostedsadresse[0]?.vegadresse;
        if(parentAddress == null){
            return false;
        }
        PDL_Vegadresse childAddress1;
        PDL_Vegadresse childAddress2;
        if(child?.data?.hentPerson?.bostedsadresse != null && !child.data.hentPerson.bostedsadresse.isEmpty()){
            childAddress1 = child.data.hentPerson.bostedsadresse[0].vegadresse;
        }
        if(child?.data?.hentPerson?.deltBosted != null && !child.data.hentPerson.deltBosted.isEmpty()){
            childAddress2 = child.data.hentPerson.deltBosted[0].vegadresse;
        }
        Boolean childAddress1Match = true;
        Boolean childAddress2Match = true;
        if(parentAddress.matrikkelId != null){
            if(parentAddress.matrikkelId != childAddress1?.matrikkelId){
                childAddress1Match = false;
            }
            if(parentAddress.matrikkelId != childAddress2?.matrikkelId){
                childAddress2Match = false;
            }
        }else{
            if(childAddress1?.matrikkelId != null){
                childAddress1Match = false;
            }
            if(childAddress2?.matrikkelId != null){
                childAddress2Match = false;
            }
        }
        if(parentAddress.husnummer != null){
            if(parentAddress.husnummer != childAddress1?.husnummer){
                childAddress1Match = false;
            }
            if(parentAddress.husnummer != childAddress2?.husnummer){
                childAddress2Match = false;
            }
        }else{
            childAddress1Match = false;
            childAddress2Match = false;
        }
        if(parentAddress.husbokstav != null){
            if(parentAddress.husbokstav != childAddress1?.husbokstav){
                childAddress1Match = false;
            }
            if(parentAddress.husbokstav != childAddress2?.husbokstav){
                childAddress2Match = false;
            }
        }else{
            if(childAddress1?.husbokstav != null){
                childAddress1Match = false;
            }
            if(childAddress2?.husbokstav != null){
                childAddress2Match = false;
            }
        }
        if(parentAddress.bruksenhetsnummer != null){
            if(parentAddress.bruksenhetsnummer != childAddress1?.bruksenhetsnummer){
                childAddress1Match = false;
            }
            if(parentAddress.bruksenhetsnummer != childAddress2?.bruksenhetsnummer){
                childAddress2Match = false;
            }
        }else{
            if(childAddress1?.bruksenhetsnummer != null){
                childAddress1Match = false;
            }
            if(childAddress2?.bruksenhetsnummer != null){
                childAddress2Match = false;
            }
        }
        if(parentAddress.adressenavn != null){
            if(parentAddress.adressenavn != childAddress1?.adressenavn){
                childAddress1Match = false;
            }
            if(parentAddress.adressenavn != childAddress2?.adressenavn){
                childAddress2Match = false;
            }
        }else{
            childAddress1Match = false;
            childAddress2Match = false;
        }
        if(parentAddress.kommunenummer != null){
            if(parentAddress.kommunenummer != childAddress1?.kommunenummer){
                childAddress1Match = false;
            }
            if(parentAddress.kommunenummer != childAddress2?.kommunenummer){
                childAddress2Match = false;
            }
        }else{
                childAddress1Match = false;
                childAddress2Match = false;
        }
        if(parentAddress.bydelsnummer != null){
            if(parentAddress.bydelsnummer != childAddress1?.bydelsnummer){
                childAddress1Match = false;
            }
            if(parentAddress.bydelsnummer != childAddress2?.bydelsnummer){
                childAddress2Match = false;
            }
        }else{
            if(childAddress1?.bydelsnummer != null){
                childAddress1Match = false;
            }
            if(childAddress2?.bydelsnummer != null){
                childAddress2Match = false;
            }
        }
        if(parentAddress.postnummer != null){
            if(parentAddress.postnummer != childAddress1?.postnummer){
                childAddress1Match = false;
            }
            if(parentAddress.postnummer != childAddress2?.postnummer){
                childAddress2Match = false;
            }
        }else{
                childAddress1Match = false;
                childAddress2Match = false;
        }
        if(childAddress1Match || childAddress2Match){
            return true;
        }
        if(parentAddress.tilleggsnavn != null){
            if(parentAddress.tilleggsnavn != childAddress1?.tilleggsnavn){
                childAddress1Match = false;
            }
            if(parentAddress.tilleggsnavn != childAddress2?.tilleggsnavn){
                childAddress2Match = false;
            }
        }else{
            if(childAddress1?.tilleggsnavn != null){
                childAddress1Match = false;
            }
            if(childAddress2?.tilleggsnavn != null){
                childAddress2Match = false;
            }
        }
        return false;
    }
    private static final List<PDL_Sivilstandstype> maritalStatusOfInterest = 
        new List<PDL_Sivilstandstype>{
            PDL_Sivilstandstype.GIFT,
            PDL_Sivilstandstype.ENKE_ELLER_ENKEMANN,
            PDL_Sivilstandstype.SEPARERT,
            PDL_Sivilstandstype.REGISTRERT_PARTNER,
            PDL_Sivilstandstype.SEPARERT_PARTNER,
            PDL_Sivilstandstype.GJENLEVENDE_PARTNER
        };
    private final static Map<PDL_AdressebeskyttelseGradering,Integer> gradeWeight = 
        new Map<PDL_AdressebeskyttelseGradering,Integer>{
            PDL_AdressebeskyttelseGradering.STRENGT_FORTROLIG_UTLAND => 2,
            PDL_AdressebeskyttelseGradering.STRENGT_FORTROLIG => 2,
            PDL_AdressebeskyttelseGradering.FORTROLIG => 1,
            PDL_AdressebeskyttelseGradering.UGRADERT => 0
        };
    private static final List<PDL_ForelderBarnRelasjonRolle> parentTypes =
        new List<PDL_ForelderBarnRelasjonRolle>{
            PDL_ForelderBarnRelasjonRolle.MOR,
            PDL_ForelderBarnRelasjonRolle.FAR,
            PDL_ForelderBarnRelasjonRolle.MEDMOR
        };
}
