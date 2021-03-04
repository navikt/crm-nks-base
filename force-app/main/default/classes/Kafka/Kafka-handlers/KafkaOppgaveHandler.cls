public class KafkaOppgaveHandler implements IKafkaMessageConsumer {
    private LoggerUtility logger = new LoggerUtility();
    private Map<String, String> actorAccMap = new Map<String, String>();
    private Map<String, KafkaMessage__c> messageMap = new Map<String, KafkaMessage__c>();
    private Map<String, List<FeedItem>> feedItemMap = new Map<String, List<FeedItem>>(); //Maps a oppgave ref (INT_External_Reference__c) to a list of feed items to be created

    private static Map<String, String> commonCodeMap {
        get {
            Map<String, String> returnMap = new Map<String, String>();
            for (Common_Code__c comCode : [
                SELECT Id, CRM_Code__c, CRM_Code_Set__c
                FROM Common_Code__c
                WHERE CRM_Code_Set__c IN ('Tema', 'Behandlingstema')
            ]) {
                returnMap.put(comCode.CRM_Code_Set__c + comCode.CRM_Code__c, comCode.Id);
            }
            return returnMap;
        }
        private set {
        }
    }

    private static Map<String, String> navUnitMap {
        get {
            Map<String, String> returnMap = new Map<String, String>();
            for (NavUnit__c navUnit : [SELECT Id, INT_UnitNumber__c FROM NavUnit__c]) {
                returnMap.put(navUnit.INT_UnitNumber__c, navUnit.Id);
            }
            return returnMap;
        }
        private set {
        }
    }

    public void processMessages(List<KafkaMessage__c> messages) {
        List<NavTask__c> tasksToUpsert = new List<NavTask__c>();
        Map<Decimal, KafkaOppgave> kafkaTaskMap = convertToKafkaTasks(messages);
        initAccountMap();

        tasksToUpsert = convertToNavTasks(kafkaTaskMap.values());

        doUpsert(tasksToUpsert);
        logger.publish();
    }

    private void doUpsert(List<NavTask__c> tasksToUpsert) {
        Schema.SObjectField extRef = NavTask__c.Fields.INT_External_Reference__c;

        List<Database.UpsertResult> upsList = Database.upsert(tasksToUpsert, extRef, false);
        verifyUpsertResults(upsList, tasksToUpsert);
    }

    private void initAccountMap() {
        for (Person__c person : [
            SELECT Id, CRM_Account__c, INT_ActorId__c
            FROM Person__c
            WHERE INT_ActorId__c IN :this.actorAccMap.keySet()
        ]) {
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
            try {
                KafkaOppgave kafkaOppgave = convertToKafkaTask(message);
                if (kafkaOppgave != null) {
                    if (kafkaOppgave.getActorId() != null)
                        actorAccMap.put(kafkaOppgave.getActorId(), ''); //Adding the actor ids to map for initialization aftert successful conversions
                    //If the map already contains the unique task reference, check which of the messages containcs the latest version number
                    if (returnMap.containsKey(Decimal.valueOf(message.CRM_Key__c))) {
                        KafkaOppgave latestVersjon = getLatestTaskVersion(
                            kafkaOppgave,
                            returnMap.get(Decimal.valueOf(message.CRM_Key__c))
                        );
                        returnMap.put(Decimal.valueOf(latestVersjon.id), latestVersjon);
                    } else {
                        returnMap.put(Decimal.valueOf(message.CRM_Key__c), kafkaOppgave);
                    }
                    //Put in message map for later status update depending on DML
                    this.messageMap.put(message.CRM_Key__c, message);
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } else {
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                }
            } catch (Exception ex) {
                message.CRM_ErrorMessage__c =
                    ex.getTypeName() +
                    ': ' +
                    ex.getMessage() +
                    ' (' +
                    ex.getLineNumber() +
                    ')';
                message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }
        return returnMap;
    }

    /**
     * @description: Compares two KafkaOppgave wrappers and return the one with the highest version number
     * @author Stian Ruud Schikora | 02-26-2021
     * @param lhKafka
     * @param rhKafka
     * @return KafkaOppgave
     **/
    private KafkaOppgave getLatestTaskVersion(KafkaOppgave lhKafka, KafkaOppgave rhKafka) {
        KafkaOppgave newestKafka = lhKafka.versjon > rhKafka.versjon ? lhKafka : rhKafka;
        KafkaOppgave oldestKafka = lhKafka.versjon > rhKafka.versjon ? rhKafka : lhKafka;

        //If beskrivelse is changed, create feed item for this to be displayed in the history
        if (newestKafka.beskrivelse != oldestKafka.beskrivelse) {
            addFeedItem(oldestKafka);
        }
        return newestKafka;
    }

    private void addFeedItem(KafkaOppgave kafkaOppgave) {
        String oppgaveRef = String.valueOf(kafkaOppgave.id);

        if (this.feedItemMap.containsKey(oppgaveRef)) {
            List<FeedItem> mappedItems = this.feedItemMap.get(oppgaveRef);
            mappedItems.add(createFeedItem(kafkaOppgave));
            this.feedItemMap.put(oppgaveRef, mappedItems);
        } else {
            this.feedItemMap.put(oppgaveRef, new List<FeedItem>{ createFeedItem(kafkaOppgave) });
        }
    }

    /**
     * @description: Creating a placeholder feeditem that needs the parent ID field
     * updated after successful upsert of NAV Tasks
     * @author Stian Ruud Schikora | 03-04-2021
     * @param kafkaOppgave
     * @return FeedItem
     **/
    private FeedItem createFeedItem(KafkaOppgave kafkaOppgave) {
        FeedItem post = new FeedItem();
        post.Body = kafkaOppgave.beskrivelse;
        return post;
    }

    /**
     * @description: Performs converstion from KafkaOppgave => NavTask__c
     * @author Stian Ruud Schikora | 02-26-2021
     * @param kafkaOppgaver
     * @return List<NavTask__c>
     **/
    private List<NavTask__c> convertToNavTasks(List<KafkaOppgave> kafkaOppgaver) {
        List<NavTask__c> returnList = new List<NavTask__c>();
        NavTask__c convertedTask;

        for (KafkaOppgave kafkaOppgave : kafkaOppgaver) {
            try {
                convertedTask = convertToNavTask(kafkaOppgave);
            } catch (Exception ex) {
                //If conversion throws exception, add error to related kafka message
                getRelatedMessage(String.valueOf(kafkaOppgave.id))
                    .CRM_Status__c = KafkaMessageService.STATUS_ERROR;
                String errorMsg =
                    'Exception: ' +
                    ex.getTypeName() +
                    ' - ' +
                    ex.getMessage() +
                    ' - ' +
                    ex.getStackTraceString();
                getRelatedMessage(String.valueOf(kafkaOppgave.id))
                    .CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
            }
            if (convertedTask != null)
                returnList.add(convertedTask);
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
        if (
            this.actorAccMap.containsKey(kafkaOppgave.getActorId()) &&
            String.isNotBlank(this.actorAccMap.get(kafkaOppgave.getActorId())) &&
            commonCodeMap.containsKey('Tema' + kafkaOppgave.tema)
        ) {
            navTask.CRM_Account__c = this.actorAccMap.get(kafkaOppgave.getActorId());
            navTask.INT_External_Reference__c = kafkaOppgave.id;
            navTask.NKS_Task_Version__c = kafkaOppgave.versjon;
            navTask.CRM_NavUnit__c = navUnitMap.containsKey(kafkaOppgave.tildeltEnhetsnr)
                ? navUnitMap.get(kafkaOppgave.tildeltEnhetsnr)
                : null;
            navTask.NKS_Assignee__c = kafkaOppgave.tilordnetRessurs;
            navTask.CRM_Comments__c = kafkaOppgave.beskrivelse;
            navTask.NKS_Task_Type__c = kafkaOppgave.oppgavetype;
            navTask.NKS_Theme__c = commonCodeMap.get('Tema' + kafkaOppgave.tema);
            navTask.NKS_Subtheme__c = commonCodeMap.containsKey(
                    'Behandlingstema' + kafkaOppgave.tema
                )
                ? commonCodeMap.get('Behandlingstema' + kafkaOppgave.tema)
                : null;
            navTask.CRM_DueDate__c = Date.valueOf(kafkaOppgave.fristFerdigstillelse);
            navTask.CRM_Priority__c = kafkaOppgave.prioritet;
            navTask.NKS_Status__c = kafkaOppgave.status;
            navTask.CRM_NoPersonInformation__c = true; //Need to be default set because of validation rule
        } else {
            //If actor is not existing in Salesforce, create an application log
            this.logger.error(
                'Error creating NAV task, actor not found: ' +
                kafkaOppgave.getActorId() +
                '\n Task reference: ' +
                kafkaOppgave.id,
                null,
                CRM_ApplicationDomain.domain.NKS
            );
            getRelatedMessage(String.valueOf(kafkaOppgave.id))
                .CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            getRelatedMessage(String.valueOf(kafkaOppgave.id)).CRM_ErrorMessage__c =
                'Actor not found: ' + kafkaOppgave.getActorId();
            return null;
        }
        return navTask;
    }

    //##########################//
    //      ERROR HANDLING      //
    //##########################//

    /**
     * @description: Verifies the upsert results and updates the KafkaMessages with
     * Correct status and error messages.
     * @author Stian Ruud Schikora | 02-26-2021
     * @param upsList
     * @param taskList
     **/
    private void verifyUpsertResults(
        List<Database.UpsertResult> upsList,
        List<NavTask__c> taskList
    ) {
        Map<Id, NavTask__c> successMap = new Map<Id, NavTask__c>();

        for (Integer index = 0; index < upsList.size(); index++) {
            if (upsList[index].isSuccess()) {
                //Successful upsert
                Id taskId = upsList[index].getId();
                successMap.put(taskId, taskList[index]);
            } else {
                setMessageError(
                    upsList[index].getErrors(),
                    getRelatedMessage(String.valueOf(taskList[index].INT_External_Reference__c))
                );
            }
        }

        processFeedItems(successMap);
    }

    /**
     * @description: Creates feed items for the updated NAV Tasks where the beskrivelse was changed
     * @author Stian Ruud Schikora | 03-04-2021
     * @param successList : List og external references successfully created/updated
     **/
    private void processFeedItems(Map<Id, NavTask__c> successMap) {
        List<FeedItem> postsToInsert = new List<FeedItem>();

        for (Id navTaskId : successMap.keySet()) {
            String oppgaveRef = String.valueOf(successMap.get(navTaskId).INT_External_Reference__c);
            if (this.feedItemMap.containsKey(oppgaveRef)) {
                for (FeedItem post : this.feedItemMap.get(oppgaveRef)) {
                    post.ParentId = navTaskId;
                    postsToInsert.add(post);
                }
            }
        }

        List<Database.SaveResult> srList = Database.insert(postsToInsert);
        for (Integer index = 0; index < srList.size(); index++) {
            if (!srList[index].isSuccess()) {
                String messageReference = String.valueOf(
                    successMap.get(postsToInsert[index].ParentId).INT_External_Reference__c
                );
                setMessageError(srList[index].getErrors(), getRelatedMessage(messageReference));
            }
        }
    }

    /**
     * @description: Sets the message error
     * @author Stian Ruud Schikora | 02-26-2021
     * @param errList
     * @param message
     **/
    private void setMessageError(List<Database.Error> errList, KafkaMessage__c message) {
        for (Database.Error err : errList) {
            message.CRM_ErrorMessage__c =
                err.getStatusCode() +
                ': ' +
                err.getMessage() +
                ' - ' +
                'FIELDS: ' +
                err.getFields();
        }
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    /**
     * @description: Returns the message related to the task matching CRM_Key__c
     * and the INT_EXternal_Reference__c field
     * @author Stian Ruud Schikora | 02-26-2021
     * @param task
     * @return KafkaMessage__c
     **/
    private KafkaMessage__c getRelatedMessage(String reference) {
        return this.messageMap.get(reference);
    }
}
