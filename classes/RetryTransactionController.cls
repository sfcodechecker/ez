public with sharing class RetryTransactionController {
    @AuraEnabled
    public static Transaction__c getTransactionDetails(String recordId){
        return [Select Id, Name, Gateway_Name__c, Transaction_Status__c From Transaction__c Where Id =: recordId WITH SECURITY_ENFORCED LIMIT 1];
    }

    /******Method to check if gateway is connected*******/
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
    public static string retryCurrentTransaction(String recordId){
        String returnValue = '';
        try{
            Transaction__c current_transaction = [Select Id, Name, Gateway_Name__c, Recurring_Payment__c, Transaction_Status__c, Amount__c From Transaction__c Where Id =: recordId WITH SECURITY_ENFORCED LIMIT 1];

            Recurring_Payment__c RPRecord = [Select Id, Name, Amount__c, Date_Established__c, Duration__c, Gateway_Name__c, Gateway_Refund_Id__c, Gateway_Schedule_Id__c, Installment_Period__c, Next_Installment_Date__c, Refund_Amount__c, Refund_Date__c, Refund_Description__c, Refund_Status__c, Secured_Token__c, RelatedToId__c, Status__c from Recurring_Payment__c Where Id =: current_transaction.Recurring_Payment__c WITH SECURITY_ENFORCED LIMIT 1];

            RecurringWrapper recurWrap = new RecurringWrapper();
            recurWrap.sfProcessingId = RPRecord.Id;
            recurWrap.amount = RPRecord.Amount__c;
            recurWrap.instalPeriod = RPRecord.Installment_Period__c;
            recurWrap.startDate = RPRecord.Next_Installment_Date__c;
            recurWrap.tokenValue = RPRecord.Secured_Token__c;

            TransactionWrapper tranWrapper = new TransactionWrapper();
            tranWrapper.sfProcessingId = current_transaction.Id;
            tranWrapper.amount = current_transaction.Amount__c;
            tranWrapper.transactionDate = RPRecord.Next_Installment_Date__c;
            tranWrapper.recurringRecordId = RPRecord.Id;

            returnValue = NABTransactHelper.updateTransactionBatchProcess(false, false, null, tranWrapper, recurWrap);
        }
        catch(Exception ex){
            returnValue = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('RetryTransactionController',ex,null);
        }
        return returnValue;
    }
}