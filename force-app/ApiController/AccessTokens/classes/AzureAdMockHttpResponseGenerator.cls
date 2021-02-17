public class AzureAdMockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        String body = '{ "token_type": "Bearer","scope": "user.read","expires_in": 3600,"access_token": "testToken","refresh_token": "refreshToken"}';
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}
