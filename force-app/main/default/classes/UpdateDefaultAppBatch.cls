public class UpdateDefaultAppBatch implements Database.Batchable<SObject>, Database.Stateful {
    private String oldAppDevName = 'NAV_Kontaktsenter_v_2';
    private String newAppDevName = 'NAV_Kontaktsenter';
    private String oldAppDurableId;
    private String newAppDurableId;

    public UpdateDefaultAppBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        AppDefinition[] apps = [
            SELECT DurableId, DeveloperName
            FROM AppDefinition
            WHERE DeveloperName IN ('NAV_Kontaktsenter_v_2', 'NAV_Kontaktsenter')
        ];
        for (AppDefinition app : apps) {
            if (app.DeveloperName == oldAppDevName) {
                oldAppDurableId = app.DurableId;
            } else if (app.DeveloperName == newAppDevName) {
                newAppDurableId = app.DurableId;
            }
        }

        if (oldAppDurableId == null || newAppDurableId == null) {
            throw new AuraHandledException('Could not find both apps. Check DeveloperNames.');
        }

        return Database.getQueryLocator(
            [
                SELECT Id, AppDefinitionId
                FROM UserAppInfo
                WHERE AppDefinitionId = :oldAppDurableId
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<UserAppInfo> scope) {
        for (UserAppInfo uai : scope) {
            uai.AppDefinitionId = newAppDurableId;
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
    }
}
