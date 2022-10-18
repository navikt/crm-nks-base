//Fix merge person and account
Map<String,List<Account>> accMap = new Map<String,List<Account>>();
for(Account acc : [SELECT Id, INT_PersonIdent__c, CRM_Person__r.CRM_Account__c FROM Account]) {
    if(String.isBlank(acc.INT_PersonIdent__c)) {
        continue;
    }

    if(accMap.containsKey(acc.INT_PersonIdent__c) == false) {
        accMap.put(acc.INT_PersonIdent__c, new List<Account>());
    }

    accMap.get(acc.INT_PersonIdent__c).add(acc);
}

for(String ident : accMap.keySet()) {
    if(accMap.get(ident).size() > 1) {
        Account master;
        List<Account> duplicates = new List<Account>();
        for(Account acc : accMap.get(ident)) {
            if(acc.CRM_Person__r.CRM_Account__c == null) {
                duplicates.add(new Account(Id = acc.Id));
            } else {
                master = new Account(Id = acc.Id);
            }
        }

        Database.merge(master, duplicates);
    }
}