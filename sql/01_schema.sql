-- 01_schema.sql
-- PostgreSQL DDL for the retail e-commerce analytics schema.
-- Retail E-Commerce Sales Analytics — PostgreSQL Enterprise Schema
-- Database Engine: PostgreSQL 14+ (Star-Schema Architecture)
-- Central fact table: orders (59,125 transactions)
-- Dimension tables: customers, products, regions, returns, marketing_spend
-- Primary and foreign key constraints enforce referential integrity across entities.

CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.regions (
    region_id     INTEGER PRIMARY KEY,
    region_name   VARCHAR(50) NOT NULL,
    country       VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.products (
    product_id    INTEGER PRIMARY KEY,
    product_name  VARCHAR(50) NOT NULL,
    category      VARCHAR(30) NOT NULL,
    list_price    NUMERIC(10,2) NOT NULL,
    unit_cost     NUMERIC(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.customers (
    customer_id          INTEGER PRIMARY KEY,
    signup_date           DATE NOT NULL,
    region_id             INTEGER REFERENCES analytics.regions(region_id),
    acquisition_channel    VARCHAR(20) NOT NULL,
    segment                VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.orders (
    order_id          INTEGER PRIMARY KEY,
    order_date         DATE NOT NULL,
    customer_id        INTEGER REFERENCES analytics.customers(customer_id),  -- NULL = guest checkout
    product_id         INTEGER REFERENCES analytics.products(product_id),
    region_id           INTEGER REFERENCES analytics.regions(region_id),      -- -1 = unmapped
    channel             VARCHAR(20) NOT NULL,                                  -- standardized in cleaning
    quantity             INTEGER NOT NULL,
    unit_price           NUMERIC(10,2) NOT NULL,
    discount_pct          NUMERIC(5,3) NOT NULL,
    revenue               NUMERIC(12,2) NOT NULL,
    cost                   NUMERIC(12,2) NOT NULL,
    gross_profit            NUMERIC(12,2) NOT NULL,
    quality_flag             VARCHAR(20),
    is_guest_checkout          BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_price               BOOLEAN NOT NULL DEFAULT TRUE                -- FALSE = known pricing-glitch row, exclude from revenue KPIs
);

CREATE TABLE IF NOT EXISTS analytics.returns (
    return_id      INTEGER PRIMARY KEY,
    order_id        INTEGER REFERENCES analytics.orders(order_id),
    return_date      DATE NOT NULL,
    reason            VARCHAR(30) NOT NULL,
    refund_amount      NUMERIC(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.marketing_spend (
    month        DATE NOT NULL,
    region_id     INTEGER REFERENCES analytics.regions(region_id),
    channel        VARCHAR(20) NOT NULL,
    spend           NUMERIC(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.calendar (
    date               DATE PRIMARY KEY,
    year                INTEGER NOT NULL,
    month                INTEGER NOT NULL,
    month_name            VARCHAR(20) NOT NULL,
    quarter                INTEGER NOT NULL,
    day_of_week             VARCHAR(20) NOT NULL,
    is_weekend                BOOLEAN NOT NULL,
    is_holiday_season           BOOLEAN NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON analytics.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON analytics.orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_product ON analytics.orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_region ON analytics.orders(region_id);
CREATE INDEX IF NOT EXISTS idx_returns_order ON analytics.returns(order_id);
