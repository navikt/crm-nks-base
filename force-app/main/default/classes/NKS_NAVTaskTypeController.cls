public with sharing class NKS_NAVTaskTypeController {
    @AuraEnabled(cacheable=true)
    public static Map<Common_Code__c, String> getTaskTypes(String themeCode) {
        Map<Common_Code__c, String> returnmap = new Map<Common_Code__c, String>();
        List<String> validtasktypecodes = new List<String>{
            'VUR_KONS_YTE',
            'VURD_HENV',
            'KONT_BRUK'
        };
        NKS_NavTaskManager.NavTaskTypeResponse response = NKS_NavTaskManager.getTaskTypes(
            themeCode
        );
        List<Common_Code__c> tasktypes = [
            SELECT CRM_Code__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = :'Oppgavetyper' AND CRM_Code__c IN :validtasktypecodes
        ];
        System.debug('SUCCESS: ' + response.success);

        if (response.success) {
            List<String> validtasktypes = new List<String>();
            for (NKS_NavTaskManager.OppgaveTypeResponse o : response.tasktypes) {
                validtasktypes.add(o.oppgavetype);
            }
            for (Common_Code__c c : tasktypes) {
                if (validtasktypecodes.contains(c.CRM_Code__c))
                    returnmap.put(c, c.Name);
            }
        } else {
            for (Common_Code__c c : tasktypes) {
                returnmap.put(c, c.Name);
            }
        }
        return returnmap;
    }
}
