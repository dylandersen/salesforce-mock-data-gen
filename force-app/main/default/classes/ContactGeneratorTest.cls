@isTest
private class ContactGeneratorTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology'
        );
        insert testAccount;
    }
    
    @isTest
    static void testSuccessfulContactCreation() {
        // Get test account
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        // Prepare test data
        String jsonData = '[{"firstName":"John","lastName":"Doe","title":"Manager","phone":"555-1234","email":"john.doe@test.com","mailingStreet":"123 Main St","mailingCity":"Test City","mailingState":"CA","mailingPostalCode":"12345","mailingCountry":"United States","description":"Test contact"}]';
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = jsonData;
        request.expectedContactCount = 1;
        request.industry = 'Technology';
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(result.success, 'Should be successful. Error: ' + result.message);
        System.assertEquals(1, result.contactsCreated, 'Should create one contact');
        System.assert(String.isNotBlank(result.contactIdList), 'Should have contact IDs');
        System.assert(result.message.contains('Successfully created 1 contacts'), 'Should have success message');
        System.assert(result.message.contains('Technology'), 'Should mention industry');
        
        // Verify contact was created
        List<Contact> contacts = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(1, contacts.size(), 'Should have one contact in database');
        System.assertEquals('John', contacts[0].FirstName, 'First name should match');
        System.assertEquals('Doe', contacts[0].LastName, 'Last name should match');
    }
    
    @isTest
    static void testMultipleContactsCreation() {
        // Get test account
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        // Prepare test data for multiple contacts
        String jsonData = '[{"firstName":"Jane","lastName":"Smith","title":"Developer","phone":"555-5678","email":"jane.smith@test.com","mailingStreet":"456 Oak Ave","mailingCity":"Test City","mailingState":"NY","mailingPostalCode":"67890","mailingCountry":"United States","description":"Developer contact"},{"firstName":"Bob","lastName":"Johnson","title":"Analyst","phone":"555-9012","email":"bob.johnson@test.com","mailingStreet":"789 Pine St","mailingCity":"Test City","mailingState":"TX","mailingPostalCode":"11223","mailingCountry":"United States","description":"Analyst contact"}]';
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = jsonData;
        request.expectedContactCount = 2;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(result.success, 'Should be successful. Error: ' + result.message);
        System.assertEquals(2, result.contactsCreated, 'Should create two contacts');
        System.assert(String.isNotBlank(result.contactIdList), 'Should have contact IDs');
        
        // Verify contacts were created
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE AccountId = :testAccount.Id ORDER BY FirstName];
        System.assertEquals(2, contacts.size(), 'Should have two contacts in database');
        System.assertEquals('Bob', contacts[0].FirstName, 'First contact should be Bob');
        System.assertEquals('Jane', contacts[1].FirstName, 'Second contact should be Jane');
    }
    
    @isTest
    static void testMissingAccountId() {
        String jsonData = '[{"firstName":"John","lastName":"Doe","title":"Manager","phone":"555-1234","email":"john.doe@test.com","mailingStreet":"123 Main St","mailingCity":"Test City","mailingState":"CA","mailingPostalCode":"12345","mailingCountry":"United States","description":"Test contact"}]';
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = '';
        request.contactJsonData = jsonData;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(!result.success, 'Should not be successful');
        System.assertEquals('Account ID is required', result.message, 'Should have correct error message');
        System.assertEquals(0, result.contactsCreated, 'Should not create any contacts');
    }
    
    @isTest
    static void testMissingJsonData() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = '';
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(!result.success, 'Should not be successful');
        System.assertEquals('Contact JSON data is required', result.message, 'Should have correct error message');
        System.assertEquals(0, result.contactsCreated, 'Should not create any contacts');
    }
    
    @isTest
    static void testInvalidAccountId() {
        String jsonData = '[{"firstName":"John","lastName":"Doe","title":"Manager","phone":"555-1234","email":"john.doe@test.com","mailingStreet":"123 Main St","mailingCity":"Test City","mailingState":"CA","mailingPostalCode":"12345","mailingCountry":"United States","description":"Test contact"}]';
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = '001000000000000'; // Invalid ID
        request.contactJsonData = jsonData;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(!result.success, 'Should not be successful');
        System.assert(result.message.contains('Invalid Account ID'), 'Should have correct error message');
        System.assertEquals(0, result.contactsCreated, 'Should not create any contacts');
    }
    
    @isTest
    static void testCountMismatch() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        String jsonData = '[{"firstName":"John","lastName":"Doe","title":"Manager","phone":"555-1234","email":"john.doe@test.com","mailingStreet":"123 Main St","mailingCity":"Test City","mailingState":"CA","mailingPostalCode":"12345","mailingCountry":"United States","description":"Test contact"}]';
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = jsonData;
        request.expectedContactCount = 3; // Expect 3 but only 1 provided
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(!result.success, 'Should not be successful');
        System.assert(result.message.contains('Expected 3 contacts but received 1'), 'Should have correct error message');
        System.assertEquals(0, result.contactsCreated, 'Should not create any contacts');
    }
    
    @isTest
    static void testInvalidJsonFormat() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        String invalidJsonData = '{"firstName":"John","lastName":"Doe"}'; // Missing array brackets
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = invalidJsonData;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(!result.success, 'Should not be successful');
        System.assert(result.message.contains('Invalid JSON format'), 'Should have correct error message');
        System.assertEquals(0, result.contactsCreated, 'Should not create any contacts');
    }
    
    @isTest
    static void testJsonWithSpecialCharacters() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        // JSON with non-breaking spaces (but not smart quotes in property values to avoid JSON parsing issues)
        String jsonData = '[{"firstName":"John\u00A0","lastName":"Doe\u2007","title":"Manager","phone":"555-1234","email":"john.doe@test.com","mailingStreet":"123\u202FMain St","mailingCity":"Test City","mailingState":"CA","mailingPostalCode":"12345","mailingCountry":"United States","description":"Test contact"}]';
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = jsonData;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(result.success, 'Should be successful. Error: ' + result.message);
        System.assertEquals(1, result.contactsCreated, 'Should create one contact');
        
        // Verify contact was created with cleaned data
        List<Contact> contacts = [SELECT Id, FirstName, LastName, MailingStreet, MailingCity FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(1, contacts.size(), 'Should have one contact in database');
        System.assertEquals('John', contacts[0].FirstName, 'First name should be cleaned');
        System.assertEquals('Doe', contacts[0].LastName, 'Last name should be cleaned');
        System.assertEquals('123 Main St', contacts[0].MailingStreet, 'Street should be cleaned');
        System.assertEquals('Test City', contacts[0].MailingCity, 'City should be normal');
    }
    
    @isTest
    static void testEmptyContactList() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        String jsonData = '[]'; // Empty array
        
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        request.accountId = testAccount.Id;
        request.contactJsonData = jsonData;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        ContactGenerator.ContactGenerationResult result = results[0];
        System.assert(!result.success, 'Should not be successful');
        System.assertEquals('No valid contact data found in JSON', result.message, 'Should have correct error message');
        System.assertEquals(0, result.contactsCreated, 'Should not create any contacts');
    }
    
    @isTest
    static void testMultipleRequests() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        // First request - valid
        String jsonData1 = '[{"firstName":"John","lastName":"Doe","title":"Manager","phone":"555-1234","email":"john.doe@test.com","mailingStreet":"123 Main St","mailingCity":"Test City","mailingState":"CA","mailingPostalCode":"12345","mailingCountry":"United States","description":"Test contact"}]';
        
        ContactGenerator.ContactGenerationRequest request1 = new ContactGenerator.ContactGenerationRequest();
        request1.accountId = testAccount.Id;
        request1.contactJsonData = jsonData1;
        
        // Second request - invalid (missing account ID)
        ContactGenerator.ContactGenerationRequest request2 = new ContactGenerator.ContactGenerationRequest();
        request2.accountId = '';
        request2.contactJsonData = jsonData1;
        
        Test.startTest();
        List<ContactGenerator.ContactGenerationResult> results = ContactGenerator.createContactsFromJson(new List<ContactGenerator.ContactGenerationRequest>{request1, request2});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, results.size(), 'Should return two results');
        
        // First result should be successful
        ContactGenerator.ContactGenerationResult result1 = results[0];
        System.assert(result1.success, 'First request should be successful. Error: ' + result1.message);
        System.assertEquals(1, result1.contactsCreated, 'Should create one contact');
        
        // Second result should fail
        ContactGenerator.ContactGenerationResult result2 = results[1];
        System.assert(!result2.success, 'Second request should fail');
        System.assertEquals('Account ID is required', result2.message, 'Should have correct error message');
    }
    
    @isTest
    static void testContactDataWrapperClass() {
        // Test the inner ContactData class
        ContactGenerator.ContactData contactData = new ContactGenerator.ContactData();
        contactData.firstName = 'Test';
        contactData.lastName = 'User';
        contactData.title = 'Developer';
        contactData.phone = '555-1234';
        contactData.email = 'test@example.com';
        contactData.mailingStreet = '123 Test St';
        contactData.mailingCity = 'Test City';
        contactData.mailingState = 'CA';
        contactData.mailingPostalCode = '12345';
        contactData.mailingCountry = 'United States';
        contactData.description = 'Test description';
        
        // Verify all fields are set correctly
        System.assertEquals('Test', contactData.firstName, 'First name should match');
        System.assertEquals('User', contactData.lastName, 'Last name should match');
        System.assertEquals('Developer', contactData.title, 'Title should match');
        System.assertEquals('555-1234', contactData.phone, 'Phone should match');
        System.assertEquals('test@example.com', contactData.email, 'Email should match');
        System.assertEquals('123 Test St', contactData.mailingStreet, 'Street should match');
        System.assertEquals('Test City', contactData.mailingCity, 'City should match');
        System.assertEquals('CA', contactData.mailingState, 'State should match');
        System.assertEquals('12345', contactData.mailingPostalCode, 'Postal code should match');
        System.assertEquals('United States', contactData.mailingCountry, 'Country should match');
        System.assertEquals('Test description', contactData.description, 'Description should match');
    }
    
    @isTest
    static void testContactGenerationResultWrapperClass() {
        // Test the inner ContactGenerationResult class
        ContactGenerator.ContactGenerationResult result = new ContactGenerator.ContactGenerationResult();
        
        // Verify default values
        System.assert(!result.success, 'Success should default to false');
        System.assertEquals(0, result.contactsCreated, 'Contacts created should default to 0');
        System.assertEquals('', result.contactIdList, 'Contact ID list should default to empty string');
        System.assertEquals(null, result.message, 'Message should default to null');
        
        // Test setting values
        result.success = true;
        result.contactsCreated = 5;
        result.contactIdList = '001,002,003,004,005';
        result.message = 'Test message';
        
        // Verify values are set correctly
        System.assert(result.success, 'Success should be true');
        System.assertEquals(5, result.contactsCreated, 'Contacts created should be 5');
        System.assertEquals('001,002,003,004,005', result.contactIdList, 'Contact ID list should match');
        System.assertEquals('Test message', result.message, 'Message should match');
    }
    
    @isTest
    static void testContactGenerationRequestWrapperClass() {
        // Test the inner ContactGenerationRequest class
        ContactGenerator.ContactGenerationRequest request = new ContactGenerator.ContactGenerationRequest();
        
        // Test setting values
        request.accountId = '001000000000000';
        request.contactJsonData = '{"test":"data"}';
        request.expectedContactCount = 10;
        request.industry = 'Technology';
        
        // Verify values are set correctly
        System.assertEquals('001000000000000', request.accountId, 'Account ID should match');
        System.assertEquals('{"test":"data"}', request.contactJsonData, 'Contact JSON data should match');
        System.assertEquals(10, request.expectedContactCount, 'Expected contact count should match');
        System.assertEquals('Technology', request.industry, 'Industry should match');
    }
}