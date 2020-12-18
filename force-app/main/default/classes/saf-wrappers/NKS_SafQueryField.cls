public with sharing class NKS_SafQueryField {
    public String name;
        public List<NKS_SafQueryField> queryFields;

        public NKS_SafQueryField() {
            queryFields = new List<NKS_SafQueryField>();
        }

        public NKS_SafQueryField(String name) {
            this();
            this.name = name;
        }

        public override String toString() {
            String stringToReturn = name;

            if(null != queryFields && false == queryFields.isEmpty()) {
                stringToReturn += ' { ';

                for(NKS_SafQueryField qf : queryFields) {
                    stringToReturn += qf.toString() + ' ';
                }
                stringToReturn += '}';
            }

            return stringToReturn;
        }
}
