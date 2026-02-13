-- =====================================================
-- СКРИПТ: assign_trip.sql
-- НАЗНАЧЕНИЕ: Назначение транспортного средства и водителя на заказ
-- ПАРАМЕТРЫ: order_id, vehicle_id, driver_id, дата/время
-- =====================================================

DO $$
DECLARE
    v_order_id INTEGER := 1; -- ID заказа (заменить на нужный)
    v_vehicle_id INTEGER;
    v_driver_id INTEGER;
    v_trip_number VARCHAR(30);
    v_order_status VARCHAR(30);
BEGIN
    -- Проверка статуса заказа
    SELECT status INTO v_order_status FROM orders WHERE id = v_order_id;

    IF v_order_status != 'Новый' AND v_order_status != 'Подтвержден' THEN
        RAISE EXCEPTION 'Заказ имеет статус %, назначение рейса невозможно', v_order_status;
    END IF;

    -- Выбор свободного ТС (пример: грузовик, не в рейсе и не в ремонте)
    SELECT id INTO v_vehicle_id FROM vehicles
    WHERE status = 'Свободен'
      AND vehicle_type IN ('Грузовая', 'Рефрижератор')
    LIMIT 1;

    IF v_vehicle_id IS NULL THEN
        RAISE EXCEPTION 'Нет свободных транспортных средств';
    END IF;

    -- Выбор свободного водителя
    SELECT id INTO v_driver_id FROM drivers
    WHERE status = 'Активен'
    LIMIT 1;

    IF v_driver_id IS NULL THEN
        RAISE EXCEPTION 'Нет свободных водителей';
    END IF;

    -- Генерация номера рейса
    v_trip_number := 'TRIP-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(v_order_id::TEXT, 5, '0');

    -- Создание рейса
    INSERT INTO trips (
        order_id,
        vehicle_id,
        driver_id,
        trip_number,
        planned_start_date,
        status
    ) VALUES (
        v_order_id,
        v_vehicle_id,
        v_driver_id,
        v_trip_number,
        CURRENT_TIMESTAMP + INTERVAL '1 day',
        'Назначен'
    );

    -- Обновление статуса заказа
    UPDATE orders SET status = 'Подтвержден' WHERE id = v_order_id;

    -- Обновление статусов ТС и водителя
    UPDATE vehicles SET status = 'В рейсе' WHERE id = v_vehicle_id;
    UPDATE drivers SET status = 'В рейсе' WHERE id = v_driver_id;

    RAISE NOTICE 'Создан рейс № % для заказа %', v_trip_number, v_order_id;
    RAISE NOTICE 'Назначены: ТС ID %, Водитель ID %', v_vehicle_id, v_driver_id;
END $$;

-- Просмотр назначенного рейса
SELECT t.*,
       v.reg_number, v.brand, v.model,
       d.full_name as driver_name,
       o.order_number
FROM trips t
JOIN vehicles v ON t.vehicle_id = v.id
JOIN drivers d ON t.driver_id = d.id
JOIN orders o ON t.order_id = o.id
ORDER BY t.id DESC
LIMIT 1;