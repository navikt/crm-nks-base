trigger AuditLogAnnouncement on NKS_Audit_Log__c(before delete) {
    for (NKS_Audit_Log__c a : Trigger.old) {
        a.addError('You cannot delete Audit Logs.');
    }
}
