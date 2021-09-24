public without sharing class FamilyRelationViewerController {
    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelatedPersons(Id recordId, String objectApiName) {
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
        /*
        List<PersonJSONFieldObjects.Familierelasjoner> familyRelations = (List<PersonJSONFieldObjects.Familierelasjoner>) System.JSON.deserialize(
            getFamilyRelationJSONString(personId),
            List<PersonJSONFieldObjects.Familierelasjoner>.class
        );

        Map<String, String> roleByRelatedPersonIdent = new Map<String, String>();
        for (PersonJSONFieldObjects.Familierelasjoner familyRelation : familyRelations) {
            roleByRelatedPersonIdent.put(familyRelation.relatertPersonsIdent, familyRelation.relatertPersonsRolle);
        }

        List<Person__c> relatedPersons = getRelatedPersons(roleByRelatedPersonIdent.keySet());
        Person__c p = getPerson(personId)[0];
        relatedPersons = removeChildrenUnder21(relatedPersons, roleByRelatedPersonIdent, p);
        relations.add(getMaritalRelation(p));
        relations.addAll(createRelations(relatedPersons, roleByRelatedPersonIdent));
        */


        //TODO: catch PDL_API related exceptions here
        String personIdent;
        PDL_API_Response relationsFromPDL =  getRelationsFromPDL(personIdent);
        Relation maritalRelation = getMaritalPerson(relationsFromPDL);
        if(maritalRelation != null){
            relations.add(maritalRelation);
        }
        relations.add(getChildren(relationsFromPDL));
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
        public Boolean deceased;
        @AuraEnabled
        public Integer age;
        @AuraEnabled
        public String birthdate;
        @AuraEnabled
        public String dateOfDeath;
        @AuraEnabled
        public Boolean disableurl;
        @AuraEnabled
        public Boolean child;
        @AuraEnabled
        public String color;
    }

    private static List<Person__c> removeChildrenUnder21(
        List<Person__c> familyRelations,
        Map<String, String> relatedPersonIds,
        Person__c p
    ) {
        List<Person__c> withoutChildrenOver21 = new List<Person__c>();
        Integer personage = Integer.valueOf(p.CRM_Age__c);
        //  Integer.valueOf(
        //     Date.valueOf(p.INT_DateOfBirth__c + ' 00:00:00').daysBetween(Date.Today()) / 365
        // );
        for (Person__c person : familyRelations) {
            String role = relatedPersonIds.get(person.Name).toLowerCase().capitalize();
            if (person.INT_DateOfBirth__c != null) {
                Integer age = Integer.valueOf(person.CRM_Age__c);
                // Integer.valueOf(
                //     Date.valueOf(person.INT_DateOfBirth__c + ' 00:00:00').daysBetween(Date.Today()) / 365
                // );
                if (age <= 21 && role == 'Barn')
                    withoutChildrenOver21.add(person);
            }
            if (personage <= 21 && role != 'Barn')
                withoutChildrenOver21.add(person);
        }
        return withoutChildrenOver21;
    }

    private static Relation getMaritalRelation(Person__c p) {
        if (p.INT_MaritalStatus__c != null) {
            Relation maritalrelation = new Relation();
            if (p.INT_MaritalRelation__c != null) {
                Person__c marriedto = getMaritalPerson(p.INT_MaritalRelation__c)[0];
                maritalrelation.personId = marriedto.Id;
                maritalrelation.accountId = marriedto.CRM_Account__c;
                maritalrelation.personIdent = marriedto.Name;
                maritalrelation.personName = marriedto.CRM_Account__r.Name;
                String birthdate;
                if (marriedto.INT_DateOfBirth__c != null) {
                    DateTime d = Date.valueOf(marriedto.INT_DateOfBirth__c + ' 00:00:00');
                    birthdate = d.format('dd.MM.yyyy');
                    // maritalrelation.age = Integer.valueOf(
                    //     Date.valueOf(marriedto.INT_DateOfBirth__c + ' 00:00:00').daysBetween(Date.Today()) / 365
                    // );
                }
                maritalrelation.birthdate = birthdate;
                maritalrelation.age = Integer.valueOf(marriedto.CRM_Age__c);
                if (marriedto.INT_Sex__c == 'Kvinne')
                    maritalrelation.color = 'pink';
                else if (marriedto.INT_Sex__c == 'Mann')
                    maritalrelation.color = 'blue';
                if (marriedto.INT_Confidential__c != 'UGRADERT' || marriedto.INT_IsNAvEmployee__c == true)
                    maritalrelation.disableurl = true;
            }
            maritalrelation.role = 'Sivilstatus: ' + p.INT_MaritalStatus__c.toLowerCase().capitalize();
            maritalrelation.child = false;
            return maritalrelation;
        } else
            return null;
    }

    private static List<Relation> createRelations(
        List<Person__c> relatedPersons,
        Map<String, String> roleByRelatedPersonIdent
    ) {
        List<Relation> relations = new List<Relation>();
        for (Person__c person : relatedPersons) {
            // Integer age;
            String birthdate;
            if (person.INT_DateOfBirth__c != null) {
                DateTime d = Date.valueOf(person.INT_DateOfBirth__c + ' 00:00:00');
                birthdate = d.format('dd.MM.yyyy');
                //     age = Integer.valueOf(
                //         Date.valueOf(person.INT_DateOfBirth__c + ' 00:00:00').daysBetween(Date.Today()) / 365
                //     );
            }
            String role = roleByRelatedPersonIdent.get(person.Name).toLowerCase().capitalize();

            Relation r = new Relation();
            r.personId = person.Id;
            r.accountId = person.CRM_Account__c;
            r.personIdent = person.Name;
            r.personName = person.CRM_Account__r.Name;
            r.role = role;
            r.age = Integer.valueOf(person.CRM_Age__c);
            r.birthdate = birthdate;
            r.sex = person.INT_Sex__c;
            r.deceased = person.INT_IsDeceased__c;
            r.child = false;
            r.disableurl = false;
            if (person.INT_Sex__c == 'Kvinne') {
                r.color = 'pink';
                if (role == 'Barn')
                    r.sex = 'Jente';
            } else if (person.INT_Sex__c == 'Mann') {
                r.color = 'blue';
                if (role == 'Barn')
                    r.sex = 'Gutt';
            }
            if (role == 'Barn')
                r.child = true;
            if (person.INT_Confidential__c != 'UGRADERT' || person.INT_IsNAvEmployee__c == true)
                r.disableurl = true;
            relations.add(r);
        }
        return relations;
    }

    private static List<Person__c> getRelatedPersons(Set<String> relatedPersonIds) {
        return [
            SELECT
                Id,
                Name,
                INT_FirstName__c,
                INT_MiddleName__c,
                INT_LastName__c,
                INT_DateOfBirth__c,
                INT_Sex__c,
                CRM_Account__c,
                CRM_Account__r.Name,
                CRM_Age__c,
                INT_Confidential__c,
                INT_IsNavEmployee__c,
                INT_IsDeceased__c
            FROM Person__c
            WHERE Name IN :relatedPersonIds
            ORDER BY INT_DateOfBirth__c DESC
        ];
    }

    private static String getFamilyRelationJSONString(Id personId) {
        return [SELECT Id, INT_FamilyRelations__c FROM Person__c WHERE Id = :personId].INT_FamilyRelations__c;
    }

    private static List<Person__c> getPerson(Id personId) {
        return [
            SELECT
                Id,
                CRM_Age__c,
                INT_MaritalRelation__c,
                INT_MaritalStatus__c,
                INT_ActorId__c,
                INT_DateOfBirth__c,
                INT_Confidential__c,
                INT_IsNavEmployee__c
            FROM Person__c
            WHERE Id = :personId
            LIMIT 1
        ];
    }

    private static List<Person__c> getMaritalPerson(String personId) {
        return [
            SELECT
                Id,
                Name,
                INT_ActorId__c,
                CRM_Account__c,
                CRM_Account__r.Name,
                CRM_Age__c,
                INT_Sex__c,
                INT_DateOfBirth__c,
                INT_Confidential__c,
                INT_IsNavEmployee__c
            FROM Person__c
            WHERE Name = :personId
            LIMIT 1
        ];
    }
    private static PDL_API_Response getRelationsFromPDL(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.selectAll();
        query.hentPerson.forelderbarnrelasjon.selectAll();
        return query.execute();
    }
    private static List<Relation> getChildren(PDL_API_Response relations){
        List<Relation> children = new List<Relation>();
        if(relations?.data?.hentPerson?.forelderbarnrelasjon == null){
            return children;
        }
        for(PDL_Forelderbarnrelasjon relation : relations.data.hentPerson.forelerbarnrelasjon){
            if(relation.relatertpersonsrolle == PDL_ForelderBarnRelasjonRolle.BARN &&
            relation.relatertpersonsident != null){
                PDL_API_Response childResponse = queryChild(relation.relatertpersonsident);
                if(child != null){
                    Relation childRelation = makeRelationFromResponse(childResponse);
                    if(childRelation.age != null && childRelation.age > 20) continue;
                    childRelation.role = relation.relatertpersonsrolle;
                    children.add(childRelation);
                }
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
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }
    private static Relation getMaritalPerson(PDL_API_Response relations){
        if(!maritalStatusOfInterest.contains(relations?.data?.hentPerson?.sivilstand[0]?.type)){
            return null;
        }
        if(relations.data.hentPeson.sivilstand[0].relatertVedSivilstand == null){
            return null;
        }
        PDL_API_Response response = queryMaritalPerson(relations.data.hentPerson.sivilstand[0].relatertVedSivilstand);
        
        if(response == null){
            return null;
        }
        Relation maritalRelation = makeRelationFromResponse(response);
        maritalRelation.role = relations?.data?.hentPerson?.sivilstand[0]?.type?.name();
        return maritalRelation;
    }
    private static Relation makeRelationFromResponse(PDL_API_Response response){
        Relation r = new Relation();
        r.disableurl = false;
        if(isUnauthorized(response)){
            r.Name = 'IKKE TILGJENGELIG';
            r.disableurl = true;
            return r;
        }

        r.Name = getFullName(response);
        r.birthdate = (response.data?.hentPerson?.foedsel[0]?.foedselsdato != null)
                    ? response.data.henpPerson.foedsel[0].foedselsdato.format('dd.MM.yyyy')
                    : null;
        r.age = getAge(response);
        r.sex = response.data?.hentPerson?.kjoenn[0]?.kjoenn?.name();
        r.color = (r.sex == 'MANN')? 'blue' : ( (r.sex == 'KVINNE')? 'pink' : 'gray' );
        r.dateOfDeath = response.data?.hentPerson?.doedsfall[0]?.dato?.format('dd.MM.yyyy');
        r.deceased = (r.dateOfDeath != null) ? true : false;
        if(!hasShield(response)){
            r.personId = getPersonIdFromIdents(getIdentsList(response));
            r.accountId = getAccountIdFromPersonId(r.personId);
            r.personIdent = getPersonIdent(response);
            r.disableurl = true;
        }
        return r;
    }
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
    private static Boolean isUnauthorized(PDL_API_Response response){
        if(response.errors != null){
            for(PDL_Error error : response.errors){
                if(error.extensions?.code == 'unauthorized'){
                    return true;
                }
            }
        }
        return false;
    }
    private static Boolean hasShield(PDL_API_Response response){
        if(response.data?.hentPerson?.adressebekyttelse[0]?.gradering == null){
            return false;
        }
        if(response.data.hentPerson.adressebeskyttelse[0].gradering == 'UGRADERT'){
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
        if(response.data?.hentPerson?.foedsel[0]?.foedselsdato == null){
            return null;
        }
        Date d = (response.data?.hentPerson?.doedsfall[0]?.dato != null) 
                ? response.data.hentPerson.doedsfall[0].dato 
                : Date.today();
        return d
                .addDays(-response.data.hentPerson.foedsel[0].foedselsdato.day())
                .addMonths(-response.data.hentPerson.foedsel[0].foedselsdato.month())
                .addYears(-response.data.hentPerson.foedsel[0].foedselsdato.year())
                .year();
    }
    private static String getFullName(PDL_API_Response response){
        List<String> nameParts = new List<String>();
        if(response?.data?.hentPerson?.navn[0]?.fornavn != null){
            nameParts.add(response.data.hentPerson.navn[0].fornavn);
        }
        if(response?.data?.hentPerson?.navn[0]?.mellomnavn != null){
            nameParts.add(response.data.hentPerson.navn[0].mellomnavn);
        }
        if(response?.data?.hentPerson?.navn[0]?.etternavn != null){
            nameParts.add(response.data.hentPerson.navn[0].etternavn);
        }
        if(nameParts.isEmpty()){
            return null;
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
}