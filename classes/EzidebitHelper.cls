public with sharing class EzidebitHelper {
    
    /**************Method to process one time request*************/
    public static String ProcessOneTimeRequest(Payment_Log__c log){
        try{
            String returnValue='';
            TransactionWrapper oneWrap = new TransactionWrapper();
            oneWrap.sfProcessingId=log.Processing_Record_Id__c;
            oneWrap.amount=log.Amount__c;
            oneWrap.transactionType=UTILGateway.ONETIMEKEYWORD;
            List<Payment_Log__c> logList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            log=logList.get(logList.size()-1);
            oneWrap.logrefId=log.Id;
            oneWrap.requestUrl=log.Requesting_Url__c;
            UTILGateway.PayLogSet_JSON.clear();
            oneWrap=EzidebitManager.requestOneTimePayment(oneWrap);//remove maintain log from chargenowcontroller
            returnValue=(oneWrap.status) ? oneWrap.processingLink : oneWrap.errorResponse;
            return returnValue;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /**************Method to process recurring request*************/
    public static String ProcessRecurringRequest(Payment_Log__c log){
        try{
            List<Payment_Log__c> paymentLogList=new List<Payment_Log__c>();
            Id recordId=log.Processing_Record_Id__c;
            Contact newContact=[Select FirstName,LastName from Contact where Id=:recordId WITH SECURITY_ENFORCED Limit 1];
            String value ='';        
            RecurringWrapper reccWrapper = new RecurringWrapper();
            reccWrapper.amount=log.Amount__c;
            reccWrapper.sfProcessingId=log.Processing_Record_Id__c;
            reccWrapper.name=newContact.FirstName+' '+newContact.LastName;
            reccWrapper.instalPeriod=log.Frequency__c;
            reccWrapper.startDate=log.Recurring_Start_Date__c;
            reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD;
            reccWrapper.requestUrl=log.Requesting_Url__c;
            log.Serialized_Record__c=JSON.serialize(reccWrapper);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
            paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
            log=paymentLogList.get(paymentLogList.size()-1);
            reccWrapper.transactionreference=log.Id;
            reccWrapper.recurringRequestId=log.Id+''+String.valueOf(Datetime.now().getTime());
            reccWrapper =  EzidebitManager.requestRecurringPayment(reccWrapper);
            value=(reccWrapper.status)?reccWrapper.processingLink:reccWrapper.errorResponse;
            return value;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /***************Method to process one time transaction during checkout************************/
    public static TransactionWrapper ProcessingOneTimeTransaction(TransactionWrapper transWrapper){
        try{
            ReceiptWrapper receipt=new ReceiptWrapper();
            receipt.paymentId=transWrapper.transactionId;
            receipt.amount=transWrapper.amount;
            receipt.chargeType=transWrapper.transactionType;
            receipt.paymentStatus=(transWrapper.transactionStatus == 'APPROVED') ? 'Transaction Approved' : transWrapper.transactionStatus;
            receipt.requestUrl=transWrapper.requestUrl;
            List<Payment_Log__c> paymentLogList=new List<Payment_Log__c>();
            if(transWrapper.transactionStatus=='APPROVED'){
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'insert')){
                	Transaction__c oneoffTransaction = mapOneOffTransaction(transWrapper);
                	insert oneoffTransaction;
                }
                transWrapper.transResponse='Payment is charged successfully.';
                receipt.paymentResponse=transWrapper.transResponse;
                EzidebitManager.checkoutComplete(transWrapper, receipt);   
                paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
                transWrapper.logrefId=newLog.Id;
            }else{
                transWrapper.transResponse='Payment is failed due to '+EzidebitManager.getResponseMsg(transWrapper.transactionResponseCode)+'.';
                receipt.paymentResponse=transWrapper.transResponse;
                receipt.paymentStatus='Transaction Rejected';
                transWrapper=retryOneTimePayment(transWrapper,receipt);
            }
            return transWrapper;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
        
    }
    
    /*********************Method to retry one time payment during checkout**********************/
    public static TransactionWrapper retryOneTimePayment(TransactionWrapper wrapper,ReceiptWrapper receipt){
        try{
            wrapper=EzidebitManager.requestOneTimePayment(wrapper);
            String redirectUrl=wrapper.status?wrapper.processingLink:wrapper.errorResponse;
            String serializedWrapper=JSON.serialize(receipt);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.onetimeCheckoutfail, Http_Response__c=JSON.serialize(wrapper),Request_Type__c='POST',Amount__c=wrapper.Amount,Charge_Type__c=wrapper.transactionType,End_Point__c=wrapper.successUrl,Serialized_Record__c=serializedWrapper,Retry_Schedule_Url__c=redirectUrl,Gateway_Name__c=UtilGateway.EZIDEBITWORD)));
            List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
            wrapper.logrefId=newLog.Id;
            return wrapper;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    public static RecurringWrapper validationChecksBeforeRPCreation(RecurringWrapper wrapperRP,Payment_Log__c ref_log){
        try{
            wrapperRP.status=false;
            wrapperRP=EzidebitManager.validateCreditCardDetails(wrapperRP);
            wrapperRP.responseCode=wrapperRP.responseMessage.substringBefore(' ');
            wrapperRP.requestUrl=ref_log.Requesting_Url__c;
            wrapperRP.logrefId=ref_log.Id;
            if(wrapperRP.responseMessage.substringAfter(':')=='APPROVED'){
                wrapperRP.status=true;
                wrapperRP.refundId=wrapperRP.responseMessage.substringBetween(' ',':');
                wrapperRP.refundStatus='Awaiting';
            }else{
                wrapperRP=EzidebitManager.changeCustomerStatus(wrapperRP);
            }
            return wrapperRP;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /******************Method to process recurring payment during checkout*************/
    public static RecurringWrapper ProcessingRecurringPayment(RecurringWrapper reccWrapper){
        try{
            List<Payment_Log__c> paymentLogList=new List<Payment_Log__c>();
            String response='';
            ReceiptWrapper receipt = new ReceiptWrapper();
            receipt.amount=reccWrapper.amount;
            receipt.chargeType=reccWrapper.transactionType;
            receipt.establishmentDate=Date.today();
            receipt.nextInstallmentDate=reccWrapper.startDate;
            receipt.installPeriod=reccWrapper.instalPeriod;
            receipt.requestUrl=reccWrapper.requestUrl;
            if(reccWrapper.responseMessage.substringAfter(':').trim()=='APPROVED'){
                receipt.paymentStatus='Payment Approved';
                reccWrapper=EzidebitManager.getScheduledTransactions(reccWrapper);
                if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'create')){
                    Recurring_Payment__c newRP=mapRecurringPayment(reccWrapper);
                    insert newRP;
                    if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                        List<Transaction__c> transactionList=mapRecurringTransactions(reccWrapper.transactionList,newRP.Id);
                        insert transactionList;
                        reccWrapper.responseMessage = MessageHandler.recurringSuccess;
                        receipt.paymentResponse=reccWrapper.responseMessage;
                        // UTILGateway.PayLogSet_JSON.clear();
                        eddrCheckoutComplete(reccWrapper,receipt);
                        paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                        Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
                        reccWrapper.logrefId=newLog.Id;
                    }
                }
            }else{
                reccWrapper.responseMessage= MessageHandler.recurringFailed + EzidebitManager.getResponseMsg(reccWrapper.responseCode)+'. Click on Retry to setup the Recurring Payment again.';
                receipt.paymentStatus='Payment Rejected';
                receipt.paymentResponse=reccWrapper.responseMessage;
                reccWrapper=retryRecurringPayment(reccWrapper, receipt);
            }
            return reccWrapper;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /**********************Method to retry the recurring payment during checkout************************/
    public static RecurringWrapper retryRecurringPayment(RecurringWrapper wrapper,ReceiptWrapper receipt){
        try{
            wrapper.recurringRequestId=wrapper.logrefId+''+String.valueOf(Datetime.now().getTime());
            wrapper.instalPeriod=EzidebitManager.handleFrequencies(wrapper.instalPeriod,false);
            wrapper=EzidebitManager.requestRecurringPayment(wrapper);
            String redirectUrl=(wrapper.status)?wrapper.processingLink:wrapper.errorResponse;
            String serializedWrapper=JSON.serialize(receipt);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.retryRPRequest, Http_Response__c=JSON.serialize(wrapper),Request_Type__c='POST',Amount__c=wrapper.Amount,Charge_Type__c=wrapper.transactionType,End_Point__c=wrapper.successUrl,Serialized_Record__c=serializedWrapper,Retry_Schedule_Url__c=redirectUrl,Frequency__c=wrapper.instalPeriod,Recurring_Start_Date__c=wrapper.startDate,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
            List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
            wrapper.logrefId=newLog.Id;
            return wrapper;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /***************Method to map fields for one time transaction*****************/
    public static Transaction__c mapOneOffTransaction(TransactionWrapper wrapper){
        try{
            Transaction__c oneoffTransaction = new Transaction__c();
            if(Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() &&
               Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()){
                   oneoffTransaction.Amount__c=wrapper.amount;
                   oneoffTransaction.Gateway_Name__c=UTILGateway.EZIDEBITWORD;
                   oneoffTransaction.Transaction_Date__c=Datetime.now();
                   oneoffTransaction.Transaction_Status__c='Paid';
                   oneoffTransaction.RecordTypeId=Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('One Time').getRecordTypeId();
                   oneoffTransaction.Transaction_Id__c=wrapper.transactionId;
               }else{
                   throw new UTILPermission.PermsException('Transaction__c','Amount__c,Gateway_Name__c,Transaction_Date__c,Transaction_Status__c,RecordTypeId,Transaction_Id__c','Create');
               }
            return oneoffTransaction;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
        
    }
    /**********Method to map fields for recurring payment********************/
    public static Recurring_Payment__c mapRecurringPayment(RecurringWrapper wrapper){
        try{
            Recurring_Payment__c newRecurringPayment=new Recurring_Payment__c();
            if(UTILPermission.CheckSinglePerm('create', 'Q_Charge__Recurring_Payment__c', new Set<String>{'Q_Charge__Amount__c','Q_Charge__Date_Established__c','Q_Charge__Next_Installment_Date__c','Q_Charge__Gateway_Name__c','Q_Charge__Installment_Period__c','Q_Charge__Status__c','Q_Charge__RelatedToId__c','Q_Charge__Gateway_Schedule_Id__c','Q_Charge__Gateway_Refund_Id__c','Q_Charge__Refund_Status__c','Q_Charge__Refund_Amount__c'})){
                if((Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isCreateable() &&
                    Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isCreateable() &&
                    Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isCreateable()
                    && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isCreateable()
                    &&Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isCreateable())
                   ||
                   (Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() &&
                    Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable() &&
                    Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable()
                    && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isUpdateable()
                    &&Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isUpdateable())){
                        newRecurringPayment.Amount__c=wrapper.amount;
                        newRecurringPayment.Date_Established__c=Date.today();
                        newRecurringPayment.Next_Installment_Date__c=wrapper.startDate;
                        newRecurringPayment.Gateway_Name__c=UTILGateway.EZIDEBITWORD;
                        newRecurringPayment.Installment_Period__c=wrapper.instalPeriod;
                        newRecurringPayment.Status__c='Open';
                        newRecurringPayment.RelatedToId__c=wrapper.sfProcessingId;
                        newRecurringPayment.Gateway_Schedule_Id__c=wrapper.recurringRequestId.toUpperCase();
                        newRecurringPayment.Gateway_Refund_Id__c=wrapper.refundId;
                        newRecurringPayment.Refund_Status__c=wrapper.refundStatus;
                        newRecurringPayment.Refund_Amount__c=1.00;
                        
                        //Fetching card details of a customer
                        wrapper = EzidebitManager.fetchCardDetails(wrapper);
                        if(wrapper.cardDetails.ErrorMessage==null || wrapper.cardDetails.ErrorMessage.length()==0){
                            newRecurringPayment.Card_Last_Updated_On__c = Datetime.now();
                            newRecurringPayment.Card_Name__c = wrapper.cardDetails.CardHolderName;
                            newRecurringPayment.Card_Number__c = 'xxxx '+wrapper.cardDetails.CardNumber.right(4);
                            newRecurringPayment.Card_Expiry_Date__c = ((wrapper.cardDetails.ExpiryMonth != null) && (wrapper.cardDetails.ExpiryYear != null)) ? Date.newinstance(Integer.valueOf(wrapper.cardDetails.ExpiryYear), Integer.valueOf(wrapper.cardDetails.ExpiryMonth), Date.daysInMonth(Integer.valueOf(wrapper.cardDetails.ExpiryYear), Integer.valueOf(wrapper.cardDetails.ExpiryMonth))): null;
                        }
                    }else{
                        throw new UTILPermission.PermsException('Recurring_Payment___c','Amount__c,Date_Established__c,Next_Installment_Date__c,Gateway_Name__c,Installment_Period__c,Status__c,RelatedToId__c,Gateway_Schedule_Id__c,Gateway_Refund_Id__c,Refund_Status__c,Refund_Amount__c','Create');
                    }
            }
            return newRecurringPayment;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /******************Method to map fields for recurring payment transactions*********************/
    public static List<Transaction__c> mapRecurringTransactions(List<TransactionWrapper> wrapperList,Id recurringId){
        try{
            List<Transaction__c> transactionsList=new List<Transaction__c>();
            for(TransactionWrapper wrapperInfo:wrapperList){
                Transaction__c transactionInfo=new Transaction__c();
                if((Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable()) &&
                   (Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable())){
                       transactionInfo.RecordTypeId=Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
                       transactionInfo.Amount__c=wrapperInfo.amount;
                       transactionInfo.Transaction_Date__c=Datetime.newInstanceGmt(wrapperInfo.transactionDate.year(),wrapperInfo.transactionDate.month(),wrapperInfo.transactionDate.day(),0,0,0);
                       transactionInfo.Recurring_Payment__c=recurringId;
                       transactionInfo.Transaction_Status__c='Scheduled';
                       transactionInfo.Gateway_Name__c=UTILGateway.EZIDEBITWORD;
                   }else{
                       throw new UTILPermission.PermsException('Transaction__c','RecordTypeId,Amount__c,Transaction_Date__c,Recurring_Payment__c,Transaction_Status__c,Gateway_Name__c','Create');
                       
                   }
                transactionsList.add(transactionInfo);
            }
            return transactionsList;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /***************Method to refund from gateway**************** */
    public static void refundEzidebit(List<Recurring_Payment__c> recurringPaymentlist){
        List<Recurring_Payment__c> updatedRPList = new List<Recurring_Payment__c>();
        for(Recurring_Payment__c recurringPayment : recurringPaymentlist){
            RecurringWrapper reccWrapper=new RecurringWrapper();
            reccWrapper.refundId=recurringPayment.Gateway_Refund_Id__c;
            reccWrapper.recurringRequestId=recurringPayment.Gateway_Schedule_Id__c;
            String returnValue=EzidebitManager.getRefund(reccWrapper);
            System.debug(returnValue);
            if(Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable() &&Schema.sObjectType.Recurring_Payment__c.fields.Refund_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isUpdateable()){
                if(returnValue=='Approved'){
                    recurringPayment.Refund_Status__c='REFUNDED';
                    recurringPayment.Refund_Date__c=Datetime.now();
                    recurringPayment.Refund_Description__c=returnValue;
                }
                else if(returnValue.contains('not settled')){
                    recurringPayment.Refund_Description__c=returnValue;
                }
                else{
                    recurringPayment.Refund_Description__c=returnValue;
                    recurringPayment.Refund_Status__c='Failed';
                }
                updatedRPList.add(recurringPayment);
            }
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
            UTILGateway.allowRPUpdate = true; //[VS] implemented for Test purpose
            update updatedRPList;
        }
    } 
    
    
    /*********************Method used in batch to fetch the completed transactions*****************/
    public static void fetchCompletedRPTransactions(List<Recurring_Payment__c> recurringPaymentlist){
        if(EzidebitManager.detachedReason!=null){
            throw new GatewayException(EzidebitManager.detachedReason);
        }
        if(Q_Charge__Recurring_Payment__c.sObjectType.getDescribe().isAccessible() && Q_Charge__Recurring_Payment__c.sObjectType.getDescribe().isUpdateable()
           && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable()
           && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() 
           && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable()
           && Q_Charge__Transaction__c.sObjectType.getDescribe().isCreateable() && Q_Charge__Transaction__c.sObjectType.getDescribe().isUpdateable()
           && Q_Charge__Transaction__c.sObjectType.getDescribe().isAccessible() && Q_Charge__Transaction__c.sObjectType.getDescribe().isDeletable()){
               
               List<Transaction__c> existingTransactionList=new List<Transaction__c>();
               List<Recurring_Payment__c> updatedRPList = new List<Recurring_Payment__c>();
               List<Transaction__c> transactionsList = [Select Id,Transaction_Date__c,Transaction_Id__c,Recurring_Payment__c,Transaction_Status__c from Transaction__c where Recurring_Payment__c IN: recurringPaymentlist and Transaction_Date__c<=Today AND (Transaction_Status__c='Scheduled' OR Transaction_Status__c='PENDING' OR Transaction_Status__c='DISHONOURED') WITH SECURITY_ENFORCED];
               List<TransactionWrapper> fetchedScheduledTransactions=new List<TransactionWrapper>();
               Boolean clearUnprocessedTransactions=false;
               
               Recurring_Payment__c recurringPayment = new Recurring_Payment__c();
               for(Recurring_Payment__c fetchRP : recurringPaymentlist){
                   recurringPayment = fetchRP;
               }
               Boolean isScheduled=false;
               Integer scheduledTransactionIndex=0;
               
               for(Transaction__c trans : transactionsList){
                   TransactionWrapper transWrapper = new TransactionWrapper();
                   transWrapper.transactionStatus=trans.Transaction_Status__c;
                   transWrapper.transactionDateTime=trans.Transaction_Date__c; 
                   EzidebitManager.getTransaction(recurringPayment.Gateway_Schedule_Id__c, transWrapper);
                   trans.Transaction_Status__c=transWrapper.transactionStatus;
                   trans.Transaction_Date__c=transWrapper.transactionDateTime; 
                   trans.Transaction_Id__c=transWrapper.transactionId;
                   if(transWrapper.transactionStatus=='Scheduled'){
                       isScheduled=true;
                       scheduledTransactionIndex=transactionsList.indexOf(trans);
                   }
               }
               
               RecurringWrapper reccWrapper=new RecurringWrapper();
               reccWrapper.recurringRequestId=recurringPayment.Gateway_Schedule_Id__c;
               reccWrapper.amount=recurringPayment.Amount__c;
               reccWrapper.startDate=recurringPayment.Next_Installment_Date__c;
               reccWrapper.instalPeriod=recurringPayment.Installment_Period__c;
               //Checks if any changes to the frequency in Ezidebit Server
               clearUnprocessedTransactions=EzidebitManager.getCustomerDetails(reccWrapper);
               if(Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isAccessible() 
                  && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() && clearUnprocessedTransactions){
                   recurringPayment.Installment_Period__c=reccWrapper.instalPeriod;
               }
               
               //check if any scheduled payments are remaining
               existingTransactionList = [Select Id from Q_Charge__Transaction__c where Recurring_Payment__c=:recurringPayment.Id and Transaction_Status__c='Scheduled' and Id NOT IN :transactionsList WITH SECURITY_ENFORCED];
               //create new transactions if any change in the frequency or scheduled transactions are completed
               if(Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() && clearUnprocessedTransactions || existingTransactionList.size()==0){
                   fetchedScheduledTransactions=EzidebitManager.getTransactionsRP(recurringPayment.Gateway_Schedule_Id__c);
                   transactionsList.addAll(mapRecurringTransactions(fetchedScheduledTransactions,recurringPayment.Id));
                   TransactionWrapper wrap=fetchedScheduledTransactions.get(0);
                   recurringPayment.Next_Installment_Date__c=wrap.transactionDate; 
                   
               }else{
                   if(Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isAccessible() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable()
                      && transactionsList.size()>0 && !isScheduled){
                          Datetime newTransactionDatetime = [Select Recurring_Payment__c,Transaction_Date__c from Q_Charge__Transaction__c where (Recurring_Payment__c =:recurringPayment.Id and Transaction_Status__c='Scheduled') and Id NOT IN :transactionsList WITH SECURITY_ENFORCED Limit 1].Transaction_Date__c;
                          recurringPayment.Next_Installment_Date__c = newTransactionDatetime.date();
                      }else if(isScheduled){
                          recurringPayment.Next_Installment_Date__c=transactionsList.get(scheduledTransactionIndex).Transaction_Date__c.date();
                      }
               }
               updatedRPList.add(recurringPayment);
                              
               if(Q_Charge__Transaction__c.sObjectType.getDescribe().isAccessible() && Q_Charge__Transaction__c.sObjectType.getDescribe().isDeletable() && clearUnprocessedTransactions && existingTransactionList.size()>0 ){
                       delete existingTransactionList;
               }
               
               upsert transactionsList; 
               UTILGateway.allowRPUpdate = true;
               update updatedRPList;
           }
    }
    
    /*****************Method to request update card detail page***************/
    public static String requestUpdateCardDetailPage(String recurringId,String gatewayScheduleId,String requestUrl){
        String returnValue='';
        Payment_Log__c log= new Payment_Log__c(Processing_Record_Id__c=recurringId,Action__c=UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.updateCardRequest,Transaction_Id__c=gatewayScheduleId,Requesting_Url__c=requestUrl,Gateway_Name__c=UTILGateway.EZIDEBITWORD);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
        RecurringWrapper updateWrapper = new RecurringWrapper();
        updateWrapper.transactionreference=newLog.Id;
        updateWrapper=EzidebitManager.updateCardDetails(updateWrapper);
        returnValue=(updateWrapper.status)?updateWrapper.processingLink:updateWrapper.errorResponse;
        return returnValue;
    }
    
    /****************Method to update card details*****************/
    public static RecurringWrapper UpdateCardDetailsHelper(RecurringWrapper wrapper){
        wrapper.status=false;
        wrapper=EzidebitManager.validateCreditCardDetails(wrapper);
        if(wrapper.responseMessage.substringAfter(':')=='APPROVED'){
            wrapper=EzidebitManager.fetchCardDetails(wrapper);
            if(wrapper.cardDetails.ErrorMessage==null || wrapper.cardDetails.ErrorMessage.length()==0){
                wrapper.status=true;
            }
        }else{
            wrapper.errorResponse='Update card detail failed';
            wrapper=retryUpdateCardDetails(wrapper);
        }
        return wrapper;
    }
    
    /******************Method to retry update card details*****************/
    public static RecurringWrapper retryUpdateCardDetails(RecurringWrapper wrapper){
        String redirectUrl=requestUpdateCardDetailPage(wrapper.sfProcessingId, wrapper.recurringRequestId, wrapper.requestUrl);
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.chargeType=wrapper.transactionType;
        receipt.amount=wrapper.amount;
        receipt.paymentResponse=MessageHandler.failedUpdateCard;
        receipt.paymentStatus='Transaction Rejected';
        Payment_Log__c log= new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c = UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.updateCardfail,Transaction_Id__c=wrapper.recurringRequestId,Serialized_Record__c=JSON.serialize(receipt),Requesting_Url__c=wrapper.requestUrl,Gateway_Name__c=UTILGateway.EZIDEBITWORD,Retry_Schedule_Url__c=redirectUrl);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        return wrapper;
    }
    
    /**********************Method to update the recurring payment***************/
    public static RecurringWrapper ProcessUpdateRecurringPayment(RecurringWrapper reccWrapper){
        if(!EzidebitManager.isConnected){
            reccWrapper.status=false;
            reccWrapper.errorResponse='failed:'+EzidebitManager.detachedReason;
            return reccWrapper;
        }
        String dayOfWeek=Datetime.newInstance(reccWrapper.startDate.year(),reccWrapper.startDate.month(),reccWrapper.startDate.day()).format('EEEE');
        if(reccWrapper.amount<1){
            reccWrapper.status=false;
            reccWrapper.errorResponse='failed:'+MessageHandler.amountBelowOneDoller;
            return reccWrapper;
        }else if(reccWrapper.amount>10000){
            reccWrapper.status=false;
            reccWrapper.errorResponse='failed:'+MessageHandler.amountMoreThanLimit;
            return reccWrapper;
        }else if(reccWrapper.startDate<Date.today()){
            reccWrapper.status=false;
            reccWrapper.errorResponse='failed:'+MessageHandler.prevStartDate;
            return reccWrapper;
        }else if(reccWrapper.startDate==Date.today()){
            Datetime currentDT=Datetime.now();
            String convertedDT=currentDT.format('yyyy-MM-dd HH:mm:ss a', 'Australia/Brisbane');
            convertedDT=convertedDT.substringAfter(' ');
            List<String> splitConvertedDT=convertedDT.split(':');
            Integer currentTime=Integer.valueOf(splitConvertedDT.get(0));
            Integer currentTimeMinutes=Integer.valueOf(splitConvertedDT.get(1));
            if(currentTime>=15){
                reccWrapper.status=false;
                reccWrapper.errorResponse='failed:'+MessageHandler.ezidebitprocessingTimeProductionRecurringUpdate;
                return reccWrapper;
            }
        }else if(dayOfWeek=='Saturday' || dayOfWeek=='Sunday'){
            reccWrapper.status=false;
            reccWrapper.errorResponse='failed:'+MessageHandler.ezidebitWeekendUpdate;
            return reccWrapper;
        }
        reccWrapper.instalPeriod=EzidebitManager.handleFrequencies(reccWrapper.instalPeriod, true);
        if(reccWrapper.instalPeriod=='W' || reccWrapper.instalPeriod=='F' || reccWrapper.instalPeriod=='4' || reccWrapper.instalPeriod=='N'){
            reccWrapper.recurringAbbr=dayOfWeek.substring(0,3).toUpperCase();
        }else if(reccWrapper.instalPeriod=='M'){
            reccWrapper.recurringAbbr=String.valueOf(reccWrapper.startDate.day());
        }
        Id recurringId=reccWrapper.sfProcessingId;
        Boolean isScheduled=true;
        Date today=Date.today();//Datetime.newInstance(2022,01,28);
        Date yesterday=Date.today().addDays(-1);///Datetime.newInstance(2022,01,27);
        List<Transaction__c> transactionsList = [Select Id,Transaction_Date__c,Transaction_Id__c,Recurring_Payment__c,Transaction_Status__c from Transaction__c where Recurring_Payment__c=:recurringId AND (Transaction_Date__c<=Today AND Transaction_Date__c>= Yesterday) AND (Transaction_Status__c='Scheduled' OR Transaction_Status__c='PENDING' OR Transaction_Status__c='DISHONOURED') WITH SECURITY_ENFORCED];
        for(Transaction__c trans : transactionsList){
            TransactionWrapper transWrapper = new TransactionWrapper();
            transWrapper.transactionStatus=trans.Transaction_Status__c;
            transWrapper.transactionDateTime=trans.Transaction_Date__c; 
            EzidebitManager.getTransaction(reccWrapper.recurringRequestId, transWrapper);
            if(transWrapper.transactionStatus!=null && trans.Transaction_Status__c!=transWrapper.transactionStatus){
                isScheduled=false;
            }
            trans.Transaction_Status__c=transWrapper.transactionStatus==null?'Scheduled':transWrapper.transactionStatus;
            trans.Transaction_Date__c=transWrapper.transactionDateTime==null?trans.Transaction_Date__c:transWrapper.transactionDateTime; 
            
        }
        reccWrapper.amount=convertDollarToCent(reccWrapper.amount,'cent');
        reccWrapper=EzidebitManager.createSchedule(reccWrapper);
        reccWrapper=EzidebitManager.getScheduledTransactions(reccWrapper);
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update') && !isScheduled){
            update transactionsList;
        }
        List<Transaction__c> deleteScheduledTransactions=[Select Id from Transaction__c where Recurring_Payment__c=:recurringId and Transaction_Status__c='Scheduled' With SECURITY_ENFORCED];
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'delete')){
            delete deleteScheduledTransactions;
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'insert')){
            List<Transaction__c> newTransactions=mapRecurringTransactions(reccWrapper.transactionList,reccWrapper.sfProcessingId);
            insert newTransactions;
        }
        Recurring_Payment__c existingRP=[Select Amount__c,Next_Installment_Date__c,Installment_Period__c from Recurring_Payment__c where Id=:recurringId With SECURITY_ENFORCED Limit 1];
        if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() &&
           Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable()){
               existingRP.Amount__c=convertDollarToCent(reccWrapper.amount, 'dollar');
               existingRP.Next_Installment_Date__c=reccWrapper.startDate;
               existingRP.Installment_Period__c=EzidebitManager.handleFrequencies(reccWrapper.instalPeriod, true);
               UTILGateway.allowRPUpdate = true;
               update existingRP;
           }
        if(reccWrapper.responseMessage=='S'){
            reccWrapper.responseMessage=MessageHandler.updateRP + UTILGateway.EZIDEBITWORD.capitalize() +'.';
        }
        return reccWrapper;
        
    }
    
    /************Method to convert dollar to cent vice versa*************/
    public static Decimal convertDollarToCent(Decimal amount,String convertTo){
        if(convertTo=='dollar'){
            amount=amount/100;
        }else if(convertTo=='cent'){
            amount=amount*100;
        }
        return amount;
        
    }
    /**************Helper method to validate credit card***************/
    public static RecurringWrapper validateCreditCardHelper(RecurringWrapper wrapper){
        wrapper=EzidebitManager.validateCreditCardDetails(wrapper);
        return wrapper;
    }
    
    /**************Helper method to change customer status***************/
    public static RecurringWrapper changeCustomerStatusHelper(RecurringWrapper wrapper){
        if(!EzidebitManager.isConnected){
            throw new GatewayException(EzidebitManager.detachedReason);
        }
        wrapper=EzidebitManager.changeCustomerStatus(wrapper);
        return wrapper;
    }
    
    /******Method to get the post checkout url******/
    public static String getPostCheckoutUrl(String id){
        return Url.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__GatewayPostCheckout?reference='+id;
    }
    
    /**********Method to create log after eddr checkout complete************* */
    public static void eddrCheckoutComplete(RecurringWrapper wrapper,ReceiptWrapper receipt){
        String serializedWrapper=JSON.serialize(receipt);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c', 'create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.recPayCheckoutComplete, Http_Response__c=JSON.serialize(wrapper),Request_Type__c='POST',Amount__c=wrapper.amount,Charge_Type__c=wrapper.transactionType,Serialized_Record__c=serializedWrapper,Requesting_Url__c=receipt.requestUrl,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));        
        }
    }
    
    /***********************Method to cancel recurring payment************************/
    public static RecurringWrapper cancelRecurringPayment(List<Recurring_Payment__c> existingRPList){
        if(!EzidebitManager.isConnected){
            throw new GatewayException(EzidebitManager.detachedReason);
        }
        
        RecurringWrapper reccWrapper=new RecurringWrapper();
        Recurring_Payment__c existingRP = new Recurring_Payment__c();
        if(existingRPList.size() > 0){
            for(Recurring_Payment__c recurPayment : existingRPList){
                existingRP = recurPayment;
            }
        }else{
            reccWrapper.responseMessage = MessageHandler.wentWrongCatchMessage;
            return reccWrapper;
        }
        
        reccWrapper.recurringRequestId=existingRP.Gateway_Schedule_Id__c;
        reccWrapper.sfProcessingId=existingRP.Id;
        Id recurringId=existingRP.Id;
        Date installmentDate=existingRP.Next_Installment_Date__c;
        List<Transaction__c> transactionsList = [Select Id,Transaction_Date__c,Transaction_Id__c,Recurring_Payment__c,Transaction_Status__c from Transaction__c where Recurring_Payment__c=:recurringId AND Transaction_Date__c<=:installmentDate AND (Transaction_Status__c='Scheduled' OR Transaction_Status__c='PENDING' OR Transaction_Status__c='DISHONOURED') WITH SECURITY_ENFORCED Limit 1];
        Boolean isScheduled=true;
        for(Transaction__c trans : transactionsList){
            TransactionWrapper transWrapper = new TransactionWrapper();
            transWrapper.transactionStatus=trans.Transaction_Status__c;
            transWrapper.transactionDateTime=trans.Transaction_Date__c; 
            EzidebitManager.getTransaction(reccWrapper.recurringRequestId, transWrapper);
            if(transWrapper.transactionStatus!=null && trans.Transaction_Status__c!=transWrapper.transactionStatus){
                isScheduled=false;
                trans.Transaction_Status__c=transWrapper.transactionStatus==null?'Scheduled':transWrapper.transactionStatus;
                trans.Transaction_Date__c=transWrapper.transactionDateTime==null?trans.Transaction_Date__c:transWrapper.transactionDateTime;
            }  
        }
        reccWrapper=EzidebitManager.changeCustomerStatus(reccWrapper);
        if(!isScheduled && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update')){
            update transactionsList;
        }
        cancelTransactions(recurringId);
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        if(reccWrapper.status && UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable()){
            existingRP.Status__c='Closed';
            UTILGateway.allowRPUpdate = true;
            update existingRP;
            reccWrapper.responseMessage=existingRP.Name+' is '+MessageHandler.cancelRP+ ' in Ezidebit.';
        }
        return reccWrapper;
    }
    
    /*****************Method to change transaction status to cancel after cancelling the recurring payment***********/
    public static void cancelTransactions(String recurringId){
        List<Transaction__c> transactionList=[Select Id,Transaction_Status__c from Transaction__c where Recurring_Payment__c=:recurringId AND Transaction_Status__c='Scheduled' WITH SECURITY_ENFORCED];
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update') && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()){
            for(Transaction__c trans : transactionList){
                trans.Transaction_Status__c='Cancelled';
            }
            
            update transactionList;
        }
        
    }
    
}