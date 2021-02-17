/**
 * @description Service class for doing callouts to Microsoft Graph related to AD Groups
 */
public with sharing class AdGroupService {
    private final string API_CONFIG_NAME = 'Microsoft_Graph_API'; //API Config name to set when using the ApiController

    /**
     * @description Get members of group id submitted
     * @author Frode Hoen | 9-2-2021
     * @param groupId [String reference to ad group id]
     * @return AdGroupResponse [Wrapper holding success (true|false), response from Microsoft Graph and error message with reference to application log]
     */
    public AdGroupResponse getAdGroupMembers(String groupId) {
        
        AdGroupResponse resp=new AdGroupResponse();
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('group-id',groupId);

        ApiController apiCtrl = new ApiController();

        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_GROUP_MEMBERS', paramMap);
        String serviceToken = Test.isRunningTest() ? 'TEST_TOKEN' : CachedTokensHandler.getAccessToken();
       
        apiCtrl.addHeader('Authorization', 'Bearer ' + serviceToken);

        apiCtrl.doCallout();
        
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();

        bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        
        if(statusCode == 200) {
           
            resp.success = true;
            resp.parse(bodyString);
           
        } else {
            
            String params = '[groupId: ' + groupId +']';
            String errorRef = logError(apiCtrl.getResponse(), 'Error from AdGroupService.getAdGroupMembers Parameters: ' + params);
            resp.errorMessage = 'Kunne ikke hente AD-gruppe medlemmer fra Microsoft Graph. Referanse til feil: ' + errorRef;
            
            if(statusCode == 404) {
                resp.errorMessage = 'Kunne ikke finne endepunkt. Referanse til feil: ' + errorRef;
            } else if(statusCode == 500) {
                resp.errorMessage = 'Noe gikk galt ved henting av AD-gruppemedlemmer. Referanse til feil: ' + errorRef;
            }
        }
        return resp;
    }


    /**
     * @description Create a log entry for troubleshooting
     * @author Frode Hoen | 8-2-2021
     * @param resp
     * @param message [Message to add to the log]
     * @return String [UUID of the log]
     */
    private String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message + '\n ' + 'Status: ' + resp.getStatus() + '\n' + 'Body: ' + resp.getBody(), null);
        errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
        logger.publish();

        return errorRef;
    }

    public class AdGroupResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public List<String> usernames;
        @AuraEnabled public String errorMessage;

        public AdGroupResponse() {
            this.success = false;
            this.usernames=null;
            this.errorMessage = null;
        }

        public void parse(String json){
            System.JSONParser parser = System.JSON.createParser(json);
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == '@odata.context') {
    
                        } else if (text == 'value') {
                            usernames = arrayOfRecord(parser);
                    }
                }
            }
        }
        }

        private List<String> arrayOfRecord(System.JSONParser p) {
            List<String> res = new List<String>();
            if (p.getCurrentToken() == null) p.nextToken();
            while (p.nextToken() != System.JSONToken.END_ARRAY) {
                res.add(getUsername(p).toLowerCase());
            }
            return res;
        }

        private String getUsername(System.JSONParser parser){
            String res=null;
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					    if (text == 'userPrincipalName') {
							res= parser.getText();
						} 
					}
				}
			}
            return res;
        }
    }
}