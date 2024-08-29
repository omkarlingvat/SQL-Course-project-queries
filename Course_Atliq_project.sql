-- MONTH
-- PRODUCT NAME
-- VARIANT
-- SOLD QUANTITY
-- GROSS PRICE PER ITEM
-- GROSS PRICE TOTAL

SELECT * FROM dim_customer where customer = "croma"; -- 90002002

SELECT * FROM fact_sales_monthly where customer_code = 90002002 ;

#need to convert calendar year to fiscal year

select * from fact_sales_monthly 
where customer_code = 90002002 AND 
	  YEAR(DATE_ADD(DATE, INTERVAL 4 MONTH)) = 2021
ORDER BY DATE;      

-- BUILD A FISCAL YEAR FUNCTION

select * from fact_sales_monthly 
where customer_code = 90002002 AND 
	  FISCAL_YEAR(DATE) = 2021 AND
      FISCAL_QUARTER(DATE) = "Q1"
ORDER BY DATE;     

select  S.DATE, S.PRODUCT_CODE, P.PRODUCT, P.VARIANT,S.SOLD_QUANTITY,
		G.GROSS_PRICE, ROUND((GROSS_PRICE*SOLD_QUANTITY),2)
        AS GROSS_PRICE_TOTAL
from fact_sales_monthly S
JOIN DIM_PRODUCT P
ON S.product_code=P.product_code
JOIN fact_gross_price G 
ON P.product_code = G.product_code AND G.fiscal_year = FISCAL_YEAR(S.DATE)
where customer_code = 90002002 AND 
	  FISCAL_YEAR(DATE) = 2021
ORDER BY DATE ASC;


-- YEARLY REPORT FOR CROMA WIHT YEAR & TOTAL GROSS SALES

SELECT FISCAL_YEAR(S.DATE) AS YEAR, SUM(G.GROSS_PRICE*S.SOLD_QUANTITY) AS TOTAL_GROSS_PRICE  -- MAY NOT WORK BECAUSE OF FUNCTION FISCAL_YEAR
FROM fact_sales_monthly S
JOIN fact_gross_price G
ON S.PRODUCT_CODE = G.PRODUCT_CODE AND G.fiscal_year = FISCAL_YEAR(S.DATE)
WHERE CUSTOMER_CODE = 90002002
GROUP BY YEAR
ORDER BY YEAR ASC;


-- STORED PROCEDURE
SELECT C.MARKET,SUM(SOLD_QUANTITY) AS TOTAL_QTY
 FROM fact_sales_monthly S
JOIN dim_customer C
ON S.customer_code=C.customer_code
WHERE FISCAL_YEAR(S.DATE) = 2021 AND MARKET = "INDIA"
GROUP BY C.MARKET;

# VIEWS

select  S.DATE, S.PRODUCT_CODE, P.PRODUCT, P.VARIANT,S.SOLD_QUANTITY,
		G.GROSS_PRICE, ROUND((GROSS_PRICE*SOLD_QUANTITY),2) AS GROSS_PRICE_TOTAL,
        PRE.PRE_INVOICE_DISCOUNT_PCT
from fact_sales_monthly S
JOIN DIM_PRODUCT P
ON S.product_code=P.product_code
JOIN fact_gross_price G 
ON P.product_code = G.product_code AND G.fiscal_year = FISCAL_YEAR(S.DATE)
JOIN fact_pre_invoice_deductions PRE
ON PRE.customer_code = S.customer_code AND
   PRE.fiscal_year = FISCAL_YEAR(S.DATE)
WHERE FISCAL_YEAR(S.DATE) = 2021
LIMIT 1000000;

# ABOVE QUERY TAKE TIME TO RUN SO TO OPTIMIZE WE CREATE DIM_dATE TABLE AND CHNAGE IT AS FOLLOWS

select  S.DATE, S.PRODUCT_CODE, P.PRODUCT, P.VARIANT,S.SOLD_QUANTITY,
		G.GROSS_PRICE, ROUND((GROSS_PRICE*SOLD_QUANTITY),2) AS GROSS_PRICE_TOTAL,
        PRE.PRE_INVOICE_DISCOUNT_PCT
from fact_sales_monthly S

JOIN DIM_PRODUCT P
ON S.product_code=P.product_code

JOIN DIM_DATE DT
ON S.DATE = DT.CALENDAR_DATE

JOIN fact_gross_price G 
ON P.product_code = G.product_code AND G.fiscal_year = DT.FISCAL_YEAR

JOIN fact_pre_invoice_deductions PRE
ON PRE.customer_code = S.customer_code AND
   PRE.fiscal_year = DT.FISCAL_YEAR
   
WHERE FISCAL_YEAR(S.DATE) = 2021;

# WE CAN ALSO OPTIMIZE BY ADDING THE FISCAL_YEAR IN FACT_SALES TABLE RATHER THAN CREATING DIM_DATE

