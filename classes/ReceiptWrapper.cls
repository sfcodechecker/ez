//Would be global
public with sharing class ReceiptWrapper {

    //common fields.
    public Decimal amount; //charged amount.
    public String paymentStatus; //payment status approved/rejected.
    public String paymentResponse; //payment response from gateway.
    public String responseText; //response text from gateway.
    public String chargeType; //type of charge to determine receipt
    public String requestUrl; //navigate back to salesforce
    //one-off specific fields.
    public String  paymentId; //payment/transaction Id from gatetway in case of one-off payment.

    //Recurring specific fields.
    public String installPeriod; //installment period for recurring payment.
    public Date establishmentDate; //date of establishment for recurring payment.
    public Date nextInstallmentDate; //next installment date for recurring payment.
    public String renderPanel; //renderPanel specific to NAB Transact.
    
}