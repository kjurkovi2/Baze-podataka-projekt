-- AUTOR: Kelvin Jurkovic

USE knjiznica;

-- 1.) Pogled prvi:
--     Prikazi zbirnu statistiku posudbi za svakog clana knjiznice,
--     ukljucujuci: ukupan broj posudbi, aktivne posudbe, vracene posudbe, zakasnjela vracanja i trenutno zakasnjele aktivne posudbe.

DROP VIEW IF EXISTS statistika_clanova;

CREATE VIEW statistika_clanova AS
SELECT
	c.id_clan,
    c.ime,
    c.prezime,
    c.email,
    
    c.status AS status_clana,
    COUNT(p.id_posudba) AS ukupan_broj_posudbi,
    
    SUM(
		CASE
			WHEN p.status = 'Aktivno' THEN 1
			ELSE 0
		END
	) AS broj_aktivnih_posudbi,
        
	SUM(
		CASE 
			WHEN p.status = 'Vraceno' then 1
            ELSE 0
		end
	) AS broj_vracenih_posudbi,
    
    SUM(
		CASE
			WHEN p.datum_vracanja IS NOT NULL AND p.datum_vracanja > p.rok_vracanja THEN 1
            ELSE 0
		END
	) AS broj_zakasnjelih_vracanja,
    
    SUM(
		CASE
			WHEN p.status = 'Aktivno' AND p.rok_vracanja < CURDATE()
            THEN 1
            ELSE 0
		END
	) AS trenutno_zakasnjele_posudbe,
    
    MAX(p.datum_posudbe) AS zadnja_posudba
    FROM clan AS c
    LEFT JOIN posudba AS p
		ON c.id_clan = p.id_clan
	GROUP BY
		c.id_clan,
        c.ime,
        c.prezime,
        c.email,
        c.status;
        
-- test
-- SELECT * FROM statistika_clanova ORDER BY ukupan_broj_posudbi DESC;
        
-- 2.) Pogled drugi:
--     Prikazi detalje svih aktivnih posudbi,
--     ukljucujuci: podatke o clanu, knjizi, primjerku i stanju roka vracanja.

DROP VIEW IF EXISTS aktivne_posudbe_detalji;

CREATE VIEW aktivne_posudbe_detalji AS
SELECT
	p.id_posudba,
    c.id_clan,
    c.ime AS ime_clana,
    c.prezime AS prezime_clana,
    k.id_knjiga,
    k.naslov,
    pr.id_primjerak,
    pr.inventarni_broj,
    p.datum_posudbe,
    p.rok_vracanja,
    
    -- pozitivna vrijednost -> rok je prosao
    DATEDIFF(CURDATE(), p.rok_vracanja) AS dani_nakon_roka,
    
    -- pozitivna vrijednost -> koliko dana preostaje do roka
	DATEDIFF(p.rok_vracanja, CURDATE()) AS dana_do_roka,
    
    CASE
		WHEN p.rok_vracanja < CURDATE() THEN 'Kasni'
        ELSE 'U roku'
	END AS stanje_roka
FROM posudba AS p
INNER JOIN clan as c
	ON p.id_clan = c.id_clan
INNER JOIN primjerak as pr
	ON p.id_primjerak = pr.id_primjerak
INNER JOIN knjiga as k
	ON pr.id_knjiga = k.id_knjiga
WHERE p.status = 'Aktivno';

-- test
-- SELECT * FROM aktivne_posudbe_detalji ORDER BY stanje_roka ASC, rok_vracanja ASC;

-- 3.) Pogled treci:
--     Povezi rezervacije s dostupnoscu primjeraka knjige, za svaku rezervaciju 
--     ukljuci: ukupan broj primjeraka, broj dostupnih primjeraka i broj aktivno posudenih primjeraka

DROP VIEW IF EXISTS rezervacije_dostupnost;

CREATE VIEW rezervacije_dostupnost AS 
SELECT
	r.id_rezervacija,
    c.id_clan,
    c.ime AS ime_clana,
    c.prezime as prezime_clana,
    k.id_knjiga,
    k.naslov,
    r.datum_rezervacije,
    r.status_rezervacije,
    
    COUNT(DISTINCT pr.id_primjerak) AS ukupan_broj_primjeraka,
    
    COUNT(
		DISTINCT CASE
			WHEN sp.naziv_statusa = 'Dostupno'
			THEN pr.id_primjerak
        END
	) AS broj_dostupnih_primjeraka,
    
    COUNT(
		DISTINCT CASE
			WHEN p.status = 'Aktivno'
            THEN pr.id_primjerak
		END
	) AS broj_aktivno_posudenih_primjeraka
    
