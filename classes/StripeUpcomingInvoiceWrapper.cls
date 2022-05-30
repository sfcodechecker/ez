public with sharing class StripeUpcomingInvoiceWrapper {
   	
	public String account_country {get;set;} 
	public String account_name {get;set;} 
	public String account_tax_ids {get;set;} 
	public Integer amount_due {get;set;} 
	public Integer amount_paid {get;set;} 
	public Integer amount_remaining {get;set;} 
	public String application_fee_amount {get;set;} 
	public Integer attempt_count {get;set;} 
	public Boolean attempted {get;set;} 
	public String billing_reason {get;set;} 
	public String charge {get;set;} 
	public String collection_method {get;set;} 
	public Integer created {get;set;} 
	public String currency_Z {get;set;} // in json: currency
	public String custom_fields {get;set;} 
	public String customer {get;set;} 
	public String customer_address {get;set;} 
	public String customer_email {get;set;} 
	public String customer_name {get;set;} 
	public String customer_phone {get;set;} 
	public String customer_shipping {get;set;} 
	public String customer_tax_exempt {get;set;} 
	public String default_payment_method {get;set;} 
	public String default_source {get;set;} 
	public String description {get;set;} 
	public String discount {get;set;}  
	public Integer due_date {get;set;} 
	public Integer ending_balance {get;set;} 
	public String footer {get;set;} 
	public String last_finalization_error {get;set;} 
	public Lines lines {get;set;} 
	public Boolean livemode {get;set;} 
	public Integer next_payment_attempt {get;set;} 
	public String number_Z {get;set;} // in json: number
	public String on_behalf_of {get;set;} 
	public Boolean paid {get;set;} 
	public Boolean paid_out_of_band {get;set;} 
	public String payment_intent {get;set;} 
	public Integer period_end {get;set;} 
	public Integer period_start {get;set;} 
	public Integer post_payment_credit_notes_amount {get;set;} 
	public Integer pre_payment_credit_notes_amount {get;set;} 
	public String quote {get;set;} 
	public String receipt_number {get;set;} 
	public Integer starting_balance {get;set;} 
	public String statement_descriptor {get;set;} 
	public String status {get;set;} 
	public Status_transitions status_transitions {get;set;} 
	public String subscription {get;set;} 
	public Integer subtotal {get;set;} 
	public String tax {get;set;} 
	public Integer total {get;set;} 
	public String transfer_data {get;set;} 
	public String webhooks_delivered_at {get;set;} 
		
	public class Status_transitions {
		public String finalized_at {get;set;} 
		public String marked_uncollectible_at {get;set;} 
		public String paid_at {get;set;} 
		public String voided_at {get;set;} 
	}
	
	public class Lines {
		public Boolean has_more {get;set;} 
		public Integer total_count {get;set;} 
		public String url {get;set;} 
	}

    public static StripeUpcomingInvoiceWrapper parse(String json){
		return (StripeUpcomingInvoiceWrapper) System.JSON.deserialize(json, StripeUpcomingInvoiceWrapper.class);
	}
}