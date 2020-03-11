
/*###############################################
Task description
-----------------------------------------------
For all users that received a notification, what is the difference in average
transactions 7 days before the notification arrived vs. 7 days after the notification
arrived, by country and age group?*/


/*###############################################
assumptions and notes
-----------------------------------------------
* I'm using only notifications that have been sent
* transactions are duplicated - need distinct
* I'm using only completed transactions
* I'm using only outbound transactions to show average transactions
* Countries that have less then 50K transacions in analysing periods are grouped into 'other'
* If country x age group has less then 2 trnasacrions (2 before and 2 after notification), then is removed from graph
*/

/*
sum_cnt_before - total number of transacions, up to 7 days before the notification
sum_cnt_after - total number of transacions of transacions, up to 7 days after the notification
sum_usd_before - total sum of transacion amount in USD, up to 7 days before the notification
sum_usd_after - total sum of transacion amount in USD, up to 7 days after the notification
avg_cnt_before - average number of transacions per client, up to 7 days before the notification
avg_cnt_after - average number of transacions per client, up to 7 days after the notification
avg_cnt_diff - difference in average transactions 7 days before the notification arrived vs. 7 days after the notification
avg_sum_usd_before - average sum of transacions amount in USD per client, up to 7 days before the notification
avg_sum_usd_after - average sum of transacions amount in USD per client, up to 7 days after the notification
avg_sum_usd_diff - difference in average total amount of transactions 7 days before the notification arrived vs. 7 days after the notification
avg_usd_before - average transacion value before the notification
avg_usd_after - average transacion value after the notification
avg_usd_diff - difference in average transacion value
*/

select
case
    when country in ('IE','ES','CH','MT','GB','CZ','LT','PL','PT','FR','RO') then country
    else 'others' end as country
,age_group
,sum(cnt_before) as sum_cnt_before
,sum(cnt_after) as sum_cnt_after
,sum(sum_usd_before) as sum_usd_before
,sum(sum_usd_after) as sum_usd_after
,avg(cnt_before) as avg_cnt_before
,avg(cnt_after) as avg_cnt_after
,avg(cnt_after)-avg(cnt_before)  as avg_cnt_diff
,avg(sum_usd_before) as avg_sum_usd_before
,avg(sum_usd_after) as avg_sum_usd_after
,avg(sum_usd_after)-avg(sum_usd_before) as avg_sum_usd_diff
,avg(sum_usd_before)/avg(cnt_before) as avg_usd_before
,avg(sum_usd_after)/avg(cnt_after) as avg_usd_after
,avg(sum_usd_after)/avg(cnt_after) - avg(sum_usd_before)/avg(cnt_before) as avg_usd_diff
from
    (
    select
    distinct user_id
    ,country
    ,age_group
    ,sum(case when trans_occured = 'before' then 1 else 0 end) as cnt_before
    ,sum(case when trans_occured = 'after' then 1 else 0 end) as cnt_after
    ,sum(case when trans_occured = 'before' then amount_usd else null end) as sum_usd_before
    ,sum(case when trans_occured = 'after' then amount_usd else null end) as sum_usd_after
    from
        (
        select
        n.user_id
        ,u.country
        ,case
            when u.birth_year <= 1946 then '1. Oldest genration'
            when u.birth_year > 1946 and u.birth_year <= 1964 then '2. Baby Boomers 1946-1964'
            when u.birth_year > 1964 and u.birth_year <= 1980 then '3. Generation X 1965-1980'
            when u.birth_year > 1980 and u.birth_year <= 2000 then '4. Generation Y 1980-2000'
            else 'Generaiton Z 2000-2012' end as age_group
        ,t.direction
        ,t.amount_usd
        ,case
            when t.created_date is null then 'none'
            when t.created_date-n.created_date <= '0 seconds'::INTERVAL then 'before'
            else 'after' end as trans_occured
        from (select * from notifications where status = 'SENT') n
        left join (select distinct * from transactions where transactions_state ='COMPLETED' and direction='OUTBOUND') t
            on n.user_id = t.user_id
               and (n.created_date-t.created_date <= '7 days'::INTERVAL
               and t.created_date-n.created_date <= '7 days'::INTERVAL)
        left join users u on n.user_id = u.user_id
        order by n.user_id
        ) s1
    group by
    user_id
    ,country
    ,age_group
    ) s2
group by
case
    when country in ('IE','ES','CH','MT','GB','CZ','LT','PL','PT','FR','RO') then country
    else 'others' end
,age_group
having sum(cnt_after)>2 and sum(cnt_before) > 2
order by age_group, country