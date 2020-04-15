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
                _timestamp = 'stop';
        END IF;
    END IF;
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
        variable INTO v_constant_of_integration;
    SELECT
        growth_rate
    FROM
        variable INTO v_growth_rate;
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
            IF (v_time > 1) THEN
                INSERT INTO patient (local_time, amount)
                    VALUES (v_time, v_population / (1 + (v_constant_of_integration * exp(- 1 * (v_growth_rate * v_time)))));
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
DECLARE
    v_time float;
    v_end_time float;
    v_timestamp text;
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
    IF (v_timestamp = 'stop') THEN
        IF (v_time <= v_end_time) THEN
            IF (v_time > 1) THEN
                UPDATE
                    variable
                SET
                    _timestamp = 'next';
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$patient_amount_grows_1$
LANGUAGE plpgsql;

CREATE FUNCTION patient_amount_arrives ()
    RETURNS TRIGGER
    AS $patient_amount_arrives$
DECLARE
    v_timestamp text;
    v_time float;
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
        _population
    FROM
        parameter INTO v_population;
    SELECT
        constant_of_integration
    FROM
        variable INTO v_constant_of_integration;
    SELECT
        growth_rate
    FROM
        variable INTO v_growth_rate;
    SELECT
        local_time
    FROM
        patient INTO v_patient_local_time;
    SELECT
        amount
    FROM
        patient INTO v_patient_amount;
    IF (v_timestamp = 'stop') THEN
        IF (v_time < 2) THEN
            IF (v_time = 0) THEN
                INSERT INTO patient (local_time, amount)
                    VALUES (v_time, 200);
                SELECT
                    amount
                FROM
                    patient INTO v_patient_amount
                ORDER BY
                    id DESC
                LIMIT 1;
                UPDATE
                    variable
                SET
                    constant_of_integration = ((v_population - v_patient_amount) / v_patient_amount);
            END IF;
            IF (v_time = 1) THEN
                INSERT INTO patient (local_time, amount)
                    VALUES (v_time, 500);
                SELECT
                    amount
                FROM
                    patient INTO v_patient_amount
                ORDER BY
                    id DESC
                LIMIT 1;
                UPDATE
                    variable
                SET
                    growth_rate = (- ln(((v_population - v_patient_amount) / (v_patient_amount * v_constant_of_integration)))) / v_time;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$patient_amount_arrives$
LANGUAGE plpgsql;

CREATE FUNCTION patient_amount_arrives_1 ()
    RETURNS TRIGGER
    AS $patient_amount_arrives_1$
DECLARE
    v_timestamp text;
    v_time float;
BEGIN
    SELECT
        _timestamp
    FROM
        variable INTO v_timestamp;
    SELECT
        _time
    FROM
        variable INTO v_time;
    IF (v_timestamp = 'stop') THEN
        IF (v_time < 2) THEN
            UPDATE
                variable
            SET
                _timestamp = 'next';
            RETURN NULL;
        END IF;
    END IF;
END;
$patient_amount_arrives_1$
LANGUAGE plpgsql;

CREATE TABLE patient (
    id serial PRIMARY KEY,
    local_time float NOT NULL DEFAULT 0,
    amount float NOT NULL DEFAULT 0
);

CREATE TABLE variable (
    id serial PRIMARY KEY,
    _timestamp text NOT NULL,
    _time float NOT NULL,
    growth_rate float NOT NULL,
    constant_of_integration float NOT NULL
);

CREATE TABLE parameter (
    id serial PRIMARY KEY,
    _population float NOT NULL,
    end_time float NOT NULL
);

INSERT INTO parameter (_population, end_time)
    VALUES (500000, 100);

INSERT INTO variable (_timestamp, _time, growth_rate, constant_of_integration)
    VALUES ('', 0, 0, 0);

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

CREATE TRIGGER patient_amount_arrives
    AFTER UPDATE OF _timestamp ON variable
    FOR EACH ROW
    EXECUTE PROCEDURE patient_amount_arrives ();

CREATE TRIGGER patient_amount_arrives_1
    AFTER UPDATE OF constant_of_integration ON variable
    FOR EACH ROW
    EXECUTE PROCEDURE patient_amount_arrives_1 ();

CREATE TRIGGER patient_amount_arrives_1_
    AFTER UPDATE OF growth_rate ON variable
    FOR EACH ROW
    EXECUTE PROCEDURE patient_amount_arrives_1 ();

UPDATE
    "variable"
SET
    _timestamp = 'stop';

