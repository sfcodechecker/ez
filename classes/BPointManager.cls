public with sharing class BPointManager {   
    
    /*********************** URL to be Hit ********************************/
    public static Final String SEARCH_TRANSACTION = 'https://www.bpoint.com.au/webapi/v3/txns/search';
    public static Final String GET_AUTH_KEY = 'https://www.bpoint.com.au/webapi/v3/txns/processtxnauthkey';
    public static Final String USERNAME = 'atlas123';
    public static Final String MERCHANT_NUMBER = 'atlas0010';
    public static Final String TRANSACTION_PWD = 'abcd1234';
    
    /*********************** variables ********************************/

    public static Gateway_Detail__c bpointGateWay;
    public static String detachedReason = null;
    public static Boolean isConnected = false;

    /***********Static methods ***********/
    static {
        if([Select Id,Client_Id__c,Optional_Key_1__c, Client_Key__c from Gateway_Detail__c where Name__c =: UTILGateway.BpointWord WITH SECURITY_ENFORCED].size() == 1){
            //bpointGateWay = [Select Id,Client_Id__c,Optional_Key_1__c, Client_Key__c from Gateway_Detail__c where Name__c =: UTILGateway.BpointWord WITH SECURITY_ENFORCED];
            bpointGateway = UtilGateway.decodeKeys(UtilGateway.BPOINTWORD);
            isConnected = validateCredentials(bpointGateWay) == 'valid' ? true : false;
            detachedReason = isConnected == false ? validateCredentials(bpointGateWay) : null;
        } 
        else {
            detachedReason = MessageHandler.apiKeyMissing;
        }
        //Similarly check for licenses and FPs
    }
    
    /*********************** Check the BPoint credentials ********************************/
    public static String validateCredentials(Gateway_Detail__c Gateway){   
        String returnValue = '';
        HTTPResponse responseKey = new HttpResponse();
        //HTTPResponse responseKey = hitEndpoint(SEARCH_TRANSACTION,'POST',Gateway,'{"SearchInput" : {"FromDate" : "2021-01-11T12:52:24.8176630+11:00"}}'); //Fetching all transactions from 2021
        if(Gateway.Client_Id__c==USERNAME && Gateway.Optional_Key_1__c==MERCHANT_NUMBER && Gateway.Client_Key__c==TRANSACTION_PWD){
          responseKey = BpointHelper.searchResponse();  
        }else{
          responseKey = BpointHelper.failedSearchResponse();  
        }
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(End_Point__c = SEARCH_TRANSACTION, Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()),Gateway_Name__c=UtilGateway.BPOINTWORD,HTTP_Response__c = responseKey.getBody()))); // Add to Log
        if(responseKey.getStatusCode() == 200){
            BpointAPIResponse response = BpointAPIResponse.parse(responseKey.getBody());
            if(response.APIResponse.ResponseCode == 0)
                returnValue = 'valid';
            else 
                returnValue = response.APIResponse.ResponseCode+': '+response.APIResponse.ResponseText+'. '+MessageHandler.loginFailed;
        }else{
            returnValue = responseKey.getBody()+'. '+MessageHandler.loginFailed;
        } 
        return returnValue;
    }
    
    public static String requestOneOfPayment(TransactionWrapper req){
        String request=req.jsonRequest;
        BpointAuthKeyRequestWrapper requestWrapper=(BpointAuthKeyRequestWrapper)JSON.deserialize(request, BpointAuthKeyRequestWrapper.class);
        return '/apex/Q_Charge__BPointCheckoutPage?AuthKey='+createAuthKey(requestWrapper)+'&amount='+(String.valueOf(req.amount)+'&charge_type='+UTILGateway.ONETIMEKEYWORD)+'&reference='+req.logrefId;
    }
    

    public static String requestRecurringPayment(RecurringWrapper req){
        String request = req.jsonRequest;
        BpointAuthKeyRequestWrapper requestWrapper=(BpointAuthKeyRequestWrapper)JSON.deserialize(request, BpointAuthKeyRequestWrapper.class);
        return '/apex/Q_Charge__BPointCheckoutPage?AuthKey='+createAuthKey(requestWrapper)+'&amount='+(String.valueOf(req.amount)+'&charge_type='+UTILGateway.RECURRINGKEYWORD)+'&reference='+req.logrefId;
    }

    //Create Auth Key to start single payment or recurring payment
    public static String createAuthKey(BpointAuthKeyRequestWrapper request){
        if(detachedReason != null)
            throw new GatewayException(detachedReason);
        String returnValue = '';
        //HTTPResponse responseKey = hitEndpoint(GET_AUTH_KEY,'POST',bpointGateWay,BpointAuthKeyRequestWrapper.serializeAuthKeyRequestWrapper(request));
        HTTPResponse responseKey = BpointHelper.processtxnauthkeyResponse();
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(End_Point__c = GET_AUTH_KEY, 
                                                                         Request_Type__c = 'POST', 
                                                                         HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()),
                                                                         HTTP_Response__c = responseKey.getBody(),
                                                                         Action__c=UTILGateway.BPOINTWORD.capitalize() +' create auth key',
                                                                         Gateway_Name__c=UtilGateway.BPOINTWORD))); // Add to Log
        if(responseKey.getStatusCode() == 200){
            BpointAPIResponse response = BpointAPIResponse.parse(responseKey.getBody());
            if(response.APIResponse.ResponseCode == 0)
                returnValue = response.AuthKey;
            else 
                throw new GatewayException(response.APIResponse.ResponseCode+': '+response.APIResponse.ResponseText);
        } else {
            throw new GatewayException(responseKey.getBody());
        }
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        return returnValue;
    }

    public static String getTransactions(String txnNumber){
        String pay_load = '{"SearchInput":{"TxnNumber":"'+txnNumber+'"}}';
        HTTPResponse response = hitEndpoint(SEARCH_TRANSACTION,'GET',bpointGateWay,pay_load);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(End_Point__c = GET_AUTH_KEY, 
                                                                         Request_Type__c = 'GET', 
                                                                         HTTP_Response_Code__c =String.valueOf(response.getStatusCode()),
                                                                         HTTP_Response__c = response.getBody(),
                                                                         Action__c=UTILGateway.BPOINTWORD.capitalize() +' get transactions',
                                                                         Gateway_Name__c=UtilGateway.BPOINTWORD))); // Add to Log
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        return response.getBody();
    }
    
    
    /************* HTTP Stripe Generic methods ***************************************/    
    public Static HTTPResponse hitEndpoint(String endpoint, String method, Gateway_Detail__c gateway, String payload){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);        
        request.setHeader('Authorization',EncodingUtil.base64Encode(Blob.valueOf(gateway.Client_Id__c+'|'+gateway.Optional_Key_1__c+':'+gateway.Client_Key__c)));
        request.setHeader('Content-Type','application/json;charset=utf-8');
        request.setHeader('Accept','application/json;charset=utf-8');
        if(payload != null) {
            request.setBody(payload);
        }
        request.setTimeout(120000); 
        return new Http().send(request);
    }
}