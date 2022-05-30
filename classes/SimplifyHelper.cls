public with sharing class SimplifyHelper {
    
    /******Method to process one time request from charge now*****/
    public static String ProcessOneTimeRequest(Payment_Log__c log){
        String returnValue='';
        List<Payment_Log__c> paymentLogList=new List<Payment_Log__c>();
        TransactionWrapper transWrapper=new TransactionWrapper();
        transWrapper.amount=log.Amount__c;
        transWrapper.sfProcessingId=log.Processing_Record_Id__c;
        transWrapper.requestUrl=log.Requesting_Url__c;
        transWrapper.transactionType=UTILGateway.ONETIMEKEYWORD;
        transWrapper.requestUrl=log.Requesting_Url__c;
        log.Serialized_Record__c=JSON.serialize(transWrapper);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
        log=paymentLogList.get(paymentLogList.size()-1);
        transWrapper.logrefId=log.Id;
        transWrapper=SimplifyManager.requestOneTime(transWrapper);
        returnValue=(transWrapper.status)?transWrapper.processingLink:transWrapper.errorResponse;
        return returnValue;
    }
    
    /**************Method to process one time payment from post checkout*****************/
    public static TransactionWrapper ProcessOneTimePayment(TransactionWrapper transWrapper){
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.amount=transWrapper.amount;
        receipt.chargeType=transWrapper.transactionType;
        receipt.paymentId=transWrapper.transactionId;
        receipt.paymentStatus=(transWrapper.transactionStatus=='APPROVED')?'Transaction Approved':'Transaction Rejected';
        receipt.paymentResponse=(transWrapper.transactionStatus=='APPROVED')? MessageHandler.onetimeSuccess : MessageHandler.simplifyOneOffFailed;
        if(transWrapper.transactionStatus=='APPROVED'){
            if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                Transaction__c transactionDetail=mapOneOffTransaction(transWrapper);
                insert transactionDetail;
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c='POST', Transaction_Id__c=transWrapper.transactionId, Transaction_Status__c=transWrapper.transactionStatus, Amount__c=transWrapper.amount, Processing_Record_Id__c=transWrapper.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.oneTimeCheckoutComplete,Charge_Type__c=UTILGateway.ONETIMEKEYWORD,Serialized_Record__c=JSON.serialize(receipt),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
                List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
                transWrapper.logrefId=log.Id;
            }
        }else{
            transWrapper=retryOneTimePayment(transWrapper, receipt);
        }
        return transWrapper;
    }
    /*******************Method to retry one time payment******************/
    public static TransactionWrapper retryOneTimePayment(TransactionWrapper wrapper, ReceiptWrapper receipt){
        wrapper=SimplifyManager.requestOneTime(wrapper);
        String retryUrl=(wrapper.status)?wrapper.processingLink:wrapper.errorResponse;
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.onetimeCheckoutfail,Charge_Type__c=UTILGateway.ONETIMEKEYWORD,Amount__c=wrapper.amount,Retry_Schedule_Url__c=retryUrl,Serialized_Record__c=JSON.serialize(receipt),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
        wrapper.logrefId=log.Id;
        return wrapper;
    }
    
    /**************Method to process recurring payment request************/
    public static String ProcessRecurringPaymentRequest(Payment_Log__c log){
        String returnValue='';
        List<Payment_Log__c> paymentLogList=new List<Payment_Log__c>();
        RecurringWrapper reccWrapper=new RecurringWrapper();
        reccWrapper.sfProcessingId=log.Processing_Record_Id__c;
        if(reccWrapper.sfProcessingId.contains('003')){
            Contact con = [Select Id,Email from Contact where Id=:reccWrapper.sfProcessingId WITH SECURITY_ENFORCED LIMIT 1];
            if(con.Email==null){
                return MessageHandler.emailRequired;
            }
        }/*else if(reccWrapper.sfProcessingId.contains('001')){
Account acc =[Select Id,(Select Name,Email from Contacts) from Account where Id=:reccWrapper.sfProcessingId WITH SECURITY_ENFORCED Limit 1];
for(Contact con : acc.Contacts){
if(con.Email==null){
return MessageHandler.emailRequired;
}
}
}*/
        reccWrapper.amount=log.Amount__c;
        reccWrapper.startDate=log.Recurring_Start_Date__c;
        reccWrapper.instalPeriod=log.Frequency__c;
        reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD;
        reccWrapper.requestUrl=log.Requesting_Url__c;
        reccWrapper.trialPeriod=(reccWrapper.startDate > Date.today())?'DAYS':'NONE';
        reccWrapper.trialDays=(reccWrapper.startDate > Date.today())?getTrialDays(reccWrapper):0;
        reccWrapper=SimplifyManager.createSimplifyPlan(reccWrapper);
        if(!reccWrapper.status){
            return reccWrapper.errorResponse;
        }
        
        log.Charge_Type__c=UTILGateway.RECURRINGKEYWORD;
        log.Serialized_Record__c=JSON.serialize(reccWrapper);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
        log=paymentLogList.get(paymentLogList.size()-1);
        reccWrapper.logrefId=log.Id;
        reccWrapper=SimplifyManager.requestRecurringPayment(reccWrapper);
        returnValue=(reccWrapper.status)?reccWrapper.processingLink:reccWrapper.errorResponse;
        return returnValue;
    }
    
    /***********Method to process recurring payment from post checkout*************/
    public static RecurringWrapper ProcessingRecurringPayment(RecurringWrapper reccWrapper){
        
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.amount=reccWrapper.amount/100;
        receipt.chargeType=UTILGateway.RECURRINGKEYWORD;
        receipt.establishmentDate=Date.today();
        receipt.nextInstallmentDate=reccWrapper.startDate;
        receipt.installPeriod=reccWrapper.instalPeriod;
        reccWrapper.status=false;
        reccWrapper=SimplifyManager.createCustomer(reccWrapper);
        if(!reccWrapper.status){
            throw new GatewayException(reccWrapper.errorResponse);
        }
        reccWrapper=SimplifyManager.createSimplifySubscription(reccWrapper);
        if(!reccWrapper.status){
            throw new GatewayException(reccWrapper.errorResponse);
        }
        if(reccWrapper.status){
            reccWrapper.refundAmount=100;
            reccWrapper=SimplifyManager.validateCreditCard(reccWrapper);
            SimplifyPaymentWrapper payment=SimplifyPaymentWrapper.parse(reccWrapper.validationResponse);
            reccWrapper.amount=reccWrapper.amount/100;
            if(payment.paymentStatus=='APPROVED'){
                if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'create')){
                    Recurring_Payment__c newRp=mapRecurringPayment(reccWrapper);
                    insert newRp;
                    if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                        Transaction__c newTransaction=createTransaction(reccWrapper,'Recurring',newRp.Id);
                        insert newTransaction;
                        reccWrapper.responseMessage = MessageHandler.recurringSuccess;
                        receipt.paymentStatus='Payment Approved';
                        receipt.paymentResponse=reccWrapper.responseMessage;
                        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c='POST', Transaction_Id__c=payment.id, Transaction_Status__c=payment.paymentStatus, Amount__c=reccWrapper.amount, Processing_Record_Id__c=reccWrapper.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.recPayCheckoutComplete,Serialized_Record__c=JSON.serialize(receipt),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
                        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                        Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
                        reccWrapper.logrefId=newLog.Id;
                    }
                }
            }else{
                reccWrapper=SimplifyManager.cancelRecurringPayment(reccWrapper);
                if(!reccWrapper.status){
                    throw new GatewayException(reccWrapper.errorResponse);
                }
                reccWrapper.responseMessage=MessageHandler.simplifyRPFailed;
                receipt.paymentStatus='Payment Rejected';
                receipt.paymentResponse=reccWrapper.responseMessage;
                reccWrapper=retryRecurringPayment(reccWrapper, receipt);
            }
        } 
        
        return reccWrapper;
    }
    
    /************Method to retry recurring payment **************/
    public static RecurringWrapper retryRecurringPayment(RecurringWrapper wrapper,ReceiptWrapper receipt){
        wrapper=SimplifyManager.requestRecurringPayment(wrapper);
        String retryUrl=wrapper.status?wrapper.processingLink:wrapper.errorResponse;
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.recPayCheckoutfail,Amount__c=wrapper.amount,Frequency__c=wrapper.instalPeriod,Recurring_Start_Date__c=wrapper.startdate,Retry_Schedule_Url__c=retryUrl,Serialized_Record__c=JSON.serialize(receipt),Gateway_Name__c=UTILGateway.SIMPLIFYWORD,Charge_Type__c=UtilGateway.RECURRINGKEYWORD)));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
        wrapper.logrefId=log.Id;
        return wrapper;
    }
    
    /***********Method to map one off transaction***********/
    public static Transaction__c mapOneOffTransaction(TransactionWrapper wrapper){
        Transaction__c oneoffTransaction = new Transaction__c();
        if(Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() &&
           Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()){
               oneoffTransaction.Amount__c=wrapper.amount;
               oneoffTransaction.Gateway_Name__c=UTILGateway.SIMPLIFYWORD;
               oneoffTransaction.Transaction_Date__c=Datetime.now();
               oneoffTransaction.Transaction_Status__c='Paid';
               oneoffTransaction.RecordTypeId=Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('One Time').getRecordTypeId();
               oneoffTransaction.Transaction_Id__c=wrapper.transactionId;
           }else{
               throw new UTILPermission.PermsException('Transaction__c','Amount__c,Gateway_Name__c,Transaction_Date__c,Transaction_Status__c,RecordTypeId,Transaction_Id__c','Create');
           }
        return oneoffTransaction;
        
    }
    /***********Method to map recurring payment***********/
    public static Recurring_Payment__c mapRecurringPayment(RecurringWrapper wrapper){
        SimplifyPaymentWrapper paymentDetails=new SimplifyPaymentWrapper();
        if(wrapper.validationResponse!=null){
            paymentDetails=SimplifyPaymentWrapper.parse(wrapper.validationResponse);
        }
        Recurring_Payment__c newRecurringPayment=new Recurring_Payment__c();
        if(UTILPermission.CheckSinglePerm('create', 'Q_Charge__Recurring_Payment__c', new Set<String>{'Q_Charge__Amount__c','Q_Charge__Date_Established__c','Q_Charge__Next_Installment_Date__c','Q_Charge__Gateway_Name__c','Q_Charge__Installment_Period__c','Q_Charge__Status__c','Q_Charge__RelatedToId__c','Q_Charge__Gateway_Schedule_Id__c','Q_Charge__Gateway_Refund_Id__c','Q_Charge__Refund_Status__c','Q_Charge__Refund_Amount__c','Q_Charge__Card_Name__c','Q_Charge__Card_Number__c','Q_Charge__Card_Expiry_Date__c','Q_Charge__Card_Last_Updated_On__c'})){
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
                    newRecurringPayment.Gateway_Name__c=UTILGateway.SIMPLIFYWORD;
                    newRecurringPayment.Installment_Period__c=wrapper.instalPeriod;
                    newRecurringPayment.Status__c='Open';
                    newRecurringPayment.RelatedToId__c=wrapper.sfProcessingId;
                    newRecurringPayment.Gateway_Schedule_Id__c=wrapper.recurringRequestId;
                    newRecurringPayment.Gateway_Refund_Id__c=paymentDetails.id;
                    newRecurringPayment.Refund_Status__c='Awaiting';
                    newRecurringPayment.Refund_Amount__c=1.00;
                    newRecurringPayment.Card_Name__c=wrapper.cardDetails.CardHolderName;
                    newRecurringPayment.Card_Number__c='xxxx '+wrapper.cardDetails.CardNumber;
                    newRecurringPayment.Card_Expiry_Date__c=(wrapper.cardDetails.ExpiryMonth!=null && wrapper.cardDetails.ExpiryYear!=null)?Date.newInstance(Integer.valueOf(wrapper.cardDetails.ExpiryYear)+2000,Integer.valueOf(wrapper.cardDetails.ExpiryMonth) , Date.daysInMonth(Integer.valueOf(wrapper.cardDetails.ExpiryYear)+2000,Integer.valueOf(wrapper.cardDetails.ExpiryMonth))):null;
                    newRecurringPayment.Card_Last_Updated_On__c=Datetime.now();
                    
                }        
        }
        return newRecurringPayment;
    }
    
    
    /****************Method to map recurring payment transaction****************/
    public static Transaction__c mapTransaction(TransactionWrapper wrapper,String recordType,String recurringId){
        Transaction__c transactionRec = new Transaction__c();
        if(Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() &&
           Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()){
               transactionRec.Amount__c=wrapper.amount;
               transactionRec.Gateway_Name__c=UTILGateway.SIMPLIFYWORD;
               transactionRec.Transaction_Date__c=wrapper.transactionDateTime;
               transactionRec.Transaction_Status__c=wrapper.transactionStatus;
               if(recordType=='Recurring'){
                   transactionRec.Recurring_Payment__c=recurringId; 
               }
               transactionRec.RecordTypeId=Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
               transactionRec.Transaction_Id__c=wrapper.transactionId;
           }else{
               throw new UTILPermission.PermsException('Transaction__c','Amount__c,Gateway_Name__c,Transaction_Date__c,Transaction_Status__c,RecordTypeId,Transaction_Id__c','Create');
           }
        return transactionRec;
    }
    
    /*************Method to create a transaction for recurring payment*********/
    public static Transaction__c createTransaction(RecurringWrapper wrapper,String recordType,String recurringId){
        Transaction__c transactionRec = new Transaction__c();
        if((Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable()) &&
           (Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() || Schema.sObjectType.Transaction__c.fields.RecordTypeId.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isUpdateable())){
               transactionRec.Amount__c=wrapper.amount;
               transactionRec.Gateway_Name__c=UTILGateway.SIMPLIFYWORD;
               transactionRec.Transaction_Date__c=Datetime.newInstance(wrapper.startDate.year(),wrapper.startDate.month(),wrapper.startDate.day());
               if(recordType=='Recurring'){
                   transactionRec.Transaction_Status__c='Scheduled';
                   transactionRec.Recurring_Payment__c=recurringId; 
               }
               transactionRec.RecordTypeId=Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
           }else{
               throw new UTILPermission.PermsException('Transaction__c','Amount__c,Gateway_Name__c,Transaction_Date__c,Transaction_Status__c,RecordTypeId,Transaction_Id__c,Recurring_Payment__c','Create/Update');
           }
        return transactionRec;
    }
    
    /***********Method to perform refund from batch****************/
    public static void refundSimplify(List<Recurring_Payment__c> recurringPaymentlist){
        if(!SimplifyManager.isConnected){
            throw new GatewayException(SimplifyManager.detachedReason);
        }
        List<Recurring_Payment__c> updateRPList = new List<Recurring_Payment__c>();
        for(Recurring_Payment__c recurringPayment : recurringPaymentlist){
            UTILGateway.allowRPUpdate=true;
            RecurringWrapper wrapper=new RecurringWrapper();
            wrapper.amount=recurringPayment.Refund_Amount__c;
            wrapper.refundId=recurringPayment.Gateway_Refund_Id__c;
            wrapper=SimplifyManager.performRefund(wrapper);
            if(Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable() &&Schema.sObjectType.Recurring_Payment__c.fields.Refund_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isUpdateable()){
                if(wrapper.status){
                    SimplifyPaymentWrapper payment=SimplifyPaymentWrapper.parse(wrapper.paymentResponse);
                    if(payment.paymentStatus=='APPROVED'){
                        recurringPayment.Refund_Date__c=Datetime.now();
                        recurringPayment.Refund_Status__c='Refunded';
                        recurringPayment.Refund_Description__c='Approved';
                    }else{
                        recurringPayment.Refund_Status__c='Failed';
                        recurringPayment.Refund_Description__c=wrapper.errorResponse;
                    }
                }else if(wrapper.errorResponse.contains('refund.payment.voided')){
                    recurringPayment.Refund_Description__c=wrapper.errorResponse.substringAfter('Field: payment');
                }
                updateRPList.add(recurringPayment);
            }
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
            update updateRPList;
        }
    }
    
    /****************Method to update payments in salesforce****************/
    public static void fetchCompletedRPTransactions(List<Recurring_Payment__c> recurringPaymentlist){
        if(!SimplifyManager.isConnected){
            throw new GatewayException(SimplifyManager.detachedReason);
        }
        if(recurringPaymentlist.size() == 0){
            return;
        }
        List<Transaction__c> newTransactionList=new List<Transaction__c>();
        list<Recurring_Payment__c> updatedRPList = new List<Recurring_Payment__c>();
        List<Transaction__c> transactionList=[Select Id,Transaction_Date__c,Transaction_Id__c,Amount__c,Recurring_Payment__c,Transaction_Status__c,Failed_Reason__c from Transaction__c where Recurring_Payment__c IN: recurringPaymentlist and Transaction_Status__c='Scheduled' WITH SECURITY_ENFORCED];
        Boolean transactionUpdated=false;
        Boolean cancelledRP=false;
        Recurring_Payment__c recurringPayment = new Recurring_Payment__c();
        for(Recurring_Payment__c fetchRP : recurringPaymentlist){
            recurringPayment = fetchRP;
        }
        
        Transaction__c newTransaction=new Transaction__c();
        TransactionWrapper invoiceWrapper=new TransactionWrapper();
        
        String decodedCK=UtilGateway.decodeCustomerKeys(recurringPayment.Gateway_Schedule_Id__c);
        RecurringWrapper req=new RecurringWrapper();
        req.customerId=decodedCK.substringBefore('+');
        req.recurringRequestId=decodedCK.substringAfter('+');
        req=SimplifyManager.findSubscription(req);
        if(!req.status && req.errorResponse.contains('object.not.found')){
            if(Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable()){
                recurringPayment.Status__c='Closed';
            }
            else{
                throw new UTILPermission.PermsException('Recurring_Payment__c','Status__c','Update');
            }
            for(Transaction__c trans : transactionList){
                TransactionWrapper transWrapper=SimplifyManager.getTransaction('payment', new Map<String,String>{'customer'=>decodedCK.substringBefore('+'),'dateCreatedMin'=>String.valueof(trans.Transaction_Date__c.getTime()),'dateCreatedMax'=>String.valueOf(Datetime.newInstance(trans.Transaction_Date__c.date().year(),trans.Transaction_Date__c.date().month(),trans.Transaction_Date__c.date().day()+1).getTime())});
                trans.Transaction_Status__c=transWrapper.responseText==null?'Cancelled':transWrapper.responseText;
                trans.Transaction_Date__c=transWrapper.transactionDateTime!=null?transWrapper.transactionDateTime:trans.Transaction_Date__c;
                trans.Transaction_Id__c=transWrapper.transactionId; 
            }
            cancelledRP = true;
            //update transactionList;
            //update recurringPayment;
            //return;
        }else if(!req.status){
            throw new GatewayException(req.errorResponse);
        }
        else if(transactionList.size()>0){
            for(Transaction__c trans:transactionList){             
                TransactionWrapper transWrapper=SimplifyManager.getTransaction('payment', new Map<String,String>{'customer'=>decodedCK.substringBefore('+'),'dateCreatedMin'=>String.valueof(trans.Transaction_Date__c.getTime()),'dateCreatedMax'=>String.valueOf(Datetime.newInstance(trans.Transaction_Date__c.date().year(),trans.Transaction_Date__c.date().month(),trans.Transaction_Date__c.date().day()+1).getTime())});
                if(transWrapper.transactionId==recurringPayment.Gateway_Refund_Id__c){
                    continue;
                }
                trans.Transaction_Status__c=transWrapper.responseText==null?'Scheduled':(transWrapper.responseText=='APPROVED'?'Paid':transWrapper.responseText);
                    Datetime prevDate=trans.Transaction_Date__c;
                trans.Transaction_Date__c=transWrapper.transactionDateTime!=null?transWrapper.transactionDateTime:trans.Transaction_Date__c;
                trans.Transaction_Id__c=transWrapper.transactionId;
                // trans.Failed_Reason__c=transWrapper.responseText!='APPROVED'?transWrapper.declinedReason:'';
                transactionUpdated=(transWrapper.responseText!=null)?true:false;
                if(trans.Transaction_Status__c=='Paid') {
                    trans.Transaction_Date__c=transWrapper.transactionDateTime!=null?transWrapper.transactionDateTime:trans.Transaction_Date__c;
                    invoiceWrapper=SimplifyManager.getTransaction('invoice', new Map<String,String>{'customer'=>decodedCK.substringBefore('+'),'dateCreatedMin'=>String.valueof(prevDate.getTime()),'dateCreatedMax'=>String.valueOf(Datetime.now().getTime())});
                    if(invoiceWrapper!=null){
                        invoiceWrapper.transactionStatus=(invoiceWrapper.transactionStatus=='OPEN' || invoiceWrapper.transactionStatus==null)?'Scheduled':invoiceWrapper.transactionStatus;
                        invoiceWrapper.amount=recurringPayment.Amount__c;
                        newTransaction=mapTransaction(invoiceWrapper,'Recurring',recurringPayment.Id);
                        if(newTransaction.Transaction_Date__c!=null && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable()){
                            recurringPayment.Next_Installment_Date__c=newTransaction.Transaction_Date__c.date();
                        }
                        newTransactionList.add(newTransaction);
                    }  
                    
                }
                /*else if(trans.Transaction_Status__c!='Scheduled'){
TransactionWrapper failedTransaction = new TransactionWrapper();
failedTransaction.transactionId= trans.Transaction_Id__c;
failedTransaction=SimplifyManager.findPayment(failedTransaction);
System.debug(failedTransaction);
//trans.Failed_Reason__c=transWrapper.responseText!='APPROVED'?transWrapper.declinedReason:'';
}*/
                
            }
            updatedRPList.add(recurringPayment);
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update') && cancelledRP){
            update transactionList;
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'upsert') && transactionUpdated){
            transactionList.addAll(newTransactionList);
            upsert transactionList;
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
            update updatedRPList;
        } 
    }
    
    /*****************Method to request update card detail page*********************/
    public static String requestUpdateCardDetailPage(String recurringId,String gatewayScheduleId,String requestUrl){
        String returnValue='';
        Payment_Log__c log= new Payment_Log__c(Processing_Record_Id__c=recurringId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.updateCardRequest,Transaction_Id__c=gatewayScheduleId,Requesting_Url__c=requestUrl,Gateway_Name__c=UTILGateway.SIMPLIFYWORD);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
        RecurringWrapper updateWrapper = new RecurringWrapper();
        updateWrapper.transactionreference=newLog.Id;
        updateWrapper=SimplifyManager.getUpdateCardPage(updateWrapper);
        returnValue=(updateWrapper.status)?updateWrapper.processingLink:updateWrapper.errorResponse;
        return returnValue;
    }
    
    /**************Method to update card details***************** */
    public static RecurringWrapper updateCardDetails(RecurringWrapper req){
        req.status=false;
        Id recurringId=req.sfProcessingId;
        Recurring_Payment__c rp = [Select Id,Card_Last_Updated_On__c,Card_Name__c,Card_Expiry_Date__c,RelatedToId__c,Card_Number__c,Amount__c from Recurring_Payment__c where Id=:recurringId WITH SECURITY_ENFORCED LIMIT 1];
        Id contactID=rp.RelatedToId__c;
        Contact con=[Select FirstName,LastName,Email from Contact where Id=:contactID WITH SECURITY_ENFORCED LIMIT 1];
        req.email=con.Email;
        req.name=con.FirstName+' '+con.LastName;
        req.refundAmount=100;
        req=SimplifyManager.updateCardDetails(req);
        if(!req.status){
            throw new GatewayException(req.errorResponse);
        }
        req=SimplifyManager.validateCreditCard(req);
        if(!req.status){
            throw new GatewayException(req.errorResponse);
        }
        SimplifyPaymentWrapper paymentRetrieved=SimplifyPaymentWrapper.parse(req.validationResponse);
        if(paymentRetrieved.paymentStatus=='APPROVED'){
            req.status=true;
            req.responseMessage='Payment Approved';
            UtilGateway.allowRPUpdate=true;
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isUpdateable() && 
               Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isUpdateable()){
                   rp.Gateway_Refund_Id__c=paymentRetrieved.id;
                   rp.Refund_Status__c='Awaiting';
                   rp.Card_Last_Updated_On__c=Datetime.now();
                   rp.Card_Name__c=req.cardDetails.CardHolderName;
                   rp.Card_Number__c='xxxx '+req.cardDetails.CardNumber;
                   rp.Card_Expiry_Date__c=(req.cardDetails.ExpiryMonth!=null && req.cardDetails.ExpiryYear!=null)?Date.newInstance(Integer.valueOf(req.cardDetails.ExpiryYear)+2000,Integer.valueOf(req.cardDetails.ExpiryMonth),Date.daysInMonth((Integer.valueOf(req.cardDetails.ExpiryYear))+2000,Integer.valueOf(req.cardDetails.ExpiryMonth))):null;
                   update rp;
               }
        }else{
            req.status=false;
            req.responseMessage='Payment Rejected';
            ReceiptWrapper receipt=new ReceiptWrapper();
            receipt.paymentResponse=req.responseMessage;
            receipt.paymentStatus='Transaction Rejected';
            receipt.chargeType = UTILGateway.RECURRINGKEYWORD;
            receipt.paymentResponse=MessageHandler.failedUpdateCard;
            retryUpdateCardDetails(req,receipt);
        }
        return req;
    }
    
    /************Method to retry update card details***************/
    public static RecurringWrapper retryUpdateCardDetails(RecurringWrapper wrapper,ReceiptWrapper receipt){
        wrapper.customerId=UTILGateway.decodeCustomerKeys(wrapper.recurringRequestId).substringBefore('+');
        wrapper=SimplifyManager.getUpdateCardPage(wrapper);
        String returnValue=(wrapper.status)?wrapper.processingLink:wrapper.errorResponse;
        Payment_Log__c log= new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.updateCardfail,Transaction_Id__c=wrapper.recurringRequestId,Serialized_Record__c=JSON.serialize(receipt),Requesting_Url__c=wrapper.requestUrl,Gateway_Name__c=UTILGateway.SIMPLIFYWORD,Retry_Schedule_Url__c=returnValue);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        return wrapper;
        
    }
    
    /**************Method to update recurring payment***************/
    public static RecurringWrapper ProcessUpdateRecurringPayment(RecurringWrapper req){
        Id recurringId=req.sfProcessingId;
        Recurring_Payment__c existingRP=[Select Amount__c,Next_Installment_Date__c,Installment_Period__c,RelatedToId__c,Gateway_Refund_Id__c from Recurring_Payment__c where Id=:recurringId With SECURITY_ENFORCED Limit 1];
        Id contactId=existingRP.RelatedToId__c;
        Contact con=[Select FirstName,LastName,Email from Contact where Id=:contactId WITH SECURITY_ENFORCED Limit 1];
        req.status=false;
        req.name=con.FirstName+' '+con.LastName;
        req.email=con.Email;
        String decodedCK=UtilGateway.decodeCustomerKeys(req.recurringRequestId);
        req.customerId=UtilGateway.encodeCustomerKeys(decodedCK.substringBefore('+'));
        Boolean transactionperformedInGateway=false;
        List<Transaction__c> transactionList=new List<Transaction__c>();
        List<Transaction__c> existingScheduledTransactions=[Select Id,Transaction_Date__c,Transaction_Status__c,Transaction_Id__c,Amount__c from Transaction__c where Recurring_Payment__c=:recurringId AND Transaction_Status__c='Scheduled' WITH SECURITY_ENFORCED];
        for(Transaction__c trans:existingScheduledTransactions){
            TransactionWrapper transWrapper=SimplifyManager.getTransaction('payment',new Map<String,String>{'amount'=>String.valueOf(Integer.valueOf(trans.Amount__c*100)),'customer'=>decodedCK.substringBefore('+'),'dateCreatedMin'=>String.valueOf(trans.Transaction_Date__c.getTime()),'dateCreatedMax'=>String.valueOf(Datetime.now().getTime())});
            if(!transWrapper.status){
                throw new GatewayException(transWrapper.errorResponse);
            }else if(transWrapper.transactionId==existingRP.Gateway_Refund_Id__c){
                continue;
            }
            if((Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable())){
                trans.Transaction_Status__c=transWrapper.responseText==null?'Scheduled':(transWrapper.responseText=='APPROVED'?'Paid':transWrapper.responseText);
                    trans.Transaction_Date__c=transWrapper.transactionDateTime==null?trans.Transaction_Date__c:transWrapper.transactionDateTime;
                trans.Transaction_Id__c=transWrapper.transactionId==null?'':transWrapper.transactionId; 
                if(trans.Transaction_Status__c!='Scheduled'){
                    transactionperformedInGateway=true;
                    transactionList.add(trans);
                    transactionperformedInGateway=true;
                }
            }
            else{
                throw new UTILPermission.PermsException('Transaction__c','Transaction_Date__c,Transaction_Status__c,Transaction_Id__c','Update');
            }
            
        }
        //req=SimplifyManager.cancelRecurringPayment(req);
        req.trialPeriod=(req.startDate > Date.today())?'DAYS':'NONE';
        req.trialDays=(req.startDate > Date.today())?getTrialDays(req):0;        
        req=SimplifyManager.createSimplifyPlan(req);
        if(req.status){
            req=SimplifyManager.updateSubscription(req);
            if(!req.status){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize( new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.updateRPFailed,Transaction_Id__c=req.recurringRequestId,Serialized_Record__c=JSON.serialize(req),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
                return req;
            }
            UtilGateway.allowRPUpdate=true;
            
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'delete') && !transactionperformedInGateway){
                delete existingScheduledTransactions;
            }
            Transaction__c newTransaction=createTransaction(req,'Recurring',req.sfProcessingId);
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'insert') && UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                transactionList.add(newTransaction);
                upsert transactionList;
            }
            
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() &&
               Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable()){
                   existingRP.Amount__c=req.amount;
                   existingRP.Next_Installment_Date__c=req.startDate;
                   existingRP.Installment_Period__c=req.instalPeriod;
                   existingRP.Gateway_Schedule_Id__c=req.recurringRequestId;
                   update existingRP;
               }
        }else{
            throw new  GatewayException(req.errorResponse);
        }
        UTILGateway.PayLogSet_JSON.add(JSON.serialize( new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.updateRpSuccess,Transaction_Id__c=req.recurringRequestId,Serialized_Record__c=JSON.serialize(req),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
        req.responseMessage=MessageHandler.updateRP + UTILGateway.SIMPLIFYWORD.capitalize()+'.';
        
        return req;
    }
    
    /***************Method to cancel recurring payment**************/
    public static RecurringWrapper cancelRecurringPayment(List<Recurring_Payment__c> existingRPList){
        
        RecurringWrapper req=new RecurringWrapper();
        Recurring_Payment__c existingRP = new Recurring_Payment__c();
        
        if(existingRPList.size() > 0){
            for(Recurring_Payment__c recurPayment : existingRPList){
                existingRP = recurPayment;
            }
        }else{
            req.errorResponse = MessageHandler.wentWrongCatchMessage;
            return req;
        }
        
        req.sfProcessingId=existingRP.Id;
        req.amount=existingRP.Amount__c*100;
        req.instalPeriod=existingRP.Installment_Period__c;
        req.startdate=existingRP.Next_Installment_Date__c;
        UtilGateway.allowRPUpdate=true;
        req.recurringRequestId=existingRP.Gateway_Schedule_Id__c;
        Id recurringId=existingRP.Id;
        req.status=false;
        Boolean transactionperformedInGateway=false;
        List<Transaction__c> transactionList=new List<Transaction__c>();
        List<Transaction__c> existingTransactionsList=[Select Id,Transaction_Status__c,Amount__c,Transaction_Date__c,Transaction_Id__c from Transaction__c where Recurring_Payment__c=:recurringId WITH SECURITY_ENFORCED];
        for(Transaction__c trans:existingTransactionsList){
            TransactionWrapper transWrapper=SimplifyManager.getTransaction('payment',new Map<String,String>{'amount'=>String.valueOf(Integer.valueOf(trans.Amount__c*100)),'customer'=>UTILGateway.decodeCustomerKeys(existingRP.Gateway_Schedule_Id__c).substringBefore('+'),'dateCreatedMin'=>String.valueOf(trans.Transaction_Date__c.getTime()),'dateCreatedMax'=>String.valueOf(Datetime.now().getTime())});
            if(!transWrapper.status){
                throw new GatewayException(transWrapper.errorResponse);
            }else if(transWrapper.transactionId==existingRP.Gateway_Refund_Id__c){
                continue;
            }
            if(Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable()){
                trans.Transaction_Status__c=transWrapper.responseText==null?'Scheduled':(transWrapper.responseText=='APPROVED'?'Paid':transWrapper.responseText);
                    trans.Transaction_Date__c=transWrapper.transactionDateTime==null?trans.Transaction_Date__c:transWrapper.transactionDateTime;
                trans.Transaction_Id__c=transWrapper.transactionId==null?'':transWrapper.transactionId; 
                if(trans.Transaction_Status__c!='Scheduled'){
                    transactionperformedInGateway=true;
                    transactionList.add(trans);
                    transactionperformedInGateway=true;
                }
            }
            else{
                throw new UTILPermission.PermsException('Transaction__c','Transaction_Date__c,Transaction_Status__c,Transaction_Id__c','Update');
            }
        }
        //String decodedCK=UTILGateway.decodeCustomerKeys(existingRP.Gateway_Schedule_Id__c);
        req=SimplifyManager.cancelRecurringPayment(req);
        if(req.status){
            if(!transactionperformedInGateway){
                for(Transaction__c trans:existingTransactionsList){
                    trans.Transaction_Status__c='Cancelled';
                }
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update') && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()){
                    update existingTransactionsList;
                }
            }else{
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update') && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()){
                    update transactionList;
                }
            }
            
            existingRP.Status__c='Closed';
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable()){
                update existingRP;
            }
            UTILGateway.PayLogSet_JSON.add(JSON.serialize( new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.cancelRecPaySuccess,Transaction_Id__c=req.recurringRequestId,Serialized_Record__c=JSON.serialize(req),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
            req.responseMessage=existingRP.Name+' is '+MessageHandler.cancelRP+' in Simplify.';
            
        }else{
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.updateRPFailed,Transaction_Id__c=req.recurringRequestId,Serialized_Record__c=JSON.serialize(req),Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
            
        }
        return req;
    }
    
    public static Long getTrialDays(RecurringWrapper req){
        Datetime today=Datetime.now();
        Datetime startDateTime=Datetime.newInstance(req.startDate.year(),req.startDate.month(),req.startDate.day());
        Long diff=Math.mod(((startDateTime.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)),365)+1;
        return diff;
    }
    
    public static String convertFrequency(String frequency){
        if(frequency=='Daily'){
            return 'Every day';
        }else if(frequency=='Every day'){
            return 'Daily';
        }
        
        return null;
    }
    
}