public with sharing class NKS_NAVTaskTypeController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTaskTypes(String themeCode) {
        Map<String, String> returnmap = new Map<String, String>();

        returnmap.put('test', 'test1');
        returnmap.put('test2', 'test13');

        NKS_NavTaskManager.NavTaskResponse response = NKS_NavTaskManager.getTaskTypes(themeCode);
        System.debug(response);

        return returnmap;
    }
}
