public with sharing class NKS_HenvendelseUtil {
    private static Map<String, Common_Code__c> commonCodeMap;

    public static Map<String, NKS_HenvendelseService.HENVENDELSE_TYPES> henvendelseEnumTypeMap {
        get {
            Map<String, NKS_HenvendelseService.HENVENDELSE_TYPES> enumMap = new Map<String, NKS_HenvendelseService.HENVENDELSE_TYPES>();
            for (
                NKS_HenvendelseService.HENVENDELSE_TYPES henvendelsesType : NKS_HenvendelseService.HENVENDELSE_TYPES.values()
            ) {
                enumMap.put(henvendelsesType.name(), henvendelsesType);
            }

            return enumMap;
        }
    }

    public static String getTemaLabel(String tema) {
        if (commonCodeMap == null) {
            loadCommonCodeMap();
        }

        Common_Code__c commonCode = commonCodeMap.get(tema);

        return commonCode == null ? 'Ukjent tema: ' + tema : commonCode.Name;
    }

    public static String getTemaGruppeLabel(String tema) {
        if (commonCodeMap == null) {
            loadCommonCodeMap();
        }

        Common_Code__c commonCode = commonCodeMap.get(tema);

        return commonCode == null ? 'Ukjent temagruppe: ' + tema : commonCode.Name;
    }

    public static Common_Code__c getTemagruppe(String tema) {
        if (commonCodeMap == null) {
            loadCommonCodeMap();
        }

        return commonCodeMap.get(tema);
    }

    private static void loadCommonCodeMap() {
        commonCodeMap = new Map<String, Common_Code__c>();
        for (Common_Code__c commonCode : [
            SELECT Id, Name, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Active__c = TRUE
        ]) {
            commonCodeMap.put(commonCode.CRM_Code__c, commonCode);
        }
    }

    public static NKS_HenvendelseService.HENVENDELSE_TYPES getHenvendelseEnumFromString(String typeName) {
        return henvendelseEnumTypeMap.get(typeName);
    }

    public static Boolean isMessageFromUser(String henvendelseType) {
        return hasEnum(
            new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_SBL_INNGAAENDE
            },
            henvendelseType
        );
    }

    public static Boolean isMessageFromNav(String henvendelseType) {
        return hasEnum(
            new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_SKRIFTLIG,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_OPPMOTE,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_TELEFON,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SAMTALEREFERAT_TELEFON,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SAMTALEREFERAT_OPPMOTE,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_MODIA_UTGAAENDE,
                NKS_HenvendelseService.HENVENDELSE_TYPES.DOKUMENT_VARSEL,
                NKS_HenvendelseService.HENVENDELSE_TYPES.OPPGAVE_VARSEL,
                NKS_HenvendelseService.HENVENDELSE_TYPES.DELVIS_SVAR_SKRIFTLIG,
                NKS_HenvendelseService.HENVENDELSE_TYPES.INFOMELDING_MODIA_UTGAAENDE
            },
            henvendelseType
        );
    }

    public static Boolean isNotificationMessage(String henvendelseType) {
        return hasEnum(
            new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.OPPGAVE_VARSEL,
                NKS_HenvendelseService.HENVENDELSE_TYPES.DOKUMENT_VARSEL
            },
            henvendelseType
        );
    }

    public static Boolean isQuestionMessage(String henvendelseType) {
        return hasEnum(
            new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_MODIA_UTGAAENDE,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG
            },
            henvendelseType
        );
    }

    public static Boolean isConversationNotes(String henvendelseType) {
        return hasEnum(
            new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.SAMTALEREFERAT_OPPMOTE,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SAMTALEREFERAT_TELEFON
            },
            henvendelseType
        );
    }

    public static Boolean isPartialyAnswered(String henvendelseType) {
        return hasEnum(
            new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.DELVIS_SVAR_SKRIFTLIG
            },
            henvendelseType
        );
    }

    public static String getMessageTitle(NKS_Henvendelse message) {
        if (
            hasEnum(
                new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                    NKS_HenvendelseService.HENVENDELSE_TYPES.DOKUMENT_VARSEL,
                    NKS_HenvendelseService.HENVENDELSE_TYPES.OPPGAVE_VARSEL
                },
                message.henvendelseType
            )
        ) {
            return gethenvendelseTypeText(getHenvendelseEnumFromString(message.henvendelseType));
        }

        if (String.isBlank(message.gjeldendeTemagruppe)) {
            return gethenvendelseTypeText(getHenvendelseEnumFromString(message.henvendelseType));
        }

        return gethenvendelseTypeText(getHenvendelseEnumFromString(message.henvendelseType)) +
            ' - ' +
            getTemaGruppeLabel(message.gjeldendeTemagruppe);
    }

    public static DateTime stringToDateTime(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }

        try {
            return Datetime.valueOf(dateString.replace('T', ' '));
        } catch (Exception e) {
            return null;
        }
    }

    private static Boolean hasEnum(List<NKS_HenvendelseService.HENVENDELSE_TYPES> toCompareTo, String henvendelseType) {
        return hasEnum(toCompareTo, getHenvendelseEnumFromString(henvendelseType));
    }

    private static Boolean hasEnum(
        List<NKS_HenvendelseService.HENVENDELSE_TYPES> toCompareTo,
        NKS_HenvendelseService.HENVENDELSE_TYPES henvendelseType
    ) {
        Set<NKS_HenvendelseService.HENVENDELSE_TYPES> toCompareToSet = new Set<NKS_HenvendelseService.HENVENDELSE_TYPES>(
            toCompareTo
        );

        return toCompareToSet.contains(henvendelseType);
    }

    private static String gethenvendelseTypeText(NKS_HenvendelseService.HENVENDELSE_TYPES henvendelseType) {
        switch on henvendelseType {
            when SVAR_TELEFON {
                return 'Svar telefon';
            }
            when SPORSMAL_SKRIFTLIG {
                return 'Spørsmål fra bruker';
            }
            when SAMTALEREFERAT_OPPMOTE {
                return 'Samtalereferat oppmøte';
            }
            when DELVIS_SVAR_SKRIFTLIG {
                return 'Delsvar';
            }
            when DOKUMENT_VARSEL {
                return 'Dokument-varsel';
            }
            when OPPGAVE_VARSEL {
                return 'Oppgave-varsel';
            }
            when SAMTALEREFERAT_TELEFON {
                return 'Samtalereferat telefon';
            }
            when SPORSMAL_MODIA_UTGAAENDE {
                return 'Spørsmål fra NAV';
            }
            when SVAR_OPPMOTE {
                return 'Svar oppmøte';
            }
            when SVAR_SBL_INNGAAENDE {
                return 'Svar fra bruker';
            }
            when SVAR_SKRIFTLIG {
                return 'Svar skriftlig';
            }
            when INFOMELDING_MODIA_UTGAAENDE {
                return 'Infomelding';
            }
            when else {
                return 'Ukjent meldingstype: ' + henvendelseType.name();
            }
        }
    }
}
