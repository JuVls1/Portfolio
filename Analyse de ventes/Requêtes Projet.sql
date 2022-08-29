create product(
	ID varchar primary key, 
	Category varchar, 
	SubCategory varchar, 
	Name varchar
);

create table orders(
	OrderID int primary key,
	OrderDate date,
	ShipDate date,
	ShipMode varchar,
	ShipCost float,
	CustomerName varchar,
	Segment varchar,
	City varchar,
	State varchar,
	Country varchar,
	Region varchar,
	ProductID varchar references product (ID),
	Quantity float,
	Discount float,
	Sales float,
	Profit float,
	OrderPriority varchar,
	Returned varchar
);

copy product from 'C:\Products.csv' delimiter ',' csv header;

copy orders from 'C:\Orders.csv' delimiter ',' csv header;

select * from orders limit 10;
select * from product limit 10;

select * from information_schema.columns where table_name = 'orders';
select * from information_schema.columns where table_name = 'product';

-- 1. Comment se caractérise l'évolution des ventes et des bénéfices au fil des ans ?
select extract(year from orderdate) as orderyear, 
sum(quantity) as totalquantity, 
round(sum(profit)) as totalprofit 
from orders group by orderyear order by orderyear desc;

-- 2. Quelles régions affichent les meilleures ventes ? 
select region, 
round(sum(sales)) as totalsales, 
round(sum(profit)) as totalprofit 
from orders group by region order by totalprofit desc limit 5;

-- 3. Quels pays apportent le meilleur profit à l’entreprise ? 
select country, 
round(sum(sales)) as totalsales, 
round(sum(profit)) as totalprofit 
from orders group by country order by totalprofit desc limit 10;

-- 4. Quels pays ont un profit négatif sur les 4 années (2012-2015), en 2015?
select country, totalquantity, totalprofit from
(select country, sum(quantity) as totalquantity, round(sum(profit)) as totalprofit 
from orders group by country) as subquery where totalprofit<0 order by totalprofit asc;

select country, totalquantity, totalprofit from
(select country, sum(quantity) as totalquantity, round(sum(profit)) as totalprofit 
from orders where (select extract(year from orderdate)=2015) group by country) as subquery 
where totalprofit<0 order by totalprofit asc;

-- 5. Quelle est la contribution de la Chine quant au profit engendré dans la région Eastern Asia? 
with profitchine as
	(select region, sum(profit) as profitchine from orders where country = 'China' group by region),
totalprofit as 
	(select distinct region, sum(profit) over (partition by region) as totalprofit from orders where region='Eastern Asia')
select profitchine/totalprofit as partchine from profitchine inner join totalprofit on profitchine.region=totalprofit.region;

-- 6. Quelle catégorie de produits rapporte le plus d’argent selon les segments ? Quel produit plus spécifiquement ? 
with CTE as 
	(select segment, category, round(sum(profit)) as totalprofit, 
	 rank() over(partition by segment order by round(sum(profit)) desc) as rank 
     from orders o inner join product p on p.id = o.productid group by segment, category)
select segment, category, totalprofit from CTE where rank = 1

with CTE as 
	(select segment, name, round(sum(profit)) as totalprofit, 
	 rank() over(partition by segment order by round(sum(profit)) desc) as rank 
  	 from orders o inner join product p on p.id = o.productid group by segment, name)
select segment, name, totalprofit from CTE where rank = 1

-- 7. Quel produit enregistre plus de 300 ventes ?
select name, category, round(sum(quantity)) as quantitysold 
from product p inner join orders o on p.id = o.productid 
group by name, category having sum(quantity) > 300 order by quantitysold desc;

-- 8. Quel produit rapporte le plus d'argent ?
select name, round(sum(profit)) as totalprofit from orders o inner join product p on p.id = o.productid group by name order by totalprofit desc limit 1;

-- 9. Quelle est l'option d'expédition la plus populaire et le délai moyen entre la commande et l'expédition pour chacune de ces options ?
select shipmode, count(*) as numberoforders, round(avg(shipdate-orderdate),2) as meandelay from orders group by shipmode order by numberoforders desc;

-- 10. Quel est le produit le plus vendu par région du monde ? par région de France ?
with CTE as 
	(select region, name, sum(quantity) as totalquantity,
     rank() over(partition by region order by sum(quantity) desc) as rank 
  	 from orders o inner join product p on p.id = o.productid group by region, name)
select region, name, totalquantity from CTE where rank = 1;

with CTE as 
	(select state, name, sum(quantity) as totalquantity,
     rank() over(partition by state order by sum(quantity) desc) as rank 
  	 from orders o inner join product p on p.id = o.productid where country='France' group by state, name)
select state, name, totalquantity from CTE where rank = 1;

-- 11. Quels sont les produits les plus retournés ? On considère les produits commandés au moins 5 fois et dont plus du tiers a été retourné.

with totalorders as 
	(select name, cast(count(*) as float) as ordered from orders o inner join product p on p.id = o.productid group by name),
ordersreturned as 
	(select name, count(*) as returned from orders o inner join product p on p.id = o.productid where returned='Yes' group by name)
select totalorders.name, ordered,returned, returned/ordered as ratio from totalorders 
inner join ordersreturned on totalorders.name=ordersreturned.name where ordered >= 5 
and returned/ordered > 1.0/3 group by totalorders.name, ordered, returned, ratio order by ratio desc;
	
	
-- 12. Quels sont les différents produits de la marque CANON vendus par l'entreprise ?
select distinct(name) from product where lower(name) LIKE '%canon%';




