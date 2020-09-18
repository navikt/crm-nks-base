public with sharing class NKS_QuickTextSearchController {

    @AuraEnabled
	public static List<QuickText> searchRecords( String search ) {
        List<QuickText> quickTexts = new List<QuickText>(); 
        for(QuickText qt : [SELECT Id, Name, Message FROM QuickText]){
            if(qt.Message.contains(search) || qt.Name.contains(search)){
                quickTexts.add(qt); 
            }
        }
		return quickTexts;
	}
}
