-- Autor: Vice Jukić

USE knjiznica;

-- ===========================================================================================================
-- Pogled 1.
-- Nedostupni primjerci s pripadajućim knjigama, statusima i lokacijama

CREATE OR REPLACE VIEW analiza_nedostupnih_primjeraka AS
SELECT	p.id_primjerak,
		p.inventarni_broj,
		k.naslov,
		sp.naziv AS status_primjerka,
		sp.opis AS opis_statusa,
		l.odjel,
		l.polica,
		l.kat
	FROM primjerak AS p
	INNER JOIN knjiga AS k
		ON p.id_knjiga = k.id_knjiga
	INNER JOIN status_primjerka AS sp
		ON p.id_status = sp.id_status
	INNER JOIN lokacija AS l
		ON p.id_lokacija = l.id_lokacija
	WHERE sp.dostupan = FALSE;

-- Upit 1.
-- Odjeli i statusi primjeraka s natprosječnim brojem nedostupnih primjeraka

SELECT  anp.odjel,
		anp.kat,
		anp.status_primjerka,
		COUNT(anp.id_primjerak) AS broj_nedostupnih_primjeraka
	FROM analiza_nedostupnih_primjeraka AS anp
	WHERE anp.kat != 'Skladiste'
	GROUP BY anp.odjel, anp.kat, anp.status_primjerka
	HAVING COUNT(anp.id_primjerak) > 
		(
			SELECT AVG(broj_nedostupnih)
				FROM (
					SELECT COUNT(anp2.id_primjerak) AS broj_nedostupnih
						FROM analiza_nedostupnih_primjeraka AS anp2
						WHERE anp2.kat != 'Skladiste'
						GROUP BY anp2.odjel, anp2.status_primjerka
				) AS prosjek_nedostupnih
		)
	ORDER BY broj_nedostupnih_primjeraka DESC,
			 anp.odjel ASC,
			 anp.status_primjerka ASC;

-- ===========================================================================================================
-- Pregled 2.
-- Broj primjeraka po lokacijama unutar svakog odjela

CREATE OR REPLACE VIEW fond_po_odjelu AS
SELECT	l.id_lokacija,
		l.odjel,
		l.kat,
		COUNT(p.id_primjerak) AS broj_primjeraka
	FROM lokacija AS l
	LEFT JOIN primjerak AS p
		ON l.id_lokacija = p.id_lokacija
	GROUP BY l.id_lokacija, l.odjel, l.kat;

-- Upit 2.
-- Odjeli s natprosječnim ukupnim brojem primjeraka i osnovne statistike po lokaciji

SELECT	fpo.odjel,
		fpo.kat,
		SUM(fpo.broj_primjeraka) AS ukupan_broj_primjeraka,
		ROUND(AVG(fpo.broj_primjeraka), 2) AS prosjecan_broj_primjeraka,
		MAX(fpo.broj_primjeraka) AS najveci_broj_primjeraka_na_lokaciji,
		MIN(fpo.broj_primjeraka) AS najmanji_broj_primjeraka_na_lokaciji
	FROM fond_po_odjelu AS fpo
	GROUP BY fpo.odjel, fpo.kat
	HAVING SUM(fpo.broj_primjeraka) >
	(
		SELECT AVG(broj_primjeraka)
			FROM fond_po_odjelu
	)
	ORDER BY ukupan_broj_primjeraka DESC,
			 prosjecan_broj_primjeraka DESC,
			 fpo.odjel ASC;

-- ===========================================================================================================
-- Pregled 3.
-- Zastupljenost knjiga i primjeraka po žanrovima knjižničnog fonda

CREATE OR REPLACE VIEW analiza_fonda_po_zanru AS
SELECT	z.id_zanr,
		z.naziv AS naziv_zanra,
		COUNT(DISTINCT k.id_knjiga) AS broj_knjiga,
		COUNT(p.id_primjerak) AS broj_primjeraka
	FROM zanr AS z
	LEFT JOIN knjiga_zanr AS kz
		ON z.id_zanr = kz.id_zanr
	LEFT JOIN knjiga AS k
		ON kz.id_knjiga = k.id_knjiga
	LEFT JOIN primjerak AS p
		ON k.id_knjiga = p.id_knjiga
	GROUP BY z.id_zanr, z.naziv;

-- Upit 3.
-- Žanrovi s natprosječnim brojem primjeraka i prosjekom po knjizi

SELECT	afpz.naziv_zanra,
		afpz.broj_knjiga,
		afpz.broj_primjeraka,
		ROUND(
			afpz.broj_primjeraka * 1.0 / afpz.broj_knjiga, 2
		) AS prosjecan_broj_primjeraka_po_knjizi
	FROM analiza_fonda_po_zanru AS afpz
	WHERE afpz.broj_primjeraka > 
	(
		SELECT AVG(afpz2.broj_primjeraka)
			FROM analiza_fonda_po_zanru AS afpz2
	)
	AND afpz.broj_knjiga > 0
	ORDER BY afpz.broj_primjeraka DESC,
			 prosjecan_broj_primjeraka_po_knjizi DESC,
			 afpz.naziv_zanra ASC;