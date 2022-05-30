public with sharing class StripeInvoiceWrapper{
	public List<data> data;
	public boolean has_more;
	public String url;	
	public class data {
		public String id;
		public Integer amount_due;	
		public Integer amount_paid;	
		public Integer amount_remaining;
		public String charge;	
		public String collection_method;
		public boolean paid;
		public String payment_intent;	
		public String status;
		public status_transitions status_transitions;
		public String subscription;	
		public Integer subtotal;	
		public tax tax;
        public Integer period_end;	
        public Integer period_start;
        public Integer created;
		public tax_percent tax_percent;
		public Integer total;	
		public total_tax_amounts[] total_tax_amounts;
		public Integer webhooks_delivered_at;	
	}
	public class status_transitions {
		public Integer finalized_at;
		public marked_uncollectible_at marked_uncollectible_at;
		public voided_at voided_at;
	}
	class marked_uncollectible_at {
	}
	class voided_at {
	}
	class tax {
	}
	class tax_percent {
	}
	class total_tax_amounts {
	}
	public static StripeInvoiceWrapper parse(String json){
		return (StripeInvoiceWrapper) System.JSON.deserialize(json, StripeInvoiceWrapper.class);
	}
}