public with sharing class PaywayHelper 
{
    public static String paywayCheck = null;
    public static Gateway_Detail__c paywaygateway;
    
    /******static****/
    static {
        if([Select Id  from Gateway_Detail__c where Name__c = :UTILGateway.PAYWAYWORD WITH SECURITY_ENFORCED].size() == 1){
            paywaygateway = UTILGateway.decodeKeys(UTILGateway.PAYWAYWORD);
        }else {
            paywayCheck = MessageHandler.apiKeyMissing;
        }
    }
    
    /*********************** creating Url for Recurring hosted Page ********************************/
    public static String requestPaymentURL(RecurringWrapper urlInfo){
        Date dateMaxLimit = Date.today().addYears(1);
        Date prevWeekLimit = Date.today().addDays(-6);
        Date prevMonthLimit = Date.today().addMonths(-1);
        Date prevFortnightLimit = Date.today().addDays(-13);
        
        String recurrngdetailspage='';
        try{
            if(urlInfo.amount == null){
                recurrngdetailspage = MessageHandler.reqFieldAmount;
                return recurrngdetailspage;
            }
            else if(urlInfo.amount.scale() > 2){
                recurrngdetailspage = MessageHandler.amountDecimalLimit ;
                return recurrngdetailspage;
            }
            else if(urlInfo.amount < 0.01) {
                recurrngdetailspage = MessageHandler.amountLessThan1Cent;
                return recurrngdetailspage;
            }
            else if(urlInfo.amount > 10000){
                recurrngdetailspage = MessageHandler.amountMoreThanLimit;
                return recurrngdetailspage;
            }
            else if(urlInfo.sfProcessingId == null || urlInfo.sfProcessingId == ''){
                recurrngdetailspage = MessageHandler.missingRecordID;
                return recurrngdetailspage;
            }
            if(urlInfo.startDate != null && urlInfo.startDate >= dateMaxLimit){
                recurrngdetailspage = MessageHandler.startDateMorethan1Year;
                return recurrngdetailspage;
            }
            else if(urlInfo.startDate != null && urlInfo.startDate < prevWeekLimit && urlInfo.instalPeriod == 'Weekly'){
                recurrngdetailspage = MessageHandler.startDatelessthan6days;
                return recurrngdetailspage;
            }
            else if(urlInfo.startDate != null && urlInfo.startDate < PrevFortnightLimit && urlInfo.instalPeriod == 'Fortnightly'){
                recurrngdetailspage = MessageHandler.startDatelessthan13days;
                return recurrngdetailspage;
            }
            else if(urlInfo.startDate != null && urlInfo.startDate < PrevMonthLimit){
                recurrngdetailspage = MessageHandler.startDatelessthan1month;
                return recurrngdetailspage;
            }
            else{
                return '/apex/Q_Charge__PaywayCheckout?reference=';
            }
        }
        catch(Exception ex){
            recurrngdetailspage = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('PaywayHelper', ex, false);
            return recurrngdetailspage;
        } 
    }
    
    
    /**********************************Helper Method for processing OneTime Payment *************************************/
    Public Static PaywayTransactionResponseWrapper procesOneTimePayment(TransactionWrapper onetimeWrapper)
    {
        PaywayTransactionResponseWrapper oneOffresponsewrapper  = new PaywayTransactionResponseWrapper();
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.amount = onetimeWrapper.amount;
        receipt.chargeType = UTILGateway.ONETIMEKEYWORD;
        receipt.requestUrl = '/apex/Q_Charge__PaywayCheckout?reference=';
        
        try {
            TransactionWrapper onetimeResponse = PaywayManager.performOneTimePayment(onetimeWrapper); 
            if(onetimeResponse.httpResponseStatus == 'Created' || onetimeResponse.transactionResponseCode == '201'){
                
                oneOffresponsewrapper = (PaywayTransactionResponseWrapper )JSON.deserialize(onetimeResponse.transResponse, PaywayTransactionResponseWrapper.class);
                
                receipt.paymentId = oneOffresponsewrapper.transactionId;
                oneOffresponsewrapper.recordtypeID = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('One_Time').getRecordTypeId();
                
                if(oneOffresponsewrapper.status =='approved'){
                    receipt.paymentStatus = 'Transaction Approved';
                    receipt.paymentResponse = MessageHandler.onetimeSuccess;
                    
                    //if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'upsert')){
                    if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'Create')){
                        Transaction__c transactionData = PaywayHelper.mapTransaction(oneOffresponsewrapper);
                        insert transactionData;
                    } else {
                        throw new UTILPermission.PermsException('Q_Charge__Transaction__c','','Create');
                    }
                }
                if(oneOffresponsewrapper.status == 'pending'){
                    receipt.paymentStatus = 'Transaction Pending';
                    receipt.paymentResponse = MessageHandler.onetimeSuccess;
                    Transaction__c transactionData = PaywayHelper.mapTransaction(oneOffresponsewrapper); 
                    
                    if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'Create')){
                        insert transactionData;
                    } else {
                        throw new UTILPermission.PermsException('Q_Charge__Transaction__c','','Create');
                    } 
                    
                }else if(oneOffresponsewrapper.status == 'declined'){
                    receipt.paymentStatus = 'Transaction Rejected';
                    receipt.paymentResponse = MessageHandler.onetimeFailed + PaywayHelper.getPaymentStatusMessage(oneOffresponsewrapper.responseCode);
                }
            }else if(onetimeResponse.httpResponseStatus == 'Unprocessable Entity' || onetimeResponse.transactionResponseCode == '422'){
                
                oneOffresponsewrapper = (PaywayTransactionResponseWrapper )JSON.deserialize(onetimeResponse.transResponse, PaywayTransactionResponseWrapper.class);
                String errorMessage=MessageHandler.onetimeFailed;
                
                for(Integer i=0; i < oneOffresponsewrapper.data.size(); i++){
                    errorMessage = errorMessage + oneOffresponsewrapper.data[i].message;
                    if(oneOffresponsewrapper.data.size() - 1 > i ){
                        errorMessage +=',';
                    }
                }
                receipt.paymentStatus = 'Transaction Rejected';
                receipt.paymentResponse= errorMessage;
            }else{
                receipt.paymentStatus = 'Transaction Rejected';
                receipt.paymentResponse = onetimeResponse.responseText;
            }
            String serializedWrapper=JSON.serialize(receipt);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.PAYWAYWORD,Retry_Schedule_URL__c = '/apex/Q_Charge__PaywayCheckout?reference='+onetimeWrapper.transactionreference,Processing_Record_Id__c=onetimeWrapper.sfProcessingId,Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.oneTimeCheckoutComplete,Request_Type__c = 'POST',Amount__c = onetimeWrapper.Amount,Charge_Type__c = UTILGateway.ONETIMEKEYWORD ,End_Point__c = '/apex/Q_Charge__PaywayCheckout?reference=',Serialized_Record__c = serializedWrapper)));
            
            List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
            oneOffresponsewrapper.transactionReference = newLog.Id;
            
        } catch(DmlException dex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',dex,null);
        }
        
        return oneOffresponsewrapper;
    }
    
    /*******************************Method for mapping transaction Records ******************************************/
    Public static Transaction__c mapTransaction(PaywayTransactionResponseWrapper transactionInfo)
    {
        Transaction__c transactionData = new Transaction__c();
        if((System.UserInfo.getUserType() == 'Guest' && (UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Create'))
            && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() 
            && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() 
            && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()
            && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable()) 
           ||
           (System.UserInfo.getUserType() != 'Guest' && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Create') && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','update')
            && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() 
            && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() 
            && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()
            && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable()
            && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable() 
            && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable() 
            && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isUpdateable()))
        {
            transactionData.RecordTypeId = transactionInfo.recordtypeID;
            transactionData.Amount__c = transactionInfo.paymentAmount;
            transactionData.Transaction_Date__c = UTILGateway.convertStringtoDateTime(transactionInfo.transactionDateTime);
            transactionData.Gateway_Name__c = UTILGateway.PAYWAYWORD;
            transactionData.Transaction_Status__c = (transactionInfo.status == 'declined') ? 'Failed' : (transactionInfo.status == 'approved') ? 'Paid' : transactionInfo.status;
            transactionData.Transaction_Id__c =(transactionInfo.transactionId != null ) ? String.valueOf(transactionInfo.transactionId) : '';
            if(transactionInfo.recurringID != null && transactionInfo.recurringID != ''){
                transactionData.Recurring_Payment__c = transactionInfo.recurringID;
            }
        }else{
            throw new UTILPermission.PermsException('Transaction__c','RecordTypeId,Amount__c,Transaction_Date__c,Gateway_Name__c,Transaction_Status__c,Transaction_Id__c,Recurring_Payment__c','Create');
        }
        return transactionData; 
    }
    
    /*******************************Method for processing recurring payments******************************************/
    Public Static PaywayRecurringResponseWrapper proessRecurringPayment(RecurringWrapper recurringWrap){
        
        String encodedCustomerNo = '';
        PaywayRecurringResponseWrapper recurringResponse = new PaywayRecurringResponseWrapper();
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.amount = recurringWrap.amount;
        receipt.chargeType = UTILGateway.RECURRINGKEYWORD;
        receipt.requestUrl = '/apex/Q_Charge__PaywayCheckout?reference='; 
        receipt.establishmentDate = recurringWrap.startDate;
        receipt.installPeriod = (recurringWrap.instalPeriod=='six-monthly')?'Half Yearly':recurringWrap.instalPeriod; 
        
        
        RecurringWrapper custRecurringResponse = PaywayManager.performRecurringPayment(recurringWrap);
        //Checking Status of schedule is created or not and if created then insert recurring.
        if(custRecurringResponse.httpResponseStatus == 'Created' || custRecurringResponse.httpResponseStatuscode == 201){
            
            recurringResponse = (PaywayRecurringResponseWrapper)JSON.deserialize(custRecurringResponse.recurringResponse, PaywayRecurringResponseWrapper.class);
            recurringResponse.httpResponseStatus = custRecurringResponse.httpResponseStatus;
            recurringResponse.httpResponseStatusCode = custRecurringResponse.httpResponseStatuscode;
            encodedCustomerNo = UTILGateway.encodeCustomerKeys(recurringResponse.customerNumber);
            
            //calling checkPayment method.
            recurringResponse.relatedtoId = recurringWrap.sfProcessingId;
            recurringResponse.transactionreference = recurringWrap.transactionreference;
            
            //calling method to check payment to validate card. 
            PaywayTransactionResponseWrapper  paymentstatus = PaywayHelper.checkPaymentinPayway(recurringResponse, recurringWrap.startDate);
            
            if(paymentStatus.status == 'approved'){  
                receipt.nextInstallmentDate = UTILGateway.convertStringtoDate(recurringResponse.Schedule.nextPaymentDate);
                receipt.establishmentDate = date.today();
                receipt.paymentResponse = paymentStatus.responseText;
                receipt.paymentStatus = 'Payment Approved';
                
            }else if(paymentStatus.status == 'pending'){
                receipt.nextInstallmentDate = UTILGateway.convertStringtoDate(recurringResponse.Schedule.nextPaymentDate);
                receipt.establishmentDate = date.today();
                receipt.paymentResponse = paymentStatus.responseText;
                receipt.paymentStatus = 'Payment Approved';
                
            }else if(paymentStatus.status == 'declined'){
                receipt.paymentResponse = Messagehandler.recurringFailed +' '+PaywayHelper.getPaymentStatusMessage(paymentStatus.responseCode);
                receipt.paymentStatus = 'Payment Rejected';
                
            }else{
                receipt.paymentResponse = paymentStatus.responseText;
                receipt.paymentStatus = 'Payment Rejected';
            }
            
        } else if( custRecurringResponse.httpResponseStatuscode == 422){
            
            recurringResponse = (PaywayRecurringResponseWrapper)JSON.deserialize(custRecurringResponse.recurringResponse, PaywayRecurringResponseWrapper.class);
            recurringResponse.httpResponseStatus = custRecurringResponse.httpResponseStatus;
            recurringResponse.httpResponseStatusCode = custRecurringResponse.httpResponseStatuscode;
            
            string recurringErrorMessage = MessageHandler.recurringFailed;
            
            for(Integer i=0; i < recurringResponse.data.size(); i++){
                recurringErrorMessage =+ recurringResponse.data[i].fieldName+' : ' + recurringResponse.data[i].message+', ';
            }
            receipt.paymentResponse = recurringErrorMessage;
            receipt.paymentStatus = 'Payment Rejected';
            
        }else{
            recurringResponse.httpResponseStatus = custRecurringResponse.httpResponseStatus;
            recurringResponse.httpResponseStatusCode = custRecurringResponse.httpResponseStatuscode;
            receipt.paymentResponse =  PaywayHelper.getPaymentStatusMessage(String.valueOf(recurringResponse.httpResponseStatusCode));
            receipt.paymentStatus = 'Payment Rejected';
        }
        
        //creating log for redirecting to reciept page.
        String serializedWrapper=JSON.serialize(receipt);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.PAYWAYWORD,Processing_Record_Id__c=recurringWrap.sfProcessingId,Frequency__c = recurringWrap.instalPeriod ,Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.recPayCheckoutComplete, Request_Type__c = 'POST',Recurring_Start_Date__c = recurringWrap.startDate , Amount__c = recurringWrap.amount,Charge_Type__c = UTILGateway.RECURRINGKEYWORD, End_Point__c = '/apex/Q_Charge__PaywayCheckout?reference=', Serialized_Record__c = serializedWrapper, Q_Charge__Payment_Parameter_1__c = encodedCustomerNo)));
        List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
        recurringResponse.transactionreference = newLog.Id;
        return recurringResponse;
    }
    
    
    /*********************** Helper method for retry the schedule ********************************/
    Public Static PaywayRecurringResponseWrapper proessRecurringPaymentRetry(RecurringWrapper retryWrap)
    {
        retryWrap.customerNumber = UTILGateway.decodeCustomerKeys(retryWrap.customerNumber);
        String recurringMessage = ''; 
        
        PaywayRecurringResponseWrapper retryresponsewrapper = new PaywayRecurringResponseWrapper();
        PaywayRecurringResponseWrapper.Schedule scheduleinfo = new PaywayRecurringResponseWrapper.Schedule();
        PaywayRecurringResponseWrapper.PaymentSetup cardInfoSetup = new PaywayRecurringResponseWrapper.PaymentSetup();
        PaywayRecurringResponseWrapper.CreditCard cardInfo = new PaywayRecurringResponseWrapper.CreditCard();
        
        
        ReceiptWrapper receipt=new ReceiptWrapper();
        receipt.amount = retryWrap.amount;
        receipt.chargeType = UTILGateway.RECURRINGKEYWORD;
        receipt.requestUrl = '/apex/Q_Charge__PaywayCheckout?reference='; 
        receipt.establishmentDate = retryWrap.startDate;
        receipt.installPeriod = (retryWrap.instalPeriod=='six-monthly')?'Half Yearly':retryWrap.instalPeriod;
        
        //update Card details
        String updatePayload = 'merchantId='+EncodingUtil.urlEncode(retryWrap.merchantId, 'UTF-8');
        updatePayload += retryWrap.tokenValue != null ? '&singleUseTokenId='+EncodingUtil.urlEncode(retryWrap.tokenValue, 'UTF-8') : '';
        HTTPResponse updateResponse = PaywayManager.updateCardDetails(retryWrap.customerNumber, updatePayload);
        
        if((updateResponse.getStatus() == 'OK' || updateResponse.getStatusCode() == 200))
        {
            //Performing retry for customer.
            HTTPResponse retryresponse = PaywayManager.updateRecurringPayment(retryWrap.customerNumber , retryWrap.transactionPayload);
            
            if((retryresponse.getStatus() == 'OK' || retryresponse.getStatusCode() ==200))
            {                    
                retryresponsewrapper = (PaywayRecurringResponseWrapper)JSON.deserialize(retryresponse.getBody(), PaywayRecurringResponseWrapper.class);
                PaywayRecurringResponseWrapper cardInformation = (PaywayRecurringResponseWrapper )JSON.deserialize(updateResponse.getBody(), PaywayRecurringResponseWrapper.class);
                
                //assigning card details
                cardInfo.cardNumber = cardInformation.creditCard.cardNumber;
                cardInfo.expiryDateMonth = cardInformation.creditCard.expiryDateMonth;
                cardInfo.expiryDateYear = cardInformation.creditCard.expiryDateYear;
                cardInfo.cardholderName = cardInformation.creditCard.cardholderName;
                cardInfo.cardScheme = cardInformation.creditCard.cardScheme;
                
                //assining schedule info
                scheduleinfo.frequency = retryresponsewrapper.frequency;
                scheduleinfo.nextPaymentAmount = retryresponsewrapper.nextPaymentAmount;
                scheduleinfo.nextPaymentDate = retryresponsewrapper.nextPaymentDate;
                scheduleinfo.nextPrincipalAmount = retryresponsewrapper.nextPrincipalAmount;
                scheduleinfo.regularPrincipalAmount = retryresponsewrapper.regularPrincipalAmount;
                scheduleinfo.nextPrincipalAmount = retryresponsewrapper.nextPrincipalAmount;
                scheduleinfo.regularPaymentAmount = retryresponsewrapper.regularPaymentAmount;
                
                retryresponsewrapper.schedule = scheduleinfo;
                cardInfoSetup.creditCard = cardInfo;
                
                retryresponsewrapper.paymentSetup = cardInfoSetup; 
                retryresponsewrapper.relatedtoId = retryWrap.sfProcessingId;
                retryresponsewrapper.customerNumber = retryWrap.customerNumber;
                
                PaywayTransactionResponseWrapper  paymentstatus = PaywayHelper.checkPaymentinPayway( retryresponsewrapper, retryWrap.startDate);
                
                if(paymentStatus.status == 'approved'){ 
                    
                    receipt.nextInstallmentDate = UTILGateway.convertStringtoDate(retryresponsewrapper.nextPaymentDate);
                    receipt.establishmentDate = date.today();
                    receipt.paymentResponse = paymentstatus.responseText;
                    receipt.paymentStatus = 'Payment Approved';
                    
                }else if(paymentStatus.status == 'pending'){
                    
                    receipt.nextInstallmentDate = UTILGateway.convertStringtoDate(retryresponsewrapper.nextPaymentDate);
                    receipt.establishmentDate = date.today();
                    receipt.paymentResponse = paymentStatus.responseText;
                    receipt.paymentStatus = 'Payment Approved';
                    
                } else if(paymentStatus.status == 'declined'){
                    
                    receipt.paymentResponse = Messagehandler.recurringFailed +'. '+ paymentStatus.responseText;
                    receipt.paymentStatus = 'Payment Rejected';
                    
                }else{
                    receipt.paymentResponse = paymentStatus.responseText;
                    receipt.paymentStatus = 'Payment Rejected';
                }
            }else {
                
                recurringMessage = MessageHandler.recurringFailed;
                if(retryresponse.getStatusCode() == 422){
                    
                    retryresponsewrapper = (PaywayRecurringResponseWrapper)JSON.deserialize(retryresponse.getBody(), PaywayRecurringResponseWrapper.class);
                    for(Integer i=0; i < retryresponsewrapper.data.size(); i++){
                        recurringMessage =+ retryresponsewrapper.Data[i].fieldName +' : '+ retryresponsewrapper.data[i].message+'\n';
                    }
                    receipt.paymentResponse = recurringMessage;
                    receipt.paymentStatus = 'Payment Rejected';
                    
                } else{
                    receipt.paymentResponse = PaywayHelper.getPaymentStatusMessage(String.valueOf(retryresponse.getStatusCode()));
                    receipt.paymentStatus = 'Payment Rejected';                    
                }
            }
        }else{
            
            recurringMessage = MessageHandler.recRetryCardUpdtFailed;
            if(updateResponse.getStatusCode() == 422){
                retryresponsewrapper = (PaywayRecurringResponseWrapper)JSON.deserialize(updateResponse.getBody(), PaywayRecurringResponseWrapper.class);
                for(Integer i=0; i < retryresponsewrapper.data.size(); i++){
                    recurringMessage =+ retryresponsewrapper.Data[i].fieldName +' : '+ retryresponsewrapper.data[i].message+'\n';
                }
                receipt.paymentResponse = recurringMessage;
                receipt.paymentStatus = 'Payment Rejected';
                
            } else{
                receipt.paymentResponse =  PaywayHelper.getPaymentStatusMessage(String.valueOf(updateResponse.getStatusCode()));
                receipt.paymentStatus = 'Payment Rejected';
            }
        }
        
        String serializedWrapper=JSON.serialize(receipt);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UTILGateway.PAYWAYWORD,Processing_Record_Id__c=retryWrap.sfProcessingId,Frequency__c = retryWrap.instalPeriod ,Action__c=UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.recPayCheckoutComplete, Request_Type__c = 'POST',Recurring_Start_Date__c = retryWrap.startDate , Amount__c = retryWrap.amount,Charge_Type__c = UTILGateway.RECURRINGKEYWORD, End_Point__c = '/apex/Q_Charge__PaywayCheckout?reference=', Serialized_Record__c = serializedWrapper, Q_Charge__Payment_Parameter_1__c = UTILGateway.encodeCustomerKeys(retryWrap.customerNumber))));
        
        List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog = paymentLogList.get(paymentLogList.size()-1);
        retryresponsewrapper.transactionreference = newLog.Id;
        return retryresponsewrapper;
    }
    
    /*************************** method for fetching or validating the Payments.  ***************************/
    public static PaywayTransactionResponseWrapper checkPaymentinPayway(PaywayRecurringResponseWrapper recurringResponse , Date paymentstartDate)
    {
        PaywayTransactionResponseWrapper oneOffresponsewrapper = new PaywayTransactionResponseWrapper();
        String cancelResp = '';
        //Checking if card details with a transaction of $1 if date of payment belongs to future.
        if(paymentstartDate > date.today()){
            
            TransactionWrapper checkCardResponseWrapper = PaywayHelper.create1DollerTransaction(recurringResponse);
            if(checkCardResponseWrapper.httpResponseStatus == 'Created' || checkCardResponseWrapper.transactionResponseCode == '201'){
                
                oneOffresponsewrapper = (PaywayTransactionResponseWrapper )JSON.deserialize(checkCardResponseWrapper.transResponse, PaywayTransactionResponseWrapper.class);
                
                if(oneOffresponsewrapper.status == 'declined'){
                    cancelResp = PaywayManager.cancelRecurringPayment(recurringResponse.customerNumber);
                    
                } else if((oneOffresponsewrapper.status == 'approved' || oneOffresponsewrapper.status == 'pending') && (cancelResp == '' || cancelResp == 'Cancelled')){
                    oneOffresponsewrapper.responseText = (oneOffresponsewrapper.status == 'approved') ? MessageHandler.recurringSuccess : MessageHandler.scheduleTransacionPending;
                    recurringResponse.paymentStatus = oneOffresponsewrapper.status;
                    recurringResponse.paymentStartDate = paymentstartDate;    
                    
                    //Assigning 1 doller transaction response to PaywayCustPymtRespWrapper.
                    PaywayCustPymtRespWrapper paymentResponse = new PaywayCustPymtRespWrapper();
                    List<PaywayCustPymtRespWrapper.Data> custPaymnt = new List<PaywayCustPymtRespWrapper.Data>();
                    
                    PaywayCustPymtRespWrapper.Data newPayment = new PaywayCustPymtRespWrapper.Data();
                    newPayment.transactionId = Long.valueof(oneOffresponsewrapper.transactionId);
                    newPayment.paymentAmount = oneOffresponsewrapper.paymentAmount;
                    newPayment.customerNumber = oneOffresponsewrapper.customerNumber;
                    newPayment.status = oneOffresponsewrapper.status;
                    
                    custPaymnt.add(newPayment);
                    paymentResponse.data = custPaymnt;
                    paymentResponse.updateSchedule = false;
                    
                    //calling method to Create Recurring, Transaction and payment log record of schedule.
                    PaywayHelper.createRecurringTransaction(recurringResponse,paymentResponse);
                    
                } else if(cancelResp != '' || cancelResp != 'Cancelled'){
                    oneOffresponsewrapper.status = cancelResp;
                    oneOffresponsewrapper.responseText = MessageHandler.wentWrongCatchMessage;
                    PaywayHelper.sendCancelFailureEmail(recurringResponse.customerNumber ,cancelResp);
                }
                
            } else if(checkCardResponseWrapper.transactionResponseCode == '422'){
                
                oneOffresponsewrapper = (PaywayTransactionResponseWrapper )JSON.deserialize(checkCardResponseWrapper.transResponse, PaywayTransactionResponseWrapper.class);
                String errorMessage = MessageHandler.cardValidationFailed;
                
                for(Integer i=0; i < oneOffresponsewrapper.data.size(); i++){
                    errorMessage = errorMessage + oneOffresponsewrapper.data[i].message+', ';
                }
                oneOffresponsewrapper.status = errorMessage;
                
            } else{
                String errorMessage = MessageHandler.cardValidationFailed;
                
                if(PaywayHelper.getPaymentStatusMessage(checkCardResponseWrapper.transactionResponseCode) != null){
                    oneOffresponsewrapper.status = errorMessage + PaywayHelper.getPaymentStatusMessage(checkCardResponseWrapper.transactionResponseCode);
                } else {
                    oneOffresponsewrapper.status = MessageHandler.wentWrongCatchMessage;
                }
            }
        } else{
            //fetching payment status if payment date is today.
            RecurringWrapper recurringPayments = PaywayManager.getTransactionRP(recurringResponse.customerNumber);
            if(recurringPayments.httpResponseStatus == 'OK'|| recurringPayments.httpResponseStatuscode == 200){
                
                PaywayCustPymtRespWrapper paymentResponse = (PaywayCustPymtRespWrapper )JSON.deserialize(recurringPayments.recurringResponse, PaywayCustPymtRespWrapper.class);
                paymentResponse.updateSchedule = false;
                oneOffresponsewrapper.status = paymentResponse.Data[0].status;
                
                if( paymentResponse.Data[0].status == 'declined'){
                    cancelResp = PaywayManager.cancelRecurringPayment (recurringResponse.customerNumber);
                    TransactionWrapper transInfoReq = new TransactionWrapper();
                    transInfoReq.transactionId = String.valueOf(paymentResponse.Data[0].transactionId);
                    transInfoReq.customerNumber = paymentResponse.Data[0].customerNumber;
                    transInfoReq = PaywayManager.getTransaction(transInfoReq);
                    oneOffresponsewrapper = (PaywayTransactionResponseWrapper )JSON.deserialize(transInfoReq.transResponse, PaywayTransactionResponseWrapper.class);
                    
                } else if((paymentResponse.Data[0].status == 'approved' || paymentResponse.Data[0].status == 'pending') && (cancelResp == '' || cancelResp == 'Cancelled')){
                    recurringResponse.paymentStatus = paymentResponse.Data[0].status;
                    recurringResponse.paymentStartDate = paymentstartDate;
                    oneOffresponsewrapper.responseText = (paymentResponse.Data[0].status == 'approved') ? MessageHandler.recurringSuccess : MessageHandler.scheduleTransacionPending;
                    
                    //calling method to Create Recurring, Transaction and payment log record of schedule. 
                    PaywayHelper.createRecurringTransaction(recurringResponse,paymentResponse);  
                    
                }else if(cancelResp != '' || cancelResp != 'Cancelled'){
                    oneOffresponsewrapper.responseText = MessageHandler.wentWrongCatchMessage;
                    PaywayHelper.sendCancelFailureEmail(recurringResponse.customerNumber ,cancelResp);
                }
                
            } else{
                oneOffresponsewrapper.status = recurringPayments.httpResponseStatus;
                oneOffresponsewrapper.responseText = PaywayHelper.getPaymentStatusMessage(String.valueOf(recurringPayments.httpResponseStatuscode));
            }
        }
        return oneOffresponsewrapper;	
    }
    
    
    /******************************** Method for creating Recurring Payment record ***************************************/  
    public static void createRecurringTransaction(PaywayRecurringResponseWrapper recurringResponse,PaywayCustPymtRespWrapper transactionWrapperList){
        try{
            ID transactionRecordtype = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
            Recurring_Payment__c recurringPayment = new Recurring_Payment__c();
            
            if(Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isCreateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isCreateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isCreateable()
               && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isCreateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isCreateable()
               && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isCreateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isCreateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Type__c.isCreateable())
            {
                recurringPayment.Amount__c = Decimal.valueof(recurringResponse.schedule.regularPaymentAmount);
                recurringPayment.Next_Installment_Date__c = UTILGateway.convertStringtoDate(recurringResponse.schedule.nextPaymentDate);
                recurringPayment.Date_Established__c = date.today();
                recurringPayment.Gateway_Name__c = UTILGateway.PAYWAYWORD;
                recurringPayment.Installment_Period__c = (recurringResponse.schedule.frequency=='six-monthly')?'Half Yearly':recurringResponse.schedule.frequency.capitalize();
                recurringPayment.Status__c = 'Open';
                recurringPayment.RelatedToId__c = recurringResponse.relatedtoId;
                recurringPayment.Gateway_Schedule_Id__c = UTILGateway.encodeCustomerKeys(recurringResponse.customerNumber);
                recurringPayment.Card_Last_Updated_On__c = Datetime.now();
                recurringPayment.Card_Name__c = recurringResponse.paymentSetup.creditCard.cardholderName;
                recurringPayment.Card_Number__c = recurringResponse.paymentSetup.creditCard.cardNumber;
                recurringPayment.Card_Expiry_Date__c = ((recurringResponse.paymentSetup.creditCard.expiryDateMonth != null) && (recurringResponse.paymentSetup.creditCard.expiryDateYear != null)) ? Date.newinstance(Integer.valueOf(recurringResponse.paymentSetup.creditCard.expiryDateYear)+2000, Integer.valueOf(recurringResponse.paymentSetup.creditCard.expiryDateMonth), Date.daysInMonth(Integer.valueOf(recurringResponse.paymentSetup.creditCard.expiryDateYear)+2000, Integer.valueOf(recurringResponse.paymentSetup.creditCard.expiryDateMonth))) : null;
                recurringPayment.Card_Type__c = recurringResponse.paymentSetup.creditCard.cardScheme.toUpperCase();
                
                if(recurringResponse.paymentstartDate > date.today() && transactionWrapperList.data[0].paymentAmount == 1.00){
                    
                    recurringPayment.Gateway_Refund_Id__c = string.valueOf(transactionWrapperList.data[0].transactionId);
                    recurringPayment.Refund_Status__c = 'Awaiting';
                    recurringPayment.Refund_Amount__c = transactionWrapperList.data[0].paymentAmount;
                }
                
                //Creating paid tranaction record of RP.
                List<Transaction__c> recurringTransactions = mapRecurringTransactionRecord(transactionWrapperList,recurringPayment);
                //Creating scheduled transaction reord of RP
                recurringTransactions.add(mapScheduleTransaction(recurringPayment));
                
                if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'create')){
                    insert recurringPayment;
                }else {
                    throw new UTILPermission.PermsException('Q_Charge__Recurring_Payment__c','','Create');
                }
                
                if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'create') 
                   && Schema.sObjectType.Q_Charge__Transaction__c.fields.Recurring_Payment__c.isCreateable())
                {
                    for( Transaction__c recTran : recurringTransactions){
                        recTran.Recurring_Payment__c = recurringPayment.id;
                    }
                    if(recurringTransactions.size() > 0){
                        insert recurringTransactions;
                    }
                }else {
                    throw new UTILPermission.PermsException('Q_Charge__Transaction__c','','create');
                }
            }else{
                throw new UTILPermission.PermsException('Q_Charge__Recurring_Payment__c','Amount__c,Next_Installment_Date__c,Refund_Amount__c,Refund_Status__c,Gateway_Refund_Id__c,RelatedToId__c,Card_Number__c,Gateway_Schedule_Id__c,Installment_Period__c,Date_Established__c,Gateway_Name__c','Create');
            }
        } catch(DmlException dex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',dex,null);
        }
    }
    
    /******************************* Method for mapping recurring transaction. ****************************************/
    public static List<Transaction__c> mapRecurringTransactionRecord(PaywayCustPymtRespWrapper paymentResponse, Recurring_Payment__c recurringPayment)
    {
        List<Transaction__c> transactionsToCaptureInSF = new List<Transaction__c>();
        List<Transaction__c> transactionsList = [Select Id,Transaction_Date__c,Transaction_Id__c,Recurring_Payment__c,Transaction_Status__c from Transaction__c where Recurring_Payment__c=:recurringPayment.id AND Recurring_Payment__c != null WITH SECURITY_ENFORCED];
        List<Transaction__c> scheduledTransaction = [Select Id,Transaction_Date__c,Transaction_Id__c,Recurring_Payment__c,Transaction_Status__c from Transaction__c where Recurring_Payment__c =: recurringPayment.id AND Recurring_Payment__c != null AND Transaction_Status__c = 'Scheduled' WITH SECURITY_ENFORCED limit 1];
        List<Transaction__c> futureScheduled = new List<Transaction__c>();
        
        ID transactionRecordtype = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
        Set<String> transactionIdSet = new Set<String>();
        if(transactionsList.size() > 0){
            for(Transaction__c transactionrecord : transactionsList){
                transactionIdSet.add(transactionrecord.Transaction_Id__c);
            }
        }
        Integer flag = 0;
        for(Integer i=paymentResponse.Data.size() - 1; i >= 0; i--){
            
            if(!transactionIdSet.contains(String.valueOf(paymentResponse.Data[i].transactionId)) 
               && recurringPayment.Gateway_Refund_Id__c != String.valueOf(paymentResponse.Data[i].transactionId) 
               && paymentResponse.Data[i].paymentAmount > 0 ){
                   
                   TransactionWrapper transInfoReq = new TransactionWrapper();
                   transInfoReq.transactionId = String.valueOf(paymentResponse.Data[i].transactionId);
                   transInfoReq.customerNumber = paymentResponse.Data[i].customerNumber;
                   
                   transInfoReq = PaywayManager.getTransaction(transInfoReq);
                   PaywayTransactionResponseWrapper transactionInfo = (PaywayTransactionResponseWrapper )JSON.deserialize(transInfoReq.transResponse, PaywayTransactionResponseWrapper.class);
                   
                   if(flag == 0 && scheduledTransaction.size() > 0 && paymentResponse.updateSchedule == true){
                       transactionsToCaptureInSF.add(mapUpdateTransaction(transactionInfo,scheduledTransaction[0]));
                       //Using scheduleTransacionlist
                       if(recurringPayment.Status__c != 'Closed'){
                           futureScheduled.add(mapScheduleTransaction(recurringPayment));
                       }
                   } else{
                       
                       //Fetching complete transaction details of a recurring payments.
                       transactionInfo.recordtypeID = transactionRecordtype;
                       transactionInfo.recurringID = recurringPayment.Id;
                       Transaction__c recurringTransactionData = mapTransaction(transactionInfo);
                       transactionsToCaptureInSF.add(recurringTransactionData);
                   } 
                   flag = flag + 1;
                   
               } else if(i==0 && scheduledTransaction.size() < 1 && paymentResponse.updateSchedule == true && recurringPayment.Status__c != 'Closed'){
                   futureScheduled.add(mapScheduleTransaction(recurringPayment));
               }
        }
        if(futureScheduled.size() == 1 && recurringPayment.Status__c != 'Closed'){
            transactionsToCaptureInSF.add(futureScheduled[0]);
        } 
        if(transactionsToCaptureInSF.size() == 0 && scheduledTransaction.size() == 1){
            PaywayTransactionResponseWrapper updateScheuleRecord = new PaywayTransactionResponseWrapper();
            updateScheuleRecord.paymentAmount = recurringPayment.Amount__c;
            updateScheuleRecord.status = (recurringPayment.Status__c != 'Closed') ? 'Scheduled' : 'Cancelled';
            updateScheuleRecord.transactionDateTime = UTILGateway.convertDatetoString(date.newinstance(recurringPayment.Next_Installment_Date__c.year(), recurringPayment.Next_Installment_Date__c.month(), recurringPayment.Next_Installment_Date__c.day()));
            transactionsToCaptureInSF.add(mapUpdateTransaction(updateScheuleRecord,scheduledTransaction[0]));
        }
        return transactionsToCaptureInSF;
    }
    
    
    
    /*******************************Method for mapping scheduled transaction Record. ******************************************/
    Public static Transaction__c mapScheduleTransaction(Recurring_Payment__c recurringPayment)
    {
        PaywayTransactionResponseWrapper scheduledTransRec = new PaywayTransactionResponseWrapper();
        scheduledTransRec.paymentAmount = recurringPayment.Amount__c;
        scheduledTransRec.status = (recurringPayment.Status__c == 'Closed') ? 'Cancelled' : 'Scheduled' ;
        scheduledTransRec.recordtypeID = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
        scheduledTransRec.transactionDateTime = UTILGateway.convertDatetoString(recurringPayment.Next_Installment_Date__c);
        scheduledTransRec.recurringID = recurringPayment.id;
        
        return mapTransaction(scheduledTransRec);
    }
    
    /******************************* Method for mapping updated information to scheduled transaction Record. ******************************************/
    Public static Transaction__c mapUpdateTransaction(PaywayTransactionResponseWrapper transactionInfo, Transaction__c scheduleTrans)
    {
        if((System.UserInfo.getUserType() == 'Guest' && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','create') && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable()
        && Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable()
        && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable())
        ||
        (System.UserInfo.getUserType() != 'Guest' && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','update') 
        && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','create') && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable()
        && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable()
        && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable() 
        && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()
        && Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable()
        && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable()))
        {
            scheduleTrans.Amount__c = transactionInfo.paymentAmount;
            scheduleTrans.Transaction_Date__c = UTILGateway.convertStringtoDateTime(transactionInfo.transactionDateTime);
            scheduleTrans.Gateway_Name__c = UTILGateway.PAYWAYWORD;
            scheduleTrans.Transaction_Status__c = (transactionInfo.status == 'declined') ? 'Failed' : (transactionInfo.status == 'approved') ? 'Paid' : transactionInfo.status;
            scheduleTrans.Transaction_Id__c =(transactionInfo.transactionId != null ) ? String.valueOf(transactionInfo.transactionId) : '';
            
        } else{
            throw new UTILPermission.PermsException('Transaction__c','RecordTypeId,Amount__c,Transaction_Date__c,Gateway_Name__c,Transaction_Status__c,Transaction_Id__c,Recurring_Payment__c','Update');
        }
        return scheduleTrans; 
    }
    
    /*********************Method used in batch to fetch the Recurring Payments*****************/
    public static void fetchRecurringTransaction(List<Recurring_Payment__c> recurringPaymentlist){
        
        if(paywayCheck != null){
            throw new GatewayException(paywayCheck);
        }
        //process only one record at a time.
        Recurring_Payment__c recurringPayment = new Recurring_Payment__c(); 
        List<Transaction__c> listofTransaction = new List<Transaction__c>();
        
        if(recurringPaymentlist.size() > 0){
            for(Recurring_Payment__c recurPayment : recurringPaymentlist){
                recurringPayment = recurPayment;
            }
        }else{
            return;
        }
        
        //Checks if frequency,regular amound is changed in payway server.
        HTTPResponse transactionresponse = PaywayManager.getScheduleDetails(UTILGateway.decodeCustomerKeys(recurringPayment.Gateway_Schedule_Id__c));
        
        if(transactionresponse.getStatusCode() ==200 || transactionresponse.getStatus() =='OK'){
            PaywayRecurringResponseWrapper custRecurringResponseWrapper = (PaywayRecurringResponseWrapper )JSON.deserialize(transactionresponse.getBody(), PaywayRecurringResponseWrapper.class);
            if(Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() 
               && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable())
            {
                if(recurringPayment.Installment_Period__c != custRecurringResponseWrapper.schedule.frequency.capitalize()){
                    recurringPayment.Installment_Period__c = custRecurringResponseWrapper.schedule.frequency.capitalize();
                    
                }else if( recurringPayment.Amount__c != Decimal.valueof(custRecurringResponseWrapper.schedule.regularPaymentAmount)){
                    recurringPayment.Amount__c = Decimal.valueof(custRecurringResponseWrapper.schedule.regularPaymentAmount);
                    
                }else if(recurringPayment.Next_Installment_Date__c != UTILGateway.convertStringtoDate(custRecurringResponseWrapper.schedule.nextPaymentDate)){
                    recurringPayment.Next_Installment_Date__c = UTILGateway.convertStringtoDate(custRecurringResponseWrapper.schedule.nextPaymentDate);
                }
                
                //fetching payments of the customer
                RecurringWrapper recurringPayments = PaywayManager.getTransactionRP(custRecurringResponseWrapper.customerNumber);
                if(recurringPayments.httpResponseStatus == 'OK' || recurringPayments.httpResponseStatuscode == 200){
                    
                    PaywayCustPymtRespWrapper paymentResponse = (PaywayCustPymtRespWrapper )JSON.deserialize(recurringPayments.recurringResponse, PaywayCustPymtRespWrapper.class);
                    paymentResponse.updateSchedule = true;
                    
                    //Calling mapping method to map transaction record.
                    listofTransaction = mapRecurringTransactionRecord(paymentResponse,recurringPayment);
                } else{
                    throw new GatewayException(PaywayHelper.getPaymentStatusMessage(String.valueOf(recurringPayments.httpResponseStatuscode)));
                }
            }else{
                throw new UTILPermission.PermsException('Q_Charge__Recurring_Payment__c','Installment_Period__c,Amount__c,Next_Installment_Date__c','Update');
            }
        }else{
            throw new GatewayException(PaywayHelper.getPaymentStatusMessage(String.valueOf(transactionresponse.getStatusCode())));
        }
        UTILGateway.allowRPUpdate = true;
        if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && recurringPaymentlist.size()>0){
            update recurringPaymentlist;
        }
        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'upsert') && listofTransaction.size()>0){
            upsert listofTransaction;
        }
    }
    
    /*********************** Method for creating 1 doller charge to verify card details ********************************/
    public static TransactionWrapper create1DollerTransaction(PaywayRecurringResponseWrapper recurringResponse)
    {
        TransactionWrapper checkCardwrapper = new TransactionWrapper();
        checkCardwrapper.pcurrency = 'aud';
        checkCardwrapper.amount = 1.00; 
        checkCardwrapper.transactionType = 'payment';
        checkCardwrapper.customerNumber = recurringResponse.customerNumber;
        checkCardwrapper.sfProcessingId = recurringResponse.relatedtoId;
        string checkCardPayload = PaywayHelper.createOneTimePayLoad(checkCardwrapper);
        
        checkCardwrapper.actiontype = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.validateCard;
        checkCardwrapper.transactionPayload = checkCardPayload;
        checkCardwrapper.encodedCustomerNumber = UTILGateway.encodeCustomerKeys(recurringResponse.customerNumber);
        
        TransactionWrapper checkCardDetails = PaywayManager.performOneTimePayment(checkCardwrapper);
        return checkCardDetails;
    }
    
    /**************************** Method for cancelling recurring payment **************************/
    public static String cancelRecurringPayment(List<Recurring_Payment__c> existingRPList)
    {
        String returnValue = '';
        List<Transaction__c> listofTransaction = new List<Transaction__c>();
        Recurring_Payment__c existingRP = new Recurring_Payment__c();
        
        try{
            
            if(existingRPList.size() > 0){
                for(Recurring_Payment__c recurPayment : existingRPList){
                    existingRP = recurPayment;
                }
            }else{
                return MessageHandler.wentWrongCatchMessage;
            }
            
            String customerRef = UTILGateway.decodeCustomerKeys(existingRP.Gateway_Schedule_Id__c);
            returnValue = PaywayManager.cancelRecurringPayment(customerRef);
            
            if(returnValue == 'Cancelled'){
                returnValue = existingRP.Name+''+MessageHandler.cancelRP+' in Payway.';
                
                if(Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable() && (UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') 
                                                                                               && UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'upsert')))
                {
                    existingRP.Status__c = 'Closed';
                    
                    RecurringWrapper recurringPayments = PaywayManager.getTransactionRP(customerRef);                        
                    if(recurringPayments.httpResponseStatus == 'OK'){
                        PaywayCustPymtRespWrapper paymentResponse = (PaywayCustPymtRespWrapper )JSON.deserialize(recurringPayments.recurringResponse, PaywayCustPymtRespWrapper.class);
                        paymentResponse.updateSchedule = true;
                        listofTransaction = mapRecurringTransactionRecord(paymentResponse,existingRP);
                    }
                    
                    UTILGateway.allowRPUpdate = true;
                    update existingRP;
                    upsert listofTransaction;
                    
                }else{
                    throw new UTILPermission.PermsException('Transaction__c,Recurring_Payment__c','Transaction_Status__c,Status__c','update');
                }
            }else{
                returnValue =  +existingRP.name + MessageHandler.faildetoCancel + returnValue+ MessageHandler.refreshAndTryagain;             
            }
        } catch(UTILPermission.PermsException pex){
            returnValue = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',pex,null);
            
        } catch(DmlException dex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',dex,null);
            
        } catch(Exception ex){
            returnValue = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('PaywayHelper', ex, false);
        }
        return returnValue;
    }
    
    
    /***************** Method to request update card detail page ***************/
    public static String requestUpdateCardDetails(String recurringId,String gatewayScheduleId,String requestUrl)
    {
        String returnValue='';
        Payment_Log__c log= new Payment_Log__c(Processing_Record_Id__c=recurringId,Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.updateCardRequest, Transaction_Id__c=gatewayScheduleId,Requesting_Url__c=requestUrl,Gateway_Name__c=UTILGateway.PAYWAYWORD);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c newLog=paymentLogList.get(paymentLogList.size()-1);
        RecurringWrapper updateWrapper = new RecurringWrapper();
        updateWrapper.transactionreference=newLog.Id;
        updateWrapper=PaywayManager.requestUpdateCardDetails(updateWrapper);
        returnValue=(updateWrapper.status) ? updateWrapper.processingLink : updateWrapper.errorResponse;
        return returnValue;
    }
    
    /**************************************** Update Card details mehod for Payway*********************************************/
    public static String updatePaywayCardDetails(RecurringWrapper updateWrap)
    {
        String errormessage = '';
        String result = '';
        ReceiptWrapper receipt = new ReceiptWrapper();
        try{
            HTTPResponse updateResponse = PaywayManager.updateCardDetails(updateWrap.customerNumber, updateWrap.transactionPayload);
            
            if(updateResponse.getStatusCode() == 200 || updateResponse.getStatus() =='OK'){
                PaywayRecurringResponseWrapper recResp = new PaywayRecurringResponseWrapper();
                recResp.customerNumber = updateWrap.customerNumber;
                recResp.relatedtoId = updateWrap.sfProcessingId;
                
                TransactionWrapper checkCardResponseWrapper = PaywayHelper.create1DollerTransaction(recResp);
                PaywayTransactionResponseWrapper oneOffresponsewrapper = (PaywayTransactionResponseWrapper )JSON.deserialize(checkCardResponseWrapper.transResponse, PaywayTransactionResponseWrapper.class);
                if(checkCardResponseWrapper.httpResponseStatus == 'Created' || checkCardResponseWrapper.transactionResponseCode == '201'){
                    
                    if(oneOffresponsewrapper.status == 'declined') {
                        errormessage = MessageHandler.updatedWithWrongCard;
                    } else if(oneOffresponsewrapper.status == 'approved') {
                        result = MessageHandler.creditCardUpdatSuccesse + UTILGateway.PAYWAYWORD.capitalize()+'.';
                    } else if(oneOffresponsewrapper.status == 'pending') { //Some Need to be figureOut about this situation.
                        result = MessageHandler.cardvalidationPending;
                    }
                    
                } else if(checkCardResponseWrapper.transactionResponseCode == '422') {
                    errorMessage = MessageHandler.cardValidationFailed;
                    for(Integer i=0; i < oneOffresponsewrapper.data.size(); i++) {
                        errorMessage = errorMessage + oneOffresponsewrapper.data[i].message+', ';
                    }
                    
                } else{
                    errorMessage = MessageHandler.cardValidationFailed;
                    if(PaywayHelper.getPaymentStatusMessage(checkCardResponseWrapper.transactionResponseCode) != null){
                        errorMessage = errorMessage + PaywayHelper.getPaymentStatusMessage(checkCardResponseWrapper.transactionResponseCode);
                    }else {
                        errorMessage = MessageHandler.wentWrongCatchMessage;
                    }
                }
                
                PaywayRecurringResponseWrapper cardInformation = (PaywayRecurringResponseWrapper )JSON.deserialize(updateResponse.getBody(), PaywayRecurringResponseWrapper.class);
                Recurring_Payment__c recurringPayment = [Select Amount__c, Card_Last_Updated_On__c,Refund_Description__c,Refund_Date__c,Refund_Status__c,Card_Name__c,Card_Expiry_Date__c,RelatedToId__c,Card_Number__c from Recurring_Payment__c where Id=:updateWrap.sfProcessingId WITH SECURITY_ENFORCED LIMIT 1];
                updateWrap.amount = recurringPayment.Amount__c;
                
                //Updating card details of recurring payment.
                if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable() 
                   && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isUpdateable() 
                   && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable() 
                   && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Date__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isUpdateable()
                   && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isUpdateable()){   
                       recurringPayment.Card_Last_Updated_On__c = Datetime.now();
                       recurringPayment.Card_Name__c = cardInformation.creditCard.cardholderName;
                       recurringPayment.Card_Number__c = cardInformation.creditCard.cardNumber;
                       recurringPayment.Card_Type__c = cardInformation.creditCard.cardScheme.toUpperCase();
                       recurringPayment.Card_Expiry_Date__c = ((cardInformation.creditCard.expiryDateMonth != null) && (cardInformation.creditCard.expiryDateYear != null)) ? Date.newinstance(Integer.valueOf(cardInformation.creditCard.expiryDateYear)+2000, Integer.valueOf(cardInformation.creditCard.expiryDateMonth), 
                                                                                                                                                                                               Date.daysInMonth(Integer.valueOf(cardInformation.creditCard.expiryDateYear)+2000, Integer.valueOf(cardInformation.creditCard.expiryDateMonth))) : null;
                       
                       if(oneOffresponsewrapper.status != 'declined'){
                           recurringPayment.Refund_Status__c = 'Awaiting';
                           recurringPayment.Gateway_Refund_Id__c = oneOffresponsewrapper.transactionId;
                           recurringPayment.Refund_Description__c = '';
                           recurringPayment.Refund_Date__c = null;
                           recurringPayment.Refund_Amount__c = oneOffresponsewrapper.paymentAmount;
                       }
                       
                       UTILGateway.allowRPUpdate = true;
                       update recurringPayment;
                   }else{
                       throw new UTILPermission.PermsException('Q_Charge__Recurring_Payment__c','Card_Last_Updated_On__c,Card_Name__c,Card_Number__c,Refund_Status__c,Gateway_Refund_Id__c,Refund_Description__c,Refund_Amount__c,Card_Expiry_Date__c,Refund_Date__c','Update');
                   }
            } else{
                errorMessage = PaywayHelper.getPaymentStatusMessage(String.valueOf(updateResponse.getStatusCode()));
            }
        } catch(UTILPermission.PermsException pex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',pex,null);
        } catch(DmlException dex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',dex,null);
        } catch(Exception ex){
            errorMessage = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('PaywayUpdateCardController', ex, false);
        }
        
        if(errorMessage != ''){
            String retryUrl = '/apex/Q_Charge__PaywayUpdateCard?reference='+updateWrap.logrefId;
            receipt.chargeType = UTILGateway.RECURRINGKEYWORD;
            receipt.amount = updateWrap.amount;
            receipt.paymentResponse = errorMessage +' '+ MessageHandler.enableRetry;
            receipt.paymentStatus= 'Transaction Rejected';
            
            Payment_Log__c log = new Payment_Log__c(Processing_Record_Id__c = updateWrap.sfProcessingId,Action__c=UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.updateCardfail,Transaction_Id__c = updateWrap.recurringRequestId,Charge_Type__c = 'Update Card',Serialized_Record__c = JSON.serialize(receipt),Requesting_Url__c = updateWrap.requestUrl,Gateway_Name__c = UTILGateway.PAYWAYWORD ,Retry_Schedule_Url__c = retryUrl);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
            List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            Payment_Log__c refLog = paymentLogList.get(paymentLogList.size()-1);
            result='/apex/Q_Charge__GatewayReceiptPage?reference='+refLog.Id;
        }
        return result;
    }
    
    
    /*********************** Helper method for Updating schedule ********************************/
    public static String processUpdateRecurringPayment(RecurringWrapper rectoUpate)
    {
        String updateResponse='';
        Date dateMaxLimit = Date.today().addYears(1);
        Date prevWeekLimit = Date.today().addDays(-6);
        Date prevMonthLimit = Date.today().addMonths(-1);
        Date prevFortnightLimit = Date.today().addDays(-13);
        try{
            if(paywayCheck != null){
                throw new GatewayException(paywayCheck);
            }
            List<Transaction__c> listofTransaction = new List<Transaction__c>();
            if(rectoUpate.amount.scale() > 2){
                updateResponse = MessageHandler.amountDecimalLimit;
            }
            else if(rectoUpate.startDate != null && rectoUpate.startDate >= dateMaxLimit){
                updateResponse = MessageHandler.startDateMorethan1Year;
            }
            else if(rectoUpate.startDate != null && rectoUpate.startDate < prevWeekLimit && rectoUpate.instalPeriod == 'Weekly'){
                updateResponse = MessageHandler.startDatelessthan6days;
            }
            else if(rectoUpate.startDate != null && rectoUpate.startDate < PrevFortnightLimit && rectoUpate.instalPeriod == 'Fortnightly'){
                updateResponse = MessageHandler.startDatelessthan13days;
            }
            else if(rectoUpate.startDate != null && rectoUpate.startDate < PrevMonthLimit && rectoUpate.instalPeriod == 'Monthly'){
                updateResponse = MessageHandler.startDatelessthan1month;
            }
            else if(updateResponse == ''){
                Recurring_Payment__c recurringToUpdate = [SELECT  Id,Name,Date_Established__c, Q_Charge__Gateway_Schedule_Id__c, Gateway_Name__c,RelatedToId__c,Status__c,
                                                          Gateway_Refund_Id__c,Refund_Amount__c,Refund_Status__c,Q_Charge__Installment_Period__c  
                                                          FROM Q_Charge__Recurring_Payment__c WHERE Id =:rectoUpate.sfProcessingId  WITH SECURITY_ENFORCED limit 1];
                
                HTTPResponse updateRecurring = PaywayManager.updateRecurringPayment( UTILGateway.decodeCustomerKeys(recurringToUpdate.Q_Charge__Gateway_Schedule_Id__c), rectoUpate.transactionPayload);
                
                if(updateRecurring.getStatus() == 'OK' || updateRecurring.getStatusCode() == 200){ 
                    
                    updateResponse = recurringToUpdate.Name + MessageHandler.updateRP + UTILGateway.PAYWAYWORD.capitalize()+'.';
                    PaywayRecurringResponseWrapper custRecurringResponseWrapper = (PaywayRecurringResponseWrapper )JSON.deserialize(updateRecurring.getBody(), PaywayRecurringResponseWrapper.class);
                    
                    if(Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() 
                       && Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() 
                       && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable())
                    {
                        recurringToUpdate.Installment_Period__c = (custRecurringResponseWrapper.frequency=='Six-Monthly')?'Half Yearly':custRecurringResponseWrapper.frequency.capitalize();
                        recurringToUpdate.Amount__c = Decimal.valueof(custRecurringResponseWrapper.regularPaymentAmount);
                        recurringToUpdate.Next_Installment_Date__c = UTILGateway.convertStringtoDate(custRecurringResponseWrapper.nextPaymentDate);
                        RecurringWrapper recurringPayments = PaywayManager.getTransactionRP(UTILGateway.decodeCustomerKeys(recurringToUpdate.Q_Charge__Gateway_Schedule_Id__c));
                        
                        if(recurringPayments.httpResponseStatus == 'OK'){
                            PaywayCustPymtRespWrapper paymentResponse = (PaywayCustPymtRespWrapper )JSON.deserialize(recurringPayments.recurringResponse, PaywayCustPymtRespWrapper.class);
                            paymentResponse.updateSchedule = true;
                            listofTransaction = mapRecurringTransactionRecord(paymentResponse,recurringToUpdate);
                        }
                        
                        if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update')){
                            UTILGateway.allowRPUpdate = true;
                            update recurringToUpdate;
                        }
                        if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c', 'upsert') && listofTransaction.size()>0){
                            upsert listofTransaction;
                        }
                    }else{
                        throw new UTILPermission.PermsException('Q_Charge__Recurring_Payment__c','Installment_Period__c,Amount__c,Next_Installment_Date__c','Update');
                    }
                } else{
                    String recurringMessage = MessageHandler.recPayUpdtFailed;
                    if(UpdateRecurring.getStatusCode() == 422){
                        PaywayRecurringResponseWrapper updateRecurringwrapper = (PaywayRecurringResponseWrapper)JSON.deserialize(UpdateRecurring.getBody(), PaywayRecurringResponseWrapper.class);
                        for(Integer i=0; i < updateRecurringwrapper.data.size(); i++){
                            recurringMessage =+ updateRecurringwrapper.Data[i].fieldName +' : '+ updateRecurringwrapper.data[i].message+'\n';
                        }
                        updateResponse = recurringMessage;
                    }
                    else{
                        updateResponse = recurringMessage + PaywayHelper.getPaymentStatusMessage(String.valueOf(updateRecurring.getStatusCode()));
                    }
                }
            }
        } catch(UTILPermission.PermsException pex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',pex,null);
        } catch(DmlException dex){
            EmailHandler.sendExceptionEmailtoAdmin('PaywayHelper',dex,null);
        } catch(Exception ex){
            updateResponse = MessageHandler.wentWrongCatchMessage;
            EmailHandler.sendExceptionEmail('PaywayHelper', ex, false);
        }
        return updateResponse;
    }
    
    /*******************Method used in refund batch************/
    public static void refund1Doller(List<Recurring_Payment__c> recurringPaymentlist)
    {
        if(paywayCheck != null){
            throw new GatewayException(paywayCheck);
        }
        if(recurringPaymentlist.size() > 0)
        {
            for(Recurring_Payment__c recurringPayment : recurringPaymentlist)
            {
                TransactionWrapper refundrequest = new TransactionWrapper();
                refundrequest.transactionType = 'refund';
                refundrequest.transactionId = recurringPayment.Gateway_Refund_Id__c;
                refundrequest.amount = recurringPayment.Refund_Amount__c;
                refundrequest.encodedCustomerNumber = recurringPayment.Gateway_Schedule_Id__c;
                
                TransactionWrapper refund = PaywayManager.getRefund(refundrequest);
                if(Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Date__c.isUpdateable() 
                   && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Description__c.isUpdateable())
                {
                    if(refund.httpResponseStatus == 'Created'){
                        recurringPayment.Refund_Date__c = System.Datetime.now();
                        recurringPayment.Refund_Status__c = 'Refunded';
                        recurringPayment.Refund_Description__c = 'Approved';
                        
                    } else if (refund.httpResponseStatus == 'Unprocessable Entity' || refund.transactionResponseCode == '422'){
                        String errorResp = 'Refund failed due to:\n';
                        PaywayTransactionResponseWrapper errorResponse = (PaywayTransactionResponseWrapper)JSON.deserialize(refund.errorResponse, PaywayTransactionResponseWrapper.class);
                        
                        for(Integer i=0; i < errorResponse.data.size(); i++){
                            errorResp = errorResp + (errorResponse.Data[i].fieldName).capitalize() +' : '+ errorResponse.data[i].message+'\n';
                        }
                        
                        if(!errorResp.contains('Credit card payments are only refundable after they have settled')){
                            recurringPayment.Refund_Status__c = 'Failed';
                            recurringPayment.Refund_Description__c = errorResp;
                        } else{
                            recurringPayment.Refund_Description__c = 'Refund attempted at '+Datetime.now()+ ' Can\'t be process due to : \n "'+MessageHandler.paymentNotSettled+'".';
                        }
                        
                    }else{
                        recurringPayment.Refund_Description__c = 'Refund is '+refund.httpResponseStatus+'\n'+refund.errorResponse;
                    }
                } else{
                    throw new UTILPermission.PermsException('Recurring_Payment__c','Refund_Status__c,Refund_Date__c,Refund_Description__c','Update');
                }
            }
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c', 'update') && recurringPaymentlist.size()>0){
                UTILGateway.allowRPUpdate = true;
                update recurringPaymentlist;
            }
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        }
    }
    /************************************ Payload as form-url-encoded method of payway recurring ******************************************/
    public static String  createOneTimePayLoad(TransactionWrapper transactionReq) 
    {
        String customerPayLoad= '';
        customerPayLoad += 'principalAmount='+EncodingUtil.urlEncode(String.valueOf(transactionReq.amount), 'UTF-8');
        customerPayLoad += transactionReq.tokenValue != null ? '&singleUseTokenId='+EncodingUtil.urlEncode(transactionReq.tokenValue, 'UTF-8') : '';
        customerPayLoad += transactionReq.customerNumber != null ? '&customerNumber='+EncodingUtil.urlEncode(transactionReq.customerNumber, 'UTF-8') : '';
        customerPayLoad += transactionReq.pcurrency != null ? '&currency='+EncodingUtil.urlEncode(transactionReq.pcurrency, 'UTF-8') : '';
        customerPayLoad += transactionReq.transactionType != null ? '&transactionType='+EncodingUtil.urlEncode(transactionReq.transactionType, 'UTF-8') : '';
        customerPayLoad += transactionReq.merchantId != null ? '&merchantId='+EncodingUtil.urlEncode(transactionReq.merchantId, 'UTF-8') : '';
        customerPayLoad += transactionReq.transactionId != null ? '&parentTransactionId='+EncodingUtil.urlEncode(transactionReq.transactionId, 'UTF-8') : '';
        return customerPayLoad;  
    }
    
    //Payload as form-url-encoded method of payway recurring.
    public static String  createReccurringPayLoad(RecurringWrapper scheduleReq) 
    {
        String customerPayLoad= '';
        customerPayLoad += 'frequency='+EncodingUtil.urlEncode(scheduleReq.instalPeriod.toLowerCase(), 'UTF-8');
        customerPayLoad += scheduleReq.name != null ? '&customerName='+EncodingUtil.urlEncode(scheduleReq.name, 'UTF-8') : '';
        customerPayLoad += scheduleReq.tokenValue != null ? '&singleUseTokenId='+EncodingUtil.urlEncode(scheduleReq.tokenValue, 'UTF-8') : '';
        customerPayLoad += scheduleReq.amount != null ? '&regularPrincipalAmount='+EncodingUtil.urlEncode(String.valueof(scheduleReq.amount), 'UTF-8') : '';
        customerPayLoad += scheduleReq.nextPaymentDate != null ? '&nextPaymentDate='+EncodingUtil.urlEncode(scheduleReq.nextPaymentDate, 'UTF-8') : '';
        customerPayLoad += scheduleReq.merchantId != null ? '&merchantId='+EncodingUtil.urlEncode(scheduleReq.merchantId, 'UTF-8') : '';
        return customerPayLoad;  
    }
    
    
    /*********************** Method for getting Payment status message on the basis of status code.********************************/
    public static String getPaymentStatusMessage(String code)
    {
        Map<String,String> responseMessageMap = new Map<String,String>();
        //responseMessageMap.put('200',PaywayMessages.message200);
        //responseMessageMap.put('201',PaywayMessages.message201);
        responseMessageMap.put('202',PaywayMessages.message202);
        responseMessageMap.put('400',PaywayMessages.message400);
        responseMessageMap.put('403',PaywayMessages.message403);
        responseMessageMap.put('404',PaywayMessages.message404);
        responseMessageMap.put('405',PaywayMessages.message405);
        responseMessageMap.put('406',PaywayMessages.message406);
        responseMessageMap.put('409',PaywayMessages.message409);
        responseMessageMap.put('410',PaywayMessages.message410);
        responseMessageMap.put('415',PaywayMessages.message415);
        responseMessageMap.put('422',PaywayMessages.message422);
        responseMessageMap.put('429',PaywayMessages.message429);
        responseMessageMap.put('500',PaywayMessages.message500);
        responseMessageMap.put('501',PaywayMessages.message405);
        responseMessageMap.put('503',PaywayMessages.message406);
        
        responseMessageMap.put('00',PaywayMessages.message00);
        responseMessageMap.put('01',PaywayMessages.message01);
        responseMessageMap.put('03',PaywayMessages.message03);
        responseMessageMap.put('04',PaywayMessages.message04);
        responseMessageMap.put('05',PaywayMessages.message05);
        responseMessageMap.put('08',PaywayMessages.message08);
        responseMessageMap.put('12',PaywayMessages.message12);
        responseMessageMap.put('14',PaywayMessages.message14);
        responseMessageMap.put('17',PaywayMessages.message17);
        responseMessageMap.put('22',PaywayMessages.message22);
        responseMessageMap.put('34',PaywayMessages.message34);
        responseMessageMap.put('39',PaywayMessages.message39);
        responseMessageMap.put('40',PaywayMessages.message40);
        responseMessageMap.put('41',PaywayMessages.message41);
        responseMessageMap.put('42',PaywayMessages.message42);
        responseMessageMap.put('43',PaywayMessages.message43);
        responseMessageMap.put('51',PaywayMessages.message51);
        responseMessageMap.put('54',PaywayMessages.message54);
        responseMessageMap.put('61',PaywayMessages.message61);
        responseMessageMap.put('63',PaywayMessages.message63);
        responseMessageMap.put('68',PaywayMessages.message68);
        responseMessageMap.put('91',PaywayMessages.message91);
        responseMessageMap.put('92',PaywayMessages.message92);
        
        responseMessageMap.put('QA',PaywayMessages.messageQA);
        responseMessageMap.put('QI',PaywayMessages.messageQI);
        responseMessageMap.put('QQ',PaywayMessages.messageQQ);
        responseMessageMap.put('QY',PaywayMessages.messageQY);     
        
        if(responseMessageMap.containsKey(code)){
            return responseMessageMap.get(code);
        }
        else{
            return null;
        }
    }
    
    
    /***************************************************************/
    public static void sendCancelFailureEmail(String customerNo , String errorResp ) {
        
        String emailbody = 'Payway Recurrig Payment cancellation for customer '+customerNo+ ' failed due to : '+errorResp;
        String emailSubject = 'Payway - Recurring payment cancellation failed';
        String emailAddress ='';
        ID sysAdmProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' WITH SECURITY_ENFORCED].Id;
        List<User> sysAdm = [SELECT id, Email FROM User WHERE ProfileId = :sysAdmProfile WITH SECURITY_ENFORCED];
        for(User userInfo : sysAdm){
            emailAddress += userInfo.Email+',';
        }
        EmailHandler.sendEmailTo( emailSubject, emailBody, emailAddress, null);
    }
}