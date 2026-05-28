-- AUTOR: Lucija Baljak -----

USE biblioteka;


-- ================================================================
-- 1. POGLED: posudbe_detalji
-- ================================================================
-- pregled svake posudbe koji spaja podatke o clanu,primjerku, knjizi 
-- i neplacenim kaznama na jednom mjestu.
-- Podupit za kazne agregira neplacene iznose po posudbi kako bi
-- se izbjeglo dupliciranje redaka kada posudba ima vise kazni.

CREATE OR REPLACE VIEW posudbe_detalji AS
SELECT
    p.id_posudba,
    CONCAT(c.ime, ' ', c.prezime) AS clan,
    c.telefon,
    pk.inventarni_broj,
    k.naslov,
    p.datum_posudbe,
    p.rok_vracanja,
    p.status,
    GREATEST(DATEDIFF(COALESCE(p.datum_vracanja, CURDATE()), p.rok_vracanja), 0) AS dana_kasnjenja,
    COALESCE(kz.ukupni_dug, 0) AS ukupni_dug
FROM posudba AS p
INNER JOIN primjerak AS pk ON pk.id_primjerak = p.id_primjerak
INNER JOIN knjiga AS k ON pk.id_knjiga = k.id_knjiga
INNER JOIN clan AS c ON c.id_clan = p.id_clan
LEFT JOIN (
    SELECT
        ka.id_posudba,
        SUM(ka.iznos) AS ukupni_dug
    FROM kazna AS ka
    WHERE ka.placeno = FALSE
    GROUP BY ka.id_posudba
) AS kz ON p.id_posudba = kz.id_posudba;


-- ----------------------------------------------------------------
-- SELECT 1: Problematicne posudbe — aktivne koje kasne
-- ----------------------------------------------------------------
-- popis clanova koje treba kontaktirati jer kasne s vracanjem.
--  Rezultati su sortirani od najduzeg kasnjenja prema dolje — najhitniji slucajevi su na vrhu.

SELECT
    pd.clan,
    pd.telefon,
    pd.inventarni_broj,
    pd.naslov,
    pd.rok_vracanja,
    pd.dana_kasnjenja,
    pd.ukupni_dug
FROM posudbe_detalji AS pd
WHERE pd.status = 'Aktivno'
  AND pd.dana_kasnjenja > 0
ORDER BY pd.dana_kasnjenja DESC;


-- ================================================================
-- 2. POGLED: zaposlenici_statistika
-- ================================================================
-- Mjesecna statistika svakog zaposlenika.
-- Sluzi za godisnje evaluacije.

CREATE OR REPLACE VIEW zaposlenici_statistika AS
SELECT
    z.id_zaposlenik,
    CONCAT(z.ime, ' ', z.prezime) AS zaposlenik,
    z.radno_mjesto,
    z.datum_zaposlenja,
    DATE_FORMAT(p.datum_posudbe, '%Y') AS godina,
    DATE_FORMAT(p.datum_posudbe, '%Y-%m') AS mjesec,
    COUNT(DISTINCT p.id_posudba) AS izdano_knjiga,
    SUM(CASE WHEN p.datum_vracanja IS NOT NULL AND ka.id_kazna IS NULL THEN 1 ELSE 0 END) AS vraceno_bez_kazne,
    COUNT(DISTINCT CASE WHEN ka.id_kazna IS NOT NULL THEN p.id_posudba END) AS posudbi_s_kaznom,
    SUM(CASE WHEN rk.naziv_razloga = 'Kasnjenje' THEN 1 ELSE 0 END) AS kazni_kasnjenje,
    SUM(CASE WHEN rk.naziv_razloga = 'Ostecenje' THEN 1 ELSE 0 END) AS kazni_ostecenje,
    SUM(CASE WHEN rk.naziv_razloga = 'Gubitak' THEN 1 ELSE 0 END) AS kazni_gubitak,
    COALESCE(SUM(ka.iznos), 0) AS obracunato_kazni,
    COALESCE(SUM(CASE WHEN ka.placeno = TRUE THEN ka.iznos ELSE 0 END), 0) AS naplaceno_kazni
FROM zaposlenik AS z
INNER JOIN posudba AS p ON z.id_zaposlenik = p.id_zaposlenik
LEFT JOIN kazna AS ka ON p.id_posudba = ka.id_posudba
LEFT JOIN razlog_kazne AS rk ON rk.id_razlog = ka.id_razlog
GROUP BY z.id_zaposlenik, godina, mjesec;


-- ----------------------------------------------------------------
-- SELECT 2: Ucinkovitost zaposlenika — godisnji izvjestaj za 2025.
-- ----------------------------------------------------------------
-- Voditelj knjiznice na kraju godine rangira zaposlenike po aktivnosti
-- i kvaliteti rada. Filtrira se samo 2025. godina.

SELECT
    zs.id_zaposlenik,
    zs.zaposlenik,
    zs.radno_mjesto,
    zs.datum_zaposlenja,
    SUM(zs.izdano_knjiga) AS ukupno_izdano,
    SUM(zs.posudbi_s_kaznom) AS ukupno_s_kaznom,
    SUM(zs.kazni_kasnjenje) AS kasnjenja,
    SUM(zs.kazni_ostecenje) AS ostecenja,
    SUM(zs.kazni_gubitak) AS gubici,
    SUM(zs.obracunato_kazni) AS ukupno_obracunato,
    SUM(zs.naplaceno_kazni) AS ukupno_naplaceno,
    MAX(zs.izdano_knjiga) AS najbolji_mjesec
FROM zaposlenici_statistika AS zs
WHERE zs.godina = '2025'
GROUP BY zs.id_zaposlenik
ORDER BY ukupno_izdano DESC;


-- ================================================================
-- 3. POGLED: kazne_pregled
-- ================================================================
-- Pojednostavljeni pregled kazni za analizu. 
-- Sadrzi samo osnovne podatke: razlog, iznos, datum i status placanja.

CREATE OR REPLACE VIEW kazne_pregled AS
SELECT
    rk.naziv_razloga AS razlog,
    ka.iznos,
    ka.datum,
    CASE WHEN ka.placeno = TRUE THEN 'Placeno' ELSE 'Neplaceno' END AS status_placanja
FROM kazna AS ka
INNER JOIN razlog_kazne AS rk ON ka.id_razlog = rk.id_razlog;


-- ----------------------------------------------------------------
-- SELECT 3: Kronoloski ispisane kazne po mjesecima
-- ----------------------------------------------------------------
-- Kazne su razdvojene po tipu u stupcima za brzu usporedbu.
-- Kazna se pripisuje mjesecu u kojem je evidentirana.

SELECT
    DATE_FORMAT(kp.datum, '%Y-%m') AS mjesec,
    SUM(CASE WHEN kp.razlog = 'Kasnjenje' THEN 1 ELSE 0 END) AS broj_kasnjenja,
    SUM(CASE WHEN kp.razlog = 'Ostecenje' THEN 1 ELSE 0 END) AS broj_ostecenja,
    SUM(CASE WHEN kp.razlog = 'Gubitak' THEN 1 ELSE 0 END) AS broj_gubitaka,
    COUNT(*) AS ukupno_kazni,
    SUM(kp.iznos) AS ukupni_iznos,
    SUM(CASE WHEN kp.status_placanja = 'Neplaceno' THEN kp.iznos ELSE 0 END) AS neplaceni_iznos
FROM kazne_pregled AS kp
GROUP BY mjesec
ORDER BY mjesec;