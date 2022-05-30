public with sharing class RecurringPaymentIterator implements iterator<Recurring_Payment__c>{

    private List<Recurring_Payment__c> complete_RP_list;
    private Integer currentIndex;
    
    public RecurringPaymentIterator(List<Recurring_Payment__c> complete_RP_list){
        this.complete_RP_list = complete_RP_list;
        this.currentIndex = 0;
    }
    
    public boolean hasNext(){
        return currentIndex < complete_RP_list.size();
    }    
    
    public Recurring_Payment__c next(){
        if(hasNext()) {
            currentIndex++;
            return complete_RP_list[currentIndex - 1];
        } else {
            throw new NoSuchElementException();
        }
    }
}