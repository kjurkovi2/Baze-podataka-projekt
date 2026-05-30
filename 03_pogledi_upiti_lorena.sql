-- AUTOR: Lorena Pavličić

USE knjiznica;

-- ------------------------------------------------------------
-- POGLEDI
-- ------------------------------------------------------------

-- Pogled 1:
-- Prikazuje osnovni bibliografski katalog knjiga, 
-- uključujući podatke o knjizi, izdavaču i autoru.

CREATE OR REPLACE VIEW v_bibliografski_katalog AS
SELECT 
    k.id_knjiga,
    k.naslov,
    k.isbn,
    k.godina_izdanja,
    k.broj_stranica,
    i.naziv AS izdavac,
    i.drzava AS drzava_izdavaca,
    CONCAT(a.ime, ' ', a.prezime) AS autor,
    a.drzava AS drzava_autora,
    ka.redoslijed_autora
FROM knjiga k
JOIN izdavac i ON k.id_izdavac = i.id_izdavac
JOIN knjiga_autor ka ON k.id_knjiga = ka.id_knjiga
JOIN autor a ON ka.id_autor = a.id_autor;

-- Pogled 2:
-- Prikazuje broj knjiga po autoru

CREATE OR REPLACE VIEW v_broj_knjiga_po_autoru AS
SELECT
    a.id_autor,
    CONCAT(a.ime, ' ', a.prezime) AS autor,
    a.drzava,
    COUNT(ka.id_knjiga) AS broj_knjiga
FROM autor a
LEFT JOIN knjiga_autor ka ON a.id_autor = ka.id_autor
GROUP BY a.id_autor, a.ime, a.prezime, a.drzava;

-- Pogled 3:
-- Prikazuje broj autora po knjizi, 
-- uključujuči naziv izdavača.

CREATE OR REPLACE VIEW v_broj_autora_po_knjizi AS
SELECT
    k.id_knjiga,
    k.naslov,
    k.godina_izdanja,
    i.naziv AS izdavac,
    COUNT(ka.id_autor) AS broj_autora
FROM knjiga k
JOIN izdavac i ON k.id_izdavac = i.id_izdavac
LEFT JOIN knjiga_autor ka ON k.id_knjiga = ka.id_knjiga
GROUP BY k.id_knjiga, k.naslov, k.godina_izdanja, i.naziv;


-- ------------------------------------------------------------
-- SLOŽENI UPITI
-- ------------------------------------------------------------

-- Upit 1:
-- Prikazuje sve knjige određenog autora, uključujući izdavača,
-- godinu izdanja i ISBN.

SELECT
    CONCAT(a.ime, ' ', a.prezime) AS autor,
    k.naslov,
    k.isbn,
    k.godina_izdanja,
    i.naziv AS izdavac
FROM autor a
JOIN knjiga_autor ka ON a.id_autor = ka.id_autor
JOIN knjiga k ON ka.id_knjiga = k.id_knjiga
JOIN izdavac i ON k.id_izdavac = i.id_izdavac
WHERE a.prezime = 'Orwell'
ORDER BY k.godina_izdanja DESC;

-- Upit 2:
-- Prikazuje autore koji imaju dvije ili više knjiga u katalogu.

SELECT
    CONCAT(a.ime, ' ', a.prezime) AS autor,
    a.drzava,
    COUNT(ka.id_knjiga) AS broj_knjiga
FROM autor a
JOIN knjiga_autor ka ON a.id_autor = ka.id_autor
GROUP BY a.id_autor, a.ime, a.prezime, a.drzava
HAVING COUNT(ka.id_knjiga) >= 2
ORDER BY broj_knjiga DESC, autor;

-- Upit 3:
-- Prikazuje knjige koje imaju više od jednog autora.

SELECT
    k.naslov,
    k.godina_izdanja,
    i.naziv AS izdavac,
    COUNT(ka.id_autor) AS broj_autora
FROM knjiga k
JOIN izdavac i ON k.id_izdavac = i.id_izdavac
JOIN knjiga_autor ka ON k.id_knjiga = ka.id_knjiga
GROUP BY k.id_knjiga, k.naslov, k.godina_izdanja, i.naziv
HAVING COUNT(ka.id_autor) > 1
ORDER BY broj_autora DESC, k.naslov;
