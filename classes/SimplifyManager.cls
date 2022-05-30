public with sharing class SimplifyManager {
    
    public class SubscriptionPayload{
        public String customer;
        public SimplifyCustomerWrapper customerObj;
        public String frequency;
        public String frequencyPeriod;
        public String amount;
        public String name;
        
        
    }
    /*public class SimplifyPaymentWrapper{
        public String id;
        public String paymentStatus;
        public String paymentDate;
        public String amount;
        public String declineReason;
        public String currencySimplify='AUD';
        public String description;
        public String reference;
        public String token;
        public String customer;
        public SimplifyCustomerWrapper customerObject;
        public String errorResponse;
        
    }*/
    
    
    
    
    
    /*********************** Simplify URLS ********************************/
    public static Final String OAUTH_BASE_URL           = 'https://www.simplify.com/commerce/oauth'; 
    public static Final String SANDBOX_URL           = 'https://sandbox.simplify.com/v1/api/';
    public static Final String PROD_URL           = 'https://api.simplify.com/v1/api/';
    public static Final String HostedPage_Endpoint                 =  'https://www.simplify.com/commerce/simplify.pay.js';
    
    /*********************** Simplify Sandbox Keys - This will be moved to custom setting  ********************************/
    public static Final String SB_PUBLIC_KEY            = 'sbpb_ZThkNjQ3NDItZGM1OC00MThiLWFhY2ItM2Q3ZTViYzM5MzI0'; // sandbox public key from Atlas Simplify app
    public static Final String SB_PRIVATE_KEY           = 'sq/E+jHsUxLTeoXPaa22WqveBFuq6+slDJ+/bHqNebB5YFFQL0ODSXAOkNtXTToq'; // sandbox private key from Atlas Simplify app
    public static Final String SB_REDIRECT_URL          = 'https://business-business-9482-dev-ed.lightning.force.com//apex/SimplifyAuth'; // sandbox redirect URL from Atlas Simplify app
    public static final String SB_APIKey_PK       = 'sbpb_Y2EyMzVjZjItNGJlOC00ZjU1LTgxNzEtNmUxZmYzZGIzZTJi';
    public static final String SB_APIKey_SK       = 'tYHzqxuY7NGwWmdFoOJSYGhApkv/O9yQipehFFTtwjR5YFFQL0ODSXAOkNtXTToq';
   

    /*********************** Variables for Authentication  ********************************/
    public static Final String JWS_ALGORITHM            = 'HS256';
    public static Final String JWS_TYPE                 = 'JWS';
    public static Final String JWS_HDR_URI              = 'api.simplifycommerce.com/uri';
    public static Final String JWS_HDR_TIMESTAMP        = 'api.simplifycommerce.com/timestamp';
    public static Final String JWS_HDR_NONCE            = 'api.simplifycommerce.com/nonce';
    public static Final String JWS_HDR_TOKEN            = 'api.simplifycommerce.com/token';
    
    
    public static Gateway_Detail__c SimplifyGateway;
    public static String endpoint=null; 
    public static Boolean isConnected=false;
    public static String detachedReason=null;
    public static FINAL Integer MilliSecInDay = 86400000;

    /***********Static methods ***********/
    static {
        try{
            if([Select Id  from Gateway_Detail__c where Name__c = :UTILGateway.SIMPLIFYWORD WITH SECURITY_ENFORCED].size() == 1){
                SimplifyGateway = UTILGateway.decodeKeys(UTILGateway.SIMPLIFYWORD);
                String response=validateCredentials(SimplifyGateway,false);
                isConnected=(response=='valid')?true:false;
                detachedReason=(response!='valid')?response:null;
            } else {
                detachedReason = MessageHandler.apiKeyMissing;
            } 
        }catch(Exception ex){
            detachedReason = ex.getMessage();
        }
        
        
        
        //Similarly check for licenses and FPs
    }
    
    /*********************** Authenticate simplify credentials *******************************/
  /*  public static String getAuthorizationCode(String state) {
        return OAUTH_BASE_URL + '/authorize?response_type=code&scope=full&client_id=' + SB_PUBLIC_KEY + '&state='+state;
    }*/
    
    // code will be returned from Simplify server
  /*  public static Map<Boolean, String> getAccessCode(String code) {
        String url = OAUTH_BASE_URL +'/token';
        String props = 'code='+code+'&redirect_uri='+SB_REDIRECT_URL+'&grant_type=authorization_code';
        HttpResponse response = request(url,'POST',props);
        if(response.getStatusCode() == 200){
            //Store Access code and other information
            return new Map<Boolean,String>{true => response.getBody()};
        } else {
            return new Map<Boolean,String>{false => ''}; 
        }
    }*/
    
    /***********Method to use to get access token using refresh token***************/
  /*  public static Map<Boolean,String> getAccessTokenUsingRefreshToken(String refreshToken){
        String endpoint=OAUTH_BASE_URL+'/token';
        String props = 'refresh_token='+refreshToken+'&grant_type=refresh_token';
        HttpResponse response = request(endpoint,'POST',props);
        if(response.getStatusCode()==200){
            return new Map<Boolean,String>{true=>response.getBody()};
        }else{
            return new Map<Boolean,String>{false=>''};
        }
    }*/
    
    /**************Method to make a request to the gateway using Simplify app keys************ */
   /* public static HttpResponse request(String url, String method, String payload){
        //Building Header
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('typ', JWS_TYPE);
        header.writeStringField('alg', JWS_ALGORITHM);
        header.writeStringField('kid', SB_PUBLIC_KEY);
        header.writeStringField(JWS_HDR_URI, url);
        header.writeStringField(JWS_HDR_TIMESTAMP, String.valueOf(((DateTime.now()).getTime())/1000 + '000'));
        header.writeStringField(JWS_HDR_NONCE, String.valueOf(Crypto.getRandomInteger()));
        header.writeEndObject();
        String jwt = base64URLencode(Blob.valueOf(header.getAsString()));
        
        if(method == 'POST' || method == 'PUT'){
            String body = base64URLencode(Blob.valueOf(payload));
            jwt += '.' + body;
        }
        
        Blob key = EncodingUtil.base64Decode(SB_PRIVATE_KEY);
        Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
        jwt += '.' + base64URLencode(signature);  
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod(method);        
        request.setHeader('Content-Type','application/json');
        request.setHeader('Accept','application/json');
        request.setHeader('User-Agent','ACPL::EzyCharge');
        if(method == 'POST' || method == 'PUT'){
            request.setBody(jwt);
        } else {
            request.setHeader('Authorization','JWS '+jwt);
        }
        request.setTimeout(120000); 
        return  new Http().send(request);
    }
    */
    /***********Method to make requests to the gateway using Simplify api keys*****************/
    public static HttpResponse apiRequest(String url, String method, String payload,String publicKey,String privateKey){
        //Building Header
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('typ', JWS_TYPE);
        header.writeStringField('alg', JWS_ALGORITHM);
        header.writeStringField('kid', publicKey);
        header.writeStringField(JWS_HDR_URI, url);
        header.writeStringField(JWS_HDR_TIMESTAMP, String.valueOf(((DateTime.now()).getTime())/1000 + '000'));
        header.writeStringField(JWS_HDR_NONCE, String.valueOf(Crypto.getRandomInteger()));
        header.writeEndObject();
        String jwt = base64URLencode(Blob.valueOf(header.getAsString()));
        
        if(method == 'POST' || method == 'PUT'){
            String body = base64URLencode(Blob.valueOf(payload));
            jwt += '.' + body;
        }else{
            jwt+= '.' + '';
        }
        
        Blob key = EncodingUtil.base64Decode(privateKey);
        Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
        jwt += '.' + base64URLencode(signature);  
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod(method);    
        request.setHeader('Content-Type','application/json');    
        request.setHeader('Accept','application/json');
        request.setHeader('User-Agent','ACPL::EzyCharge');
        if(method == 'POST' || method == 'PUT'){
            request.setBody(jwt);
        } else {
            request.setHeader('Authorization','JWS '+jwt);
            
        }
        request.setTimeout(120000);
        return  new Http().send(request);
    }    
    
    /*******Method to encode url***********/
    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        output = output.replace('=', '');
        return output;
    }
    
    
    
    /*********************** Store simplify auth code ********************************/
    public static String storeAuthCode(String authcode){
        /*String returnValue = '';
        current_gateway = new Gateway_Detail__c(Authorisation_Code__c = authcode, Name__c = 'simplify');
        UTILGateway.encodeKeys(current_gateway);
        Database.UpsertResult[] res = Database.upsert(new List<Gateway_Detail__c>{current_gateway}, Gateway_Detail__c.Name__c, true);
        Payment_Log__c Paymentlog = new Payment_Log__c();
        Paymentlog.End_Point__c = EndPointURL;
        Paymentlog.Request_Type__c = 'GET';
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(Paymentlog)); // Add to Log
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        return returnValue;*/
        return null;
    }
    
    /************* Check SimplifyGateway credentials ******************/
    public static String validateCredentials(Gateway_Detail__c Gateway,Boolean createLog){   
        String endpoint=(Gateway.isSandbox__c)?SANDBOX_URL:PROD_URL;
        String payload='max=30';
        endpoint+='payment/?'+payload;
        HttpResponse response=apiRequest(endpoint, 'GET', '',Gateway.Q_Charge__HostedPayments_PublicKey__c,Gateway.Q_Charge__HostedPayments_PrivateKey__c);
        if(createLog){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c= UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.checkCredential,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
        }

        if(response.getStatusCode()==200){
            return 'valid';
        }else{
            String message = errorResponse(response.getBody());
            return message;
        }
    }
    
    /**********Not in use*************/
    public static String checkCredentials(Gateway_Detail__c gateway){
        return 'valid';
    }
    
    /**********Not in use*************/
    public static String CheckExistingCredentails(){   
        return 'valid';
    }
    
    
    /*********** accessing simplify hosted vf page **********************/
    public static TransactionWrapper requestOneTime(TransactionWrapper req){
        
        req.status=false;
        if(req.sfProcessingId==null || req.amount==null){
            req.errorResponse=MessageHandler.wentWrongCatchMessage;
            return req;
        }else if(req.amount<1){
            req.errorResponse=MessageHandler.amountBelowOneDoller;
            return req;
        }else if(req.amount > 500000){
            req.errorResponse=MessageHandler.amountMoreThanLimit;
            return req;
        }
        req.processingLink='/apex/Q_Charge__SimplifyCheckout?reference='+req.logrefId;
        req.status=true;
        return req;
    }
    
    /*********************** Store details after complete transaction ********************************/
    public static void checkOutComplete(String endpointURL, String recordId, String amount, String ReceiptId, String paymentStatus){
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(End_Point__c=endpointURL, Request_Type__c='GET', Transaction_Id__c=ReceiptId, Transaction_Status__c=paymentStatus, Amount__c=Decimal.valueOf(amount), Processing_Record_Id__c=recordId,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
        UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
    }
    
    /*************accessing Simplify hosted vf page***************** */
    public static RecurringWrapper requestRecurringPayment(RecurringWrapper req){
        
        req.status=false;
        if(req.amount ==null ||req.sfProcessingId==null || req.startDate==null || req.logrefId==null){
            req.errorResponse=MessageHandler.wentWrongCatchMessage;
            return req;
        }else if(req.amount<0.5){
            req.errorResponse=MessageHandler.amountLessThan50Cent;
            return req;
        }else if(req.amount>10000){
            req.errorResponse=MessageHandler.amountMoreThanLimit;
            return req;
        }else if(req.startDate < Date.today()){
            req.errorResponse=MessageHandler.prevStartDate;
            return req;
        }
        req.processingLink='/apex/Q_Charge__SimplifyCheckout?reference='+req.logrefId;
        req.status=true;
        return req;
    }
   
    public static RecurringWrapper createSimplifyPlan(RecurringWrapper req){ 
        req.status=false;
        if(req.amount==null || req.instalPeriod==null || req.trialPeriod ==null ){
            req.errorResponse=MessageHandler.wentWrongCatchMessage;
            return req;
        }
        Map<String,String> planMap=new Map<String,String>{'amount'=>String.valueOf(Integer.valueOf(req.amount*100)),'frequency'=>req.instalPeriod.toUpperCase(),'frequencyPeriod'=>'1','trialPeriod'=>req.trialPeriod,'currency'=>'AUD','name'=>req.instalPeriod};
        if(req.trialPeriod!='NONE'){
            planMap.put('trialPeriodQuantity',String.valueOf(req.trialDays));
        }
        String payload=SimplifyPlanWrapper.createPlanPayload(planMap);
        
        //String payload=planPayload(wrapper);
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'plan/';
        //String urltohit=SB_SANDBOX_URL;
        
        HttpResponse response=apiRequest(endpoint, 'POST', payload,SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c = UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.createPlan,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));
        if(response.getStatusCode()==200){
            req.status=true;
            String body=response.getBody().replace('currency', 'currencySimplify');
            SimplifyPlanWrapper plan=SimplifyPlanWrapper.parse(body);
            req.planId=plan.Id;
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;       
    }
    
    
    /************Method to create customer in gateway**************/
    public static RecurringWrapper createCustomer(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        String payload=SimplifyCustomerWrapper.createCustomerPayload(new Map<String,String>{'name'=>req.name,'email'=>req.email,'reference'=>req.sfProcessingId,'token'=>UTILGateway.decodeCustomerKeys(req.tokenValue)});
        payload=payload.replace('numbers','number');
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'customer/';
        HttpResponse response=apiRequest(endpoint, 'POST', payload,SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.createCustomer,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));

        if(response.getStatusCode()==200){
            req.status=true;
            SimplifyCustomerWrapper validCustomer=(SimplifyCustomerWrapper)JSON.deserialize(response.getBody(), SimplifyCustomerWrapper.class);
            SimplifyCustomerWrapper.Card cardDetails=validCustomer.cards.get(validCustomer.cards.size()-1);
            req.cardDetails=new RecurringWrapper.CardInformation();
            req.cardDetails.CardHolderName=cardDetails.name;
            req.cardDetails.CardNumber=cardDetails.last4;
            req.cardDetails.ExpiryMonth=cardDetails.expMonth;
            req.cardDetails.ExpiryYear=cardDetails.expYear;
            req.customerId=UTILGateway.encodeCustomerKeys(validCustomer.id);
            return req;
        }else{
            req.errorResponse=errorResponse(response.getBody());
            return req; 
        }
    }
    
    /***************Accessing update card vf page********************/
    public static RecurringWrapper getUpdateCardPage(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        if(req.transactionreference!=null){
            req.status=true;
            req.processingLink='/apex/Q_Charge__SimplifyUpdateCard?reference='+req.transactionreference;
        }else{
            req.errorResponse='';
        }
        return req;
    }
    
    /*************Method to update the customer card details***************/
    public static RecurringWrapper updateCardDetails(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        SimplifyCustomerWrapper customer=new SimplifyCustomerWrapper();
        customer.id=UTILGateway.decodeCustomerKeys(req.recurringRequestId).substringBefore('+');
        customer.token=UtilGateway.decodeCustomerKeys(req.tokenValue);
        customer.name=req.name;
        customer.email=req.email;
        String payload=JSON.serialize(customer);
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'customer/';
        HttpResponse response=apiRequest(endpoint, 'PUT', payload,SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.updateCardDetails,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));

        if(response.getStatusCode()==200){
            req.status=true;
            SimplifyCustomerWrapper validCustomer=(SimplifyCustomerWrapper)JSON.deserialize(response.getBody(), SimplifyCustomerWrapper.class);
            SimplifyCustomerWrapper.Card cardDetails=validCustomer.cards.get(0);
            req.cardDetails=new RecurringWrapper.CardInformation();
            req.cardDetails.CardHolderName=cardDetails.name;
            req.cardDetails.CardNumber=cardDetails.last4;
            req.cardDetails.ExpiryMonth=cardDetails.expMonth;
            req.cardDetails.ExpiryYear=cardDetails.expYear;
            
        }else{
            req.errorResponse=errorResponse(response.getBody());
            
        }
        return req;
    }
    
    public static RecurringWrapper createSimplifySubscription(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        
        String payload=SimplifySubscriptionWrapper.createSubscriptionPayload(new Map<String,String>{'customer'=>UtilGateway.decodeCustomerKeys(req.customerId),'plan'=>req.planId});
        //  String payload=SimplifySubscriptionWrapper.createSubscriptionPayload(subscription);
        //payload=payload.replace('customerId', 'customer');
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'subscription/';
        HttpResponse response=apiRequest(endpoint, 'POST', payload,SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c= MessageHandler.processPayment(UTILGateway.SIMPLIFYWORD.capitalize(),UTILGateway.RECURRINGKEYWORD) ,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));

        if(response.getStatusCode()==200){
            String body=response.getBody();
            body=body.replace('customer','customerObj');
            req.status=true;
            SimplifySubscriptionWrapper validSubscription=(SimplifySubscriptionWrapper)JSON.deserialize(body, SimplifySubscriptionWrapper.class);
            req.recurringRequestId=UtilGateway.encodeCustomerKeys(UtilGateway.decodeCustomerKeys(req.customerId)+'+'+validSubscription.id);
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;

    }
    
    /*********Method to find subscription in gateway***********/ 
    public static RecurringWrapper findSubscription(RecurringWrapper req){
        UTILGateway.allowRPUpdate=true;
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'subscription/'+req.recurringRequestId;
        HttpResponse response=apiRequest(endpoint, 'GET', '',SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);

        if(response.getStatusCode()==200){
            req.status=true;
            String body=response.getBody();
            body=body.replace('customer','customerObj');
            req.status=true;
            SimplifySubscriptionWrapper subscription=(SimplifySubscriptionWrapper)JSON.deserialize(body,SimplifySubscriptionWrapper.class );
            req.instalPeriod=subscription.frequency;
            //req.amount=Decimal.valueOf(subscription.amount)/100;
            req.amount=subscription.plan.amount/100;
            req.recurringResponse=response.getBody();
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;
        
    }

    public static RecurringWrapper updateSubscription(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        endpoint = ((SimplifyGateway.isSandbox__c)?SANDBOX_URL:PROD_URL)+'subscription/';
        String payload = SimplifySubscriptionWrapper.createSubscriptionPayload(new Map<String,String>{'id'=>UtilGateway.decodeCustomerKeys(req.recurringRequestId).substringAfter('+'),'plan'=>req.planId});
        HttpResponse response = apiRequest(endpoint, 'PUT', payload, SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c, SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        if(response.getStatusCode()==200){
            req.status=true;
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;
    }
    
    /****************Method to cancel subscription in gateway**************/
    public static  RecurringWrapper cancelRecurringPayment(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'subscription/'+UTILGateway.decodeCustomerKeys(req.recurringRequestId).substringAfter('+');
        HttpResponse response=apiRequest(endpoint, 'DELETE', '',SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.cancelRecPay, Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Request_Type__c='DELETE',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));

        String body=response.getBody();
        body=body.replace('customer','customerObj');
        if(response.getStatusCode()==200){
            req.status=true;
            SimplifySubscriptionWrapper validSubscription=(SimplifySubscriptionWrapper)JSON.deserialize(body, SimplifySubscriptionWrapper.class);
            req.responseMessage=validSubscription.status;
            return req;
        }else{
            req.errorResponse=errorResponse(response.getBody());
            return req;
        }
        
    }

    
    /************Method to create payment in gateway**************/
    public static RecurringWrapper validateCreditCard(RecurringWrapper req){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        req.status=false;
        String payload=SimplifyPaymentWrapper.createPaymentPayload(new Map<String,String>{'customer'=>UtilGateway.decodeCustomerKeys(req.recurringRequestId).substringBefore('+'),'amount'=>String.valueOf(req.refundAmount),'currency'=>'AUD'});
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'payment/';
        HttpResponse response=apiRequest(endpoint, 'POST', payload,SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() + MessageHandler.validateCard, Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=endpoint,Gateway_Name__c=UTILGateway.SIMPLIFYWORD)));

        if(response.getStatusCode()==200){
            String body=response.getBody();
            body=body.replace('customer','customerObj');
            req.status=true;
            req.validationResponse=body;
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;
    }
    
    
    /*********Method to make get requests to the gateway**************/    
    public static TransactionWrapper getTransaction(String objectName, Map<String,String> filters){
        if(!isConnected){
            throw new GatewayException(detachedReason);
        }
        TransactionWrapper responseWrapper=new TransactionWrapper();
        responseWrapper.status=false;
        if((objectName==null || objectName=='') && filters==null){
            responseWrapper.errorResponse=MessageHandler.wentWrongCatchMessage;
        }
        String filter='';
        for(String filterName : filters.keySet()){
            String tempfilter=EncodingUtil.urlEncode('filter['+filterName+']', 'UTF-8')+'='+filters.get(filterName);
            filter+='&'+tempfilter;
        }
        String payload='max=1'+filter;
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+''+objectName.toLowerCase()+'/?'+payload;
        HttpResponse response = apiRequest(endpoint, 'GET', '',SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        String body=response.getBody();
        body=body.replace('list','list_Z');
        if(response.getStatusCode()==200){
            responseWrapper.status=true;
            if(objectName=='invoice'){
                SimplifyInvoiceWrapper validResponse=(SimplifyInvoiceWrapper)JSON.deserialize(body, SimplifyInvoiceWrapper.class);
                if(validResponse.list_Z!=null){
                    for(SimplifyInvoiceWrapper.List_Z payment:validResponse.list_Z){
                        if(payment.payment!=null){
                            responseWrapper.amount=Decimal.valueOf(payment.payment.amount)/100;
                            responseWrapper.transactionId=payment.payment.id;
                            Datetime receivedDT = Datetime.newInstance(payment.payment.paymentDate);
                            responseWrapper.transactionDateTime=Datetime.newInstance(receivedDT.date(),Time.newInstance(0, 0, 0, 0));
                            responseWrapper.responseText=payment.payment.paymentStatus;
                        }else{
                            responseWrapper.amount=Decimal.valueOf(payment.items.get(validResponse.list_Z.indexOf(payment)).amount)*100;
                            responseWrapper.transactionStatus=payment.status;
                            //responseWrapper.transactionDateTime=Datetime.newInstance(payment.dueDate);
                            Datetime receivedDT = Datetime.newInstance(payment.dueDate);
                            responseWrapper.transactionDateTime=Datetime.newInstance(receivedDT.date(),Time.newInstance(0, 0, 0, 0));
                        }
                        responseWrapper.transResponse=JSON.serialize(payment);
                    }
                }
                else{
                    responseWrapper.status=false;
                    responseWrapper.errorResponse=MessageHandler.wentWrongCatchMessage;
                }
                
            }else if(objectName=='payment'){
                SimplifyPaymentWrapper paymentList=SimplifyPaymentWrapper.parse(body);
                if(paymentList.list_Z!=null){
                    for(SimplifyPaymentWrapper.List_Z payment:paymentList.list_Z){
                        responseWrapper.amount=Decimal.valueOf(payment.transactionData.amount)/100; 
                        responseWrapper.transactionId=payment.id;
                        responseWrapper.transactionDateTime=Datetime.newInstance(payment.paymentDate);
                        responseWrapper.responseText=payment.paymentStatus;
                        
                    }
                }
            }
            
        }else{
            responseWrapper.errorResponse=errorResponse(response.getBody());
        }
        return responseWrapper;
    }
    
    /*********Method to get the error response*******/
    public static String errorResponse(String response){
        String returnMsg='';
        SimplifyErrorResponseWrapper errorObject=SimplifyErrorResponseWrapper.parse(response);
        returnMsg='Error code: '+errorObject.error.code+' Error message: '+errorObject.error.message;
        if(errorObject.error.fieldErrors!=null && errorObject.error.fieldErrors.size()>0){
            for(SimplifyErrorResponseWrapper.FieldErrors err : errorObject.error.fieldErrors){
                returnMsg+='Field: ';
                returnMsg+='Code: '+err.code+' Field: '+err.field+' Message: '+err.message;
            }
        }
        
        return returnMsg;
    }
    
    /************Method to perform refund in gateway*************/
    public static RecurringWrapper performRefund(RecurringWrapper req){
        req.status=false;
        SimplifyPaymentWrapper refund= new SimplifyPaymentWrapper();
        refund.amount=String.valueOf(req.amount*100);
        refund.id=req.refundId;
        String payload=JSON.serialize(refund);
        payload=payload.replace('id', 'payment');
        endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'refund/';
        HttpResponse response=apiRequest(endpoint, 'POST', payload,SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        if(response.getStatusCode()==200){
            req.status=true;
            req.paymentResponse=response.getBody();
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;
    }

    public static TransactionWrapper findPayment(TransactionWrapper req){
        req.status=false;
        String endpoint=((SimplifyGateway.Q_Charge__isSandbox__c)?SANDBOX_URL:PROD_URL)+'payment/8qpRgzkj7';//+req.transactionId;
        HttpResponse response=apiRequest(endpoint, 'GET', '',SimplifyGateway.Q_Charge__HostedPayments_PublicKey__c,SimplifyGateway.Q_Charge__HostedPayments_PrivateKey__c);
        if(response.getStatusCode()==200){
            req.status=true;
            String body=response.getBody();
            req.transResponse=body;        
        }else{
            req.errorResponse=errorResponse(response.getBody());
        }
        return req;
    }
    public static String convertDateToUnix(Date ToDate){
        Integer daysBetween = Date.today().daysBetween(ToDate); 
        return String.valueOf(((Datetime.now().getTime() + (daysBetween * MilliSecInDay))));
    }
    
}