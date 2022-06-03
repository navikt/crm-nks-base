public with sharing class NKS_FagsystemController {
    @AuraEnabled(cacheable=true)
    public static string getPersonId(String recordId, String relatedField, String objectApiName) {
        try {
        String query = 'SELECT ' + getField(relatedField) + ' FROM ' + objectApiName + ' WHERE Id = :recordId';
        System.debug(query);
        List<SOBject> objs = Database.query(query);
        return getIdFromRelationshipQuery(objs, relatedField);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static string getField(String relatedField) {
        if (relatedField == 'Id') {
            return 'CRM_Person__c';
        }
        return relatedField.replace('__c', '__r') + '.CRM_Person__c';
    }

    public static string getIdFromRelationshipQuery(List<SObject> objs, String relatedField) {
        SOBject currentObj = objs[0];
        List<String> splitQuery = getField(relatedField).split('\\.');
        System.debug(splitQuery);
        for (Integer i = 0; i < splitQuery.size() - 1; i++) {
            currentObj = currentObj.getSObject(splitQuery[i]);
        }
        return (String) currentObj.get(splitQuery[splitQuery.size() - 1]);
    }
}
