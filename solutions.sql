CREATE TABLE transactions (
    buyer_id NUMBER,
    purchase_time TIMESTAMP,
    refund_time TIMESTAMP,    
    refund_item VARCHAR2(10),
    store_id VARCHAR2(10),
    item_id VARCHAR2(10),
    gross_transaction_value NUMBER
);

-- assuming table exists before dropping
drop table  transactions;

CREATE TABLE items (
    store_id      VARCHAR2(20),
    item_id       VARCHAR2(20),
    item_category VARCHAR2(50),
    item_name     VARCHAR2(100),
    PRIMARY KEY (store_id, item_id)
);

-- sample items data
INSERT INTO items VALUES ('a', 'a1', 'pants', 'denim pants');
INSERT INTO items VALUES ('a', 'a2', 'tops', 'blouse');
INSERT INTO items VALUES ('f', 'f1', 'table', 'coffee table');
INSERT INTO items VALUES ('f', 'f5', 'chair', 'lounge chair');
INSERT INTO items VALUES ('f', 'f6', 'chair', 'armchair');
INSERT INTO items VALUES ('d', 'd2', 'jewelry', 'bracelet');
INSERT INTO items VALUES ('b', 'b4', 'earphone', 'airpods');

SELECT * FROM transactions;
SELECT * FROM items;

-- inserting transaction data (purchase_time & refund_time are already TIMESTAMP)
INSERT INTO transactions VALUES (3, TIMESTAMP '2019-09-19 21:19:06.544', NULL, NULL, 'a', 'a1', 58);
INSERT INTO transactions VALUES (12, TIMESTAMP '2019-12-10 20:10:14.324', TIMESTAMP '2019-12-15 23:19:06.544', 'b2', 'b', 'b2', 475);
INSERT INTO transactions VALUES (3, TIMESTAMP '2020-09-01 23:59:46.561', TIMESTAMP '2020-09-02 21:22:06.331', 'f9', 'f', 'f9', 33);
INSERT INTO transactions VALUES (2, TIMESTAMP '2020-04-30 21:19:06.544', NULL, NULL, 'd', 'd3', 250);
INSERT INTO transactions VALUES (1, TIMESTAMP '2020-10-22 22:20:06.531', NULL, NULL, 'f', 'f2', 91);
INSERT INTO transactions VALUES (8, TIMESTAMP '2020-04-16 21:10:22.214', NULL, NULL, 'e', 'e7', 24);
INSERT INTO transactions VALUES (5, TIMESTAMP '2019-09-23 12:09:35.542', TIMESTAMP '2019-09-27 02:55:02.114', 'g6', 'g', 'g6', 61);

SELECT * FROM transactions;

-------------------------------------------------------------
-- 1) PURCHASE COUNT PER MONTH (EXCLUDING REFUNDED)
-- Assumption: A refunded purchase is any row where refund_time IS NOT NULL.
-------------------------------------------------------------
SELECT TO_CHAR(purchase_time, 'YYYY-MM') AS month,
       COUNT(*) AS purchase_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY TO_CHAR(purchase_time, 'YYYY-MM')
ORDER BY month;

-------------------------------------------------------------
-- 2) COUNT STORES WITH >=5 ORDERS IN OCT 2020
-- Assumption: Only purchase_time is used to identify the month.
-------------------------------------------------------------
SELECT COUNT(*)
FROM (
    SELECT store_id, COUNT(*) AS cnt
    FROM transactions
    WHERE TO_CHAR(purchase_time, 'YYYY-MM') = '2020-10'
    GROUP BY store_id
    HAVING COUNT(*) >= 5
);

-------------------------------------------------------------
-- 3) SHORTEST INTERVAL FROM PURCHASE TO REFUND
-- Assumption: TIMESTAMP subtraction returns days → multiplied to minutes.
-------------------------------------------------------------
SELECT store_id,
       MIN( (refund_time - purchase_time) * 24 * 60 ) AS shortest_minutes
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;

-------------------------------------------------------------
-- 4) FIRST ORDER VALUE PER STORE
-- Assumption: Earliest purchase_time = first order.
-------------------------------------------------------------
SELECT store_id, gross_transaction_value
FROM (
    SELECT store_id, gross_transaction_value,
           ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time) AS rn
    FROM transactions
)
WHERE rn = 1;

-------------------------------------------------------------
-- 5) MOST POPULAR ITEM ON BUYER'S FIRST PURCHASE
-- Assumption: Refunded transactions do not count as first purchases.
-------------------------------------------------------------
WITH first_purchase AS (
    SELECT fp.*,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS rn
    FROM transactions fp
),
item_count AS (
    SELECT i.item_name,
           COUNT(*) AS frequency
    FROM first_purchase fp
    JOIN items i 
        ON fp.store_id = i.store_id 
       AND fp.item_id = i.item_id
    WHERE fp.rn = 1
    GROUP BY i.item_name
    ORDER BY frequency DESC
)
SELECT *
FROM item_count
WHERE ROWNUM = 1;


-- 6) REFUND PROCESSABLE FLAG
-- Assumption: A refund within 72 hours of purchase is allowed.

ALTER TABLE transactions
ADD refund_processable NUMBER(1);

UPDATE transactions
SET refund_processable =
    CASE 
        WHEN refund_time IS NULL THEN 0
        WHEN refund_time <= purchase_time + NUMTODSINTERVAL(72, 'HOUR') THEN 1
        ELSE 0
    END;


-- 7) SECOND PURCHASE PER BUYER (IGNORING REFUNDS)
-- Assumption: Only non-refunded rows are considered as actual purchases.

SELECT *
FROM (
    SELECT t.*,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions t
    WHERE refund_time IS NULL
)
WHERE rn = 2;


-- 8) SECOND TRANSACTION TIME PER BUYER (NO MIN/MAX)
-- Assumption: ROW_NUMBER() is used to find 2nd purchase.

SELECT buyer_id, purchase_time
FROM (
    SELECT buyer_id, purchase_time,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
)
WHERE rn = 2;
