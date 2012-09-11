public with sharing class TestRecordFactory {

	public static final String booleans =   			'boolean,checkbox';
	public static final String strings =    			'combobox,email,phone,reference,multipicklist,string,picklist,textarea,url';
	public static final String integers =   			'integer';
	public static final String doubles =    			'currency,double,percent';
	public static final String base64s =    			'base64';
	public static final String references =				'reference';
	public static final String trues =      			'true,yes,y,1';
	public static final String falses =					'false,no,n,0';
	public static final String excludedFields = 		'CreatedById,LastModifiedById,OwnerId,ParentId,MasterRecordId,ReportsToId';
	public static final String globallyUniqueFields = 	'JigsawCompanyId,JigsawContactId';
 
  	public static final String randomText = '' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
  	'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

  	public static Map<String, Map<String, Schema.sObjectField>> fieldCache { get; set; }
  	public static Map<String, Map<String, List<Schema.PicklistEntry>>> picklistCache { get; set; }
  	
  	public static Map<String, sObject> recordCache {
  		get {
  			if(recordCache == null) recordCache = new Map<String, sObject>();
  			return recordCache;
  		}
  		set;
  	}


  	public static Map<String, ITestRecord> testRecordClassCache {
  		get {
  			if(testRecordClassCache == null) testRecordClassCache = new Map<String, ITestRecord>();
  			return testRecordClassCache;
  		}
  		set;
  	}

  	// requiredFieldsOnly
  	// default = true
  	// if true, then only required fields are set on the records
  	// if false, then all fields are set on the records
  	public static Boolean requiredFieldsOnly {
  		get {
  			if(requiredFieldsOnly == null) requiredFieldsOnly = true;
  			return requiredFieldsOnly;
  		}
  		set;
  	}

  	// reuseParentRecords
  	// default = true
  	// if true, then a new parent record is created once then added to a cache to reuse for future lookups
  	// if false, then a new parent record is created when needed to populate a lookup reference on a record
  	// note: setting this value to "false" can be expensive script-statement-wise. Use with care.
  	public static Boolean reuseParentRecords {
  		get {
  			if(reuseParentRecords == null) reuseParentRecords = true;
  			return reuseParentRecords;
  		}
  		set;
  	}

  	public static List<sObject> createRecords(sObject overrides, Integer recordCount) {
  		List<sObject> records = new List<sObject>();
  		for(Integer x = 0; x < recordCount; x++) records.add(createRecord(overrides));
  		return records;
  	}

  	public static sObject createRecord(sObject overrides) {

  		Schema.DescribeSObjectResult describe = overrides.getSObjectType().getDescribe();
    	sObject defaults = Schema.getGlobalDescribe().get(describe.getName()).newSObject();

    	if(getTestRecordClass(defaults.getSObjectType().getDescribe().getName()) != null) {
    		defaults = getTestRecordClass(defaults.getSObjectType().getDescribe().getName()).getDefaultRecord();
    	}

    	for(Schema.sObjectField f : describe.fields.getMap().values()) {
      		if(!f.getDescribe().isCreateable()) continue;
      		setField(f.getDescribe(), defaults, overrides);
    	}

    	return defaults;

  	}

	private static Map<String, Schema.sObjectField> getCachedSObjectFields(Schema.sObjectType sot) {
		if(fieldCache == null) fieldCache = new Map<String, Map<String, Schema.sObjectField>>();
		if(!fieldCache.containsKey(sot.getDescribe().getName())) fieldCache.put(sot.getDescribe().getName(), sot.getDescribe().fields.getMap());
		return fieldCache.get(sot.getDescribe().getName());
	}

	private static List<Schema.PicklistEntry> getCachedPicklistEntries(Schema.sObjectType sot, Schema.DescribeFieldResult describe) {
		if(picklistCache == null) picklistCache = new Map<String, Map<String, List<Schema.PicklistEntry>>>();
		if(!picklistCache.containsKey(sot.getDescribe().getName())) picklistCache.put(sot.getDescribe().getName(), new Map<String, List<Schema.PicklistEntry>>());
		if(!picklistCache.get(sot.getDescribe().getName()).containsKey(describe.getName())) picklistCache.get(sot.getDescribe().getName()).put(describe.getName(), describe.getPicklistValues());
		return picklistCache.get(sot.getDescribe().getName()).get(describe.getName());
	}

	public static void addTestRecordClass(String sObjectTypeName, ITestRecord testRecordClass) {
		testRecordClassCache.put(sObjectTypeName, testRecordClass);
	}

	public static ITestRecord getTestRecordClass(String sObjectTypeName) {
		return testRecordClassCache.containsKey(sObjectTypeName) ? testRecordClassCache.get(sObjectTypeName) : null;
	}

	public static void addCachedRecord(sObject record) {
		recordCache.put(record.getSObjectType().getDescribe().getName(), record);
	}

	public static sObject getCachedRecord(String sObjectTypeName) {
		return recordCache.containsKey(sObjectTypeName) ? recordCache.get(sObjectTypeName) : null;
	}

  	public static void setField(Schema.DescribeFieldResult describe, sObject defaults, sObject overrides) {

		if(getFieldValue(overrides, describe.getName()) != null) {
	  		// populate the defaults record with the overrides field 
			setFieldValue(defaults, describe.getName(), getFieldValue(overrides, describe.getName()));    
	  	}

	  	else if(excludedFields.contains(describe.getName())) return;

		else if((!describe.isNillable() || !requiredFieldsOnly) && getFieldValue(defaults, describe.getName()) == null) {
	
			if(globallyUniqueFields.contains(describe.getName()))
				setFieldValue(defaults, describe.getName(), String.valueOf(Crypto.getRandomLong()));		

			else if(('string,textarea').contains(describe.getType().name().toLowerCase()))
				setFieldValue(defaults, describe.getName(), randomText.substring(0, describe.getLength() > 2000 ? 2000 : describe.getLength()));
		
			else if(('picklist,multipicklist').contains(describe.getType().name().toLowerCase())) {
				if(getCachedPicklistEntries(defaults.getSObjectType(), describe).size() > 0) setFieldValue(defaults, describe.getName(), getCachedPicklistEntries(defaults.getSObjectType(), describe)[0].getValue());
				else setFieldValue(defaults, describe.getName(), randomText.substring(0, 40));
			}

			else if(doubles.contains(describe.getType().name().toLowerCase()))
				setFieldValue(defaults, describe.getName(), 1);

			else if(integers.contains(describe.getType().name().toLowerCase()))
				setFieldValue(defaults, describe.getName(), 1);
	    	
	    	else if(describe.getType().name().toLowerCase() == 'date') 
	    		setFieldValue(defaults, describe.getName(), 'today');
	      
	      	else if(describe.getType().name().toLowerCase() == 'datetime') 
	      		setFieldValue(defaults, describe.getName(), 'now');
	      
	      	else if(describe.getType().name().toLowerCase() == 'reference') {
	      		// this is more interesting - a required reference field (either a MD or a user-specified required lookup)
	      		// we need to dynamically create a record to support it.
	      		// this is the ONLY place in TestRecordFactory where we generate AND insert a record.
	      		//system.debug(describe.getReferenceTo()[0].getDescribe().getName());
	      		sObject lookup = null;
	      		if(reuseParentRecords) lookup = getCachedRecord(describe.getReferenceTo()[0].getDescribe().getName());
	      		if(lookup == null) {
	      			lookup = createRecord(describe.getReferenceTo()[0].newSObject());
	      			insert lookup;
	      			if(reuseParentRecords) addCachedRecord(lookup);
	      		}
	      		setFieldValue(defaults, describe.getName(), lookup.Id);
	      	}
	      	else if(describe.getType().name().toLowerCase() == 'url') 
	      		setFieldValue(defaults, describe.getName(), 'http://www.test.com');
	      
	      	else if(describe.getType().name().toLowerCase() == 'email') 
	      		setFieldValue(defaults, describe.getName(), 'test@test.com');

	      	else if(describe.getType().name().toLowerCase() == 'phone') 
	      		setFieldValue(defaults, describe.getName(), '5555551212');

	      	else if(booleans.contains(describe.getType().name().toLowerCase()))
	      		setFieldValue(defaults, describe.getName(), true);

	      	else if(describe.getType().name().toLowerCase() == 'base64') 
	      		setFieldValue(defaults, describe.getName(), randomText);

	    }
	    
	}

	private static Object getFieldValue(sObject record, String fieldName) {
	    try {
	     	return record.get(fieldName);
	    }
	    catch(Exception ex) {
	     	// splat
	    }
	    return null;
	}

	public static void setFieldValue(sObject record, String fieldName, Object fieldValue) {
    
		//system.debug(record);
		//system.debug(fieldName);
		//system.debug(fieldValue);

       Schema.sObjectType sot = record.getSObjectType();
       Map<String, Schema.sObjectField> sotFields = getCachedSObjectFields(sot);

       if(!sotFields.containsKey(fieldName)) return;

       String fieldType = sotFields.get(fieldName).getDescribe().getType().name().toLowerCase();

		try {
			
			if(strings.contains(fieldType)) {
				record.put(fieldName, String.valueOf(fieldValue));
			}
			if(references.contains(fieldType)) {
				record.put(fieldName, String.valueOf(fieldValue));
			}
			else if(doubles.contains(fieldType)) {
	        	record.put(fieldName, Double.valueOf(fieldValue));
			}
			else if(integers.contains(fieldType)) {
	        	record.put(fieldName, Integer.valueOf(fieldValue));
			}
			else if(fieldType == 'date') {
        		try { record.put(fieldName, Date.parse(String.valueOf(fieldValue))); }
            	catch(Exception ex) {
              		try { record.put(fieldName, Date.valueOf(String.valueOf(fieldValue))); }
                	catch(Exception ex2) {
            			try {
              				// try to read it as a datetime via timestamp
              				record.put(fieldName, Datetime.newInstance(Long.valueOf(String.valueOf(fieldValue))).date());
            			}
            			catch(Exception ex3) {
              				// try to parse the value "today"
                    		try {
                      			String now = String.valueOf(fieldValue);
                      			if(now.toLowerCase() == 'today') record.put(fieldName, Date.today());
                    		}
                    		catch(Exception ex4) {
                      			// splat
                    		}
            			}
                	}
        		}
        	}
        	else if(fieldType == 'datetime') {
          		try { record.put(fieldName, DateTime.parse(String.valueOf(fieldValue))); }
            	catch(Exception ex) {
              		try { record.put(fieldName, DateTime.valueOfGmt(String.valueOf(fieldValue))); }
                	catch(Exception ex2) {
                  		// try to parse the value "now"
                  		try {
                    		String now = String.valueOf(fieldValue);
                    		if(now.toLowerCase() == 'now') record.put(fieldName, DateTime.now());
                  		}
                  		catch(Exception ex3) {
                    		// splat
                  		}
          			}
        		}
      		}
      		else if(booleans.contains(fieldType)) {
				record.put(fieldName, Boolean.valueOf(fieldValue));
			}
      		else if(base64s.contains(fieldType)) {
	           	record.put(fieldName, Blob.valueOf(String.valueOf(fieldValue)));
			}
		}
		catch(Exception ex) {
			// splat
		}
    }
  
    @isTest
    public static void testAccount() {
    	TestRecordFactory.requiredFieldsOnly = true; 			// this is the default - you don't need to set it, just showing for example.
    	TestRecordFactory.reuseParentRecords = true; 			// this is the default - you don't need to set it, just showing for example.
    	Account record = (Account)TestRecordFactory.createRecord(new Account()); // this is how you
    	insert record;
    }

    @isTest
    public static void testAccountAllFields() {
    	TestRecordFactory.requiredFieldsOnly = false; 
    	Account record = (Account)TestRecordFactory.createRecord(new Account());
    	insert record;
    }

    @isTest
    public static void testAccountWithTestRecordDefinition() {
    	TestRecordFactory.addTestRecordClass('Account', new ExampleAccountTestRecord());
    	Account record = (Account)TestRecordFactory.createRecord(new Account());
    	system.assertEquals('Example', record.Name);
    	insert record;
    }

    @isTest
    public static void testAccountAllFieldsTestRecordDefinition() {
    	TestRecordFactory.requiredFieldsOnly = false; 
    	TestRecordFactory.addTestRecordClass('Account', new ExampleAccountTestRecord());
    	Account record = (Account)TestRecordFactory.createRecord(new Account());
    	insert record;
    }

	@isTest
	public static void testAccounts() {
		List<Account> records = (List<Account>)TestRecordFactory.createRecords(new Account(), 5);
		insert records;
	}

	@isTest
	public static void testAccountsAllFields() {
		TestRecordFactory.requiredFieldsOnly = false;
		List<Account> records = (List<Account>)TestRecordFactory.createRecords(new Account(), 5);
		insert records;
	}

	@isTest
	public static void testAccountsWithTestRecordDefinition() {
		TestRecordFactory.addTestRecordClass('Account', new ExampleAccountTestRecord());
		List<Account> records = (List<Account>)TestRecordFactory.createRecords(new Account(), 5);
		insert records;
	}

	@isTest
	public static void testAccountsAllFieldsWithTestRecordDefinition() {
		TestRecordFactory.requiredFieldsOnly = false;
		TestRecordFactory.addTestRecordClass('Account', new ExampleAccountTestRecord());
		List<Account> records = (List<Account>)TestRecordFactory.createRecords(new Account(), 5);
		insert records;
	}

	@isTest
    public static void testContact() {
    	Contact record = (Contact)TestRecordFactory.createRecord(new Contact());
    	insert record;
    }

    @isTest
    public static void testContactsWithUniqueAccounts() {
    	TestRecordFactory.requiredFieldsOnly = false;
    	TestRecordFactory.reuseParentRecords = false;
    	List<Contact> records = (List<Contact>)TestRecordFactory.createRecords(new Contact(), 5);
    	system.assertNotEquals(records[0].AccountId, records[1].AccountId);
    	insert records;
    }

    @isTest
    public static void testContactsWithUniqueAccountsWithTestRecordDefinition() {
    	TestRecordFactory.requiredFieldsOnly = false;
    	TestRecordFactory.reuseParentRecords = false;
    	TestRecordFactory.addTestRecordClass('Account', new ExampleAccountTestRecord());
    	List<Contact> records = (List<Contact>)TestRecordFactory.createRecords(new Contact(), 5);
    	system.assertNotEquals(records[0].AccountId, records[1].AccountId);
    	insert records;
    }

    @isTest
    public static void testContactsWithReusedAccounts() {
    	TestRecordFactory.requiredFieldsOnly = false;
    	TestRecordFactory.reuseParentRecords = true;
    	List<Contact> records = (List<Contact>)TestRecordFactory.createRecords(new Contact(), 5);
    	system.assertEquals(records[0].AccountId, records[1].AccountId);
    	insert records;
    }

     @isTest
    public static void testContactsWithReusedAccountsWithTestRecordDefinition() {
    	TestRecordFactory.requiredFieldsOnly = false;
    	TestRecordFactory.reuseParentRecords = true;
    	TestRecordFactory.addTestRecordClass('Account', new ExampleAccountTestRecord());
    	List<Contact> records = (List<Contact>)TestRecordFactory.createRecords(new Contact(), 5);
    	system.assertEquals(records[0].AccountId, records[1].AccountId);
    	insert records;
    }

    @isTest
    public static void testContactAllFields() {
    	TestRecordFactory.requiredFieldsOnly = false;
    	Contact record = (Contact)TestRecordFactory.createRecord(new Contact());
    	insert record;
    }

     @isTest
    public static void testAttachment() {
    	Account record = (Account)TestRecordFactory.createRecord(new Account());
    	insert record;

    	Attachment attachment = (Attachment)TestRecordFactory.createRecord(new Attachment(
    		ParentId = record.Id
    	));
    	insert attachment;
    }

}