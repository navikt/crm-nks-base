public with sharing class NKS_NAVTaskTypeController {
    @AuraEnabled(cacheable=true)
    public static List<CommonCode> getTaskTypes(String themeCode) {
        List<CommonCode> commoncodes = new List<CommonCode>();
        List<String> validtasktypecodes = new List<String>{ 'VUR_KONS_YTE', 'VURD_HENV', 'KONT_BRUK' };

        NKS_NavTaskManager.NavTaskTypeResponse response = new NKS_NavTaskManager.NavTaskTypeResponse();
        if (String.isBlank(themeCode)) {
            response.success = false;
        } else {
            response = NKS_NavTaskManager.getTaskTypes(themeCode);
        }

        List<Common_Code__c> tasktypes = [
            SELECT CRM_Code__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = :'Oppgavetyper' AND CRM_Code__c IN :validtasktypecodes
        ];

        if (response.success) {
            List<String> validtasktypes = new List<String>();
            for (NKS_NavTaskManager.OppgaveTypeResponse o : response.tasktypes) {
                validtasktypes.add(o.oppgavetype);
            }
            commoncodes = createCommonCodes(tasktypes, validtasktypes);
        } else {
            commoncodes = createCommonCodes(tasktypes, validtasktypecodes);
        }
        return commoncodes;
    }

    private static List<CommonCode> createCommonCodes(List<Common_Code__c> tasktypes, List<String> validtasktypes) {
        List<CommonCode> commoncodes = new List<CommonCode>();
        for (Common_Code__c c : tasktypes) {
            CommonCode cc = new CommonCode();
            if (validtasktypes.contains(c.CRM_Code__c)) {
                cc.id = c.Id;
                cc.commoncode = c.CRM_Code__c;
                cc.name = c.Name;
                commoncodes.add(cc);
            }
        }
        return commoncodes;
    }

    public class CommonCode {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String commoncode;
        @AuraEnabled
        public String name;
    }
}
