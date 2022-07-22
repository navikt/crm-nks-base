public without sharing class NKS_NavTaskSyncCtrl {
    /**
     * Calls the OppgaveSyncController to sync open and assigned "oppgaver" to the running user.
     * @author Stian Ruud Schikora | 05-30-2022
     **/
    @AuraEnabled
    public static void syncOpenAndAssigned() {
        try {
            User runningUser = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE Id = :UserInfo.getUserId()];
            CRM_OppgaveQuery oppgQuery = new CRM_OppgaveQuery();
            oppgQuery.tilordnetRessurs = runningUser.CRM_NAV_Ident__c;
            oppgQuery.statuskategori = OppgaveStatuskategori.AAPEN;

            CRM_OppgaveSyncController.doOppgaveSync(JSON.serialize(oppgQuery));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
