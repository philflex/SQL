--R1, R7, R28, Month and DueWeek calculations from an 'ActionTime'

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
