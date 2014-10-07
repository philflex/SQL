/* DA BOMB DIGGITY PEOPLE DASHBOARD */

Use ZocDoc

/* Ops Members Start */

Use ZocDoc

SELECT e.WorkingLocationGeographyId ,ep.PositionID, pr.PositionName, lower(e.WorkEmail) AS LoweredEmail, (e.FirstName+' '+e.LastName) AS FullName
		INTO #Ops
			FROM Employee e
					OUTER APPLY
						(SELECT TOP 1 epi.PositionID
							 FROM EmployeePosition epi
								 WHERE epi.EmployeeID = e.EmployeeID
							 AND epi.EmployeePosDeletedDate is null
						  AND e.RecordDeletedDate IS NULL
					  AND e.TermDate IS NULL
				  Order by epi.EmployeePosStartDate Desc) ep
			INNER JOIN Position_REF pr on pr.PositionID = ep.PositionID 
	WHERE PositionName LIKE '%Provider%'
	OR PositionName LIKE '%Patient%'
	OR PositionName LIKE '%Director of Operations%'
	OR PositionName LIKE '%Technical Operations%'
	OR PositionName LIKE '%Operations Trainer%'
	OR PositionName LIKE '%Operations Associate%'
	ORDER BY pr.PositionName DESC
	

/* Ops Members End */


/* Unconfirmed Start*/

USE ZOCDOC

SELECT DISTINCT TimeZoneID, ZipCode, pp.ProviderID, pp.ProfessionalID
INTO #timezone
FROM ZipCode_REF zc
JOIN ProviderLocation pl ON pl.ZIP=zc.ZipCode
JOIN ProviderLocationMapping plm ON plm.ProviderLocationID=pl.ID
JOIN ProfessionalProvider pp on pp.ProviderID=plm.ProviderID

SELECT rs.requestid
INTO #called
FROM RequestStatus rs 
WHERE rs.Type = 3
AND rs.Status IN (51,52) 
AND rs.Timestamp > GETDATE() - 365

