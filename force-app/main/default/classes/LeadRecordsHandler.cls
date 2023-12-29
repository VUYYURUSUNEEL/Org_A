public with sharing class LeadRecordsHandler {
    public static void CreateBulkLeadRecords() {
        List<Lead> leadList = new List<Lead>();
        
        // Define Lead Sources
        String[] leadSources = new String[] {'Web', 'Phone Inquiry', 'Partner Referral', 'Purchased List'};
            Integer leadSourceIndex = 0;
        
        // Create 1000 Lead records with different Lead Sources
        for(Integer i = 0; i < 1000; i++) {
            Lead ld = new Lead();
            ld.FirstName = 'Lead';
            ld.LastName = ' - ' + i;
            ld.Company = 'Company ' + i;
            ld.LeadSource = leadSources[leadSourceIndex];
            leadList.add(ld);
            
            // Update Lead Source for the next Lead record
            leadSourceIndex++;
            if(leadSourceIndex == leadSources.size()) {
                leadSourceIndex = 0; // Reset index to rotate through Lead Sources
            }
        }
        
        // Insert Lead records
        insert leadList;
        System.debug('1000 Lead records with different Lead Sources have been created.');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeads(String searchTerm, String selectedSource) {
        String searchTermLike = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        String sourceFilter = (selectedSource != null && selectedSource != '') ? 'AND LeadSource = :selectedSource' : '';
        
        // Query leads with search term, lead source, and pagination
        String query = 'SELECT Id, Name, LeadSource FROM Lead ' +
            'WHERE (Name LIKE :searchTermLike OR Company LIKE :searchTermLike) ' + sourceFilter +
            ' ORDER BY Name';
        List<Lead> leadList = Database.query(query);
        return leadList;
    }
    
    @AuraEnabled
    public static String syncContact(){
        List<String>emailList =  getContactsEmail();
        List<Contact> newCon = [Select FirstName , LastName , Email From Contact Where Email NOT IN : emailList AND Email != NULL LIMIT 50000];
        System.debug('newCon--'+newCon);
        
        if(newCon != null && newCon.size() > 0){
            String returnString  = syncContactInTargetOrg(newCon);
            if(returnString == '1'){
                return 'Contacts are synced successfully.';
            }else if(returnString == '0'){
                return 'Error';
            }
            return null;
        }else{
            return 'Contacts are already Synced.';
        }
    }	
    
    public static List<String> getContactsEmail(){
        try{
            Http http = new Http();
            HTTPResponse response;
            HttpRequest request;
            request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint('callout:S2S/services/apexrest/ContactMapping/');
            response = http.send(request);
            List<String> emailList = (List<String>)JSON.deserialize(response.getBody() , List<String>.class);
            return emailList;
        }catch(Exception e){
            return new List<String>();
        }
        
    }
    
    public static string syncContactInTargetOrg(List<Contact> conList){
        List<ConWrapper> wrpList = new List<ConWrapper>();
        for(Contact con : conList){
            ConWrapper wrp = new ConWrapper();
            wrp.firstName = con.firstName;
            wrp.lastName = con.LastName;
            wrp.emailCon = con.Email;
            wrpList.add(wrp);
        }
        
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint('callout:S2S/services/apexrest/ContactMapping');
            request.setHeader('Content-Type','application/json');
            request.setBody(JSON.serialize(wrpList));
            HTTPResponse response = http.send(request);
            return response.getBody();
        }catch(Exception e){
            return null;
        }
        
    }
    
    public class ConWrapper{
        public String firstName{get;Set;}
        public String lastName{get;Set;}
        public String emailCon{get;Set;}
    }
}