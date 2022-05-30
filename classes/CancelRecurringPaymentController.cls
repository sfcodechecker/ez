public with sharing class CancelRecurringPaymentController {
    
    
    @AuraEnabled
    public static List<Recurring_Payment__c> getRecurringRecord(String recordId){
        return  [Select Id,Name,Duration__c,RelatedToId__c,Status__c,Gateway_Refund_Id__c,Gateway_Name__c,Date_Established__c ,Amount__c, Next_Installment_Date__c,Installment_Period__c,Gateway_Schedule_Id__c  from Recurring_Payment__c where Id=:recordId WITH SECURITY_ENFORCED Limit 1];
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
    public static String cancelRPEzidebit(List<Recurring_Payment__c> existingRP){
        String returnMsg='';
        try{
            RecurringWrapper wrapper=EzidebitHelper.cancelRecurringPayment(existingRP);
            returnMsg=wrapper.status?wrapper.responseMessage:wrapper.errorResponse;
            UtilGateway.MaintainLog(UTILGateway.PayLogSet_JSON);		
        }catch(Exception e){
            returnMsg=e.getMessage();
        }        
        
        return returnMsg;
    }
    
    @AuraEnabled
    public static String cancelPaywayRP(List<Recurring_Payment__c> existingRP){
        String returnMsg='';
        try{
            returnMsg = PaywayHelper.cancelRecurringPayment(existingRP);            
        }catch(Exception exc){
            returnMsg = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('CancelRecurringPaymentController',exc,null);
        }        
        return returnMsg;
    }

    @AuraEnabled
    public static String cancelNABTransactRP(List<Recurring_Payment__c> existingRP){
        String returnMsg='';
        try{
            returnMsg = NABTransactHelper.cancelRecurringPayment(existingRP);
            
        }catch(Exception exc){
            returnMsg = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('CancelRecurringPaymentController',exc,null);
        }        
        return returnMsg;
    }
    
    @AuraEnabled
    public static String cancelRPSimplify(List<Recurring_Payment__c> existingRP){
        String returnMsg='';
        try{
            RecurringWrapper wrapper=SimplifyHelper.cancelRecurringPayment(existingRP);
            returnMsg=wrapper.status?wrapper.responseMessage:wrapper.errorResponse;
        }catch(Exception e){
            returnMsg=e.getMessage();
        }        
        
        return returnMsg;
    }

    @AuraEnabled
    public static String cancelStripeRP(List<Recurring_Payment__c> existingRP){
        String returnMsg='';
        try{
            returnMsg = StripeHelper.processCancelRP(existingRP);
        }catch(Exception e){
            returnMsg = e.getMessage();
        }        
        return returnMsg;
    }
    
    // Sends an Exception email to support.    
    @AuraEnabled
    public static void sendExceptionEmail(String emailBody){
        EmailHandler.sendEmailTo('Error occurred during the process', emailBody, null, false);
    }
}