public with sharing class NABTransactManager {

    /****************URL to hit ********************/ 
    public static final String TestDemoURL = 'https://demo.transact.nab.com.au/xmlapi/payment';
    public static final String LiveURL = 'https://transact.nab.com.au/live/xmlapi/payment';
    public static final String TestOneOffURL = 'https://demo.transact.nab.com.au/directpostv2/authorise';
    public static final String LiveOneOffURL = 'https://transact.nab.com.au/live/directpostv2/authorise';
    public static final String TestRPURL = 'https://demo.transact.nab.com.au/xmlapi/periodic';
    public static final String LiveRPURL = 'https://transact.nab.com.au/xmlapi/periodic';
     
    /*********************** variables ********************************/
    public static Gateway_Detail__c NABTransactGateway;
    public static String detachedReason = null;
    public static Boolean isConnected = false;

    /***********Static methods ***********/
    static {
        if([Select Id  from Gateway_Detail__c where Name__c = :UTILGateway.NABTRANSWORD WITH SECURITY_ENFORCED].size() == 1){
            NABTransactGateway = UTILGateway.decodeKeys(UTILGateway.NABTRANSWORD);
            try{
                String credChecking = validateCredentials(NABTransactGateway, true);
                isConnected = (credChecking == 'valid' ? true : false);
                detachedReason = (credChecking != 'valid' ? credChecking : detachedReason);
            }
            catch(Exception ex){
                detachedReason = MessageHandler.apiKeyMissing+' Due to '+ex.getMessage()+'.';
            }
        } else {
            detachedReason = MessageHandler.apiKeyMissing;
        }
        //Similarly check for licenses and FPs
    }

    /******************Method to store credentials*******************/
    public static String PostCredentials(Gateway_Detail__c Gateway){
        String returnString = '';
        String UrlToHit = (Gateway.isSandbox__c)? TestDemoURL : LiveURL; 

        String Payload = authenticationXMLWriter(Gateway.Client_Id__c, Gateway.Client_Key__c);
        HttpResponse response = hitEndpointXML(UrlToHit, 'GET', Payload);

        Payment_Log__c log = new Payment_Log__c(End_point__c = UrlToHit, Http_Response__c = response.getBody(), Http_Response_Code__c = String.valueOf(response.getStatusCode()), Payload__c = Payload, Request_Type__c = 'GET', Action__c = UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.storingCredential, Transaction_Status__c = 'Void',Gateway_Name__c=UtilGateway.NABTRANSWORD);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));            
        
        if(response.getStatusCode()==200){
            String responseXML = UTILGateway.XMLParser(response.getBody());
            if(responseXML.contains('Normal')){
                returnString='valid';
            }
            else{
                returnString=MessageHandler.loginFailed;
            }
        }
        else {
            if(response.getBody() == null){
                returnString = MessageHandler.noResponseFromNAB;
            }
            else{
                returnString = UTILGateway.XmlParser(response.getBody());
            }
        } 
        return returnString;       
    }

    /*********************** WouldBeGlobal Check the NAB Transact credentials ********************************/
    public static String validateCredentials(Gateway_Detail__c Gateway, Boolean createLog){
        if(detachedReason != null)
            throw new GatewayException(detachedReason);

        String returnString = '';
        String UrlToHit = (Gateway.isSandbox__c)? TestDemoURL : LiveURL;
        
        String Payload = authenticationXMLWriter(Gateway.Client_Id__c, Gateway.Client_Key__c);
        HttpResponse response = hitEndpointXML(UrlToHit, 'GET', Payload);

        if(createLog){
            Payment_Log__c log = new Payment_Log__c(End_point__c = UrlToHit, Http_Response__c = response.getBody(), Http_Response_Code__c = String.valueOf(response.getStatusCode()), Payload__c = Payload, Request_Type__c = 'GET', Action__c=UTILGateway.NABTRANSWORD.capitalize()+''+MessageHandler.checkCredential, Transaction_Status__c = 'Void',Gateway_Name__c=UtilGateway.NABTRANSWORD);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        }            
        
        if(response?.getStatusCode()==200) {
            String responseXML = UTILGateway.XMLParser(response.getBody());
            if(responseXML.contains('Normal')){
                returnString='valid'; 
            }
            else{
                returnString=MessageHandler.loginFailed; 
            }
        }
        else {
            if(response.getBody() == null){
                returnString = MessageHandler.noResponseFromNAB;
            }
            else{
                returnString = UTILGateway.XmlParser(response.getBody());
            }
        }
        return returnString;       
    }
    
    /***************Generic method for XML requests*****************/
    public static HttpResponse hitEndpointXML(String endPointUrl, String method, String payload)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod(method);
        req.setHeader('Content-Type', 'text/xml');
        if(Payload!=null)
            req.setBody(payload);
        req.setTimeout(120000);
        return new Http().send(req);
    }

    /*********************** WouldBeGlobal create a one off payment session ********************************/
    public static TransactionWrapper requestOneTimePayment(TransactionWrapper req){
        req.status = false;
        if(req.amount != null && req.sfProcessingId != null && req.transactionType != null){
            String endPoint = (NABTransactGateway.Q_Charge__isSandbox__c)? TestOneOffURL : LiveOneOffURL;

            if(req.amount <= 0){
                req.errorResponse = MessageHandler.amountLessThan1Cent;
            }
            else if(req.amount > 99999999.99){
                req.errorResponse = MessageHandler.amountAboveLimit;
            }
            else{
                req.status = true;
                req.successURL =endPoint;
            }
        }
        else{
            req.errorResponse = MessageHandler.transactionError;
        }
        return req;
    }

    /*********************** WouldBeGlobal create a recurring payment session ********************************/
    public static RecurringWrapper requestRecurringPayment(RecurringWrapper req){
        req.status = false;
        if(req.amount != null && req.sfProcessingId != null && req.transactionType != null && req.instalPeriod != null && req.startDate != null){
            String endPoint = (NABTransactGateway.Q_Charge__isSandbox__c)? TestOneOffURL : LiveOneOffURL;

            if(req.amount <= 0){
                req.errorResponse = MessageHandler.amountLessThan1Cent;
            }
            else if(req.amount > 99999999.99){
                req.errorResponse = MessageHandler.amountAboveLimit;
            }
            else if(req.startDate != null && req.startDate < Date.today()){
                req.errorResponse = MessageHandler.prevStartDate;
            }
            else if(req.transactionType == UTILGateway.RECURRINGKEYWORD && req.startDate == null){
                req.errorResponse = MessageHandler.startDateMissing;
            }
            else{
                req.status = true;
                req.successURL = endPoint;
            }
        }
        else{
            req.errorResponse = MessageHandler.transactionError;
        }
        return req;
    }

    /*********************** Method to validate credit card for schedule payment ********************************/
    public static TransactionWrapper validateCreditCard(TransactionWrapper transWrapper){
        String complete_response = '';
        String urlToHit = (NABTransactGateway.isSandbox__c)? TestRPURL : LiveRPURL;
        String transactionId = '';
        String amount = '100';

        String payload = commonBodyXMLWriter('chargeAmount', null, null, transWrapper.tokenValue, transWrapper.transactionId, null, amount, null, null, null);
        HttpResponse response = hitEndpointXML(urlToHit, 'POST', payload);

        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c = 'POST', Action__c = UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.validateCard, Amount__c = 1.00, HTTP_Response__c = response.getBody(), Http_Response_Code__c = String.valueOf(response.getStatusCode()), End_Point__c = UrlToHit, Payload__c = payload, Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Transaction_Status__c = 'Void',Gateway_Name__c=UtilGateway.NABTRANSWORD)));

        if(response.getStatusCode()==200) {
            String responseXML = UTILGateway.XMLParser(response.getBody());
            if(responseXML.contains('Normal')){
                complete_response = 'Normal';
                
                XmlStreamReader reader = new XmlStreamReader(response.getBody());
                while(reader.hasNext()){
                    if(reader.getEventType() == XmlTag.START_ELEMENT){
                        if('NABTransactMessage' == reader.getLocalName()){
                            transactionId = xmlReader(reader, 'txnID');
                            complete_response+='&TransactionId='+transactionId;
                            transWrapper.transResponse = complete_response;
                        }  
                    }
                    reader.next();
                } 
            }
            else{
                transWrapper.transResponse = responseXML; 
            }
        }
        else {
            if(response.getBody() == null){
                transWrapper.transResponse = MessageHandler.noResponseFromNAB;
            }
            else{
                transWrapper.transResponse = UTILGateway.XmlParser(response.getBody());
            }
        }
        return transWrapper;
    }

    /********************* Method to read XML body*******************/
    public static String xmlReader(XmlStreamReader reader,String localName){
        Boolean hasResult = false;
        String paymentResult = '';
        while(reader.hasNext()){
            if(reader.getEventType() == XmlTag.START_ELEMENT){
                if(reader.getLocalName() == localName){
                    hasResult = true;
                }
            }
            if(reader.getEventType() == XmlTag.CHARACTERS){
                if(hasResult){
                    paymentResult = reader.getText()+' ';
                    hasResult = false;
                    return paymentResult;
                }
            }
            reader.next();
        }
        return paymentResult;
    }

    /********************* Method to refund a $1 from NAB Transact*******************/
    public static RecurringWrapper refundValidationAmount(RecurringWrapper recurringWrapper, Boolean createLog){
        if(detachedReason != null)
            throw new GatewayException(detachedReason);
        String UrlToHit = (NABTransactGateway.isSandbox__c)? TestDemoURL : LiveURL;
        string responseMessage = '';

        String payLoad = commonBodyXMLWriter('refundAmount', recurringWrapper.refundId, recurringWrapper.transactionreference, null, null, null, null, null, null, null);
        HttpResponse response = hitEndpointXML(UrlToHit, 'POST', payLoad);
        if(createLog){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c = 'POST', Action__c = UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.refundAction, Amount__c = 1.00, Processing_Record_Id__c = recurringWrapper.sfProcessingId, HTTP_Response__c = response.getBody(), Http_Response_Code__c = String.valueOf(response.getStatusCode()), End_Point__c = UrlToHit, Payload__c = payload, Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Transaction_Status__c = 'Void',Gateway_Name__c=UtilGateway.NABTRANSWORD)));
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        }

        if(response.getStatusCode()==200) {
            String responseXML = UTILGateway.XMLParser(response.getBody());
            if(responseXML.contains('Yes')){
                recurringWrapper.refundStatus = 'Refunded';
                recurringWrapper.refundTime = DateTime.now();
                recurringWrapper.refundDesc = 'Amount refunded successfully.';
            }
            else{
                XmlStreamReader reader = new XmlStreamReader(response.getBody());
                while(reader.hasNext()){
                    if(reader.getEventType() == XmlTag.START_ELEMENT){
                        if('NABTransactMessage' == reader.getLocalName()){
                            responseMessage = xmlReader(reader, 'responseText');
                            responseMessage = responseMessage.trim();
                        }  
                    }
                    reader.next();
                }
                recurringWrapper.refundDesc = responseMessage+'.';
                recurringWrapper.refundStatus = 'Failed';               
            } 
        }
        else {
            if(response.getBody() == null){
                recurringWrapper.refundDesc = MessageHandler.noResponseFromNAB;
            }
            else{
                recurringWrapper.refundDesc = UTILGateway.XmlParser(response.getBody());
            }
        }
        return recurringWrapper;
    }


    /*******Method to charge current transaction of schedule*******/
    public static TransactionWrapper chargeCurrentTransaction(TransactionWrapper transWrapper){
        String urlToHit = (NABTransactGateway.isSandbox__c)? TestRPURL : LiveRPURL;
        String transactionId = '';
        String scheduleRefId = 'Transaction-'+transWrapper.transactionId;
        String Complete_response;

        String payload = commonBodyXMLWriter('chargeAmount', null, null, transWrapper.tokenValue, scheduleRefId, null, String.valueOf(Integer.valueOf(transWrapper.amount)), null, null, null);
        HttpResponse response = hitEndpointXML(urlToHit, 'POST', payload);

        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Request_Type__c = 'POST', Action__c = UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.chargeRecTransaction, Amount__c = transWrapper.amount, HTTP_Response__c = response.getBody(), Http_Response_Code__c = String.valueOf(response.getStatusCode()), End_Point__c = UrlToHit, Payload__c = payload, Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Transaction_Status__c = 'Void',Gateway_Name__c=UtilGateway.NABTRANSWORD)));

        if(response.getStatusCode()==200) {
            String responseXML = UTILGateway.XMLParser(response.getBody());
            if(responseXML.contains('Normal')){
                Complete_response = 'Normal';
                
                XmlStreamReader reader = new XmlStreamReader(response.getBody());
                while(reader.hasNext()){
                    if(reader.getEventType() == XmlTag.START_ELEMENT){
                        if('NABTransactMessage' == reader.getLocalName()){
                            transactionId = xmlReader(reader, 'txnID');
                            Complete_response+= '&TransactionId='+transactionId;
                            transWrapper.transResponse = Complete_response;
                        }  
                    }
                    reader.next();
                } 
            }
            else{
                transWrapper.transResponse = responseXML; 
            }
        }
        else {
            if(response.getBody() == null){
                transWrapper.transResponse = MessageHandler.noResponseFromNAB;
            }
            else{
                transWrapper.transResponse = UTILGateway.XMLParser(response.getBody());
            }
        }
        return transWrapper;
    }

    /*******Method to return vf page url to update card details*****/
    public static RecurringWrapper updateCardDetails(RecurringWrapper recurWrap){
        recurWrap.status = true;
        String urlToHit = (NABTransactGateway.isSandbox__c)? TestOneOffURL : LiveOneOffURL;
        recurWrap.successURL = urlToHit;
        recurWrap.processingLink = '/apex/Q_Charge__NABTransactUpdateCardDetails';   
        return recurWrap;
    }

    /*******Method to create common XML body for XMLWriter*****/
    public static String commonBodyXMLWriter(String xmlRequestName, String transactionId, String referenceId, String returnToken, String scheduleRefId, String startDate, String finalAmount, String paymentInterval, String numberOfPayment, String scheduleName){
        String GMTtimestamp = DateTime.now().formatGMT('yyyyddMMHHmmss');
        String timeStamp = GMTtimestamp+'000000+000';
        String returnString = '';

        XmlStreamWriter xs = new XmlStreamWriter();
        xs.writeStartDocument( 'UTF-8', '1.0' );
        xs.writeStartElement( null, 'NABTransactMessage', null );
        xs.writeStartElement( null, 'MessageInfo', null );
        xs.writeStartElement( null, 'messageID', null );
        xs.writeCharacters(GMTtimestamp);
        xs.writeEndElement();
        xs.writeStartElement( null, 'messageTimestamp', null );
        xs.writeCharacters(timeStamp);
        xs.writeEndElement();
        xs.writeStartElement( null, 'timeoutValue', null );
        xs.writeCharacters('60');
        xs.writeEndElement();
        xs.writeStartElement( null, 'apiVersion', null );
        xs.writeCharacters('xml-4.2');
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeStartElement( null, 'MerchantInfo', null );
        xs.writeStartElement( null, 'merchantID', null );
        xs.writeCharacters(NABTransactGateway.Client_Id__c);
        xs.writeEndElement();
        xs.writeStartElement( null, 'password', null );
        xs.writeCharacters(NABTransactGateway.Client_Key__c);
        xs.writeEndElement();
        xs.writeEndElement();

        switch on xmlRequestName {
            when 'chargeAmount' {
                chargeAmountXMLWriter(xs,returnToken,scheduleRefId,finalAmount);
            }
            when 'refundAmount' {
                refundAmountXMLWriter(xs,transactionId, referenceId);
            }
        }

        xs.writeEndElement();
        xs.writeEndDocument();
        returnString = xs.getXmlString();
        return returnString;
    }

    /*******Method to create XML body for authenticating credentials using XMLWriter*****/
    public static string authenticationXMLWriter(String clientId, String clientKey){
        String GMTtimestamp = DateTime.now().formatGMT('yyyyddMMHHmmss');
        String timeStamp = GMTtimestamp+'000000+000';
        String returnString = '';

        XmlStreamWriter xs = new XmlStreamWriter();
        xs.writeStartDocument( 'UTF-8', '1.0' );
        xs.writeStartElement( null, 'NABTransactMessage', null );
        xs.writeStartElement( null, 'MessageInfo', null );
        xs.writeStartElement( null, 'messageID', null );
        xs.writeCharacters(GMTtimestamp);
        xs.writeEndElement();
        xs.writeStartElement( null, 'messageTimestamp', null );
        xs.writeCharacters(timeStamp);
        xs.writeEndElement();
        xs.writeStartElement( null, 'timeoutValue', null );
        xs.writeCharacters('60');
        xs.writeEndElement();
        xs.writeStartElement( null, 'apiVersion', null );
        xs.writeCharacters('xml-4.2');
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeStartElement( null, 'MerchantInfo', null );
        xs.writeStartElement( null, 'merchantID', null );
        xs.writeCharacters(clientId);
        xs.writeEndElement();
        xs.writeStartElement( null, 'password', null );
        xs.writeCharacters(clientKey);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeStartElement( null, 'RequestType', null );
        xs.writeCharacters('Echo');
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndDocument();
        returnString = xs.getXmlString();
        return returnString;
    }

    public static void refundAmountXMLWriter(XmlStreamWriter xs, String transactionId, String referenceId){
        xs.writeStartElement( null, 'RequestType', null );
        xs.writeCharacters('Payment');
        xs.writeEndElement();
        xs.writeStartElement( null, 'Payment', null );
        xs.writeStartElement( null, 'TxnList', null );
        xs.writeAttribute( null, null, 'count', '1' );
        xs.writeStartElement( null, 'Txn', null );
        xs.writeAttribute( null, null, 'ID', '1' );
        xs.writeStartElement( null, 'txnType', null );
        xs.writeCharacters('4');
        xs.writeEndElement();
        xs.writeStartElement( null, 'txnSource', null );
        xs.writeCharacters('23');
        xs.writeEndElement();
        xs.writeStartElement( null, 'amount', null );
        xs.writeCharacters('100');
        xs.writeEndElement();
        xs.writeStartElement( null, 'currency', null );
        xs.writeCharacters('AUD');
        xs.writeEndElement();
        xs.writeStartElement( null, 'txnID', null );
        xs.writeCharacters(transactionId);
        xs.writeEndElement();
        xs.writeStartElement( null, 'purchaseOrderNo', null );
        xs.writeCharacters(referenceId);
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }

    /*******Method to create XML body for charging current transaction using XMLWriter*****/
    public static void chargeAmountXMLWriter(XmlStreamWriter xs, String returnToken, String scheduleRefId, String finalAmount){
        xs.writeStartElement( null, 'RequestType', null );
        xs.writeCharacters('Periodic');
        xs.writeEndElement();
        xs.writeStartElement( null, 'Periodic', null );
        xs.writeStartElement( null, 'PeriodicList', null );
        xs.writeAttribute( null, null, 'count', '1' );
        xs.writeStartElement( null, 'PeriodicItem', null );
        xs.writeAttribute( null, null, 'ID', '1' );
        xs.writeStartElement( null, 'actionType', null );
        xs.writeCharacters('trigger');
        xs.writeEndElement();
        xs.writeStartElement( null, 'periodicType', null );
        xs.writeCharacters('8');
        xs.writeEndElement();
        xs.writeStartElement( null, 'crn', null );
        xs.writeCharacters(returnToken);
        xs.writeEndElement();
        xs.writeStartElement( null, 'transactionReference', null );
        xs.writeCharacters(scheduleRefId);
        xs.writeEndElement();
        xs.writeStartElement( null, 'amount', null );
        xs.writeCharacters(finalAmount);
        xs.writeEndElement();
        xs.writeStartElement( null, 'currency', null );
        xs.writeCharacters('AUD');
        xs.writeEndElement();
        xs.writeStartElement( null, 'CreditCardInfo', null );
        xs.writeStartElement( null, 'recurringFlag', null );
        xs.writeCharacters('no');
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
        xs.writeEndElement();
    }
}