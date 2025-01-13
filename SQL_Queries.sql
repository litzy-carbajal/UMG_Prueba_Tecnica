---------------------------------------------------------------------------------------------------------------------------------
--QUERY 01: TOTAL SESSIONS BY BROWSER
---------------------------------------------------------------------------------------------------------------------------------
SELECT
  browser,
  COUNT (session_id) AS total_session
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE sequence_number = 1 AND created_at BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' )
GROUP BY 1
ORDER BY total_session DESC


---------------------------------------------------------------------------------------------------------------------------------
--QUERY 02: BOUNCE RATE BY VISITOR TYPE (single page sesiones/total de # de sesiones)
---------------------------------------------------------------------------------------------------------------------------------
-- Query sessions that begin within the time frame by visitor type
WITH a AS
( SELECT session_id,
  CASE WHEN user_id IS NULL THEN 'guest' ELSE 'member' END AS visitor_type,
  CASE WHEN MAX(sequence_number)= 1 THEN 'Yes' ELSE 'No' END AS is_bounce  

FROM `bigquery-public-data.thelook_ecommerce.events`
GROUP BY 1,2
HAVING MIN(created_at) BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' ))

-- Query total session, bounce rate by visitor type per month
SELECT
  visitor_type,
  COUNT(session_id) AS total_session,
  SUM(CASE WHEN is_bounce = 'Yes' THEN 1 ELSE 0 END) AS bounce_session,
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN is_bounce = 'Yes' THEN 1 ELSE 0 END), COUNT(session_id))
    ,4) AS bounce_rate
FROM a
GROUP BY 1

---------------------------------------------------------------------------------------------------------------------------------
--QUERY 03: EVENT TYPE OF BOUNCE SESSIONS
---------------------------------------------------------------------------------------------------------------------------------
-- Query all bounce sessions occurring within a time frame
WITH a AS
( SELECT session_id,
FROM `bigquery-public-data.thelook_ecommerce.events`
GROUP BY 1
HAVING MAX(sequence_number) = 1 AND MIN (created_at) BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' ))

-- Query event type of bounce session
SELECT
  event_type,
  COUNT(session_id) AS total_bounce_session,
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE session_id IN (SELECT session_id FROM a)
GROUP BY 1 
ORDER BY 2 DESC


---------------------------------------------------------------------------------------------------------------------------------
--QUERY 04: TOTAL SESSIONS, PURCHASE SESSIONS AND CONVERSION RATE BY TRAFFIC SOURCE
---------------------------------------------------------------------------------------------------------------------------------
-- Query total sessions by traffic source, based on begin time
WITH a AS
( SELECT
  traffic_source,
  COUNT(session_id) AS total_session
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE sequence_number =1 AND created_at BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' )
GROUP BY 1),

-- Query purchase sessions in the time frame, based on session begin time
b AS 
(SELECT
  traffic_source,
  COUNT(session_id) AS purchase_session,
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE event_type= 'purchase' AND session_id IN
  (SELECT session_id 
  FROM `bigquery-public-data.thelook_ecommerce.events` 
  GROUP BY 1
  HAVING MIN (created_at) BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' ))
GROUP BY 1)

-- Query total sessions, total purchase session and conversion rate by traffic source

SELECT
  a.traffic_source,
  a.total_session,
  b.purchase_session,
  ROUND(SAFE_DIVIDE(b.purchase_session, a.total_session), 4) AS conversion_rate
FROM a JOIN b ON a.traffic_source = b.traffic_source
ORDER BY 2 DESC

---------------------------------------------------------------------------------------------------------------------------------
--QUERY 05:  NUMBER OF PRODUCTS ADDED INTO CART IN SESSIONS THAT HAVE ADD INTO CART EVENT
---------------------------------------------------------------------------------------------------------------------------------

WITH a AS
( SELECT
  session_id,
  COUNT(session_id) AS items_in_cart
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE event_type = 'cart'
GROUP BY 1
HAVING MIN (created_at) BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' ))


SELECT
  items_in_cart,
  COUNT(session_id) AS session_num
FROM a
GROUP BY 1
ORDER BY 1

---------------------------------------------------------------------------------------------------------------------------------
--QUERY 06:  TOTAL PURCHASES PER USER THAT MADE (A) PURCHASE(S)
---------------------------------------------------------------------------------------------------------------------------------

--Query all sessions that occur within the time frame, based on session begin time
WITH a AS
(SELECT 
  session_id
FROM `bigquery-public-data.thelook_ecommerce.events`
GROUP BY 1
HAVING MIN(created_at) BETWEEN PARSE_TIMESTAMP('%Y-%m-%d','2024-01-01') AND PARSE_TIMESTAMP('%Y-%m-%d', '2025-01-01' )),

--Query the total purchase(s) per user who made (a) purchase(s)
b AS
(SELECT 
  user_id, 
  COUNT(session_id) AS total_purchase
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE session_id IN (SELECT session_id FROM a) AND event_type = 'purchase'
GROUP BY 1)

--Query the number of users by total purchase times
SELECT 
  total_purchase, 
  COUNT(user_id) AS user_num
FROM b 
GROUP BY 1
ORDER BY 1
