({
    doInit : function(component,event,helper){
        component.set("v.showSpinner",true);
        
        helper.getRecurringRecord(component,event);
        
        window.addEventListener("message", function(event1) {
            if(event1.data.type == "UpdateCardDetails" && 
               (event1.origin.search(".visualforce.com") > 0 || event1.origin.search(".force.com") > 0 
                || event1.origin.search(".salesforce.com") > 0 || event1.origin.search(".salesforceliveagent.com") > 0 
                || event1.origin.search(".lightning.com") > 0 || event1.origin.search(".salesforce-communities.com") > 0
                || event1.origin.search(".documentforce.com") > 0 || event1.origin.search(".forceusercontent.com") > 0 
                || event1.origin.search(".forcesslreports.com") > 0 || event1.origin.search(".salesforce-hub.com") > 0))
            { 
                $A.get('e.force:refreshView').fire();  
                if(event1.data.message.includes('successfully')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"success","duration": 20000,"message": event1.data.message});
                    toastEvent.fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"error","message": event1.data.message});
                    toastEvent.fire();
                }
                
            }
        });
    },
   
    closeModel : function(component,event){
        $A.get("e.force:closeQuickAction").fire();
    },
    
    confirm : function(component,event,helper){
       helper.updateCardDetails(component,event);

    }
})