// Would be Global
public with sharing class TransactionWrapper {
  
  public String name; // Name of customer, to create a customer.
  public Decimal amount;	// Amount in Dollar.
  public String email; // Email, to create a customer. 
  public String sfProcessingId; // Salesforce record Id, for which the one time payment is need to be done.
  public String successURL; // must include customer_id= in stripe other can skip, overrides with the <<customerGUID>>, from gateway.
  public String cancelURL; // must include customer_id= in stripe other can skip, overrides with the <<customerGUID>>, from gateway.
  public String requestUrl; //include record page url to navigate after post checkout
  // request to fetch the transaction.
  public String paymentId;
  
  // response populated when hit to gateway.
  public Boolean status; // return true if responses from gateway are valid.
  public String processingLink; // return the link for performing the setup, checkout.
  public String transResponse; // return the response in JSON serialized for payment in gateway, if no exception occured.
  public String errorResponse; // return the error message, if any exception occured.
  public String tokenValue; //return the token value from gateway.
  public String responseText; //return response text from gateway,either approved or rejected.
  
  // field wrapper for transaction records.
  public String transactionId;
  public String transactionStatus;
  public Date transactionDate; 
  public Datetime transactionDateTime;
  public String transactionType; // Onetime or Recurring.
  public String transactionreference; // Reference for transaction.
  public String transactionResponseCode; //store respone code for one time transaction
  public String logrefId; // store log id for reference.
  public String nextInvoiceId; //store the next invoice id 
  public String recurringRecordId; //store the recurring record id of transaction.
  public String jsonRequest;      //used for bpoint
  // field required for payway
  public string customerNumber;
  public string pcurrency;
  public string merchantId;
  public String encodedCustomerNumber;
	public String httpResponseStatus;
  public String transactionPayload;
  public string actiontype;

  public static TransactionWrapper parse(String json){
    return (TransactionWrapper) System.JSON.deserialize(json, TransactionWrapper.class);
  }
}