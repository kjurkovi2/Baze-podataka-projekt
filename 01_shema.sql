DROP DATABASE IF EXISTS biblioteka;
CREATE DATABASE biblioteka;
USE biblioteka;

CREATE TABLE autor (
    id_autor INT PRIMARY KEY AUTO_INCREMENT,
    ime VARCHAR(50) NOT NULL,
    prezime VARCHAR(50) NOT NULL,
    datum_rodenja DATE,
    drzava VARCHAR(50)
);

CREATE TABLE izdavac (
    id_izdavac INT PRIMARY KEY AUTO_INCREMENT,
    naziv VARCHAR(100) NOT NULL,
    drzava VARCHAR(50)
);

CREATE TABLE zanr (
    id_zanr INT PRIMARY KEY AUTO_INCREMENT,
    naziv_zanra VARCHAR(50) NOT NULL UNIQUE,
    opis VARCHAR(255)
);

CREATE TABLE status_primjerka (
    id_status INT PRIMARY KEY AUTO_INCREMENT,
    naziv_statusa VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE lokacija (
    id_lokacija INT PRIMARY KEY AUTO_INCREMENT,
    odjel VARCHAR(50) NOT NULL,
    polica VARCHAR(20) NOT NULL,
    kat VARCHAR(20)
);

CREATE TABLE clan (
    id_clan INT PRIMARY KEY AUTO_INCREMENT,
    ime VARCHAR(50) NOT NULL,
    prezime VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefon VARCHAR(30),
    datum_uclanjenja DATE NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE TABLE zaposlenik (
    id_zaposlenik INT PRIMARY KEY AUTO_INCREMENT,
    ime VARCHAR(50) NOT NULL,
    prezime VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    radno_mjesto VARCHAR(50) NOT NULL,
    datum_zaposlenja DATE NOT NULL
);

CREATE TABLE knjiga (
    id_knjiga INT PRIMARY KEY AUTO_INCREMENT,
    id_izdavac INT NOT NULL,
    naslov VARCHAR(150) NOT NULL,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    godina_izdanja INT,
    broj_stranica INT,

    FOREIGN KEY (id_izdavac) REFERENCES izdavac(id_izdavac)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (godina_izdanja IS NULL OR godina_izdanja > 0),
    CHECK (broj_stranica IS NULL OR broj_stranica > 0)
);

CREATE TABLE knjiga_autor (
    id_knjiga INT NOT NULL,
    id_autor INT NOT NULL,
    redoslijed_autora INT NOT NULL,

    PRIMARY KEY (id_knjiga, id_autor),

    FOREIGN KEY (id_knjiga) REFERENCES knjiga(id_knjiga)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (id_autor) REFERENCES autor(id_autor)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (redoslijed_autora > 0)
);

CREATE TABLE knjiga_zanr (
    id_knjiga INT NOT NULL,
    id_zanr INT NOT NULL,

    PRIMARY KEY (id_knjiga, id_zanr),

    FOREIGN KEY (id_knjiga) REFERENCES knjiga(id_knjiga)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (id_zanr) REFERENCES zanr(id_zanr)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE primjerak (
    id_primjerak INT PRIMARY KEY AUTO_INCREMENT,
    id_knjiga INT NOT NULL,
    id_lokacija INT NOT NULL,
    id_status INT NOT NULL,
    inventarni_broj VARCHAR(30) NOT NULL UNIQUE,
    datum_nabave DATE NOT NULL,

    FOREIGN KEY (id_knjiga) REFERENCES knjiga(id_knjiga)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (id_lokacija) REFERENCES lokacija(id_lokacija)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (id_status) REFERENCES status_primjerka(id_status)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE rezervacija (
    id_rezervacija INT PRIMARY KEY AUTO_INCREMENT,
    id_clan INT NOT NULL,
    id_knjiga INT NOT NULL,
    datum_rezervacije DATE NOT NULL,
    status_rezervacije VARCHAR(30) NOT NULL,

    FOREIGN KEY (id_clan) REFERENCES clan(id_clan)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (id_knjiga) REFERENCES knjiga(id_knjiga)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE posudba (
    id_posudba INT PRIMARY KEY AUTO_INCREMENT,
    id_clan INT NOT NULL,
    id_primjerak INT NOT NULL,
    id_zaposlenik INT NOT NULL,
    datum_posudbe DATE NOT NULL,
    rok_vracanja DATE NOT NULL,
    datum_vracanja DATE,
    status VARCHAR(30) NOT NULL,

    FOREIGN KEY (id_clan) REFERENCES clan(id_clan)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (id_primjerak) REFERENCES primjerak(id_primjerak)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik(id_zaposlenik)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (rok_vracanja >= datum_posudbe),
    CHECK (datum_vracanja IS NULL OR datum_vracanja >= datum_posudbe)
);

CREATE TABLE kazna (
    id_kazna INT PRIMARY KEY AUTO_INCREMENT,
    id_posudba INT NOT NULL UNIQUE,
    iznos NUMERIC(8,2) NOT NULL,
    datum DATE NOT NULL,
    placeno BOOLEAN NOT NULL DEFAULT FALSE,

    FOREIGN KEY (id_posudba) REFERENCES posudba(id_posudba)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CHECK (iznos >= 0)
);