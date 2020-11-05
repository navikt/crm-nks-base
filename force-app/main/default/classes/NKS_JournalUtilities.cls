//Utility class used to allow flow to retrieve the AD token from the session cache
public class NKS_JournalUtilities {

    @InvocableMethod(label = 'Journal Utility Request' description = 'Retrieve AD token or generate compliant document' category = 'Journal')
    public static List<String> handleRequest(List<utilityRequest> request) {
        List<String> returnList = new List<String>();
        
        switch on (request[0].requestType){
            when 'AD_TOKEN' {
                returnList.add(getADToken());
            }
            when 'GENERATE_DOCUMENT' {
                returnList.add(generateDocument(request[0].documentString));
            }
        }

        return returnList;
    }

    /**
    * @description: Retrieves the AD token for the logged in user from the session cache
    * @author Stian Ruud Schikora | 09-17-2020 
    * @return String [AD token]
    **/
    public static String getADToken() {
        String ADtoken = Test.isRunningTest() ? null : CachedTokensHandler.getServiceToken('Dokarkiv');
        return ADtoken;
    }

    /**
    * @description: Base 64 encode an input string, used for generating valid document for journal API
    * @author Stian Ruud Schikora | 09-17-2020 
    * @param stringToEncode [STRING]
    * @return String 
    **/
    public static String generateDocument(String documentString) {
        return EncodingUtil.base64Encode(blob.toPdf(documentString));
    }

    public class utilityRequest{

        public utilityRequest(){
            this.requestType = null;
            this.documentString = null;
        }

        public utilityRequest(String requestType, String documentString){
            this.requestType = requestType;
            this.documentString = documentString;
        }

        @invocableVariable(label = 'Type of Apex action to perform (Valid actions are: AD_TOKEN and GENERATE_DOCUMENT)' description = 'Valid actions are: AD_TOKEN and GENERATE_DOCUMENT' required = true)
        public String requestType;

        @invocableVariable
        public String documentString;
    }
    
}
