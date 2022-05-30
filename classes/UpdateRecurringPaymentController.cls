public with sharing class UpdateRecurringPaymentController {
    @AuraEnabled
    public static Recurring_Payment__c getRecurringDetails(string recurringId)
    {
        return  [Select Id,Name,Q_Charge__Duration__c,Q_Charge__RelatedToId__c, Q_Charge__Status__c, Gateway_Name__c,Q_Charge__Date_Established__c ,Amount__c, Next_Installment_Date__c,Installment_Period__c,Gateway_Schedule_Id__c  from Recurring_Payment__c where Id=:recurringId WITH SECURITY_ENFORCED Limit 1];
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
    public static Contact getContactInfo(String relatedId){
        return new Contact();//[Select Id, Name from Contact where Id =: relatedId WITH SECURITY_ENFORCED Limit 1];
    }

    @AuraEnabled
    public static Boolean checkFailedTransaction(string recurringId){
        List<Transaction__c> failedTransactions = [Select Id, Name, Transaction_Status__c from Transaction__c where Recurring_Payment__c =: recurringId AND (Transaction_Status__c = 'First Transaction Failure' OR Transaction_Status__c = 'Second Transaction Failure' OR Transaction_Status__c = 'Permanent Transaction Failure' OR Transaction_Status__c = 'Failed') WITH SECURITY_ENFORCED order by LastModifiedDate DESC Limit 1];
        if(failedTransactions.size() > 0){
            return true;
        }
        else{
            return false;
        }
    }
    
    /**************************** Method for fetching frequncy list of gateways. ********************************/
    @AuraEnabled
    public static List<ComboClass> instalmentPeriodList(String gatewayName){
        List<ComboClass> cmblist = new List<ComboClass>();
        try{
            Frequency__mdt frequency = Frequency__mdt.getInstance(GatewayName.replaceAll(' ', '_').toLowerCase());
            if(frequency != null){                
                for(String eachPeriod : frequency.Instalment_Period__c.split(',')) { 
                    /*if(eachPeriod == 'Half-Yearly'){                          //changed KW
                        eachPeriod = 'Six-monthly';
                    }
                    if(eachPeriod == 'Annual'){
                        eachPeriod = 'Yearly';
                    }*/
                    cmblist.add(new ComboClass(eachPeriod,eachPeriod,false));
                }
            }
        }catch(Exception ex){
            EmailHandler.sendExceptionEmail('UpdateRecurringPaymentController',ex,null);
        }
        return cmblist;
    }
    
    //Update Recurring Payment Method for Stripe.
    @AuraEnabled
    public static string StripeUpdateRP(Recurring_Payment__c recPayment){ 
        String updateRPResult = '';
        try {
            if(recPayment.status__c != null && recPayment.Status__c == 'Open'){
                RecurringWrapper rec = new RecurringWrapper();
                rec.sfRecurringId = recPayment.Id;
                rec.sfProcessingId = recPayment.Q_Charge__RelatedToId__c;
                rec.amount = recPayment.Amount__c;
                rec.instalPeriod = recPayment.Q_Charge__Installment_Period__c;               
                rec.recurringRequestId = recPayment.Gateway_Schedule_Id__c;
                rec.startDate = recPayment.Next_Installment_Date__c;
                updateRPResult = StripeHelper.processUpdateRP(rec,'');             
                if(updateRPResult.startsWith('succeeded:')){
                    updateRPResult = recPayment.Name+MessageHandler.updateRP + UTILGateway.STRIPEWORD.capitalize() + '.';
                }
            }else{
                updateRPResult = MessageHandler.stripeRPNotUpdated + MessageHandler.invalidRPStatus;
            } 
        } catch (Exception ex) {
            updateRPResult = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('UpdateRecurringPaymentController',ex,null);
        }
        return updateRPResult;
    }

    //Update Recurring Payment Method for Payway.
    @AuraEnabled
    public static String paywayUpdateRP(String recordId, Decimal amount, String installPeriod, String startDate)
    {
        String updateResp = '';
        try {

            RecurringWrapper reccWrapper = new RecurringWrapper();
            reccWrapper.amount = amount;
            reccWrapper.instalPeriod = installPeriod=='Half Yearly'?'Six-Monthly':installPeriod;
            reccWrapper.sfProcessingId = recordId;
            reccWrapper.nextPaymentDate = UTILGateway.convertDatetoString(Date.valueOf(startDate));
            reccWrapper.startDate = Date.valueOf(startDate);            
            
            //creating paylod to schedule retry request.
            reccWrapper.transactionPayload = PaywayHelper.createReccurringPayLoad(reccWrapper);
            updateResp = PaywayHelper.processUpdateRecurringPayment(reccWrapper);

        }catch (Exception exc) {
            updateResp = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('UpdateRecurringPaymentController',exc,null);
        }
        return updateResp;
    }

    //Update Recurring Payment Method for NAB Transact.
    @AuraEnabled
    public static string NABTransactUpdateRP(String recordId, Decimal amount, String installPeriod, String startDate){
        String updateRPResult = '';
        try {
            RecurringWrapper recurWrap = new RecurringWrapper();
            recurWrap.sfProcessingId = recordId;
            recurWrap.amount = amount;
            recurWrap.instalPeriod = installPeriod;
            recurWrap.startDate = date.valueOf(startDate);
            updateRPResult = NABTransactHelper.processUpdateRP(recurWrap);

        } catch (Exception ex) {
            updateRPResult = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('UpdateRecurringPaymentController',ex,null);
        }
        return updateRPResult;
    }
    
    //Update Recurring Payment Method for Ezidebit.
    @AuraEnabled
    public static string ezidebitUpdateRP(String recordId, Decimal amount, String installPeriod, String startDate,String scheduleId){
        String response='';
        try {
            RecurringWrapper reccWrapper=new RecurringWrapper();
            reccWrapper.sfProcessingId=recordId;
            reccWrapper.amount=amount;
            reccWrapper.instalPeriod=installPeriod;
            reccWrapper.startDate=Date.valueOf(startDate);
            reccWrapper.recurringRequestId=scheduleId;
            reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD;
            reccWrapper.status=false;
            reccWrapper=EzidebitHelper.ProcessUpdateRecurringPayment(reccWrapper);
            response=(reccWrapper.status)?reccWrapper.responseMessage:reccWrapper.errorResponse;
        } catch (Exception e) {
            response=e.getMessage();
            EmailHandler.sendExceptionEmail('UpdateRecurringPaymentController',e,null);
        }
        return response;
    }
    
    //Update Recurring Payment Method for Simplify.
    @AuraEnabled
    public static String simplifyUpdateRP(String recordId, Decimal amount, String installPeriod, String startDate,String scheduleId){
        String response='';
        try {
            RecurringWrapper reccWrapper=new RecurringWrapper();
            reccWrapper.sfProcessingId=recordId;
            reccWrapper.amount=amount;
            reccWrapper.instalPeriod=installPeriod;
            reccWrapper.startDate=Date.valueOf(startDate);
            reccWrapper.recurringRequestId=scheduleId;
            reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD;
            reccWrapper.status=false;
            reccWrapper=SimplifyHelper.ProcessUpdateRecurringPayment(reccWrapper);
            response=(reccWrapper.status)?reccWrapper.responseMessage:reccWrapper.errorResponse;
            UtilGateway.MaintainLog(UtilGateway.PayLogSet_JSON);
        } catch (Exception e) {
            response=e.getMessage();
            EmailHandler.sendExceptionEmail('UpdateRecurringPaymentController',e,null);
        }
        return response;
    }
    
    public class ComboClass{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isdefault; 
        
        public ComboClass(String l, String v, Boolean def){
            this.label = l;
            this.value = v;
            this.isdefault = def;
        }
    }

    // Sends an Exception email to support.    
    @AuraEnabled
    public static void sendExceptionEmail(String emailBody){
        EmailHandler.sendEmailTo('Error occurred during the process', emailBody, null, false);
    }
}