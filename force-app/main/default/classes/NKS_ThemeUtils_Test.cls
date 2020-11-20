@isTest
public class NKS_ThemeUtils_Test {

    @TestSetup
    static void makeData(){
        Common_Code__c themeGroup = (Common_Code__c) UTIL_TestDataFactory.createRecord(new Common_Code__c(Name='Arbeid', CRM_Code_Set__c = 'Temagrupper', CRM_Code__c = 'ARBD'));
        List<Common_Code__c> themes = new List<Common_Code__c>{new Common_Code__c(Name='AAP', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'ab00001', CRM_Parent_Code__c = themeGroup.Id)};
        themes.add(new Common_Code__c(Name='Dagpenger', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'ab00002', CRM_Parent_Code__c = themeGroup.Id));
        themes = (List<Common_Code__c>) UTIL_TestDataFactory.createRecordList(themes);

        List<Common_Code__c> subthemes = new List<Common_Code__c>{new Common_Code__c(Name='Utbetaling', CRM_Code_Set__c = 'Behandlingstema', CRM_Code__c = 'ae00001', CRM_Parent_Code__c = themes[0].Id)};
        subthemes.add(new Common_Code__c(Name='tilbakebetaling', CRM_Code_Set__c = 'Behandlingstema', CRM_Code__c = 'ae00002', CRM_Parent_Code__c = themes[0].Id));
        UTIL_TestDataFactory.createRecordList(subthemes);
    }

    @isTest
    static void testGetCategorization() {

        Test.startTest();
        NKS_ThemeUtils.Categories categories = NKS_ThemeUtils.getCategorization();
        Test.stopTest();

        System.assertEquals('Arbeid', categories.themeGroups[0].Name);
    }
}
