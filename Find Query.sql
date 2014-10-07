SELECT  t.name, c.name
FROM    sys.tables t
inner join sys.columns c
	on c.object_id = t.object_id
where (  c.name like '%PlanTypeID%' )