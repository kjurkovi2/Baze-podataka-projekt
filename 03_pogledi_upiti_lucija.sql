-- AUTOR: Lucija Baljak

USE biblioteka;

--- 1.----

-- CREATE VIEW ----

CREATE OR REPLACE VIEW posudbe_detalji AS
SELECT 
    k.naslov,
    p.datum_posudbe,
    p.rok_vracanja,
    p.datum_vracanja,
    p.status,
    GREATEST(DATEDIFF(COALESCE(p.datum_vracanja, CURDATE()), p.rok_vracanja), 0) AS dana_kasnjenja,
    CASE 
        WHEN ka.id_kazna IS NULL THEN 'Nema kazne'
        WHEN ka.placeno = TRUE THEN 'Kazna placena'
        ELSE 'Kazna neplacena'
    END AS status_kazne,
    COALESCE(ka.iznos, 0) AS iznos_kazne
FROM posudba AS p
INNER JOIN primjerak AS pk ON pk.id_primjerak = p.id_primjerak
INNER JOIN knjiga AS k ON pk.id_knjiga = k.id_knjiga
LEFT JOIN kazna AS ka ON p.id_posudba = ka.id_posudba;


--- SELECT ------

SELECT 
    pd.status,
    COUNT(*) AS broj_posudbi,
    SUM(CASE WHEN pd.dana_kasnjenja > 0 THEN 1 ELSE 0 END) AS s_kasnjenjem,
    SUM(CASE WHEN pd.dana_kasnjenja = 0 THEN 1 ELSE 0 END) AS na_vrijeme,
    ROUND(AVG(pd.dana_kasnjenja), 1) AS prosjecno_kasnjenje,
    MAX(pd.dana_kasnjenja) AS najduze_kasnjenje
FROM posudbe_detalji AS pd
GROUP BY pd.status
ORDER BY broj_posudbi DESC;


---- 2. -----

---- CREATE VIEW -----

CREATE OR REPLACE VIEW zaposlenici_statistika AS
SELECT 
    z.id_zaposlenik,
    CONCAT(z.ime, ' ', z.prezime) AS zaposlenik,
    z.radno_mjesto,
    DATE_FORMAT(p.datum_posudbe, '%Y-%m') AS mjesec,
    COUNT(p.id_posudba) AS izdano_knjiga,
    SUM(CASE WHEN p.datum_vracanja IS NOT NULL AND k.id_kazna IS NULL THEN 1 ELSE 0 END) AS vraceno_bez_kazne,
    SUM(CASE WHEN k.id_kazna IS NOT NULL THEN 1 ELSE 0 END) AS vraceno_s_kaznom,
    COALESCE(SUM(k.iznos), 0) AS naplaceno_kazni
FROM zaposlenik AS z
INNER JOIN posudba AS p ON z.id_zaposlenik = p.id_zaposlenik
LEFT JOIN kazna AS k ON p.id_posudba = k.id_posudba
GROUP BY z.id_zaposlenik, z.ime, z.prezime, z.radno_mjesto, mjesec;


---- SELECT ----

SELECT 
    zs.zaposlenik,
    zs.radno_mjesto,
    COUNT(DISTINCT zs.mjesec) AS aktivnih_mjeseci,
    SUM(zs.izdano_knjiga) AS ukupno_izdano,
    ROUND(AVG(zs.izdano_knjiga), 1) AS prosjek_mjesecno,
    SUM(zs.vraceno_s_kaznom) AS ukupno_s_kaznom,
    SUM(zs.naplaceno_kazni) AS ukupno_naplaceno,
    MAX(zs.izdano_knjiga) AS najbolji_mjesec
FROM zaposlenici_statistika AS zs
GROUP BY zs.id_zaposlenik, zs.zaposlenik, zs.radno_mjesto
ORDER BY ukupno_izdano DESC;


-- 3. --

---- CREATE VIEW ----

CREATE OR REPLACE VIEW kazne_pregled AS
SELECT 
    ka.id_kazna,
    CONCAT(c.ime, ' ', c.prezime) AS clan,
    c.status AS status_clana,
    kn.naslov,
    ka.iznos,
    ka.datum,
    CASE WHEN ka.placeno = TRUE THEN 'Placeno' ELSE 'Neplaceno' END AS status_placanja
FROM kazna AS ka
INNER JOIN posudba AS p ON ka.id_posudba = p.id_posudba
INNER JOIN clan AS c ON p.id_clan = c.id_clan
INNER JOIN primjerak AS pk ON p.id_primjerak = pk.id_primjerak
INNER JOIN knjiga AS kn ON pk.id_knjiga = kn.id_knjiga;

---- SELECT -----


SELECT 
    kp.clan,
    kp.status_clana,
    kp.naslov,
    kp.iznos,
    kp.datum,
    kp.status_placanja
FROM kazne_pregled AS kp
WHERE kp.iznos > (SELECT AVG(iznos) FROM kazne_pregled)
ORDER BY kp.iznos DESC;