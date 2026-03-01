
-- QUERY 1: Average price by seat section
-- Shows which seats are most expensive
SELECT 
	seat_section,
	COUNT(*) as total_tickets,
	ROUND(AVG(ticket_price::int),2) AS avg_price,
	ROUND(MIN(ticket_price::int),2) AS min_price,
	ROUND(MAX(ticket_price::int),2) AS max_price,
	ROUND(SUM(revenue::int),2) AS total_revenue
FROM ticket
GROUP BY seat_section
ORDER BY avg_price DESC;


-- QUERY 2: Price changes based on urgency
-- How prices change as event approaches
SELECT 
	CASE 
		WHEN days_until_event <= 7 THEN 'Last Week'
	    WHEN days_until_event <= 30 THEN '1-4 Weeks'
		WHEN days_until_event <= 60 THEN '1-2 Months'
		ELSE 'More than 2 Months'
	END AS time_window,
	COUNT(*) as ticket_sold,
	ROUND(AVG(ticket_price::int),2) AS avg_price,
	ROUND(SUM(revenue::int),2) AS total_revenue
FROM ticket
GROUP BY time_window
ORDER BY avg_price DESC;


-- QUERY 3: Our prices vs competitors
-- Are we cheaper or more expensive?
WITH our_price AS (
SELECT 
	seat_section,
	ROUND(AVG(ticket_price::int),2) AS our_avg_price
FROM ticket
GROUP BY seat_section
),
competitor_price AS (
SELECT 
	seat_section,
	ROUND(AVG(competitor_price::int),2) AS competitor_avg_price
FROM competitor
GROUP BY seat_section
)
SELECT 
	o.seat_section,
	o.our_avg_price,
	c.competitor_avg_price,
	ROUND(AVG(o.our_avg_price::int - c.competitor_avg_price),2) AS price_diff,
	CASE 
		WHEN o.our_avg_price < c.competitor_avg_price THEN 'we are cheaper'
		WHEN o.our_avg_price > c.competitor_avg_price THEN 'we are more expensive'
		ELSE 'same price'
	END AS pricing_seg
FROM our_price AS o
LEFT JOIN competitor_price AS c
	ON o.event_id = c.event_id
ORDER BY o.our_avg_price DESC;


-- QUERY 4: Weekend vs weekday pricing
-- Do weekend events cost more?
SELECT 
	CASE WHEN is_weekend::numeric = 1 THEN 'Weekend'
	     ELSE 'Weekday'
	END AS day_type,
	COUNT(*) as total_tickets,
	ROUND(AVG(ticket_price::numeric),2) AS avg_price,
	ROUND(SUM(revenue::numeric),2) AS total_revenue
FROM ticket
GROUP BY is_weekend
ORDER BY avg_price DESC;


-- QUERY 5: Revenue by event type
-- Which event types make most money?
SELECT 
	event_type,
	COUNT(DISTINCT event_id) AS num_events,
	SUM(quantity_sold) as total_tickets_sold,
	ROUND(AVG(ticket_price::numeric),2) AS avg_price,
	ROUND(SUM(revenue::numeric),2) AS total_revenue
FROM ticket
GROUP BY event_type
ORDER BY total_revenue DESC;



-- QUERY 6: Sales by day of week
-- When do people buy tickets?
SELECT 
	CASE EXTRACT(DOW FROM sale_date::date)
		WHEN 0 THEN 'Sunday'
		WHEN 1 THEN 'Monday'
		WHEN 2 THEN 'Tuesday'
		WHEN 3 THEN 'Wednesday'
		WHEN 4 THEN 'Thursday'
		WHEN 5 THEN 'Friday'
		WHEN 6 THEN 'Saturday'
	END AS day_name,
	COUNT(*) as transactions,
	SUM(quantity_sold) AS tickets_sold,
	ROUND(AVG(ticket_price)::numeric,2) AS avg_price
FROM ticket
GROUP BY EXTRACT(DOW FROM sale_date::date)
ORDER BY tickets_sold DESC;


-- QUERY 7: Monthly revenue trend
-- How is business growing?
SELECT 
	TO_CHAR(event_date::date,'YYYY-MM') AS month,
	COUNT(DISTINCT event_id) AS num_events,
	SUM(quantity_sold) AS tickets_sold,
	ROUND(SUM(revenue::numeric),2) AS total_revenue,
	ROUND(AVG(ticket_price::numeric),2) AS avg_price
