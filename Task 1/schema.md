# Olist Database Schema Documentation

## 📊 Overview

The Olist dataset is a real-world Brazilian e-commerce dataset containing **99,441 orders** placed between **September 2016 and October 2018** at Olist Store, a Brazilian marketplace that connects small businesses across Brazil.

The dataset is organized into **9 related tables** that follow a classic dimensional model, with `orders` as the central fact table and the others connected via foreign keys.

---

## 🗺️ Entity Relationship Diagram (Text Representation)

```
                                  ┌──────────────────────┐
                                  │   product_category   │
                                  │   _name_translation  │
                                  └──────────┬───────────┘
                                             │ (product_category_name)
                                             ▼
┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐
│  customers   │◄───│     orders       │◄───│   order_items    │───►│   products   │
│              │    │                  │    │                  │    └──────────────┘
└──────┬───────┘    └────────┬─────────┘    └────────┬─────────┘
       │                     │                       │
       │                     │                       ▼
       │                     ▼               ┌──────────────┐
       │             ┌───────────────┐       │   sellers    │
       │             │ order_reviews │       └──────────────┘
       │             └───────────────┘
       │
       │             ┌───────────────┐
       └────────────►│ order_payments│
                     └───────────────┘

┌──────────────────────┐
│    geolocation       │  (linked by zip_code_prefix to customers & sellers)
└──────────────────────┘
```

---

## 📋 Table Definitions

### 1. `customers` (99,441 rows)
Each row = a unique customer who placed at least one order.

| Column | Type | Description |
|---|---|---|
| `customer_id` | TEXT (PK) | Unique ID per **order** (one customer can have multiple `customer_id`s if they placed multiple orders) |
| `customer_unique_id` | TEXT | True customer identifier — same across multiple orders by the same person |
| `customer_zip_code_prefix` | TEXT | First 5 digits of customer's zip code |
| `customer_city` | TEXT | Customer's city |
| `customer_state` | TEXT | Customer's state (2-letter Brazilian state code, e.g., SP, RJ, MG) |

> ⚠️ **Important**: `customer_id` is unique per order, but `customer_unique_id` identifies the actual person. To find repeat customers, group by `customer_unique_id`.

---

### 2. `orders` (99,441 rows) — **Central Fact Table**
Each row = one order placed on the marketplace.

| Column | Type | Description |
|---|---|---|
| `order_id` | TEXT (PK) | Unique order identifier |
| `customer_id` | TEXT (FK → customers) | Links to the customer who placed the order |
| `order_status` | TEXT | Status: delivered, shipped, canceled, unavailable, etc. |
| `order_purchase_timestamp` | TEXT | When the customer placed the order |
| `order_approved_at` | TEXT | When payment was approved |
| `order_delivered_carrier_date` | TEXT | When the order was handed to the logistics carrier |
| `order_delivered_customer_date` | TEXT | When the customer actually received the order |
| `order_estimated_delivery_date` | TEXT | Estimated delivery date shown to customer at purchase |

---

### 3. `order_items` (112,650 rows)
Each row = one product in an order. An order with 3 products has 3 rows here.

| Column | Type | Description |
|---|---|---|
| `order_id` | TEXT (FK → orders) | The order this item belongs to |
| `order_item_id` | INTEGER | Sequential number identifying the item within an order (1, 2, 3...) |
| `product_id` | TEXT (FK → products) | The product purchased |
| `seller_id` | TEXT (FK → sellers) | The seller who fulfilled the item |
| `shipping_limit_date` | TEXT | Deadline for the seller to ship the item |
| `price` | REAL | Item price in Brazilian Reais (R$) |
| `freight_value` | REAL | Shipping cost in R$ |

> **Composite PK**: (`order_id`, `order_item_id`)

---

### 4. `order_payments` (103,886 rows)
Each row = one payment. An order paid with 2 vouchers + credit card has 3 rows.

| Column | Type | Description |
|---|---|---|
| `order_id` | TEXT (FK → orders) | The order this payment belongs to |
| `payment_sequential` | INTEGER | Sequential number for multiple payments on one order |
| `payment_type` | TEXT | Credit card, boleto (Brazilian payment slip), voucher, debit card |
| `payment_installments` | INTEGER | Number of installments (e.g., 1 = paid in full, 12 = 12 monthly payments) |
| `payment_value` | REAL | Payment amount in R$ |

---

### 5. `order_reviews` (99,224 rows)
Each row = one review submitted by a customer after receiving their order.

| Column | Type | Description |
|---|---|---|
| `review_id` | TEXT | Unique review identifier |
| `order_id` | TEXT (FK → orders) | The order being reviewed |
| `review_score` | INTEGER | 1 (worst) to 5 (best) |
| `review_comment_title` | TEXT | Comment title (often NULL) |
| `review_comment_message` | TEXT | Comment text (often NULL) |
| `review_creation_date` | TEXT | When the review survey was sent |
| `review_answer_timestamp` | TEXT | When the customer submitted the review |