SELECT
r.CProfessionalID, r.ID AS RequestID, r.TimeInitiated AS 'Start', r.CAppointmentTime AS 'DueDate' 
INTO #interaction
FROM Request r
JOIN RequestStatus rs ON r.ID = rs.RequestID
WHERE r.ID IN (SELECT #called.RequestID FROM #called)
AND r.TimeInitiated > GETDATE() - 365
AND r.CAppointmentTime < GETDATE() - 1 
AND r.CProfessionalID IN (SELECT pp.ProfessionalID FROM ProfessionalProvider pp WHERE pp.ProviderID IN (SELECT Provider.ID FROM Provider where Provider.IsUrgentCare=0))
      
SELECT DISTINCT *

,(SELECT TOP 1 rs.Timestamp 
	FROM RequestStatus rs 
		WHERE rs.RequestID = #interaction.RequestId 
			AND rs.Type = 3 
				AND rs.Status IN (12, 51, 52,8,9)
					 ORDER BY rs.Timestamp DESC) AS OpsInteraction
					 
,(SELECT TOP 1 rs.OwnerEmail
	FROM RequestStatus rs
		 WHERE rs.RequestID=#interaction.requestid
			AND rs.Type=3
					AND rs.Status IN (12, 51, 52,8,9)
						ORDER BY rs.timestamp DESC) AS Associate
						
,(SELECT TOP 1 rs.Timestamp
	 FROM RequestStatus rs 
		WHERE rs.RequestID = #interaction.RequestId
			 AND rs.Type = 2
				 AND rs.Status IN (2, 3, 5,210) 
					ORDER BY rs.Timestamp DESC) 
						AS PracticeInteraction
						
,(SELECT TOP 1 rs.Timestamp 
	FROM RequestStatus rs 
		WHERE rs.RequestID = #interaction.RequestId 
			AND rs.Type = 1 
				AND rs.Status IN (3,8,9) 
					ORDER BY rs.Timestamp DESC) 
						AS PatientCancelled
INTO #final
FROM #interaction

SELECT *
	
	,CASE 
		WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Pacific Standard Time')
			
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-11, Start) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Eastern Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-5, Start)
					
						WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Central Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-7, Start) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Mountain Standard Time')								
				
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, Start) 
	
			    WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Mountain Standard Time')                                               
                        
			  THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, Start) 
		
		ELSE NULL
	
	END AS StartAdjusted
	
	,CASE 
		WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Pacific Standard Time')
			
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-11, PatientCancelled) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Eastern Standard Time')
				
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-5, PatientCancelled)
					
						WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Central Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-7, PatientCancelled) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Mountain Standard Time')								
				
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, PatientCancelled) 

		        WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Mountain Standard Time')                                               
                        
                  THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, PatientCancelled) 
		
		ELSE NULL
		
	END AS PatientCancelledAdjusted
	
	,CASE 
		WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Pacific Standard Time')
			
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-11, PracticeInteraction) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Eastern Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-5, PracticeInteraction)
					
						WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Central Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-7, PracticeInteraction) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Mountain Standard Time')								
				
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, PracticeInteraction) 
                    
                WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Mountain Standard Time')                                               
                        
            THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, PracticeInteraction) 
          

		ELSE NULL
		
	END AS PracticeInteractionAdjusted
	
	,CASE 
		WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Pacific Standard Time')
			
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-11, OpsInteraction) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Eastern Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-5, OpsInteraction)
					
						WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Central Standard Time')
					
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-7, OpsInteraction) 
				
				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Mountain Standard Time')								
				
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, OpsInteraction) 

				WHEN CProfessionalID IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Mountain Standard Time')                                               
                        
            THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM TimeZone_REF tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM ZipCode_REF zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM ProviderLocation pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM ProfessionalLocationMapping plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, OpsInteraction) 

		ELSE NULL
		
	END AS OpsInteractionAdjusted
	
INTO #final1
FROM #final
   
SELECT DISTINCT CprofessionalID
, RequestID
, 'https://csr.zocdoc.com/csr/doctorstatus#professionalId/'+convert(varchar, Cprofessionalid)+'/requestId/'+convert(varchar, requestid) AS DocStatus
, StartAdjusted AS 'Start'
, OpsInteractionAdjusted AS 'OpsInteraction'
, Associate 
, PracticeInteractionAdjusted AS 'PracticeInteraction'
, PatientCancelledAdjusted AS 'PatientCancelled'
, DueDate

INTO #final2
FROM #final1


SELECT * 
	,CASE 
		WHEN PracticeInteraction < OpsInteraction AND DATEDIFF(minute,OpsInteraction,PracticeInteraction) > 2
			THEN 'X' 
		WHEN PatientCancelled < PracticeInteraction AND PracticeInteraction < DueDate
			THEN 'X'	
				END AS Ignore
	

INTO #Final3
FROM #final2

SELECT *,
	CASE 
		WHEN Ignore IS NOT NULL 
			THEN NULL
				WHEN PracticeInteraction IS NOT NULL AND PracticeInteraction < DueDate
					THEN 1
						ELSE 0
							END AS 'InMetric'
INTO #final4
FROM #final3

SELECT DISTINCT *
INTO #final5
FROM #final4
WHERE OpsInteraction IS NOT NULL
AND Ignore IS NULL
AND DueDate < GETDATE() - 1
AND DueDate > GETDATE() - 365

/* Unconfirmed End*/


/* Alerter Start*/

USE ZocDoc

SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #alerter
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (37)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, users