FROM rezervacija as r
INNER JOIN clan as c 
	ON r.id_clan = c.id_clan
INNER JOIN knjiga as k
	ON r.id_knjiga = k.id_knjiga
LEFT JOIN primjerak as pr
	ON k.id_knjiga = pr.id_knjiga
LEFT JOIN status_primjerka AS sp
	ON pr.id_status = sp.id_status
LEFT JOIN posudba as p
	ON pr.id_primjerak = p.id_primjerak
	AND p.status = 'Aktivno'
GROUP BY
	r.id_rezervacija,
	c.id_clan,
	c.ime,
	c.prezime,
	k.id_knjiga,
	k.naslov,
	r.datum_rezervacije,
	r.status_rezervacije;
-- test
/*
SELECT *
FROM rezervacije_dostupnost
WHERE status_rezervacije = 'Aktivna' AND broj_dostupnih_primjeraka = 0;
*/


-- 4.) Upit prvi: clanovi sa iznadprosjecnim brojem aktivnih posudbi
--     Pronadi clanove koji trenutno imaju vise aktivnih posudbi od prosjeka.
--     Prosjek racunaj na temelju broja aktivnih posudbi po clanu.
--     Koristi pogled: statistika_clanova

SELECT
	sc.id_clan,
    sc.ime,
    sc.prezime,
    sc.email,
    sc.status_clana,
    sc.ukupan_broj_posudbi,
    sc.broj_aktivnih_posudbi,
    sc.broj_vracenih_posudbi,
    sc.broj_zakasnjelih_vracanja,
    sc.trenutno_zakasnjele_posudbe,
    sc.zadnja_posudba
    
FROM statistika_clanova as sc
WHERE sc.broj_aktivnih_posudbi > (
	SELECT AVG(broj_aktivnih_posudbi)
    FROM statistika_clanova
)
ORDER BY
	sc.broj_aktivnih_posudbi DESC,
    sc.trenutno_zakasnjele_posudbe DESC,
    sc.prezime ASC;
    

-- 5.) Upit drugi: aktivne posudbe koje kasne ili uskoro isticu
--     Prikazi aktivne posudbe koje zahtijevaju paznju zaposlenika jer kasne ili im rok vracanja istice unutar 5 dana.
--     Dodatno prikazi broj aktivnih rezervacija za istu knjigu.
--     Koristi pogled: aktivne_posudbe_detalji

SELECT
	apd.id_posudba,
    apd.id_clan,
    apd.ime_clana,
    apd.prezime_clana,
    apd.id_knjiga,
    apd.naslov,
    apd.id_primjerak,
    apd.inventarni_broj,
    apd.datum_posudbe,
    apd.rok_vracanja,
    apd.dani_nakon_roka,
    apd.dana_do_roka,
    apd.stanje_roka,
    (
    SELECT COUNT(*)
    FROM rezervacija as r
    WHERE r.id_knjiga = apd.id_knjiga AND r.status_rezervacije = 'Aktivna'
    ) AS broj_aktivnih_rezervacija_za_knjigu

FROM aktivne_posudbe_detalji as apd
WHERE apd.stanje_roka = 'Kasni' OR apd.dana_do_roka BETWEEN 0 AND 5
ORDER BY
	apd.stanje_roka ASC,
    apd.rok_vracanja ASC;
    
    
-- 6.) Upit treci: knjige s vise aktivnih rezervacija nego dostupnih primjeraka
--     Pronadi knjige za koje je potraznja veca nego trenutna dostupnost.
--     Prikazi koliko primjeraka nedostaje da bi se pokrile sve aktivne rezervacije.
--     Koristi pogled: rezervacije_dostupnost

SELECT
	rd.id_knjiga,
    rd.naslov,
    COUNT(rd.id_rezervacija) AS broj_aktivnih_rezervacija,
    MAX(rd.broj_dostupnih_primjeraka) AS broj_dostupnih_primjeraka,
    COUNT(rd.id_rezervacija) - MAX(rd.broj_dostupnih_primjeraka) AS manjak_primjeraka
    
FROM rezervacije_dostupnost AS rd
WHERE rd.status_rezervacije = 'Aktivna'
GROUP BY
	rd.id_knjiga,
    rd.naslov
HAVING COUNT(rd.id_rezervacija) > MAX(rd.broj_dostupnih_primjeraka)
ORDER BY manjak_primjeraka DESC;




    

    
    
    
    

    