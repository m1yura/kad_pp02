-- =====================================================
-- СКРИПТ: close_waybill.sql
-- НАЗНАЧЕНИЕ: Закрытие путевого листа после рейса
-- ПАРАМЕТРЫ: waybill_id, конечные показания, остаток топлива
-- =====================================================

DO $$
DECLARE
    v_waybill_id INTEGER := 1; -- ID путевого листа
    v_odometer_end INTEGER := 155800; -- Пробег при возврате
    v_fuel_end NUMERIC(6,2) := 85.5; -- Остаток топлива
    v_trip_id INTEGER;
    v_odometer_start INTEGER;
    v_distance INTEGER;
    v_fuel_start NUMERIC(6,2);
    v_fuel_issued NUMERIC(8,2);
    v_fuel_used NUMERIC(8,2);
BEGIN
    -- Получаем данные путевого листа и рейса
    SELECT w.trip_id, w.odometer_start, w.fuel_at_start,
           t.fuel_issued_liters
    INTO v_trip_id, v_odometer_start, v_fuel_start, v_fuel_issued
    FROM waybills w
    JOIN trips t ON w.trip_id = t.id
    WHERE w.id = v_waybill_id;

    -- Расчет пробега и расхода топлива
    v_distance := v_odometer_end - v_odometer_start;
    v_fuel_used := v_fuel_start + v_fuel_issued - v_fuel_end;

    -- Обновление путевого листа
    UPDATE waybills SET
        closed_date = CURRENT_DATE,
        odometer_end = v_odometer_end,
        fuel_at_end = v_fuel_end,
        accountant_signature = TRUE
    WHERE id = v_waybill_id;

    -- Обновление рейса
    UPDATE trips SET
        actual_end_date = CURRENT_TIMESTAMP,
        actual_distance_km = v_distance,
        fuel_used_liters = v_fuel_used,
        status = 'Завершен'
    WHERE id = v_trip_id;

    -- Обновление пробега в ТС
    UPDATE vehicles v
    SET mileage_km = v_odometer_end
    FROM trips t
    WHERE v.id = t.vehicle_id AND t.id = v_trip_id;

    -- Освобождение водителя и ТС
    UPDATE drivers SET status = 'Активен'
    WHERE id = (SELECT driver_id FROM trips WHERE id = v_trip_id);

    UPDATE vehicles SET status = 'Свободен'
    WHERE id = (SELECT vehicle_id FROM trips WHERE id = v_trip_id);

    RAISE NOTICE 'Путевой лист № % закрыт', v_waybill_id;
    RAISE NOTICE 'Пробег: % км, Расход топлива: % л', v_distance, v_fuel_used;
END $$;

-- Проверка закрытого путевого листа
SELECT w.*,
       t.trip_number,
       t.actual_distance_km,
       t.fuel_used_liters
FROM waybills w
JOIN trips t ON w.trip_id = t.id
WHERE w.id = 1;