, (SELECT TOP 1 Taskstatus
		FROM #Alerter
			WHERE #Alerter.WorkflowId=w.workflowId
				AND #Alerter.tasktypeID=w.tasktypeID
					AND #Alerter.Users=w.Users
					ORDER BY #Alerter.lastactiontimeUtc DESC) 
						AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #Alerter
			WHERE #Alerter.WorkflowId=w.workflowId
				AND #Alerter.tasktypeID=w.tasktypeID
					AND #Alerter.Users=w.Users
						ORDER BY #Alerter.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #Alerter2
FROM #Alerter w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #Alerter3
FROM #Alerter2


/* Alerter end*/

/* Widget Installation Start*/

SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #widgets
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (5,8)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	AND h.dateUTC NOT IN ('2014-05-19','2014-05-20')
	
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #widgets
			WHERE #widgets.WorkflowId=w.workflowId
				AND #widgets.tasktypeID=w.tasktypeID
					AND #widgets.Users=w.Users
						ORDER BY #widgets.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #widgets
			WHERE #widgets.WorkflowId=w.workflowId
				AND #widgets.tasktypeID=w.tasktypeID
						AND #widgets.Users=w.Users
							ORDER BY #widgets.lastactiontimeUtc DESC) 
								AS 'FirstCompleted'
	
INTO #widgets2
FROM #widgets w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #widgets3
FROM #widgets2

/* Unbookable Start */
	
SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #unbookable
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (30, 31, 32, 33, 34, 36)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful','Closed Should No Longer Exist')
	AND odt.targetEntityId NOT IN (SELECT ch.ProfessionalId FROM ChurnQueue ch where ch.DateResolved IS NULL)
		
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #unbookable
			WHERE #unbookable.WorkflowId=w.workflowId
				AND #unbookable.tasktypeID=w.tasktypeID
					AND #unbookable.users=w.users
						ORDER BY #unbookable.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #unbookable
			WHERE #unbookable.WorkflowId=w.workflowId
				AND #unbookable.tasktypeID=w.tasktypeID
					AND #unbookable.users=w.users
						ORDER BY #unbookable.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'
	
INTO #unbookable2
FROM #unbookable w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #unbookable3
FROM #unbookable2
/* Unbookable End */

/* Professional Photos Start */

SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #photo
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (39)
		AND taskStatus.statusString IN ('Snoozed','Closed - Successful','Closed Should No Longer Exist')
	
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #photo
			WHERE #photo.WorkflowId=w.workflowId
				AND #photo.tasktypeID=w.tasktypeID
					AND #photo.users=w.users
						ORDER BY #photo.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #photo
			WHERE #photo.WorkflowId=w.workflowId
				AND #photo.tasktypeID=w.tasktypeID
					AND #photo.users=w.users
						ORDER BY #photo.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #photo2
FROM #photo w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #photo3
FROM #photo2


 /* Professional Photos END */

/* Professional Phone Trees Start*/

Use ZocDoc

select pt.providerID, prof.ProfessionalID, pt.DateCreated, pt.CreatedBy AS 'Associate', pt.DateResolved
INTO #phonetree
from PhoneTree pt 
	CROSS APPLY (SELECT TOP 1 pp.professionalID
					FROM ProfessionalProvider pp
						WHERE pp.ProviderID=pt.providerId
							ORDER BY pp.ActivationDate DESC) prof

/* Professional Phone Trees End*/

/* Google Places Start*/
	
SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #gp
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (43)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #gp
			WHERE #gp.WorkflowId=w.workflowId
				AND #gp.tasktypeID=w.tasktypeID
					AND #gp.Users=w.Users
						ORDER BY #gp.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #gp
			WHERE #gp.WorkflowId=w.workflowId
				AND #gp.tasktypeID=w.tasktypeID
					AND #gp.Users=w.Users
						ORDER BY #gp.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #gp2
FROM #gp w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #gp3
FROM #gp2

/* Google Places End*/

/* Reminders Start */


SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #reminders
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (64)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, users

, (SELECT TOP 1 Taskstatus
		FROM #reminders
			WHERE #reminders.WorkflowId=w.workflowId
				AND #reminders.tasktypeID=w.tasktypeID
					AND #reminders.users=w.users
						ORDER BY #reminders.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #reminders
			WHERE #reminders.WorkflowId=w.workflowId
				AND #reminders.tasktypeID=w.tasktypeID
					AND #reminders.users=w.users
						ORDER BY #reminders.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #reminders2
FROM #reminders w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #reminders3
FROM #reminders2

/* Reminders End */

/* Sync Start */

SELECT
	 oqi.ProviderLocationId
	, oqi.createdby
	, oqi.scheduleddate
    , CASE 
		WHEN oqi.Type = 1 THEN 'BrokenSync' 
		WHEN oqi.Type = 2 THEN 'NewSync' 
		WHEN oqi.type = 3 THEN 'AddNewSoftwareRequest' 
		WHEN oqi.Type = 4 THEN 'Technical Issue' 
		WHEN oqi.Type = 5 THEN 'Other' 
		WHEN oqi.Type = 6 THEN 'New Reminders' 
		WHEN oqi.Type = 7 THEN 'Broken Reminders'
		ELSE 'Unknown'
	END AS Type
	, CASE
		WHEN oqi.Status = 1 THEN 'Unresolved'
		WHEN oqi.Status = 2 THEN 'AwaitingResponse'
		WHEN oqi.Status = 3 THEN 'Completed'
		WHEN oqi.Status = 4 THEN 'Infeasible'
		WHEN oqi.Status = 5 THEN 'IntegrationRefused'
		WHEN oqi.Status = 6 THEN 'IntegrationScheduled'
		WHEN oqi.Status = 7 THEN 'IntegrationEscalated'
		WHEN oqi.Status = 8 THEN 'SchedulingHero'
		WHEN oqi.Status = 9 THEN 'FrontEndIntegrationNeeded'
		WHEN oqi.Status = 10 THEN 'Unresponsive'
		WHEN oqi.Status = 11 THEN 'NotAnIntegrationTicket'
		WHEN oqi.Status = 12 THEN 'EscalatedToAM'
		ELSE 'Unknown Status'
	END AS Status
	, oqi.CreatedDate
	, CASE WHEN oqi.Status IN (3,4,9) THEN oqi.LastUpdated ELSE NULL END AS ResolveDate
INTO #synca
FROM OpsQueueIntegration oqi
where oqi.type IN (1,2)
and CreatedDate > GETDATE()-365

SELECT *
,'https://csr.zocdoc.com/csr/doctorstatus#professionalId/'+CONVERT(varchar(50), b.professionalID) AS URL
, CASE 
	WHEN Scheduleddate IS NULL 
		THEN 
			CASE	
				WHEN DATEDIFF(DD,CreatedDate,ResolveDate) <= 2 THEN 1 
			END  
	ELSE 
		CASE
			 WHEN scheduleddate IS NOT NULL 
				
				THEN 
		CASE
				WHEN ResolveDate IS NOT NULL AND DATEDIFF(hh,scheduleddate,resolvedate) < 2 THEN 1 ELSE 0 
			END
		END 
	END
  	AS InMetric
INTO #syncb
FROM #synca
CROSS APPLY 
	(Select TOP 1 plm.providerId
		FROM providerlocationmapping plm 
			where plm.providerlocationid=#synca.providerlocationId) a
		
OUTER APPLY 
	(SELECT TOP 1 pp.professionalID 
		FROM professionalprovider pp 
			Where pp.providerID=a.providerId		
				ORDER BY pp.activationdate DESC) b 
				
				
/* Sync End */

/* Visit Reason Start */


SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #visitreason
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (46)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #visitreason
			WHERE #visitreason.WorkflowId=w.workflowId
				AND #visitreason.tasktypeID=w.tasktypeID
					AND #visitreason.users=w.users
						ORDER BY #visitreason.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #visitreason
			WHERE #visitreason.WorkflowId=w.workflowId
				AND #visitreason.tasktypeID=w.tasktypeID
					AND #visitreason.users=w.users
						ORDER BY #visitreason.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'
	
INTO #visitreason2
FROM #visitreason w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #visitreason3
FROM #visitreason2

/* Visit Reason End */

/* Insurance Coverage Start */

SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #insurance
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (45)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #insurance
			WHERE #insurance.WorkflowId=w.workflowId
				AND #insurance.tasktypeID=w.tasktypeID
					AND #insurance.users=w.users
						ORDER BY #insurance.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #insurance
			WHERE #insurance.WorkflowId=w.workflowId
				AND #insurance.tasktypeID=w.tasktypeID
					AND #insurance.users=w.users
						ORDER BY #insurance.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #insurance2
FROM #insurance w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #insurance3
FROM #insurance2

/* Insurance Coverage End */

/* Faxed Reviews Start */

SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #reviews
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (38)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, Users

, (SELECT TOP 1 Taskstatus
		FROM #reviews
			WHERE #reviews.WorkflowId=w.workflowId
				AND #reviews.tasktypeID=w.tasktypeID
					AND #reviews.users=w.users
						ORDER BY #reviews.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #reviews
			WHERE #reviews.WorkflowId=w.workflowId
				AND #reviews.tasktypeID=w.tasktypeID
					AND #reviews.users=w.users
						ORDER BY #reviews.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #reviews2
FROM #reviews w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #reviews3
FROM #reviews2

/* Faxed Reviews End */

/* Professional Statement Start */

SELECT DISTINCT
 odt.taskId
,odt.targetEntityId AS 'ProviderId'
,odtt.friendlyName AS 'taskname'
,odw.workflowId
,h.dateUTC AS 'LastActionTimeUtc'
,odt.taskTypeId
,u.LoweredUserName AS 'Users'
,taskStatus.statusString AS 'Taskstatus'
INTO #statement
FROM OnDeckTask odt
INNER JOIN OnDeckTaskStatusHistory h ON h.taskId=odt.taskId
INNER JOIN OnDeckWorkflowTask odw ON odw.taskId=odt.taskId
INNER JOIN OnDeckTaskType odtt ON odtt.taskTypeId=Odt.taskTypeId
INNER JOIN OnDeckTaskStatus_REF taskStatus ON taskStatus.taskStatusId = h.statusId
INNER JOIN aspnet_Users u on u.UserId = h.actionPerformedByUserId
WHERE
	odt.taskTypeId IN (44)
	AND taskStatus.statusString IN ('Snoozed','Closed - Successful')
	
SELECT DISTINCT WorkflowId, providerID, taskname, users

, (SELECT TOP 1 Taskstatus
		FROM #statement
			WHERE #statement.WorkflowId=w.workflowId
				AND #statement.tasktypeID=w.tasktypeID
					AND #statement.users=w.users
						ORDER BY #statement.lastactiontimeUtc DESC) 
							AS 'Status'
						
, (SELECT TOP 1 LastactiontimeUtc
		FROM #statement
			WHERE #statement.WorkflowId=w.workflowId
				AND #statement.tasktypeID=w.tasktypeID
					AND #statement.users=w.users
						ORDER BY #statement.lastactiontimeUtc DESC) 
							AS 'FirstCompleted'

INTO #statement2
FROM #statement w

SELECT *
,'https://csr.zocdoc.com/csr/OnDeck/WorkFlow/'+CONVERT(varchar(50), workflowID ) AS URL
INTO #statement3
FROM #statement2

/* Professional Statement End */

/* FollowUps Start */

SELECT
       oq.ResponseFrom AS 'Associate'
     , oq.ResponseDate AS 'ActionTime'
	 , 'https://csr.zocdoc.com/csr/EmailQueue#category=1&email='+ CONVERT(VARCHAR, oq.Id) AS 'URL'
INTO #followups
FROM OpsQueue oq
WHERE oq.Category = 'FollowUp' and oq.CreatedDate > GETDATE() - 365
AND ResponseDate IS NOT NULL

UNION SELECT
	   oq.ResponseFrom AS 'Associate'
     , oq.ResponseDate AS 'ActionTime'
	 , 'https://csr.zocdoc.com/csr/EmailQueue#category=1&email='+ CONVERT(VARCHAR, oq.Id) AS 'URL'
FROM OpsQueue_vw oq
WHERE oq.Category = 'FollowUp' and oq.CreatedDate > GETDATE() - 365
AND ResponseDate IS NOT NULL


/* FollowUps End */

/* Amazons Dispatcher Start */

SELECT  
	  oqpt.LastAccess AS ActionTime
	, oqpt.Username AS Associate
	, 'https://csr.zocdoc.com/csr/patientstatus#!/patient-'+convert(varchar, patientId) AS URL
INTO #ama
FROM OpsQueuePatientTask oqpt
WHERE oqpt.TaskId IN (1,2) 
AND oqpt.CreatedDate IS NOT NULL
AND oqpt.ResolveDate > GETDATE()-365

  /* Amazons Dispatcher End */

USE zocdoc
SELECT
	r.ID AS RequestID
	, r.ZdAppointmentId
	, r.CProfessionalID AS ProfessionalID
	, rs.OwnerEmail
	, (SELECT TOP 1 rs2.Timestamp 
		FROM Request r2 
			JOIN RequestStatus rs2 ON r2.ID = rs2.RequestID
				 WHERE r2.ID = r.ID 
					AND rs2.Status IN (14)) 
						AS AutoEmail
						
	, (SELECT TOP 1 rs2.Timestamp 
		FROM Request r2 
			JOIN RequestStatus rs2 ON r2.ID = rs2.RequestID 
				WHERE r2.ID = r.ID 
					AND rs2.Status IN (13)	
						ORDER BY rs2.Timestamp DESC) 
							AS TimeCalled
							
	, (SELECT TOP 1 rs3.Timestamp 
		FROM Request r3 
			JOIN RequestStatus rs3 ON r3.ID = rs3.RequestID
				 WHERE r3.ID = r.ID 
					AND rs3.Status = 10 
						ORDER BY rs3.Timestamp DESC)
							 AS TimeAmazon
							 
	, (SELECT TOP 1 rs3.Timestamp 
		FROM Request r3 
			JOIN RequestStatus rs3 ON r3.ID = rs3.RequestID 
				WHERE r3.ID = r.ID  
					AND rs3.Status = 17 ORDER BY rs3.Timestamp DESC)
						 AS TimeClosed
						 
	, (SELECT TOP 1 rs3.OwnerEmail 
		FROM Request r3 
			JOIN RequestStatus rs3 ON r3.ID = rs3.RequestID 
				WHERE r3.ID = r.ID 
					 AND rs3.Status = 17 
						ORDER BY rs3.Timestamp DESC) 
							AS ClosedBy
INTO #amazon
FROM Request r
INNER JOIN RequestStatus rs
	ON r.id = rs.RequestID
WHERE rs.Status IN (13) 
AND r.TimeInitiated > GETDATE() - 365
ORDER BY r.ID

SELECT
	ProfessionalID 
	, RequestID
	, OwnerEmail
	, AutoEmail
	, TimeAmazon
	, TimeClosed
	, TimeCalled
	, 'https://csr.zocdoc.com/csr/doctorstatus#professionalId/'+convert(varchar, professionalid)+'/requestId/'+convert(varchar, requestid) AS URL
	, CASE WHEN (right(#amazon.ClosedBy, 14) = '@testemail.com') THEN 'Auto-close' ELSE #amazon.ClosedBy END AS ClosedBy
	, CASE 
			WHEN TimeCalled IS NOT NULL
				AND TimeClosed IS NOT NULL
					AND TimeCalled < TimeClosed
						AND ClosedBy NOT LIKE ('%@testemail.com') 
							AND DATEDIFF(MINUTE, TimeCalled, TimeClosed) > 2
								 THEN 1 ELSE 0 END AS TotalCallbacks
INTO #amazon2
FROM #amazon 

/* Amazon End */

/* UNION */

SELECT 'Unconfirmed' AS Queue
, ' Unconfirmed Productivity' AS QueueType
, docstatus AS 'URL'
, Associate
, OpsInteraction AS ActionTime
INTO #final6
FROM #final5 

UNION SELECT 'Unconfirmed' AS Queue
, ' Unconfirmed Success' AS QueueType
, docstatus AS 'URL'
, Associate
, PracticeInteraction AS ActionTime
FROM #final5
Where InMetric=1 


UNION SELECT 'Alerter' AS Queue
, ' Alerter Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #alerter3


UNION SELECT 'Alerter' AS Queue
, 'Alerter Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #alerter3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Widget' AS Queue
, 'Widget Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #widgets3

UNION SELECT 'Widget' AS Queue
, 'Widget Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #widgets3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Unbookable' AS Queue
, 'Unbookable Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #unbookable3

UNION SELECT 'Unbookable' AS Queue
, 'Unbookable Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #unbookable3
WHERE Status IN ('Closed - Successful','Closed Should No Longer Exist')

UNION SELECT 'Photos' AS Queue
, 'Photos Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #photo3

UNION SELECT 'Photos' AS Queue
, 'Photos Success' AS QueueType
, URL
, (select TOP 1 Users 
		from #photo3 a
			where a.status IN ('Snoozed') 
				and a.workflowId=#photo3.workflowid
						order by firstcompleted DESC) AS Associate
, FirstCompleted AS ActionTime
FROM #photo3
WHERE Status IN ('Closed - Successful','Closed Should No Longer Exist')

UNION SELECT 'Professional Phonetree' AS Queue
, 'Professional Phonetree Productivity' AS QueueType
, 'https://csr.zocdoc.com/csr/doctorstatus#professionalId/'+convert(varchar, ProfessionalId) AS URL
, Associate
, DateCreated AS ActionTime
FROM #phonetree

UNION SELECT 'Professional Phonetree' AS Queue
, 'Professional Phonetree Success' AS QueueType
, 'https://csr.zocdoc.com/csr/doctorstatus#professionalId/'+convert(varchar, ProfessionalId) AS URL
, Associate
, DateResolved AS ActionTime
FROM #phonetree
WHERE Dateresolved IS NOT NULL

UNION SELECT 'Google Places' AS Queue
, 'Google Places Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #gp3

UNION SELECT 'Google Places' AS Queue
, 'Google Places Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #gp3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Reminders' AS Queue
, 'Reminders Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #Reminders3

UNION SELECT 'Reminders' AS Queue
, 'Reminders Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #Reminders3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Sync-Broken' AS Queue
, 'Sync-Broken Productivity' AS QueueType
, URL
, createdby AS Associate
, createddate AS ActionTime
FROM #syncb

UNION SELECT 'Sync-Broken' AS Queue
, 'Sync-Broken Success' AS QueueType
, URL
, createdby AS Associate
, createddate AS ActionTime
FROM #syncb
WHERE InMetric=1

UNION SELECT 'Visit Reason' AS Queue
, 'Visit Reason Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #visitreason3

UNION SELECT 'Visit Reason' AS Queue
, 'Visit Reason Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #visitreason3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Insurance' AS Queue
, 'Insurance Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #insurance3

UNION SELECT 'Insurance' AS Queue
, 'Insurance Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #Insurance3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Reviews' AS Queue
, 'Reviews Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #reviews3

UNION SELECT 'Reviews' AS Queue
, 'Reminders Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #reviews3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'Professional Statement' AS Queue
, 'Professional Statement Productivity' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #statement3

UNION SELECT 'Professional Statement' AS Queue
, 'Professional Statement Success' AS QueueType
, URL
, Users AS Associate
, FirstCompleted AS ActionTime
FROM #statement3
WHERE Status IN ('Closed - Successful')

UNION SELECT 'FollowUps' AS Queue
, 'FollowUps Productivity' AS QueueType
, URL
, Associate
, ActionTime
FROM #followups

UNION SELECT 'FollowUps' AS Queue
, 'FollowUps Success' AS QueueType
, URL
, Associate
, ActionTime
FROM #followups

UNION SELECT 'Problem Appointment Calls' AS Queue
, 'Problem Appointment Calls Productivity' AS QueueType
, URL
, Associate
, ActionTime
FROM #ama

UNION SELECT 'Problem Appointment Calls' AS Queue
, 'Problem Appointment Calls Success' AS QueueType
, URL
, OwnerEmail AS Associate
, TimeCalled AS ActionTime
FROM #amazon2
WHERE TotalCallbacks = 1


SELECT 
	* 
	, CASE  
		when DATEPART(WEEKDAY,ActionTime)= 1 then CONVERT(date,DATEADD(DAY, -6, ActionTime))
		when DATEPART(WEEKDAY,ActionTime)= 2 then convert(date,ActionTime)
		when DATEPART(WEEKDAY,ActionTime)= 3 then convert(date,DATEADD(DAY, -1, ActionTime))
		when DATEPART(WEEKDAY,ActionTime)= 4 then convert(date,DATEADD(DAY, -2, ActionTime))
		when DATEPART(WEEKDAY,ActionTime)= 5 then convert(date,DATEADD(DAY, -3, ActionTime))
		when DATEPART(WEEKDAY,ActionTime)= 6 then convert(date,DATEADD(DAY, -4, ActionTime))
		when DATEPART(WEEKDAY,ActionTime)= 7 then convert(date,DATEADD(DAY, -5, ActionTime))
	END AS Week
	, -DATEDIFF(day, ActionTime, GETDATE()) AS R1
	, -ceiling(convert(float, DATEDIFF(day, ActionTime, GETDATE())) / 7) AS R7
	, -ceiling(convert(float, DATEDIFF(day, ActionTime, GETDATE())) / 28) AS R28
	, -DATEDIFF(month, ActionTime, GETDATE()) AS M
FROM #final6
WHERE -ceiling(convert(float, DATEDIFF(day, ActionTime, GETDATE())) / 28) >= -12
 

DROP TABLE #timezone
DROP TABLE #called
DROP TABLE #interaction
DROP TABLE #final
DROP TABLE #final1
DROP TABLE #final2
DROP TABLE #final3
DROP TABLE #final4
DROP TABLE #final5
DROP TABLE #final6
DROP TABLE #alerter
DROP TABLE #alerter2
DROP TABLE #alerter3
DROP TABLE #widgets
DROP TABLE #widgets2
DROP TABLE #widgets3
DROP TABLE #unbookable
DROP TABLE #unbookable2
DROP TABLE #unbookable3
DROP TABLE #ops
DROP TABLE #photo
DROP TABLE #photo2
DROP TABLE #photo3
DROP TABLE #phonetree
DROP TABLE #gp
DROP TABLE #gp2
DROP TABLE #gp3
DROP TABLE #reminders
DROP TABLE #reminders2
DROP TABLE #reminders3
DROP TABLE #synca
DROP TABLE #syncb
DROP TABLE #visitreason
DROP TABLE #visitreason2
DROP TABLE #visitreason3
DROP TABLE #insurance
DROP TABLE #insurance2
DROP TABLE #insurance3
DROP TABLE #reviews
DROP TABLE #reviews2
DROP TABLE #reviews3
DROP TABLE #statement
DROP TABLE #statement2
DROP TABLE #statement3
DROP TABLE #followups
DROP TABLE #amazon
DROP TABLE #amazon2
DROP TABLE #ama

