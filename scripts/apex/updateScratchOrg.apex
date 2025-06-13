connectAccountToChat();

public void connectAccountToChat() {
    List<MessagingSession> chats = [
        SELECT Id, AccountId
        FROM MessagingSession
    ];
    List<Account> accounts = [SELECT Id FROM Account];
    for (MessagingSession c : chats) {
        c.AccountId = accounts[0].Id;
    }
    update chats;
}
