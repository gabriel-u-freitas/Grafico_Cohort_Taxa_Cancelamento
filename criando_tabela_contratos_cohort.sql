-- Step 1: Create the table
CREATE TABLE contratos (
    id SERIAL PRIMARY KEY,
    contratacao TIMESTAMP NOT NULL,
    cancelamento TIMESTAMP
);

-- Step 2: Generate 2000 rows with contratacao and random cancelamento
WITH series AS (
    -- Generate 2000 random contratacao timestamps between 2023-06-01 and 2024-10-15
    SELECT 
        '2023-06-01'::timestamp + (random() * ('2024-10-15'::timestamp - '2023-06-01'::timestamp)) AS contratacao
    FROM generate_series(1, 2000)
),
day_chances AS (
    SELECT 
        s.contratacao,
        gs.days,
        -- Calculate the actual date of each month after contratacao
        s.contratacao + (gs.days || ' days')::interval AS day_date,
        
        -- Calculate base chance (4% for contratacao < 2024-04-01, 6% for contratacao >= 2024-04-01)
        -- Calculate final chance, adding 50% increase on the 12th and 13th months
        CASE 
            WHEN gs.days between 365 and 395 THEN 
                1.5 * (CASE WHEN s.contratacao < '2024-04-01' THEN 0.04/30 ELSE 0.06/30 END)
            ELSE
                CASE WHEN s.contratacao < '2024-04-01' THEN 0.04/30 ELSE 0.06/30 END
        END AS final_chance
        
    FROM series s
    -- Generate a series of months from 0 to the number of months between contratacao and now()
    JOIN generate_series(0, EXTRACT(year FROM age(now(), '2023-06-01'::timestamp)) * 365 + EXTRACT(month FROM age(now(), '2023-06-01'::timestamp))*12 +EXTRACT(day FROM age(now(), '2023-06-01'::timestamp))) AS gs(days)
    ON TRUE
),
final_data AS (
    SELECT
        mc.contratacao,
        -- Determine if a cancelamento occurs based on cumulative monthly chance
        CASE 
            WHEN random() < final_chance THEN
                mc.day_date + (random() * interval '12 hours')
            ELSE NULL
        END AS cancelamento
    FROM day_chances mc
),
final_data_grouped AS (
    -- Group by contratacao to ensure only one cancelamento per contratacao
    SELECT
        fd.contratacao,
        MIN(fd.cancelamento) AS cancelamento
    FROM final_data fd
    GROUP BY fd.contratacao
)
-- Step 3: Insert into the table
INSERT INTO contratos (contratacao, cancelamento)
SELECT contratacao, cancelamento
FROM final_data_grouped;