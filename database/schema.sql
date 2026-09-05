CREATE DATABASE IF NOT EXISTS hadroug_delivery
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE hadroug_delivery;

-- =========================================================
-- USERS
-- =========================================================

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,

    password_hash VARCHAR(255) NOT NULL,

    role ENUM('restaurant', 'driver', 'admin') NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_users_role (role),
    INDEX idx_users_active (is_active)
);

-- =========================================================
-- RESTAURANTS
-- =========================================================

CREATE TABLE restaurants (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL UNIQUE,

    name VARCHAR(200) NOT NULL,
    address VARCHAR(500),

    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,

    balance_due DECIMAL(10, 3) NOT NULL DEFAULT 0.000,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_restaurant_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    INDEX idx_restaurant_location (latitude, longitude),
    INDEX idx_restaurant_active (is_active)
);

-- =========================================================
-- DRIVERS
-- =========================================================

CREATE TABLE drivers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL UNIQUE,

    phone VARCHAR(30) NOT NULL UNIQUE,

    vehicle_type ENUM('motorcycle', 'car', 'other')
        NOT NULL DEFAULT 'motorcycle',

    is_online BOOLEAN NOT NULL DEFAULT FALSE,

    is_available BOOLEAN NOT NULL DEFAULT FALSE,

    current_orders_count INT UNSIGNED NOT NULL DEFAULT 0,

    total_completed_orders INT UNSIGNED NOT NULL DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    INDEX idx_driver_status (
        is_online,
        is_available,
        current_orders_count
    )
);

-- =========================================================
-- DRIVER LOCATIONS
-- =========================================================

CREATE TABLE driver_locations (
    driver_id BIGINT UNSIGNED PRIMARY KEY,

    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,

    accuracy DECIMAL(8, 2),

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_location_driver
        FOREIGN KEY (driver_id)
        REFERENCES drivers(id)
        ON DELETE CASCADE
);

-- =========================================================
-- ORDERS
-- =========================================================

CREATE TABLE orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    restaurant_id BIGINT UNSIGNED NOT NULL,

    driver_id BIGINT UNSIGNED NULL,

    customer_name VARCHAR(150),
    customer_phone VARCHAR(30),

    customer_address VARCHAR(500) NOT NULL,

    customer_latitude DECIMAL(10, 8) NOT NULL,
    customer_longitude DECIMAL(11, 8) NOT NULL,

    food_amount DECIMAL(10, 3) NOT NULL,

    hadroug_fee DECIMAL(10, 3) NOT NULL DEFAULT 1.000,

    driver_fee DECIMAL(10, 3) NOT NULL DEFAULT 0.000,

    status ENUM(
        'pending',
        'dispatching',
        'offered',
        'accepted',
        'driver_arrived',
        'pickup_verified',
        'picked_up',
        'delivering',
        'delivered',
        'cancelled',
        'failed'
    ) NOT NULL DEFAULT 'pending',

    current_offer_driver_id BIGINT UNSIGNED NULL,

    offer_expires_at DATETIME NULL,

    pickup_otp_hash VARCHAR(255) NULL,

    pickup_otp_expires_at DATETIME NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    pickup_verified_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_restaurant
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_order_driver
        FOREIGN KEY (driver_id)
        REFERENCES drivers(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_order_offer_driver
        FOREIGN KEY (current_offer_driver_id)
        REFERENCES drivers(id)
        ON DELETE SET NULL,

    INDEX idx_orders_restaurant (restaurant_id),
    INDEX idx_orders_driver (driver_id),
    INDEX idx_orders_status (status),
    INDEX idx_orders_created (created_at),
    INDEX idx_orders_offer (
        status,
        current_offer_driver_id,
        offer_expires_at
    )
);

-- =========================================================
-- ORDER OFFERS
-- =========================================================

CREATE TABLE order_offers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    order_id BIGINT UNSIGNED NOT NULL,

    driver_id BIGINT UNSIGNED NOT NULL,

    distance_to_restaurant DECIMAL(10, 3),

    offered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    expires_at DATETIME NOT NULL,

    responded_at DATETIME NULL,

    status ENUM(
        'offered',
        'accepted',
        'rejected',
        'expired'
    ) NOT NULL DEFAULT 'offered',

    CONSTRAINT fk_offer_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_offer_driver
        FOREIGN KEY (driver_id)
        REFERENCES drivers(id)
        ON DELETE RESTRICT,

    INDEX idx_offer_order (order_id),
    INDEX idx_offer_driver (driver_id),
    INDEX idx_offer_status (status)
);

-- =========================================================
-- ORDER EVENTS
-- =========================================================

CREATE TABLE order_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    order_id BIGINT UNSIGNED NOT NULL,

    actor_user_id BIGINT UNSIGNED NULL,

    event_type VARCHAR(100) NOT NULL,

    old_status VARCHAR(50),
    new_status VARCHAR(50),

    description VARCHAR(500),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_event_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_event_user
        FOREIGN KEY (actor_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    INDEX idx_events_order (order_id),
    INDEX idx_events_created (created_at)
);

-- =========================================================
-- TRANSACTIONS
-- =========================================================

CREATE TABLE transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    order_id BIGINT UNSIGNED NULL,

    restaurant_id BIGINT UNSIGNED NULL,

    driver_id BIGINT UNSIGNED NULL,

    type ENUM(
        'restaurant_fee',
        'driver_income',
        'restaurant_payment',
        'adjustment'
    ) NOT NULL,

    amount DECIMAL(10, 3) NOT NULL,

    description VARCHAR(500),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_transaction_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_transaction_restaurant
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_transaction_driver
        FOREIGN KEY (driver_id)
        REFERENCES drivers(id)
        ON DELETE SET NULL,

    INDEX idx_transactions_order (order_id),
    INDEX idx_transactions_restaurant (restaurant_id),
    INDEX idx_transactions_driver (driver_id),
    INDEX idx_transactions_created (created_at)
);
