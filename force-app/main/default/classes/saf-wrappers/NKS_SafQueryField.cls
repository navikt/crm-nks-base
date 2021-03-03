public with sharing class NKS_SafQueryField {
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public List<NKS_SafQueryField> queryFields { get; set; }

    public NKS_SafQueryField() {
        queryFields = new List<NKS_SafQueryField>();
    }

    public NKS_SafQueryField(String name) {
        this();
        this.name = name;
    }

    public override String toString() {
        String stringToReturn = name;

        if (false == queryFields.isEmpty()) {
            stringToReturn += ' { ';

            for (NKS_SafQueryField qf : queryFields) {
                stringToReturn += qf.toString() + ' ';
            }
            stringToReturn += '}';
        }

        return stringToReturn;
    }
}
