public with sharing class ExampleAccountTestRecord implements ITestRecord {
	public sObject getDefaultRecord() {
		return new Account(Name = 'Example'); 
	} 
}