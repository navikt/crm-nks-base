public class NKS_ThemeUtils {

    @AuraEnabled(Cacheable=true)
    public static Map<String, List<Theme__c>> getThemes(){
        Map<String, List<Theme__c>> groupThemeMap = new Map<String, List<Theme__c>>();

        for (Theme__c theme : [SELECT Id, Name, CRM_Theme_Group__c, toLabel(CRM_Theme_Group__c) themeGroupLabel FROM Theme__c WHERE CRM_Active__c = true]) {
            if(groupThemeMap.containsKey(theme.CRM_Theme_Group__c)){
                List<Theme__c> mapThemes = groupThemeMap.get(theme.CRM_Theme_Group__c);
                mapThemes.add(theme);
                groupThemeMap.put(theme.CRM_Theme_Group__c, mapThemes);
            }
            else{
                groupThemeMap.put(theme.CRM_Theme_Group__c, new List<Theme__c>{theme});
            }
        }

        return groupThemeMap;
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, List<Subtheme__c>> getSubthemes(){
       Map<String, List<Subtheme__c>> subthemeMap = new Map<String, List<Subtheme__c>>();

       for (Subtheme__c subtheme : [SELECT Id, CRM_Theme__c, Name FROM Subtheme__c WHERE CRM_Active__c = true]) {
           if(subthemeMap.containsKey(subtheme.CRM_Theme__c)){
               List<Subtheme__c> mapSubthemes = subthemeMap.get(subtheme.CRM_Theme__c);
               mapSubthemes.add(subtheme);
               subthemeMap.put(subtheme.CRM_Theme__c, mapSubthemes);
           }
           else{
                subthemeMap.put(subtheme.CRM_Theme__c, new List<Subtheme__c>{subtheme});
           }
       }

       return subthemeMap;
    }

}
