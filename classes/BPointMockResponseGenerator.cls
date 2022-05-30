global class BPointMockResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) 
    {
        
        if(req.getEndpoint()=='https://www.bpoint.com.au/webapi/v3/txns/search'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Accept', 'application/json');
            res.setBody('{"APIResponse":{"ResponseCode":0,"ResponseText":"Success"},"TxnRespList":[{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"372626","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}},{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"380662","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}}]}');
            res.setStatusCode(200);
            return res;
        }
        else if(req.getEndpoint()=='https://www.bpoint.com.au/webapi/v3/txns/processtxnauthkey'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"APIResponse":{"ResponseCode":0,"ResponseText":"Success"},"AuthKey":"df998fea-f309-4e6e-9629-7149799dc028"}');
            res.setStatusCode(200);
            return res;
        }
        else {
            HttpResponse res = new HttpResponse();
            return res;
        }
    }
    
}