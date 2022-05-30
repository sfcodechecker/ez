public with sharing class GatewayPostCheckoutController {
    
    public String spinnerMessage{get;set;}
    public String errorMessage{get;set;}
    public String redirectUrl{get;set;}
    public String paymentReference{get; set;}
    public string transactionId {get; set;}
    public string returnToken {get; set;}
    
    
    public String paymentReferenceID;
    List<Payment_Log__c> paymentLogList;
    public string gatewayName ;
    public String chargetype;
    public string paymentyLogRef;
    //NAB
    public String responseMessage;
    public String paymentStatus;
    public String refundTransactionId;
    public String scheduleTransactionId;
    public string createRecurringPaymentResult;
    public String cardNumber;
    public String cardExpiry;
    public String cardHolder;
    
    public String responseText;
    
    public TransactionWrapper oneTimeWrap{get;set;}
    public RecurringWrapper wrapperRP{get;set;}
    
    //stripe
    public String customerId; 
    public String stripeStatus;
    public String refreshPage{get;set;}
    
    public GatewayPostCheckoutController() {
        try {
            paymentLogList = new List<Payment_Log__c>();
            
            paymentyLogRef = ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            if(paymentyLogRef.length()==31){
                paymentReferenceID = paymentyLogRef.substring(0, 18);
            }else if(paymentyLogRef == 'stripe'){
                customerId = ApexPages.currentPage().getParameters().get('customer_id').escapeHtml4();
                paymentReferenceID = [Select id, Processing_Record_Id__c From Payment_Log__c Where Payment_Parameter_1__c = :customerId WITH SECURITY_ENFORCED LIMIT 1].id;
            }
            else{
                paymentReferenceID = paymentyLogRef;
            }

            paymentLogList = [Select id, Q_Charge__Frequency__c,Processing_Record_Id__c,Amount__c,Q_Charge__Gateway_Name__c,Q_Charge__Recurring_Start_Date__c, Serialized_Record__c,Charge_Type__c,Payment_Parameter_1__c,Requesting_Url__c,Q_Charge__HTTP_Response__c,Payment_Parameter_2__c, Payment_Parameter_3__c from Payment_Log__c where Id =: paymentReferenceID WITH SECURITY_ENFORCED LIMIT 1];
            if(paymentLogList.size() == 1){
                
                chargetype = paymentLogList[0].Charge_Type__c;
                gatewayName = paymentLogList[0].Q_Charge__Gateway_Name__c;
                
                if(chargetype == UTILGateway.ONETIMEKEYWORD && gatewayName != 'stripe'){
                    oneTimeWrap=(TransactionWrapper)JSON.deserialize(paymentLogList[0].Serialized_Record__c, TransactionWrapper.class);
                    spinnerMessage= MessageHandler.spinnerWait;
                    
                }else if(chargetype == UTILGateway.RECURRINGKEYWORD && gatewayName != 'stripe'){
                    
                    wrapperRP = (RecurringWrapper)JSON.deserialize(paymentLogList[0].Serialized_Record__c, RecurringWrapper.class);
                    wrapperRP.recurringRequestId = paymentyLogRef;
                    spinnerMessage = MessageHandler.spinnerCardValidate;
                }else{
                    spinnerMessage= MessageHandler.spinnerWait;
                }
            }else{
                errorMessage = (paymentReferenceID != null && paymentReferenceID != '') ? MessageHandler.incorrectLogId : MessageHandler.missingLogId;
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, errorMessage));
            }
            
        }catch(Exception ex){
            errorMessage = ex.getMessage() +' found at '+ ex.getStackTraceString();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Checkout cannot be performed.'+errorMessage));
        }
    }
    
    
    public void completePayment()
    {
        if(chargetype==UTILGateway.ONETIMEKEYWORD){
            try{
                switch on gatewayName {
                    when 'stripe' {
                        customerId = ApexPages.currentPage().getParameters().get('customer_id').escapeHtml4();
                        stripeStatus = ApexPages.currentPage().getParameters().get('status').escapeHtml4();
                        responseMessage = StripeHelper.ProcessOneTimeTransaction(paymentLogList,stripeStatus);
                        redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+responseMessage+'&status='+stripeStatus;
                    }
                    when 'payway' {
                        PaywayTransactionResponseWrapper oneOffresponsewrapper = PaywayHelper.procesOneTimePayment(oneTimeWrap);
                        redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+oneOffresponsewrapper.transactionReference;
                    }
                    when 'nab_transact' {
                        transactionId = ApexPages.currentPage().getParameters().get('txnid').escapeHtml4();
                        responseText = ApexPages.currentPage().getParameters().get('restext').escapeHtml4();
                        oneTimeWrap.transactionId = transactionId;
                        oneTimeWrap.responseText = responseText;
                        TransactionWrapper transWrapper = NABTransactHelper.ProcessOneTimeTransaction(oneTimeWrap);
                        redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+transWrapper.logrefId;
                    }
                    when 'ezidebit' {
                        oneTimeWrap = EzidebitHelper.ProcessingOneTimeTransaction(oneTimeWrap);
                        redirectUrl='/apex/Q_Charge__GatewayReceiptPage?reference='+oneTimeWrap.logrefId;
                    }
                    when 'bpoint' {
                        Decimal amount = Decimal.valueOf(ApexPages.currentPage().getParameters().get('amount').escapeHtml4());
                        oneTimeWrap.logrefId=paymentyLogRef;
                        BpointTxnResponseWrapper response = BpointTxnResponseWrapper.parse(paymentLogList[0].Q_Charge__HTTP_Response__c);
                        response.TxnResp.Amount = amount;
                        Id refId = BpointHelper.processOneOffPayment(response,oneTimeWrap);
                        redirectUrl='/apex/Q_Charge__GatewayReceiptPage?reference='+refId;
                    }
                    when 'simplify' {
                        oneTimeWrap.logrefId=paymentReferenceID;
                        oneTimeWrap=SimplifyHelper.ProcessOneTimePayment(oneTimeWrap);
                        redirectUrl='/apex/GatewayReceiptPage?reference='+oneTimeWrap.logrefId;
                    }
                    when else{
                        throw new GatewayException(MessageHandler.wentWrongCatchMessage);
                    }
                }
                
            } catch(UTILPermission.PermsException pex){
                errorMessage = pex.getMessage();
                EmailHandler.sendExceptionEmailtoAdmin('GatewayPostCheckoutController',pex,null);
            } catch(Exception ex){
                errorMessage = ex.getMessage() +' due to '+ ex.getStackTraceString();
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Checkout cannot be performed.'+errorMessage));
                EmailHandler.sendExceptionEmail('GatewayPostCheckoutController', ex, false);
            }   
        }
        else if(chargetype==UTILGateway.RECURRINGKEYWORD){
            try
            {
                switch on gatewayName 
                {
                    when 'stripe' {
                        customerId = ApexPages.currentPage().getParameters().get('customer_id').escapeHtml4();
                        stripeStatus = ApexPages.currentPage().getParameters().get('status').escapeHtml4();
                        responseMessage = StripeHelper.ProcessRecurringTransaction(paymentLogList,stripeStatus);
                        redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+responseMessage+'&status='+stripeStatus;
                    }
                    when 'payway' {
                        if(wrapperRP.customerNumber != null && wrapperRP.customerNumber != ''){
                            PaywayRecurringResponseWrapper transactionresponsewrapper = PaywayHelper.proessRecurringPaymentRetry(wrapperRP);
                            redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+transactionresponsewrapper.transactionReference;
                        }else{
                            PaywayRecurringResponseWrapper transactionresponsewrapper = PaywayHelper.proessRecurringPayment(wrapperRP);
                            redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+transactionresponsewrapper.transactionReference;
                        }
                    }
                    when 'nab_transact' {
                        paymentReference = ApexPages.currentPage().getParameters().get('refid').escapeHtml4();
                        returnToken = ApexPages.currentPage().getParameters().get('token').escapeHtml4();
                        responseText = ApexPages.currentPage().getParameters().get('strestext').escapeHtml4();
                        cardNumber = ApexPages.currentPage().getParameters().get('pan').escapeHtml4();
                        cardExpiry = ApexPages.currentPage().getParameters().get('expirydate').escapeHtml4(); 
                        cardHolder = ApexPages.currentPage().getParameters().get('nameOnCard').escapeHtml4();
                        wrapperRP.logrefId = paymentReferenceID;
                        wrapperRP.refundReference = paymentReference;
                        wrapperRP.tokenValue = returnToken;
                        wrapperRP.responseMessage = responseText;
                        wrapperRP.cardExpiryMonth = cardExpiry.substring(0,2);
                        wrapperRP.cardExpiryYear = cardExpiry.right(4);
                        wrapperRP.cardNumber = cardNumber;
                        wrapperRP.CardHolderName = cardHolder.replace('+',' ');
                        RecurringWrapper recResp = NABTransactHelper.ProcessRecurringTransaction(wrapperRP);
                        redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+recResp.logrefId;
                    }
                    when 'ezidebit' {
                        wrapperRP=EzidebitHelper.validationChecksBeforeRPCreation(wrapperRP,paymentLogList[0]);
                        if(!wrapperRP.status){
                            redirectUrl='/apex/Q_Charge__SomethingWentWrong?';
                            return;
                        }
                        wrapperRP = EzidebitHelper.ProcessingRecurringPayment(wrapperRP);
                        redirectUrl = '/apex/Q_Charge__GatewayReceiptPage?reference='+wrapperRP.logrefId;
                    }
                    when 'bpoint' {
                        Decimal Amount = Decimal.valueOf(ApexPages.currentPage().getParameters().get('amount').escapeHtml4());
                        wrapperRP.logrefId=paymentyLogRef;
                        BpointTxnResponseWrapper response = BpointTxnResponseWrapper.parse(paymentLogList[0].Q_Charge__HTTP_Response__c);
                        response.TxnResp.Amount = Amount;
                        Id refId = BpointHelper.ProcessRecurringPayment(response, wrapperRP);
                        redirectUrl='/apex/Q_Charge__GatewayReceiptPage?reference='+refId;
                    }
                    when 'simplify' {
                        Id contactId=paymentLogList[0].Processing_Record_Id__c;
                        Contact con=[Select FirstName,LastName,Email from Contact where Id=:contactId WITH SECURITY_ENFORCED Limit 1];
                        wrapperRP.name=con.FirstName+' '+con.LastName;
                        wrapperRP.email=con.Email;
                        wrapperRP.tokenValue=paymentLogList[0].Payment_Parameter_1__c;
                        wrapperRP=SimplifyHelper.ProcessingRecurringPayment(wrapperRP);
                        redirectUrl='/apex/Q_Charge__GatewayReceiptPage?reference='+wrapperRP.logrefId;                    
                    }
                    when else{
                        throw new GatewayException(MessageHandler.wentWrongCatchMessage);
                    }
                }
            }
            catch(UTILPermission.PermsException pex){
                errorMessage = pex.getMessage();
                EmailHandler.sendExceptionEmailtoAdmin('GatewayPostCheckoutController',pex,null);
            }
            catch(Exception ex){
                errorMessage = ex.getMessage();
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Checkout cannot be performed.'+errorMessage));
                EmailHandler.sendExceptionEmail('GatewayPostCheckoutController', ex, false);
            }
        }
    }  
}