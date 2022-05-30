public with sharing class PostUpdateCardDetailsController {
    
    public static String tokenValue{get;set;}
    public static String renderMessage{get;set;}
    public String refreshPage{get;set;}
    public String logId{get;set;}
    public String responseText{get;set;}
    public Payment_Log__c logRefId;
    public String gatewayName;
    public String recurringId{get;set;}
    public String result{get;set;}
    public String returnMsg{get;set;}
    public String validationResult;
    public String refundTransactionId;
    public String paymentReference;
    public String cardNumber;
    public String cardExpiry;
    public String cardHolder;
    
    public PostUpdateCardDetailsController(){
        try{
            logId = ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            responseText = ApexPages.currentPage().getParameters().get('strestext').escapeHtml4();
            tokenValue = ApexPages.currentPage().getParameters().get('token').escapeHtml4();
            paymentReference = ApexPages.currentPage().getParameters().get('refid').escapeHtml4();
            cardNumber = ApexPages.currentPage().getParameters().get('pan').escapeHtml4();
            cardExpiry = ApexPages.currentPage().getParameters().get('expirydate').escapeHtml4(); 
            cardHolder = ApexPages.currentPage().getParameters().get('nameOnCard').escapeHtml4();
            if(logId == 'null'){
                renderMessage = MessageHandler.wentWrongCatchMessage;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,renderMessage));
            }
            logRefId = [Select Id,Processing_Record_Id__c,Transaction_Id__c,Requesting_Url__c, Retry_Schedule_URL__c, Gateway_Name__c from Payment_Log__c where Id =: logId WITH SECURITY_ENFORCED Limit 1];
            gatewayName = logRefId.Gateway_Name__c;
            recurringId = logRefId.Processing_Record_Id__c;
            if(logRefId.Requesting_Url__c != null){
                refreshPage = logRefId.Requesting_Url__c;
            }else{
                refreshPage = URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+recurringId;
            }
        }
        catch(Exception ex){
            renderMessage = MessageHandler.urlEdit;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,renderMessage));
            System.debug('Stack Trace '+ex.getStackTraceString()+' Message '+ex.getMessage()+' Line number '+ex.getLineNumber());
            EmailHandler.sendExceptionEmail('UpdateCreditCardController', ex, false);
        }
    }
    
    /********Method to update the recurring payment*********/
    public void updateRecurringPayment(){
        try{
            String returnValue = '';
            Date next_installment_date;
            Recurring_Payment__c current_RP = [Select Id, Name, Card_Last_Updated_On__c, Secured_Token__c, Date_Established__c, Installment_Period__c, Next_Installment_Date__c, Amount__c From Recurring_Payment__c Where Id =: recurringId WITH SECURITY_ENFORCED LIMIT 1];
            if(responseText == 'Successful'){
                String token = Apexpages.currentPage().getParameters().get('tokenValue').escapeHtml4();
                Transaction__c check_if_failed_transaction = [Select Id, Name, Transaction_Status__c, Amount__c from Transaction__c Where Recurring_Payment__c =: current_RP.Id WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 1];
                
                if(check_if_failed_transaction.Transaction_Status__c == 'Failed' || check_if_failed_transaction.Transaction_Status__c == 'First Transaction Failure' || check_if_failed_transaction.Transaction_Status__c == 'Second Transaction Failure' || check_if_failed_transaction.Transaction_Status__c == 'Permanent Transaction Failure'){
                    RecurringWrapper recurWrap = new RecurringWrapper();
                    recurWrap.sfProcessingId = current_RP.Id;
                    recurWrap.amount = current_RP.Amount__c;
                    recurWrap.instalPeriod = current_RP.Installment_Period__c;
                    recurWrap.startDate = current_RP.Next_Installment_Date__c;
                    recurWrap.tokenValue = current_RP.Secured_Token__c;
                    
                    TransactionWrapper tranWrapper = new TransactionWrapper();
                    tranWrapper.sfProcessingId = check_if_failed_transaction.Id;
                    tranWrapper.amount = current_RP.Amount__c;
                    tranWrapper.transactionDate = current_RP.Next_Installment_Date__c;
                    tranWrapper.recurringRecordId = current_RP.Id;
                    
                    returnValue = NABTransactHelper.updateTransactionBatchProcess(false, true, token, tranWrapper, recurWrap);
                    next_installment_date = Date.valueOf(returnValue.SubStringAfter('&NextInstallmentDate='));
                    returnValue = returnValue.substringBefore('&NextInstallmentDate=');
                    if(returnValue == 'Transaction Successful.'){
                        validationResult = 'Normal';
                    }
                    else{
                        validationResult = returnValue;
                    }
                }
                else{
                    TransactionWrapper transWrapper = new TransactionWrapper();
                    transWrapper.tokenValue = token; 
                    transWrapper.transactionId = paymentReference;
                    transWrapper = NABTransactManager.validateCreditCard(transWrapper);
                    validationResult = transWrapper.transResponse;
                    refundTransactionId = validationResult.SubStringAfter('&TransactionId=');        
                    validationResult = validationResult.substringBefore('&TransactionId=');
                    String response = NABTransactHelper.updateRPForRefundInfo(refundTransactionId,paymentReference, current_RP.Id);
                }
                
                
                if(validationResult == 'Normal'){
                    RecurringWrapper recurWrap = new RecurringWrapper();
                    recurWrap.cardExpiryDate = cardExpiry;
                    recurWrap.cardNumber = cardNumber;
                    recurWrap.cardHolderName = cardHolder;
                    recurWrap.tokenValue = token;
                    recurWrap.sfProcessingId = current_RP.Id;
                    String updateMessage = NABTransactHelper.updateCardDetails(recurWrap);
                    if(updateMessage.contains('successfully') && (check_if_failed_transaction.Transaction_Status__c == 'Failed' || check_if_failed_transaction.Transaction_Status__c == 'First Transaction Failure' || check_if_failed_transaction.Transaction_Status__c == 'Second Transaction Failure' || check_if_failed_transaction.Transaction_Status__c == 'Permanent Transaction Failure')){
                        ReceiptWrapper receiptPageWrap = new ReceiptWrapper();
                        receiptPageWrap.amount = check_if_failed_transaction.Amount__c;
                        receiptPageWrap.paymentResponse = MessageHandler.recurringSuccess;
                        receiptPageWrap.paymentStatus = (validationResult == 'Normal') ? 'Payment Approved' : 'Payment Rejected';
                        receiptPageWrap.establishmentDate = current_RP.Date_Established__c;
                        receiptPageWrap.installPeriod = current_RP.Installment_Period__c;
                        receiptPageWrap.nextInstallmentDate = next_installment_date;
                        receiptPageWrap.chargeType = 'Recurring';
                        String serializedWrapper = JSON.serialize(receiptPageWrap);
                        
                        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.NABTRANSWORD,Action__c = UTILGateway.NABTRANSWORD.capitalize() + MessageHandler.chargeFailed, Amount__c = check_if_failed_transaction.Amount__c, Processing_Record_Id__c = current_RP.Id, Charge_Type__c = 'Recurring', Serialized_Record__c = serializedWrapper)));
                        List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                        Payment_Log__c current_log = new_log.get(new_log.size()-1);
                        returnMsg = '/apex/Q_Charge__GatewayReceiptPage?reference='+current_log.Id;
                    }
                    else{
                        returnMsg = MessageHandler.creditCardUpdatSuccesse+' NAB Transact.';
                    }
                }
                else{
                    RecurringWrapper wrapper = new RecurringWrapper();
                    wrapper.sfProcessingId = current_RP.Id;
                    wrapper.requestUrl = logRefId.Requesting_Url__c;
                    wrapper.responseMessage = validationResult;
                    wrapper = NABTransactHelper.retryUpdateCardDetails(wrapper);            
                    List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                    Payment_Log__c log = paymentLogList.get(paymentLogList.size()-1);
                    returnMsg = '/apex/Q_Charge__GatewayReceiptPage?reference='+log.Id;
                    
                }
            }
            else if(responseText != null){
                RecurringWrapper wrapper = new RecurringWrapper();
                wrapper.sfProcessingId = current_RP.Id;
                wrapper.requestUrl = logRefId.Requesting_Url__c;
                wrapper.responseMessage = responseText;
                wrapper = NABTransactHelper.retryUpdateCardDetails(wrapper);            
                List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c log = paymentLogList.get(paymentLogList.size()-1);
                returnMsg = '/apex/Q_Charge__GatewayReceiptPage?reference='+log.Id;
            }
        }catch(DmlException dex){
            returnMsg=dex.getMessage();
            EmailHandler.sendExceptionEmail('PostUpdateCardDetailsController', dex, false);
        }
        catch(Exception ex){
            System.debug('Stack trace '+ex.getStackTraceString()+' '+ex.getMessage()+' '+ex.getLineNumber());
            returnMsg = ex.getMessage();
            EmailHandler.sendExceptionEmail('PostUpdateCardDetailsController', ex, false);
        }
    }
    
}