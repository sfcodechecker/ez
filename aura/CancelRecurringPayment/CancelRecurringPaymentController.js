({
    doInit : function(component, event, helper){
       component.set('v.showSpinner',true);
       var action = component.get('c.getRecurringRecord');
        action.setParams({"recordId":component.get('v.recordId')});
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state==='SUCCESS'){
                component.set('v.RecurringDetails',response.getReturnValue());
                var result=response.getReturnValue();
                
                if(result[0].Q_Charge__Status__c=='Cancelled' || result[0].Q_Charge__Status__c =='Closed'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.RPAlreadyClosed')});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
                else if(result[0].Q_Charge__Gateway_Name__c != null){
                    var checkIsConnected = component.get("c.isGatewayConnected");
                    checkIsConnected.setParams({"gatewayName":result[0].Q_Charge__Gateway_Name__c});
                    checkIsConnected.setCallback(this,function(response){
                            var state = response.getState();
                            var result = response.getReturnValue();
                            if(state === "SUCCESS"){
                                if(result == false){
                                    $A.get("e.force:closeQuickAction").fire();
                                    component.set('v.showModel',false);
                                    var toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({"type":"warning","message": component.get('v.DiscontinueRPOnDisconnectedGateway')});
                                    toastEvent.fire();
                                    return;
                                }else{
                                    component.set('v.showSpinner',false);
                                    component.set('v.showModel', true);
                                    component.set("v.isDisabled",false);
                                }
                            }
                    });
                    $A.enqueueAction(checkIsConnected);
                }
                
            }else{
             helper.ParseError(component,event,response);   
            }
        });
        $A.enqueueAction(action);

    },
    
	confirm : function(component, event, helper) {
        component.set('v.showSpinner',true);
        var obj=component.get('v.RecurringDetails');
        var gatewayName = component.get('v.RecurringDetails[0].Q_Charge__Gateway_Name__c');
        gatewayName=gatewayName.toLowerCase().replaceAll(' ','_');
        switch(gatewayName){
            case 'stripe':
                helper.cancelStripeRP(component,event);
                break;
               
            case 'payway':
                helper.cancelPaywayRP(component,event);
                break;
                
            case 'nab_transact':
                helper.cancelNABTransactRP(component, event);
                break;
                
            case 'ezidebit':
                helper.cancelRPEzidebit(component,event);
                break;
                
            case 'bpoint':
                break;
                
            case 'simplify':
                helper.cancelRPSimplify(component,event);
                break;
                
            default:
   	
        }
			
	},
    
    closeModal : function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
    }
    
})