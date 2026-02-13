-- =====================================================
-- СКРИПТ: create_db.sql
-- НАЗНАЧЕНИЕ: Создание структуры базы данных транспортной компании
-- =====================================================

-- Создание базы данных (если не существует)
CREATE DATABASE transport_company
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;

\c transport_company;

-- =====================================================
-- Таблица 1: Клиенты
-- =====================================================
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    client_type VARCHAR(20) NOT NULL CHECK (client_type IN ('Юрлицо', 'Физлицо')),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    inn VARCHAR(12),
    kpp VARCHAR(9),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- Таблица 2: Транспортные средства
-- =====================================================
CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    reg_number VARCHAR(15) UNIQUE NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    vehicle_type VARCHAR(30) NOT NULL,
    load_capacity_kg NUMERIC(10, 2),
    volume_m3 NUMERIC(10, 2),
    fuel_type VARCHAR(20),
    fuel_consumption_norm NUMERIC(5, 2),
    year_manufacture INTEGER,
    status VARCHAR(20) DEFAULT 'Свободен',
    mileage_km INTEGER DEFAULT 0,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Таблица 3: Водители
-- =====================================================
CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    birth_date DATE,
    passport_number VARCHAR(20) UNIQUE,
    license_number VARCHAR(20) UNIQUE NOT NULL,
    license_category VARCHAR(10) NOT NULL,
    experience_years INTEGER DEFAULT 0,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    hire_date DATE NOT NULL,
    fire_date DATE,
    status VARCHAR(20) DEFAULT 'Активен',
    salary_rate NUMERIC(10, 2)
);

-- =====================================================
-- Таблица 4: Заказы
-- =====================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id) ON DELETE RESTRICT,
    order_number VARCHAR(30) UNIQUE NOT NULL,
    cargo_description TEXT NOT NULL,
    cargo_weight_kg NUMERIC(10, 2),
    cargo_volume_m3 NUMERIC(10, 2),
    pickup_address TEXT NOT NULL,
    delivery_address TEXT NOT NULL,
    pickup_date DATE NOT NULL,
    delivery_date DATE,
    is_return_trip BOOLEAN DEFAULT FALSE,
    special_conditions TEXT,
    status VARCHAR(30) DEFAULT 'Новый',
    total_price NUMERIC(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Таблица 5: Рейсы
-- =====================================================
CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    order_id INTEGER UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE RESTRICT,
    driver_id INTEGER REFERENCES drivers(id) ON DELETE RESTRICT,
    trip_number VARCHAR(30) UNIQUE NOT NULL,
    planned_start_date TIMESTAMP NOT NULL,
    planned_end_date TIMESTAMP,
    actual_start_date TIMESTAMP,
    actual_end_date TIMESTAMP,
    planned_distance_km INTEGER,
    actual_distance_km INTEGER,
    fuel_issued_liters NUMERIC(8, 2),
    fuel_used_liters NUMERIC(8, 2),
    status VARCHAR(30) DEFAULT 'Запланирован',
    notes TEXT
);

-- =====================================================
-- Таблица 6: Путевые листы
-- =====================================================
CREATE TABLE waybills (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER UNIQUE REFERENCES trips(id) ON DELETE RESTRICT,
    waybill_number VARCHAR(30) UNIQUE NOT NULL,
    issued_date DATE NOT NULL,
    closed_date DATE,
    mechanic_signature BOOLEAN DEFAULT FALSE,
    accountant_signature BOOLEAN DEFAULT FALSE,
    odometer_start INTEGER,
    odometer_end INTEGER,
    fuel_at_start NUMERIC(6, 2),
    fuel_at_end NUMERIC(6, 2)
);

-- =====================================================
-- Таблица 7: Учет топлива
-- =====================================================
CREATE TABLE fuel_records (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE RESTRICT,
    driver_id INTEGER REFERENCES drivers(id) ON DELETE RESTRICT,
    fuel_date DATE NOT NULL,
    fuel_amount_liters NUMERIC(8, 2) NOT NULL,
    fuel_cost_per_liter NUMERIC(8, 2) NOT NULL,
    total_cost NUMERIC(10, 2) GENERATED ALWAYS AS (fuel_amount_liters * fuel_cost_per_liter) STORED,
    fuel_card_number VARCHAR(30),
    odometer_km INTEGER NOT NULL,
    gas_station VARCHAR(100)
);

-- =====================================================
-- Таблица 8: Техническое обслуживание
-- =====================================================
CREATE TABLE maintenance (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE RESTRICT,
    maintenance_type VARCHAR(50),
    service_date DATE NOT NULL,
    service_mileage_km INTEGER NOT NULL,
    description TEXT,
    parts_cost NUMERIC(10, 2),
    labor_cost NUMERIC(10, 2),
    total_cost NUMERIC(12, 2) GENERATED ALWAYS AS (parts_cost + labor_cost) STORED,
    service_center VARCHAR(100),
    next_service_mileage_km INTEGER,
    next_service_date DATE
);

-- =====================================================
-- Таблица 9: Склад запчастей и материалов
-- =====================================================
CREATE TABLE spare_parts (
    id SERIAL PRIMARY KEY,
    part_number VARCHAR(50) UNIQUE NOT NULL,
    part_name VARCHAR(200) NOT NULL,
    manufacturer VARCHAR(100),
    quantity INTEGER NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL,
    price_per_unit NUMERIC(10, 2),
    min_stock INTEGER DEFAULT 1,
    location VARCHAR(50)
);

-- =====================================================
-- Таблица 10: Списание материалов
-- =====================================================
CREATE TABLE material_write_offs (
    id SERIAL PRIMARY KEY,
    part_id INTEGER REFERENCES spare_parts(id) ON DELETE RESTRICT,
    maintenance_id INTEGER REFERENCES maintenance(id) ON DELETE RESTRICT,
    write_off_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    reason VARCHAR(200),
    written_by VARCHAR(100) -- ФИО механика
);

-- =====================================================
-- Создание индексов
-- =====================================================
CREATE INDEX idx_orders_client_id ON orders(client_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_fuel_records_vehicle_id ON fuel_records(vehicle_id);
CREATE INDEX idx_maintenance_vehicle_id ON maintenance(vehicle_id);