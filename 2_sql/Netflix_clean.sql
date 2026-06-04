create database netflix;
use netflix;

/* CREACIÓN E IMPORTACIÓN */
drop table if exists catalogo;

CREATE TABLE catalogo (
    catalogo_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    show_id VARCHAR(15),
    type VARCHAR(50),
    title VARCHAR(150),
    director VARCHAR(150),
    cast_names TEXT,
    country VARCHAR(100),
    date_added DATE,
    release_year INT,
    rating VARCHAR(50),
    duration VARCHAR(50),
    listed_in TEXT,
    descrip TEXT
);


LOAD DATA LOCAL INFILE '/Users/bedolla/workspace/proyecto3-netflix/1_datos/netflix_titles.csv'
INTO TABLE catalogo
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    show_id,
    type,
    title,
    director,
    cast_names,
    country,
    @date_added,
    @release_year,
    rating,
    duration,
    listed_in,
    descrip
)
SET 
    date_added = CASE 
        WHEN @date_added = '' THEN NULL
        ELSE STR_TO_DATE(@date_added, '%M %e, %Y')
    END,
    release_year = CAST(@release_year AS UNSIGNED);
 
    /* VALIDACION DE DATOS */
SELECT 
    *
FROM
    catalogo
 SELECT 
    COUNT(*)
FROM
    catalogo
 SELECT 
    COUNT(*)
FROM
    catalogo
WHERE
    date_added IS NULL
 SELECT 
    COUNT(*)
FROM
    catalogo
WHERE
    director IS NULL OR director = ''
    
    /* PROCEDIMIENTO ALMACENADO PARA EL SELECT DE CATALOGO */
	DELIMITER //
    
    CREATE PROCEDURE cat()
    begin
    select * from catalogo;
    end //
    delimiter ;
    
    call cat();
 
    /* LIMPIEZA */
SELECT 
    show_id, COUNT(*) AS cantidad_duplicados
FROM
    catalogo
GROUP BY show_id
HAVING COUNT(*) > 1;


SELECT COUNT(*) cantidad_duplicados
FROM
    (SELECT 
        show_id, COUNT(*) AS cantidad_duplicados
    FROM
        catalogo
    GROUP BY show_id
    HAVING COUNT(*) > 1) AS subquery;
    
call cat();

/* Campos vacíos */

   /* Identificando vacios */

SELECT show_id, director, country, cast_names
FROM catalogo
WHERE director = ''
   OR country = ''
   OR cast_names = '';
/* Conteo de vacios */

select count(*) as cantidad_vacios from (SELECT show_id, director, country, cast_names
FROM catalogo
WHERE director = ''
   OR country = ''
   OR cast_names = '') as subquery2;

   /* Vacios a null */
   
   SET SQL_SAFE_UPDATES = 0;
  
UPDATE catalogo 
SET 
    director = NULLIF(TRIM(director), ''),
    country = NULLIF(TRIM(country), ''),
    cast_names = NULLIF(TRIM(cast_names), '')
