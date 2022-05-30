global class PaywayMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) 
    {
        if(req.getEndpoint()=='https://api.payway.com.au/rest/v1/'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Accept', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
        else if(req.getEndpoint().startsWith('https://api.payway.com.au/rest/v1/merchants')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "merchantId" : "TEST",  "merchantName" : "Test Merchant",  "links" : [ {    "rel" : "help",    "href" : "https://www.payway.com.au/docs/rest.html#merchants"  } ]}');
            res.setStatusCode(200);
            res.setStatus('Created');
            return res;
        }
        else if((req.getEndpoint() == 'https://api.payway.com.au/rest/v1/transactions' || (req.getEndpoint().startsWith('https://api.payway.com.au/rest/v1/transactions') 
        && !req.getEndpoint().contains('search-customer'))) && !req.getBody().contains('422')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "transactionId" : 3087266670,  "receiptNumber" : "3087266670",  "status" : "approved",  "responseCode" : "08",  "responseText" : "Honour with identification",  "transactionType" : "payment",  "customerNumber" : "GIBSON00HOPDAAAN",  "customerName" : "DHruv",  "currency" : "aud",  "principalAmount" : 50.00,  "surchargeAmount" : 0.00,  "paymentAmount" : 50.00,  "paymentMethod" : "creditCard",  "creditCard" : {    "cardNumber" : "456471...004",    "expiryDateMonth" : "02",    "expiryDateYear" : "29",    "cardScheme" : "visa",    "cardType" : "credit",    "cardholderName" : "DHruv"  },  "merchant" : {    "merchantId" : "TEST",    "merchantName" : "Test Merchant",    "links" : [ {      "rel" : "self",      "href" : "https://api.payway.com.au/rest/v1/merchants/TEST"    } ]  },  "transactionDateTime" : "17 Nov 2021 15:12 AEDT",  "settlementDate" : "17 Nov 2021",  "isVoidable" : true,  "isRefundable" : false,  "links" : [ {    "rel" : "self",    "href" : "https://api.payway.com.au/rest/v1/transactions/3087266669"  }, {    "rel" : "void",    "href" : "https://api.payway.com.au/rest/v1/transactions/3087266669/void"  } ]}');
            res.setStatusCode(200);
            res.setStatus('Created');
            return res;
        }
        
        else if((req.getEndpoint() == 'https://api.payway.com.au/rest/v1/transactions' || (req.getEndpoint().startsWith('https://api.payway.com.au/rest/v1/transactions') 
        && req.getMethod() == 'GET' && !req.getEndpoint().contains('search-customer'))) && req.getBody().contains('422'))
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "data" : [ {    "fieldName" : "singleUseTokenId",    "message" : "The cardholder must provide a CVN to conduct a payment using PayWay Net.",    "fieldValue" : "4cc0b7e7-d435-474f-9df8-036aab12489d"  } ],  "links" : [ {    "rel" : "help",    "href" : "https://www.payway.com.au/docs/rest.html#transactions"  } ]}');
            res.setStatusCode(422);
            res.setStatus('Unprocessable Entity');
            return res;
        }
        else if(req.getEndpoint().startsWith('https://api.payway.com.au/rest/v1/transactions/search-customer?customerNumber=')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":[{"transactionId":3087502308,"receiptNumber":"3087502308","status":"approved","transactionType":"payment","customerNumber":"19629","currency":"aud","paymentAmount":45.45,"settlementDate":"18Nov2021","links":[{"rel":"self","href":"https://api.payway.com.au/rest/v1/transactions/3087502308"}]}],"links":[{"rel":"help","href":"https://www.payway.com.au/docs/rest.html#transactions"}]}');
            res.setStatusCode(200);
            return res;
        }
        else if((req.getEndpoint() == 'https://api.payway.com.au/rest/v1/customers' || (req.getEndpoint().startsWith('https://api.payway.com.au/rest/v1/customers') 
        && req.getMethod() == 'GET')) && (!req.getBody().contains('422') && !req.getEndpoint().contains('422'))){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"schedule":{"regularSurchargeAmount":"0.00","regularPrincipalAmount":"15.00","regularPaymentAmount":"15.00","nextSurchargeAmount":"0.00","nextPrincipalAmount":"15.00","nextPaymentDate":"18 Nov 2021","nextPaymentAmount":"15.00","frequency":"fortnightly"},"paymentSetup":{"stopped":false,"paymentMethod":"creditCard","merchant":{"merchantName":"Test Merchant","merchantId":"TEST","links":[{"rel":"self","href":"https://api.payway.com.au/rest/v1/merchants/TEST"}]},"creditCard":{"surchargePercentage":0.0,"expiryDateYear":"26","expiryDateMonth":"02","cardType":"credit","cardScheme":"visa","cardNumber":"456471...004","cardholderName":"DHruv"}},"links":[{"rel":"self","href":"https://api.payway.com.au/rest/v1/customers/19622"},{"rel":"help","href":"https://www.payway.com.au/docs/rest.html#customers"},{"rel":"contact","href":"https://api.payway.com.au/rest/v1/customers/19622/contact"},{"rel":"custom-fields","href":"https://api.payway.com.au/rest/v1/customers/19622/custom-fields"},{"rel":"payment-setup","href":"https://api.payway.com.au/rest/v1/customers/19622/payment-setup"},{"rel":"schedule","href":"https://api.payway.com.au/rest/v1/customers/19622/schedule"},{"rel":"virtual-account","href":"https://api.payway.com.au/rest/v1/customers/19622/virtual-account"},{"rel":"search-customer-transactions","href":"https://api.payway.com.au/rest/v1/transactions/search-customer?customerNumber=19622"}],"customFields":{},"customerNumber":"19622","contact":{"sendEmailReceipts":false,"phoneNumber":"+61240136469","emailAddress":null,"customerName":"Nate Angus","address":{"street2":"50 Nerrigundah Drive","street1":"31 South Street","state":"TAS","postalCode":"3077","cityName":"TRANMERE"}}}');
            res.setStatusCode(200);
            res.setStatus('Created');
            return res;
        }
        else if((req.getEndpoint() == 'https://api.payway.com.au/rest/v1/customers' || (req.getEndpoint().startsWith('https://api.payway.com.au/rest/v1/customers') 
        && req.getMethod() == 'GET') && (req.getBody().contains('422') || req.getEndpoint().contains('422'))))
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "data" : [ {    "fieldName" : "singleUseTokenId",    "message" : "The cardholder must provide a CVN to conduct a payment using PayWay Net.",    "fieldValue" : "4cc0b7e7-d435-474f-9df8-036aab12489d"  } ],  "links" : [ {    "rel" : "help",    "href" : "https://www.payway.com.au/docs/rest.html#transactions"  } ]}');
            res.setStatusCode(422);
            res.setStatus('Unprocessable Entity');
            return res;
        }
        else if(req.getEndpoint().contains('schedule') && req.getMethod() == 'PUT' && !req.getBody().contains('422')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"frequency" : "fortnightly",  "nextPaymentDate" : "25 Jan 2022", "nextPrincipalAmount" : 1595.00,  "nextSurchargeAmount" : 0.00,  "nextPaymentAmount" : 1595.00,  "regularPrincipalAmount" : 1595.00,  "regularSurchargeAmount" : 0.00,  "regularPaymentAmount" : 1595.00,  "links" : [ { "rel" : "help", "href" : "https://www.payway.com.au/docs/rest.html#customers"}, {"rel" : "transaction", "href" : "https://api.payway.com.au/rest/v1/transactions/3121943451"}]}');
            res.setStatusCode(200);
            res.setStatus('Created');
            return res;
        }
        else if((req.getEndpoint().contains('schedule') && req.getMethod() == 'PUT') && req.getBody().contains('422')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "data" : [ {    "fieldName" : "singleUseTokenId",    "message" : "The cardholder must provide a CVN to conduct a payment using PayWay Net.",    "fieldValue" : "4cc0b7e7-d435-474f-9df8-036aab12489d"  } ],  "links" : [ {    "rel" : "help",    "href" : "https://www.payway.com.au/docs/rest.html#transactions"  } ]}');
            res.setStatusCode(422);
            res.setStatus('Unprocessable Entity');
            return res;
        }
        else if(req.getEndpoint().contains('payment-setup') && req.getMethod() == 'PUT' && !req.getBody().contains('merchantId=TEST&singleUseTokenId=Grj08UqKHBNjOGEw%2BgKOFcbdee4dW4VH6pr19J1xHug%3D')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "paymentMethod" : "creditCard",  "stopped" : false,  "creditCard" : { "cardNumber" : "456403...007", "expiryDateMonth" : "02", "expiryDateYear" : "30",    "cardScheme" : "visa", "cardType" : "debit", "cardholderName" : "Nutan", "surchargePercentage" : 0.0  }, "merchant" : { "merchantId" : "TEST", "merchantName" : "Test Merchant",    "links" : [ {      "rel" : "self",      "href" : "https://api.payway.com.au/rest/v1/merchants/TEST" }]}, "links" : [ { "rel" : "help", "href" : "https://www.payway.com.au/docs/rest.html#customers" }]}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
        else if((req.getEndpoint().contains('payment-setup') && req.getMethod() == 'PUT') && req.getBody().contains('merchantId=TEST&singleUseTokenId=Grj08UqKHBNjOGEw%2BgKOFcbdee4dW4VH6pr19J1xHug%3D')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "data" : [ {    "fieldName" : "singleUseTokenId",    "message" : "The cardholder must provide a CVN to conduct a payment using PayWay Net.",    "fieldValue" : "4cc0b7e7-d435-474f-9df8-036aab12489d"  } ],  "links" : [ {    "rel" : "help",    "href" : "https://www.payway.com.au/docs/rest.html#transactions"  } ]}');
            res.setStatusCode(422);
            res.setStatus('Unprocessable Entity');
            return res;
        }
        else if(req.getEndpoint().contains('payment-setup') && req.getMethod() == 'PATCH'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{  "paymentMethod" : "creditCard",  "stopped" : true,  "creditCard" : { "cardNumber" : "456403...007", "expiryDateMonth" : "02", "expiryDateYear" : "30",    "cardScheme" : "visa", "cardType" : "debit", "cardholderName" : "Nutan", "surchargePercentage" : 0.0  }, "merchant" : { "merchantId" : "TEST", "merchantName" : "Test Merchant",    "links" : [ {      "rel" : "self",      "href" : "https://api.payway.com.au/rest/v1/merchants/TEST" }]}, "links" : [ { "rel" : "help", "href" : "https://www.payway.com.au/docs/rest.html#customers" }]}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
        else {
            HttpResponse res = new HttpResponse();
            return res;
        }
    }
}