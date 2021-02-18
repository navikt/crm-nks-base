public class NKS_ThemeUtils {
    /**
     * @description: Retrieves all active theme groups, themes and subthemes and returns
     * and returns in a hierarchical mapped wrapper class
     * @author Stian Ruud Schikora | 11-20-2020
     * @return Categories
     **/
    @AuraEnabled(Cacheable=true)
    public static Categories getCategorization() {
        List<Common_Code__c> themeGroups = [
            SELECT Id, Name, CRM_Code__c, CRM_Code_Set__c
            FROM Common_Code__c
            WHERE CRM_Code_set__c = 'Temagrupper' AND CRM_Active__c = TRUE
            ORDER BY Name
        ];
        List<Common_Code__c> themesAndSubthemes = [
            SELECT
                Id,
                Name,
                CRM_Code__c,
                CRM_Code_Set__c,
                CRM_Parent_Code__r.CRM_Code__c,
                (
                    SELECT
                        Id,
                        Name,
                        CRM_Code__c,
                        CRM_Code_Set__c,
                        CRM_Parent_Code__r.CRM_Code__c
                    FROM Child_Codes__r
                    WHERE
                        CRM_Code_Set__c = 'Behandlingstema'
                        AND CRM_Active__c = TRUE
                    ORDER BY Name
                )
            FROM Common_Code__c
            WHERE CRM_Code_set__c = 'Tema' AND CRM_Active__c = TRUE
            ORDER BY Name
        ];

        Map<String, List<Common_Code__c>> themeMap = new Map<String, List<Common_Code__c>>();
        Map<String, List<Common_Code__c>> subthemeMap = new Map<String, List<Common_Code__c>>();

        for (Common_Code__c theme : themesAndSubthemes) {
            if (themeMap.containsKey(theme.CRM_Parent_Code__r.Id)) {
                List<Common_Code__c> mapThemes = themeMap.get(
                    theme.CRM_Parent_Code__r.Id
                );
                mapThemes.add(theme);
                themeMap.put(theme.CRM_Parent_Code__r.Id, mapThemes);
            } else {
                themeMap.put(
                    theme.CRM_Parent_Code__r.Id,
                    new List<Common_Code__c>{ theme }
                );
            }

            for (Common_Code__c subtheme : theme.Child_Codes__r) {
                if (subthemeMap.containsKey(subtheme.CRM_Parent_Code__r.Id)) {
                    List<Common_Code__c> mapSubthemes = subthemeMap.get(
                        subtheme.CRM_Parent_Code__r.Id
                    );
                    mapSubthemes.add(subtheme);
                    subthemeMap.put(
                        subtheme.CRM_Parent_Code__r.Id,
                        mapSubthemes
                    );
                } else {
                    subthemeMap.put(
                        subtheme.CRM_Parent_Code__r.Id,
                        new List<Common_Code__c>{ subtheme }
                    );
                }
            }
        }

        return new Categories(themeGroups, themeMap, subthemeMap);
    }

    @testVisible
    private class Categories {
        @AuraEnabled
        public List<Common_Code__c> themeGroups;
        @AuraEnabled
        public Map<String, List<Common_Code__c>> themeMap; //Mapping a theme group Id to list of themes
        @AuraEnabled
        public Map<String, List<Common_Code__c>> subthemeMap; //Mapping a theme Id to a list of subthemes

        public Categories(
            List<Common_Code__c> themeGroups,
            Map<String, List<Common_Code__c>> themeMap,
            Map<String, List<Common_Code__c>> subthemeMap
        ) {
            this.themeGroups = themeGroups;
            this.themeMap = themeMap;
            this.subthemeMap = subthemeMap;
        }
    }
}
