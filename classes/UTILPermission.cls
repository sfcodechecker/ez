public with sharing class UTILPermission {

    /** @description  exception Class for Field Level & Object Security errors. */
    public virtual class PermsException extends Exception {
        
        // Use this contrcutor when using object -> field permission
        public PermsException(String objectName, String fieldname, String accessType){
            this('Insufficient Privileges. No '+accessType+' access on '+objectName+'('+fieldname+'). Please contact your system  administrator.');
        }
    }
    
    // Always pass the object name with naqmespace included, eg: Q_Charge__Gateway_Detail__c
    // Only check all custom fields.
    public static Boolean CheckSingleObject(String objectName, String PermissionType){
        Set<String> ObjectFieldSet = new Set<String>();
        PermissionType =  PermissionType.toLowercase();
        if(PermissionType != 'delete'){
            for(Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                if(field.getDescribe().isCustom())
                    ObjectFieldSet.add(field.getDescribe().getName());
            }
        }
        CheckMultiObject(new LIST<Perms>{new Perms(PermissionType,objectName,ObjectFieldSet)});
        return true;
    }

    // Check the permission for multiple object.
    public static Boolean CheckMultiObject(List<Perms> PermissionList){
        for(Perms eachPerm : PermissionList){
            eachPerm.PermissionType =  eachPerm.PermissionType.toLowercase();
            if(eachPerm.PermissionType == 'delete'){
                if (!Schema.getGlobalDescribe().get(eachPerm.ObjectName).getDescribe().isDeletable() ) {
                    throw new PermsException( eachPerm.ObjectName, '', eachPerm.PermissionType);
                }
            }else{
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(eachPerm.ObjectName).getDescribe().fields.getMap(); 
                for(String singleField : eachPerm.ObjectFieldSet){
                    if( (eachPerm.PermissionType == 'create' && !fieldMap.get(singleField).getDescribe().isCreateable()) ||
                        (eachPerm.PermissionType == 'update' && !fieldMap.get(singleField).getDescribe().isUpdateable()) ||
                        (eachPerm.PermissionType == 'upsert' && !fieldMap.get(singleField).getDescribe().isCreateable() &&
                         !fieldMap.get(singleField).getDescribe().isUpdateable()) ||  
                        (eachPerm.PermissionType == 'read'   && !fieldMap.get(singleField).getDescribe().isAccessible()) ){
                            throw new PermsException( eachPerm.ObjectName, singleField, eachPerm.PermissionType);
                    } 
                }
            }
        }        
        return true;
    }

    
    // Always pass the object name with naqmespace included, eg: Q_Charge__Gateway_Detail__c 
    public static Boolean CheckSinglePerm(String PermissionType, String objectName, Set<String> ObjectFieldSet ){ 
        CheckMultiObject(new LIST<Perms>{new Perms(PermissionType.toLowercase(),objectName,ObjectFieldSet)});
        return true;
    }

    /********** Perms Wrapper ***********************/
    public class Perms {
        public String PermissionType; // PermissionType => Create || Update || Upsert || Read || Delete
        public String ObjectName;
        public Set<String> ObjectFieldSet;
        public Perms(String PermissionType,String ObjectName, Set<String> ObjectFieldSet) {
            this.PermissionType = PermissionType; this.ObjectName = ObjectName; this.ObjectFieldSet = ObjectFieldSet;
        }
    }
}