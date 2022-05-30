public with sharing class StripeHelper {
    
    public static FINAL String OpenKeyWord = 'Open';
    public static FINAL String ClosedKeyWord = 'Closed';
    public static FINAL String PaidKeyWord = 'Paid';
    public static FINAL String ScheduleKeyWord = 'Scheduled'; 
    
    
    /*********************** Process one off payment helper method ********************************/
    public static String ProcessOneTimeTransaction(List<Payment_Log__c> logList,String status){

        Payment_Log__c log = new Payment_Log__c();
        if(logList.size() > 0){
            for(Payment_Log__c recurPaymentlog : logList){
                log = recurPaymentlog;
            }
        }else{
            return MessageHandler.wentWrongCatchMessage;
        }
        
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.amount = log.Amount__c;
        receipt.chargeType = UTILGateway.ONETIMEKEYWORD;        
        if(log?.Payment_Parameter_1__c != null)
        {
            String responseMessage = MessageHandler.wentWrongCatchMessage;
            TransactionWrapper trans = new TransactionWrapper();
            trans.paymentId = log.Payment_Parameter_2__c;
            trans.sfProcessingId = log.Processing_Record_Id__c;
            trans = StripeManager.getTransaction(trans);
            
            if(trans.status && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Create') && Schema.sObjectType.Q_Charge__Transaction__c.isCreateable()){
                StripePaymentIntent payIntent = (StripePaymentIntent)JSON.deserialize(trans.transResponse, StripePaymentIntent.class);
                responseMessage = payIntent.status+':'+String.valueOf(payIntent.Id);
                Database.insert(MappingOneTimeTransaction(trans, 'Create'), true);
                receipt.paymentStatus = 'Transaction Approved';
                receipt.paymentResponse = MessageHandler.onetimeSuccess;
                receipt.paymentId = responseMessage.substringAfter('succeeded:');
                
            }else if(status=='cancel'){
                receipt.paymentStatus = 'Transaction Rejected';
                receipt.paymentResponse = MessageHandler.oneTimeFailed+MessageHandler.stripeTransactionCancelled;
            }else{
                receipt.paymentStatus = 'Transaction Rejected';
                receipt.paymentResponse =  responseMessage.substringAfter(':');
            }
        }else {
            receipt.paymentStatus = 'Transaction Rejected';
            receipt.paymentResponse =  MessageHandler.noTransactionInitated; 
        }
        
        String serializedWrapper=JSON.serialize(receipt);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.STRIPEWORD,Processing_Record_Id__c=log.Processing_Record_Id__c, Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.oneTimeCheckoutComplete,Request_Type__c = 'POST',Amount__c = log.Amount__c,Charge_Type__c = UTILGateway.ONETIMEKEYWORD ,Serialized_Record__c = serializedWrapper)));
        List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
        
        return String.valueOf(newLog.id);
    }
    
    /*********************** Process a schedule method ********************************/
    public static String ProcessRecurringTransaction(List<Payment_Log__c> logList,String status){
        
        String responseMessage = '';        
        
        Payment_Log__c log = new Payment_Log__c();
        if(logList.size() > 0){
            for(Payment_Log__c recurPaymentlog : logList){
                log = recurPaymentlog;
            }
        }else{
            return MessageHandler.wentWrongCatchMessage;
        }

        ReceiptWrapper receipt = new ReceiptWrapper();
        receipt.amount = log.Amount__c;
        receipt.chargeType = UTILGateway.RECURRINGKEYWORD;
        receipt.establishmentDate = Date.today();
        receipt.installPeriod = log.Frequency__c;
        
        if(log?.Payment_Parameter_1__c != null)
        {
            RecurringWrapper recWrap = new RecurringWrapper();
            recWrap.recurringRequestId = log.Payment_Parameter_2__c;
            recWrap.sfProcessingId = log.Processing_Record_Id__c;
            recWrap.instalPeriod = log.Frequency__c;
            recWrap = StripeManager.getTransactionRPbyCheckout(recWrap);
            
            if(recWrap.status && Schema.sObjectType.Q_Charge__Transaction__c.isCreateable() && Schema.sObjectType.Q_Charge__Recurring_Payment__c.isCreateable()){
                StripeSubscriptionWrapper ScheduleWrapper = (StripeSubscriptionWrapper)JSON.deserialize(recWrap.recurringResponse, StripeSubscriptionWrapper.Class);
                
                Recurring_Payment__c reccur = MappingRecurringPayment(ScheduleWrapper, null, 'Create',true);
                Database.SaveResult sr = Database.insert(reccur, true); 
                
                if(recWrap.transactionList != null && !recWrap.transactionList.isEmpty()){
                    Database.SaveResult[] sinvList = Database.insert(MappingRecurringTransaction(recWrap.transactionList, sr.getId(), 'Create'), true);
                    for(Database.SaveResult sinv : sinvList){
                        if(!sinv.isSuccess())
                        responseMessage = sinv.getErrors()[0].getMessage();
                    }
                }            
                receipt.paymentResponse = MessageHandler.recurringSuccess;
                receipt.paymentStatus = 'Payment Approved';
                receipt.establishmentDate = DateTime.newInstance(Long.valueOf(String.valueOf(ScheduleWrapper.created)+ '000')).date();
                //receipt.establishmentDate =  dt.day()+'/'+dt.month()+'/'+dt.year();
                receipt.nextInstallmentDate = DateTime.newInstance(Long.valueOf(String.valueOf(ScheduleWrapper.current_period_end)+ '000')).date();
                //receipt.nextInstallmentDate = dt.day()+'/'+dt.month()+'/'+dt.year();
            }else if(status=='cancel'){
                receipt.paymentStatus = 'Payment Rejected';
                receipt.paymentResponse = MessageHandler.recurringFailed+MessageHandler.stripeTransactionCancelled;
            }else{
                receipt.paymentStatus = 'Payment Rejected'; 
                receipt.paymentResponse = MessageHandler.recurringFailed + responseMessage+'.';
            }
        }else {
            receipt.paymentStatus = 'Payment Rejected'; 
            receipt.paymentResponse =  MessageHandler.noTransactionInitated;
        }
        
        String serializedWrapper=JSON.serialize(receipt);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.STRIPEWORD,Processing_Record_Id__c=log.Processing_Record_Id__c,Frequency__c = log.Frequency__c ,Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.recPayCheckoutComplete, Request_Type__c = 'POST',Recurring_Start_Date__c = log.Recurring_Start_Date__c , Amount__c = log.Amount__c, Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Serialized_Record__c = serializedWrapper)));
        List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
        
        return String.valueOf(newLog.id);
    }
    
    /***************** Method to request update card detail page ***************/
    public static String requestUpdateCardDetailPage(String recurrId, String requestingURL){
        
        Q_Charge__Recurring_Payment__c rec = [Select Id,Name,Amount__c,Status__c,Gateway_Schedule_Id__c,RelatedToId__c From Q_Charge__Recurring_Payment__c where Id =:recurrId WITH SECURITY_ENFORCED limit 1];
        
        Contact con = [Select Id, Name, email from contact Where Id = :rec.RelatedToId__c WITH SECURITY_ENFORCED limit 1];
        
        if(rec.Status__c != 'Open'){
            return MessageHandler.stripeRPNotUpdated + MessageHandler.invalidRPStatus;
        }
        
        StripePaymentMethodwrapper pay_method = new StripePaymentMethodwrapper();
        pay_method.billing_details = new StripePaymentMethodwrapper.Billing_details();
        pay_method.billing_details.email = con.email;        
        pay_method.successURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__StripeUpdateCard?record_id='+recurrId+'&type=setup&requestedURL='+requestingURL+'&reference=stripe';
        pay_method.cancelURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__StripeCheckoutCancel?record_id='+recurrId+'&type=setup&requestedURL='+requestingURL+'&reference=stripe';
        
        String value = StripeManager.updateCardDetails(pay_method);
        
        if(value.startsWith('/apex/Q_Charge__StripeCheckout?session_id=')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.logUpdateCard + rec.Name,Transaction_Id__c = rec.Gateway_Schedule_Id__c,Requesting_Url__c = requestingURL,Gateway_Name__c = UTILGateway.STRIPEWORD, Processing_Record_Id__c = recurrId, Payment_Parameter_1__c = value.substringAfter('/apex/Q_Charge__StripeCheckout?session_id='), Serialized_Record__c = JSON.serialize(rec)))); // Add to Log
        }
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        return value;
    }
    
    /***************** Method to request update card detail page ***************/
    public static String processUpdateRP(RecurringWrapper req, String requestingURL){
        String value = '';
        List<Recurring_Payment__c> reccurList = new List<Recurring_Payment__c>();
        if(req.startDate != null && req.startDate >= Date.today()){ 
            req.startDateUnix = req.startDate != Date.today() ? convertDateToUnix(req.startDate) : null;
            value = StripeManager.updateRecurringPayment(req);
            if(value.contains('successfully')){
                Recurring_Payment__c reccur = new Recurring_Payment__c();
                If(Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable()){
                    reccur.id = req.sfRecurringId;
                    reccur.Amount__c = req.amount;
                    reccur.Installment_Period__c = req.instalPeriod;             
                    reccur.RelatedToId__c = req.sfProcessingId;
                    reccur.Gateway_Schedule_Id__c = req.recurringRequestId;
                    reccurList.add(reccur);
                }
                else{
                    throw new UTILPermission.PermsException('Recurring_Payment__c','id,Amount__c,Installment_Period__c,RelatedToId__c,Gateway_Schedule_Id__c','update');
                }
                // Method fetch todays transaction and update the upcoming transaction.
                value = fetchCompletedRPTransactions(reccurList, Date.today().addDays(-1));
            }
        }else{
            value = MessageHandler.stripeRPNotUpdated + MessageHandler.prevStartDate;
        }
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        return value;
    }
    


    /***************** Method to request cancel recurring payments ***************/
    public static String processCancelRP(List<Recurring_Payment__c> existingRPList){
        
        Recurring_Payment__c reccur = new Recurring_Payment__c();
        if(existingRPList.size() > 0){
            for(Recurring_Payment__c recurPayment : existingRPList){
                reccur = recurPayment;
            }
        }else{
            return MessageHandler.wentWrongCatchMessage;
        }
        String value = StripeManager.cancelRecurringPayment(reccur.Gateway_Schedule_Id__c);
        if(value.contains('successfully')){
            // Method fetch todays transaction and update the upcoming transaction.
            value = fetchCompletedRPTransactions(existingRPList, null);
            value = value.startsWith('succeeded') ? reccur.Name+' is '+MessageHandler.cancelRP+' in Stripe.' :  value;
            
            if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update') && Schema.sObjectType.Q_Charge__Transaction__c.isUpdateable()){
                List<Transaction__c> scheduledTransaction = [Select Id,Transaction_Status__c from Transaction__c where Recurring_Payment__c =: reccur.id AND Transaction_Status__c = 'Scheduled' WITH SECURITY_ENFORCED limit 1];
                if(scheduledTransaction.size() == 1){
                    scheduledTransaction[0].Transaction_Status__c = 'Cancelled';
                }
                Update scheduledTransaction;
            }
        }
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        return value;
    }

    
    /*********************** Fetch Subscription and its transactions *******************************/    
    public static String fetchCompletedRPTransactions(List<Recurring_Payment__c> recurringPaymentlist, Date FetchInvoiceFrom){ 
        String responseMessage = ''; 
        String filter = null;       
        RecurringWrapper recWrap = new RecurringWrapper();
        Recurring_Payment__c reccur = new Recurring_Payment__c();
        Boolean isTransactionAvailable = false;
        Boolean isUpdateScheduleTranRequired;
        Integer indexOfScheduleTran;
        Transaction__c Scheduledtran = new Transaction__c();
        If([SELECT Id FROM Transaction__c Where Recurring_Payment__c  IN: recurringPaymentlist AND Transaction_Status__c =: ScheduleKeyWord WITH SECURITY_ENFORCED limit 1].size() > 0 ){
            isTransactionAvailable = true;
            Scheduledtran = [SELECT Id,Amount__c,Transaction_Date__c FROM Transaction__c Where Recurring_Payment__c IN: recurringPaymentlist AND Transaction_Status__c =:ScheduleKeyWord WITH SECURITY_ENFORCED limit 1];
        }
        for(Recurring_Payment__c rec : recurringPaymentlist){
            recWrap.recurringRequestId = rec.Gateway_Schedule_Id__c;
            recWrap.sfProcessingId = rec.RelatedToId__c;
            recWrap.instalPeriod = rec.Installment_Period__c;
            // filter from created date.
            if(FetchInvoiceFrom != null){
                filter = '&created[gte]='+convertDateToUnix(FetchInvoiceFrom);
            }        
            
            recWrap = StripeManager.getTransactionRP(recWrap, filter);
            if(recWrap.status && Schema.sObjectType.Q_Charge__Transaction__c.isCreateable()
            && Schema.sObjectType.Q_Charge__Transaction__c.isUpdateable()
            && Schema.sObjectType.Q_Charge__Recurring_Payment__c.isUpdateable()){
                StripeSubscriptionWrapper ScheduleWrapper = (StripeSubscriptionWrapper)JSON.deserialize(recWrap.recurringResponse, StripeSubscriptionWrapper.Class);
                reccur = MappingRecurringPayment(ScheduleWrapper, rec, 'Update',false);
                
                
                if(recWrap.transactionList != null && !recWrap.transactionList.isEmpty()){
                    
                    // update the existing schedule record to paid.
                    if(rec.Id != null && isTransactionAvailable){
                        isUpdateScheduleTranRequired = false;
                        
                        for(TransactionWrapper eachTran : recWrap.transactionList){
                            if(Scheduledtran.Transaction_Date__c == eachTran.transactionDate){
                                Scheduledtran = MapScheduleTransaction(Scheduledtran, eachTran, 'Update');
                                isUpdateScheduleTranRequired = true;
                                indexOfScheduleTran = recWrap.transactionList.indexOf(eachTran);
                                break;
                            }
                        }
                    }
                }            
                responseMessage = (responseMessage != '' ? responseMessage : 'succeeded:'+recWrap.recurringResponse);
            }else{
                responseMessage = recWrap.errorResponse;
            }
        }
        
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'upsert') && UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
            Database.SaveResult sr = Database.update(reccur, true);
            if(isUpdateScheduleTranRequired){
                recWrap.transactionList.remove(indexOfScheduleTran);
                Database.SaveResult stran = Database.update(Scheduledtran, true); 
            }
            Database.UpsertResult[] sinvList = Database.upsert(MappingRecurringTransaction(recWrap.transactionList, sr.getId(), 'Upsert'), Transaction__c.Transaction_Id__c, true);
            for(Database.UpsertResult sinv : sinvList){
                if(!sinv.isSuccess())
                responseMessage = sinv.getErrors()[0].getMessage();
            }
        }

        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
        return responseMessage;
    }
    
    /*******Method to map Recurring Payment*****/
    public static Recurring_Payment__c MappingRecurringPayment(StripeSubscriptionWrapper subWrap, Recurring_Payment__c reccur, String Permcheck,Boolean updateCardInfo){ 
        if(reccur == null)
        reccur = new Recurring_Payment__c(); 
        if(Permcheck == 'Update')
        UTILGateway.allowRPUpdate = true;
        
        if((Permcheck == 'Create' && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isCreateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isCreateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isCreateable()
        && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isCreateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Last_Installment_Date__c.isCreateable()) || 
        (Permcheck == 'Update' && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isUpdateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isUpdateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable()
        && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isUpdateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Last_Installment_Date__c.isUpdateable()) ){
            reccur.Amount__c = StripeManager.convertCentToDollar(subWrap.plan.amount);
            reccur.Date_Established__c = DateTime.newInstance(Long.valueOf(String.valueOf(subWrap.created)+ '000')).date();
            reccur.Next_Installment_Date__c = DateTime.newInstance(Long.valueOf(String.valueOf(subWrap.current_period_end)+ '000')).date();
            reccur.Last_Installment_Date__c = DateTime.newInstance(Long.valueOf(String.valueOf(subWrap.current_period_start)+ '000')).date();
            reccur.Gateway_Name__c = UTILGateway.STRIPEWORD; 
            String interval = null;
            if(subWrap.plan != null && subWrap.plan.interval != null && subWrap.plan.interval_count != null){
                interval = StripeScheduleHandler.convertPlanToInstalmentPeriod(subWrap.plan.interval,subWrap.plan.interval_count);
                subWrap.Installment_Period = (interval != null ? interval : subWrap.Installment_Period);
            }
            reccur.Installment_Period__c = subWrap.Installment_Period;
            reccur.Status__c = (subWrap.status =='active' || subWrap.status =='trialing' ? OpenKeyWord : (subWrap.status == 'canceled' ? ClosedKeyWord: subWrap.status )); 
            reccur.RelatedToId__c = subWrap.RelatedToId;
            reccur.Gateway_Schedule_Id__c = subWrap.id;
            if(subWrap.default_pay_method != null && updateCardInfo){
                MappingRecurringPaymentIntent(subWrap.default_pay_method, reccur, Permcheck);
            }
        }
        return reccur;
    }
    
    /*******Method to map card details field in Recurring Payment*******/
    public static Recurring_Payment__c MappingRecurringPaymentIntent(StripePaymentMethodwrapper subWrap, Recurring_Payment__c reccur, String Permcheck){ 
        if(Permcheck == 'Update')
        UTILGateway.allowRPUpdate = true;      
        if((Permcheck == 'Create' && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isCreateable() 
        && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Type__c.isCreateable() ) || 
        (Permcheck == 'Update' && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable()
        && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Type__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable() ) ){                
            reccur.Card_Name__c = subWrap.billing_details != null ? subWrap.billing_details.name : null;
            reccur.Card_Number__c = subWrap.card != null ? 'xxxx '+subWrap.card.last4 : null;
            reccur.Card_Expiry_Date__c = subWrap.card != null ? Date.newinstance(subWrap.card.exp_year, subWrap.card.exp_month,  Date.daysInMonth(subWrap.card.exp_year, subWrap.card.exp_month)) : null; 
            reccur.Card_Type__c = subWrap.card != null ? subWrap.card.brand.toUpperCase() : (subWrap.type != null) ? subWrap.type.toUpperCase() : ''; 
            reccur.Card_Last_Updated_On__c = DateTime.now();    
        }
        return reccur;
    }
    
    /********Method to map Recurring Payment Transactions********/
    public static List<Transaction__c> MappingRecurringTransaction(List<TransactionWrapper> InvoicesList, String SFRecurringId, String Permcheck){
        List<Transaction__c> transactList = new List<Transaction__c>(); 
        
        if(Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() 
        && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable() 
        && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() 
        && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable()){
            for(TransactionWrapper invoice : InvoicesList){                                      
                Transaction__c eachTranct = new Transaction__c();
                eachTranct.Amount__c = invoice.amount;
                eachTranct.Recurring_Payment__c = SFRecurringId;
                eachTranct.Gateway_Name__c = UTILGateway.STRIPEWORD; 
                eachTranct.Transaction_Id__c = invoice.transactionId;
                //eachTranct.Payment_Id__c = invoice.paymentId;                   
                eachTranct.Transaction_Status__c = invoice.transactionStatus =='succeeded' ? PaidKeyWord : (invoice.transactionStatus == 'draft' ? ScheduleKeyWord : invoice.transactionStatus);
                eachTranct.Transaction_Date__c = invoice.transactionDate; 
                eachTranct.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Recurring').getRecordTypeId();
                transactList.add(eachTranct);                   
            } 
        }        
        return transactList;
    }
    
    /****Method to map transactions for one-time payment******/
    public static Transaction__c MappingOneTimeTransaction(TransactionWrapper tran, String Permcheck){
        Transaction__c eachTranct = new Transaction__c();        
        if(Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() 
        && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()
        && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() 
        && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable()){
            eachTranct.Amount__c = tran.amount;
            eachTranct.Gateway_Name__c = UTILGateway.STRIPEWORD; 
            eachTranct.Transaction_Id__c = tran.transactionId;
            //eachTranct.Payment_Id__c = tran.paymentId;
            eachTranct.Transaction_Status__c = tran.transactionStatus =='succeeded' ? PaidKeyWord : tran.transactionStatus;
            eachTranct.Transaction_Date__c = DateTime.now(); //tran.transactionDate;
            eachTranct.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('One_Time').getRecordTypeId();
        }
        return eachTranct;
    }
    
    /*****Method to map transactions for recurring payment******/
    public static Transaction__c MapScheduleTransaction(Transaction__c tranRec, TransactionWrapper tran, String Permcheck){
        if(Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()
           && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable()){
            tranRec.Transaction_Id__c = tran.transactionId;
            //tranRec.Payment_Id__c = tran.paymentId;
            tranRec.Amount__c = tran.amount;
            tranRec.Transaction_Status__c = tran.transactionStatus == 'succeeded' ? PaidKeyWord :  (tran.transactionStatus == 'draft' ? ScheduleKeyWord : tran.transactionStatus); 
        }
        return tranRec;
    }
    
    public static String convertDateToUnix(Date ToDate){
        Integer daysBetween = Date.today().daysBetween(ToDate);  
        return String.valueOf(Datetime.now().addDays(daysBetween).getTime() / 1000); // Divided by 1000 to get values in Seconds.
    }
    
}