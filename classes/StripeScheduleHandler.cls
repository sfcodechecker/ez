public with sharing class StripeScheduleHandler {

    public static StripePlanWrapper createStripePlanWrapper(Decimal Amount, String InstalPeriod) {
        StripePlanWrapper plan_wrapper = new StripePlanWrapper();
        plan_wrapper.amount_decimal = Integer.valueOf(Amount * 100);
        InstalPeriod = InstalPeriod.trim().toLowerCase();
        switch on InstalPeriod{
            when 'weekly' {		
                plan_wrapper.interval = 'week';
            }
            when 'monthly' {		
                plan_wrapper.interval = 'month';
            }
            when 'yearly' {		  
                plan_wrapper.interval = 'year';
            }
            when 'quarterly'{
                plan_wrapper.interval = 'month';
                plan_wrapper.interval_count = ''+3;
            } 	
            when 'fortnightly'{
                plan_wrapper.interval = 'day';
                plan_wrapper.interval_count = ''+15;
            } 	
            when 'daily'{
                plan_wrapper.interval = 'day';
                plan_wrapper.interval_count = ''+1;
            }  	
            when 'half yearly'{
                plan_wrapper.interval = 'month';
                plan_wrapper.interval_count = ''+6;
            }
            when else{
                List<String> instalmentValues = InstalPeriod.split('-');
                if(instalmentValues!= null && instalmentValues.size() == 2 ){
                    plan_wrapper.interval_count = ''+instalmentValues[0];
                    switch on instalmentValues[1] {
                        when 'days' {		
                            plan_wrapper.interval = 'day';
                        }
                        when 'weeks' {	
                            plan_wrapper.interval = 'week'; 
                        }
                        when 'months' {		
                            plan_wrapper.interval = 'month'; 
                        }
                        when 'years' {
                            plan_wrapper.interval = 'year'; 
                        }
                    }
                }
            }
        }
        plan_wrapper.product = StripeManager.StripeGateWay.Optional_Key_1__c; 
        plan_wrapper.Currency_z = 'AUD';
        return plan_wrapper;        
    }    

    public static String convertPlanToInstalmentPeriod(String interval, Integer interval_count) {

        if(interval_count == 1 && interval == 'day')
            return 'Daily';
        else if(interval_count == 1 && interval == 'week')
            return 'Weekly';
        else if(interval_count == 1 && interval == 'month')
            return 'Monthly';
        else if(interval_count == 1 && interval == 'year')
            return 'Yearly';
        else if(interval_count == 15 && interval == 'day')
            return 'Fortnightly';
        else if(interval_count == 3 && interval == 'month')
            return 'Quarterly'; 
        else if(interval_count == 6 && interval == 'month')
            return 'Half Yearly'; 
        else
            return null;
    }


}