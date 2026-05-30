-- AUTOR: Lucija Baljak -----

USE knjiznica;


-- 1. POGLED: ocekivane_kazne
-- Pregled aktivnih posudbi s kašnjenjem i izračunatim iznosom kazne.
-- Namijenjen knjižničaru pri dolasku člana po novu posudbu —
-- omogućuje brzi pregled svih kašnjenja i iznosa koji treba naplatiti
-- prije kreiranja nove posudbe.

CREATE OR REPLACE VIEW ocekivane_kazne AS
SELECT
    c.id_clan,
    CONCAT(c.ime, ' ', c.prezime) AS clan,
    pk.inventarni_broj,
    k.naslov,
    p.rok_vracanja,
    DATEDIFF(CURDATE(), p.rok_vracanja) AS dana_kasnjenja,
    rk.osnovna_cijena,
    DATEDIFF(CURDATE(), p.rok_vracanja) * rk.osnovna_cijena AS izracunata_kazna
FROM posudba AS p
INNER JOIN primjerak AS pk ON pk.id_primjerak = p.id_primjerak
INNER JOIN knjiga AS k ON pk.id_knjiga = k.id_knjiga
INNER JOIN clan AS c ON c.id_clan = p.id_clan
CROSS JOIN razlog_kazne AS rk
WHERE p.status = 'Aktivno'
  AND DATEDIFF(CURDATE(), p.rok_vracanja) > 0
  AND rk.naziv_razloga = 'Kasnjenje';

-- TEST
-- SELECT * FROM ocekivane_kazne


-- SELECT 1: Pregled kašnjenja po članu
-- Knjižničar pretražuje po id_clan ili inventarnom broju
-- kako bi vidio sve aktivne posudbe s kašnjenjem i iznosom kazne
-- prije odobravanja nove posudbe.

SELECT
    ok.clan,
    ok.inventarni_broj,
    ok.naslov,
    ok.rok_vracanja,
    ok.dana_kasnjenja,
    ok.osnovna_cijena,
    ok.izracunata_kazna
FROM ocekivane_kazne AS ok
WHERE ok.id_clan = 1
ORDER BY ok.dana_kasnjenja DESC;

-- 2. POGLED: zaposlenici_statistika
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

-- TEST
-- SELECT * FROM zaposlenici_statistika


-- SELECT 2: Ucinkovitost zaposlenika — godisnji izvjestaj za 2025.
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



-- 3. POGLED: kazne_pregled
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

-- TEST 
-- SELECT * FROM kazne_pregled


-- SELECT 3: Kronoloski ispisane kazne po mjesecima
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