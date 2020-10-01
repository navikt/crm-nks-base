public class NKS_RelatedListController {
    
    /**
    * @description: Returns a list of records 
    * @author Stian Ruud Schikora | 09-29-2020 
    * @param fieldNames [List<String : Fields to retrieve from the returned records]
    * @param parentId [String : Id of the record the LWC is displayed on]
    * @param objectApiName  [String : API name of object to return]
    * @param relationField  [String : Field API name relating the record to the parent]
    * @param parentRelationField [String : Field API name relating the parent to the child(s)]
    * @param parentObjectApiName [String : Object API name of the record the LWC is displayed on] 
    * @param filterConditions [String : Optional filter conditions]
    * @return List<sObject> 
    **/
    @AuraEnabled
    public static List<sObject> getRelatedList(List<String> fieldNames, String parentId, String objectApiName, String relationField, String parentRelationField, String parentObjectApiName, String filterConditions){
        String query = 'SELECT ';

        //Appending fields to query string
        for (String field : fieldNames) {
            query += field +  ', ';
        }

        query = query.removeEndIgnoreCase(', ') + ' FROM ' + objectApiName + ' WHERE ';
        query += String.isNotBlank(filterConditions) ? 
                    filterConditions.trim() + ' AND ' : '';
        query +=  relationField + ' IN (SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = \'' + parentId + '\')';

        List<sObject> returnList = Database.query(query);
        return returnList;
    }
}
