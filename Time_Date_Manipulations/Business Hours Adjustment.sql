SELECT *,
CASE
	WHEN DATEPART (dw,Start) = 2 --Monday
		THEN
			CASE 
				WHEN DATEPART(hh, Start) <= 8
					THEN dateadd(hh, 9, dateadd(dd, 1, convert(datetime, CONVERT(date, Start))))
						WHEN DATEPART(hh, Start) >= 16
							THEN dateadd(hh, 9, dateadd(dd, 1, convert(datetime, CONVERT(date, Start))))
								ELSE Start END
							WHEN DATEPART (dw, Start) = 3
						THEN
					CASE 
				WHEN DATEPART(hh, Start)  <= 8
			THEN dateadd(hh, 9, convert(datetime, CONVERT(date, Start)))
		WHEN DATEPART(hh, Start) >= 16
	THEN dateadd(hh, 9, dateadd(dd, 1, convert(datetime, CONVERT(date, Start))))
		ELSE Start END
			WHEN DATEPART (dw,Start) = 4
				THEN
					CASE	
						WHEN DATEPART(hh, Start)  <= 8
							THEN dateadd(hh, 9, convert(datetime, CONVERT(date, Start)))
								WHEN DATEPART(hh, Start) >= 16
							THEN dateadd(hh, 9, dateadd(dd, 1, convert(datetime, CONVERT(date, Start))))
						ELSE Start END
					WHEN DATEPART (dw, Start ) = 5
				THEN
			CASE 
		WHEN DATEPART(hh, Start) <= 8
	THEN dateadd(hh, 9, convert(datetime, CONVERT(date, Start)))
		WHEN DATEPART(hh,Start) >= 16
			THEN dateadd(hh, 9, dateadd(dd, 1, convert(datetime, CONVERT(date, Start))))
				ELSE Start END
					WHEN DATEPART (dw, Start) = 6 AND DATEPART (hh, Start) <= 8
						THEN DATEADD (hh, 9, CONVERT(DATETIME, CONVERT(DATE,Start)))
							WHEN DATEPART (dw, Start) = 6 AND DATEPART (hh, Start) >= 16	
								THEN DATEADD(hh, 9, DATEADD(dd, 3, CONVERT(DATETIME, CONVERT(DATE, Start))))
							WHEN DATEPART (dw, Start) = 7
						THEN DATEADD(hh, 9, DATEADD(dd, 2, CONVERT(datetime, CONVERT(DATE, Start))))
					WHEN DATEPART (dw, Start) = 1
				THEN DATEADD(hh, 9, DATEADD(dd, 1, CONVERT(datetime, CONVERT(DATE, Start))))				
			ELSE Start
		END AS 'Action'
