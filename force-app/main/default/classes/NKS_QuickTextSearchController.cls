public with sharing class NKS_QuickTextSearchController {

    @AuraEnabled
	public static List<QuickText> searchRecords( String search ) {
        List<QuickText> quickTexts = new List<QuickText>(); 
        for(QuickText qt : [SELECT Id, Name, Message FROM QuickText]){
            if(qt.Message.toLowerCase().contains(search.toLowerCase()) || qt.Name.toLowerCase().contains(search.toLowerCase())){
                quickTexts.add(qt); 
            }
        }
		return quickTexts;
    }
     
    @AuraEnabled(cacheable = true)
    public static List<QuickText> getRecentlyViewedRecords() {
        return [
            SELECT Id, Name, Message, LastViewedDate 
            FROM QuickText
            WHERE LastViewedDate !=null
            ORDER BY LastViewedDate DESC LIMIT 5 ];
    }
}
