-- =====================================================
-- СКРИПТ: add_fuel_record.sql
-- НАЗНАЧЕНИЕ: Фиксация заправки транспортного средства
-- ПАРАМЕТРЫ: vehicle_id, driver_id, литры, цена, пробег
-- =====================================================

DO $$
DECLARE
    v_vehicle_id INTEGER := 1; -- ID ТС
    v_driver_id INTEGER := 1; -- ID водителя
    v_fuel_amount NUMERIC(8,2) := 150.0; -- 150 литров
    v_price_per_liter NUMERIC(8,2) := 58.50; -- Цена за литр
    v_odometer INTEGER := 152300; -- Пробег на момент заправки
    v_card_number VARCHAR(30) := 'ТК-1234-5678-9012';
    v_gas_station VARCHAR(100) := 'АЗС "Лукойл" МКАД 45-й км';
BEGIN
    -- Проверка существования ТС и водителя
    IF NOT EXISTS (SELECT 1 FROM vehicles WHERE id = v_vehicle_id) THEN
        RAISE EXCEPTION 'ТС с ID % не найдено', v_vehicle_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM drivers WHERE id = v_driver_id) THEN
        RAISE EXCEPTION 'Водитель с ID % не найден', v_driver_id;
    END IF;

    -- Запись о заправке
    INSERT INTO fuel_records (
        vehicle_id,
        driver_id,
        fuel_date,
        fuel_amount_liters,
        fuel_cost_per_liter,
        fuel_card_number,
        odometer_km,
        gas_station
    ) VALUES (
        v_vehicle_id,
        v_driver_id,
        CURRENT_DATE,
        v_fuel_amount,
        v_price_per_liter,
        v_card_number,
        v_odometer,
        v_gas_station
    );

    RAISE NOTICE 'Заправка ТС % на % литров зафиксирована', v_vehicle_id, v_fuel_amount;
    RAISE NOTICE 'Сумма: % руб.', v_fuel_amount * v_price_per_liter;
END $$;

-- Просмотр последних заправок
SELECT fr.*,
       v.reg_number,
       d.full_name as driver_name
FROM fuel_records fr
JOIN vehicles v ON fr.vehicle_id = v.id
JOIN drivers d ON fr.driver_id = d.id
ORDER BY fr.fuel_date DESC
LIMIT 5;