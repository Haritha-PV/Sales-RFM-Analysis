--SALES RFM ANALYSIS

--Inspecting Data
select * from [dbo].[sales_data_sample]

--Checking unique values
select distinct STATUS from [dbo].[sales_data_sample]
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]
select distinct COUNTRY from [dbo].[sales_data_sample]
select distinct DEALSIZE from [dbo].[sales_data_sample]

--ANALYSIS
--Grouping sales by productline
select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

--Grouping sales by yearid
select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

--Grouping sales by dealsize
select DEALSIZE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc


--Best month of sales in specific year and respective revenue
select  MONTH_ID,sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [sales RFM analysis].[dbo].[sales_data_sample]
where YEAR_ID = 2003
group by  MONTH_ID
order by 2 desc
--november is the best month having sales in the year 2003

select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [sales RFM analysis].[dbo].[sales_data_sample]
where YEAR_ID = 2004
group by  MONTH_ID
order by 2 desc
--november is the best month having sales in the year 2004


select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [sales RFM analysis].[dbo].[sales_data_sample]
where YEAR_ID = 2005
group by  MONTH_ID
order by 2 desc
--may is the best month having sales in the year 2005


--Most selling productline in the bestmonth
select  MONTH_ID, PRODUCTLINE,sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [sales RFM analysis].[dbo].[sales_data_sample]
where YEAR_ID = 2003 and MONTH_ID=11
group by  MONTH_ID, PRODUCTLINE
order by 3 desc
--best selling product in the month of november is classic cars

-------Introducing RFM
--An RFM is segmenting customers using three key matrics:
  --Recency:How long ago their last purchase was(last order date)
  --Frequency:How often they purchase(count of total order)
  --Monetary value:How much they spend(total spend)

--who is the best customer(using RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
   select 
	  CUSTOMERNAME, 
	  sum(sales) MonetaryValue,
	  avg(sales) AvgMonetaryValue,
	  count(ORDERNUMBER) Frequency,
	  max(ORDERDATE) last_order_date,

		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [sales RFM analysis].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


--Most often sold products
select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [sales RFM analysis].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc
