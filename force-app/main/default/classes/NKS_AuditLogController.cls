public without sharing class NKS_AuditLogController {
    public static final Id USERID = UserInfo.getUserId();
    public static final String KNOWLEDGE_LOOKUP_FIELD = 'Knowledge__c';
    public static final String ANNOUNCEMENT_LOOKUP_FIELD = 'Announcement__c';
    public static final String KNOWLEDGE_AUDIT_LOG = 'Knowledge Audit Log';
    public static final String ANNOUNCEMENT_AUDIT_LOG = 'Announcement Audit Log';

    @AuraEnabled
    public static void createAuditLog(Id recordId, String lookupField) {
        try {
            if (lookupField == KNOWLEDGE_LOOKUP_FIELD) {
                Id recordTypeId = getRecordTypeId(KNOWLEDGE_AUDIT_LOG);
                NKS_Audit_Log__c al = new NKS_Audit_Log__c();
                al.RecordTypeId = recordTypeId;
                al.Knowledge__c = recordId;
                al.User__c = USERID;
                al.Operation__c = 'View';
                insert al;
            }

            if (lookupField == ANNOUNCEMENT_LOOKUP_FIELD) {
                Id recordTypeId = getRecordTypeId(ANNOUNCEMENT_AUDIT_LOG);
                NKS_Audit_Log__c al = new NKS_Audit_Log__c();
                al.RecordTypeId = recordTypeId;
                al.Announcement__c = recordId;
                al.User__c = USERID;
                al.Operation__c = 'View';
                insert al;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Problem creating NKS_Audit_Log__c: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer countViews(Id recordId, String lookupField) {
        List<Id> originalList = new List<Id>();
        Set<Id> resultList = new Set<Id>();
        Map<String, Object> bindParams = new Map<String, Object>{ 'recordId' => recordId };
        String query =
            'SELECT COUNT_DISTINCT(User__c) nmbOfUniqueViews FROM NKS_Audit_Log__c WHERE ' +
            lookupField +
            ' = :recordId';
        try {
            AggregateResult[] countResult = Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE);
            return Integer.valueOf(countResult[0].get('nmbOfUniqueViews'));
        } catch (Exception ex) {
            throw new AuraHandledException('Problem counting article veiws: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isKnowledgeUser() {
        try {
            return [SELECT Id FROM User WHERE UserPermissionsKnowledgeUser = TRUE AND Id = :USERID]?.Id != null;
        } catch (Exception e) {
            throw new AuraHandledException('Problem checking knowledge user: ' + e.getMessage());
        }
    }

    @TestVisible
    private static String getRecordTypeId(String recordTypeName) {
        return Schema.SObjectType.NKS_Audit_Log__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }
}