---

### 6. `products` (32,951 rows)
Each row = one product in the Olist catalog.

| Column | Type | Description |
|---|---|---|
| `product_id` | TEXT (PK) | Unique product identifier |
| `product_category_name` | TEXT | Category name in Portuguese |
| `product_name_lenght` | INTEGER | Length of product name string |
| `product_description_lenght` | INTEGER | Length of product description string |
| `product_photos_qty` | INTEGER | Number of product photos |
| `product_weight_g` | INTEGER | Product weight in grams |
| `product_length_cm` | INTEGER | Product length in cm |
| `product_height_cm` | INTEGER | Product height in cm |
| `product_width_cm` | INTEGER | Product width in cm |

---

### 7. `sellers` (3,095 rows)
Each row = one seller on the marketplace.

| Column | Type | Description |
|---|---|---|
| `seller_id` | TEXT (PK) | Unique seller identifier |
| `seller_zip_code_prefix` | TEXT | First 5 digits of seller's zip code |
| `seller_city` | TEXT | Seller's city |
| `seller_state` | TEXT | Seller's state |

---

### 8. `geolocation` (1,000,163 rows)
Maps zip code prefixes to latitude/longitude coordinates. Used for mapping and distance calculations.

| Column | Type | Description |
|---|---|---|
| `geolocation_zip_code_prefix` | TEXT | Zip code prefix |
| `geolocation_lat` | REAL | Latitude |
| `geolocation_lng` | REAL | Longitude |
| `geolocation_city` | TEXT | City name |
| `geolocation_state` | TEXT | State code |

> ⚠️ This table has **many rows per zip code prefix** (one for each neighborhood block). For joins, aggregate to one row per zip code using `AVG(lat), AVG(lng)`.

---

### 9. `product_category_name_translation` (71 rows)
Translates Portuguese category names to English.

| Column | Type | Description |
|---|---|---|
| `product_category_name` | TEXT (PK) | Portuguese name (matches `products.product_category_name`) |
| `product_category_name_english` | TEXT | English translation |

---

## 🔑 Key Relationships (Foreign Keys)

| From Table | From Column | To Table | To Column | Relationship |
|---|---|---|---|---|
| `orders` | `customer_id` | `customers` | `customer_id` | Many orders → 1 customer |
| `order_items` | `order_id` | `orders` | `order_id` | Many items → 1 order |
| `order_items` | `product_id` | `products` | `product_id` | Many items → 1 product |
| `order_items` | `seller_id` | `sellers` | `seller_id` | Many items → 1 seller |
| `order_payments` | `order_id` | `orders` | `order_id` | Many payments → 1 order |
| `order_reviews` | `order_id` | `orders` | `order_id` | Many reviews → 1 order (rare) |
| `customers` | `customer_zip_code_prefix` | `geolocation` | `geolocation_zip_code_prefix` | Many customers → many geo rows |
| `sellers` | `seller_zip_code_prefix` | `geolocation` | `geolocation_zip_code_prefix` | Many sellers → many geo rows |
| `products` | `product_category_name` | `product_category_name_translation` | `product_category_name` | Many products → 1 category translation |

---

## 💡 Key Business Insights Available

This schema supports a wide range of analyses:

1. **Revenue analysis** — total sales, by product, by category, by seller, by region
2. **Customer behavior** — repeat purchase rate, customer lifetime value, cohort retention
3. **Logistics performance** — delivery time, on-time delivery rate, late deliveries
4. **Payment patterns** — preferred payment methods, installment behavior
5. **Product performance** — top sellers, highest-rated categories, review score trends
6. **Geographic analysis** — revenue by state, seller coverage, regional preferences
7. **Time trends** — monthly revenue, seasonality, growth rates
8. **Seller performance** — top sellers by revenue, seller rating, fulfillment speed

---

## 🛠️ How to Use This Database

### Option A: DB Browser for SQLite (Recommended for beginners)
1. Download from https://sqlitebrowser.org/dl/
2. Open DB Browser for SQLite
3. File → Open Database → select `olist.db`
4. Go to "Execute SQL" tab
5. Paste any query → click ▶️ Run (or F5)
6. Right-click results → "Export to CSV" for screenshots

### Option B: Command Line (sqlite3)
```bash
sqlite3 olist.db
sqlite> .headers on
sqlite> .mode column
sqlite> SELECT * FROM customers LIMIT 5;
```

### Option C: Python
```python
import sqlite3
conn = sqlite3.connect("olist.db")
df = pd.read_sql_query("SELECT * FROM orders LIMIT 10", conn)
```
