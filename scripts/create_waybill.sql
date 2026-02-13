-- =====================================================
-- СКРИПТ: create_waybill.sql
-- НАЗНАЧЕНИЕ: Формирование путевого листа перед рейсом
-- ПАРАМЕТРЫ: trip_id, показания спидометра, остаток топлива
-- =====================================================

DO $$
DECLARE
    v_trip_id INTEGER := 1; -- ID рейса (заменить на нужный)
    v_waybill_number VARCHAR(30);
    v_vehicle_id INTEGER;
    v_odometer_current INTEGER := 150000; -- Текущие показания спидометра
    v_fuel_current NUMERIC(6,2) := 120.5; -- Остаток топлива в баке
    v_fuel_issued NUMERIC(8,2) := 300.0; -- Выдано топлива (литров)
    v_trip_status VARCHAR(30);
BEGIN
    -- Проверка статуса рейса
    SELECT status, vehicle_id INTO v_trip_status, v_vehicle_id
    FROM trips WHERE id = v_trip_id;

    IF v_trip_status != 'Назначен' THEN
        RAISE EXCEPTION 'Рейс имеет статус %, нельзя выдать путевой лист', v_trip_status;
    END IF;

    -- Генерация номера путевого листа
    v_waybill_number := 'ПЛ-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(v_trip_id::TEXT, 4, '0');

    -- Создание путевого листа
    INSERT INTO waybills (
        trip_id,
        waybill_number,
        issued_date,
        odometer_start,
        fuel_at_start,
        mechanic_signature,
        accountant_signature
    ) VALUES (
        v_trip_id,
        v_waybill_number,
        CURRENT_DATE,
        v_odometer_current,
        v_fuel_current,
        TRUE, -- Механик подписал
        FALSE -- Бухгалтер еще не подписал
    );

    -- Обновление данных в рейсе (выданное топливо)
    UPDATE trips
    SET fuel_issued_liters = v_fuel_issued,
        status = 'В пути'
    WHERE id = v_trip_id;

    -- Обновление пробега в ТС (если нужно)
    UPDATE vehicles SET mileage_km = v_odometer_current WHERE id = v_vehicle_id;

    RAISE NOTICE 'Выдан путевой лист № % для рейса %', v_waybill_number, v_trip_id;
END $$;

-- Просмотр выданного путевого листа
SELECT w.*,
       t.trip_number,
       v.reg_number,
       d.full_name as driver_name
FROM waybills w
JOIN trips t ON w.trip_id = t.id
JOIN vehicles v ON t.vehicle_id = v.id
JOIN drivers d ON t.driver_id = d.id
ORDER BY w.id DESC
LIMIT 1;