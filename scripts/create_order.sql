-- =====================================================
-- СКРИПТ: create_order.sql
-- НАЗНАЧЕНИЕ: Создание новой заявки клиента на перевозку
-- ПАРАМЕТРЫ: client_id, описание груза, адреса, даты
-- =====================================================

-- Генерация уникального номера заказа
-- Формат: ORD-YYYYMMDD-XXXX

DO $$
DECLARE
    new_order_number VARCHAR(30);
    v_client_id INTEGER := 1; -- ID клиента (заменить на нужный)
    v_cargo_desc TEXT := 'Строительные материалы (кирпич, цемент)';
    v_weight NUMERIC := 15000; -- 15 тонн
    v_volume NUMERIC := 30; -- 30 м³
    v_pickup TEXT := 'г. Москва, ул. Строителей, 10, склад №3';
    v_delivery TEXT := 'г. Санкт-Петербург, ул. Промышленная, 25';
    v_pickup_date DATE := CURRENT_DATE + INTERVAL '3 days';
BEGIN
    -- Формирование номера заказа
    new_order_number := 'ORD-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

    -- Вставка заказа
    INSERT INTO orders (
        client_id,
        order_number,
        cargo_description,
        cargo_weight_kg,
        cargo_volume_m3,
        pickup_address,
        delivery_address,
        pickup_date,
        status
    ) VALUES (
        v_client_id,
        new_order_number,
        v_cargo_desc,
        v_weight,
        v_volume,
        v_pickup,
        v_delivery,
        v_pickup_date,
        'Новый'
    );

    RAISE NOTICE 'Создан заказ № % для клиента ID %', new_order_number, v_client_id;
END $$;

-- Проверка созданного заказа
SELECT o.*, c.full_name as client_name
FROM orders o
JOIN clients c ON o.client_id = c.id
ORDER BY o.id DESC
LIMIT 1;