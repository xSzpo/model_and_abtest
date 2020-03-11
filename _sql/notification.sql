/*For all users that received a notification, what is the difference in average
transactions 7 days before the notification arrived vs. 7 days after the notification
arrived, by country and age group?*/

select
    count(user_id) as cnt_user
    ,count (distinct user_id) as cnt_dist_user
from users

/*check how often client recived notyfiaction -> 1.8*/
SELECT
    avg(avg_month_not) AS avg_month_not_all
FROM
    (SELECT user_id,
            cnt,
            months_diff,
            CASE
                WHEN months_diff>0 THEN (cnt/months_diff)
                ELSE cnt
                END AS avg_month_not
    FROM
        (SELECT user_id ,
                count(*) AS cnt,
                (DATE_PART('year', max(created_date) ::date) - DATE_PART('year', min(created_date)::date)) * 12 + (DATE_PART('month', max(created_date)::date) - DATE_PART('month', min(created_date)::date)) AS months_diff
        FROM notifications
        GROUP BY user_id) as sq1
    ) as sq2


/*For all users that received a notification*/

/*check how often client recived notyfiaction -> 1.8*/
/*48% recives 1 notyfication a month
24% recives 2 notyfication a month
10% recives 3 notyfiaction a month
5% recises 4 notyfication a month
4 % more then 4
6% 0 notyfiaciotns a month */
SELECT
    round(avg_month_not) as avg_month_not
    ,count(*) as cnt
FROM
    (SELECT user_id,
            cnt,
            months_diff,
            CASE
                WHEN months_diff>0 THEN (cnt/months_diff)
                ELSE cnt
                END AS avg_month_not
    FROM
        (SELECT user_id ,
                count(*) AS cnt,
                (DATE_PART('year', max(created_date) ::date) - DATE_PART('year', min(created_date)::date)) * 12 + (DATE_PART('month', max(created_date)::date) - DATE_PART('month', min(created_date)::date)) AS months_diff
        FROM notifications
        GROUP BY user_id) as sq1
    ) as sq2
group by round(avg_month_not)
order by cnt desc


select count(*) as cnt, count(distinct user_id) from users


/*transakcje sa zdublowane*/

select
    transactions_state, user_id, (date_part('month',created_date)+date_part('year',created_date)*12)
    ,count(*) as cnt
    ,count(distinct transaction_id) as dcnt
from transactions
where user_id = 'user_12657' and
(date_part('month',created_date)+date_part('year',created_date)*12) = 24232
group by transactions_state, user_id, (date_part('month',created_date)+date_part('year',created_date)*12)
order by cnt desc

select * from transactions
where user_id = 'user_12657' and
(date_part('month',created_date)+date_part('year',created_date)*12) = 24232
and transaction_id in (
select transaction_id from (
select transaction_id, count(*) as cnt
from transactions
where user_id = 'user_12657' and (date_part('month',created_date)+date_part('year',created_date)*12) = 24232
group by transaction_id
having count(*) > 1
) a )
order by transaction_id


/*dziala*/

select
n.user_id
,n.created_date as notif_date
,t.created_date as trans_date
,n.created_date-t.created_date as diff
,t.transactions_type
,t.amount_usd
,t.direction
,case when (t.created_date::date-n.created_date::date)<0 then 'przed' else 'po' end as diff
from (
        select *
        from notifications
        where status = 'SENT'
        limit 100) n
left join (select distinct * from transactions where transactions_state ='COMPLETED') t
    on n.user_id = t.user_id
    and (
            (n.created_date::date - t.created_date::date) <= 7
            and (t.created_date::date - n.created_date::date) <= 7
        )
left join users u on n.user_id = u.user_id
order by n.user_id




select
trans_occured
,direction
,country
,age_group
,count(*) as cnt
,avg(amount_usd) as avg
from
(
select distinct
n.user_id
,u.country
,case
    when u.birth_year <= 1946 then 'Older genration'
    when u.birth_year > 1946 and u.birth_year <= 1964 then 'Baby Boomers 1946-1964'
    when u.birth_year > 1964 and u.birth_year <= 1980 then 'Generation X 1965-1980'
    when u.birth_year > 1980 and u.birth_year <= 2000 then 'Generation Y 1980-2000'
    else 'Generaiton Z 2000-2012' end as age_group
,t.direction
,t.amount_usd
,case
    when t.created_date is null then 'none'
    when t.created_date-n.created_date <= '0 seconds'::INTERVAL then 'before'
    else 'after' end as trans_occured
from (
        select *
        from notifications
        where status = 'SENT'
        limit 100) n
left join (select distinct * from transactions where transactions_state ='COMPLETED') t
    on n.user_id = t.user_id
    and (
            n.created_date-t.created_date <= '7 days'::INTERVAL
            and t.created_date-n.created_date <= '7 days'::INTERVAL
        )
left join users u on n.user_id = u.user_id
order by n.user_id
) sq
group by
trans_occured
,direction
,country
,age_group




select
distinct user_id
,direction
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
    when u.birth_year <= 1946 then 'Older genration'
    when u.birth_year > 1946 and u.birth_year <= 1964 then 'Baby Boomers 1946-1964'
    when u.birth_year > 1964 and u.birth_year <= 1980 then 'Generation X 1965-1980'
    when u.birth_year > 1980 and u.birth_year <= 2000 then 'Generation Y 1980-2000'
    else 'Generaiton Z 2000-2012' end as age_group
,t.direction
,t.amount_usd
,case
    when t.created_date is null then 'none'
    when t.created_date-n.created_date <= '0 seconds'::INTERVAL then 'before'
    else 'after' end as trans_occured
from (
        select *
        from notifications
        where status = 'SENT'
        limit 100) n
left join (
            select distinct *
            from transactions
            where transactions_state ='COMPLETED'
            and direction='OUTBOUND') t
    on n.user_id = t.user_id
    and (
            n.created_date-t.created_date <= '7 days'::INTERVAL
            and t.created_date-n.created_date <= '7 days'::INTERVAL
        )
left join users u on n.user_id = u.user_id
order by n.user_id
) sq
group by
user_id
,direction
,country
,age_group



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
    when u.birth_year <= 1946 then 'Older genration'
    when u.birth_year > 1946 and u.birth_year <= 1964 then 'Baby Boomers 1946-1964'
    when u.birth_year > 1964 and u.birth_year <= 1980 then 'Generation X 1965-1980'
    when u.birth_year > 1980 and u.birth_year <= 2000 then 'Generation Y 1980-2000'
    else 'Generaiton Z 2000-2012' end as age_group
,t.direction
,t.amount_usd
,case
    when t.created_date is null then 'none'
    when t.created_date-n.created_date <= '0 seconds'::INTERVAL then 'before'
    else 'after' end as trans_occured
from (
        select *
        from notifications
        where status = 'SENT'
        ) n
left join (
            select distinct *
            from transactions
            where transactions_state ='COMPLETED'
            and direction='OUTBOUND') t
    on n.user_id = t.user_id
    and (
            n.created_date-t.created_date <= '7 days'::INTERVAL
            and t.created_date-n.created_date <= '7 days'::INTERVAL
        )
left join users u on n.user_id = u.user_id
order by n.user_id
) sq
group by
user_id
,country
,age_group
