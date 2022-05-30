public with sharing class PaywayMessages 
{
    
    public static string message00 = 'The transaction has been authorised.';
    public static string message01 = 'Refer to card issuer. this may be any of the following:Suspected Fraud/Insufficient Funds/Stolen Card/Expired Card/Invalid CVN/Any other rule imposed by the card issuer that causes a decline.'; //' (e.g. daily limit exceeded, duplicate transaction suspected, etc).';
    public static string message03 = 'There is a problem with the merchant configuration. they wouldn\'t allow the transaction over the internet for an Australian bank.';
    //Need to be verified 01/03/05
    public static string message04 = 'The card has been reported as lost or stolen.';
    public static string message05 = 'Problem from the card issuer. This may be any of the following:Suspected Fraud/Insufficient Funds/Stolen Card/Expired Card/Invalid CVN/Any other rule imposed by the card issuer that causes a decline.'; //(e.g. daily limit exceeded, duplicate transaction suspected, etc).';
    public static string message08 = 'The transaction has been authorised.';
    public static string message12 = 'Transaction for the same amount and merchant is attempted multiple times quickly for the same card. The card holder should contact their issuing bank.';
    public static string message14 = 'Invalid card number (no such number).';
    public static string message17 = 'This indicates that the transaction was authorised and subsequently voided.';
    public static string message22 = 'Invalid card number.';
    public static string message34 = 'Suspected fraud. Fraud guard suspended the payment because it was unusual.';
    public static string message39 = 'No credit account (no such number).';
    public static string message40 = 'Request function not supported. The cardholder\'s bank has declined the transaction as it does not allow this type of transaction.';
    public static string message41 = 'Lost card. The card has been reported as lost or stolen.';
    public static string message42 = 'No universal account (no such number).';
    public static string message43 = 'Stolen card. The card has been reported as lost or stolen.';
    public static string message51 = 'Not sufficient funds. There is insufficient funds to charge.';
    public static string message54 = 'Expired card. Wrong expiry date has been entered for the credit card.';
    public static string message61 = 'Card holder does not have enough credit to pay the specified amount.';
    public static string message63 = 'Security violation. We have reasonable grounds to suspect fraudulent activity related to the transaction.';
    public static string message68 = 'Response received too late. The card issuer (your bank) did not respond in time.';
    public static string message91 = 'The card issuer (your bank) could not be contacted, or did not respond in time.';
    public static string message92 = 'The card number is incorrect. Financial institution or intermediate network facility cannot be found for routing.';

    public static string messageQA = 'Invalid parameters. Invalid parameters passed to API';
    public static string messageQI = 'Transaction incomplete. Request message was sent to the PayWay server but no response was received within the timeout period.';
    public static string messageQQ = 'Invalid card. Credit card details (card number, expiry date or CVN) are invalid.';
    public static string messageQY = 'Invalid card. Card type not accepted';

    //HTTP Response code
    public static string message200 = 'The request has succeeded.';
    public static string message201 = '201 Created. The server has created the resource you requested.';
    public static string message202 = '202 Accepted. The request has been accepted for processing, but the processing has not completed.';
    public static string message400 = '400 Bad request. The request could not be understood by the server due to malformed syntax.';
    public static string message403 = '403 Forbidden A valid API key was provided, but it does not have access to the requested resource.';
    public static string message404 = '404 Not found. The server has not found anything matching the Request-URI';
    public static string message405 = '405 Method not allowed. A request was made of a resource using a request method not supported by that resource.';
    public static string message406 = '406 Not acceptable. The server can not send the representation requested by the client.';
    public static string message409 = '409 The server can not process the request as it has conflicted with another request.';
    public static string message410 = '410 Gone. The server no longer has the resource.';
    public static string message415 = '415 Unsupported media type. The server can not process the content type which was provided, or the request is not allowed to have any content.';
    public static string message422 = '422 Unprocessable entity. The server can not process the content of the request.';
    public static string message429 = '429 Too many requests';
    public static string message500 = '500 Internal server error. The server encountered an unexpected condition which prevented it from fulfilling the request.';
    public static string message501 = '501 Not implemented. The server does not recognise the request method.';
    public static string message503 = '503 service unavailable. The server is currently unable to handle the request due to a temporary overloading or maintenance of the server.';
}