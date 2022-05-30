public with sharing class UpdateCreditCardController {
    public String publicKey{get;set;}
    public String amount{get;set;}
    public String showAmount{get;set;}
    public String endPoint{get;set;}
    public static String referenceId{get;set;}
    public Payment_Log__c ref_log{get;set;}
    public String logId{get;set;}
    public static String renderMessage{get;set;}
    public String companyName{get;set;}
    public String recurringId{get;set;}
    public String refreshPage{get;set;}
    public String merchantId{get;set;}
    public boolean tokenStore{get;set;}
    public string tokenStoreType{get;set;}
    public Integer transactionType{get;set;}
    public String paymentReference{get;set;}
    public String GMTtimestamp{get;set;}
    public String fingerprintValue{get;set;}
    public String resultURL{get;set;}
    public String result{get;set;}
    public String returnMsg{get;set;}
    public Boolean redirect{get;set;}
    public boolean resultParams{get;set;}  
    public String gatewayName;
    public string transactionPassword;
    public String combineString;
    public Blob hmacData;
    public String errorMessage{get;set;}
    public String hostedpayments_publicKey{get;set;}
    public String responseToken{get;set;}
    //Payway
    public String publishableKey {get;set;}
    public string paymentlogId {get; set;} 
    public String singleUseTokenId {get; set;}
    public String merchanID {get;set;}
    public String customerNumber;
    public List<String> expiryYear{get;set;}
    public List<String> monthsOfYear{get;set;}
    public List<Recurring_Payment__c> rpToUpdate;
    public string rpName {get;set;}
    public string installperiod {get;set;}
    public string nextPayDate {get;set;}
    
    //stripe
    public String record_id;
    public String ChargeStatus {get;set;}
    
    public UpdateCreditCardController() {
        companyName=UserInfo.getOrganizationName();
        try{
            
            logId=ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            if(logId=='null'){
                renderMessage=MessageHandler.wentWrongCatchMessage;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,renderMessage));
                
            }else if(logId == 'stripe'){
                record_id = ApexPages.currentPage().getParameters().get('record_id').escapeHtml4();
                logId = [SELECT Id,Amount__c,Gateway_Name__c FROM Payment_Log__c WHERE Processing_Record_Id__c = :record_id WITH SECURITY_ENFORCED Order by createddate desc limit 1 ].id;
            }
            
            ref_log = [SELECT Id,Processing_Record_Id__c,Amount__c,Frequency__c,Transaction_Id__c,Payment_Parameter_1__c,Payment_Parameter_2__c, Payment_Parameter_3__c,Requesting_Url__c,Serialized_Record__c,Retry_Schedule_URL__c, Gateway_Name__c FROM Payment_Log__c WHERE Id=:logId WITH SECURITY_ENFORCED Limit 1];
            rpToUpdate = [SELECT Id, Name, Q_Charge__Amount__c, Q_Charge__Card_Expiry_Date__c, Q_Charge__Next_Installment_Date__c, Q_Charge__Gateway_Name__c, Q_Charge__Installment_Period__c FROM Q_Charge__Recurring_Payment__c WHERE Id =:  ref_log.Processing_Record_Id__c WITH SECURITY_ENFORCED Order by createddate desc limit 1 ];
            rpName = (rpToUpdate.size()>0) ? rpToUpdate[0].Name : '';
            installperiod = (rpToUpdate.size()>0) ? rpToUpdate[0].Q_Charge__Installment_Period__c : '';
            nextPayDate = (rpToUpdate.size()>0) ? UTILGateway.convertDatetoString(rpToUpdate[0].Q_Charge__Next_Installment_Date__c) : '' ;
           // amount = (rpToUpdate.size()>0) ? rpToUpdate[0].Q_Charge__Amount__c.format() : '' ;
           showAmount = (rpToUpdate.size()>0) ? (rpToUpdate[0].Q_Charge__Amount__c.format().contains('.')?rpToUpdate[0].Q_Charge__Amount__c.format():rpToUpdate[0].Q_Charge__Amount__c.format()+'.00'):'';

            gatewayName = ref_log.Gateway_Name__c;
            switch on gatewayName {
                when  'ezidebit'{
                    if(EzidebitManager.isConnected){                   
                        publicKey=EzidebitManager.EzidebitGateway.Client_Key__c;
                        endPoint=EzidebitManager.EzidebitGateway.isSandbox__c?EzidebitManager.EziDebitSandboxPayment:EzidebitManager.EziDebitProductionPayment;
                        referenceId=ref_log.Transaction_Id__c;
                        recurringId=ref_log.Processing_Record_Id__c;
                        if(ref_log.Requesting_Url__c!=null){
                            refreshPage=ref_log.Requesting_Url__c;
                        }else{
                            refreshPage=URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+recurringId;
                        }
                    }else{
                        renderMessage=MessageHandler.apiKeyMissing;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,renderMessage));
                    }
                }
                when 'nab_transact' {
                    if(NABTransactManager.isConnected == false){
                        renderMessage = MessageHandler.apiKeyMissing;
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,renderMessage));
                    }
                    else{
                        Gateway_Detail__c Gateway = UTILGateway.decodeKeys(UTILGateway.NABTRANSWORD);
                        endPoint = ref_log.Retry_Schedule_URL__c;
                        GMTtimestamp = DateTime.now().formatGMT('yyyyMMddHHmmss');
                        merchantId = Gateway.Client_Id__c;          
                        transactionPassword = Gateway.Client_Key__c;  
                        redirect = TRUE;
                        resultParams = TRUE;
                        tokenStore = TRUE;
                        tokenStoreType = 'TOKEN';
                        transactionType = 8; 
                        paymentReference = logId;
                        expiryYear = UTILGateway.expiryYearGenerator();
                        monthsOfYear = UTILGateway.monthsGenerator();
                        String combineString = merchantId+'|'+transactionPassword+'|'+transactionType+'|'+tokenStoreType+'|'+logId+'|'+GMTtimestamp;
                        hmacData = Crypto.generateMac('HMACSHA256', Blob.valueOf(combineString), Blob.valueOf(transactionPassword));
                        fingerprintValue = EncodingUtil.convertToHex(hmacData);
                        resultURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__PostUpdateCardDetails?reference='+paymentReference;
                    }
                }
                when 'stripe' {
                    if(ApexPages.currentPage().getParameters().get('requestedURL') != null){
                        refreshPage = EncodingUtil.urlDecode(ApexPages.currentPage().getParameters().get('requestedURL'),'UTF-8').escapeHtml4();
                    }else {
                        refreshPage = URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+record_id; 
                    } 
                }
                when 'payway' {
                    if(PaywayManager.isConnected == false){
                        renderMessage =  MessageHandler.apiKeyMissing;
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,renderMessage));
                    } else{
                        merchanID = PaywayManager.paywaygateway.Optional_Key_1__c;
                        publishableKey = PaywayManager.paywaygateway.Client_Id__c;
                        gatewayName = ref_log.Gateway_Name__c;
                        customerNumber = UTILGateway.decodeCustomerKeys(ref_log.Transaction_Id__c);
                        recurringId=ref_log.Processing_Record_Id__c;
                        
                        if(ref_log.Requesting_Url__c!=null){
                            refreshPage=ref_log.Requesting_Url__c;
                        } else{
                            refreshPage=URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+recurringId;
                        }
                    }
                }
                when 'bpoint' {
                    // add logic here
                }
                when 'simplify' {
                    if(SimplifyManager.isConnected){
                        hostedpayments_publicKey=SimplifyManager.SimplifyGateway.HostedPayments_PublicKey__c;
                        amount='100';
                        if(ref_log.Requesting_Url__c!=null){
                            refreshPage=ref_log.Requesting_Url__c;
                        }else{
                            refreshPage=URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+recurringId;
                        }
                    }else{
                        errorMessage=SimplifyManager.detachedReason	;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }
                    
                }
            }
        }catch(Exception ex){
            renderMessage=MessageHandler.urlEdit;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,renderMessage));
        }   
    }
    
    /********Method to update the recurring payment*********/
    public void updateRecurringPayment(){
        RecurringWrapper wrapper=new RecurringWrapper();
        wrapper.logrefId=logId;
        wrapper.recurringRequestId=ref_log.Transaction_Id__c;
        wrapper.requestUrl=ref_log.Requesting_Url__c;
        wrapper.sfProcessingId=ref_log.Processing_Record_Id__c;
        try{
            Id recurringId=wrapper.sfProcessingId;
            Recurring_Payment__c rp = [Select Card_Last_Updated_On__c,Card_Name__c,Card_Expiry_Date__c,RelatedToId__c,Card_Number__c,Amount__c from Recurring_Payment__c where Id=:recurringId WITH SECURITY_ENFORCED LIMIT 1];
            wrapper.amount=rp.Amount__c;
            Id contactId=rp.RelatedToId__c;
            Contact contactInfo=[Select FirstName,LastName from Contact where Id=:contactId WITH SECURITY_ENFORCED Limit 1];
            wrapper.name=contactInfo.FirstName+' '+contactInfo.LastName;
            if(returnMsg=='Success'){
                wrapper=EzidebitHelper.UpdateCardDetailsHelper(wrapper);
                if(!wrapper.status){
                    List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                    Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
                    result='/apex/Q_Charge__GatewayReceiptPage?reference='+log.Id;
                }else{
                    if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isUpdateable() && 
                    Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isUpdateable()){
                        rp.Card_Last_Updated_On__c=Datetime.now();
                        rp.Card_Name__c=wrapper.cardDetails.CardHolderName;
                        rp.Card_Number__c=wrapper.cardDetails.CardNumber;
                        rp.Card_Expiry_Date__c = ((wrapper.cardDetails.ExpiryMonth != null) && (wrapper.cardDetails.ExpiryYear != null)) ? Date.newinstance(Integer.valueOf(wrapper.cardDetails.ExpiryYear), Integer.valueOf(wrapper.cardDetails.ExpiryMonth), Date.daysInMonth(Integer.valueOf(wrapper.cardDetails.ExpiryYear), Integer.valueOf(wrapper.cardDetails.ExpiryMonth))): null;
                        UTILGateway.allowRPUpdate = true;
                        update rp;
                        result=MessageHandler.creditCardUpdatSuccesse + UTILGateway.EZIDEBITWORD.capitalize()+'.';
                    }
                    
                }
            }else{
                wrapper=EzidebitHelper.retryUpdateCardDetails(wrapper);
                List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
                result='/apex/Q_Charge__GatewayReceiptPage?reference='+log.Id;
                
            }
        }catch(DmlException dex){
            result=dex.getMessage();
            EmailHandler.sendExceptionEmail('UpdateCreditCardController', dex, false);
        }catch(Exception ex){
            result=ex.getMessage();
            EmailHandler.sendExceptionEmail('UpdateCreditCardController', ex, false);
            
        }
    }
    
    /**************************************** Update Card details mehod for Payway*********************************************/
    public void updatePaywayCard()
    {
        String updatePayload = '';
        updatePayload = 'merchantId='+EncodingUtil.urlEncode(merchanID, 'UTF-8');
        updatePayload += singleUseTokenId != null ? '&singleUseTokenId='+EncodingUtil.urlEncode(singleUseTokenId, 'UTF-8') : '';
        
        RecurringWrapper updateCardWrap = new RecurringWrapper();
        updateCardWrap.transactionPayload = updatePayload;
        updateCardWrap.sfProcessingId = recurringId;
        updateCardWrap.recurringRequestId = ref_log.Transaction_Id__c;
        updateCardWrap.logrefId = logId;
        updateCardWrap.customerNumber = customerNumber;
        updateCardWrap.requestUrl = (ref_log.Requesting_Url__c != null) ? ref_log.Requesting_Url__c : URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+recurringId;
        
        result = PaywayHelper.updatePaywayCardDetails(updateCardWrap);
    }
    
    public void updateSimplifyCreditCard(){
        RecurringWrapper wrapper=new RecurringWrapper();
        wrapper.transactionreference=logId;
        wrapper.sfProcessingId=ref_log.Processing_Record_Id__c;
        wrapper.recurringRequestId=ref_log.Transaction_Id__c;
        wrapper.tokenValue=UTILGateway.encodeCustomerKeys(responseToken);
        try{
            wrapper=SimplifyHelper.updateCardDetails(wrapper);
            if(wrapper.responseMessage=='Payment Rejected'){
                List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
                result='/apex/Q_Charge__GatewayReceiptPage?reference='+log.Id;
            }else{
                
                result = MessageHandler.creditCardUpdatSuccesse + UTILGateway.SIMPLIFYWORD.capitalize()+'.';
            }
            List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            
        }catch(UTILPermission.PermsException pex){
            result=pex.getMessage();
            EmailHandler.sendExceptionEmail('updateSimplifyCreditCard', pex, false);
        }catch(DmlException dex){
            result=dex.getMessage();
            EmailHandler.sendExceptionEmail('updateSimplifyCreditCard', dex, false);
        }catch(Exception ex){
            result=ex.getMessage();
            EmailHandler.sendExceptionEmail('updateSimplifyCreditCard', ex, false);
        }
    }
    
    //method for updating stripe card details
    public void updateStripeCard(){
        
        try{ 
            if(ref_log.Payment_Parameter_1__c != null)
            {                      
                result = StripeManager.ProcessUpdateCard(ref_log);
                if(result.startsWith('succeeded:')){
                    StripePaymentMethodwrapper defaultPayment = (StripePaymentMethodwrapper)JSON.deserialize(result.substringAfter('succeeded:'), StripePaymentMethodwrapper.Class);
                    Recurring_Payment__c recurr = (Recurring_Payment__c)JSON.deserialize(ref_log.Serialized_Record__c, Sobject.class);
                    recurr = StripeHelper.MappingRecurringPaymentIntent(defaultPayment, recurr, 'Update');
                    if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                    	update recurr;
                    }
                    ChargeStatus = 'Approved';
                    result  = MessageHandler.creditCardUpdatSuccesse + UTILGateway.STRIPEWORD.capitalize()+'.'; 
                }else{                        
                    ChargeStatus = 'Declined';                        
                }
                
            } else {
                result = MessageHandler.noTransactionInitated; 
            }
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
        }catch(Exception ex){
            result = ex.getMessage();
            EmailHandler.sendExceptionEmail('StripePostCheckoutController',ex,null);
        }
    }
}