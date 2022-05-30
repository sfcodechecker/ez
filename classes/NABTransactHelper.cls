public with sharing class NABTransactHelper {
    
    /*********************** Process one off payment helper method ********************************/
    public static TransactionWrapper ProcessOneTimeTransaction(TransactionWrapper transWrapper){
        try{
            transWrapper.transactionStatus = (transWrapper.responseText == 'Approved') ? 'Transaction Approved' : 'Transaction Rejected';
            transWrapper.transResponse = (transWrapper.responseText == 'Approved') ? MessageHandler.onetimeSuccess : MessageHandler.onetimeFailed+transWrapper.responseText+'.';
            
            String serializedWrapper = '';
            String status = (transWrapper.transactionId != null)? 'Paid' : 'Failed';
            
            ReceiptWrapper receiptPageWrap = new ReceiptWrapper();
            receiptPageWrap.amount = transWrapper.amount;
            receiptPageWrap.paymentId = transWrapper.transactionId;
            receiptPageWrap.paymentStatus = transWrapper.transactionStatus;
            receiptPageWrap.paymentResponse =transWrapper.transResponse;
            receiptPageWrap.chargeType = UTILGateway.ONETIMEKEYWORD;
            
            if(transWrapper.responseText == 'Approved'){
                Transaction__c create_new_transaction = new Transaction__c(Amount__c = transWrapper.amount, Gateway_Name__c = UTILGateway.NABTRANSWORD.replace('_',' '),Transaction_Id__c = transWrapper.transactionId, Transaction_Date__c = Datetime.now(), Transaction_Status__c = status, RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('One Time').getRecordTypeId());
                
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                    insert create_new_transaction;
                }
                serializedWrapper = JSON.serialize(receiptPageWrap);
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c = 'POST', Action__c = MessageHandler.processPayment(UTILGateway.NABTRANSWORD.capitalize(),UTILGateway.ONETIMEKEYWORD), Amount__c = transWrapper.amount, Processing_Record_Id__c = transWrapper.sfProcessingId, Transaction_Id__c = transWrapper.transactionId, Transaction_Status__c = 'Approved', End_Point__c = transWrapper.successURL, Charge_Type__c = UTILGateway.ONETIMEKEYWORD, Payment_Parameter_1__c = create_new_transaction.Id, Serialized_Record__c = serializedWrapper, Response_Message__c = transWrapper.transResponse,Gateway_Name__c=UtilGateway.NABTRANSWORD)));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                transWrapper.logrefId = current_log.Id;
            }
            else{
                serializedWrapper = JSON.serialize(receiptPageWrap);
                String retryURL = retryOneOffTransaction(transWrapper);
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c = 'POST', Action__c = UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.onetimeDeclined, Amount__c = transWrapper.amount, Processing_Record_Id__c = transWrapper.sfProcessingId, Transaction_Id__c = transWrapper.transactionId, Transaction_Status__c = 'Rejected', End_Point__c = transWrapper.successURL, Retry_Schedule_URL__c = retryURL, Charge_Type__c = UTILGateway.ONETIMEKEYWORD, Serialized_Record__c = serializedWrapper, Response_Message__c = transWrapper.transResponse,Gateway_Name__c=UtilGateway.NABTRANSWORD)));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                transWrapper.logrefId = current_log.Id;
            }
            return transWrapper;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /**********Method to refund validation amount************/
    public static void refundValidationAmount(List<Recurring_Payment__c> recurringPaymentlist){
        try{
            List<Recurring_Payment__c> updatedRPList = new List<Recurring_Payment__c>();
            for(Recurring_Payment__c recurringPayment : recurringPaymentlist){
                RecurringWrapper recurringWrapper = new RecurringWrapper();
                recurringWrapper.transactionreference = recurringPayment.Gateway_Schedule_Id__c;
                recurringWrapper.refundId = recurringPayment.Gateway_Refund_Id__c;
                recurringWrapper.sfProcessingId = recurringPayment.RelatedToId__c;
                recurringWrapper = NABTransactManager.refundValidationAmount(recurringWrapper, true);
                
                if(recurringWrapper.refundStatus == 'Refunded'){
                    //update record and set refund status as refunded.
                    if(Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isUpdateable()){
                        recurringPayment.Refund_Status__c = 'Refunded';
                        recurringPayment.Refund_Date__c = DateTime.now();
                        recurringPayment.Refund_Description__c ='Approved';
                    }
                    else{
                        throw new UTILPermission.PermsException('Recurring_Payment__c','Refund_Status__c,Refund_Date__c,Refund_Description__c','Update');
                    }
                }
                else if(recurringWrapper.refundStatus == 'Failed'){
                    //set the description as the error from NAB Server. Do not update status. 
                    if(Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable()){
                        if(recurringPayment.Refund_Status__c == 'Refunded'){
                            recurringPayment.Refund_Description__c = recurringWrapper.refundDesc;
                        }
                        else{
                            recurringPayment.Refund_Description__c = recurringWrapper.refundDesc;
                            recurringPayment.Refund_Status__c = 'Failed';
                        }
                    }else{
                        throw new UTILPermission.PermsException('Recurring_Payment__c','Refund_Description__c','Update');
                    }
                } 
                updatedRPList.add(recurringPayment);
            }
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                UTILGateway.allowRPUpdate = true;
                update updatedRPList;
            }
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
    }
    
    /*********************** Process a schedule method ********************************/
    public static RecurringWrapper ProcessRecurringTransaction(RecurringWrapper recurWrapper){
        try{
            String responseMessage = '';
            String serializedWrapper = '';
            TransactionWrapper transWrapper = new TransactionWrapper();
            ReceiptWrapper receiptPageWrap = new ReceiptWrapper();
            
            if(recurWrapper.responseMessage != 'Successful'){
                recurWrapper.responseMessage = MessageHandler.recurringFailed +''+recurWrapper.responseMessage;
                recurWrapper.paymentStatus = 'Payment Rejected';
            }
            else if(recurWrapper.responseMessage == 'Successful')
            {
                if(Date.valueOf(recurWrapper.startDate) == Date.today())
                {
                    transWrapper.tokenValue = recurWrapper.tokenValue; 
                    transWrapper.transactionId = recurWrapper.refundReference;
                    transWrapper.amount = recurWrapper.amount * 100;
                    transWrapper = NABTransactManager.chargeCurrentTransaction(transWrapper);
                    
                    //assigning response to  recurrring wrapper.
                    recurWrapper.transactionreference = transWrapper.transResponse.SubStringAfter('&TransactionId=');
                    recurWrapper.recurringResponse = transWrapper.transResponse.substringBefore('&TransactionId=');
                    
                    recurWrapper.responseMessage = (recurWrapper.recurringResponse == 'Normal') ? MessageHandler.recurringSuccess : MessageHandler.recurringFailed +''+recurWrapper.recurringResponse+'.';
                    recurWrapper.paymentStatus = (recurWrapper.recurringResponse == 'Normal') ? 'Payment Approved' : 'Payment Rejected';
                    
                } else{
                    
                    transWrapper.tokenValue = recurWrapper.tokenValue; 
                    transWrapper.transactionId = recurWrapper.refundReference;
                    transWrapper = NABTransactManager.validateCreditCard(transWrapper);
                    
                    recurWrapper.validationResponse = transWrapper.transResponse.substringBefore('&TransactionId=');
                    recurWrapper.refundId = transWrapper.transResponse.SubStringAfter('&TransactionId=');
                    recurWrapper.responseMessage = (recurWrapper.validationResponse == 'Normal') ? MessageHandler.recurringSuccess : MessageHandler.recurringFailed +''+recurWrapper.validationResponse+'.';
                    recurWrapper.paymentStatus = (recurWrapper.validationResponse == 'Normal') ? 'Payment Approved' : 'Payment Rejected';
                } 
            } 
            
            // processing record creation and initialising reciept wrapper.
            if(recurWrapper.recurringResponse == 'Normal' || recurWrapper.validationResponse == 'Normal'){
                DateTime actualTransDate;
                DateTime transacationDateTime;
                String returnToken = UTILGateway.encodeCustomerKeys(recurWrapper.tokenValue);
                String installPeriod = recurWrapper.instalPeriod;
                responseMessage = 'Transaction Successful.';
                
                /*if(recurWrapper.instalPeriod == 'Half-Yearly'){               //changed KW
installPeriod = 'Six-monthly';
}
if(recurWrapper.instalPeriod == 'Annual'){
installPeriod = 'Yearly';
}*/
                
                Integer last_day_of_month = Date.daysInMonth(Integer.valueOf(recurWrapper.cardExpiryYear), Integer.valueOf(recurWrapper.cardExpiryMonth));
                
                Recurring_Payment__c create_new_RP = new Recurring_Payment__c(Amount__c = recurWrapper.amount, Date_Established__c = Date.today(), Duration__c = 'Ongoing', Gateway_Name__c = UTILGateway.NABTRANSWORD.replace('_',' '), Installment_Period__c = installPeriod,  RelatedToId__c = recurWrapper.sfProcessingId, Status__c = 'Open', Secured_Token__c = returnToken, Q_Charge__Card_Expiry_Date__c = Date.newinstance(Integer.valueOf(recurWrapper.cardExpiryYear), Integer.valueOf(recurWrapper.cardExpiryMonth),last_day_of_month), Q_Charge__Card_Name__c = recurWrapper.cardHolderName, Q_Charge__Card_Number__c = recurWrapper.cardNumber, Q_Charge__Card_Last_Updated_On__c = DateTime.now());
                
                if(recurWrapper.startDate > Date.today()){
                    if(Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isCreateable()){
                        create_new_RP.Next_Installment_Date__c = recurWrapper.startDate;
                        create_new_RP.Gateway_Schedule_Id__c = recurWrapper.refundReference;                                      
                        create_new_RP.Gateway_Refund_Id__c = recurWrapper.refundId;
                        create_new_RP.Refund_Amount__c = 1.00;
                        create_new_RP.Refund_Status__c = 'Awaiting';
                        receiptPageWrap.nextInstallmentDate = recurWrapper.startDate;
                    }else{
                        throw new UTILPermission.PermsException('Recurring_Payment__c','Gateway_Schedule_Id__c,Gateway_Refund_Id__c,Refund_Amount__c,Refund_Status__c,Next_Installment_Date__c','Create');
                    }
                }
                
                if(Date.valueOf(recurWrapper.startDate) == Date.today()){
                    if(Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isCreateable()){
                        if(recurWrapper.instalPeriod == 'Weekly')
                            create_new_RP.Next_Installment_Date__c = recurWrapper.startDate.addDays(7);
                        else if(recurWrapper.instalPeriod == 'Fortnightly')
                            create_new_RP.Next_Installment_Date__c = recurWrapper.startDate.addDays(14);
                        else if(recurWrapper.instalPeriod == 'Monthly')
                            create_new_RP.Next_Installment_Date__c = recurWrapper.startDate.addMonths(1);
                        else if(recurWrapper.instalPeriod == 'Quarterly')
                            create_new_RP.Next_Installment_Date__c = recurWrapper.startDate.addMonths(3);
                        else if(recurWrapper.instalPeriod == 'Half Yearly')
                            create_new_RP.Next_Installment_Date__c = recurWrapper.startDate.addMonths(6);
                        else if(recurWrapper.instalPeriod == 'Yearly')
                            create_new_RP.Next_Installment_Date__c = recurWrapper.startDate.addYears(1);
                    }else{
                        throw new UTILPermission.PermsException('Recurring_Payment__c','Next_Installment_Date__c','Create');
                    }
                }
                
                if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'create')){
                    insert create_new_RP;
                }
                
                String scheduleStatus = (recurWrapper.startDate > Date.today())? 'Scheduled' : 'Paid' ;
                if(scheduleStatus == 'Paid'){
                    actualTransDate = DateTime.now();
                    transacationDateTime = DateTime.now();
                }
                else{
                    actualTransDate = null;
                    transacationDateTime = create_new_RP.Next_Installment_Date__c;
                }
                
                Transaction__c create_new_transaction = new Transaction__c(Amount__c = recurWrapper.amount, Gateway_Name__c = UTILGateway.NABTRANSWORD.replace('_',' '),Recurring_Payment__c = create_new_RP.Id, Transaction_Date__c = transacationDateTime, Actual_Transaction_Date__c = actualTransDate, Transaction_Status__c = scheduleStatus, Transaction_Id__c = recurWrapper.transactionreference, RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId());
                
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                    insert create_new_transaction;
                    if(recurWrapper.startDate == Date.today()){
                        Transaction__c transactiontoadd = createNewTransaction(create_new_RP, create_new_transaction);
                        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                            insert transactiontoadd;
                        }
                        receiptPageWrap.nextInstallmentDate = create_new_RP.Next_Installment_Date__c;
                    }               
                }
                receiptPageWrap.amount = recurWrapper.amount;
                receiptPageWrap.paymentResponse = recurWrapper.responseMessage;
                receiptPageWrap.paymentStatus = recurWrapper.paymentStatus;
                receiptPageWrap.establishmentDate = Date.today();
                receiptPageWrap.installPeriod = recurWrapper.instalPeriod;
                receiptPageWrap.chargeType = UTILGateway.RECURRINGKEYWORD;
                serializedWrapper = JSON.serialize(receiptPageWrap);
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = MessageHandler.processPayment(UTILGateway.NABTRANSWORD.capitalize(),UTILGateway.RECURRINGKEYWORD), Amount__c = recurWrapper.amount, Processing_Record_Id__c = recurWrapper.sfProcessingId, Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Serialized_Record__c = serializedWrapper,Gateway_Name__c=UtilGateway.NABTRANSWORD)));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                recurWrapper.logrefId = current_log.Id;
            }
            else{
                responseMessage = (recurWrapper.recurringResponse != null)? recurWrapper.recurringResponse : recurWrapper.validationResponse;
                receiptPageWrap.amount = recurWrapper.amount;
                receiptPageWrap.paymentResponse = recurWrapper.responseMessage;
                receiptPageWrap.paymentStatus = recurWrapper.paymentStatus;
                receiptPageWrap.establishmentDate = recurWrapper.startDate;
                receiptPageWrap.installPeriod = recurWrapper.instalPeriod;
                receiptPageWrap.renderPanel = recurWrapper.renderPanel;
                receiptPageWrap.chargeType = UTILGateway.RECURRINGKEYWORD;
                String retryURL = retryRecurringPayment(recurWrapper);
                serializedWrapper = JSON.serialize(receiptPageWrap);
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.NABTRANSWORD, Action__c = UTILGateway.NABTRANSWORD.capitalize() + MessageHandler.createRPFailed, Amount__c = recurWrapper.amount, Processing_Record_Id__c = recurWrapper.sfProcessingId, Charge_Type__c = UTILGateway.RECURRINGKEYWORD, HTTP_Response__c = responseMessage, Transaction_Status__c = 'Void', Serialized_Record__c = serializedWrapper, Retry_Schedule_URL__c = retryURL)));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                recurWrapper.logrefId = current_log.Id;
            }
            return recurWrapper;
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('DML Exception occurred', 'DML Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
            return null;
        }
    }
    
    /*******Method to retry recurring payment*******/
    public static String retryRecurringPayment(RecurringWrapper recurringWrap){
        try{
            String returnUrl = '';
            recurringWrap.transactionType = UTILGateway.RECURRINGKEYWORD;
            recurringWrap = NABTransactManager.requestRecurringPayment(recurringWrap); 
            String serializedWrapper = JSON.serialize(recurringWrap);
            if(recurringWrap.status == true){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.NABTRANSWORD,Processing_Record_Id__c = recurringWrap.sfProcessingId, Amount__c = recurringWrap.amount, Action__c = UTILGateway.NABTRANSWORD.capitalize() +MessageHandler.retryLog, Request_Type__c='POST', Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Frequency__c = recurringWrap.instalPeriod, Recurring_Start_Date__c = recurringWrap.startDate, Transaction_Status__c = 'Void', End_Point__c = recurringWrap.successURL, Serialized_Record__c = serializedWrapper)));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                returnUrl = '/apex/Q_Charge__NABTransactCheckout?reference='+current_log.Id;
            }
            return returnUrl;
        }
        catch(Exception ex){
            EmailHandler.sendExceptionEmail('NABTransactHelper', ex, false);
            return null;
        }            
    }
    
    /*******Method to retry oneoff transaction*******/
    public static String retryOneOffTransaction(TransactionWrapper transactionWrap){
        try{
            String returnUrl = '';
            transactionWrap.transactionType = UTILGateway.ONETIMEKEYWORD;
            transactionWrap = NABTransactManager.requestOneTimePayment(transactionWrap); 
            if(transactionWrap.status == true){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c=UTILGateway.NABTRANSWORD, Processing_Record_Id__c = transactionWrap.sfProcessingId, Amount__c = transactionWrap.amount, Action__c = UTILGateway.NABTRANSWORD.capitalize() + MessageHandler.retryLog, Request_Type__c='POST', Charge_Type__c = UTILGateway.ONETIMEKEYWORD,Transaction_Status__c = 'Void', End_Point__c = transactionWrap.successURL, Serialized_Record__c = JSON.serialize(transactionWrap))));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                returnUrl = '/apex/Q_Charge__NABTransactCheckout?reference='+current_log.Id;
            }
            return returnUrl;
        }
        catch(Exception ex){
            EmailHandler.sendExceptionEmail('NABTransactHelper', ex, false);
            return null;
        }            
    }
    
    
    /*******Method to update transaction record*******/
    public static String updateTransactionBatchProcess(Boolean callFromBatch, Boolean callFromPostUpdateCardDetailsController, String token, TransactionWrapper tranWrapper, RecurringWrapper recurWrapper){
        String responseMessage = '';
        try{
            if(NABTransactManager.detachedReason!=null){
                throw new GatewayException(NABTransactManager.detachedReason);
            }
            
            List<Transaction__c> listTransaction = new List<Transaction__c>();
            List<Transaction__c> listtoupdate = new List<Transaction__c>();
            List<Transaction__c> listtoinsert = new List<Transaction__c>();
            List<Recurring_Payment__c> listtoupdateRP = new List<Recurring_Payment__c>();
            Boolean isUpdateSuccess = false;
            boolean updatefrombatch = true;
            
            String tokenValue = '';
            Transaction__c currentTransaction = new Transaction__c();
            Recurring_Payment__c currentRP = [Select Id, Name, Amount__c, Installment_Period__c, Next_Installment_Date__c, Secured_Token__c From Recurring_Payment__c Where Id =: recurWrapper.sfProcessingId WITH SECURITY_ENFORCED LIMIT 1];
            if(Schema.sObjectType.Recurring_Payment__c.fields.Secured_Token__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable()){
                   currentRP.Secured_Token__c = recurWrapper.tokenValue;
                   currentRP.Amount__c = recurWrapper.amount;
                   currentRP.Installment_Period__c = recurWrapper.instalPeriod;
                   currentRP.Next_Installment_Date__c = recurWrapper.startDate;
               }
            else{
                throw new UTILPermission.PermsException('Recurring_Payment__c','Secured_Token__c,Id,Amount__c,Installment_Period__c,Next_Installment_Date__c','update');
            }
            
            if(callFromBatch){
                currentTransaction = [Select Id, Amount__c, Name, Transaction_Status__c, Failed_Reason__c, Transaction_Date__c, Recurring_Payment__c, Actual_Transaction_Date__c, Transaction_Id__c From Transaction__c Where Recurring_Payment__c =: currentRP.Id AND (Transaction_Status__c = 'Scheduled' OR Transaction_Status__c = 'First Transaction Failure' OR Transaction_Status__c = 'Second Transaction Failure') AND Recurring_Payment__r.Secured_Token__c != null WITH SECURITY_ENFORCED LIMIT 1]; 
            }
            else{
                currentTransaction = [Select Id, Amount__c, Name, Transaction_Status__c, Failed_Reason__c, Transaction_Date__c, Recurring_Payment__c, Actual_Transaction_Date__c, Transaction_Id__c From Transaction__c Where Id =: tranWrapper.sfProcessingId WITH SECURITY_ENFORCED LIMIT 1];
                if((Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isUpdateable())){
                    currentTransaction.Amount__c = tranWrapper.amount;
                    currentTransaction.Transaction_Date__c = tranWrapper.transactionDate;
                    currentTransaction.Recurring_Payment__c = tranWrapper.recurringRecordId;
                }
                else{
                    throw new UTILPermission.PermsException('Transaction__c','Id,Amount__c,Transaction_Date__c,Recurring_Payment__c','create/update');
                }
            }
            
            if(callFromPostUpdateCardDetailsController){
                tokenValue = token;
            }
            else{
                tokenValue = UTILGateway.decodeCustomerKeys(currentRP.Secured_Token__c);
            }
            
            String transactionAmount = String.valueOf(Integer.valueOf(currentTransaction.Amount__c*100));
            
            TransactionWrapper transWrapper = new TransactionWrapper();
            transWrapper.tokenValue = tokenValue;
            transWrapper.transactionId = currentTransaction.Id;
            transWrapper.amount = Decimal.valueOf(transactionAmount);
            transWrapper = NABTransactManager.chargeCurrentTransaction(transWrapper);
            String createRecurringPaymentResult = transWrapper.transResponse;
            String transactionId = createRecurringPaymentResult.SubStringAfter('&TransactionId=');
            createRecurringPaymentResult = createRecurringPaymentResult.substringBefore('&TransactionId=');
            
            if(createRecurringPaymentResult != null && createRecurringPaymentResult == 'Normal'){
                responseMessage = 'Transaction Successful.';
                if((Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Actual_Transaction_Date__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Actual_Transaction_Date__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Failed_Reason__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Failed_Reason__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable())){
                    currentTransaction.Transaction_Status__c = 'Paid';
                    currentTransaction.Actual_Transaction_Date__c = DateTime.now();
                    currentTransaction.Failed_Reason__c = '';
                    currentTransaction.Transaction_Id__c = transactionId;
                }
                else{
                    throw new UTILPermission.PermsException('Transaction__c','Transaction_Status__c,Actual_Transaction_Date__c,Failed_Reason__c,Transaction_Id__c','create/update');
                }
                Transaction__c transactiontoadd = createNewTransaction(currentRP, currentTransaction);
                if(transactiontoadd != null){
                    listTransaction.add(transactiontoadd); //new transaction is added.
                }
            }
            else{
                responseMessage = createRecurringPaymentResult+'.';
                if((Schema.sObjectType.Transaction__c.fields.Failed_Reason__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Failed_Reason__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable())){
                    currentTransaction.Failed_Reason__c = createRecurringPaymentResult;
                    if(callFromBatch){
                        if(currentTransaction.Transaction_Date__c.date() == Date.today())
                            currentTransaction.Transaction_Status__c='First Transaction Failure';
                        else if(currentTransaction.Transaction_Date__c.date() == Date.today().addDays(-1))
                            currentTransaction.Transaction_Status__c='Second Transaction Failure';
                        else if(currentTransaction.Transaction_Date__c.date() == Date.today().addDays(-2))
                            currentTransaction.Transaction_Status__c='Permanent Transaction Failure';
                    }
                    else{
                        currentTransaction.Transaction_Status__c='Failed';
                    }
                }
                else{
                    throw new UTILPermission.PermsException('Transaction__c','Failed_Reason__c,Transaction_Status__c','create/update');
                }
            }
            listTransaction.add(currentTransaction);
            
            //fill Transaction update and insert list.
            for(Transaction__c transactions : listTransaction)
            {
                if(transactions.id != null)
                {
                    listtoupdate.add(transactions);
                    listtoupdateRP.add(updateRecurringPayment(updatefrombatch, responseMessage, createRecurringPaymentResult, currentRP, currentTransaction));
                }
                else
                {
                    listtoinsert.add(transactions);
                }
            }
            
            if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update')){
                //update Transaction transaction.
                update listtoupdate;
                isUpdateSuccess = true;
            }
            
            if(isUpdateSuccess == true){
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create')){
                    insert listtoinsert;
                }
                if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                    UTILGateway.allowRPUpdate = true;
                    update listtoupdateRP;
                }
            }
            if(callFromPostUpdateCardDetailsController){
                return responseMessage+'&NextInstallmentDate='+String.valueOf(listtoupdateRP[0].Next_Installment_Date__c);
            }
            else{
                return responseMessage;
            }
        }
        catch(UTILPermission.PermsException pex){
            responseMessage = pex.getMessage();
            EmailHandler.sendExceptionEmailtoAdmin('NABTransactHelper',pex,null);
        } catch(DmlException dex){
            responseMessage = dex.getMessage();
            EmailHandler.sendExceptionEmailtoAdmin('NABTransactHelper',dex,null);
        } catch(Exception ex){
            responseMessage = ex.getMessage();
            EmailHandler.sendExceptionEmail('NABTransactHelper', ex, false);
        }
        return responseMessage;
    }
    
    
    /*******Method to update Recurring payment record*******/
    public static Recurring_Payment__c updateRecurringPayment(Boolean updatefrombatch, String responseMessage, String response, Recurring_Payment__c RPRecord, Transaction__c transactionRecord)
    {
        dateTime savedTransactioDate = transactionRecord.Transaction_Date__c;
        if(updatefrombatch == true){
            if(Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable()){
                if(RPRecord.Installment_Period__c == 'Weekly')
                    transactionRecord.Transaction_Date__c = transactionRecord.Transaction_Date__c.addDays(7);
                else if(RPRecord.Installment_Period__c == 'Fortnightly')
                    transactionRecord.Transaction_Date__c = transactionRecord.Transaction_Date__c.addDays(14);
                else if(RPRecord.Installment_Period__c == 'Monthly')
                    transactionRecord.Transaction_Date__c = transactionRecord.Transaction_Date__c.addMonths(1);
                else if(RPRecord.Installment_Period__c == 'Quarterly')
                    transactionRecord.Transaction_Date__c = transactionRecord.Transaction_Date__c.addMonths(3);
                else if(RPRecord.Installment_Period__c == 'Half Yearly')
                    transactionRecord.Transaction_Date__c = transactionRecord.Transaction_Date__c.addMonths(6);
                else if(RPRecord.Installment_Period__c == 'Yearly')
                    transactionRecord.Transaction_Date__c = transactionRecord.Transaction_Date__c.addYears(1);
                
                
            }else{
                throw new UTILPermission.PermsException('Transaction__c','Transaction_Date__c','Create');
            }
        }
        if(response == 'Normal'){
            if(Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable()){
                RPRecord.Next_Installment_Date__c = Date.valueOf(transactionRecord.Transaction_Date__c);
            }
            else{
                throw new UTILPermission.PermsException('Recurring_Payment__c','Next_Installment_Date__c','update');
            }
            if(updatefrombatch == true){
                transactionRecord.Transaction_Date__c = savedTransactioDate;
            }
        }
        return RPRecord;
    }
    
    /*******Method to Update RP for refund information*******/
    public static String updateRPForRefundInfo(String refundTransactionId, String paymentReference, String recurringpaymentId){
        try{
            Recurring_Payment__c current_RP = [Select Id, Name, Refund_Amount__c, Gateway_Refund_Id__c, Refund_Status__c, Gateway_Schedule_Id__c, Refund_Description__c, Refund_Date__c from Recurring_Payment__c Where Id =: recurringpaymentId WITH SECURITY_ENFORCED LIMIT 1];
            if(Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Date__c.isCreateable() && UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                current_RP.Refund_Amount__c = 1.00;
                current_RP.Gateway_Refund_Id__c = refundTransactionId;
                current_RP.Refund_Status__c = 'Awaiting';
                current_RP.Gateway_Schedule_Id__c = paymentReference;
                current_RP.Refund_Date__c = null;
                current_RP.Refund_Description__c = '';
                UTILGateway.allowRPUpdate = true;
                UTILGateway.allowRPUpdate = true;
                update current_RP;
            }
            else{
                throw new UTILPermission.PermsException('Recurring_Payment__c','Gateway_Schedule_Id__c,Gateway_Refund_Id__c,Refund_Amount__c,Refund_Status__c','Create');
            }
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendEmailTo('DML Exception occurred', 'DML Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
        return null;
    }
    
    
    /*******Method to next create transaction record*******/
    public static Transaction__c createNewTransaction(Recurring_Payment__c RPRecord, Transaction__c transactionRecord)
    {
        Transaction__c new_Transaction = new Transaction__c();
        if((Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()) && (Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() || Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable()) && 
           (Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() || Schema.sObjectType.Transaction__c.fields.RecordTypeId.isUpdateable())){
               
               new_Transaction.Amount__c = RPRecord.Amount__c;
               new_Transaction.Recurring_Payment__c = RPRecord.Id;
               
               new_Transaction.Transaction_Status__c = 'Scheduled';
               new_Transaction.Gateway_Name__c = UTILGateway.NABTRANSWORD.replace('_',' ');
               new_Transaction.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
           }else{
               throw new UTILPermission.PermsException('Transaction__c','Amount__c,Recurring_Payment__c,Transaction_Status__c,Gateway_Name__c,RecordTypeId','Create/Update');
           }
        
        if(Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable()){
            
            if(RPRecord.Installment_Period__c == 'Weekly')
                new_Transaction.Transaction_Date__c = transactionRecord.Transaction_Date__c.addDays(7);
            else if(RPRecord.Installment_Period__c == 'Fortnightly')
                new_Transaction.Transaction_Date__c = transactionRecord.Transaction_Date__c.addDays(14);
            else if(RPRecord.Installment_Period__c == 'Monthly')
                new_Transaction.Transaction_Date__c = transactionRecord.Transaction_Date__c.addMonths(1);
            else if(RPRecord.Installment_Period__c == 'Quarterly')
                new_Transaction.Transaction_Date__c = transactionRecord.Transaction_Date__c.addMonths(3);
            else if(RPRecord.Installment_Period__c == 'Half Yearly')
                new_Transaction.Transaction_Date__c = transactionRecord.Transaction_Date__c.addMonths(6);
            else if(RPRecord.Installment_Period__c == 'Yearly')
                new_Transaction.Transaction_Date__c = transactionRecord.Transaction_Date__c.addYears(1);
            
        }else{
            throw new UTILPermission.PermsException('Transaction__c','Transaction_Date__c','Create');
        }
        return new_Transaction;
    }
    
    /************Method to cancel Recurring Payment************/
    public static String cancelRecurringPayment(List<Recurring_Payment__c> existingRPList){
        String returnvalue = '';
        Recurring_Payment__c existingRP = new Recurring_Payment__c();
        try{
            if(existingRPList.size() > 0){
                for(Recurring_Payment__c recurPayment : existingRPList){
                    existingRP = recurPayment;
                }
            }else{
                return MessageHandler.wentWrongCatchMessage;
            }
            List<Transaction__c> scheduledTransaction = [Select Id, Transaction_Id__c, Recurring_Payment__c, Transaction_Status__c from Transaction__c where Recurring_Payment__c =: existingRP.id AND (Transaction_Status__c = 'Scheduled' OR Transaction_Status__c = 'First Transaction Failure' OR Transaction_Status__c = 'Second Transaction Failure') WITH SECURITY_ENFORCED limit 1];
            
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.NABTRANSWORD.capitalize() + MessageHandler.cancelRecPay, Processing_Record_Id__c = existingRP.Id, Charge_Type__c = 'Recurring', Amount__c = existingRP.Amount__c, Transaction_Status__c = 'Void',Gateway_Name__c=UtilGateway.NABTRANSWORD)));
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            
            If(Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable() && (UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update'))){
                if(scheduledTransaction.size() > 0){
                    scheduledTransaction[0].Transaction_Status__c = 'Cancelled';
                }
                existingRP.Status__c = 'Closed';
                
                UTILGateway.allowRPUpdate = true;
                update existingRP;
                update scheduledTransaction;
                returnvalue = existingRP.Name+MessageHandler.cancelRP+' in NAB Transact.';
            }
            else{
                throw new UTILPermission.PermsException('Transaction__c,Recurring_Payment__c','Transaction_Status__c,Status__c','update');
            }
        }
        catch(Exception ex){
            returnvalue = 'Exception Occured : '+ex.getMessage();
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
        return returnvalue;
    }
    
    /*********Method to request update card details********/
    public static String requestUpdateCardDetails(String recordId, String requestUrl){
        String returnValue='';
        RecurringWrapper recurringWrap = new RecurringWrapper();
        recurringWrap = NABTransactManager.updateCardDetails(recurringWrap);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c = recordId, Action__c = UTILGateway.NABTRANSWORD.capitalize()+MessageHandler.updateCardRequest, Requesting_Url__c = requestUrl, Gateway_Name__c = UTILGateway.NABTRANSWORD, Retry_Schedule_URL__c = recurringWrap.successURL)));
        List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c current_log = new_log.get(new_log.size()-1);
        if(recurringWrap.status == true){
            returnValue = recurringWrap.processingLink+'?reference='+current_log.Id;
        }
        else{
            returnValue = recurringWrap.errorResponse;
        }
        return returnValue;
    }
    
    /******Method to process update card details********/
    public static String updateCardDetails(RecurringWrapper recurWrap){
        String returnValue = '';
        try{
            Recurring_Payment__c current_RP = [Select Id, Name, Card_Expiry_Date__c, Card_Name__c, Card_Number__c, Card_Last_Updated_On__c From Recurring_Payment__c Where Id =: recurWrap.sfProcessingId WITH SECURITY_ENFORCED limit 1];
            Integer last_day_of_month = Date.daysInMonth(Integer.valueOf(recurWrap.cardExpiryDate.right(4)), Integer.valueOf(recurWrap.cardExpiryDate.substring(0,2)));
            current_RP.Card_Expiry_Date__c = Date.newinstance(Integer.valueOf(recurWrap.cardExpiryDate.right(4)), Integer.valueOf(recurWrap.cardExpiryDate.substring(0,2)), last_day_of_month);
            current_RP.Card_Name__c = recurWrap.cardHolderName.replace('+',' ');
            current_RP.Card_Number__c = recurWrap.cardNumber;
            current_RP.Card_Last_Updated_On__c = Datetime.now();
            current_RP.Secured_Token__c = UTILGateway.encodeCustomerKeys(recurWrap.tokenValue);
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                UTILGateway.allowRPUpdate = true;
                returnvalue = MessageHandler.creditCardUpdatSuccesse+' NAB Transact.';
                update current_RP;
            }
        }
        catch(Exception ex){
            returnvalue = 'Exception Occured : '+ex.getMessage();
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
        return returnValue;
    }
    
    /*******Method to retry update card details********/
    public static RecurringWrapper retryUpdateCardDetails(RecurringWrapper wrapper){
        String redirectURL = requestUpdateCardDetails(wrapper.sfProcessingId, wrapper.requestUrl);
        ReceiptWrapper receipt = new ReceiptWrapper();
        receipt.amount = 100;
        receipt.paymentResponse = MessageHandler.updateCardfailed+wrapper.responseMessage;
        receipt.paymentStatus = 'Transaction Rejected';
        Payment_Log__c log = new Payment_Log__c(Processing_Record_Id__c = wrapper.sfProcessingId, Action__c =  UTILGateway.NABTRANSWORD.capitalize()+MessageHandler.updateCardfail, Serialized_Record__c = JSON.serialize(receipt), Requesting_Url__c = wrapper.requestUrl, Gateway_Name__c = UTILGateway.NABTRANSWORD, Retry_Schedule_Url__c = redirectURL, Charge_Type__c = UTILGateway.ONETIMEKEYWORD, Amount__c = 100);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        return wrapper;
    }
    
    /****Method to cancel single RP transaction******/
    public static String cancelTransaction(String recordId){
        String returnValue = '';
        try{
            Boolean isUpdateSuccess = false;
            Transaction__c current_transaction = [Select Id, Name, Transaction_Date__c, Transaction_Status__c, Recurring_Payment__c, Failed_Reason__c From Transaction__c Where Id =: recordId WITH SECURITY_ENFORCED LIMIT 1];
            
            Recurring_Payment__c getRPRecord = [Select Id, Name, Amount__c, Gateway_Name__c, Installment_Period__c, Next_Installment_Date__c,  Secured_Token__c, RelatedToId__c, Status__c from Recurring_Payment__c Where Id =: current_transaction.Recurring_Payment__c WITH SECURITY_ENFORCED LIMIT 1];
            
            If(Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update')){
                current_transaction.Transaction_Status__c = 'Cancelled';
                update current_transaction;
                isUpdateSuccess = true;
                returnvalue = current_transaction.Name + MessageHandler.cancelRP+'.';
            }
            else{
                throw new UTILPermission.PermsException('Transaction__c,Recurring_Payment__c','Transaction_Status__c,Status__c','update');
            }
            if(isUpdateSuccess){
                Transaction__c new_transaction = createNewTransaction(getRPRecord, current_transaction);
                
                Recurring_Payment__c RPRecord = updateRecurringPayment(true, current_transaction.Failed_Reason__c, 'Normal', getRPRecord, current_transaction);
                If(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'insert')){
                    insert new_transaction;
                    UTILGateway.allowRPUpdate = true;
                    update RPRecord;
                }     
            }
        }
        catch(Exception ex){
            returnvalue = 'Exception Occured : '+ex.getMessage();
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
        return returnvalue;
    }
    
    /****Mehtod to process update RP*****/
    public static String processUpdateRP(RecurringWrapper recurWrap){
        String returnvalue = '';
        try{
            Recurring_Payment__c current_RP = [Select Id, Name, Amount__c, Installment_Period__c, Next_Installment_Date__c, Secured_Token__c From Recurring_Payment__c Where Id =: recurWrap.sfProcessingId WITH SECURITY_ENFORCED LIMIT 1];
            
            Transaction__c latest_transaction = [Select Id, Name, Transaction_Date__c, Amount__c From Transaction__c Where Recurring_Payment__c =: current_RP.Id AND Transaction_Status__c = 'Scheduled' WITH SECURITY_ENFORCED LIMIT 1];
            
            If(Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable()){
                current_RP.Amount__c = recurWrap.amount;
                current_RP.Installment_Period__c = recurWrap.instalPeriod;
                current_RP.Next_Installment_Date__c = recurWrap.startDate;
                
                latest_transaction.Transaction_Date__c = recurWrap.startDate;
                latest_transaction.Amount__c = recurWrap.amount;
                
                If(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'update')){
                    if(current_RP.Next_Installment_Date__c == Date.today()){
                        TransactionWrapper transWrapper = new TransactionWrapper();
                        transWrapper.sfProcessingId = latest_transaction.Id;
                        transWrapper.amount = recurWrap.amount;
                        transWrapper.transactionDate = recurWrap.startDate;
                        transWrapper.recurringRecordId = current_RP.Id;
                        recurWrap.tokenValue = current_RP.Secured_Token__c;
                        
                        String methodResponse = updateTransactionBatchProcess(false, false, null, transWrapper, recurWrap);
                        if(methodResponse == 'Transaction Successful.'){
                            returnvalue = current_RP.Name + MessageHandler.updateRP+' NAB Transact.';
                        }
                        else{
                            returnvalue = methodResponse;
                        }
                    }
                    else{
                        UTILGateway.allowRPUpdate = true;
                        update current_RP;
                        update latest_transaction;
                        returnvalue = current_RP.Name + MessageHandler.updateRP+' NAB Transact.';
                    }
                }
            }
            else{
                throw new UTILPermission.PermsException('Transaction__c,Recurring_Payment__c','Transaction_Status__c,Status__c','update');
            }
        }
        catch(Exception ex){
            returnvalue = 'Exception Occured : '+ex.getMessage();
            EmailHandler.sendEmailTo('Exception occurred', 'Exception occurred: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
        return returnvalue;
    }
}