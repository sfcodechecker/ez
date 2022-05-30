public with sharing class PaywayManager {
    
    /*********************** URL to be Hit ********************************/ 
    public static Final String PAYWAY_AUTH_URL = 'https://api.payway.com.au/rest/v1/';  
    public static Final String PAYWAY_TRANSACTION_URL = 'https://api.payway.com.au/rest/v1/transactions';
    public static Final string PAYWAY_MERCHANT_URL = 'https://api.payway.com.au/rest/v1/merchants';
    public static Final string PAYWAY_CUSTOMER_URL = 'https://api.payway.com.au/rest/v1/customers';
    public static Final string PW_CUSTOMER_TRANSACTION_URL = 'https://api.payway.com.au/rest/v1/transactions/search-customer?customerNumber='; // remove parameter and add it in the function
    
    /*********************** variables ********************************/
    public static Gateway_Detail__c paywaygateway;
    public static String detachedReason = null;
    public static Boolean isConnected = false;
    
    /******static****/
    static {
        if([Select Id  from Gateway_Detail__c where Name__c = :UTILGateway.PAYWAYWORD WITH SECURITY_ENFORCED].size() == 1){
            paywaygateway = UTILGateway.decodeKeys(UTILGateway.PAYWAYWORD);
            try{
                String credChecking = validateCredentials(paywaygateway, false);
                isConnected = (credChecking == 'valid' ? true : false);
                detachedReason = (credChecking != 'valid' ? credChecking : detachedReason);
            }catch(Exception ex){
                detachedReason = MessageHandler.apiKeyMissing+' Due to '+ex.getMessage()+'.';
            }  
        }else {
            detachedReason = MessageHandler.apiKeyMissing;
        }
    }
    
    /*********************** Check the Payway credentials ********************************/
    public static String validateCredentials(Gateway_Detail__c gateway, Boolean createLog){ 
        
        String returnValue = '';
        PaywayAuthResponseWrapper paywayAPIresponse;
        
        HTTPResponse responseKey = hitEndpoint(PAYWAY_AUTH_URL,'GET',gateway.Client_Id__c, null);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create') && createLog == true){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,End_Point__c = PAYWAY_AUTH_URL,Request_Type__c = 'GET',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.checkCredential,HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = String.valueof(responseKey))));
        }
        
        if(responseKey.getStatusCode()==200){
            paywayAPIresponse = PaywayAuthResponseWrapper.parse(responseKey.getBody());
            returnValue = checkMerchantID(gateway, createLog);
            
        } else if(responseKey.getStatusCode() == 401){
            paywayAPIresponse = PaywayAuthResponseWrapper.parse(responseKey.getBody());
            returnValue =  MessageHandler.authFailedPublicKey;
            
        } else{
            if(PaywayHelper.getPaymentStatusMessage(String.valueOf(responseKey.getStatusCode())) != null){
                returnValue = MessageHandler.authFailed+''+PaywayHelper.getPaymentStatusMessage(String.valueOf(responseKey.getStatusCode()));
                
            }else{
                returnValue = MessageHandler.wentWrongCatchMessage;
            }
        }
        return returnValue;
    }
    
    /*********************** Check the PayWay MerchanID ********************************/
    public static String checkMerchantID(Gateway_Detail__c gateway, Boolean createLog){
        
        String returnValue = '';
        PaywayAuthResponseWrapper authResponse;
        
        HTTPResponse responseKey = hitEndpoint(PAYWAY_MERCHANT_URL+'/'+gateway.Optional_Key_1__c,'GET',gateway.Client_Key__c, null);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create') && createLog == true){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,End_Point__c = PAYWAY_MERCHANT_URL,Request_Type__c = 'GET',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.checkMerchantid,HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = String.valueof(responseKey))));
        }
        
        if(responseKey.getStatusCode()==200){
            authResponse = PaywayAuthResponseWrapper.parse(responseKey.getBody());
            if(authResponse.merchantId == gateway.Optional_Key_1__c){
                returnValue = 'valid';
            }else{
                returnValue = MessageHandler.merchantInvalidMessage;
            }
        }
        else if(responseKey.getStatusCode() == 404){
            returnValue = MessageHandler.merchantInvalidMessage;
        }
        else if(responseKey.getStatusCode() == 401){
            returnValue = MessageHandler.authFailedSecretKey;
        }
        else{
            if(PaywayHelper.getPaymentStatusMessage(String.valueOf(responseKey.getStatusCode())) != null){
                returnValue = MessageHandler.authFailed+''+PaywayHelper.getPaymentStatusMessage(String.valueOf(responseKey.getStatusCode()));
            }else{
                returnValue = MessageHandler.wentWrongCatchMessage;
            }
        }
        return returnValue;
    }
    
    
    /*************Method for processing onetimeTransaction***************************************/ 
    public static TransactionWrapper performOneTimePayment(TransactionWrapper transactionReq){
        
        HTTPResponse transactionresponse = PaywayManager.hitEndpoint(PAYWAY_TRANSACTION_URL, 'POST', Paywaygateway.Client_Key__c, transactionReq.transactionPayload);
        transactionReq.httpResponseStatus = transactionresponse.getStatus();
        transactionReq.transactionResponseCode = String.valueOf(transactionresponse.getStatusCode());
        if(transactionresponse.getStatusCode() == 422 || transactionresponse.getStatusCode() == 201 || transactionresponse.getStatus() == 'Created'){
            transactionReq.transResponse = transactionresponse.getBody();
        } else{ 
            if(PaywayHelper.getPaymentStatusMessage(String.valueOf(transactionresponse.getStatusCode())) != null){
                transactionReq.responseText = PaywayHelper.getPaymentStatusMessage(String.valueOf(transactionresponse.getStatusCode()));
            } else{
                transactionReq.responseText =+ transactionresponse.getStatusCode()+' Something went wrong due to '+ transactionresponse.getStatus()+'. Please refresh and try again';
            }
        }
        
        Q_Charge__Payment_Log__c log = new Q_Charge__Payment_Log__c();
        if(Schema.sObjectType.Q_Charge__Payment_Log__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.processing_Record_ID__c.isCreateable() 
        && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.Action__c.isCreateable() 
        && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.End_Point__c.isCreateable() && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.Payload__c.isCreateable() 
        && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.Request_Type__c.isCreateable() && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.HTTP_Response_Code__c.isCreateable() 
        && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.HTTP_Response__c.isCreateable() && Schema.sObjectType.Q_Charge__Payment_Log__c.fields.Q_Charge__Payment_Parameter_1__c.isCreateable())
        {
            log.Amount__c = transactionReq.amount;
            log.processing_Record_ID__c = transactionReq.sfProcessingId;
            log.Transaction_Status__c = transactionresponse.getStatus();
            log.Action__c = transactionReq.actiontype;
            log.End_Point__c = PAYWAY_TRANSACTION_URL;
            log.Payload__c = transactionReq.transactionPayload ; 
            log.Q_Charge__Charge_Type__c = transactionReq.actiontype;
            log.Request_Type__c = 'POST';
            log.HTTP_Response_Code__c = string.valueof(transactionresponse.getStatusCode());
            log.HTTP_Response__c =transactionresponse.getBody();   //String.valueof(transactionresponse);
            log.Q_Charge__Payment_Parameter_1__c = transactionReq.encodedCustomerNumber;
            log.Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD;
            
        }else{
            throw new UTILPermission.PermsException('Q_Charge__Payment_Log__c','Amount__c,processing_Record_ID__c,Transaction_Status__c,Action__c,End_Point__c,Payload__c,Request_Type__c,HTTP_Response_Code__c,HTTP_Response__c,Q_Charge__Payment_Parameter_1__c,','Create');
        }
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        return transactionReq;
    }
    
    /*************Method for processing Recurring payment ***************************************/ 
    public static RecurringWrapper performRecurringPayment(RecurringWrapper recurringRequest ){
        
        HTTPResponse transactionresponse = PaywayManager.hitEndpoint(PAYWAY_CUSTOMER_URL, 'POST', Paywaygateway.Client_Key__c, recurringRequest.transactionPayload );
        recurringRequest.httpResponseStatus = transactionresponse.getStatus();
        recurringRequest.httpResponseStatuscode = transactionresponse.getStatusCode();
        
        if(transactionresponse.getStatus() == 'Created' || transactionresponse.getStatusCode() == 422){
            recurringRequest.recurringResponse = transactionresponse.getBody();
            if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Payment_Parameter_2__c = recurringRequest.transactionreference, Q_Charge__Frequency__c = recurringRequest.instalPeriod, Q_Charge__Charge_Type__c = 'Recurring',Amount__c = recurringRequest.amount,Transaction_Status__c = transactionresponse.getStatus(),processing_Record_ID__c = recurringRequest.sfProcessingId, Action__c = MessageHandler.processPayment(UTILGateway.PAYWAYWORD.capitalize(),UTILGateway.RECURRINGKEYWORD), End_Point__c = PAYWAY_CUSTOMER_URL,Payload__c = recurringRequest.transactionPayload ,Request_Type__c = 'POST',HTTP_Response_Code__c = string.valueof(transactionresponse.getStatusCode()), HTTP_Response__c = String.valueof(transactionresponse))));
            }
        }
        return recurringRequest;
    }
    
    /*********************** Get all payments of a Recurring Customer ********************************/
    public static RecurringWrapper getTransactionRP(String customerNumber){
        
        RecurringWrapper recurringPaymentsResp = new RecurringWrapper();
        HTTPResponse responseKey = hitEndpoint(PW_CUSTOMER_TRANSACTION_URL+''+customerNumber,'GET',paywaygateway.Client_Key__c, null);
        
        recurringPaymentsResp.httpResponseStatus = responseKey.getStatus();
        recurringPaymentsResp.httpResponseStatuscode = responseKey.getStatusCode();
        if(responseKey.getStatusCode() == 200 || responseKey.getStatusCode() == 422 || responseKey.getStatus() == 'OK'){
            recurringPaymentsResp.recurringResponse  = responseKey.getBody();
        }
        
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c='Recurring',End_Point__c = PW_CUSTOMER_TRANSACTION_URL,Request_Type__c = 'GET',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.fetchRecurringPayments,Transaction_Status__c=responseKey.getStatus(),HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = String.valueof(responseKey))));
        }
        
        return recurringPaymentsResp;
    }
    
    /*********************** Get the Transaction details of a payment of a recurring payment ********************************/
    public static TransactionWrapper getTransaction(TransactionWrapper rpTransactionDetails){ 
        
        HTTPResponse transactionresponse = PaywayManager.hitEndpoint(PAYWAY_TRANSACTION_URL+'/'+rpTransactionDetails.transactionId, 'GET', Paywaygateway.Client_Key__c, null );
        rpTransactionDetails.httpResponseStatus = transactionresponse.getStatus();
        rpTransactionDetails.transactionResponseCode = String.valueOf(transactionresponse.getStatusCode());
        
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c='Recurring', End_Point__c = PAYWAY_TRANSACTION_URL,Request_Type__c = 'GET',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.fetchSingleRPTransaction,Transaction_Status__c=transactionresponse.getStatus(),HTTP_Response_Code__c =String.valueOf(transactionresponse.getStatusCode()),HTTP_Response__c = String.valueof(transactionresponse),Q_Charge__Payment_Parameter_1__c = UTILGateway.encodeCustomerKeys(rpTransactionDetails.customerNumber))));
        }
        if(transactionresponse.getStatus() =='OK' || transactionresponse.getStatusCode() == 200 || transactionresponse.getStatusCode() == 422){
            rpTransactionDetails.transResponse = transactionresponse.getBody();   
        }
        return rpTransactionDetails;
    }
    
    /*********************** Pause the schedule of customer if card details are wrong ********************************/
    public static String cancelRecurringPayment(String customerNumber){
        
        String returnValue=''; 
        String payload = 'stopped='+EncodingUtil.urlEncode('true', 'UTF-8');
        HTTPResponse responseKey = hitEndpoint(PAYWAY_CUSTOMER_URL+'/'+customerNumber+'/payment-setup','PATCH',paywaygateway.Client_Key__c, payload); 
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c = 'Recurring',End_Point__c = PAYWAY_CUSTOMER_URL+'{CustomerNumber}'+'/payment-setup',Request_Type__c = 'PATCH',Transaction_Status__c = responseKey.getStatus(),Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.inativeCustomer, HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = String.valueof(responseKey), Q_Charge__Payment_Parameter_1__c = UTILGateway.encodeCustomerKeys(customerNumber) )));  
        }
        if(responseKey.getStatus() == 'OK' || responseKey.getStatusCode() == 200){
            returnValue = 'Cancelled';
        }else{
            returnValue = PaywayHelper.getPaymentStatusMessage(String.valueOf(responseKey.getStatusCode()));
        }
        return returnValue;
    }
    
    /*********************** Update Card details of the Customer ********************************/
    public static HTTPResponse updateCardDetails(String customerNumber, String payload){ 
        
        HTTPResponse responseKey = hitEndpoint(PAYWAY_CUSTOMER_URL+'/'+customerNumber+'/payment-setup','PUT',paywaygateway.Client_Key__c, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c = 'Recurring', End_Point__c = PW_CUSTOMER_TRANSACTION_URL,Transaction_Status__c = responseKey.getStatus(),Request_Type__c = 'GET',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.updateCardDetails,HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = String.valueof(responseKey), Q_Charge__Payment_Parameter_1__c = UTILGateway.encodeCustomerKeys(customerNumber) )));
        }
        return responseKey;
    }
    
    /*********************** retry schedule of the Customer ********************************/
    public static HTTPResponse updateRecurringPayment(String customerNumber, String payload){ 
        
        HTTPResponse responseKey = hitEndpoint(PAYWAY_CUSTOMER_URL+'/'+customerNumber+'/schedule','PUT',paywaygateway.Client_Key__c, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c = 'Recurring',End_Point__c = PW_CUSTOMER_TRANSACTION_URL,Transaction_Status__c = responseKey.getStatus(),Request_Type__c = 'GET',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.updateRPDetails,HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = String.valueof(responseKey), Q_Charge__Payment_Parameter_1__c = UTILGateway.encodeCustomerKeys(customerNumber) )));
        }
        return responseKey;
    }
    
    /*********************** Fetch Customer and schedule details ********************************/
    public static HTTPResponse getScheduleDetails(String customerNumber){ 
        
        HTTPResponse customerResponse = hitEndpoint(PAYWAY_CUSTOMER_URL+'/'+customerNumber , 'GET',paywaygateway.Client_Key__c, null);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c = 'Recurring',End_Point__c = PW_CUSTOMER_TRANSACTION_URL,Request_Type__c = 'GET',Transaction_Status__c = customerResponse.getStatus(),Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.fetchRPDetails, HTTP_Response_Code__c = String.valueOf(customerResponse.getStatusCode()),HTTP_Response__c = String.valueof(customerResponse), Q_Charge__Payment_Parameter_1__c = UTILGateway.encodeCustomerKeys(customerNumber))));
        }
        return customerResponse;
    }
    
    /*******************Method to perform refund*********************/
    public static TransactionWrapper getRefund(TransactionWrapper refundrequest){
        
        String payload = PaywayHelper.createOneTimePayLoad(refundrequest);
        HttpResponse refundResponse = hitEndpoint(PAYWAY_TRANSACTION_URL, 'POST', Paywaygateway.Client_Key__c, payload);
        if(refundResponse.getStatus() == 'Created'){
            refundrequest.transResponse = refundResponse.getBody();
        }else{
            refundrequest.errorResponse = refundResponse.getBody();
        }
        refundrequest.httpResponseStatus = refundResponse.getStatus();
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__Gateway_Name__c = UTILGateway.PAYWAYWORD,Q_Charge__Charge_Type__c = 'Recurring',Transaction_Status__c = refundResponse.getStatus(),Amount__c = refundrequest.amount,End_Point__c = PAYWAY_TRANSACTION_URL,Request_Type__c = 'POST',Action__c = UTILGateway.PAYWAYWORD.capitalize() + MessageHandler.refundAction, HTTP_Response_Code__c = String.valueOf(refundResponse.getStatusCode()),HTTP_Response__c = String.valueof(refundResponse), Q_Charge__Payment_Parameter_1__c = '')));//refundrequest.encodedCustomerNumber
        }
        return refundrequest;
    }
    
    
    
    /************* HTTP PayWay Generic methods ***************************************/ 
    public Static HTTPResponse hitEndpoint(String endPointURL, String method, String paywayAPIKEY, String payLoad){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPointURL);
        request.setMethod(method);  
        if(payLoad != null){
            request.setBody(payLoad);
            request.setHeader('Content-Type','application/x-www-form-urlencoded');
        }else{
            request.setHeader('Accept','application/json');
        }      
        request.setHeader('Authorization', 'Basic '+EncodingUtil.base64Encode(Blob.valueOF(paywayAPIKEY))); 
        
        request.setTimeout(120000); 
        return new Http().send(request);
    }
    
    /*************************** method for getting update card details URL ***************************/
    public static RecurringWrapper requestUpdateCardDetails(RecurringWrapper req){
        req.status=false;
        if(req.transactionreference==null){
            req.errorResponse=MessageHandler.wentWrongCatchMessage;
            return req;
        }
        req.status=true;
        req.processingLink='/apex/Q_Charge__PaywayUpdateCard?reference='+req.transactionreference;   
        return req;     
    }
}