public with sharing class PaywayTransactionResponseWrapper 
{
    public String transactionId; 
	public String receiptNumber; 
	public String status; 
	public String responseCode; 
	public String responseText; 
	public String transactionType; 
	public String customerNumber; 
	public String customerName; 
	public String currency_Z;
	public Double principalAmount; 
	public Double surchargeAmount; 
	public Double paymentAmount; 
	public String paymentMethod; 
	public CreditCard creditCard; 
	public Merchant merchant; 
	public String transactionDateTime; 
	public String settlementDate; 
	public String declinedDate; 
	public Boolean isVoidable; 
	public Boolean isRefundable; 
	public List<Links> links; 
	public String httpResponseStatus;
	public Integer httpResponseStatusCode;
	public String errorResponse;
	public String recurringID;
	public string recordtypeID ;
	public string transactionReference ;


	
	public class Merchant {
		public String merchantId; 
		public String merchantName; 
		public List<Links> links; 

	}
	
	public class Links {
		public String rel; 
		public String href; 

	}
	
	public class CreditCard {
		public String cardNumber; 
		public String expiryDateMonth; 
		public String expiryDateYear; 
		public String cardScheme; 
		public String cardType; 
		public String cardholderName; 
	}

	public List<Data> data;
    public class Data 
    {
        public String fieldName;
        public String message;
        public String fieldValue;
    }
}