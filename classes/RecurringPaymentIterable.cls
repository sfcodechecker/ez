public with sharing class RecurringPaymentIterable implements Iterable<Recurring_Payment__c>{

    public Iterator<Recurring_Payment__c> iterator(){
        List<Recurring_Payment__c> complete_RP_list = new List<Recurring_Payment__c>();

        List<Recurring_Payment__c> recurring_payments_list = [Select Id, Name, Amount__c, Date_Established__c, Duration__c, Gateway_Name__c, Gateway_Refund_Id__c, Gateway_Schedule_Id__c, Installment_Period__c, Next_Installment_Date__c, Refund_Amount__c, Refund_Date__c, Refund_Description__c, Refund_Status__c, Secured_Token__c, RelatedToId__c, Status__c From Recurring_payment__c Where Refund_Status__c = 'Awaiting' OR (Duration__c = 'Ongoing' AND Status__c = 'open' AND Next_Installment_Date__c <= Today ) WITH SECURITY_ENFORCED]; 

        for(Recurring_Payment__c currentRP : recurring_payments_list){
            if(currentRP.Refund_Status__c == 'Awaiting'){
                complete_RP_list.add(currentRP);
            }
            if(currentRP.Duration__c == 'Ongoing' && currentRP.Status__c == 'open'){
                complete_RP_list.add(currentRP);
            }
        }
        
        return new RecurringPaymentIterator(complete_RP_list);
    }    
}