//Utility class used to allow flow to retrieve the AD token from the session cache
public class NksJournalUtilities {

    @InvocableMethod(label = 'Journal Utility Request' description = 'Retrieves the users AD token from the session cache' category = 'Journal')
    public static List<String> handleRequest(List<utilityRequest> request) {
        List<String> returnList = new List<String>();
        
        switch on (request[0].requestType){
            when 'AD_TOKEN' {
                returnList.add(getADToken());
            }
            when 'ENCODE_BASE_64' {
                returnList.add(base64Encode(request[0].stringToEncode));
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
        String ADtoken;
//String accessToken = Auth.AuthToken.getAccessToken('PROVIDERID',  'Open Id Connect')
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.tokens');
        ADtoken = (String) sessionPart.get('ADTOKEN');
System.debug('TOKEN: ' + ADtoken);

        return ADtoken;
    }

    /**
    * @description: Base 64 encode an input string, used for generating valid document for journal API
    * @author Stian Ruud Schikora | 09-17-2020 
    * @param stringToEncode [STRING]
    * @return String 
    **/
    public static String base64Encode(String stringToEncode) {
        return EncodingUtil.base64Encode(blob.valueOf(stringToEncode));
    }

    public class utilityRequest{

        public utilityRequest(String requestType, String stringToEncode){
            this.requestType = requestType;
            this.stringToEncode = stringToEncode;
        }

        @invocableVariable(label = 'Type og Apex action to perform' description = 'Valid actions are: AD_TOKEN and ENCODE_BASE_64' required = true)
        public String requestType;

        @invocableVariable
        public String stringToEncode;
    }
    
}
