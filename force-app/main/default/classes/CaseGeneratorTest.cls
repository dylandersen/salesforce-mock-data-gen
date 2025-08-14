@isTest
public class CaseGeneratorTest {
    
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account', Industry = 'Technology');
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Phone = '(555) 123-4567',
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    @isTest
    static void testCreateCasesFromJson_Success() {
        // Get test contact
        Contact testContact = [SELECT Id, AccountId FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        String validJson = '[' +
            '{' +
                '"subject": "Cannot login to system",' +
                '"description": "User is unable to access their account after password reset",' +
                '"status": "New",' +
                '"priority": "High",' +
                '"origin": "Email",' +
                '"type": "Problem",' +
                '"reason": "User_Interface",' +
                '"suppliedEmail": "user@test.com",' +
                '"suppliedName": "Test User",' +
                '"suppliedPhone": "(555) 123-4567"' +
            '},' +
            '{' +
                '"subject": "Feature request for reporting",' +
                '"description": "Customer would like additional fields in the monthly report",' +
                '"status": "New",' +
                '"priority": "Medium",' +
                '"origin": "Web",' +
                '"type": "Feature Request",' +
                '"reason": "Enhancement",' +
                '"suppliedEmail": "another.user@test.com",' +
                '"suppliedName": "Another User"' +
            '}' +
        ']';
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = testContact.Id;
        request.caseJsonData = validJson;
        request.expectedCaseCount = 2;
        request.industry = 'Technology';
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(true, result.success, 'Expected successful creation');
        System.assertEquals(2, result.casesCreated, 'Expected 2 cases created');
        System.assert(result.message.contains('Successfully created 2 cases'), 'Expected success message');
        System.assert(String.isNotBlank(result.caseIdList), 'Expected case IDs');
        
        // Verify cases were actually created
        List<Case> createdCases = [SELECT Id, Subject, Description, Status, Priority, Origin, Type, ContactId, AccountId FROM Case];
        System.assertEquals(2, createdCases.size(), 'Expected 2 cases in database');
        
        // Verify case content and relationships
        Case case1 = createdCases[0];
        System.assertEquals('Cannot login to system', case1.Subject, 'Expected correct subject');
        System.assertEquals('New', case1.Status, 'Expected correct status');
        System.assertEquals('High', case1.Priority, 'Expected correct priority');
        System.assertEquals(testContact.Id, case1.ContactId, 'Expected correct contact');
        System.assertEquals(testContact.AccountId, case1.AccountId, 'Expected correct account from contact');
    }
    
    @isTest
    static void testCreateCasesFromJson_BlankContactId() {
        // Test with blank contact ID
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = '';
        request.caseJsonData = '[]';
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals('Contact ID is required', result.message, 'Expected error message');
        System.assertEquals(0, result.casesCreated, 'Expected no cases created');
    }
    
    @isTest
    static void testCreateCasesFromJson_BlankJsonData() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = testContact.Id;
        request.caseJsonData = '';
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals('Case JSON data is required', result.message, 'Expected error message');
        System.assertEquals(0, result.casesCreated, 'Expected no cases created');
    }
    
    @isTest
    static void testCreateCasesFromJson_InvalidContactId() {
        // Test with invalid contact ID
        
        String fakeContactId = '003000000000000';
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = fakeContactId;
        request.caseJsonData = '[]';
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assert(result.message.contains('Invalid Contact ID'), 'Expected invalid contact error message');
        System.assertEquals(0, result.casesCreated, 'Expected no cases created');
    }
    
    @isTest
    static void testCreateCasesFromJson_InvalidJson() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        String invalidJson = 'invalid json format';
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = testContact.Id;
        request.caseJsonData = invalidJson;
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assert(result.message.contains('Invalid JSON format'), 'Expected JSON error message');
        System.assertEquals(0, result.casesCreated, 'Expected no cases created');
    }
    
    @isTest
    static void testCreateCasesFromJson_WrongCaseCount() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        String validJson = '[' +
            '{' +
                '"subject": "Test case",' +
                '"description": "Test case description",' +
                '"status": "New",' +
                '"priority": "Medium",' +
                '"origin": "Web",' +
                '"type": "Question"' +
            '}' +
        ']';
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = testContact.Id;
        request.caseJsonData = validJson;
        request.expectedCaseCount = 3; // Expecting 3 but JSON has 1
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assert(result.message.contains('Expected 3 cases but received 1'), 'Expected count mismatch message');
        System.assertEquals(0, result.casesCreated, 'Expected no cases created');
    }
    
    @isTest
    static void testCreateCasesFromJson_EmptyJsonArray() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        String emptyJson = '[]';
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = testContact.Id;
        request.caseJsonData = emptyJson;
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals('No valid case data found in JSON', result.message, 'Expected no data message');
        System.assertEquals(0, result.casesCreated, 'Expected no cases created');
    }
    
    @isTest
    static void testCreateCasesFromJson_DefaultValues() {
        // Test that default values are applied correctly
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        String jsonWithDefaults = '[' +
            '{' +
                '"subject": "Test case with defaults",' +
                '"description": "Testing default values"' +
                // No status, priority, or origin specified
            '}' +
        ']';
        
        CaseGenerator.CaseGenerationRequest request = new CaseGenerator.CaseGenerationRequest();
        request.contactId = testContact.Id;
        request.caseJsonData = jsonWithDefaults;
        
        Test.startTest();
        List<CaseGenerator.CaseGenerationResult> results = 
            CaseGenerator.createCasesFromJson(new List<CaseGenerator.CaseGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        CaseGenerator.CaseGenerationResult result = results[0];
        
        System.assertEquals(true, result.success, 'Expected successful creation');
        System.assertEquals(1, result.casesCreated, 'Expected 1 case created');
        
        // Verify defaults were applied
        Case createdCase = [SELECT Id, Status, Priority, Origin, OwnerId, ContactId FROM Case LIMIT 1];
        System.assertEquals('New', createdCase.Status, 'Expected default status');
        System.assertEquals('Medium', createdCase.Priority, 'Expected default priority');
        System.assertEquals('Web', createdCase.Origin, 'Expected default origin');
        System.assertEquals(UserInfo.getUserId(), createdCase.OwnerId, 'Expected current user as owner');
        System.assertEquals(testContact.Id, createdCase.ContactId, 'Expected correct contact linkage');
    }
}
