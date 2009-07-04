<cfcomponent extends="coldbox.system.testing.BaseTestCase">
<cfscript>
	function setup(){
		console = getMockBox().createMock(className="coldbox.system.logging.appenders.ConsoleAppender");
		console.init('MyConsoleAppender',5);
		
		loge = getMockBox().createMock(className="coldbox.system.logging.LogEvent");
		loge.init("Unit Test Sample",0,structnew(),"UnitTest");
	}
	function testLogMessage(){
		for(x=0; x lte 5; x++){
			loge.setSeverity(x);
			loge.setCategory("coldbox.system.testing");
			console.logMessage(loge);
		}
	}	
</cfscript>
</cfcomponent>