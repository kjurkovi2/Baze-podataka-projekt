-- Autor: Vice Jukić

USE biblioteka;

-- POGLEDI --

-- 1. Pogled: problematični_primjerci
-- Prikazuje sve primjerke koji nisu dostupni za normalno korištenje.
-- Uključuje oštećene, izgubljene i rezervirane primjerke.

-- DOBAR
-- Pogled služi zaposlenicima za praćenje primjeraka koji nisu dostupni za
-- standardno korištenje kako bi se mogla planirati zamjena, popravak ili
-- reorganizacija fonda.
CREATE VIEW problematicni_primjerci AS
	SELECT p.id_primjerak, k.naslov, p.inventarni_broj, sp.naziv_statusa, l.odjel, l.polica, l.kat
	    FROM primjerak AS p
        INNER JOIN knjiga AS k
            ON p.id_knjiga = k.id_knjiga
        INNER JOIN status_primjerka AS sp
            ON p.id_status = sp.id_status
        INNER JOIN lokacija AS l
            ON p.id_lokacija = l.id_lokacija
        WHERE sp.naziv_statusa IN ('Osteceno', 'Izgubljeno', 'Rezervirano');

SELECT *
	FROM problematicni_primjerci
	WHERE kat = '1. kat';

-- 2. Pogled: knjige_po_zanru
-- Prikazuje broj knjiga u svakom žanru.
-- Uključuje i žanrove bez pridruženih knjiga.

-- ovdje bi bilo bolje da umjesto broj knjiga po žanru
-- napravim broj primjeraka po žanru
CREATE VIEW knjige_po_zanru AS
	SELECT z.id_zanr, z.naziv_zanra, COALESCE(COUNT(kz.id_knjiga), 0) AS broj_knjiga
		FROM zanr AS z
		LEFT JOIN knjiga_zanr AS kz
			ON z.id_zanr = kz.id_zanr
		GROUP BY z.id_zanr, z.naziv_zanra;

SELECT *
	FROM knjige_po_zanru
	WHERE broj_knjiga > 5
	ORDER BY broj_knjiga DESC;

-- 3. Pogled: fond_po_odjelu
-- Prikazuje ukupan broj primjeraka po odjelima knjižnice.

-- DOBAR
-- Možeš dodati:
-- broj dostupnih primjeraka
-- broj oštećenih po odjelu
CREATE VIEW fond_po_odjelu AS
	SELECT l.odjel, COUNT(p.id_primjerak) AS broj_primjeraka
		FROM lokacija AS l
		LEFT JOIN primjerak AS p
			ON l.id_lokacija = p.id_lokacija
		GROUP BY l.odjel;

SELECT *
	FROM fond_po_odjelu;

-- 4. Pogled: dostupni_primjerci
-- Prikazuje sve trenutno dostupne primjerke knjiga i njihove lokacije.

-- DOBAR
-- Malo je "listing" tip upita.
-- Nije loš, ali nije jako analitičan.
CREATE VIEW dostupni_primjerci AS
	SELECT k.naslov, p.inventarni_broj, l.odjel, l.polica, l.kat
		FROM knjiga AS k
		INNER JOIN primjerak AS p
			ON k.id_knjiga = p.id_knjiga
		INNER JOIN status_primjerka AS sp
			ON p.id_status = sp.id_status
		INNER JOIN lokacija AS l
			ON p.id_lokacija = l.id_lokacija
		WHERE sp.naziv_statusa = 'Dostupno';

SELECT *
	FROM dostupni_primjerci;

-- UPITI --

-- 1. Upit: prikaz svih oštećenih i izgubljenih primjeraka
-- Prikazuje primjerke knjiga koji imaju status 'Osteceno'
-- ili 'Izgubljeno'.
-- Upit služi zaposlenicima za evidenciju problematičnih primjeraka.

-- suvišan jer radi istu stvar kao i problematici_primjerci
-- nepotreban/umjetan union, školski je previše
-- za zadržati union treba mi dva seta različitih podataka
SELECT k.naslov, p.inventarni_broj, sp.naziv_statusa, l.odjel, l.polica
	FROM knjiga AS k
	INNER JOIN primjerak AS p
		ON k.id_knjiga = p.id_knjiga
	INNER JOIN status_primjerka AS sp
		ON p.id_status = sp.id_status
	INNER JOIN lokacija AS l
		ON p.id_lokacija = l.id_lokacija
	WHERE sp.naziv_statusa = 'Osteceno'

UNION

SELECT k.naslov, p.inventarni_broj, sp.naziv_statusa, l.odjel, l.polica
	FROM knjiga AS k
	INNER JOIN primjerak AS p
		ON k.id_knjiga = p.id_knjiga
	INNER JOIN status_primjerka AS sp
		ON p.id_status = sp.id_status
	INNER JOIN lokacija AS l
		ON p.id_lokacija = l.id_lokacija
	WHERE sp.naziv_statusa = 'Izgubljeno';

-- 2. Upit: prikaz svih žanrova i broja knjiga u svakom žanru
-- Prikazuje sve žanrove, uključujući i one koji trenutno nemaju knjige.
-- COALESCE funkcija prikazuje vrijednost 0 za žanrove bez knjiga.

SELECT z.naziv_zanra, COALESCE(COUNT(kz.id_knjiga), 0) AS broj_knjiga
	FROM zanr AS z
	LEFT JOIN knjiga_zanr AS kz
		ON z.id_zanr = kz.id_zanr
	GROUP BY z.id_zanr, z.naziv_zanra
	ORDER BY broj_knjiga DESC;

-- 3. Upit: knjige nabavljene između 2023. i 2025. godine
-- Prikazuje primjerke knjiga koji su nabavljeni
-- između 1.1.2023. i 31.12.2025.
-- Upit služi za pregled novijih nabava knjižničnog fonda.

-- najslabiji upit, forsiran BETWEEN, školski
-- bolje je: "Analiza novih nabava po odjelima"
-- ili
-- "Pregled recentno nabavljenih primjeraka radi planiranja fonda"
-- "Koji odjeli imaju najviše novih nabava?"
SELECT k.naslov, p.inventarni_broj, p.datum_nabave, l.odjel
	FROM knjiga AS k
	INNER JOIN primjerak AS p
		ON k.id_knjiga = p.id_knjiga
	INNER JOIN lokacija AS l
		ON p.id_lokacija = l.id_lokacija
	WHERE p.datum_nabave BETWEEN '2023-01-01' AND '2025-12-31'
	ORDER BY p.datum_nabave DESC;

-- 4. Upit: oštećeni ili rezervirani primjerci na drugom katu
-- Prikazuje primjerke knjiga koji imaju status
-- 'Osteceno' ili 'Rezervirano'
-- i nalaze se na 1. katu knjižnice.
-- Upit služi za evidenciju problematičnih primjeraka po lokaciji.

-- solidno, ali preusko
-- pretvoriti ga u "Analiza problematičnih primjeraka po lokaciji"
SELECT k.naslov, p.inventarni_broj, sp.naziv_statusa, l.odjel, l.polica, l.kat
	FROM knjiga AS k
	INNER JOIN primjerak AS p
		ON k.id_knjiga = p.id_knjiga
	INNER JOIN status_primjerka AS sp
		ON p.id_status = sp.id_status
	INNER JOIN lokacija AS l
		ON p.id_lokacija = l.id_lokacija
	WHERE (sp.naziv_statusa = 'Osteceno' OR sp.naziv_statusa = 'Rezervirano') AND l.kat = '2. kat'
	ORDER BY l.kat, l.odjel, k.naslov;
