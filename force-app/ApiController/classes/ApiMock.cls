global class ApiMock {
    private Integer statusCode;
    private String status;
    public Map<String, String> headers;
    public String body;

    public ApiMock() {
        this.statusCode = null;
        this.status = null;
        this.headers = new Map<String, String>();
        this.body = null;
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

    /**
    * @description Queries the Mock_Response__c from the service to be mocked
    * @author Stian Ruud Schikora | 02-01-2021 
    * @param serviceName 
    * @return String 
    **/
    private String getMock(String serviceName) {
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
    public ApiMock initMock(String serviceName, Integer statusCodeToMock, String statusToMock) {
        this.status = statusToMock;
        this.statusCode = statusCodeToMock;
        String stringStatusCode = String.valueOf(statusCodeToMock);
        String ApiMockResponses = getMock(serviceName);

        Map<String, Object> mocks = (Map<String, Object>) JSON.deserializeUntyped(ApiMockResponses);
        for(String mockedStatus : mocks.keySet()){
            if(mockedStatus == String.valueOf(stringStatusCode)) {
                Map<String, Object> mockResponse = (Map<String, Object>) mocks.get(stringStatusCode);
                Map<String, Object> headers = (Map<String, Object>) mockResponse.get('headers');
                if(headers != null) {
                    for (String headerKey : headers.keySet()) {
                        this.headers.put(headerKey, (String) headers.get(headerKey));
                    }
                }
                this.body = JSON.serialize(mockResponse.get('body'));
                break;
            }
        }
        return this;
    }

    public static void setTestMock(String serviceName, Integer statusCode, String status) {
        ApiMock apiMock = new ApiMock();
        apiMOck.initMock(serviceName, statusCode, status);
        SingleRequestMock mock = new SingleRequestMock(apiMock.statusCode, apiMock.status, apiMock.body, apiMock.headers);
        Test.setMock(HttpCalloutMock.class, mock);
    }

}
