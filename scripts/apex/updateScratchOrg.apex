connectAccountToChat(); 

public void connectAccountToChat(){
    List<LiveChatTranscript> chats = [SELECT Id, AccountId FROM LiveChatTranscript]; 
    List<Account> accounts = [SELECT Id FROM Account]; 
    for(LiveChatTranscript c : chats){
        c.AccountId = accounts[0].Id; 
    }
    update chats; 
}