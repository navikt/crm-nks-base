trigger AuditLogAnnouncement on NKS_Audit_Log__c (before delete) {
	for (NKS_Audit_Log__c a : trigger.old) {
        a.AddError('You cannot delete Audit Logs.');
    }
}