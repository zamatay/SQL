with cte as (
select id, parent_id, 0 direct from StateGroups where del = 0 and id = 763
union all
select sg.id, sg.parent_id , direct + 1
	from StateGroups sg
	join cte c on c.parent_id = sg.id and (direct>=0)
union all
select sg.id, sg.parent_id, direct -1
	from StateGroups sg
	join cte c on c.id = sg.parent_id and (direct<=0)
)
select * from cte order by direct