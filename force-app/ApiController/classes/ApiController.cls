public virtual class ApiController {
    
    protected HttpRequest req = new HttpRequest();
    protected HttpResponse resp;
    protected String baseEndpoint;      //Endpoint to be used for the HTTP request
    protected String requestEndpoint;   //Request endpoint is the base endpoint with potential url parameter additions
    protected Integer HTTP_CALLOUT_TIMEOUT = 60000;
    protected Boolean urlParamsSet = false; //Boolean to determine if the url parameters has been set already
    private Boolean isMockActive =false; //True if the mock is active
    private HttpResponse mockResponse; //Mock response if mocks are turned on.
    
    /**
    * @description: Performs the callout to the defined endpoint. Throws exception if there are
    * required parameters missing from the request
    * @author Stian Ruud Schikora | 08-16-2020 
    * @return HttpResponse 
    **/
    public void doCallout() {
        if(String.isBlank(baseEndpoint)) {
            throw new InvalidOperationException('Cannot perform callout without endpoint');
        }
        else if(String.isBlank(req.getMethod())) {
            throw new InvalidOperationException('Cannot perform callout without defining REST method');
        }
        req.setEndpoint(requestEndpoint);

        if(false == this.isMockActive) {
            this.resp = new Http().send(req);
        } else {
            this.resp = this.mockResponse;
        }
    }

    public void initRequest(String apiConfigName, String serviceName) {
        initRequest(apiConfigName, serviceName, null);
    }

    /**
    * @description: Initializes a HTTP request with method and endpoint from either named credential of basic endpoint
    * @author Stian Ruud Schikora | 10-15-2020 
    * @param apiConfigName 
    * @param serviceName 
    * @param paramMap 
    **/
    public void initRequest(String apiConfigName, String serviceName, Map<String, String> paramMap) {
        API_Base_Configuration__mdt baseConfig = Test.isRunningTest() ? getApiConfiguration('TEST_CONFIG', 'TEST_SERVICE_CONFIG') : getApiConfiguration(apiConfigName, serviceName);
        API_Service_Configuration__mdt serviceConfig = baseConfig.API_Service_Configurations__r[0];
        String servicePath = serviceConfig.Has_Path_Parameters__c ? replacePathParameters(serviceConfig.Service_Path__c, paramMap) : serviceConfig.Service_Path__c;
        setMethod(serviceConfig.HTTP_Method__c);

        if(String.isNotBlank(baseConfig.Named_Credential__c)) {
            setNamedCredential(baseConfig.Named_Credential__c, servicePath);
        }
        else{
            setEndpoint(baseConfig.Base_Endpoint__c + servicePath);
        }

        if(baseConfig.Use_Gateway__c) addApiGwHeader();

        setMockSettings(serviceName);
    }

    /**
    * @description: Retrieves the correct API configuration from custom metadata
    * @author Stian Ruud Schikora | 10-15-2020 
    * @param apiConfigName 
    * @param serviceName 
    * @return API_Base_Configuration__mdt 
    **/
    private API_Base_Configuration__mdt getApiConfiguration(String apiConfigName, String serviceName) {
        API_Base_Configuration__mdt baseConfig = [SELECT Base_Endpoint__c,Base_Endpoint_Test__c, Named_Credential__c, Named_Credential_Test__c, Use_Gateway__c,
                                                        (SELECT Service_Path__c, Has_Path_Parameters__c, HTTP_Method__c FROM API_Service_Configurations__r WHERE DeveloperName =: serviceName)
                                                         FROM API_Base_Configuration__mdt WHERE DeveloperName =: apiConfigName LIMIT 1];

        if(baseConfig.API_Service_Configurations__r.isEmpty()) throw new NoServiceConfigurationException('No service configuration found for name: ' + serviceName);

        return baseConfig;
    }

    /**
    * @description: Replaces the path parameters with the parameters from the paramMap
    * @author Stian Ruud Schikora | 10-15-2020 
    * @param inputPath [STRING]
    * @param paramMap [[Map<String, String>]]
    * @return String [STRING: Updates path]
    **/
    public String replacePathParameters(String inputPath, Map<String, String> paramMap) {
        validatePathInput(inputPath, paramMap); //Throws an exception if any parameters are missing

        String outputPath = inputPath;
        for (String param : paramMap.keySet()) {
            outputPath = outputPath.replace('{' + param + '}', paramMap.get(param));
        }

        return outputPath;
    }

    /**
    * @description: Validates if the the paramMap includes all necessary params for the input Path
    * @author Stian Ruud Schikora | 10-15-2020 
    * @param inputPath 
    * @param paramMap 
    **/
    private void validatePathInput(String inputPath, Map<String, String> paramMap) {
        Pattern p = Pattern.compile('\\{.+?\\}');

        Matcher m = p.matcher(inputPath);
        while(m.find()) {
            String matcherParam = m.group(0).remove('{').remove('}');
            if(paramMap == null || !paramMap.containsKey(matcherParam)) throw new InvalidPathParamException('Missing parameter in paramMap: ' + matcherParam);
        }
    }

    /**
    * @description: Getter for the response variable
    * @author Stian Ruud Schikora | 08-27-2020 
    * @return HttpResponse 
    **/
    public HttpResponse getResponse() {
        return this.resp;
    }

    /**
    * @description: getter for the request variable 
    * @author Stian Ruud Schikora | 08-27-2020 
    * @return HttpRequest 
    **/
    public HttpRequest getRequest() {
        return this.req;
    }
    
    /**
    * @description: Sets the request timeout, defaults to 60s 
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param timeout [INT: timout im ms]
    * @return ApiController 
    **/
    public ApiController setTimeout(Integer timeout) {
        this.HTTP_CALLOUT_TIMEOUT = timeout;
        return this;
    }

    /**
    * @description: Sets the desired http method for the request 
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param httpMethod [STRING: Http method (POST, GET, PATCH, PUT, DELETE)]
    * @return ApiController 
    **/
    public ApiController setMethod(String httpMethod) {
        req.setMethod(httpMethod);
        return this;
    }
    
    /**
    * @description: Sets the endpoint parameter for the callout request
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param endpoint [STRING: Callout endpoint]
    * @return ApiController 
    **/
    public ApiController setEndpoint(String endpoint) {
        this.baseEndpoint = endpoint;
        this.requestEndpoint = endpoint;
        return this;
    }

    /**
    * @description: Sets the request body
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param endpoint [STRING: request body]
    * @return ApiController 
    **/
    public ApiController setBody(String body) {
        req.setBody(body);
        return this;
    }

    public String getEndpoint() {
        return baseEndpoint;
    }

    /**
    * @description: Setting the endpoint paramater to use named credential for authentication.
    * Remember to include the '/' in the service path parameter
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param credentialName [Name of the named credential to be used]
    * @param servicePath    [Path of the service to be called]
    * @return ApiController [SELF]
    **/
    public ApiController setNamedCredential(String credentialName, String servicePath) {
        this.setEndpoint('callout:' + credentialName + servicePath);
        return this;
    }

    /**
    * @description: Adds the appropriate on-behalf-of token to the authorization header
    * of the request 
    * @author Stian Ruud Schikora | 10-29-2020 
    * @param serviceName [Name of service (Must match field name on custom setting: AccessTokenScope__c)]
    * @return ApiController 
    **/
    public ApiController addServiceAuthHeader(String serviceName) {
        String serviceToken = Test.isRunningTest() || true == this.isMockActive ? 'TEST_TOKEN' : CachedTokensHandler.getServiceToken(serviceName);
        return addHeader('Authorization', 'Bearer ' + serviceToken);
    }


    /**
    * @description: Dynamically adds the ApiGWKey to the request headers
    * Only usable if endpoint is set using named credential
    * @author Stian Ruud Schikora | 11-24-2020 
    * @return ApiController 
    **/
    public ApiController addApiGwHeader() {
        return addHeader('Ocp-Apim-Subscription-Key', '{!$Credential.Password}');
    }
	
    /**
    * @description: Adds url parameters to the request
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param key    [STRING: parameter key]
    * @param value  [STRING: parameter value]
    * @return ApiController 
    **/
    public ApiController addUrlParam(String key, String value) {
        if(String.isBlank(baseEndpoint)) {
            throw new InvalidOperationException('Cannot add url parameters before setting endpoint');
        }
        else {
            //If no parameters have been set already, then we need to add the '?'
            if(!urlParamsSet) {
            	requestEndpoint += '?';
            }
            requestEndpoint += key + '=' + value;
            urlParamsSet = true;
        }
        
        return this;
    }
    
    /**
    * @description: Adds a map of url parameters to the request. Be aware that calling this will wipe away
    * parameters added by the addUrlParam method 
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param urlParams  [Map<String, String>: Map of key -> value pairs]
    * @return ApiController 
    **/
    public ApiController setUrlParams(Map<String, String> urlParams) {
        if(String.isBlank(baseEndpoint)) {
            throw new InvalidOperationException('Cannot add url parameters before setting endpoint');
        }
        //Adding all additional urlParams to endpoint
        if(urlParams != null && !urlParams.isEmpty()){
            requestEndpoint = baseEndpoint + '?';
            for(String param : urlParams.keySet()){
                if(String.isNotBlank(urlParams.get(param))){
                    requestEndpoint += param + '=' + urlParams.get(param) + '&';
                }
            }
            requestEndpoint = requestEndpoint.removeEndIgnoreCase('&'); //Removes the last '&'' from the endpoint string
            urlParamsSet = true;
        }
        
        return this;
    }
    
    /**
    * @description: Adds HTTP headers to the request
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param key    [STRING: Header key]
    * @param value  [STRING: Header value]
    * @return ApiController 
    **/
    public ApiController addHeader(String key, String value) {
        req.setHeader(key, value);
        
        return this;
    }
    
    /**
    * @description: Adds a map of key -> value headers pairs to the request
    * @author Stian Ruud Schikora | 08-16-2020 
    * @param httpHeaders 
    * @return ApiController 
    **/
    public ApiController setHeaders(Map<String, String> httpHeaders) {
        if(httpHeaders != null && !httpHeaders.isEmpty()){
            for(String contentType : httpHeaders.keySet()){
                if(String.isNotBlank(contentType)){
                    req.setHeader(contentType, httpHeaders.get(contentType));
                }
            }
        }
        
        return this;
    }

    /**
    * @description: Check if mock setting is turned on and set mock response
    * @author Tor Håkon Sigurdsen | 10-12-2020 
    * @param serviceName [String with the service name]
    **/
    private void setMockSettings(String serviceName) {
        try {
            //If there is a setting at the user level, this takes precedence, else check for profile level
            NKS_APIControllerUseMock__c mockSetting;
            if(NKS_APIControllerUseMock__c.getInstance(UserInfo.getUserId()) != null) {
                mockSetting = NKS_APIControllerUseMock__c.getInstance(UserInfo.getUserId());
            }
            else if(NKS_APIControllerUseMock__c.getInstance(UserInfo.getProfileId()) != null) {
                mockSetting = NKS_APIControllerUseMock__c.getInstance(UserInfo.getProfileId());
            }

            if(null != mockSetting && true == mockSetting.NKS_UseMock__c) {
                String mockResponse = getMockConfiguration(serviceName);
                this.mockResponse = ApiMock.initMock(mockResponse, Integer.valueOf(mockSetting.NKS_StatusCode__c), mockSetting.NKS_Status__c).respond();

                this.isMockActive = true;
            }
        } catch(Exception e) {
            //Do nothing
        }
    }

    /**
    * @description Queries the Mock_Response__c from the service to be mocked
    * @author Stian Ruud Schikora | 02-01-2021 
    * @param serviceName 
    * @return String 
    **/
    private String getMockConfiguration(String serviceName) {
        API_Service_Configuration__mdt config = [SELECT Id, Mock_Response__c FROM API_Service_Configuration__mdt WHERE DeveloperName =: serviceName LIMIT 1];
        return config?.Mock_Response__c;
    }
    
    
    /**
    * @description Initializes a ApiMock wrapper based on the mock response configred on the API Service Configuration,
    * Mocked status code and mock status
    * @author Stian Ruud Schikora | 02-01-2021 
    * @param ApiMockResponses 
    * @param statusCodeToMock 
    * @param statusToMock 
    * @return ApiMock 
    **/
    public static ApiMock initMock(String ApiMockResponses, Integer statusCodeToMock, String statusToMock) {
        ApiMock returnMock = new ApiMock(statusCodeToMock, statusToMock);
        String stringStatusCode = String.valueOf(statusCodeToMock);
        Map<String, Object> mocks = (Map<String, Object>) JSON.deserializeUntyped(ApiMockResponses);
        for(String mockedStatus : mocks.keySet()){
            if(mockedStatus == String.valueOf(stringStatusCode)) {
                Map<String, Object> mockResponse = (Map<String, Object>) mocks.get(stringStatusCode);
                Map<String, Object> headers = (Map<String, Object>) mockResponse.get('headers');
                if(headers != null) {
                    for (String headerKey : headers.keySet()) {
                        returnMock.headers.put(headerKey, (String) headers.get(headerKey));
                    }
                }
                returnMock.body = JSON.serialize(mockResponse.get('body'));
                break;
            }
        }
        return returnMock;
    }

    public class ApiMock {
        private Integer statusCode;
        private String status;
        public Map<String, String> headers;
        public String body;

        public ApiMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
            this.headers = new Map<String, String>();
        }

        public HttpResponse respond() {
            HttpResponse resp = new HttpResponse();
            resp.setStatus(this.status);
            resp.setStatusCode(this.statusCode);
            for (String headerKey : this.headers.keySet()) {
                resp.setHeader(headerKey, this.headers.get(headerKey));
            }
            resp.setBody(this.body);
            return resp;
        }

    }
    
    public class InvalidOperationException extends Exception {}
    public class NoServiceConfigurationException extends Exception {}
    public class InvalidPathParamException extends Exception {}
}