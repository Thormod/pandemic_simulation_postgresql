CREATE FUNCTION calculate_constant_of_integration (IN growth_rate float, IN _population float, OUT constant_of_integration float
)
AS $$
DECLARE
    v_time float;
    v_patient_amount float;
BEGIN
    SELECT
        _time
    FROM
        variable INTO v_time;
    SELECT
        amount
    FROM
        patient INTO v_patient_amount;
    constant_of_integration := (exp(growth_rate * v_time) * (_population - v_patient_amount)) / v_patient_amount;
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

CREATE FUNCTION calculate_growth_rate (IN _constant_of_integration float, IN _population float, OUT growth_rate float
)
AS $$
DECLARE
    v_time float;
    v_patient_amount float;
BEGIN
    SELECT
        _time
    FROM
        variable INTO v_time;
    SELECT
        amount
    FROM
        patient INTO v_patient_amount;
    growth_rate := log(((_population - v_patient_amount) / (v_patient_amount * constant_of_integration)) / v_time);
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

CREATE FUNCTION time_passes_trigger ()
    RETURNS TRIGGER
    AS $time_passes_trigger$
DECLARE
    v_timestamp text;
    v_time float;
    v_end_time float;
BEGIN
    SELECT
        _timestamp
    FROM
        variable INTO v_timestamp;
    SELECT
        _time
    FROM
        variable INTO v_time;
    SELECT
        end_time
    FROM
        parameter INTO v_end_time;
    IF (v_timestamp = 'next') THEN
        IF (v_time <= v_end_time) THEN
            UPDATE
                variable
            SET
                _time = v_time + 1;
        END IF;
    END IF;
    RETURN NULL;
END;
$time_passes_trigger$
LANGUAGE plpgsql;

CREATE FUNCTION time_passes_1_trigger ()
    RETURNS TRIGGER
    AS $time_passes_1_trigger$
BEGIN
    UPDATE
        variable
    SET
        _timestamp = 'stop';
    RETURN NULL;
END;
$time_passes_1_trigger$
LANGUAGE plpgsql;

CREATE FUNCTION patient_amount_grows ()
    RETURNS TRIGGER
    AS $patient_amount_grows$
DECLARE
    v_timestamp text;
    v_time float;
    v_end_time float;
    v_population float;
    v_constant_of_integration float;
    v_growth_rate float;
    v_patient_local_time float;
    v_patient_amount float;
    v_res float;
BEGIN
    SELECT
        _timestamp
    FROM
        variable INTO v_timestamp;
    SELECT
        _time
    FROM
        variable INTO v_time;
    SELECT
        end_time
    FROM
        parameter INTO v_end_time;
    SELECT
        _population
    FROM
        parameter INTO v_population;
    SELECT
        constant_of_integration
    FROM
        parameter INTO v_constant_of_integration;
    SELECT
        growth_rate
    FROM
        parameter INTO v_growth_rate;
    SELECT
        local_time
    FROM
        patient INTO v_patient_local_time;
    SELECT
        amount
    FROM
        patient INTO v_patient_amount;
    IF (v_timestamp = 'stop') THEN
        IF (v_time <= v_end_time) THEN
            IF (v_time >= 1) THEN
                v_res := v_population / (1 + (v_constant_of_integration * exp(- 1 * (v_growth_rate * v_time))));
                INSERT INTO patient (local_time, amount)
                    VALUES (v_time, v_res);
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$patient_amount_grows$
LANGUAGE plpgsql;

CREATE FUNCTION patient_amount_grows_1 ()
    RETURNS TRIGGER
    AS $patient_amount_grows_1$
BEGIN
    UPDATE
        variable
    SET
        _timestamp = 'next';
    RETURN NULL;
END;
$patient_amount_grows_1$
LANGUAGE plpgsql;

CREATE TABLE patient (
    id serial PRIMARY KEY,
    local_time float NOT NULL DEFAULT 0,
    amount float NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE variable (
    id serial PRIMARY KEY,
    _timestamp text NOT NULL,
    _time float NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE parameter (
    id serial PRIMARY KEY,
    _population float NOT NULL,
    end_time float NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    growth_rate float NOT NULL,
    constant_of_integration float NOT NULL
);

INSERT INTO patient (local_time, amount)
    VALUES (0, 200);

INSERT INTO variable (_timestamp, _time)
    VALUES ('stop', 0);

INSERT INTO parameter (_population, growth_rate, end_time, constant_of_integration)
    VALUES (500000, 0.916891, 6, 2499);

CREATE TRIGGER time_passes_trigger
    AFTER UPDATE OF _timestamp ON variable
    FOR EACH ROW
    EXECUTE PROCEDURE time_passes_trigger ();

CREATE TRIGGER time_passes_1_trigger
    AFTER UPDATE OF _time ON variable
    FOR EACH ROW
    EXECUTE PROCEDURE time_passes_1_trigger ();

CREATE TRIGGER patient_amount_grows
    AFTER UPDATE OF _timestamp ON variable
    FOR EACH ROW
    EXECUTE PROCEDURE patient_amount_grows ();

CREATE TRIGGER patient_amount_grows_1
    AFTER INSERT ON patient
    FOR EACH ROW
    EXECUTE PROCEDURE patient_amount_grows_1 ();

