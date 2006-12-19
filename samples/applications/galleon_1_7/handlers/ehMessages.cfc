<!-----------------------------------------------------------------------Author 	 :	Luis MajanoDate     :	September 25, 2005Description :	Message events-----------------------------------------------------------------------><cfcomponent name="ehMessages" extends="coldbox.system.eventhandler"><!-------------------------------------------- PRIVATE ------------------------------------------------>	<cffunction name="initMessages" output="false" access="private" returntype="void" hint="Init message viewing or posting">
		<!--- Check for thread id --->		<cfif not valueExists("threadid") or not len(getValue("threadid"))>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<!--- get parents --->		<cftry>			<cfset request.thread = application.thread.getThread(getValue("threadid"))>			<cfset request.forum = application.forum.getForum(request.thread.forumidfk)>			<cfset request.conference = application.conference.getConference(request.forum.conferenceidfk)>			<cfcatch>				<cfset getPlugin("logger").logError("Error getting forums and conferences information", cfcatch)>				<cfset setNextEvent("ehForums.dspHome")>			</cfcatch>		</cftry>		<!--- determine if read only --->		<cfif request.forum.readonly or request.thread.readonly>			<cfset setValue("readonly", true)>		<cfelse>			<cfset setValue("readonly", false)>		</cfif>
	</cffunction>
