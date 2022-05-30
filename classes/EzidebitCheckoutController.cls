public with sharing class EzidebitCheckoutController {
    
    public EzidebitCheckoutWrapper checkoutWrapper{get;set;}
    public String publicKey{get;set;}
    public String errorMessage{get;set;}
    public String endPoint{get;set;}
    public String recordId{get;set;}
    public String logId{get;set;}
    public String amount{get;set;}
    public String chargeType{get;set;}
    public String rdDate{get;set;}
    public String frequency{get;set;}
    public String duration{get;set;}
    public String preferenceId{get;set;}
    public Contact contactInfo{get;set;}
    public String phone{get;set;}
    public String hostedPageUrl{get;set;}
    public String callbackUrl{get;set;}
    public String orgName{get;set;}
    public String jsonData{get;set;}
    public String ref_Id{get;set;}
    public Payment_Log__c ref_log{get;set;}
    
    
    public String email {get; set;}
    public string name {get; set;}
    public string showAmount {get;set;}
    
    public EzidebitCheckoutController() {
        try{
            ref_Id=ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            if(ref_Id.length()==31)
            {
                logId=ref_Id.substring(0, 18);           
            }else{
                logId=ref_Id;
            }
            ref_log=[Select Processing_Record_Id__c,Amount__c,Charge_Type__c,Serialized_Record__c,Frequency__c,Recurring_Start_Date__c,Requesting_Url__c from Payment_Log__c where Id=:logId WITH SECURITY_ENFORCED Limit 1];
            orgName=UserInfo.getOrganizationName();
            
            if(EzidebitManager.detachedReason==null){
                recordId=ref_log.Processing_Record_Id__c;
                amount=String.valueOf(ref_log.Amount__c);
                showAmount = ref_log.Amount__c.format().contains('.')?ref_log.Amount__c.format():ref_log.Amount__c.format()+'.00';
                if(recordId!='null'){
                    contactInfo=[Select FirstName,LastName,Email,MobilePhone,MailingPostalCode,MailingState,MailingStreet,MailingCountry from Contact where Id = :recordId  WITH SECURITY_ENFORCED Limit 1];             
                    email = contactInfo.Email;
                    name = (contactInfo.FirstName != null) ? contactInfo.FirstName+' '+contactInfo.LastName : contactInfo.LastName;
                }
                chargeType=ref_log.Charge_Type__c;
                if(chargeType==UTILGateway.ONETIMEKEYWORD){
                    publicKey=EzidebitManager.EzidebitGateway.Client_Id__c;
                    endPoint=(EzidebitManager.EzidebitGateway.isSandbox__c)?EzidebitManager.EziDebitSandboxPayment:EzidebitManager.EziDebitProductionPayment;
                }
                else if(chargeType==UTILGateway.RECURRINGKEYWORD){ 
                    hostedPageUrl=EzidebitManager.EzidebitGateway.Schedule_Page_URL__c+'a='+EzidebitManager.EzidebitGateway.Client_Id__c+'&debits=4';
                    if(hostedPageUrl==null || hostedPageUrl.trim().length()<=1){
                        errorMessage=MessageHandler.ezidebitEddr;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }   
                    
                    
                    rdDate=String.valueOf(ref_log.Recurring_Start_Date__c);
                    frequency=EzidebitManager.handleFrequencies(ref_log.Frequency__c,false);
                    duration='1';
                    preferenceId=ref_Id;
                    callbackUrl=EzidebitHelper.getPostCheckoutUrl(ref_Id);
                    
                    if(rdDate=='null' || rdDate.length()==0){
                        errorMessage=MessageHandler.invalidParams;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }
                    else if(Date.valueOf(rdDate)< Date.today()){
                        errorMessage=MessageHandler.prevStartDate;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }
                    else if(Date.valueOf(rdDate)==Date.today()){
                        Datetime currentDT=Datetime.now();
                        String convertedDT=currentDT.format('yyyy-MM-dd HH:mm:ss a', 'Australia/Brisbane');
                        convertedDT=convertedDT.substringAfter(' ');
                        List<String> splitConvertedDT=convertedDT.split(':');
                        Integer currentTime=Integer.valueOf(splitConvertedDT.get(0));
                        Integer currentTimeMinutes=Integer.valueOf(splitConvertedDT.get(1));
                        if(currentTime>=15){
                            errorMessage=MessageHandler.ezidebitprocessingTimeProduction;
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                        }
                    }   
                }
                if(Decimal.valueOf(amount)<1){
                    errorMessage=MessageHandler.amountBelowOneDoller;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                }
                if(Decimal.valueOf(amount)>10000){
                    errorMessage=MessageHandler.amountMoreThanLimit;       
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));            
                }
            }else{
                errorMessage=MessageHandler.apiKeyMissing;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
            }
        }catch(UTILPermission.PermsException pe){
            errorMessage=pe.getMessage();       
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Checkout cannot be performed.'+errorMessage));
            
        }catch(Exception ex){
            errorMessage=ex.getMessage();       
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Checkout cannot be performed.'+errorMessage));
        }
        
    }
    
    public void createPaymentLog(){
        String dummy=jsonData;
        jsonData=jsonData.replaceAll('"', '');
        try{
            checkoutWrapper=(EzidebitCheckoutWrapper)JSON.deserialize(dummy, EzidebitCheckoutWrapper.class);
            TransactionWrapper wrapper = new TransactionWrapper();
            wrapper.transactionReference=checkoutWrapper.BankReceiptID;
            wrapper.transactionId=checkoutWrapper.ExchangePaymentID;
            wrapper.transactionResponseCode=checkoutWrapper.PaymentResultCode;
            wrapper.transactionStatus=checkoutWrapper.PaymentResultText;
            wrapper.transactionType=UTILGateway.ONETIMEKEYWORD;
            wrapper.sfProcessingId=recordId;
            wrapper.amount=Decimal.valueOf(amount);
            wrapper.transactionDate=Date.today();
            wrapper.successURL=endpoint;
            wrapper.logrefId=logId;
            wrapper.requestUrl=ref_log.Requesting_Url__c;
            String serializedWrapper=JSON.serialize(wrapper);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UtilGateway.EZIDEBITWORD, Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize()+''+MessageHandler.storingResponse,Http_Response__c=JSON.serialize(wrapper),Request_Type__c='POST',Amount__c=wrapper.amount,Charge_Type__c=wrapper.transactionType,Serialized_Record__c=serializedWrapper,Requesting_Url__c=wrapper.requestUrl)));
            List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
            callbackUrl=EzidebitHelper.getPostCheckoutUrl(newLog.Id);
        }catch(Exception ex){
            errorMessage=ex.getMessage();       
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Checkout cannot be performed.'+errorMessage));
            EmailHandler.sendExceptionEmail('EzidebitCheckoutController', ex, false);
        }
    }
    
}