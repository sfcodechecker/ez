public with sharing class UpdateCardDetailController {

    @AuraEnabled
    public static Recurring_Payment__c getRecurringRecord(String recordId){
        try {
            Recurring_Payment__c rp = [Select Gateway_Refund_Id__c,Refund_Status__c,Status__c,Gateway_Name__c,Gateway_Schedule_Id__c from Recurring_Payment__c where Id=:recordId WITH SECURITY_ENFORCED Limit 1];
            return rp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean geTransactionStatus(String recordId){
        List<Transaction__c> failedTransactions = [Select Id, Name, Transaction_Status__c from Transaction__c where Recurring_Payment__c =: recordId AND (Transaction_Status__c = 'First Transaction Failure' OR Transaction_Status__c = 'Second Transaction Failure' OR Transaction_Status__c = 'Permanent Transaction Failure' OR Transaction_Status__c = 'Failed') WITH SECURITY_ENFORCED order by LastModifiedDate DESC Limit 1];
        if(failedTransactions.size() > 0){
            return true;
        }
        else{
            return false;
        }
    }

    //Method to check if gateway is connected or not.
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
    public static string updateCardDetails(String existingRPId, String requestUrl){
        String returnMsg='';
        Recurring_Payment__c existingRP = [Select Id, Amount__c, Date_Established__c, Duration__c, Gateway_Name__c, Gateway_Schedule_Id__c, Installment_Period__c, Last_Installment_Date__c, Next_Installment_Date__c, RelatedToId__c, Secured_Token__c, Status__c From Recurring_Payment__c Where Id =: existingRPId WITH SECURITY_ENFORCED Limit 1];
        String GatewayName=existingRP.Gateway_Name__c.toLowerCase().replaceAll(' ','_');
        try {
            switch on GatewayName {
                when 'stripe' {                    
                	returnMsg = (StripeManager.isConnected) ? StripeHelper.requestUpdateCardDetailPage(existingRP.Id, requestUrl) : StripeManager.detachedReason;
                }
                when 'payway' {
                	returnMsg = (PaywayManager.isConnected) ? PaywayHelper.requestUpdateCardDetails(existingRP.Id, existingRP.Gateway_Schedule_Id__c, requestUrl) : PaywayManager.detachedReason;
                }
                when 'nab_transact' {
                    returnMsg = (NABTransactManager.isConnected)?NABTransactHelper.requestUpdateCardDetails(existingRP.Id, requestUrl):NABTransactManager.detachedReason;
                }
                when 'ezidebit' {
                    returnMsg=(EzidebitManager.isConnected)?EzidebitHelper.requestUpdateCardDetailPage(existingRP.Id,existingRP.Gateway_Schedule_Id__c,requestUrl):EzidebitManager.detachedReason;
                }
                when 'bpoint' {
                    //bpoint update card detail method
                }
                when 'simplify' {
                    returnMsg=(SimplifyManager.isConnected)?SimplifyHelper.requestUpdateCardDetailPage(existingRP.Id, existingRP.Gateway_Schedule_Id__c, requestUrl):SimplifyManager.detachedReason;
                }
                when else{
                    throw new GatewayException('Something went wrong. Please try again.');
                }

            }
        } catch (Exception e) {
            returnMsg=e.getMessage();
        }
        return returnMsg;
    }

    // Sends an Exception email to support.    
    @AuraEnabled
    public static void sendExceptionEmail(String emailBody){
        EmailHandler.sendEmailTo('Error occurred during the process', emailBody, null, false);
    }
}