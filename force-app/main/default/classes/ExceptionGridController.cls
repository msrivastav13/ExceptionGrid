public with sharing class ExceptionGridController {
    @AuraEnabled(cacheable=true)
    public static List<ExceptionGridResponse> showExceptionGrid(Id recordId) {
        List<ExceptionGridResponse> response = new List<ExceptionGridResponse>();
        Map<String, ExceptionGridConfig__mdt> mapFieldNameByExceptionGridMDT = new Map<String, ExceptionGridConfig__mdt>();
        List<String> fields = new List<String>();
        try {
            // From the RecordId extract its Object Name
            String objectName = String.valueOf(recordId?.getSobjectType());
            // Query for all the Custom Metadata records related to the Object
            for (ExceptionGridConfig__mdt gridMetadata : [
                SELECT
                    ExpectedValue__c,
                    ExceptionMessage__c,
                    Field__c,
                    RequiredText__c,
                    Type__c
                FROM ExceptionGridConfig__mdt
                WHERE Object__c = :objectName
            ]) {
                // Split to get field Name from Entity Particle
                List<String> particle = (gridMetadata.Field__c).split('\\.');
                String fieldName;
                if (particle.size() == 3) {
                    fieldName = particle[2];
                } else {
                    fieldName = particle[1];
                }
                mapFieldNameByExceptionGridMDT.put(fieldName, gridMetadata);
            }
            // This prepares all the fields on which query will run
            fields.addAll(mapFieldNameByExceptionGridMDT.keyset());
            String soql =
                'SELECT ' +
                String.join(fields, ',') +
                ' FROM ' +
                objectName +
                ' WHERE ID =:recordId WITH SECURITY_ENFORCED LIMIT 1';
            // Get the record with all the field values configured in CMDT
            sObject record = Database.query(soql);
            // Loop over the fields and do a Match between what is configured in CMDT vs whats in the record
            for (String field : mapFieldNameByExceptionGridMDT.keyset()) {
                ExceptionGridConfig__mdt expectionGridRecord = mapFieldNameByExceptionGridMDT.get(
                    field
                );
                // Based on the Type check for the condition

                // Condition 1 - If the field is a Text field
                if (expectionGridRecord.Type__c == 'Text') {
                    if (expectionGridRecord.RequiredText__c) {
                        if (String.isBlank((String) record.get(field))) {
                            response.add(
                                new ExceptionGridResponse(
                                    field,
                                    true,
                                    expectionGridRecord.ExceptionMessage__c
                                )
                            );
                        } else {
                            if (
                                (String) record.get(field) !=
                                expectionGridRecord.ExpectedValue__c
                            )
                                response.add(
                                    new ExceptionGridResponse(
                                        field,
                                        true,
                                        mapFieldNameByExceptionGridMDT.get(
                                                field
                                            )
                                            .ExceptionMessage__c
                                    )
                                );
                        }
                    }
                }
                // Condition 2 - If the field is a Boolean field
                if (expectionGridRecord.Type__c == 'Picklist') {
                    if (
                        (String) record.get(field) !=
                        expectionGridRecord.ExpectedValue__c
                    )
                        response.add(
                            new ExceptionGridResponse(
                                field,
                                true,
                                mapFieldNameByExceptionGridMDT.get(field)
                                    .ExceptionMessage__c
                            )
                        );
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }

    public class ExceptionGridResponse {
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public Boolean isError;
        @AuraEnabled
        public String exceptionMessage;

        public ExceptionGridResponse(
            String fieldName,
            Boolean isError,
            String exceptionMessage
        ) {
            this.fieldName = fieldName;
            this.isError = isError;
            this.exceptionMessage = exceptionMessage;
        }
    }
}
