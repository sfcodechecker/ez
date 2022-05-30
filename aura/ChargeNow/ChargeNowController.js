({
    doInit: function(component, event, helper){
        window.addEventListener("message", function(event1) {
            if(event1.data == "Refresh_Detail_Page_by_Stripe" && 
               (event1.origin.search(".visualforce.com") > 0 || event1.origin.search(".force.com") > 0 
                || event1.origin.search(".salesforce.com") > 0 || event1.origin.search(".salesforceliveagent.com") > 0 
                || event1.origin.search(".lightning.com") > 0 || event1.origin.search(".salesforce-communities.com") > 0
                || event1.origin.search(".documentforce.com") > 0 || event1.origin.search(".forceusercontent.com") > 0 
                || event1.origin.search(".forcesslreports.com") > 0 || event1.origin.search(".salesforce-hub.com") > 0))
            {  
                $A.get('e.force:refreshView').fire(); 
            }
        });
        component.set('v.showSpinner', true);
        var action = component.get("c.ActivePaymentList");
        action.setCallback(this,function(response){
            var state = response.getState();
            console.log(state);
            console.log(response);
            console.log(response.getReturnValue());
            if (state === "SUCCESS") {
                var result = response.getReturnValue();   
                component.set('v.GatewayList',result);
                component.set('v.showSpinner', false);
                if(result.length > 0)
                    component.set('v.SelectedGateway',result[0].value);
                else if(result==null || result.length==0){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get("v.NoGatewaysFound")});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    return;
                } 
                    
            }else{
                helper.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    handleGatewayChange : function(component, event, helper) { 
        component.set("v.SelectedGateway",event.getParam("value"));
        component.set("v.SelectedFrequency",null); 
        if(component.get("v.SelectedChargeType") == 'recurring')
            helper.FrequencyHandler(component, event);
    },
    handleFrequencyChange : function(component, event) { 
        component.set("v.SelectedFrequency",event.getParam("value"));   
    },
    handleChargeTypeChange: function(component,event,helper){
        component.set("v.SelectedChargeType",event.getParam("value"));
        var dt = new Date();
        var today = dt.getFullYear()+'-'+(dt.getMonth()+1)+'-'+dt.getDate(); 
        if(component.get("v.SelectedChargeType") == 'onetime'){
            component.set("v.isRecurring",false);
            component.set("v.ChargeButtonLabel","Charge");
        }else if(component.get("v.SelectedChargeType") == 'recurring'){
            component.set("v.isRecurring",true);
            component.set("v.SelectedInstalmentDate", today);
            component.set("v.MinimumInstalmentDate", today);
            component.set("v.ChargeButtonLabel","Setup");
            helper.FrequencyHandler(component, event);
        }

    }, 
   /* handleActiveTab : function(component, event, helper) { 
        var tab = event.getSource();
        component.set("v.SelectedChargeType",tab.get('v.id'));
        component.set("v.ChargeButtonLabel","Charge");
        if(component.get("v.SelectedChargeType") == 'recurring'){
            var dt = new Date();
            var today = dt.getFullYear()+'-'+(dt.getMonth()+1)+'-'+dt.getDate();            
            component.set("v.SelectedInstalmentDate", today);
            component.set("v.MinimumInstalmentDate", today);
            component.set("v.ChargeButtonLabel","Setup");
            helper.FrequencyHandler(component, event);
        }           
    },*/
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        $A.get("e.force:closeQuickAction").fire();
    },  
    chargePayment : function(component, event, helper) {        
        var selectedCharge = component.get("v.SelectedGateway");
        var selectedChargeType = component.get("v.SelectedChargeType");
        var selectedFrequency = component.get("v.SelectedFrequency");
        var amount = component.get("v.ChargeAmount");
        var selectedInstallmentDate = component.get("v.SelectedInstalmentDate");
        var selectedGateway = component.get("v.SelectedGateway");
        
        if(selectedGateway == undefined){

            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.NoGateway")});
            toastEvent.fire();
            return;
        }
        else if(selectedChargeType == 'recurring' && selectedGateway == undefined && selectedFrequency == undefined && selectedInstallmentDate == undefined && amount == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.RequiredFields")});
            toastEvent.fire();
            return;
        }
         else if(selectedChargeType == 'recurring' && selectedFrequency == undefined && selectedInstallmentDate == undefined && amount == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.AmtDateFrequency_NotSpecified")});
            toastEvent.fire();
            return;
        }
        else if(selectedChargeType == 'recurring' && selectedInstallmentDate == undefined && amount == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.AmtDate_NotSpecified")});
            toastEvent.fire();
            return;
        } else if(selectedChargeType == 'recurring' && selectedFrequency == undefined && amount == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.AmtFreq_NotSpecified")});
            toastEvent.fire();
            return;
        }else if(selectedChargeType == 'recurring' && selectedFrequency == undefined && selectedInstallmentDate == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.FreqDate_NotSpecified")});
            toastEvent.fire();
            return;
        }       
        else if(amount==undefined || amount <= 0 || amount.toString().length==0){
            var amountMessage=component.get("v.ValidAmount");
            console.log(amountMessage);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": amountMessage});
            toastEvent.fire();
            return;
        }
        else if(selectedChargeType == 'recurring' && selectedFrequency == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.Frequency_NotSpecified")});
            toastEvent.fire();
            return;
        }    
        else if(selectedChargeType == 'recurring' && selectedInstallmentDate == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get("v.InstallmentDate_NotSpecified")});
            toastEvent.fire();
            return;
        }
       



        if(selectedCharge != undefined){
            component.set('v.showSpinner', true);
            if(selectedCharge.toLowerCase() == 'stripe' && selectedChargeType == 'onetime'){
                helper.ChargeStripe(component, event); // Stripe One Time
            }else if(selectedCharge.toLowerCase() == 'stripe' && selectedChargeType == 'recurring'){
                helper.ScheduleStripe(component, event); // Stripe Recurring
            }else if(selectedCharge.toLowerCase() == 'bpoint' && selectedChargeType == 'onetime') {
                helper.chargeBpoint(component, event); // BPoint One Time
            }else if(selectedCharge.toLowerCase() == 'bpoint' && selectedChargeType == 'recurring'){
                helper.ScheduleBpoint(component, event); // BPoint Recurring
            }else if(selectedCharge.toLowerCase() == 'simplify' && selectedChargeType == 'onetime') {
                helper.chargeSimplify(component, event); // Simplify One Time
            }else if(selectedCharge.toLowerCase() == 'simplify' && selectedChargeType == 'recurring'){
                helper.ScheduleSimplify(component, event); // Simplify Recurring
            }else if(selectedCharge.toLowerCase() == 'ezidebit' && selectedChargeType == 'onetime'){
                helper.ChargeEzidebit(component,event); // Ezidebit One Time
            }else if(selectedCharge.toLowerCase() == 'ezidebit' && selectedChargeType == 'recurring'){
                helper.ScheduleEzidebit(component, event); // Ezidebit Recurring
            }else if(selectedCharge.toLowerCase() == 'payway' && selectedChargeType == 'onetime'){
                helper.ChargePayway(component,event); // Payway One Time
            }else if(selectedCharge.toLowerCase() == 'payway' && selectedChargeType == 'recurring'){
                helper.SchedulePayway(component, event); // Payway Recurring
            }else if(selectedCharge.toLowerCase() == 'nab_transact' && selectedChargeType == 'onetime'){
                helper.ChargeNABTransact(component,event); // NAB One Time
            }else if(selectedCharge.toLowerCase() == 'nab_transact' && selectedChargeType == 'recurring'){
                helper.ScheduleNABTransact(component, event); // NAB Recurring
            }
        }else{            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": "No payment gateway found."});
            toastEvent.fire();
        }
    }
})