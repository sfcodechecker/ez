public with sharing class PaywayCheckoutController {
    
    //declaring variable
    public String publishableKey {get;set;}
    public String contactID {get;set;} 
    public string paymentlogId {get; set;} 
    public String email {get; set;}
    public string phone {get;set;}
    public string name {get; set;}
    public string transactionType {get; set;}
    public String buttonname {get; set;}
    public string singleUseTokenId {get; set;}
    public string recieptLogID {get;set;}
    public String paymentAmount {get; set;}
    public String paymentDate {get; set;}
    public String frequency{get; set;}
    public String displayFrequency{get;set;}
    public String showAmount {get;set;}
    
    public Contact payeeDetails;
    public Date paymentstartDate;
    public String customerNumber;
    public String regularPaymentAmount;
    public Gateway_Detail__c gatewayinfo;
    public List<Payment_Log__c> urlinfoLog;
    List<Payment_Log__c> paymentLogList; 
    public String customerName;
    public String nextInstallmentDate;
    public String customerReference;
    public static string renderMessage{get; set;}
    
    public PaywayCheckoutController()
    {
        try{
            paymentLogList = new List<Payment_Log__c>();
            paymentlogId = ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            
            if(PaywayManager.isConnected == false){
                renderMessage = MessageHandler.apiKeyMissing;
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, MessageHandler.apiKeyMissing));
            }else{
                gatewayinfo = PaywayManager.paywaygateway;
                publishableKey = PaywayManager.paywaygateway.Client_Id__c;
            }
            
            urlinfoLog =[Select id, Processing_Record_Id__c,Amount__c,Charge_Type__c,Serialized_Record__c,Q_Charge__Payment_Parameter_1__c,Frequency__c,Recurring_Start_Date__c from Payment_Log__c where Id=:paymentlogId WITH SECURITY_ENFORCED Limit 1];
            if(urlinfoLog.size() > 0){                
                //check for transaction type  
                if(urlinfoLog[0].Charge_Type__c == '' || urlinfoLog[0].Charge_Type__c == null){
                    renderMessage = MessageHandler.chargeTypeMissing;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
                    
                }else if(urlinfoLog[0].Amount__c < 0.01 || urlinfoLog[0].Amount__c > 10000){
                    renderMessage = (urlinfoLog[0].Amount__c < 0.01) ? MessageHandler.amountLessThan1Cent : MessageHandler.amountMoreThanLimit;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
                }
                else if( urlinfoLog[0].Amount__c == null){
                    renderMessage = MessageHandler.reqFieldAmount;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
                }
                else if(urlinfoLog[0].Charge_Type__c == UTILGateway.RECURRINGKEYWORD && (urlinfoLog[0].Frequency__c == null || urlinfoLog[0].Frequency__c == '')){
                    renderMessage = MessageHandler.frequencyMissing;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
                }
                else if(urlinfoLog[0].Charge_Type__c == UTILGateway.RECURRINGKEYWORD && (urlinfoLog[0].Recurring_Start_Date__c == null)){
                    renderMessage = MessageHandler.startDateMissing;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
                }
                
                else if(urlinfoLog[0].Processing_Record_Id__c == null || urlinfoLog[0].Processing_Record_Id__c == ''){
                    renderMessage = MessageHandler.missingRecordID;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
                }else{
                    customerNumber = (urlinfoLog[0].Q_Charge__Payment_Parameter_1__c != null && urlinfoLog[0].Q_Charge__Payment_Parameter_1__c != '') ? urlinfoLog[0].Q_Charge__Payment_Parameter_1__c : '';
                    paymentAmount = String.valueof(urlinfoLog[0].Amount__c);
                    showAmount = urlinfoLog[0].Amount__c.format().contains('.')?urlinfoLog[0].Amount__c.format():urlinfoLog[0].Amount__c.format()+'.00';
                    transactionType = urlinfoLog[0].Charge_Type__c;
                    
                    if(urlinfoLog[0].Charge_Type__c == UTILGateway.RECURRINGKEYWORD){
                        paymentstartDate = urlinfoLog[0].Recurring_Start_Date__c;
                        displayFrequency = urlinfoLog[0].Frequency__c;
                        frequency = urlinfoLog[0].Frequency__c=='Half Yearly'?'six-monthly':urlinfoLog[0].Frequency__c;             //changed KW
                        paymentDate = UTILGateway.convertDatetoString(urlinfoLog[0].Recurring_Start_Date__c);
                    }
                    
                    buttonname = (urlinfoLog[0].Charge_Type__c == UTILGateway.ONETIMEKEYWORD) ? 'Charge' :  'Subscribe';
                    contactID = urlinfoLog[0].Processing_Record_Id__c;
                    payeeDetails = [select id,firstName,LastName,Email,Phone from contact where Id=:contactID WITH SECURITY_ENFORCED Limit 1];
                    email = PayeeDetails.Email;
                    phone = PayeeDetails.Phone;
                    name = ((payeeDetails.FirstName != null)) ? payeeDetails.FirstName+' '+payeeDetails.LastName : payeeDetails.LastName;
                }
            } else{
                renderMessage = (paymentlogId != null && paymentlogId != '') ? MessageHandler.incorrectLogId : MessageHandler.missingLogId;
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, renderMessage));
            }
        } catch(Exception exc){
            renderMessage = exc.getMessage() +'. '+exc.getStackTraceString();
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, MessageHandler.wentWrongCatchMessage));
            EmailHandler.sendExceptionEmail('PaywayCheckoutController',exc,null);
        }
    }
    
    
    public void createTransaction(){
        if(transactionType == UTILGateway.ONETIMEKEYWORD){
            oneOffTransaction();
        }
        if(transactionType == UTILGateway.RECURRINGKEYWORD){
            if((customerNumber == null || customerNumber == '') && singleUseTokenId != null){
                createNewSchedule();
            }else{
                retrySchedule(customerNumber);
            }
        } 
    }
    
    public void oneOffTransaction(){
        
        try{
            /*****************************  Creating customer reference number  ****************************/
            String tenDigitID = contactID.substring(8,17);
            customerReference = (payeeDetails.LastName + tenDigitID).replaceAll(' ', '_');
            //performing Transaction request
            TransactionWrapper oneoffReq = new TransactionWrapper();
            oneoffReq.sfProcessingId = contactID;
            oneoffReq.merchantId =  gatewayinfo.Optional_Key_1__c;
            oneoffReq.tokenValue = singleUseTokenId; 
            oneoffReq.pcurrency = 'aud';
            oneoffReq.amount = Decimal.valueof(paymentAmount);
            oneoffReq.transactionType = 'payment';
            oneoffReq.customerNumber = (customerReference.length() > 20) ? customerReference.substring(20) : customerReference;
            oneoffReq.actiontype = MessageHandler.processPayment(UTILGateway.PAYWAYWORD.capitalize(), UTILGateway.ONETIMEKEYWORD) ;
            oneoffReq.transactionPayload = PaywayHelper.createOneTimePayLoad(oneoffReq);
            oneoffReq.encodedCustomerNumber = UTILGateway.encodeCustomerKeys(customerReference);
            oneoffReq.transactionreference = paymentlogId;
            //Log for Post checkout page.
            String onetimeTransactionWrapper = JSON.serialize(oneoffReq);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD, Processing_Record_Id__c = contactID,Action__c = UTILGateway.PAYWAYWORD +''+MessageHandler.requestPostCheckout, Request_Type__c = 'POST', Amount__c = Decimal.valueof(paymentAmount), Charge_Type__c = UTILGateway.ONETIMEKEYWORD, End_Point__c = '/apex/Q_Charge__GatewayPostCheckout?reference=',Serialized_Record__c = onetimeTransactionWrapper)));
            paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
            recieptLogID = newLog.Id;
            
        }catch(Exception exc){
            renderMessage = exc.getMessage() +'. '+exc.getStackTraceString();
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, MessageHandler.wentWrongCatchMessage));
            EmailHandler.sendExceptionEmail('PaywayCheckoutController',exc,null);
        }
    }
    
    /*********************** Method for creating schedule. ********************************/ 
    public void createNewSchedule(){
        try{
            //Assigning values to wrapper for creating customer and their schedule.
            RecurringWrapper recurringReq = new RecurringWrapper();
            recurringReq.amount = decimal.valueof(paymentAmount);
            recurringReq.merchantId =  gatewayinfo.Optional_Key_1__c;
            recurringReq.tokenValue = singleUseTokenId;
            recurringReq.instalPeriod = frequency;
            recurringReq.nextPaymentDate = paymentDate;
            recurringReq.name = name;
            //creating transaction request payload.
            recurringReq.transactionPayload = PaywayHelper.createReccurringPayLoad(recurringReq);
            recurringReq.startDate = paymentstartDate;
            recurringReq.transactionreference = paymentlogId;
            recurringReq.sfProcessingId = contactID;
            //Log for reciept page.
            String recurringRequest = JSON.serialize(recurringReq);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c( Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD, Processing_Record_Id__c = contactID,Action__c = UTILGateway.PAYWAYWORD +''+MessageHandler.requestPostCheckout, Request_Type__c = 'POST', Amount__c = Decimal.valueof(paymentAmount), Charge_Type__c = UTILGateway.RECURRINGKEYWORD, End_Point__c = '/apex/Q_Charge__GatewayPostCheckout?reference=',Serialized_Record__c = recurringRequest)));
            paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
            recieptLogID = newLog.Id;
            
        } catch(Exception exc){
            renderMessage = exc.getMessage() +'. '+exc.getStackTraceString();
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, MessageHandler.wentWrongCatchMessage));
            EmailHandler.sendExceptionEmail('PaywayCheckoutController',exc,null);
        }
    }
    
    /*********************** method for retry the schedule with same custmer number ********************************/
    public void retrySchedule(String customerNumber){
        try{
            
            RecurringWrapper recurringReq = new RecurringWrapper();
            recurringReq.amount = decimal.valueof(paymentAmount);
            recurringReq.instalPeriod = frequency;
            recurringReq.nextPaymentDate = paymentDate;
            //creating paylod to schedule retry request.
            recurringReq.transactionPayload = PaywayHelper.createReccurringPayLoad(recurringReq);
            recurringReq.sfProcessingId = contactID;
            recurringReq.merchantId = gatewayinfo.Optional_Key_1__c;
            recurringReq.customerNumber = customerNumber;
            recurringReq.tokenValue = singleUseTokenId;
            recurringReq.startDate = paymentstartDate;
            
            //assigning retry log information for reciept page redirect.
            String recurringRequest = JSON.serialize(recurringReq);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD, Processing_Record_Id__c = contactID, Action__c =  UTILGateway.PAYWAYWORD +''+MessageHandler.requestPostCheckout, Request_Type__c = 'POST', Amount__c = Decimal.valueof(paymentAmount), Charge_Type__c = UTILGateway.RECURRINGKEYWORD, End_Point__c = '/apex/Q_Charge__GatewayPostCheckout?reference=',Serialized_Record__c = recurringRequest)));
            paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
            recieptLogID = newLog.Id;
            
        } catch(Exception exc){
            renderMessage = exc.getMessage() +'. '+exc.getStackTraceString();
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, MessageHandler.wentWrongCatchMessage));
            EmailHandler.sendExceptionEmail('PaywayCheckoutController',exc,null);
        }
    }
}