WHERE
    director = '' OR country = ''
    OR cast_names = '';
    
    call cat();
    
    /* TRANSFORMACION */
    
    /* Separar duracion, min y seasons */
    
    /* Agregamos columnas nuevas para min y seasons */
    alter table catalogo
    add duration_min INt,
    add seasons int;
    
    /* revisamos como vienen los datos */
    select distinct duration from catalogo 
    limit 20;
    
    
    /* Sacamos minutos de peliculas */
    
    update catalogo
    set duration_min = 
    cast(replace(duration,' min', '')as UNSIGNED)
    where duration like '%min';
    
    select duration_min from catalogo;
    
    /* Sacamos numero de seasons de temporadas */
    
    update catalogo
    set seasons = 
    cast(replace(replace(duration, ' Seasons', ''), ' Season', '') as unsigned)
	where duration like '%Season%';
    
    select seasons from catalogo;
    
    /* Separacion de fecha mes y año */

	alter table catalogo
    add year_added int,
    add month_added int;
    
    update catalogo
    set 
    year_added = year(date_added),
    month_added = month(date_added);
    
    select year_added, month_added from catalogo;
    
    /* Extrayendo un pais principal */
    
    alter table catalogo
    add column main_country varchar(100);
    
    update catalogo
    set main_country = 
    trim(substring_index(country, ',', 1));
    
    select * from catalogo
    limit 20;
    
    /* Análisis */
    
    /* Promedio de dduración peliculas */
    
    select avg(duration_min) as promedio_duracion 
    from catalogo;
    
    call cat();
    
    /* CONTEO */
    
    /* Total contenido */
    
    select count(*) as total_contenido from catalogo;
    
    /* Cuantas series vs cuantas peliculas */
    select type, count(*) as total 
    from catalogo
    group by type;
    
    /* Contenido por pais, top paises */

	SELECT main_country, COUNT(*) AS total
	FROM catalogo
	GROUP BY main_country
	ORDER BY total DESC
	LIMIT 10;    
    
    
	/* Contenido por año */
    
	SELECT year_added, COUNT(*) AS total
	FROM catalogo
	GROUP BY year_added
	ORDER BY total desc;
    
    /* DURACION PROMEDIO DE PELICULAS */
    
    SELECT AVG(duration_min) AS promedio_minutos
	FROM catalogo
	WHERE duration_min IS NOT NULL;
    
    /* PROMEDIO DE TEMPORADAS */
    SELECT AVG(seasons) AS promedio_temporadas
	FROM catalogo
	WHERE seasons IS NOT NULL;
    
    /* Segmentación */
    
    /* Contenido por clasificacion */
    SELECT rating, COUNT(*) AS total
	FROM catalogo
	GROUP BY rating
	ORDER BY total DESC;
    
    /* Por mes, en que mes agregan mas contenido */
    SELECT month_added, COUNT(*) AS total
	FROM catalogo
	GROUP BY month_added
	ORDER BY total desc;
    
    /* Top generos */
    
    SELECT listed_in, COUNT(*) AS total
	FROM catalogo
	GROUP BY listed_in
	ORDER BY total DESC
	LIMIT 10;
    
    /* Pais por tipo */
    SELECT main_country, type, COUNT(*) AS total
	FROM catalogo
	GROUP BY main_country, type
	ORDER BY total DESC;
    
    /* Top directores */
    SELECT director, COUNT(*) AS total
	FROM catalogo
	WHERE director IS NOT NULL
	GROUP BY director
	ORDER BY total DESC
	LIMIT 10;
    
    /* CREACION TABLA FINAL */
    
    DROP TABLE IF EXISTS catalogo_final;

CREATE TABLE catalogo_final AS
SELECT 
    show_id,
    type,
    title,
    director,
    cast_names,
    main_country,
    date_added,
    year_added,
    month_added,
    release_year,
    rating,
    duration_min,
    seasons,
    listed_in
FROM catalogo;

SELECT COUNT(*) FROM catalogo_final;

SELECT * FROM catalogo_final LIMIT 20;


/* KPIS */
/* kpi 1 total de contenido */

SELECT COUNT(*) AS total_contenido
FROM catalogo_final;

/* Porcentaje de peliculas vs series */

SELECT 
    type,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM catalogo_final), 2) AS porcentaje
FROM catalogo_final
GROUP BY type;

/* Duracion promedio de peliculas */

SELECT 
    ROUND(AVG(duration_min), 2) AS promedio_minutos
FROM catalogo_final
WHERE duration_min IS NOT NULL;

/* Promedio de temporadas */

SELECT 
    ROUND(AVG(seasons), 2) AS promedio_temporadas
FROM catalogo_final
WHERE seasons IS NOT NULL;

/* Año con mas contenido */

SELECT year_added, COUNT(*) AS total
FROM catalogo_final
GROUP BY year_added
ORDER BY total DESC
LIMIT 1;

/*. Pais con mas contenido */

SELECT main_country, COUNT(*) AS total
FROM catalogo_final
GROUP BY main_country
ORDER BY total DESC
LIMIT 1;

