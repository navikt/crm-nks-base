public virtual class ApiController {
    
    protected HttpRequest req = new HttpRequest();
    protected HttpResponse resp;
    protected String baseEndpoint;      //Endpoint to be used for the HTTP request
    protected String requestEndpoint;   //Request endpoint is the base endpoint with potential url parameter additions
    protected Integer HTTP_CALLOUT_TIMEOUT = 60000;
    protected Boolean urlParamsSet = false; //Boolean to determine if the url parameters has been set already
    
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
        this.resp = new Http().send(req);
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
    
    public class InvalidOperationException extends Exception {}
}