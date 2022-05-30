public with sharing class CancelTransactionController {
    @AuraEnabled
    public static Transaction__c getTransactionDetails(String recordId){
        return [Select Id, Name, Gateway_Name__c, Transaction_Status__c From Transaction__c Where Id =: recordId WITH SECURITY_ENFORCED LIMIT 1];
    }

    //Method to check of gateway is connected or not.
    @AuraEnabled
    public static Boolean isGatewayConnected(String gatewayName){
        gatewayName = gatewayName.replaceAll(' ','_').toLowerCase();
        List<Gateway_Detail__c> checkGateway = [Select Id from Gateway_Detail__c where Name__c =: gatewayName WITH SECURITY_ENFORCED Limit 1];
        if(checkGateway.size() > 0){
            return true;
        }
        else{
            return false;
        }
    }

    @AuraEnabled
    public static string cancelCurrentTransaction(String recordId){
        String returnValue = '';
        try {
            returnValue = NABTransactHelper.cancelTransaction(recordId);
        } catch (Exception ex) {
            returnValue = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('RetryTransactionController',ex,null);
        }
        return returnValue;
    }
}