global class NKS_ConversationNotePersonAccessHandler  extends MyTriggers {
        public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
            system.debug('update person');
        }
}
