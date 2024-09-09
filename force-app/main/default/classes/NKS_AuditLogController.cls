public without sharing class NKS_AuditLogController {
    public static final Id USERID = UserInfo.getUserId();
    public static final String KNOWLEDGE_LOOKUP_FIELD = 'Knowledge__c';
    public static final String ANNOUNCEMENT_LOOKUP_FIELD = 'Announcement__c';
    public static final String KNOWLEDGE_AUDIT_LOG = 'Knowledge Audit Log';
    public static final String ANNOUNCEMENT_AUDIT_LOG = 'Announcement Audit Log';

    private static LoggerUtility logger = new LoggerUtility('NKS Audit Log');

    @AuraEnabled
    public static void createAuditLog(Id recordId, String lookupField) {
        try {
            NKS_Audit_Log__c al = new NKS_Audit_Log__c();
            if (lookupField == KNOWLEDGE_LOOKUP_FIELD) {
                al.RecordTypeId = getRecordTypeId(KNOWLEDGE_AUDIT_LOG);
            }
            else if (lookupField == ANNOUNCEMENT_LOOKUP_FIELD) {
                al.RecordTypeId = getRecordTypeId(ANNOUNCEMENT_AUDIT_LOG);
            }
            else {
                return;
            }
            
            al.Announcement__c = recordId;
            al.User__c = USERID;
            al.Operation__c = 'View';
            
            Database.SaveResult sr = Database.insert(al, false);
            if (!sr.isSuccess()) {
                logErrorMessage (sr);
            }
        } catch (Exception e) {
            logger.error('Failed to create Audit Log record: ' + e.getMessage(), null, CRM_ApplicationDomain.Domain.NKS);
    } finally {
        logger.publish();
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

    private static void logErrorMessage (Database.SaveResult sr) {
        String errorMessage = 'The following error has occurred under creation of Audit Log record:\n';
        for(Database.Error error : sr.getErrors()) {
            errorMessage += error.getStatusCode() + ': ' + error.getMessage() + '\n';
        }
        logger.error(errorMessage, null, CRM_ApplicationDomain.Domain.NKS);
    }
}
