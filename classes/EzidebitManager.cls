public with sharing class EzidebitManager {
    
    
    /****************URL to hit ********************/  
    public static final String EziDebitProductionNonPCI='https://api.ezidebit.com.au/v3-5/nonpci';
    public static final String EziDebitProductionPCI='https://api.ezidebit.com.au/v3-5/pci';
    public static final String EziDebitProductionPayment='https://api.ezidebit.com.au/V3-5/public-rest';
    public static final String EziDebitSandboxNonPCI='https://api.demo.ezidebit.com.au/v3-5/nonpci';
    public static final String EziDebitSandboxPCI='https://api.demo.ezidebit.com.au/v3-5/pci';
    public static final String EziDebitSandboxPayment='https://api.demo.ezidebit.com.au/V3-5/public-rest';
    public static final String EziDebitEddrUrlSandbox='https://demo.ezidebit.com.au/webddr/Request.aspx?';
    public static final String EziDebitEddrUrlProd='https://secure.ezidebit.com.au/webddr/Request.aspx?';
    public static final String EziDebitUpdateCardUrlSandbox='https://widget.demo.ezidebit.com.au/account/';
    public static final String EziDebitUpdateCardUrlProd='https://widget.ezidebit.com.au/account/';
    
    
    
    /***************SOAPAction URL****************/
    public static final String envelope='http://schemas.xmlsoap.org/soap/envelope/';
    public static final String pxezidebit='https://px.ezidebit.com.au/';
    public static final String GetCustomerList='https://px.ezidebit.com.au/INonPCIService/GetCustomerList';
    public static final String GetScheduledPayments='https://px.ezidebit.com.au/INonPCIService/GetScheduledPayments';
    public static final String ProcessRealtimeTokenPayment='https://px.ezidebit.com.au/IPCIService/ProcessRealtimeTokenPayment';
    public static final String ProcessRefund='https://px.ezidebit.com.au/INonPCIService/ProcessRefund';
    public static final String ClearSchedule='https://px.ezidebit.com.au/INonPCIService/ClearSchedule';
    public static final String GetPayments='https://px.ezidebit.com.au/INonPCIService/GetPayments';
    public static final String GetCustomerDetails='https://px.ezidebit.com.au/INonPCIService/GetCustomerDetails';
    public static final String ChangeCustomerStatus='https://px.ezidebit.com.au/INonPCIService/ChangeCustomerStatus';
    public static final String GetCustomerAccountDetails='https://px.ezidebit.com.au/IPCIService/GetCustomerAccountDetails';
    public static final String CreateSchedule='https://px.ezidebit.com.au/INonPCIService/CreateSchedule';
    
    /*******variables *******/
    public static Gateway_Detail__c EzidebitGateway;
    public static String detachedReason=null;
    public static Boolean isConnected=false;
    
    
    
    /******static****/
    static {
        try{
            if([Select Id  from Gateway_Detail__c where Name__c = :UTILGateway.EZIDEBITWORD WITH SECURITY_ENFORCED].size() == 1){
                EzidebitGateway = UTILGateway.decodeKeys(UTILGateway.EZIDEBITWORD);
                String result=validateCredentials(EzidebitGateway,false);
                isConnected=(result=='valid')?true:false;
                detachedReason=(result!='valid')?result:null;
            }else {
                detachedReason = MessageHandler.apiKeyMissing;
            }
        }catch(Exception ex){
            detachedReason = MessageHandler.apiKeyMissing+' due to '+ex.getMessage();
        }
        //Similarly check for licenses and FPs
    }
    
    /******************Method to authenticate credentials**********/
    public static String validateCredentials(Gateway_Detail__c Gateway,Boolean createLog)
    {
        if(detachedReason != null && detachedReason != MessageHandler.apiKeyMissing)
        throw new GatewayException(detachedReason);
        String UrlToHit=(Gateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        Gateway.Schedule_Page_URL__c=(Gateway.isSandbox__c)?EziDebitEddrUrlSandbox:EziDebitEddrUrlProd;
        String returnString='';
        String Payload=XMLBodyBuilder('getCustomerList', '', '', '',Gateway.Client_Key__c,'',null,null);            //Only for demo[cent Value as null]
        HttpResponse response=hitEndpointXML(UrlToHit, 'POST', GetCustomerList, Payload);
        if(createLog){
            Payment_Log__c log=new Payment_Log__c();
            if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
                log.End_point__c=UrlToHit;
                log.Http_Response__c=String.valueOf(response);
                log.Http_Response_Code__c=String.valueOf(response.getStatusCode());
                log.Payload__c=Payload;
                log.Request_Type__c='POST';
                log.Gateway_Name__c=UTILGateway.EZIDEBITWORD;
                log.Action__c = UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.checkCredential;
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
            }
            
        }
        if(response.getStatusCode()==200)
        {
            Map<Boolean,String> errorMap=checkErrors(response.getBody());   
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(false)){
                    returnString = errorMap.get(false); 
                }else {
                    returnString='valid';
                }   
            }else{
                returnString = MessageHandler.wentWrongCatchMessage;
            } 
        }
        else {
            returnString = xmlReader(new XmlStreamReader(response.getBody()), 'faultstring');
        } 
        return returnString;
    }
    
    /***************Generic method for XML requests**********/
    public static HttpResponse hitEndpointXML(String endPointUrl,String Method,String SOAPAction,String Payload)
    {
        HttpRequest req=new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod(Method);
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('SOAPAction',SOAPAction);
        if(Payload!=null)
        req.setBody(Payload);
        req.setTimeout(120000);
        return new Http().send(req);
    }
    
    /*******Method to check errors *************/
    public static Map<Boolean,String> checkErrors(String XMLResponse){
        Boolean noErrors=true;
        if(XMLResponse.contains('<!DOCTYPE') || XMLResponse.contains('!ENTITY') || XMLResponse.contains('!ELEMENT')){
            throw new GatewayException('XML Response from the Ezidebit server is not of a valid XML.'); 
        }
        XmlStreamReader reader=new XmlStreamReader(XMLResponse);
        while(reader.hasNext()){
            if(reader.getEventType()==XmlTag.DTD){
                return new Map<Boolean,String>{false=>'XML Response from the Ezidebit server is not of a valid XML.'};
            }
            if(reader.getEventType()==XmlTag.START_ELEMENT){
                if('ErrorMessage'==reader.getLocalName())
                {
                    if('true'==reader.getAttributeValue(null, 'nil')){
                        return new Map<Boolean,String>{noErrors=>null};
                    }else{
                        noErrors=false;
                    }   
                }           
            }
            if(reader.getEventType()==XmlTag.CHARACTERS){
                if(!noErrors){
                    String msg=reader.getText();
                    
                    return new Map<Boolean,String>{noErrors=>msg};
                }
            }     
            reader.next();
        }
        return new Map<Boolean,String>();
    }
    
    
    /*******Method to get the hosted page******/
    public static TransactionWrapper requestOneTimePayment(TransactionWrapper req){
        req.status=false;
        if(req.amount!=null &&  req.sfProcessingId!=null){
            String endPoint=(EzidebitGateway.isSandbox__c) ? EziDebitSandboxPayment : EziDebitProductionPayment;
            req.status=true;
            req.processingLink='/apex/Q_Charge__EzidebitCheckout?reference='+req.logrefId;
        }else{
            req.errorResponse=MessageHandler.wentWrongCatchMessage;
        }
        return req; 
    }
    
    /*********************Method to create a log after checkout**********/
    public static void checkoutComplete(TransactionWrapper wrapper,ReceiptWrapper receipt){
        String serializedWrapper=JSON.serialize(receipt);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.oneTimeCheckoutComplete ,Http_Response__c=JSON.serialize(wrapper),Request_Type__c='GET',Amount__c=wrapper.Amount,Charge_Type__c=wrapper.transactionType,End_Point__c=wrapper.successUrl,Serialized_Record__c=serializedWrapper,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
    }
    
    /*******Method to access the eddr page*********/
    public static RecurringWrapper requestRecurringPayment(RecurringWrapper req){
        req.status=true;
        if(req.amount==null && req.startDate==null && req.sfProcessingId==null && req.recurringRequestId==null && req.instalPeriod==null){
            req.status=false;
            req.errorResponse=MessageHandler.invalidParams;
            return req;
        }
        
        if(EzidebitGateway.Schedule_Page_URL__c==null || EzidebitGateway.Schedule_Page_URL__c.trim().length()<=1)
        {
            req.status=false;
            req.errorResponse=MessageHandler.ezidebitEddr;
            return req;
        }
        req.instalPeriod=handleFrequencies(req.instalPeriod,false);
        String checkDay=Datetime.newInstance(req.startDate.year(),req.startDate.month(),req.startDate.day()).format('EEEE');
        if(req.instalPeriod==null)
        throw new GatewayException('Installment Period not valid');
        //duration=(duration=='Ongoing')?'1':(duration=='Total Amount')?'2':(duration=='Total Payments')?'4':'';  
        if(req.startDate==Date.today()){
            Datetime currentDT=Datetime.now();
            String convertedDT=currentDT.format('yyyy-MM-dd HH:mm:ss a', 'Australia/Brisbane');
            convertedDT=convertedDT.substringAfter(' ');
            List<String> splitConvertedDT=convertedDT.split(':');
            Integer currentTime=Integer.valueOf(splitConvertedDT.get(0));
            Integer currentTimeMinutes=Integer.valueOf(splitConvertedDT.get(1));
            if(currentTime>=15){
                req.status=false;
                req.errorResponse=MessageHandler.ezidebitprocessingTimeProductionRecurring;
                return req;
            }
        }else if(req.startDate<Date.today()){
            req.status=false;
            req.errorResponse=MessageHandler.prevStartDate;
            return req;
        }else if(checkDay=='Saturday' || checkDay=='Sunday'){
            req.status=false;
            req.errorResponse=MessageHandler.ezidebitWeekendSetup;
            return req;
        }
        
        if(req.status){
            req.processingLink = '/apex/Q_Charge__EzidebitRPCheckout?reference='+req.recurringRequestId;
        }
        return req;
    }
    
    /*******************Helper method to fetch the scheduled transactions*********/
    public static RecurringWrapper getScheduledTransactions(RecurringWrapper wrapper){
        wrapper.transactionList=getTransactionsRP(wrapper.recurringRequestId);
        return wrapper;
    }
    
    /*******************[GLOBAL]Method to fetch scheduled transactions*****************/
    public static List<TransactionWrapper> getTransactionsRP(String ezidebitRefId){
        Map<Integer,TransactionWrapper> transactionInfoMap=new Map<Integer,TransactionWrapper>();
        List<TransactionWrapper> wrapperList=new List<TransactionWrapper>();
        String payload=XMLBodyBuilder('getScheduledPayments', ezidebitRefId, '', '',EzidebitGateway.Client_Key__c,'',null,null);        //Only for demo [cent value is null]
        String urlTohit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        HttpResponse response=hitEndpointXML(urlTohit, 'POST', GetScheduledPayments, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.fetchRecurringPayments ,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=UrlToHit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }
        Map<Boolean,String> errorMap=checkErrors(response.getBody());
        if(response.getStatusCode()==200){
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    wrapperList=readFetchedPayments(response.getBody());
                }else{
                    throw new GatewayException(errorMap.get(false));
                }
            }else{
                throw new GatewayException(MessageHandler.wentWrongCatchMessage);
            }
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()), 'faultstring'));
        }
        return wrapperList;
    }
    
    /*****************Parse the response of Scheduled Payments *********/
    public static List<TransactionWrapper> readFetchedPayments(String response){
        List<TransactionWrapper> wrapperList=new List<TransactionWrapper>();
        XmlStreamReader reader=new XmlStreamReader(response);
        TransactionWrapper wrapper;
        while(reader.hasNext()){
            if(reader.getEventType()==XmlTag.START_ELEMENT){
                if('ScheduledPayment'==reader.getLocalName()){
                    wrapper=new TransactionWrapper();
                    wrapper.amount=Decimal.valueOf(xmlReader(reader,'PaymentAmount').trim());
                    String dt=xmlReader(reader, 'PaymentDate');
                    wrapper.transactionDate=Date.valueOf(dt.trim().substringBefore('T'));
                    wrapper.transactionreference=xmlReader(reader,'PaymentReference').trim();
                    wrapperList.add(wrapper);
                }  
            }
            reader.next();
        }
        return wrapperList;
    }
    
    /*********************[GLOBAL]Method to validate Credit Card *******************************/
    public static RecurringWrapper validateCreditCardDetails(RecurringWrapper recurringpaymentdetails){
        String paymentResult='';
        String payload=XMLBodyBuilder('processRealTimeToken', recurringpaymentdetails.recurringRequestId,'', recurringpaymentdetails.name,EzidebitGateway.Client_Key__c,'',null,String.valueOf(recurringpaymentdetails.amount).substringAfter('.'));      //Only for demo[cent value = rp amount]
        String urlToHit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxPCI:EziDebitProductionPCI;
        HttpResponse response=hitEndpointXML(urlToHit, 'POST', ProcessRealtimeTokenPayment, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=recurringpaymentdetails.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.validateCard ,Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }       
        Map<Boolean,String> errorMap=checkErrors(response.getBody());
        if(response.getStatusCode()==200){
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey((true))){
                    paymentResult+=xmlReader(new XmlStreamReader(response.getBody()), 'PaymentResultCode')+' ';
                    paymentResult+=xmlReader(new XmlStreamReader(response.getBody()), 'ExchangePaymentID')+':';
                    paymentResult+=xmlReader(new XmlStreamReader(response.getBody()), 'PaymentResultText');
                }else{
                    paymentResult=errorMap.get(false);
                }
            }else{
                throw new GatewayException(MessageHandler.wentWrongCatchMessage);
            }
            
        }else{
            paymentResult=xmlReader(new XmlStreamReader(response.getBody()), 'faultstring');         
        }
        recurringpaymentdetails.responseMessage=paymentResult;       
        return recurringpaymentdetails;
    }
    
    
    /************Method to handle the frequencies***********/
    public static String handleFrequencies(String frequency,Boolean abbrevation){
        /*Incoming values from api will have abbrevation as true
        For eddr form abbrevation will be false*/
        Map<String,String> EzidebitFrequencies=new Map<String,String>();
        EzidebitFrequencies.put('Weekly','1:W');
        EzidebitFrequencies.put('Fortnightly','2:F');
        EzidebitFrequencies.put('Monthly', '4:M');
        EzidebitFrequencies.put('Every four weeks', '8:4');
        EzidebitFrequencies.put('Quarterly', '16:Q');
        EzidebitFrequencies.put('Half Yearly', '32:H');
        EzidebitFrequencies.put('Yearly', '64:Y');
        if(EzidebitFrequencies.containsKey(frequency) && !abbrevation){
            return EzidebitFrequencies.get(frequency).substringBefore(':');
        }else if(EzidebitFrequencies.containsKey(frequency) && abbrevation){
            return EzidebitFrequencies.get(frequency).substringAfter(':');
        }
        
        for(String name:EzidebitFrequencies.keySet()){
            if((EzidebitFrequencies.get(name).substringBefore(':').trim()==frequency && !abbrevation) || (EzidebitFrequencies.get(name).substringAfter(':').trim()==frequency && abbrevation))
            return name;
        }
        
        return null;
    } 
    
    /********************Generic method to read xml*********************/
    public static String xmlReader(XmlStreamReader reader,String localName){
        Boolean hasResult=false;
        String paymentResult='';
        if(reader.toString().contains('<!DOCTYPE') || reader.toString().contains('<!ENTITY') || reader.toString().contains('<!ELEMENT')){
            throw new GatewayException('XML Response from Ezidebit server is not a valid response.');
        }
        while(reader.hasNext()){
            if(reader.getEventType()==XmlTag.DTD){
                throw new GatewayException('XML Response from Ezidebit server is not a valid response.');
                
            }
            if(reader.getEventType()==XmlTag.START_ELEMENT){
                if(reader.getLocalName()==localName){
                    hasResult=true;
                }
            }
            if(reader.getEventType()==XmlTag.CHARACTERS){
                if(hasResult){
                    paymentResult=reader.getText();
                    hasResult=false;
                    return paymentResult;
                }
            }
            reader.next();
        }
        return paymentResult;
    }
    
    /*********************Method to handle the payment status from Ezidebit********/
    public static String handlePaymentStatus(String status){
        Map<String,String> gatewayStatusMap=new Map<String,String>();
        gatewayStatusMap.put('S', 'SUCCESSFUL');
        gatewayStatusMap.put('P','PENDING');
        gatewayStatusMap.put('W','WAITING');
        gatewayStatusMap.put('F','FATAL DISHONOUR');
        gatewayStatusMap.put('D','DISHONOURED');
        gatewayStatusMap.put('NB','Customer Status changed to Non-Processing Status');
        if(gatewayStatusMap.containsKey(status))
        return gatewayStatusMap.get(status);
        
        return null;
    }
    
    /********************[GLOBAL]Method used to fetch the process payments**************/
    public static void getTransaction(String ezidebitRefId,TransactionWrapper trans){
        String payload=XMLBodyBuilder('getPayments', ezidebitRefId, '','', EzidebitGateway.Client_Key__c,String.valueOf(trans.transactionDateTime.date()),null,null);       //Only for demo[cent value is changed]
        String urltohit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        HttpResponse response = hitEndpointXML(urltohit, 'POST', GetPayments, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=trans.sfProcessingId,Action__c = UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.fetchSingleRPTransaction, Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }
        if(response.getStatusCode()==200){
            // Boolean noErrors=checkErrors(response.getBody());
            Map<Boolean,String> errorMap=checkErrors(response.getBody());
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    String status=handlePaymentStatus(xmlReader(new XmlStreamReader(response.getBody()), 'PaymentStatus').trim());
                    if(status==null){
                        return;
                    }
                    trans.transactionStatus=status;
                    String invoiceId=xmlReader(new XmlStreamReader(response.getBody()), 'InvoiceID');
                    if(invoiceId.trim()!='0'){
                        trans.transactionId=invoiceId.trim();
                    }
                    String dt=xmlReader(new XmlStreamReader(response.getBody()), 'DebitDate');
                    //trans.Transaction_Date__c=Datetime.valueOfGmt(dt.trim().substringBefore('T')+' '+dt.trim().substringAfter('T'));
                    trans.transactionDateTime=Datetime.valueOf(dt.trim().substringBefore('T')+' '+dt.trim().substringAfter('T'));
                }else{
                    throw new GatewayException(errorMap.get(false));
                }
            }else{
                throw new GatewayException(MessageHandler.wentWrongCatchMessage);
            }
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()),'faultstring'));
        }
    }
    
    /*******************[GLOBAL]Method used to get customer details to check if frequency is changed in Ezidebit***************/
    public static Boolean getCustomerDetails(RecurringWrapper recurringPayment){
        String payload= XMLBodyBuilder('getCustomerDetails', recurringPayment.recurringRequestId, '', '', EzidebitGateway.Client_Key__c, '',null,null);         //Only for demo [Cent value is null]
        String urltohit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        HttpResponse response=hitEndpointXML(urltohit, 'POST', GetCustomerDetails, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=recurringPayment.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.fetchRPDetails, Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }        
        if(response.getStatusCode()==200){
            Map<Boolean,String> errorMap=checkErrors(response.getBody());
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    String frequency=handleFrequencies(xmlReader(new XmlStreamReader(response.getBody()), 'PaymentPeriod').trim(),true);
                    if(frequency==null) 
                    throw new GatewayException('Frequency not valid');
                    if(recurringPayment.instalPeriod!=frequency){
                        recurringPayment.instalPeriod=frequency;
                        return true;
                    }
                }else{
                    throw new GatewayException(errorMap.get(false));
                }
            }else{
                throw new GatewayException(MessageHandler.wentWrongCatchMessage);
            } 
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()),'faultstring'));
        }
        return false;
    }
    
    /*******************Method to perform refund*********************/
    public static String getRefund(RecurringWrapper wrapper){
        String result='';
        String payload=XMLBodyBuilder('processRefund', wrapper.recurringRequestId, wrapper.refundId, '', EzidebitGateway.Client_Key__c, '',null,null);          //Only for demo[cent value is null]
        String urltohit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        HttpResponse response = hitEndpointXML(urltohit, 'POST', ProcessRefund, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.refundAction, Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }
        if(response.getStatusCode()==200){
            // Boolean noErrors = checkErrors(response.getBody());
            Map<Boolean,String> errorMap=checkErrors(response.getBody());
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    result=xmlReader(new XmlStreamReader(response.getBody()), 'RefundResultText');      
                }else{
                    result=errorMap.get(false);
                }
            }else{
                throw new GatewayException(MessageHandler.wentWrongCatchMessage);
            }
            
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()), 'faultstring'));
        }
        return result;
    }
    
    /**********Method to change the customer status to cancel if validation of credit card fails*********/
    public static RecurringWrapper changeCustomerStatus(RecurringWrapper wrapper){
        wrapper.status=false;
        String result='';
        String payload=XMLBodyBuilder('changeCustomerStatus', wrapper.recurringRequestId, '', '', EzidebitGateway.Client_Key__c, '',null,null);             //Only for demo[cent value is null]
        String urltohit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        HttpResponse response=hitEndpointXML(urltohit, 'POST', ChangeCustomerStatus, payload);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=wrapper.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.inativeCustomer, Http_Response__c=String.valueOf(response),Request_Type__c='POST',Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=payload,End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        if(response.getStatusCode()==200){
            // Boolean noErrors=checkErrors(response.getBody());
            Map<Boolean,String>  errorMap=checkErrors(response.getBody());
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    result=xmlReader(new XmlStreamReader(response.getBody()),'Data');
                    if(result=='S'){
                        wrapper.status=true;
                        wrapper.responseMessage=result;
                    }
                }else{
                    wrapper.errorResponse=errorMap.get(false);
                }
            }else{
                throw new GatewayException(MessageHandler.wentWrongCatchMessage);
            }
            
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()), 'faultstring'));
        }
        return wrapper;
    }
    
    public static RecurringWrapper updateCardDetails(RecurringWrapper req){
        req.status=false;
        if(req.transactionreference==null){
            req.errorResponse=MessageHandler.wentWrongCatchMessage;
            return req;
        }
        req.status=true;
        req.processingLink='/apex/Q_Charge__EzidebitUpdateCard?reference='+req.transactionreference;   
        return req;     
    }
    
    /******************Method to fetch the card details from ezidebit************** */
    public static RecurringWrapper fetchCardDetails(RecurringWrapper req){
        req.status=false;
        RecurringWrapper.CardInformation cardDetails=new RecurringWrapper.CardInformation();
        String payload=XMLBodyBuilder('getCustomerAccountDetails', req.recurringRequestId, '', '', EzidebitGateway.Client_Key__c, '',null,null);            //Only for demo[cent value is null]
        String urltohit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxPCI:EziDebitProductionPCI;
        HttpResponse response=hitEndpointXML(urltohit, 'POST', GetCustomerAccountDetails, Payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.fetchCardDetail, Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }
        if(response.getStatusCode()==200){
            Map<Boolean,String> errorMap=checkErrors(response.getBody());
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    cardDetails.CardHolderName=xmlReader(new XmlStreamReader(response.getBody()), 'CardHolderName');
                    cardDetails.CardNumber=xmlReader(new XmlStreamReader(response.getBody()), 'CreditCardNumber');
                    List<String> cardNumberSplit=cardDetails.CardNumber.split('');
                    for(Integer i=0;i<cardNumberSplit.size();i++){
                        if(cardNumberSplit.get(i)=='x'){
                            break;
                        }else{
                            cardNumberSplit.set(i,'x');
                        }
                    }
                    cardDetails.CardNumber=String.join(cardNumberSplit, '');
                    
                    cardDetails.ExpiryMonth=xmlReader(new XmlStreamReader(response.getBody()), 'ExpiryMonth');
                    cardDetails.ExpiryYear=xmlReader(new XmlStreamReader(response.getBody()), 'ExpiryYear');
                    req.status=true;
                }else{
                    cardDetails.ErrorMessage=errorMap.get(false);
                }
            }else{
                throw new  GatewayException(MessageHandler.wentWrongCatchMessage);
            }
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()), 'faultstring'));
        }
        req.cardDetails=cardDetails;
        return req;
    }
    
    public static RecurringWrapper createSchedule(RecurringWrapper req){
        req.status=false;
        String payload=XMLBodyBuilder('createSchedule', req.recurringRequestId, '', '', EzidebitGateway.Client_Key__c, '', req,null);               //Only for demo[cent value is null]
        String urlToHit=(EzidebitGateway.isSandbox__c)?EziDebitSandboxNonPCI:EziDebitProductionNonPCI;
        HttpResponse response=hitEndpointXML(urlToHit, 'POST', CreateSchedule, payload);
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=req.sfProcessingId,Action__c = MessageHandler.processPayment(UTILGateway.EZIDEBITWORD.capitalize(),UTILGateway.RECURRINGKEYWORD), Http_Response__c=String.valueOf(response),Http_Response_Code__c=String.valueOf(response.getStatusCode()),Payload__c=Payload,Request_Type__c='POST',End_Point__c=urltohit,Gateway_Name__c=UTILGateway.EZIDEBITWORD)));
        }
        if(response.getStatusCode()==200){
            Map<Boolean,String> errorMap=checkErrors(response.getBody());
            if(!errorMap.isEmpty()){
                if(errorMap.containsKey(true)){
                    req.status=true;
                    req.responseMessage=xmlReader(new XmlStreamReader(response.getBody()), 'Data');
                }else{
                    req.errorResponse=errorMap.get(false);
                }
            }else{
                throw new  GatewayException(MessageHandler.wentWrongCatchMessage);
            }
        }else{
            throw new GatewayException(xmlReader(new XmlStreamReader(response.getBody()), 'faultstring'));
        }
        return req;
    }
    
    
    /****************************Method to build the xml body *******************/
    public static String XMLBodyBuilder(String xmlBodyName,String ezidebitRefId,String paymentId,String contactName,String digitalKey,String transactionDate,RecurringWrapper wrapper,String centValue){                //Only for demo[Remove cent value]
        String centValueChanged=(centValue==null || centValue=='')?'00':centValue;
        String centValueUpdated='1'+centValueChanged;
        XmlStreamWriter xs = new XmlStreamWriter();
        xs.writeStartDocument(null, '1.0');
        xs.writeStartElement('soapenv', 'Envelope', envelope);
        xs.writeAttribute('xmlns', envelope, 'soapenv', envelope);
        xs.writeAttribute('xmlns', envelope, 'px', pxezidebit);
        xs.writeStartElement('soapenv', 'Header',envelope);
        xs.writeEndElement();
        switch on xmlBodyName {
            when 'getCustomerList' {
                getCustomerListXML(xs,digitalKey);
            }
            when 'getScheduledPayments' {
                getScheduledPaymentsXML(xs, digitalKey, ezidebitRefId);
            }
            when 'clearSchedule' {
                clearScheduleXML(xs, digitalKey, ezidebitRefId);
            }
            when 'processRefund' {
                processRefundXml(xs, digitalKey, paymentId);
            }
            when 'processRealTimeToken'{
                processRealTimeTokenXML(xs, digitalKey, ezidebitRefId, contactName, String.valueOf(Math.random()*10),centValueUpdated);
            }
            when 'getPayments'{
                getPaymentsXML(xs, digitalKey, transactionDate, String.valueOf(Date.today()), ezidebitRefId);
            }
            when 'getCustomerDetails'{
                getCustomerDetailsXML(xs, digitalKey, ezidebitRefId);
            }
            when 'changeCustomerStatus'{
                changeCustomerStatusXML(xs, digitalKey, ezidebitRefId);
            }
            when 'getCustomerAccountDetails'{
                getCustomerAccountDetailsXML(xs, digitalKey, ezidebitRefId);
            }
            when 'createSchedule'{
                createScheduleXML(xs, digitalKey, ezidebitRefId, wrapper);
            }
        }
        xs.writeEndElement();
        xs.writeEndDocument();
        return xs.getXmlString();  
    }
    
    /*******Method to create the authentication xml body*****/
    public static void getCustomerListXML(XmlStreamWriter xs,String digitalKey){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'GetCustomerList', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'EziDebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference', pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'CustomerStatus',pxezidebit);
        xs.writeCharacters('ALL');
        xs.writeEndElement();
        xs.writeStartElement('px', 'OrderBy', pxezidebit);
        xs.writeCharacters('EzidebitCustomerID');
        xs.writeEndElement();
        xs.writeStartElement('px','Order', pxezidebit);
        xs.writeCharacters('ASC');
        xs.writeEndElement();
        xs.writeStartElement('px', 'PageNumber', pxezidebit);
        xs.writeCharacters('1');
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
        
    }
    
    /****************Method to create the schedule payments xml body**************/
    public static void getScheduledPaymentsXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'GetScheduledPayments', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'DateFrom', pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'DateTo', pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'EziDebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference', pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /*****************Method to create for process realtime token payments xml body*********/
    public static void processRealTimeTokenXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId,String contactName,String paymentReference,String centValue){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'ProcessRealtimeTokenPayment', 'https://px.ezidebit.com.au/');
        xs.writeStartElement('px', 'digitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'token',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeStartElement('px', 'paymentAmountInCents', pxezidebit);
        xs.writeCharacters(centValue);			
        xs.writeEndElement();
        xs.writeStartElement('px', 'customerName', pxezidebit);
        xs.writeCharacters(contactName);
        xs.writeEndElement();
        xs.writeStartElement('px', 'paymentReference', pxezidebit);
        xs.writeCharacters(paymentReference);
        xs.writeEndElement();
    }
    
    /***********Method to create the clear schedule xml body********/
    public static void clearScheduleXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'ClearSchedule', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'EzidebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeStartElement('px', 'KeepManualPayments', pxezidebit);
        xs.writeCharacters('NO');
        xs.writeEndElement();
        xs.writeStartElement('px', 'Username', pxezidebit);
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /**************Method to create process refund xml body *******/
    public static void processRefundXml(XmlStreamWriter xs,String digitalKey,String paymentId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'ProcessRefund', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'PaymentID',pxezidebit);
        xs.writeCharacters(paymentId);
        xs.writeEndElement();
        xs.writeStartElement('px', 'BankReceiptID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'RefundAmountInCents', pxezidebit);
        xs.writeCharacters('100');
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /***************Method to create body for get payments**************** */
    public static void getPaymentsXML(XmlStreamWriter xs,String digitalKey,String transactionDate,String today,String ezidebitRefId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'GetPayments', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'PaymentType',pxezidebit);
        xs.writeCharacters('ALL');
        xs.writeEndElement();
        xs.writeStartElement('px', 'PaymentMethod',pxezidebit);
        xs.writeCharacters('CR');
        xs.writeEndElement();
        xs.writeStartElement('px', 'PaymentSource',pxezidebit);
        xs.writeCharacters('Scheduled');
        xs.writeEndElement();
        xs.writeStartElement('px', 'DateFrom',pxezidebit);
        xs.writeCharacters(transactionDate);
        xs.writeEndElement();
        xs.writeStartElement('px', 'DateTo',pxezidebit);
        xs.writeCharacters(today);
        xs.writeEndElement();
        xs.writeStartElement('px', 'DateField',pxezidebit);
        xs.writeCharacters('PAYMENT');
        xs.writeEndElement();
        xs.writeStartElement('px', 'EzidebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /***************Method to create body for get Customer Details*******************/
    public static void getCustomerDetailsXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'GetCustomerDetails', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);        //changed
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /***************Method to create body for change customer status*******************/
    public static void changeCustomerStatusXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'ChangeCustomerStatus', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'EziDebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeStartElement('px', 'NewStatus',pxezidebit);
        xs.writeCharacters('C');
        xs.writeEndElement();
        xs.writeStartElement('px', 'Username',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /*************Method to create the xml body to get customer masked credit card details *************/
    public static void getCustomerAccountDetailsXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'GetCustomerAccountDetails', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'EziDebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    /********************Method to create xml body for create schedule*********************/
    public static void createScheduleXML(XmlStreamWriter xs,String digitalKey,String ezidebitRefId,RecurringWrapper wrapper){
        xs.writeStartElement('soapenv', 'Body', envelope);
        xs.writeStartElement('px', 'CreateSchedule', pxezidebit);
        xs.writeStartElement('px', 'DigitalKey', pxezidebit);
        xs.writeCharacters(digitalKey);
        xs.writeEndElement();
        xs.writeStartElement('px', 'EziDebitCustomerID',pxezidebit);
        xs.writeEndElement();
        xs.writeStartElement('px', 'YourSystemReference',pxezidebit);
        xs.writeCharacters(ezidebitRefId);
        xs.writeEndElement();
        xs.writeStartElement('px', 'ScheduleStartDate',pxezidebit);
        xs.writeCharacters(String.valueOf(wrapper.startDate));
        xs.writeEndElement();
        xs.writeStartElement('px', 'SchedulePeriodType',pxezidebit);
        xs.writeCharacters(wrapper.instalPeriod);
        xs.writeEndElement();
        xs.writeStartElement('px', 'DayOfWeek',pxezidebit);
        if(wrapper.instalPeriod=='W' || wrapper.instalPeriod=='F' || wrapper.instalPeriod=='4' || wrapper.instalPeriod=='N'){
            xs.writeCharacters(wrapper.recurringAbbr);
        }
        xs.writeEndElement();
        xs.writeStartElement('px', 'DayOfMonth',pxezidebit);
        if(wrapper.instalPeriod=='M'){
            xs.writeCharacters(wrapper.recurringAbbr);
        }else{
            xs.writeCharacters('0');
        }
        xs.writeEndElement();
        xs.writeStartElement('px', 'FirstWeekOfMonth',pxezidebit);
        xs.writeCharacters('N');
        xs.writeEndElement();
        xs.writeStartElement('px', 'SecondWeekOfMonth',pxezidebit);
        xs.writeCharacters('N');
        xs.writeEndElement();
        xs.writeStartElement('px', 'ThirdWeekOfMonth',pxezidebit);
        xs.writeCharacters('N');
        xs.writeEndElement();
        xs.writeStartElement('px', 'FourthWeekOfMonth',pxezidebit);
        xs.writeCharacters('N');
        xs.writeEndElement();
        xs.writeStartElement('px', 'PaymentAmountInCents',pxezidebit);
        xs.writeCharacters(String.valueOf(Integer.valueOf(wrapper.amount)));
        xs.writeEndElement();
        xs.writeStartElement('px', 'LimitToNumberOfPayments',pxezidebit);
        xs.writeCharacters('0');
        xs.writeEndElement();
        xs.writeStartElement('px', 'LimitToTotalAmountInCents',pxezidebit);
        xs.writeCharacters('0');
        xs.writeEndElement();
        xs.writeStartElement('px', 'KeepManualPayments',pxezidebit);
        xs.writeCharacters('YES');
        xs.writeEndElement();
        xs.writeStartElement('px', 'Username',pxezidebit);
        xs.writeCharacters('');
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
    
    
    public static String getResponseMsg(String responseCode){
        Map<String,String> responseCodeMap = new Map<String,String>();
        String responseMsg='';
        responseCodeMap.put('01','Refer to Issuer');
        responseCodeMap.put('02','Refer to Issuer’s Special Conditions');
        responseCodeMap.put('03','No Merchant');
        responseCodeMap.put('04','Pick Up Card');
        responseCodeMap.put('05','Do Not Honour');
        responseCodeMap.put('06','Error');
        responseCodeMap.put('07','Pick Up Card, Special Conditions');
        responseCodeMap.put('09','Request in Progress');
        responseCodeMap.put('12','Invalid Transaction');
        responseCodeMap.put('13','Invalid Amount');
        responseCodeMap.put('14','Invalid Card Number');
        responseCodeMap.put('15','No Issuer');
        responseCodeMap.put('17','3D Secure Error');
        responseCodeMap.put('19','Re-enter Transaction');
        responseCodeMap.put('21','No Action Taken');
        responseCodeMap.put('22','Suspected Malfunction');
        responseCodeMap.put('23','Unacceptable Transaction Fee');
        responseCodeMap.put('25','Unable to Locate Record on File');
        responseCodeMap.put('30','Format Error');
        responseCodeMap.put('31','Bank not Supported by Switch');
        responseCodeMap.put('33','Expired Card-Pick Up');
        responseCodeMap.put('34','Suspected Fraud-Pick Up');
        responseCodeMap.put('35','Contact Acquirer-Pick Up');
        responseCodeMap.put('36','Restricted Card-Pick Up');
        responseCodeMap.put('37','Call Acquirer Security-Pick Up');
        responseCodeMap.put('38','Allowable PIN Tries Exceeded');
        responseCodeMap.put('39','No Credit Account');
        responseCodeMap.put('40','Requested Function not Supported');
        responseCodeMap.put('41','Lost Card-Pick Up	');
        responseCodeMap.put('42','No Universal Amount');
        responseCodeMap.put('43','Stolen Card-Pick Up');
        responseCodeMap.put('44','No Investment Account');
        responseCodeMap.put('51','Insufficient Funds');
        responseCodeMap.put('52','No Cheque Account');
        responseCodeMap.put('53','No Savings Account');
        responseCodeMap.put('54','Expired Card');
        responseCodeMap.put('55','Incorrect PIN	');
        responseCodeMap.put('56','No Card Record');
        responseCodeMap.put('57','Trans. not Permitted to Cardholder');
        responseCodeMap.put('58','Transaction not Permitted to Terminal');
        responseCodeMap.put('59','Suspected Fraud');
        responseCodeMap.put('60','Card Acceptor Contact Acquirer');
        responseCodeMap.put('61','Exceeds Withdrawal Amount Limits');
        responseCodeMap.put('62','Restricted Card');
        responseCodeMap.put('63','Security Violation');
        responseCodeMap.put('64','Original Amount Incorrect	');
        responseCodeMap.put('66','Card Acceptor Call Acquirer Security');
        responseCodeMap.put('67','Hard Capture-Pick Up Card at ATM');
        responseCodeMap.put('68','Response Received Too Late');
        responseCodeMap.put('75','Allowable PIN Tries Exceeded');
        responseCodeMap.put('90','Cut-off in Progress');
        responseCodeMap.put('91','Issuer or Switch is Inoperative');
        responseCodeMap.put('92','Financial Institution not Found');
        responseCodeMap.put('93','Trans Cannot be Completed');
        responseCodeMap.put('94','Duplicate Transmission');
        responseCodeMap.put('95','Reconcile Error');
        responseCodeMap.put('96','System Malfunction');
        responseCodeMap.put('97','Reconciliation Totals Reset');
        responseCodeMap.put('98','MAC Error');
        responseCodeMap.put('99','Reserved for National Use');
        
        responseMsg=responseCodeMap.get(responseCode);
        return responseMsg;
    }
}