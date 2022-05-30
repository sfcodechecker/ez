//Trigger to stop manual edit of Recurring Payment record. 
trigger RecurringPaymentTrigger on Recurring_Payment__c (before update) {
    if(trigger.isBefore && trigger.isUpdate){
        for(Recurring_Payment__c rpInfo : Trigger.new){
            if(!System.isBatch() && !System.isFuture() && !System.isQueueable() && !System.isScheduled() && UTILGateway.allowRPUpdate == false){
                    rpInfo.addError('Recurring Payment Can\'t be updated. Please use "Update Recurring Payment" button to update.');   
            }       
        }
    }
}