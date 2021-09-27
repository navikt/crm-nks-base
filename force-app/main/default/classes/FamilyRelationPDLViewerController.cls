public with sharing class FamilyRelationPDLViewerController {
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

        //TODO: catch PDL_API related exceptions here
        String personIdent;
        PDL_API_Response relationsFromPDL =  queryRelationsFromPDL(personIdent);
        relations.add(getMaritalPerson(relationsFromPDL));
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
        public String color;
    }
    private static PDL_API_Response queryRelationsFromPDL(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.selectAll();
        query.hentPerson.forelderbarnrelasjon.selectAll();
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.foedsel.foedselsaar = true;
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
                    if(childRelation.age != null && childRelation.age < 21){
                        childRelation.role = relation.relatertpersonsrolle;
                        children.add(childRelation);
                    }
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
        List<Reslation> maritalRelationList = new List<Relation>();
        if(!maritalStatusOfInterest.contains(relations?.data?.hentPerson?.sivilstand[0]?.type)){
            return maritalRelationList;
        }
        if(relations.data.hentPeson.sivilstand[0].relatertVedSivilstand == null){
            return maritalRelationList;
        }
        PDL_API_Response response = queryMaritalPerson(relations.data.hentPerson.sivilstand[0].relatertVedSivilstand);
        
        if(response == null){
            return maritalRelationList;
        }
        Relation maritalRelation = makeRelationFromResponse(response);
        maritalRelation.role = relations?.data?.hentPerson?.sivilstand[0]?.type?.name();
        maritalRelationList.add(maritalRelation);
        return maritalRelationList;
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
        Date birthDate;
        if(response.data?.hentPerson?.foedsel[0]?.foedselsdato != null){
            birthDate = response.data.hentPerson.foedsel[0].foedselsdato;
        }else if(response.data?.hentPerson?.foedsel[0]?.foedselsaar != null){
            birthDate = Date.newInstance(response.data.hentPerson.foedsel[0].foedselsaar, 1, 1);
        }else{
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
}
