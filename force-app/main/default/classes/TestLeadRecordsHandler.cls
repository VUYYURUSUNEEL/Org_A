@isTest
private class TestLeadRecordsHandler {

    @isTest
    static void testCreateBulkLeadRecords() {
        Test.startTest();
        LeadRecordsHandler.CreateBulkLeadRecords();
        Test.stopTest();

        Integer leadCount = [SELECT count() FROM Lead];
        System.assertEquals(1000, leadCount, 'Expected 1000 Lead records to be created.');
    }

    @isTest
    static void testGetLeads() {
        List<Lead> testLeads = LeadRecordsHandler.getLeads('Test', 'Web');
        List<Lead> testLeadsEmpty = LeadRecordsHandler.getLeads(null, '');
    }

    @isTest
    static void testSyncContact() {
        // Test case for when new contacts are found and synced
        Test.startTest();
        //LeadRecordsHandler.getContactsEmail mock = new LeadRecordsHandler.getContactsEmail();
        //Test.setMock(HttpCalloutMock.class, mock);
        String result = LeadRecordsHandler.syncContact();
        Test.stopTest();

        // Test case for when no new contacts are found
        // Simulate scenario where getContactsEmail() returns an empty list
        //LeadRecordsHandler.getContactsEmail emptyMock = new LeadRecordsHandler.getContactsEmail(true);
        //Test.setMock(HttpCalloutMock.class, emptyMock);
        String resultNoNewContacts = LeadRecordsHandler.syncContact();
    }

    // Mock class to simulate getContactsEmail method returning an empty list
    public class GetContactsEmailMock implements HttpCalloutMock {
        private Boolean isEmptyList;

        public GetContactsEmailMock() {
            this.isEmptyList = false;
        }

        public GetContactsEmailMock(Boolean isEmptyList) {
            this.isEmptyList = isEmptyList;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            if (isEmptyList) {
                res.setBody('[]');
            } else {
                // Provide mock response for getContactsEmail method
                res.setBody('[ "test1@example.com", "test2@example.com" ]');
            }
            return res;
        }
    }

    // Test case for syncContactInTargetOrg method
    @isTest
    static void testSyncContactInTargetOrg() {
        List<Contact> testContactList = new List<Contact>();

        // Add test data to testContactList
        Contact testContact = new Contact();
        testContact.FirstName = 'Suneel Kumar';
        testContact.LastName = 'Vuyyuru';
        testContact.Email = 'vuyyuru243@gmail.com';
        testContactList.add(testContact);

        List<LeadRecordsHandler.ConWrapper> wrpList = new List<LeadRecordsHandler.ConWrapper>();

        LeadRecordsHandler.ConWrapper wrp = new LeadRecordsHandler.ConWrapper();
        // Populate wrapper with test data
        wrp.firstName = testContact.FirstName;
        wrp.lastName = testContact.LastName;
        wrp.emailCon = testContact.Email;
        wrpList.add(wrp);

        Test.startTest();
        String result = LeadRecordsHandler.syncContactInTargetOrg(testContactList);
        Test.stopTest();
    }
}