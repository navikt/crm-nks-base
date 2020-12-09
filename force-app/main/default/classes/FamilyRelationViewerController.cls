public without sharing class FamilyRelationViewerController {

    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelatedPersons(Id recordId , String objectApiName) {
        Id personId; 
        if(objectApiName == 'Case') personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id =: recordId].Account.CRM_Person__c; 
        else if(objectApiName == 'Account') personId = [SELECT CRM_Person__c FROM Account WHERE Id =: recordId].CRM_Person__c; 

        List<PersonJSONFieldObjects.Familierelasjoner> familyRelations = (List<PersonJSONFieldObjects.Familierelasjoner>) System.JSON.deserialize(
                getFamilyRelationJSONString(personId),
                List<PersonJSONFieldObjects.Familierelasjoner>.class
        );

        Map<String, String> roleByRelatedPersonIdent = new Map<String, String>();
        for (PersonJSONFieldObjects.Familierelasjoner familyRelation : familyRelations) {
            roleByRelatedPersonIdent.put(familyRelation.relatertPersonsIdent, familyRelation.relatertPersonsRolle);
        }

        List<Person__c> relatedPersons = getRelatedPersons(roleByRelatedPersonIdent.keySet());

        relatedPersons = removeChildrenUnder21(relatedPersons, roleByRelatedPersonIdent);
        
        List<Relation> relations = new List<Relation>();
        for (Person__c person : relatedPersons) {
            Relation r = new Relation();
            r.personId = person.Id;
            r.accountId = person.CRM_Account__c; 
            r.personIdent = person.Name;
            r.personName = person.CRM_Account__r.Name;
            r.role = roleByRelatedPersonIdent.get(person.Name).toLowerCase().capitalize();
            relations.add(r);
        }
        return relations;
    }

    public class Relation {
        @AuraEnabled public String personIdent;
        @AuraEnabled public String personId;
        @AuraEnabled public String accountId;
        @AuraEnabled public String personName;
        @AuraEnabled public String role;
    }

    private static List<Person__c> removeChildrenUnder21(List<Person__c> familyRelations, Map<String, String> relatedPersonIds) {
        List<Person__c> withoutChildrenOver21 = new List<Person__c>();
        for(Person__c person : familyRelations){
            String role = relatedPersonIds.get(person.Name).toLowerCase().capitalize();             
            if(person.INT_DateOfBirth__c != null){
                Integer age = Integer.valueOf(Date.valueOf(person.INT_DateOfBirth__c + ' 00:00:00').daysBetween(Date.Today())/365);
                if(!(age > 21  && role == 'Barn')) withoutChildrenOver21.add(person); 
            }
            else if(role != 'Barn') withoutChildrenOver21.add(person);  
        }
        return withoutChildrenOver21;
    }

    private static List<Person__c> getRelatedPersons(Set<String> relatedPersonIds) {
        return [
                SELECT Id,
                        Name,
                        INT_FirstName__c,
                        INT_MiddleName__c,
                        INT_LastName__c, 
                        INT_DateOfBirth__c,
                        CRM_Account__c, 
                        CRM_Account__r.Name
                FROM Person__c
                WHERE Name IN :relatedPersonIds
        ];
    }

    private static String getFamilyRelationJSONString(Id personId) {
        return [
                SELECT Id,
                        INT_FamilyRelations__c
                FROM Person__c
                WHERE Id = :personId
        ].INT_FamilyRelations__c;
    }

}