<!-------------------------------------------- PUBLIC ------------------------------------------------>	<cffunction name="dspMessages" access="public" returntype="void" output="false">		<!--- EXIT HANDLERS: --->		<cfset rc.xehForums = "ehForums.dspForums">		<cfset rc.xehThreads = "ehForums.dspThreads">		<cfset rc.xehMessages = "ehMessages.dspMessages">		<cfset rc.xehMessageEdit = "ehMessages.dspMessageEdit">		<cfset rc.xehMessagePost = "ehMessages.doMessagePost">		<cfset rc.xehNewPost = "ehMessages.dspNewPost">		<cfset rc.xehAttachment = "ehMessages.dspAttachment">				<!--- Init Messages --->		<cfset initMessages()>		<!--- get my messages --->		<cfset rc.data = application.message.getMessages(threadid=request.thread.id)>				<!--- determine max pages --->		<cfif rc.data.recordCount and rc.data.recordCount gt application.settings.perpage>			<cfset setValue("pages", ceiling(rc.data.recordCount / application.settings.perpage))>		<cfelse>			<cfset setvalue("pages",1)>		</cfif>				<!--- Parms --->		<cfset paramValue("post_title","RE: #request.thread.name#")>		<cfset paramValue("oldattachment", "")>		<cfset paramValue("attachment", "")>		<cfset paramValue("filename", "")>		<cfset paramValue("subscribe", "true")>		<cfset paramValue("body","")>				<!--- Set Title and Templatename --->		<cfset setValue("title","#application.settings.title# : #request.conference.name# : #request.forum.name# : #request.thread.name#")>		<cfset setValue("templatename","main")>		<!--- Set the View To Display, after Logic --->		<cfset setView("vwMessages")>	</cffunction>		<!--- ************************************************************* --->		<cffunction name="doMessagePost" access="public" returntype="void" output="false" hint="Post a message from the message display">		<cfset var errors = "">		<cfset var message = "">		<cfset var args = "">		<cfset var msgid = "">		<cfset var uinfo = "">		<cfset var newFileName = "">		<cfset var newExtension = "">				<!--- Init Messages --->		<cfset initMessages()>				<!--- Param --->		<cfset paramValue("oldattachment", "")>		<cfset paramValue("attachment", "")>		<cfset paramValue("filename", "")>		<cfif request.udf.isLoggedOn() and (application.utils.isUserInAnyRole("forumsadmin,forumsmoderator")) or not getValue("readonly")>			<!--- clean the fields --->			<cfset setvalue("post_title",trim(htmlEditFormat(rc.post_title)))>			<cfset setvalue("body", trim(htmlEditFormat(rc.body)))>			<cfif not len(getValue("post_title"))>				<cfset errors = errors & "You must enter a title.<br>">			</cfif>						<cfif not len(getValue("body"))>				<cfset errors = errors & "You must enter a body.<br>">			</cfif>			<cfif len(getValue("post_title")) gt 255>				<cfset errors = errors & "Your title is too long.<br>">			</cfif>						<cfif isBoolean(request.forum.attachments) and request.forum.attachments and len(trim(rc.attachment))>				<cffile action="upload" destination="#expandPath("./attachments")#" filefield="attachment" nameConflict="makeunique">								<cfif cffile.fileWasSaved>					<!--- Is the extension allowed? --->					<cfset newFileName = cffile.serverDirectory & getSetting("OSFileSeparator",1) & cffile.serverFile>					<cfset newExtension = cffile.serverFileExt>										<cfif not listFindNoCase(application.settings.safeExtensions, newExtension)>						<cfset errors = errors & "Your file did not have a valid extension. Allowed extensions are: #application.settings.safeExtensions#.<br>">						<cffile action="delete" file="#newFilename#">						<!--- Do not redirect, but display message for editing --->						<cfset getPlugin("messagebox").setMessage("error",errors)>						<!--- Set the Message --->						<cfset dspMessages()>						<cfreturn>					<cfelse>						<cfset rc.oldattachment = cffile.clientFile>						<cfset rc.attachment = cffile.clientFile>						<cfset rc.filename = cffile.serverFile>					</cfif>				</cfif>			<cfelseif len(rc.oldattachment)>				<cfset rc.attachment = rc.oldattachment>			</cfif>						<cfif not len(errors)>				<cfset message = structNew()>				<cfset message.title = getValue("post_title")>				<cfset message.body = getValue("body")>				<cfset message.attachment = rc.attachment>				<cfset message.filename = rc.filename>								<cfset args = structNew()>				<cfset args.message = message>				<cfset args.forumid = request.forum.id>				<cfset args.threadid = getValue("threadid")>				<cfset msgid = application.message.addMessage(argumentCollection=args)>				<cfif getValue("subscribe")>					<cfset application.user.subscribe(getAuthUser(), "thread", getValue("threadid"))>				</cfif>				<!--- clear my user info --->				<cfset uinfo = request.udf.cachedUserInfo(getAuthUser(), false)>				<cfset setNextEvent("ehMessages.dspMessages","threadid=#rc.threadid#&##top")>				<cfreturn>			</cfif>			<!--- Errors Detected --->			<cfset getPlugin("messagebox").setMessage("error",errors)>			<!--- Set the View To Display, after Logic --->			<cfset setNextEvent("ehMessages.dspMessages","posterrors&threadid=#getValue("threadid")#&##bottom")>		<cfelse>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>	</cffunction>		<!--- ************************************************************* --->		<cffunction name="dspNewPost" access="public" returntype="void" output="false" hint="From the New Post button">		<cfset var thisPage = "">		<!--- EXIT HANDLERS: --->		<cfset rc.xehForums = "ehForums.dspForums">		<cfset rc.xehThreads = "ehForums.dspThreads">		<cfset rc.xehMessages = "ehMessages.dspMessages">		<cfset rc.xehNewTopic = "ehMessages.doNewPost">				<cfif not request.udf.isLoggedOn()>			<cfset thisPage = cgi.script_name & "?" & cgi.query_string>			<cfset setNextEvent("ehUsers.dspLogin","ref=#urlEncodedFormat(thisPage)#")>		</cfif>		<cfif not valueExists("forumid") or not len(getValue("forumid"))>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<!--- get parents --->		<cftry>			<cfset request.forum = application.forum.getForum(getvalue("forumid"))>			<cfset request.conference = application.conference.getConference(request.forum.conferenceidfk)>			<!--- check both thread and forum for readonly and not admin --->			<cfif request.forum.readonly or (isDefined("request.thread") and request.thread.readonly)>				<cfif not application.utils.isUserInAnyRole("forumsadmin,forumsmoderator")>					<cfset rc.blockedAttempt = true>				</cfif>			</cfif>			<cfcatch>				<cfset getPlugin("logger").logError("Error getting forums and conferences information", cfcatch)>				<cfset setNextEvent("ehForums.dspHome")>			</cfcatch>		</cftry>				<!--- Param Values --->		<cfset paramValue("post_title","")>		<cfset paramValue("body","")>		<cfset paramValue("subscribe","true")>		<cfset paramValue("oldattachment", "")>		<cfset paramValue("attachment", "")>		<cfset paramValue("filename", "")>		<cfset paramValue("blockedAttempt","false")>				<!--- Set Title and Templatename --->		<cfset setValue("title","#application.settings.title# : New Post")>		<cfset setValue("templatename","main")>		<!--- Set the View To Display, after Logic --->		<cfset setView("vwNewpost")>	</cffunction>		<!--- ************************************************************* --->		<cffunction name="doNewPost" access="public" returntype="void" output="false" hint="Create a thread and post message.">		<cfset var errors = "">		<cfset var thisPage = "">		<cfset var message = "">		<cfset var args = "">		<cfset var msgid = "">		<cfset var uinfo = "">		<cfset var newFileName = "">		<cfset var newExtension = "">		<cfset var blockedAttempt = false>				<cfif not request.udf.isLoggedOn()>			<cfset thisPage = cgi.script_name & "?" & cgi.query_string>			<cfset setNextEvent("ehUsers.dspLogin","ref=#urlEncodedFormat(thisPage)#")>		</cfif>		<cfif not valueExists("forumid") or not len(getValue("forumid"))>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<!--- get parents --->		<cftry>			<cfset request.forum = application.forum.getForum(rc.forumid)>			<cfset request.conference = application.conference.getConference(request.forum.conferenceidfk)>			<!--- check both thread and forum for readonly and not admin --->			<cfif request.forum.readonly or (isDefined("request.thread") and request.thread.readonly)>				<cfif not application.utils.isUserInAnyRole("forumsadmin,forumsmoderator")>					<cfset rc.blockedAttempt = true>				</cfif>			</cfif>			<cfcatch>				<cflocation url="index.cfm" addToken="false">			</cfcatch>		</cftry>				<!--- Param --->		<cfset paramValue("oldattachment", "")>		<cfset paramValue("attachment", "")>		<cfset paramValue("filename", "")>		<cfset paramValue("blockedAttempt","false")>				<!--- clean the fields --->		<cfset setValue("title", trim(htmlEditFormat(getvalue("post_title"))) )>		<cfset setValue("body", trim(htmlEditFormat(getValue("body"))) )>		<cfif not len(getvalue("post_title"))>			<cfset errors = errors & "You must enter a title.<br>">		</cfif>		<cfif not len(getValue("body"))>			<cfset errors = errors & "You must enter a body.<br>">		</cfif>		<cfif len(getvalue("post_title")) gt 255>			<cfset errors = errors & "Your title is too long.<br>">		</cfif>		<cfif isBoolean(request.forum.attachments) and request.forum.attachments and len(trim(rc.attachment))>			<cffile action="upload" destination="#expandPath("./attachments")#" filefield="attachment" nameConflict="makeunique">						<cfif cffile.fileWasSaved>				<!--- Is the extension allowed? --->				<cfset newFileName = cffile.serverDirectory & getSetting("OSFileSeparator",1) & cffile.serverFile>				<cfset newExtension = cffile.serverFileExt>								<cfif not listFindNoCase(application.settings.safeExtensions, newExtension)>					<cfset errors = errors & "Your file did not have a valid extension. Allowed extensions are: #application.settings.safeExtensions#.<br>">					<cffile action="delete" file="#newFilename#">				<cfelse>					<cfset rc.oldattachment = cffile.clientFile>					<cfset rc.attachment = cffile.clientFile>					<cfset rc.filename = cffile.serverFile>				</cfif>			</cfif>		<cfelseif len(rc.oldattachment)>			<cfset rc.attachment = rc.oldattachment>		</cfif>					<cfif not len(errors)>			<cfset message = structNew()>			<cfset message.title = getvalue("post_title")>			<cfset message.body = getValue("body")>			<cfset message.attachment = rc.attachment>			<cfset message.filename = rc.filename>							<cfset args = structNew()>			<cfset args.message = message>			<cfset args.forumid = getValue("forumid")>			<cfset msgid = application.message.addMessage(argumentCollection=args)>			<!--- get the message so we can get thread id --->			<cfset message = application.message.getMessage(msgid)>			<cfif getValue("subscribe",false)>				<cfset application.user.subscribe(getAuthUser(), "thread", message.threadidfk)>			</cfif>			<!--- clear my user info --->			<cfset uinfo = request.udf.cachedUserInfo(getAuthUser(), false)>			<cfset setNextEvent("ehMessages.dspMessages","threadid=#message.threadidfk#")>		</cfif>		<!--- Do not redirect, but display message for editing --->		<cfset getPlugin("messagebox").setMessage("error",errors)>		<!--- Set the new post event --->		<cfset dspNewPost()>		<cfreturn>	</cffunction>		<!--- ************************************************************* --->		<cffunction name="dspMessageEdit" access="public" returntype="void" output="false">		<!--- EXIT HANDLERS: --->		<cfset rc.xehForums = "ehForums.dspForums">		<cfset rc.xehThreads = "ehForums.dspThreads">		<cfset rc.xehMessages = "ehMessages.dspMessages">		<cfset rc.xehMessagePost = "ehMessages.doEditPost">				<cfif not request.udf.isLoggedOn() or not application.utils.isUserInAnyRole("forumsadmin,forumsmoderator")>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<cfif not valueExists("id") or not Len(getValue("id"))>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<!--- get parents --->		<cftry>			<cfset request.message = application.message.getMessage(getValue("id"))>			<cfset request.thread = application.thread.getThread(request.message.threadidfk)>			<cfset request.forum = application.forum.getForum(request.thread.forumidfk)>			<cfset request.conference = application.conference.getConference(request.forum.conferenceidfk)>			<cfcatch>				<cfset getPlugin("logger").logError("Error getting forums, thread, messsage and conferences information", cfcatch)>				<cfset setNextEvent("ehForums.dspHome")>				<cfreturn>			</cfcatch>		</cftry>		<!--- Set Variables to Edit --->		<cfset setvalue("post_title",request.message.title)>		<cfset setvalue("body",request.message.body)>		<cfset setValue("oldattachment",request.message.attachment)>		<cfset setValue("filename", request.message.filename)>		<!--- Set Title and Templatename --->		<cfset setValue("title","#application.settings.title# : Edit Post")>		<cfset setValue("templatename","main")>		<!--- Set the View To Display, after Logic --->		<cfset setView("vwMessage_edit")>	</cffunction>		<!--- ************************************************************* --->	<cffunction name="doEditPost" access="public" returntype="void" output="false">		<cfset var errors = "">		<cfset var message = "">		<cfset var newFileName = "">		<cfset var newExtension = "">				<cfif not request.udf.isLoggedOn() or not application.utils.isUserInAnyRole("forumsadmin,forumsmoderator")>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<cfif not valueExists("id") or not Len(getValue("id"))>			<cfset setNextEvent("ehForums.dspHome")>		</cfif>		<!--- get parents --->		<cftry>			<cfset request.message = application.message.getMessage(getValue("id"))>			<cfset request.thread = application.thread.getThread(request.message.threadidfk)>			<cfset request.forum = application.forum.getForum(request.thread.forumidfk)>			<cfset request.conference = application.conference.getConference(request.forum.conferenceidfk)>			<cfcatch>				<cfset getPlugin("logger").logError("Error getting forums, thread, messsage and conferences information", cfcatch)>				<cfset setNextEvent("ehForums.dspHome")>			</cfcatch>		</cftry>		<!--- clean the fields --->		<cfset setValue("post_title", trim(htmlEditFormat(getValue("post_title"))))>		<cfset setValue("body", trim(htmlEditFormat(form.body)))>		<!--- Param Values --->		<cfset paramValue("oldattachment", "")>		<cfset paramValue("attachment", "")>		<cfset paramValue("filename", "")>				<cfif not len(getValue("post_title"))>			<cfset errors = errors & "You must enter a title.<br>">		</cfif>		<cfif not len(getValue("body"))>			<cfset errors = errors & "You must enter a body.<br>">		</cfif>		<cfif len(getValue("post_title")) gt 255>			<cfset errors = errors & "Your title is too long.<br>">		</cfif>				<cfif isBoolean(request.forum.attachments) and request.forum.attachments and len(trim(rc.attachment))>			<cffile action="upload" destination="#expandPath("./attachments")#" filefield="attachment" nameConflict="makeunique">						<cfif cffile.fileWasSaved>				<!--- Is the extension allowed? --->				<cfset newFileName = cffile.serverDirectory & "/" & cffile.serverFile>				<cfset newExtension = cffile.serverFileExt>								<cfif not listFindNoCase(application.settings.safeExtensions, newExtension)>					<cfset errors = errors & "Your file did not have a valid extension. Allowed extensions are: #application.settings.safeExtensions#.<br>">					<cffile action="delete" file="#newFilename#">				<cfelse>					<cfset rc.oldattachment = cffile.clientFile>					<cfset rc.attachment = cffile.clientFile>					<cfset rc.filename = cffile.serverFile>				</cfif>			</cfif>		<cfelseif valueExists("removefile")>			<cfset rc.attachment = "">			<cffile action="delete" file="#application.settings.attachmentdir#/#rc.filename#">			<cfset rc.filename = "">		<cfelseif len(rc.oldattachment)>			<cfset rc.attachment = rc.oldattachment>		</cfif>				<cfif not len(errors)>			<cfset message = structNew()>			<cfset message.title = trim(htmlEditFormat(getValue("post_title")))>			<cfset message.body = trim(htmlEditFormat(getValue("body")))>			<cfset message.attachment = rc.attachment>			<cfset message.filename = rc.filename>			<cfset message.posted = request.message.posted>			<cfset message.threadidfk = request.message.threadidfk>			<cfset message.useridfk = request.message.useridfk>			<cfset application.message.saveMessage(getValue("id"), message)>			<cfset setNextEvent("ehMessages.dspMessages","threadid=#message.threadidfk#")>		</cfif>		<cfset getPlugin("messagebox").setMessage("error",errors)>		<!--- Set the View To Display, after Logic --->		<cfset setNextEvent("ehMessages.dspMessages","posterrors&threadid=#getValue("id")#")>	</cffunction>	<!--- ************************************************************* --->		<cffunction name="dspAttachment" access="public" returntype="void" output="false">		<!---		Name         : attachment.cfm		Author       : Raymond Camden 		Created      : November 3, 2004		Last Updated : 		History      : 		Purpose		 : Load an attachment	--->	<cfset var message = "">	<cfset var extension = "">		<cfif not valueExists("id") or not len(rc.id)>		<cfset setNextEvent("ehForums.dspHome")>	</cfif>		<cftry>		<cfset message = application.message.getMessage(rc.id)>		<cfcatch>			<cfset getPlugin("logger").logError("Error getting Message", cfcatch)>			<cfset setNextEvent()>		</cfcatch>	</cftry>		<cfif not len(message.filename)>		<cfset setNextEvent()>	</cfif>		<cfif not fileExists(application.settings.attachmentdir & getSetting("OSFileSeparator",1) & message.filename)>		<cfset setNextEvent()>	</cfif>		<cfset extension = listLast(message.filename, ".")>		<cfswitch expression="#extension#">			<cfcase value="txt">			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">			<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="text/plain">		</cfcase>						<cfcase value="pdf">			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">					<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="application/pdf">		</cfcase>					<cfcase value="doc">			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">					<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="application/msword">				</cfcase>				<cfcase value="ppt">			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">					<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="application/vnd.ms-powerpoint">				</cfcase>				<cfcase value="xls">			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">					<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="application/application/vnd.ms-excel">				</cfcase>			<cfcase value="zip">			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">					<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="application/application/zip">				</cfcase>				<!--- everything else --->		<cfdefaultcase>			<cfheader name="Content-disposition" value="attachment;filename=#message.filename#">					<cfcontent file="#application.settings.attachmentdir#/#message.filename#" type="application/unknown">				</cfdefaultcase>					</cfswitch>		<cfabort>	</cffunction>		<!--- ************************************************************* --->	</cfcomponent>