select  S.DATE, S.PRODUCT_CODE,S.SOLD_QUANTITY,
		G.GROSS_PRICE, ROUND((GROSS_PRICE*SOLD_QUANTITY),2) AS GROSS_PRICE_TOTAL,
        PRE.PRE_INVOICE_DISCOUNT_PCT
from fact_sales_monthly S

JOIN DIM_PRODUCT P
ON S.product_code=P.product_code

JOIN fact_gross_price G 
ON P.product_code = G.product_code AND G.fiscal_year = S.FISCAL_YEAR

JOIN fact_pre_invoice_deductions PRE
ON PRE.customer_code = S.customer_code AND
   PRE.fiscal_year = S.FISCAL_YEAR
   
WHERE FISCAL_YEAR(S.DATE) = 2021;

# WE CANNOT USE DERIVED FIELD IN SAME QUERY SO WE CAN EITHER USE SUBQEURY OR CTE,alter

#CTE METHOD
 WITH CTE1 AS (	select  S.DATE, S.PRODUCT_CODE,S.SOLD_QUANTITY,
				G.GROSS_PRICE, ROUND((GROSS_PRICE*SOLD_QUANTITY),2) AS GROSS_PRICE_TOTAL,
				PRE.PRE_INVOICE_DISCOUNT_PCT
				from fact_sales_monthly S

JOIN DIM_PRODUCT P
ON S.product_code=P.product_code


JOIN fact_gross_price G 
ON P.product_code = G.product_code AND G.fiscal_year = S.FISCAL_YEAR

JOIN fact_pre_invoice_deductions PRE
ON PRE.customer_code = S.customer_code AND
   PRE.fiscal_year = S.FISCAL_YEAR
   
WHERE FISCAL_YEAR(S.DATE) = 2021)

SELECT * , (GROSS_PRICE_TOTAL - GROSS_PRICE_TOTAL * PRE_INVOICE_DISCOUNT_PCT) AS NET_INVOICE_SALES
FROM CTE1;


# WE CAN USE VIEW 
   #REFER VIEW
   # QUERIES WERE CUT PASTE SO ...
   
SELECT *,
		(1-PRE_INVOICE_DISCOUNT_PCT)*GROSS_PRICE_TOTAL AS NET_INVOICE_SALES,
		(DISCOUNTS_PCT + OTHER_DEDUCTIONS_PCT) AS POST_INV_DIS_PCT
FROM SALES_PRE_INV_DIS PRE
JOIN fact_post_invoice_deductions PO
ON  PRE.CUSTOMER_CODE = PO.CUSTOMER_CODE AND 
	PRE.PRODUCT_CODE = PO.PRODUCT_CODE AND
    PRE.DATE = PO.DATE;

SELECT *, (1-POST_INV_DIS_PCT)*NET_INVOICE_SALES AS NET_SALES
FROM SALES_POST_INV_DIS;

#EXERCISE 

SELECT S.DATE, SUM(G.GROSS_PRICE*S.SOLD_QUANTITY) AS TOTAL_GROSS_PRICE  
FROM fact_sales_monthly S
JOIN fact_gross_price G
	ON S.PRODUCT_CODE = G.PRODUCT_CODE AND G.fiscal_year = FISCAL_YEAR(S.DATE)
WHERE find_in_set(S.CUSTOMER_CODE,IN_CUSTOMER_CODE)>0
GROUP BY S.DATE;

# USING CTE

WITH SUM_QTY AS (
				SELECT PRODUCT_CODE,FISCAL_YEAR,SUM(SOLD_QUANTITY) AS TOTAL_QTY
				FROM gdb0041.fact_sales_monthly
				GROUP BY product_code, FISCAL_YEAR
                )
                
SELECT GP.PRODUCT_CODE,GP.FISCAL_YEAR,GP.GROSS_PRICE,
		QT.TOTAL_QTY,
		(GROSS_PRICE/TOTAL_QTY) AS GROSS_PRICE_PER_ITEM,
        (GROSS_PRICE*TOTAL_QTY) AS TOTAL_GROSS_PRICE
FROM fact_gross_price GP
JOIN SUM_QTY QT
ON GP.PRODUCT_CODE = QT.PRODUCT_CODE AND
   GP.FISCAL_YEAR = QT.FISCAL_YEAR;   # SAVED AS VIEWS
   
# NOW THAT WE HAVE NET_SALES COLUMN WE CALCULATE GIVEN REQUIREMENT
# CREATE STORE PROCEDURE FOR THE SAME  TOP_N_MARKET

SELECT MARKET, ROUND(sum(NET_SALES)/1000000,2) AS NET_SALES_MILL
FROM NET_SALES
WHERE FISCAL_YEAR = 2021
GROUP BY MARKET
order by NET_SALES_MILL DESC
LIMIT 5;

#CREATE STORE PROCEDURE FOR CUSTOMER TOP N

