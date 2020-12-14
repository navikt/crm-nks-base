public with sharing class NKS_NavUnitSingleController {
    private static NKS_NorgNavUnitService service {get{if(null == service){service = new NKS_NorgNavUnitService();}return service;} set;}

    @AuraEnabled(cacheable=true)
    public static NKS_NorgNavUnitService.NavUnitResponse findUnit(String field, String parentObject, String parentRecordId, String type) {
        switch on type {
            when 'PERSON_LOCATION' {
                return getNavUnitFromPerson(field,parentObject,parentRecordId);
            }
            when 'UNIT_NUMBER' {
                return getNavUnitFromNavUnitNumbers(field,parentObject,parentRecordId);
            }
        }
        
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static NKS_NorgNavUnitService.NavUnitContactInformationResponse getContactInformation(String unitNumber) {
        return service.getNavUnitContactInformation(unitNumber);
    }

    private static NKS_NorgNavUnitService.NavUnitResponse getNavUnitFromPerson(String field, String parentObject, String parentRecordId) {        
        List<Object> objectList = getQueryValue(field, parentObject, parentRecordId);

        if(true == objectList.isEmpty()) {
            NKS_NorgNavUnitService.NavUnitResponse resp = new NKS_NorgNavUnitService.NavUnitResponse();
            resp.errorMessage = 'Kunne ikke finne bruker.';
            return resp;
        }

        Id personId = (Id) objectList[0];

        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(service);
        return util.getNavUnitFromPerson(personId);
    }

    private static NKS_NorgNavUnitService.NavUnitResponse getNavUnitFromNavUnitNumbers(String field, String parentObject, String parentRecordId) {        
        List<Object> objectList = getQueryValue(field, parentObject, parentRecordId);

        if(true == objectList.isEmpty()) {
            NKS_NorgNavUnitService.NavUnitResponse resp = new NKS_NorgNavUnitService.NavUnitResponse();
            resp.errorMessage = 'Kunne ikke finne enhetsnummer.';
            return resp;
        }

        String navUnitNumber = (String) objectList[0];

        return service.getNavUnitFromUnitNumber(navUnitNumber);
    }


    /**
     * *Example
     * - field = 'Account.CRM_Person__c';
     * - objString = 'Case';
     * - recordId = '5001X000007xMSuQAM';
     * - relation = 'Id';
     */
    private static List<Object> getQueryValue(String field, String parentObject, String parentRecordId) {
        List<Object> values = new List<Object>();
        String queryString = 'SELECT ' + field + ' FROM ' + parentObject + ' WHERE Id = :parentRecordId';
        List<SObject> objList = Database.query(String.escapeSingleQuotes(queryString));

            for(SObject obj : objList) {
                Object value = getFieldValue(obj,field);
                if(null != obj) {
                    values.add(value);
                }
            }

        return values;
    }

    private static Object getFieldValue(SObject obj, String fieldName) {
        List<String> fieldNameList = fieldName.split('\\.');

        if(1 < fieldNameList.size()) {
            return getFieldValue(obj.getSObject(fieldNameList.remove(0)), String.join(fieldNameList, '.'));
        }

        return obj.get(fieldNameList[0]);
    }
}
