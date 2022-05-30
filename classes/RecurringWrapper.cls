// Would be Global
public with sharing class RecurringWrapper {
  public String name; // Name of customer, to create a customer.
  public String email;  // Email, to create a customer.
  public Date startDate; // Speicify the start date of recurring.
  public String startDateUnix; // Speicify the start date of recurring.
  public Decimal amount;	// Amount in Dollar.
  public String instalPeriod; // Specify the frequency. 
  public String sfProcessingId; // Salesforce record Id, for which the recurring is need to be done.
  public String sfRecurringId; // Salesforce record Id, for which the recurring is need to be done.
  public String successURL; // must include customer_id= in stripe other can skip, overrides with the <<customerGUID>>, from gateway.
  public String cancelURL; // must include customer_id= in stripe other can skip, overrides with the <<customerGUID>>, from gateway.
  public String transactionType; // Onetime or Recurring.
  public String transactionreference; // Reference for transaction.
  public String duration;//duration of recurring payment
  public String tokenValue; //return the token value from gateway.
  public String renderPanel; //return value for what to render on vf page.
  public String logrefId; // store log id for reference.
  public String responseMessage;
  public String responseCode;
  public String requestUrl;
  public String recurringAbbr; //used to store abbrevations for create new schedule in Ezidebit 
  public Long trialDays;
  public String trialPeriod;
  public String planId;
  public String jsonRequest; //used to store request for bpoint
  //refund information
  public String refundId; //refund Id from gateway.
  public String refundStatus; //refund status to be stored in sf.
  public Datetime refundTime; //refund time.
  public String refundDesc; // refund description.
  public String refundReference; // refund reference from gateway.
  public String nextInvoiceId;
  public Integer refundAmount; //refund amount

  //card information
  public String cardHolderName; //Card holder name on card.
  public String cardExpiryDate;  //Card expiry date.
  public String cardExpiryYear; //Card expiry year.
  public String cardExpiryMonth; //Card expiry month.
  public String cardNumber;  //Card number.

  // request fields
  public String recurringRequestId; // Specify the request Id to fetch the recurring details.
  public String customerId; //Specify the customer Id from Gateway.

  // response populated when hit to gateway.
  public Boolean status; // return true if responses from gateway are valid.
  public String processingLink; // return the link for performing the setup, checkout.
  public String recurringResponse; // return the response in JSON serialized for recurring setup in gateway, if no exception occured.
  public String paymentResponse;
  public String errorResponse; // return the error message, if any exception occured.
  public String validationResponse;
  public List<TransactionWrapper> transactionList; // return the list of transaction for a recurring.
  
  //field required for Payway recurring
  public string merchantId;
  public String nextPaymentDate;
  public string transactionPayload;
  public String paymentStatus;
  public date paymentStartDate;
  public String customerNumber;
  public String httpResponseStatus;
  public Integer httpResponseStatuscode;
  public CardInformation cardDetails;

  public class CardInformation{
    public String CardHolderName;
    public String CardNumber;
    public String ExpiryMonth;
    public String ExpiryYear;
    public String ErrorMessage;
  }

  public static RecurringWrapper parse(String json){
    return (RecurringWrapper) System.JSON.deserialize(json, RecurringWrapper.class);
  }
}