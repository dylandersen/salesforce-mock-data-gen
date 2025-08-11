@IsTest
public class TaskEventGeneratorTest {
    
    @TestSetup
    static void setupData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com'
        );
        insert testContact;
    }
    
    @IsTest
    static void testCreateTasksFromJson() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        String taskJsonData = '[' +
            '{' +
                '"subject": "Follow up call",' +
                '"activityType": "Task",' +
                '"status": "Not Started",' +
                '"priority": "Normal",' +
                '"description": "Follow up with customer about proposal",' +
                '"type": "Call",' +
                '"activityDate": "2024-12-31"' +
            '},' +
            '{' +
                '"subject": "Send proposal",' +
                '"activityType": "Task",' +
                '"status": "Not Started",' +
                '"priority": "High",' +
                '"description": "Prepare and send detailed proposal",' +
                '"type": "Email",' +
                '"activityDate": "2024-12-30"' +
            '}' +
        ']';
        
        TaskEventGenerator.TaskEventGenerationRequest request = new TaskEventGenerator.TaskEventGenerationRequest();
        request.recordId = testAccount.Id;
        request.activityJsonData = taskJsonData;
        request.expectedActivityCount = 2;
        request.industry = 'Technology';
        
        Test.startTest();
        List<TaskEventGenerator.TaskEventGenerationResult> results = 
            TaskEventGenerator.createActivitiesFromJson(new List<TaskEventGenerator.TaskEventGenerationRequest>{request});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        TaskEventGenerator.TaskEventGenerationResult result = results[0];
        Assert.isTrue(result.success, 'Operation should be successful');
        Assert.areEqual(2, result.activitiesCreated, 'Should create 2 activities');
        Assert.isTrue(result.message.contains('Successfully created 2 activities'), 'Success message should indicate 2 activities created');
        
        // Verify tasks were created
        List<Task> createdTasks = [SELECT Id, Subject, Status, Priority, Description, Type, WhatId 
                                   FROM Task WHERE WhatId = :testAccount.Id];
        Assert.areEqual(2, createdTasks.size(), 'Should create 2 tasks');
        
        // Verify task details
        Map<String, Task> tasksBySubject = new Map<String, Task>();
        for (Task task : createdTasks) {
            tasksBySubject.put(task.Subject, task);
        }
        
        Task followUpTask = tasksBySubject.get('Follow up call');
        Assert.isNotNull(followUpTask, 'Follow up task should exist');
        Assert.areEqual('Not Started', followUpTask.Status, 'Task status should match');
        Assert.areEqual('Normal', followUpTask.Priority, 'Task priority should match');
        Assert.areEqual('Call', followUpTask.Type, 'Task type should match');
        
        Task proposalTask = tasksBySubject.get('Send proposal');
        Assert.isNotNull(proposalTask, 'Proposal task should exist');
        Assert.areEqual('High', proposalTask.Priority, 'Task priority should match');
        Assert.areEqual('Email', proposalTask.Type, 'Task type should match');
    }
    
    @IsTest
    static void testCreateEventsFromJson() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        String eventJsonData = '[' +
            '{' +
                '"subject": "Client Meeting",' +
                '"activityType": "Event",' +
                '"description": "Quarterly business review meeting",' +
                '"type": "Meeting",' +
                '"location": "Conference Room A",' +
                '"activityDate": "2024-12-31",' +
                '"startTime": "14:00:00.000Z",' +
                '"durationInMinutes": 90' +
            '}' +
        ']';
        
        TaskEventGenerator.TaskEventGenerationRequest request = new TaskEventGenerator.TaskEventGenerationRequest();
        request.recordId = testAccount.Id;
        request.activityJsonData = eventJsonData;
        request.expectedActivityCount = 1;
        
        Test.startTest();
        List<TaskEventGenerator.TaskEventGenerationResult> results = 
            TaskEventGenerator.createActivitiesFromJson(new List<TaskEventGenerator.TaskEventGenerationRequest>{request});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        TaskEventGenerator.TaskEventGenerationResult result = results[0];
        Assert.isTrue(result.success, 'Operation should be successful');
        Assert.areEqual(1, result.activitiesCreated, 'Should create 1 activity');
        
        // Verify event was created
        List<Event> createdEvents = [SELECT Id, Subject, Description, Type, Location, WhatId, StartDateTime, EndDateTime 
                                     FROM Event WHERE WhatId = :testAccount.Id];
        Assert.areEqual(1, createdEvents.size(), 'Should create 1 event');
        
        Event createdEvent = createdEvents[0];
        Assert.areEqual('Client Meeting', createdEvent.Subject, 'Event subject should match');
        Assert.areEqual('Meeting', createdEvent.Type, 'Event type should match');
        Assert.areEqual('Conference Room A', createdEvent.Location, 'Event location should match');
        Assert.isNotNull(createdEvent.StartDateTime, 'Event should have start time');
        Assert.isNotNull(createdEvent.EndDateTime, 'Event should have end time');
    }
    
    @IsTest
    static void testMixedTasksAndEvents() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        String mixedJsonData = '[' +
            '{' +
                '"subject": "Preparation Task",' +
                '"activityType": "Task",' +
                '"status": "In Progress",' +
                '"priority": "High",' +
                '"description": "Prepare for client meeting",' +
                '"type": "Other",' +
                '"activityDate": "2024-12-30"' +
            '},' +
            '{' +
                '"subject": "Client Meeting",' +
                '"activityType": "Event",' +
                '"description": "Meet with client",' +
                '"type": "Meeting",' +
                '"location": "Client Office",' +
                '"activityDate": "2024-12-31",' +
                '"durationInMinutes": 120' +
            '}' +
        ']';
        
        TaskEventGenerator.TaskEventGenerationRequest request = new TaskEventGenerator.TaskEventGenerationRequest();
        request.recordId = testAccount.Id;
        request.activityJsonData = mixedJsonData;
        request.expectedActivityCount = 2;
        
        Test.startTest();
        List<TaskEventGenerator.TaskEventGenerationResult> results = 
            TaskEventGenerator.createActivitiesFromJson(new List<TaskEventGenerator.TaskEventGenerationRequest>{request});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        TaskEventGenerator.TaskEventGenerationResult result = results[0];
        Assert.isTrue(result.success, 'Operation should be successful');
        Assert.areEqual(2, result.activitiesCreated, 'Should create 2 activities');
        
        // Verify both task and event were created
        List<Task> createdTasks = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id];
        List<Event> createdEvents = [SELECT Id FROM Event WHERE WhatId = :testAccount.Id];
        
        Assert.areEqual(1, createdTasks.size(), 'Should create 1 task');
        Assert.areEqual(1, createdEvents.size(), 'Should create 1 event');
    }
    
    @IsTest
    static void testInvalidRecordId() {
        TaskEventGenerator.TaskEventGenerationRequest request = new TaskEventGenerator.TaskEventGenerationRequest();
        request.recordId = '';
        request.activityJsonData = '[]';
        
        Test.startTest();
        List<TaskEventGenerator.TaskEventGenerationResult> results = 
            TaskEventGenerator.createActivitiesFromJson(new List<TaskEventGenerator.TaskEventGenerationRequest>{request});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        TaskEventGenerator.TaskEventGenerationResult result = results[0];
        Assert.isFalse(result.success, 'Operation should fail');
        Assert.areEqual('Record ID is required', result.message, 'Should return appropriate error message');
    }
    
    @IsTest
    static void testInvalidJsonData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        TaskEventGenerator.TaskEventGenerationRequest request = new TaskEventGenerator.TaskEventGenerationRequest();
        request.recordId = testAccount.Id;
        request.activityJsonData = 'invalid json';
        
        Test.startTest();
        List<TaskEventGenerator.TaskEventGenerationResult> results = 
            TaskEventGenerator.createActivitiesFromJson(new List<TaskEventGenerator.TaskEventGenerationRequest>{request});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        TaskEventGenerator.TaskEventGenerationResult result = results[0];
        Assert.isFalse(result.success, 'Operation should fail');
        Assert.isTrue(result.message.contains('Invalid JSON format'), 'Should return JSON error message');
    }
    
    @IsTest
    static void testWrongActivityCount() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        String jsonData = '[{"subject": "Test Task", "activityType": "Task", "status": "Not Started"}]';
        
        TaskEventGenerator.TaskEventGenerationRequest request = new TaskEventGenerator.TaskEventGenerationRequest();
        request.recordId = testAccount.Id;
        request.activityJsonData = jsonData;
        request.expectedActivityCount = 5; // Expecting 5 but JSON has only 1
        
        Test.startTest();
        List<TaskEventGenerator.TaskEventGenerationResult> results = 
            TaskEventGenerator.createActivitiesFromJson(new List<TaskEventGenerator.TaskEventGenerationRequest>{request});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        TaskEventGenerator.TaskEventGenerationResult result = results[0];
        Assert.isFalse(result.success, 'Operation should fail');
        Assert.isTrue(result.message.contains('Expected 5 activities but received 1'), 'Should return count mismatch error');
    }
}