SELECT C.CUSTOMER, ROUND(sum(NS.NET_SALES)/1000000,2) AS NET_SALES_MILL
FROM NET_SALES NS
JOIN dim_customer C
ON NS.customer_code = C.customer_code
WHERE NS.FISCAL_YEAR = 2021 AND NS.MARKET = "INDIA"
GROUP BY C.CUSTOMER
order by NET_SALES_MILL DESC
LIMIT 3;

# WINDOWS FUNCTION

WITH cte1 AS (
    SELECT 
        C.CUSTOMER, 
        ROUND(SUM(NS.NET_SALES) / 1000000, 2) AS NET_SALES_MILL
    FROM 
        NET_SALES NS
    JOIN 
        dim_customer C
    ON 
        NS.customer_code = C.customer_code
    WHERE 
        NS.FISCAL_YEAR = 2021
    GROUP BY 
        C.CUSTOMER
)

SELECT 
    * ,
    (NET_SALES_MILL * 100.0) / SUM(NET_SALES_MILL) OVER() AS PCT
FROM 
    cte1
ORDER BY 
    NET_SALES_MILL DESC;


WITH CTE1 AS (
				SELECT C.REGION,C.CUSTOMER, ROUND(SUM(NS.NET_SALES/1000000),2) AS NS_MILL
				FROM net_sales NS
				JOIN DIM_CUSTOMER C
				ON NS.CUSTOMER_CODE = C.CUSTOMER_CODE
				GROUP BY C.CUSTOMER, C.REGION 
                )
SELECT *,
		NS_MILL*100/SUM(NS_MILL) OVER(PARTITION BY REGION) AS PCT_SHARE -- DIVEDS MARKET SHARE BY REGION NOT THE WHOLE
        FROM CTE1
        ORDER BY REGION,NS_MILL DESC;
        
with cte1 as (
		select p.division,p.product, sum(sold_quantity) as total_qty
		from fact_sales_monthly s
		join dim_product p
			on p.product_code = s.product_code
		where fiscal_year = 2021
        group by p.product,p.division
			),
      cte2 as (      
			select * ,
					dense_rank() over(partition by division order by total_qty desc) as d_rank
			from cte1
            )
select * from cte2 where d_rank<= 3 ;         # created stored procedure

# TOP N MARKETS IN EVERY REGION BY THEIR GROSS SALES 

WITH CTE1 AS (
				SELECT GP.product_code,GP.FISCAL_YEAR,
					   SUM(SOLD_QUANTITY) AS TOTAL_QTY, GP.gross_price
				FROM gdb0041.fact_sales_monthly S
				JOIN fact_gross_price GP
				ON GP.product_code = S.product_code AND
					GP.fiscal_year = S.fiscal_year
				GROUP BY GP.product_code, GP.FISCAL_YEAR
			)
SELECT *,
		ROUND((TOTAL_QTY*GROSS_PRICE),2)/1000000 AS GROSS_SALES
FROM CTE1
ORDER BY GROSS_SALES DESC;

#VIEW FOR gross_sales
SELECT  s.date,
		s.fiscal_year,
		s.customer_code,
		c.customer,
		c.market,
        c.region,
		s.product_code,
		p.product, p.variant,
		s.sold_quantity,
        s.fiscal_year,
		g.gross_price as gross_price_per_item,
		round(s.sold_quantity*g.gross_price,2) as gross_price_total
FROM fact_sales_monthly s
join dim_customer c 
on s.customer_code = c.customer_code
join dim_product p
on p.product_code = s.product_code
join fact_gross_price g
on g.product_code = s.product_code and g.fiscal_year=s.fiscal_year;

	# exercise created view
 with cte1 as (   
    select market,region, fiscal_year,
			round(sum(gross_price_total)/1000000,2) as total_gross_price
			from gross_sales
            where fiscal_year = 2021
			group by market,region,fiscal_year
			),

		cte2 as ( select *,
				dense_rank() over(partition by region order by total_gross_price desc) as d_rank
		from cte1 )
        
select * from cte2 
where d_rank <= 2;



# SUPPLY CHAIN PROJECT

# we can use USING () when joining 2 tables with same columns

create table fact_act_est(
		select 
				f.date, f.fiscal_year, f.product_code, f.customer_code, s.sold_quantity,
				f.forecast_quantity
		from fact_sales_monthly s
		left join fact_forecast_monthly f
		using(date,customer_code,product_code)

		union

		select 
				f.date, f.fiscal_year, f.product_code, f.customer_code, s.sold_quantity,
				f.forecast_quantity
		from fact_sales_monthly s
		right join fact_forecast_monthly f
		using(date,customer_code,product_code)
);


# STUDY OR WATCH LECTURE FOR EVENTS, TRIGGERS ETC

# CTE vs temparory table 

# CTE vs SUBQUERY VS                    watch lecture