--DATE SLAs

-- 1 BUSINESS DAY DUEDATE NO WEEKENDS

		CASE
			  WHEN (ScheduledFor IS NOT NULL)
					THEN
					CASE
						  WHEN datename (dw, ScheduledFor) = 'Friday'
								THEN
								dateadd(dd, 3, ScheduledFor)
						  WHEN datename (dw, ScheduledFor) = 'Saturday'
								THEN
								cast(convert(CHAR(8), convert(SMALLDATETIME, dateadd(dd, 3, ScheduledFor)), 112) AS DATETIME)
						  WHEN datename (dw, ScheduledFor) = 'Sunday'
								THEN
								cast(convert(CHAR(8), convert(SMALLDATETIME, dateadd(dd, 2, ScheduledFor)), 112) AS DATETIME)
						  ELSE
								dateadd(dd, 1, ScheduledFor)
					END
			  ELSE
					NULL
		END AS DueDate



-- 2 BUSINESS DAY DUEDATE NO WEEKENDS

		CASE
			  WHEN (UploadedOn IS NOT NULL)
					THEN
					CASE
					WHEN datename (dw, UploadedOn) = 'Thursday'
								THEN
								dateadd(dd, 4, UploadedOn)
					
						  WHEN datename (dw, UploadedOn) = 'Friday'
								THEN
								dateadd(dd, 4, UploadedOn)

						  WHEN datename (dw, UploadedOn) = 'Saturday'
								THEN
								cast(convert(CHAR(8), convert(SMALLDATETIME, dateadd(dd, 4, UploadedOn)), 112) AS DATETIME)
						  WHEN datename (dw, UploadedOn) = 'Sunday'
								THEN
								cast(convert(CHAR(8), convert(SMALLDATETIME, dateadd(dd, 3, UploadedOn)), 112) AS DATETIME)
						  ELSE
								dateadd(dd, 2, UploadedOn)
					END
			  ELSE
					NULL
		END AS DueDate


-- 3 BUSINESS DAY DUEDATE NO WEEKENDS


	CASE
		WHEN datename (dw, ScheduledFor) = 'Wednesday'
			THEN
			dateadd(dd, 5, ScheduledFor)
		
		WHEN datename (dw, ScheduledFor) = 'Thursday'
			THEN
			dateadd(dd, 5, ScheduledFor)
		WHEN datename (dw, ScheduledFor) = 'Friday'
			THEN
			dateadd(dd, 5, ScheduledFor)
		WHEN datename (dw, ScheduledFor) = 'Saturday'
			THEN
			cast(convert(CHAR(8), convert(SMALLDATETIME, dateadd(dd, 5, ScheduledFor)), 112) AS DATETIME)
		WHEN datename (dw, ScheduledFor) = 'Sunday'
			THEN
			cast(convert(CHAR(8), convert(SMALLDATETIME, dateadd(dd, 4, ScheduledFor)), 112) AS DATETIME)
		ELSE
			dateadd(dd, 3, ScheduledFor)
	END AS DueDate