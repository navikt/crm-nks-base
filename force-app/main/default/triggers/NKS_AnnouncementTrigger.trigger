trigger NKS_AnnouncementTrigger on NKS_Announcement__c(before delete) {
    for (NKS_Announcement__c a : Trigger.old) {
        if (a.NKS_TypeFormula__c == 'Nyhet') {
            a.AddError('Du kan ikke slette nyhetsartikler.');
        }
    }
}