FROM ticket
GROUP BY month
ORDER BY total_revenue DESC;



-- QUERY 8: Weather impact on sales
-- Do people buy less on rainy days?
SELECT 
	CASE 
		WHEN w.rain = 1 THEN 'Rainy'
		ELSE 'Clear'
	END AS weather,
	COUNT(t.ticket_id) AS transactions,
	SUM(t.quantity_sold) AS tickets_sold,
	ROUND(AVG(t.ticket_price)::numeric,2) AS avg_price,
	ROUND(SUM(t.revenue)::numeric,2) AS total_revenue
FROM ticket AS t
JOIN weather AS w
	ON DATE(t.event_date) = DATE(w.date)
GROUP BY weather
ORDER BY total_revenue DESC;



-- QUERY 9: Temperature impact
-- Price differences by temperature
SELECT 
    CASE 
        WHEN w.temperature < 50 THEN 'Cold (<50°F)'
        WHEN w.temperature < 75 THEN 'Pleasant (50-75°F)'
        ELSE 'Hot (>75°F)'
    END as temp_range,
    COUNT(t.ticket_id) AS transactions,
    ROUND(AVG(t.ticket_price::numeric), 2) AS avg_price,
    SUM(t.quantity_sold) AS tickets_sold
FROM ticket AS t
JOIN weather AS w 
    ON DATE(t.event_date) = DATE(w.date) 
GROUP BY temp_range
ORDER BY tickets_sold DESC;



-- QUERY 10: Social media buzz impact
-- Do viral events sell for more?
SELECT 
	CASE 
		WHEN s.mentions < 1500 THEN 'Low Buzz'
		WHEN s.mentions < 3000 THEN 'Medium Buzz'
		ELSE 'High Buzz'
	END AS buzz_level,
	COUNT(DISTINCT t.event_id) AS num_events,
	ROUND(AVG(ticket_price::numeric),2) AS avg_price,
	SUM(t.quantity_sold) AS tickets_sold,
	ROUND(SUM(t.revenue::numeric),2) AS total_revenue
FROM ticket AS t
JOIN social AS s 
	ON t.event_id = s.event_id
GROUP BY buzz_level
ORDER BY total_revenue DESC;



-- QUERY 11: Top 10 revenue-generating events
-- Which events made the most money?
SELECT 
	event_name,
	event_type,
	city,
	SUM(quantity_sold) AS tickets_sold,
	ROUND(AVG(ticket_price::numeric),2) AS avg_price,
	ROUND(SUM(revenue::numeric),2) AS total_revenue
FROM ticket
GROUP BY event_name , event_type,city
ORDER BY total_revenue DESC
LIMIT 10;



-- QUERY 12: City performance comparison
-- Which cities are most profitable?
SELECT 
    city,
    COUNT(DISTINCT event_id) as num_events,
    SUM(quantity_sold) as total_tickets,
    ROUND(AVG(ticket_price::numeric), 2) as avg_price,
    ROUND(SUM(revenue::numeric), 2) as total_revenue
FROM ticket
GROUP BY city
ORDER BY total_revenue DESC;




-- QUERY 13: Best performing combinations
-- Event type + seat section winners
SELECT 
    event_type,
    seat_section,
    COUNT(*) AS transactions,
    ROUND(AVG(ticket_price::numeric), 2) AS avg_price,
    ROUND(SUM(revenue::numeric), 2) AS total_revenue
FROM ticket
GROUP BY event_type, seat_section
HAVING COUNT(*) > 20 
ORDER BY total_revenue DESC
LIMIT 10;



-- QUERY 14: Early bird vs last minute buyers
-- Who spends more?
SELECT 
    CASE 
        WHEN days_until_event > 30 THEN 'Early Bird (30+ days)'
        WHEN days_until_event > 7 THEN 'Regular (8-30 days)'
        ELSE 'Last Minute (0-7 days)'
    END AS buyer_type,
    COUNT(*) AS transactions,
    SUM(quantity_sold) AS tickets_sold,
    ROUND(AVG(ticket_price::numeric), 2) AS avg_price,
    ROUND(SUM(revenue::numeric), 2) AS total_revenue,
    ROUND(SUM(revenue::numeric) * 100.0 / SUM(SUM(revenue::numeric)) OVER (), 1) AS revenue_percentage
FROM ticket
GROUP BY buyer_type
ORDER BY avg_price DESC;



