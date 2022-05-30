public with sharing class PaywayCustPymtRespWrapper {
	
	public List<Data> data; 
	public List<Links> links; 
	
	public class Data {
		public Long transactionId; 
		public String receiptNumber; 
		public String status; 
		public String transactionType; 
		public String customerNumber; 
		public String currency_Z;
		public Double paymentAmount; 
		public String settlementDate; 
		public String declinedDate; 
		public List<Links> links; 
	}

	public Boolean updateSchedule;
	public class Links {
		public String rel; 
		public String href; 
	}
}