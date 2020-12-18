
/**
 * Mock class for NKS_SafService
 * Let a user mock the response without having to create callout mocks with JSON strings
 */
@IsTest
public with sharing class NKS_SafServiceMock implements StubProvider {
    private List<NKS_SafGetDocumentResponse> safGetDocumentResponseList;
    private List<NKS_SafQueryResponse> safQueryResponseList;

    public NKS_SafServiceMock() {
        safGetDocumentResponseList = new List<NKS_SafGetDocumentResponse>();
        safQueryResponseList = new List<NKS_SafQueryResponse>();
    }

    public void addSafGetDocumentResponse(NKS_SafGetDocumentResponse safGetDocumentResponse) {
        safGetDocumentResponseList.add(safGetDocumentResponse);
    }

    public void addSafQueryResponse(NKS_SafQueryResponse safQueryResponse) {
        safQueryResponseList.add(safQueryResponse);
    }
    
    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
        switch on stubbedMethodName {
            when 'doSafQuery' {
                return safQueryResponseList.remove(0);
            }
            when 'getSafDocument' {
                return safGetDocumentResponseList.remove(0);
            }
            when else {
                throw new SafServiceMockException('Method ' + stubbedMethodName + ' is not setup as a mocked method.');
            }
        }
    }

    public class SafServiceMockException extends Exception {}

}
