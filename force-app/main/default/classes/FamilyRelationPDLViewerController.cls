public with sharing class FamilyRelationPDLViewerController {
    public static Boolean TEST_MODE = true;
    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelatedPersons(Id recordId, String objectApiName) {
        if(TEST_MODE){
            List<Relation> l = new List<Relation>();
            Relation r1 = new Relation();
            Relation r2 = new Relation();
            Relation r3 = new Relation();
            Relation r4 = new Relation();
            Relation r5 = new Relation();
            r1.personName = 'name1';
            r1.personIdent = '11111111111';
            r1.birthdate = Datetime.newInstance(1975, 8, 30).format('dd.MM.yyyy');
            r1.age = 36;
            r1.accountId = '111';
            r1.color = 'blue';
            r1.sex = 'MANN';
            r1.role = 'FAR';
            
            r2.personName = 'name2';
            r2.personIdent = '22222222222';
            r2.birthdate = Datetime.newInstance(2000, 6, 15).format('dd.MM.yyyy');
            r2.age = 21;
            r2.accountId = '222';
            r2.color = 'pink';
            r2.sex = 'KVINNE';
            r2.role = 'BARN';
            r2.missingInSalesforce = true;

            r3.personName = 'name3';
            r3.personIdent = '33333333333';
            r3.birthdate = Datetime.newInstance(2000, 6, 15).format('dd.MM.yyyy');
            r3.age = 21;
            r3.accountId = '222';
            r3.color = 'blue';
            r3.sex = 'MANN';
            r3.role = 'BARN';
            r3.deceased = true;
            r3.dateOfDeath = Datetime.newInstance(2001, 6, 15).format('dd.MM.yyyy');

            l.add(r1);
            l.add(r2);
            l.add(r3);
            return l;
        }
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
        if (!access)
            return relations;

        //TODO: catch PDL_API related exceptions here
        String personIdent = [SELECT Id, Name FROM Person__c WHERE Id = :personId]?.Name;
        if(personIdent == null){
            return relations;
        }
        PDL_API_Response relationsFromPDL =  queryRelationsFromPDL(personIdent);
        relations.addAll(getMaritalPerson(relationsFromPDL));
        relations.addAll(getChildren(relationsFromPDL));
        // relations.add(getParents(relationsFromPDL));
        return relations;
    }

    public class Relation {
        @AuraEnabled
        public String personIdent;
        @AuraEnabled
        public String personId;
        @AuraEnabled
        public String accountId;
        @AuraEnabled
        public String personName;
        @AuraEnabled
        public String role;
        @AuraEnabled
        public String sex;
        @AuraEnabled
        public Boolean deceased = false;
        @AuraEnabled
        public Integer age;
        @AuraEnabled
        public String birthdate;
        @AuraEnabled
        public String dateOfDeath;
        @AuraEnabled
        public Boolean disableurl = false;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public Boolean shielded = false;
        @AuraEnabled
        public Boolean unauthorized = false;
        @AuraEnabled
        public Boolean missingInSalesforce = false;
    }
    @TestVisible
    private static PDL_API_Response queryRelationsFromPDL(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.selectAll();
        query.hentPerson.forelderbarnrelasjon.selectAll();
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.foedsel.foedselsaar = true;
        return query.execute();
    }
    @TestVisible
    private static List<Relation> getChildren(PDL_API_Response relations){
        List<Relation> children = new List<Relation>();
        if(relations?.data?.hentPerson?.forelderbarnrelasjon == null){
            return children;
        }
        List<String> childrenIdenter = new List<String>();
        for(PDL_Forelderbarnrelasjon relation : relations.data.hentPerson.forelderbarnrelasjon){
            if(relation.relatertpersonsrolle == PDL_ForelderBarnRelasjonRolle.BARN){
                if(relation.relatertpersonsident != null){
                    if(childrenIdenter.contains(relation.relatertpersonsident)){
                        //checking if child with same ID already added
                        continue;
                    }
                    PDL_API_Response childResponse = queryChild(relation.relatertpersonsident);
                    if(childResponse != null){
                        Relation childRelation = makeRelationFromResponse(childResponse);
                        if(childRelation.age != null && childRelation.age < 21){
                            childRelation.role = relation.relatertpersonsrolle.name();
                            children.add(childRelation);
                            childrenIdenter.add(relation.relatertpersonsident);
                            continue;
                        }
                    }
                }
                Relation r = new Relation();
                r.role = relation.relatertpersonsrolle.name();
                r.personName = unknownName;
                r.disableurl = true;
            }
        }
        return children;
    }
    @TestVisible
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
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }
    @TestVisible
    private static List<Relation> getMaritalPerson(PDL_API_Response relations){
        List<Relation> maritalRelationList = new List<Relation>();
        List<PDL_Sivilstand> sivilstand = relations.data?.hentPerson?.sivilstand;
        if(sivilstand == null || sivilstand.isEmpty()){
            return maritalRelationList;
        }
        if(!maritalStatusOfInterest.contains(sivilstand[0].type)){
            return maritalRelationList;
        }
        if(sivilstand[0].relatertVedSivilstand == null){
            Relation r = new Relation();
            r.role = sivilstand[0].type.name();
            r.personName = unknownName;
            r.disableurl = true;
            maritalRelationList.add(r);
            return maritalRelationList;
        }
        PDL_API_Response response = queryMaritalPerson(sivilstand[0].relatertVedSivilstand);
        
        if(response == null){
            return maritalRelationList;
        }
        Relation maritalRelation = makeRelationFromResponse(response);
        maritalRelation.role = sivilstand[0].type.name();
        maritalRelationList.add(maritalRelation);
        return maritalRelationList;
    }
    private static Relation makeRelationFromResponse(PDL_API_Response response){
        Relation r = new Relation();
        if(isUnauthorized(response)){
            r.personName = notAvailableName;
            r.unauthorized = true;
            r.disableurl = true;
            return r;
        }

        r.personName = getFullName(response);
        r.birthdate = getBirthdate(response);
        r.age = getAge(response);
        r.sex = getSex(response);
        r.color = (r.sex == 'MANN')? 'blue' : ( (r.sex == 'KVINNE')? 'pink' : 'gray' );
        r.dateOfDeath = getDateOfDeath(response);
        r.deceased = (r.dateOfDeath != null) ? true : false;
        if(!isShielded(response)){
            r.personId = getPersonIdFromIdents(getIdentsList(response));
            r.accountId = getAccountIdFromPersonId(r.personId);
            r.personIdent = getPersonIdent(response);
            if(r.accountId == null){
                r.missingInSalesforce = true;
                r.disableurl = true;
            }
        }else{
            r.shielded = true;
            r.disableurl = true;
        }
        return r;
    }
    private static String formatDate(Date d){
        if(d == null){
            return null;
        }
        return DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
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
    private static PDL_API_Response queryMaritalPerson(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.type = true;
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
    private static Boolean isUnauthorized(PDL_API_Response response){
        if(response.errors != null){
            for(PDL_Error error : response.errors){
                if(error.extensions?.code == 'unauthorized'){
                    return true;
                }
            }
        }
        return false;
    }@TestVisible
    private static Boolean isShielded(PDL_API_Response response){
        List<PDL_Adressebeskyttelse> adressebeskyttelse = response.data?.hentPerson?.adressebeskyttelse;
        if(adressebeskyttelse == null || adressebeskyttelse.isEmpty()){
            return false;
        }
        if(adressebeskyttelse[0]?.gradering == null){
            return false;
        }
        if(adressebeskyttelse[0].gradering == PDL_AdressebeskyttelseGradering.UGRADERT){
            return false;
        }
        return true;
    }
    private static String getPersonIdent(PDL_API_Response response){
        if(response.data?.hentIdenter?.identer == null){
            return null;
        }
        for(PDL_IdentInformasjon ident : response.data.hentIdenter.identer){
            if(ident.ident != null && ident.historisk != true){
                return ident.ident;
            }
        }
        return null;
    }
    private static String getAccountIdFromPersonId(String personId){
        if(personID == null){
            return null;
        }
        return [SELECT Id FROM Account WHERE CRM_Person__c = :personId LIMIT 1]?.Id;
    }
    private static String getPersonIdFromIdents(List<String> idents){
        if(idents == null){
            return null;
        }
        return [SELECT Id FROM Person__c WHERE Name IN :idents LIMIT 1]?.Id;
    }
    private static List<String> getIdentsList(PDL_API_Response response){
        if(response.data?.hentIdenter?.identer == null){
            return null;
        }
        List<String> identer = new List<String>();
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
    private static Integer getAge(PDL_API_Response response){
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
                System.debug(d);
        // dates starts form 0001.01.01, so doing some math
        return d
                .addDays(-birthDate.day()+1)
                .addMonths(-birthDate.month()+1)
                .addYears(-birthDate.year()+1)
                .year()-1;
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
            return unknownName;
        }
        return String.join(nameParts, ' ');
    }
    private static final List<PDL_Sivilstandstype> maritalStatusOfInterest = 
        new List<PDL_Sivilstandstype>{PDL_Sivilstandstype.GIFT,
                                      PDL_Sivilstandstype.ENKE_ELLER_ENKEMANN,
                                      PDL_Sivilstandstype.SEPARERT,
                                      PDL_Sivilstandstype.REGISTRERT_PARTNER,
                                      PDL_Sivilstandstype.SEPARERT_PARTNER,
                                      PDL_Sivilstandstype.GJENLEVENDE_PARTNER};
    private static final String unknownName = 'UKJENT_NAVN';
    private static final String notAvailableName = 'IKKE_TILHGJENGELIG';
}