public class BpointTxnResponseWrapper{

	public cls_APIResponse APIResponse;
	public cls_TxnResp TxnResp;
	public class cls_APIResponse {
		public Integer ResponseCode;	
		public String ResponseText;	
	}
	public class cls_TxnResp {
		public String Action;	
		public Decimal Amount;
		public Decimal AmountOriginal;	
		public Decimal AmountSurcharge;	
		public String AuthoriseId;
		public String BankResponseCode;
		public cls_CardDetails CardDetails;
		public String CardType;	
		//public String Currency;	
		public String MerchantReference;	
		public boolean IsThreeDS;
		public boolean IsCVNPresent;
		public String MerchantNumber;	
		public String ProcessedDateTime;	
		public String RRN;	
		public String ReceiptNumber;
		public String Crn1;
		public String Crn2;
		public String Crn3;
		public String ResponseCode;
		public String ResponseText;
		public String SettlementDate;
		public String Source;	
		public boolean StoreCard;
		public boolean IsTestTxn;
		public String SubType;
		public String TxnNumber;
		public String Type;	
		public cls_FraudScreeningResponse FraudScreeningResponse;
		public cls_StatementDescriptor StatementDescriptor;
	}
	public class cls_CardDetails {
		public String CardHolderName;
		public String ExpiryDate;
		public String MaskedCardNumber;
		public String Category;	
		public String Issuer;
		public String IssuerCountryCode;
		public String Localisation;
		public String SubType;
	}
	public class cls_FraudScreeningResponse {
		public cls_ReDResponse ReDResponse;
		public String ResponseCode;
		public String ResponseMessage;
		public boolean TxnRejected;
	}
	public class cls_ReDResponse {
		public String FRAUD_REC_ID;	
		public String FRAUD_RSP_CD;	
		public String FRAUD_STAT_CD;
		public String ORD_ID;	
		public String REQ_ID;	
		public String STAT_CD;	
	}
	public class cls_StatementDescriptor {
		public String AddressLine1;
		public String AddressLine2;
		public String City;	
		public String CompanyName;
		public String CountryCode;
		public String Postcode;
		public String State;
		public String MerchantName;
		public String PhoneNumber;
	}
	public static BpointTxnResponseWrapper parse(String json){
		return (BpointTxnResponseWrapper) System.JSON.deserialize(json, BpointTxnResponseWrapper.class);
	}
}