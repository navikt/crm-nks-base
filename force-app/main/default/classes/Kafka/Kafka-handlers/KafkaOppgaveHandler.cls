public class KafkaOppgaveHandler implements IKafkaMessageConsumer {

    private LoggerUtility logger = new LoggerUtility();
    private Map<String, String> actorAccMap = new Map<String, String>(); 
    
    public void processMessages(List<KafkaMessage__c> messages) {
        List<NavTask__c> tasksToUpsert = new List<NavTask__c>();
        Map<Decimal, KafkaOppgave> kafkaTaskMap = convertToKafkaTasks(messages);
        initAccountMap();

        tasksToUpsert = convertToNavTasks(kafkaTaskMap.values());

        // Errors from DML will be caught by calling context and saved on the related AsyncRequest record
        upsert tasksToUpsert INT_External_Reference__c;
    }

    private void initAccountMap() {
        for (Person__c person : [SELECT Id, CRM_Account__c, INT_ActorId__c FROM Person__c WHERE INT_ActorId__c IN: this.actorAccMap.keySet()]) {
            this.actorAccMap.put(person.INT_ActorId__c, person.CRM_Account__c);
        }
    }

    /**
    * @description: Deserialize the Kafka message value into the wrapper object
    * @author Stian Ruud Schikora | 01-15-2021 
    * @param message 
    * @return KafkaOppgave 
    **/
    private KafkaOppgave convertToKafkaTask(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        return (KafkaOppgave) JSON.deserialize(decodedValue, KafkaOppgave.class);
    }

    /**
    * @description: Generates a list of KafkaOppgave wrappers based on the kafka messages
    * @author Stian Ruud Schikora | 01-15-2021 
    * @param messages 
    * @return List<KafkaOppgave> 
    **/
    private Map<Decimal, KafkaOppgave> convertToKafkaTasks(List<KafkaMessage__c> messages) {
        Map<Decimal, KafkaOppgave> returnMap = new Map<Decimal, KafkaOppgave>();
        
        for (KafkaMessage__c message : messages) {
            try{
                KafkaOppgave kafkaOppgave = convertToKafkaTask(message);
                actorAccMap.put(kafkaOppgave.aktoerId, ''); //Adding the actor ids to map for initialization aftert successful conversions
                //If the map already contains the unique task reference, check which of the messages containcs the latest version number
                if(returnMap.containsKey(Decimal.valueOf(message.CRM_Key__c))) {
                    KafkaOppgave latestVersjon = getLatestTaskVersion(kafkaOppgave, returnMap.get(Decimal.valueOf(message.CRM_Key__c)));
                    returnMap.put(Decimal.valueOf(latestVersjon.id), latestVersjon);
                }
                else{
                    returnMap.put(Decimal.valueOf(message.CRM_Key__c), kafkaOppgave);
                }
                message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
            }
            catch(Exception ex) {
                message.CRM_ErrorMessage__c = ex.getTypeName() + ': ' + ex.getMessage() + ' (' + ex.getLineNumber() + ')';
                message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }

        return returnMap;
    }

    private KafkaOppgave getLatestTaskVersion(KafkaOppgave lhKafka, KafkaOppgave rhKafka) {
        return lhKafka.versjon >= rhKafka.versjon ? lhKafka : rhKafka;
    }

    private List<NavTask__c> convertToNavTasks(List<KafkaOppgave> kafkaOppgaver) {
        List<NavTask__c> returnList = new List<NavTask__c>();

        for (KafkaOppgave kafkaOppgave : kafkaOppgaver) {
            returnList.add(convertToNavTask(kafkaOppgave));
        }

        return returnList;
    }

    /**
    * @description: Maps fields from KafkaOppgave wrapper class to NavTask__c fields
    * @author Stian Ruud Schikora | 01-15-2021 
    * @param kafkaOppgave 
    * @return NavTask__c 
    **/
    private NavTask__c convertToNavTask(KafkaOppgave kafkaOppgave) {
        NavTask__c navTask = new NavTask__c();
        if(this.actorAccMap.containsKey(kafkaOppgave.aktoerId)) {
            navTask.CRM_Account__c = this.actorAccMap.get(kafkaOppgave.aktoerId);
            navTask.INT_External_Reference__c = kafkaOppgave.Id;
            navTask.NKS_Task_Version__c = kafkaOppgave.versjon;
            navTask.CRM_NavUnit__r = new NavUnit__c(INT_UnitNumber__c = kafkaOppgave.tildeltEnhetsnr);
            navTask.NKS_Assignee__c = kafkaOppgave.tilordnetRessurs;
            navTask.CRM_Comments__c = kafkaOppgave.beskrivelse;
            navTask.NKS_Task_Type__c = kafkaOppgave.oppgavetype; //Need to solve how we should handle this as not all task types are implemented in the picklist --> Mapping via Common code?
            //navTask.NKS_Theme__r Need to be sure this do not break anything
            //navTask.NKS_Subtheme__r
            navTask.CRM_DueDate__c = Date.parse(kafkaOppgave.fristFerdigstillelse);
            navTask.CRM_Priority__c = kafkaOppgave.prioritet;
            navTask.CRM_Status__c = kafkaOppgave.status;
        }
        else{
            //HOW DO WE HANDLE ACTORS NOT EXISTING IN SALESFORCE?
        }
        return navTask;
    }
}
