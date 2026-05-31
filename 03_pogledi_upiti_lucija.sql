-- AUTOR: Lucija Baljak --

USE knjiznica;


-- 1. POGLED: izracun_kazne
-- Pregled aktivnih posudbi s kašnjenjem i izračunatim iznosom kazne.
-- Namijenjen knjižničaru za evidenciju i zaprimanje povratka određenog primjerka knjige.
-- Omogućuje brzi pregled svih kašnjenja i iznosa koji treba naplatiti


CREATE OR REPLACE VIEW izracun_kazne AS
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
SELECT * FROM izracun_kazne;


-- SELECT 1: Pregled kašnjenja po članu i inventarnom broju primjerka
-- Knjižničar pretražuje po id_clan i inventarnom broju
-- kako bi vidio aktivnu posudbu i da li postoji kašnjenje

SELECT
	ik.id_clan,
    ik.clan,
    ik.inventarni_broj,
    ik.naslov,
    ik.rok_vracanja,
    ik.dana_kasnjenja,
    ik.izracunata_kazna
FROM izracun_kazne AS ik
WHERE ik.id_clan = 1
  AND ik.inventarni_broj = "INV-0041";

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
    COUNT(p.id_posudba) AS izdano_knjiga
FROM zaposlenik AS z
INNER JOIN posudba AS p ON z.id_zaposlenik = p.id_zaposlenik
GROUP BY z.id_zaposlenik, godina, mjesec;

-- TEST
SELECT * FROM zaposlenici_statistika;



-- SELECT 2: Ucinkovitost zaposlenika — godisnji izvjestaj za 2025.
-- Voditelj knjiznice na kraju godine rangira zaposlenike po aktivnosti
-- i kvaliteti rada. Filtrira se samo 2025. godina.

SELECT
    zs.id_zaposlenik,
    zs.zaposlenik,
    zs.radno_mjesto,
    zs.datum_zaposlenja,
    SUM(zs.izdano_knjiga) AS ukupno_izdano,
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
SELECT * FROM kazne_pregled;


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