public class SimplifyInvoiceWrapper {

	public class Order {
		public Customer_Z customer;

	}
	public class LatestInvoice {
		public String id ;

	}	
	
	public Integer total ;
	public Integer offset ; 
	public Sorting sorting ;
	public Filter filter ; 
	public Integer max ; 
	public List<List_Z> list_Z ; // in json: list
	
	public class Customer {
		public String id ;
		public String name ; 
		public String email ; 

	}
	
	public class Customer_Z {
		public String reference ;
	}
	
	public class Sorting {

		
	}
	
	public class Card {
		public String id ; 
		public String name ; 
		public String type ; 
		public String last4 ; 
		public Integer expMonth ; 
		public Integer expYear ; 
		public Long dateCreated ;
		public String cardEntryMode ; 
		public String indicator ;
		public String indicatorSource ;

		
	}
	
	public class Payment {
		public Card card  ;
		public Boolean disputed;  
		public Integer amount ;
		public Boolean avsZipMatch ; 
		public Boolean avsCvcMatch ; 
		public Boolean avsAddressMatch ;
		public Integer amountRemaining ; 
		public Customer customer;
		public String currency_Z ; // in json: currency
		public String description ; 
		public Boolean refunded ; 
		public String authCode ;
		public String paymentStatus ;
		public Long dateCreated ; 
		public String createdBy ; 
		public Long paymentDate ;
		public String id ; 
		public TransactionData transactionData; 
		public Integer fee ; 
		public String feeCurrency ; 
		public Integer refundedFees ; 
		public Boolean feeEstimated ; 
		public String source ;
		public String declineReason;

	}
	
	public class List_Z {
		public String id ; 
		public Payment payment ;
		public Customer customer ;
		public String status ; 
		public Integer lateFee ;
		public String currency_Z ;// in json: currency
		public Long invoiceDate ; 
		public Long dueDate ; 
		public Long datePaid ;
		public Long dateCreated ; 
		public Long lastViewed ; 
		public List<Items> items ; 
		public Boolean isLate ;
		public Integer subTotal ; 
		public Integer totalTax;
		public Integer totalFees;
		public Integer totalDiscount; 
		public Integer total ; 
		public String uuid; 
		public String type; 

		
	}
	
	public class Filter {
		public String customer ;
		public String datePaidMin ; 

		
	}
	
	public class Items {
		public Long dateCreated ; 
		public String apiId ; 
		public Integer amount ; 
		public String description ; 
		public Subscription subscription ; 
		public String type ;

		
	}
	
	public class TransactionData {
		public Integer amount ; 
		public String currency_Z ; // in json: currency
		public String description;
		public String date_Z ; // in json: date
		public Order order ; 

	}
	
	public class Subscription {
		public String id ;
		public Long currentPeriodStart ; 
		public Long currentPeriodEnd ; 
		public Long start ;
		public String status ; 
		public String name ;
		public String frequency ; 
		public Integer amount ;
		public String currency_Z ; // in json: currency
		public LatestInvoice latestInvoice ;
		public Boolean custom ;
		public Customer customer ;
		public Integer frequencyPeriod ; 
		public String billingCycle ; 
		public Long dateCreated ; 
		public Boolean pendingPayment;

		
	}
	
	
	/*public static SimplifyInvoiceWrapper parse(String json) {
		return (SimplifyInvoiceWrapper)JSON.deserialize(json, SimplifyInvoiceWrapper.class);
	}*/

}