public with sharing class SimplifyCheckOutController 
{
    /*********************** variables ********************************/
    public String hostedpayments_publicKey{get;set;}
    public String recordId{get;set;}
    public String amount{get;set;}
    public String endpoint{get;set;}
    public String finalamount{get;set;}
    public String logrefId{get;set;}
    public Payment_Log__c ref_log{get;set;}
    public String operation{get;set;}
    public String responseToken{get;set;}
    public String redirectUrl{get;set;}
    public String chargeType{get;set;}
    public String errorMessage{get;set;}

    //changes added by VS
    public Contact payeeDetails;
    public String email {get; set;}
    public string phone {get;set;}
    public string name {get; set;}

    public String paymentAmount {get; set;}
    public String paymentDate {get; set;}
    public String frequency{get; set;}
    
    /*********************** Passing values to vf page ********************************/
    public SimplifyCheckOutController() {
        try{
            
            logrefId=ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            ref_log=[Select Processing_Record_Id__c,Amount__c,Charge_Type__c,Serialized_Record__c,Frequency__c,Recurring_Start_Date__c,Requesting_Url__c from Payment_Log__c where Id=:logrefId WITH SECURITY_ENFORCED Limit 1];
            if(SimplifyManager.isConnected){
                hostedpayments_publicKey=SimplifyManager.SimplifyGateway.HostedPayments_PublicKey__c;
                endpoint=SimplifyManager.HostedPage_Endpoint;
                
                chargeType=ref_log.Charge_Type__c;
                if(chargeType==UTILGateway.ONETIMEKEYWORD){
                    if(ref_log.Amount__c<1){
                        errorMessage=MessageHandler.amountBelowOneDoller;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }else if(ref_log.Amount__c>500000){
                        errorMessage=MessageHandler.amountMoreThanLimit;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }
                }else if(chargeType==UTILGateway.RECURRINGKEYWORD){
                    if(ref_log.Amount__c<0.5){
                        errorMessage=MessageHandler.amountLessThan50Cent;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }else if(ref_log.Recurring_Start_Date__c<Date.today()){
                        errorMessage=MessageHandler.prevStartDate;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }else if(ref_log.Amount__c>10000){
                        errorMessage=MessageHandler.amountMoreThanLimit;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
                    }
                }
                
                recordId=ref_log.Processing_Record_Id__c;
                payeeDetails = [select id,firstName,LastName,Email,Phone from contact where Id=:recordId WITH SECURITY_ENFORCED Limit 1];
                email = PayeeDetails.Email;
                phone = PayeeDetails.Phone;
                name = (payeeDetails.FirstName != null) ? payeeDetails.FirstName+' '+payeeDetails.LastName : payeeDetails.LastName;

                paymentDate = (ref_log.Recurring_Start_Date__c != null) ?  UTILGateway.convertDatetoString(ref_log.Recurring_Start_Date__c) : null;
                frequency = ref_log.Frequency__c;
                paymentAmount = ref_log.Amount__c.format().contains('.')?ref_log.Amount__c.format():ref_log.Amount__c.format()+'.00';

                amount=String.valueOf(ref_log.Amount__c*100);
                if(chargeType==UTILGateway.ONETIMEKEYWORD){
                    operation='create.payment';
                }else if(chargeType==UTILGateway.RECURRINGKEYWORD){
                    operation='create.token';
                }
                
            }else{
                errorMessage=MessageHandler.apiKeyMissing;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
            } 
            
        }catch(Exception ex){
            System.debug('Stack trace '+ex.getStackTraceString()+' Message '+ex.getMessage()+' Line no. '+ex.getLineNumber());
            errorMessage=ex.getMessage();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));
        }
        
    }
    
    public void completeCheckout(){
        if(ref_log.Charge_Type__c==UTILGateway.ONETIMEKEYWORD){
            TransactionWrapper transWrapper=(TransactionWrapper)JSON.deserialize(ref_log.Serialized_Record__c, TransactionWrapper.class);
            TransactionWrapper wrapper=(TransactionWrapper)JSON.deserialize(responseToken, TransactionWrapper.class);
            transWrapper.transactionId=wrapper.transactionId;
            transWrapper.transactionStatus=wrapper.transactionStatus;
            transWrapper.transactionDateTime=wrapper.transactionDateTime;
            transWrapper.transResponse=responseToken;
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=ref_log.Processing_Record_Id__c,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.storingResponse,Amount__c=ref_log.Amount__c,Frequency__c=ref_log.Frequency__c,Recurring_Start_Date__c=ref_log.Recurring_Start_Date__c,Gateway_Name__c=UTILGateway.SIMPLIFYWORD,Charge_Type__c=UtilGateway.ONETIMEKEYWORD,Serialized_Record__c=JSON.serialize(transWrapper))));
            
        }       
        else if(ref_log.Charge_Type__c==UTILGateway.RECURRINGKEYWORD){
            String token=UTILGateway.encodeCustomerKeys(responseToken);
            RecurringWrapper reccWrapper=(RecurringWrapper)JSON.deserialize(ref_log.Serialized_Record__c, RecurringWrapper.class);
            reccWrapper.amount=ref_log.Amount__c*100;
            reccWrapper.logrefId=logrefId;
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=ref_log.Processing_Record_Id__c,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.storingResponse,Payment_Parameter_1__c=token,Amount__c=ref_log.Amount__c,Frequency__c=ref_log.Frequency__c,Recurring_Start_Date__c=ref_log.Recurring_Start_Date__c,Gateway_Name__c=UTILGateway.SIMPLIFYWORD,Charge_Type__c=UtilGateway.RECURRINGKEYWORD,Serialized_Record__c=JSON.serialize(reccWrapper))));
        } 
        
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
        redirectUrl='/apex/GatewayPostCheckout?reference='+newLog.Id;   
    }
}