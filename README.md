# Sql-solutions
Dataset Overview
Transactions table
| Column                  | Description                                |
| ----------------------- | ------------------------------------------ |
| buyer_id                | Buyer identifier                           |
| purchase_time           | Timestamp of purchase                      |
| refund_time             | Timestamp of refund (NULL if not refunded) |
| refund_item             | Item refunded                              |
| store_id                | Store identifier                           |
| item_id                 | Item identifier                            |
| gross_transaction_value | Value of purchase                          |

items table
| Column        | Description      |
| ------------- | ---------------- |
| store_id      | Store identifier |
| item_id       | Item identifier  |
| item_category | Item category    |
| item_name     | Name of the item |

Assumptions

 1) Refund_time IS NOT NULL indicates a refunded purchase.

 2) YYYY-MM is used to format purchase_time for monthly computations.
3) Days are returned via timestamp subtraction; 

4) "First order" refers to the store's or buyer's earliest purchase moment.

5) Refunded transactions are not included for first-purchase popularity.

Thank you.

