({    
    /*
     * @description do server side call to fetch current data of gateways info on load of the comonent.
     */ 
    doInit: function(component, event, helper){
        /*var action = component.get("c.getActivePaymentList");     NOT IN USE
        action.setCallback(this,function(response){
            var state=response.getState();
            if(state==="SUCCESS"){
                var result=response.getReturnValue();
                console.log(result);
                if(result.length > 0){
                   /* component.set('v.ActiveGateways',response.getReturnValue());
                    component.set("v.selectedGateway",result[0].value.toUpperCase().replaceAll('_',' '));
                    component.set("v.isDefault",result[0].isdefault);
                }else{
                    component.set("v.GatewaysExist",false);
                }       
            }else{
                helper.ParseError(component,event,repsonse);
            }
        });
        $A.enqueueAction(action);*/     
    },
    
    /*******Handles the gateway change for drop down**********/
    GatewayChange : function(component, event, helper){
        component.set("v.selectedGateway",component.find("gatewayID").get("v.value"));
    },
    
    /*******Changes the default gateway************/
    ChangeDefaultGateway : function(component,event,helper){
        component.set("v.selectedGateway",component.get("v.selectedGateway"));
        component.set("v.isDefault",false);
    },
    
    /**********Sets the default gateway************/
    SetDefaultGateway : function(component,event,helper){
        var ActivePaymentsList = component.get('v.ActiveGateways');
        if(ActivePaymentsList.length==0){
            return;
        }
        helper.handleGatewayChange(component,event);
        component.set("v.isDefault",true);
        var gatewayName=component.get("v.selectedGateway");
        component.set("v.selectedGateway",gatewayName.replaceAll('_',' '))

    },

    handleComponentEvent : function(component,event){
        var gatewayObject={label:event.getParam('label'),value:event.getParam('value'),isdefault:event.getParam('isdefault')};
        var ActiveGateways=component.get("v.ActiveGateways");
        var GatewayEvent=event.getParam("value");
       
        if(GatewayEvent!=undefined && ActiveGateways.find(element => element.value == GatewayEvent) == undefined){
            ActiveGateways.push(gatewayObject);
            component.set("v.ActiveGateways",ActiveGateways);
            if(gatewayObject.isdefault){
                component.set("v.isDefault",true);
                component.set("v.selectedGateway",gatewayObject.value);
            }
            var isGateway=component.get("v.GatewaysExist");
            if(!isGateway){
                component.set("v.GatewaysExist",true);
            }
        }
        

    }
})