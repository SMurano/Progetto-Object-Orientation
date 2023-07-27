	
CREATE DOMAIN galleriafotograficacondivisa.NomeAlfaNumerico AS VARCHAR(30)
	CHECK(VALUE ~ '^[a-zA-Z0-9_# ]*$');

CREATE DOMAIN galleriafotograficacondivisa.NomeCongnomeUtente AS VARCHAR(30)
	CHECK(VALUE ~ '^[a-zA-Z ]*$');

CREATE DOMAIN galleriafotograficacondivisa.VisibilitaFoto AS VARCHAR(10)
	CHECK(VALUE='pubblico' OR VALUE='privato');
	
CREATE DOMAIN galleriafotograficacondivisa.CategoriaSoggetto As VARCHAR(20)
	CHECK(VALUE IN('luogo','utente','selfie','foto di gruppo','fiera','altro'));	

CREATE TABLE galleriafotograficacondivisa.GALLERIAPERSONALE
(CodGP    SERIAL     NOT NULL,
NomeGP    galleriafotograficacondivisa.NomeAlfaNumerico NOT NULL,
PRIMARY KEY (CodGP));

CREATE TABLE galleriafotograficacondivisa.GALLERIACONDIVISA
(CodGC    SERIAL     NOT NULL,
NomeGC    galleriafotograficacondivisa.NomeAlfaNumerico NOT NULL,
PRIMARY KEY (CodGC));

CREATE TABLE galleriafotograficacondivisa.UTENTE    
(Nome    galleriafotograficacondivisa.NomeCongnomeUtente,
Cognome  galleriafotograficacondivisa.NomeCongnomeUtente,  
Nickname galleriafotograficacondivisa.NomeAlfaNumerico  NOT NULL,
Pass     galleriafotograficacondivisa.NomeAlfaNumerico  NOT NULL,
CodGP    SERIAL      NOT NULL,
PRIMARY KEY (Nickname),
FOREIGN KEY (CodGP) REFERENCES galleriafotograficacondivisa.GALLERIAPERSONALE(CodGP));

CREATE TABLE galleriafotograficacondivisa.LUOGO
(Latitudine	 DECIMAL(9,6),
Longitudine	 DECIMAL(9,6),
NomeLuogo    galleriafotograficacondivisa.NomeAlfaNumerico,
PRIMARY KEY (NomeLuogo));

CREATE TABLE galleriafotograficacondivisa.FOTO
(CodFoto	 SERIAL      NOT NULL,
Dispositivo	 VARCHAR(30)  NOT NULL,
DimAltezza   DECIMAL(6,2),
DimLarghezza DECIMAL(6,2),
NomeFoto     galleriafotograficacondivisa.NomeAlfaNumerico  NOT NULL,
Nfotografo   VARCHAR(30)  NOT NULL,
NomeLuogo    galleriafotograficacondivisa.NomeAlfaNumerico,
TipoFoto     galleriafotograficacondivisa.VisibilitaFoto  NOT NULL,
DataScatto   DATE,
PRIMARY KEY (CodFoto),
FOREIGN KEY (Nfotografo) REFERENCES galleriafotograficacondivisa.UTENTE(Nickname),
FOREIGN KEY(NomeLuogo) REFERENCES galleriafotograficacondivisa.LUOGO(NomeLuogo));

CREATE TABLE galleriafotograficacondivisa.SOGGETTO
(CodSoggetto	 SERIAL      NOT NULL,
Tipo	         galleriafotograficacondivisa.CategoriaSoggetto  NOT NULL,
NomeSoggetto     VARCHAR(30)  NOT NULL,
PRIMARY KEY (CodSoggetto));

CREATE TABLE galleriafotograficacondivisa.CONTENIMENTO
(CodFoto	INTEGER			NOT NULL,
CodGP		INTEGER			NOT NULL,
PRIMARY KEY (CodFoto, CodGP),
FOREIGN KEY (CodFoto) REFERENCES galleriafotograficacondivisa.FOTO(CodFoto),
FOREIGN KEY (CodGP) REFERENCES galleriafotograficacondivisa.GALLERIAPERSONALE(CodGP));

CREATE TABLE galleriafotograficacondivisa.RAPPRESENTAZIONE
(NomeLuogo   galleriafotograficacondivisa.NomeAlfaNumerico,
CodSoggetto	 INTEGER          NOT NULL,
PRIMARY KEY (NomeLuogo,CodSoggetto),
FOREIGN KEY (NomeLuogo) REFERENCES galleriafotograficacondivisa.LUOGO(NomeLuogo),
FOREIGN KEY (CodSoggetto) REFERENCES galleriafotograficacondivisa.SOGGETTO(CodSoggetto));

CREATE TABLE galleriafotograficacondivisa.AFFERENZA          
(CodFoto	 INTEGER   NOT NULL,
CodSoggetto	 INTEGER   NOT NULL,
PRIMARY KEY (CodFoto,CodSoggetto),
FOREIGN KEY (CodFoto) REFERENCES galleriafotograficacondivisa.FOTO(CodFoto),
FOREIGN KEY (CodSoggetto) REFERENCES galleriafotograficacondivisa.SOGGETTO(CodSoggetto));

CREATE TABLE galleriafotograficacondivisa.RITRAE
(CodSoggetto	 INTEGER       NOT NULL,
Nickname         VARCHAR(30)   NOT NULL,
PRIMARY KEY (CodSoggetto, Nickname),
FOREIGN KEY (CodSoggetto) REFERENCES galleriafotograficacondivisa.SOGGETTO(CodSoggetto),
FOREIGN KEY (Nickname) REFERENCES galleriafotograficacondivisa.UTENTE(Nickname));

CREATE TABLE galleriafotograficacondivisa.PARTECIPAZIONE
(Nickname   VARCHAR(30)   NOT NULL,
CodGC       INTEGER       NOT NULL, 
PRIMARY KEY (Nickname, CodGC),
FOREIGN KEY (Nickname) REFERENCES galleriafotograficacondivisa.UTENTE(Nickname),
FOREIGN KEY (CodGC) REFERENCES galleriafotograficacondivisa.GALLERIACONDIVISA(CodGC));

CREATE TABLE galleriafotograficacondivisa.CONDIVISIONE
(CodFoto	 INTEGER    NOT NULL,
CodGC        INTEGER    NOT NULL, 
ElencoUtenti VARCHAR(255),
PRIMARY KEY (CodFoto, CodGC),
FOREIGN KEY (CodFoto) REFERENCES galleriafotograficacondivisa.FOTO(CodFoto),
FOREIGN KEY (CodGC) REFERENCES galleriafotograficacondivisa.GALLERIACONDIVISA(CodGC));

ALTER TABLE galleriafotograficacondivisa.luogo
 	ADD CONSTRAINT CoordinateLuogo UNIQUE (Latitudine, Longitudine);

CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.CreazioneGalleriaPersonale() RETURNS TRIGGER AS $CreazioneGalleriaPersonale$
	BEGIN 
		INSERT INTO galleriafotograficacondivisa.galleriapersonale VALUES(NEW.CodGP,CONCAT('GALLERIA DI ',NEW.Nickname));
		RETURN NEW;
	END;
$CreazioneGalleriaPersonale$ LANGUAGE plpgsql;

CREATE TRIGGER CreazioneGalleriaPersonale BEFORE INSERT ON galleriafotograficacondivisa.Utente
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.CreazioneGalleriaPersonale();

CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaFoto() RETURNS TRIGGER AS $EliminaFoto$
	BEGIN
		IF (NOT EXISTS(SELECT F.CodFoto
					FROM galleriafotograficacondivisa.FOTO AS F JOIN galleriafotograficacondivisa.Contenimento AS C
					on F.CodFoto=C.CodFoto
					WHERE F.CodFoto=OLD.CodFoto)
			AND	NOT EXISTS(SELECT F.CodFoto
						 FROM galleriafotograficacondivisa.FOTO AS F JOIN galleriafotograficacondivisa.Condivisione AS C
						 on F.CodFoto=C.CodFoto
						 WHERE F.CodFoto=OLD.CodFoto))
		THEN 
			DELETE FROM galleriafotograficacondivisa.FOTO AS F WHERE F.CodFoto=OLD.CodFoto;
		END IF;
		RETURN NEW;
	END;
$EliminaFoto$ LANGUAGE plpgsql;

CREATE TRIGGER EliminaFoto AFTER DELETE ON galleriafotograficacondivisa.Contenimento
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaFoto();

CREATE TRIGGER EliminaFoto2 AFTER DELETE ON galleriafotograficacondivisa.Condivisione
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaFoto();



CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.RinominaGalleriaCondivisa() RETURNS TRIGGER AS $RinominaGalleriaCondivisa$
BEGIN
	NEW.NomeGC=CONCAT(NEW.NomeGC,' #',NEW.CodGC);
	RETURN NEW;
END
$RinominaGalleriaCondivisa$ LANGUAGE plpgsql;

CREATE TRIGGER RinominaGalleriaCondivisa BEFORE INSERT ON galleriafotograficacondivisa.galleriacondivisa
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.RinominaGalleriaCondivisa();



CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaLuogo() RETURNS TRIGGER AS $EliminaLuogo$
	BEGIN
		IF (NOT EXISTS(SELECT NomeLuogo
					FROM galleriafotograficacondivisa.Luogo NATURAL JOIN galleriafotograficacondivisa.Rappresentazione
					WHERE NomeLuogo=OLD.NomeLuogo)
			AND	NOT EXISTS(SELECT NomeLuogo
						 FROM galleriafotograficacondivisa.FOTO 
						 WHERE NomeLuogo=OLD.NomeLuogo))
		THEN 
			DELETE FROM galleriafotograficacondivisa.Luogo WHERE NomeLuogo=OLD.NomeLuogo;
		END IF;
		RETURN NEW;
	END;
$EliminaLuogo$ LANGUAGE plpgsql;

CREATE TRIGGER EliminaLuogo AFTER DELETE ON galleriafotograficacondivisa.Foto
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaLuogo();

CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaSoggetto() RETURNS TRIGGER AS $EliminaSoggetto$
DECLARE 
	elencoSoggetti CURSOR FOR 	(SELECT codSoggetto 
								FROM galleriafotograficacondivisa.AFFERENZA AS A
								WHERE A.CodFoto=OLD.codFoto);
	soggettoCorrente INTEGER;
	BEGIN
		OPEN elencoSoggetti;
			LOOP
				FETCH elencoSoggetti INTO soggettoCorrente;
				IF (NOT FOUND) 
				THEN EXIT;
				END IF;
				DELETE FROM galleriafotograficacondivisa.Afferenza WHERE (codSoggetto=soggettoCorrente AND codFoto=OLD.codFoto);
				IF (NOT EXISTS(SELECT *
						       FROM galleriafotograficacondivisa.Soggetto NATURAL JOIN galleriafotograficacondivisa.Afferenza
						       WHERE codSoggetto=soggettoCorrente))

				THEN 
					DELETE FROM galleriafotograficacondivisa.Ritrae WHERE (codSoggetto=soggettoCorrente);
					DELETE FROM galleriafotograficacondivisa.Rappresentazione WHERE (codSoggetto=soggettoCorrente);
					DELETE FROM galleriafotograficacondivisa.Soggetto WHERE (codSoggetto=soggettoCorrente);
				END IF;
			END LOOP;
		CLOSE elencoSoggetti;
		RETURN OLD;
	END;
$EliminaSoggetto$ LANGUAGE plpgsql;

CREATE TRIGGER EliminaSoggetto BEFORE DELETE ON galleriafotograficacondivisa.Foto
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaSoggetto();



CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.CreaElencoUtenti() RETURNS TRIGGER AS $CreaElencoUtenti$
DECLARE 
	elencoNickname CURSOR FOR 	(SELECT Nickname 
								FROM galleriafotograficacondivisa.GALLERIACONDIVISA
								NATURAL JOIN galleriafotograficacondivisa.PARTECIPAZIONE
								NATURAL JOIN galleriafotograficacondivisa.UTENTE
								WHERE CodGC=NEW.CodGC);
	utenteCorrente VARCHAR(30);
BEGIN
	NEW.ElencoUtenti='';
	OPEN elencoNickname;
		LOOP
			FETCH elencoNickname INTO utenteCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
			NEW.ElencoUtenti= CONCAT(NEW.ElencoUtenti,utenteCorrente,', ');
		END LOOP;
	CLOSE elencoNickname;
RETURN NEW;
END;
$CreaElencoUtenti$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER CreaElencoUtenti BEFORE INSERT ON galleriafotograficacondivisa.Condivisione
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.CreaElencoUtenti();



CREATE OR REPLACE PROCEDURE galleriafotograficacondivisa.EliminaUtenteDaElenco(Utente VARCHAR(30), Foto Integer, GalleriaCondivisa Integer) 
LANGUAGE plpgsql 
AS $$
BEGIN
	UPDATE galleriafotograficacondivisa.CONDIVISIONE
	SET ElencoUtenti=REPLACE(ElencoUtenti,CONCAT(Utente,', '),'')
	WHERE (CodFoto = Foto AND CodGC = GalleriaCOndivisa);
	DELETE FROM galleriafotograficacondivisa.CONDIVISIONE
	WHERE ElencoUtenti='';
END;
$$;



CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.FiltraFotoPerLuogo(Utente VARCHAR(30), Luogo VARCHAR(30)) RETURNS REFCURSOR AS $$

DECLARE 
	elencoFoto REFCURSOR;
BEGIN
	OPEN elencoFoto FOR    (SELECT F.codFoto, F.Dispositivo, F.DimAltezza, F.DimLarghezza, F.NomeFoto, F.Nfotografo, F.DataScatto,GC.NomeGC
						   FROM galleriafotograficacondivisa.FOTO AS F 
						   JOIN galleriafotograficacondivisa.CONDIVISIONE AS CO 
						   ON F.CodFoto=CO.CodFoto
						   JOIN galleriafotograficacondivisa.GALLERIACONDIVISA AS GC
						   ON CO.CodGC=GC.CodGC
						   JOIN galleriafotograficacondivisa.PARTECIPAZIONE AS P
						   ON GC.CODGC=P.CODGC
						   WHERE F.NomeLuogo=Luogo AND P.nickname=Utente

						   UNION					
						   	   
						   SELECT F.codFoto, F.Dispositivo, F.DimAltezza, F.DimLarghezza, F.NomeFoto, F.Nfotografo, F.DataScatto,GP.NomeGP
						   FROM galleriafotograficacondivisa.FOTO AS F 						   
						   JOIN galleriafotograficacondivisa.CONTENIMENTO AS C 
						   ON F.codFoto=C.codFoto 
						   JOIN galleriafotograficacondivisa.GALLERIAPERSONALE AS GP
						   ON C.CodGP=GP.CodGP
						   WHERE GP.NomeGP=CONCAT('GALLERIA DI ',Utente) AND F.NomeLuogo=Luogo);
	CLOSE elencoFoto;
	RETURN elencoFoto;
END;
$$
LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.FiltraFotoPerSoggetto(Utente VARCHAR(30), NomeSoggetto VARCHAR(30), TipoSoggetto VARCHAR(30)) RETURNS REFCURSOR AS $$

DECLARE 
	elencoFoto REFCURSOR;
BEGIN
	OPEN elencoFoto FOR    (SELECT F.codFoto, F.Dispositivo, F.DimAltezza, F.DimLarghezza, F.NomeFoto, F.Nfotografo, F.DataScatto,GC.NomeGC
						   FROM galleriafotograficacondivisa.FOTO AS F 
						   JOIN galleriafotograficacondivisa.CONDIVISIONE AS CO 
						   ON F.CodFoto=CO.CodFoto
						   JOIN galleriafotograficacondivisa.GALLERIACONDIVISA AS GC
						   ON CO.CodGC=GC.CodGC
						   JOIN galleriafotograficacondivisa.PARTECIPAZIONE AS P
						   ON GC.CODGC=P.CODGC
						   JOIN galleriafotograficacondivisa.AFFERENZA AS A
						   ON F.CodFoto=A.CodFoto
						   JOIN galleriafotograficacondivisa.SOGGETTO AS S
						   ON A.CodSoggetto=S.CodSoggetto
						   WHERE (S.NomeSoggetto=NomeSoggetto AND S.Tipo=TipoSoggetto) AND P.nickname=Utente

						   UNION					
						   	   
						   SELECT F.codFoto, F.Dispositivo, F.DimAltezza, F.DimLarghezza, F.NomeFoto, F.Nfotografo, F.DataScatto,GP.NomeGP
						   FROM galleriafotograficacondivisa.FOTO AS F 						   
						   JOIN galleriafotograficacondivisa.CONTENIMENTO AS C 
						   ON F.codFoto=C.codFoto 
						   JOIN galleriafotograficacondivisa.GALLERIAPERSONALE AS GP
						   ON C.CodGP=GP.CodGP
						   JOIN galleriafotograficacondivisa.AFFERENZA AS A
						   ON F.CodFoto=A.CodFoto
						   JOIN galleriafotograficacondivisa.SOGGETTO AS S
						   ON A.CodSoggetto=S.CodSoggetto
						   WHERE GP.NomeGP=CONCAT('GALLERIA DI ',Utente) AND (S.NomeSoggetto=NomeSoggetto AND S.Tipo=TipoSoggetto));
	CLOSE elencoFoto;
	RETURN elencoFoto;
END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.Top3LuoghiPiuImmortalati()  RETURNS TRIGGER AS $AggiornaTop3LuoghiPiuImmortalati$

DECLARE
BEGIN
	CREATE OR REPLACE VIEW galleriafotograficacondivisa.Top3Luoghi AS
	SELECT L.NomeLuogo,COUNT (DISTINCT(F.CodFoto))
						   FROM galleriafotograficacondivisa.LUOGO AS L
						   NATURAL JOIN galleriafotograficacondivisa.RAPPRESENTAZIONE AS R
						   NATURAL JOIN galleriafotograficacondivisa.SOGGETTO AS S
						   NATURAL JOIN galleriafotograficacondivisa.AFFERENZA AS A
						   JOIN galleriafotograficacondivisa.foto AS F
						   ON F.codfoto = A.codfoto
						   GROUP BY(L.NomeLuogo)
						   ORDER BY (COUNT (F.CodFoto)) DESC
						   LIMIT 3;
	RETURN NEW;			   
END;
$AggiornaTop3LuoghiPiuImmortalati$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER AggiornaTop3LuoghiPiuImmortalati AFTER INSERT ON galleriafotograficacondivisa.SOGGETTO
FOR EACH ROW 
WHEN (NEW.Tipo='luogo')
EXECUTE PROCEDURE galleriafotograficacondivisa.Top3LuoghiPiuImmortalati();



CREATE OR REPLACE PROCEDURE galleriafotograficacondivisa.VisualizzaTop3LuoghiPiuImmortalati() AS $$
BEGIN
	SELECT * FROM galleriafotograficacondivisa.Top3Luoghi; 
END;
$$
LANGUAGE plpgsql;



/*in un sistema più complesso, il controllo di eventuali soggetti liberi viene fatta periodicamente (tipo ogni mese) invece che ad ogni inserimento per rendere il sistema più efficiente*/
CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaSoggettoLibero() RETURNS TRIGGER AS $EliminaSoggettoLibero$
DECLARE 
	elencoSoggetti CURSOR FOR (SELECT S.CodSoggetto 
							  FROM galleriafotograficacondivisa.Soggetto AS S
							  WHERE S.codSoggetto NOT IN(SELECT CodSoggetto
														FROM galleriafotograficacondivisa.AFFERENZA));
	soggettoCorrente INTEGER;
BEGIN
	OPEN elencoSoggetti;
		LOOP
			FETCH elencoSoggetti INTO soggettoCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
				DELETE FROM galleriafotograficacondivisa.Ritrae WHERE (codSoggetto=soggettoCorrente);
				DELETE FROM galleriafotograficacondivisa.Rappresentazione WHERE (codSoggetto=soggettoCorrente);
				DELETE FROM galleriafotograficacondivisa.Soggetto WHERE (codSoggetto=soggettoCorrente);
		END LOOP;
	CLOSE elencoSoggetti;
	RETURN NEW;
END;
$EliminaSoggettoLibero$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER EliminaSoggettoLibero BEFORE INSERT ON galleriafotograficacondivisa.Soggetto
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaSoggettoLibero();



/*in un sistema più complesso, il controllo di eventuali luoghi liberi viene fatta periodicamente (tipo ogni mese) invece che ad ogni inserimento per rendere il sistema più efficiente*/
CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaLuogoLibero() RETURNS TRIGGER AS $EliminaLuogoLibero$
DECLARE 
	elencoLuoghi CURSOR FOR (SELECT L.NomeLuogo 
							FROM galleriafotograficacondivisa.Luogo AS L
							WHERE L.NomeLuogo NOT IN(SELECT NomeLuogo
													 FROM galleriafotograficacondivisa.Foto));
	luogoCorrente VARCHAR(30);
BEGIN
	OPEN elencoLuoghi;
		LOOP
			FETCH elencoLuoghi INTO luogoCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
				DELETE FROM galleriafotograficacondivisa.Rappresentazione WHERE (NomeLuogo=luogoCorrente);
				DELETE FROM galleriafotograficacondivisa.Luogo WHERE (NomeLuogo=luogoCorrente);
		END LOOP;
	CLOSE elencoLuoghi;
	RETURN NEW;
END;
$EliminaLuogoLibero$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER EliminaLuogoLibero BEFORE INSERT ON galleriafotograficacondivisa.Luogo
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaLuogoLibero();



/*in un sistema più complesso, il controllo di eventuali fotografie libere viene fatta periodicamente (tipo ogni mese) invece che ad ogni inserimento per rendere il sistema più efficiente*/
CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaFotoLibera() RETURNS TRIGGER AS $EliminaFotoLibera$
DECLARE 
	elencoFoto CURSOR FOR (SELECT F.CodFoto 
						  FROM galleriafotograficacondivisa.Foto AS F
						  WHERE F.CodFoto NOT IN(SELECT CodFoto
												 FROM galleriafotograficacondivisa.Contenimento)
						  AND F.CodFoto NOT IN(SELECT CodFoto
											   FROM galleriafotograficacondivisa.Condivisione));
	
	elencoFoto2 CURSOR FOR (SELECT F.CodFoto 
						   FROM galleriafotograficacondivisa.Foto AS F
						   WHERE F.CodFoto NOT IN(SELECT CodFoto
												  FROM galleriafotograficacondivisa.Afferenza));
	fotoCorrente INTEGER;
BEGIN
	OPEN elencoFoto2;
		LOOP
			FETCH elencoFoto2 INTO fotoCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
				DELETE FROM galleriafotograficacondivisa.Contenimento WHERE (CodFoto=fotoCorrente);
				DELETE FROM galleriafotograficacondivisa.Condivisione WHERE (CodFoto=fotoCorrente);
		END LOOP;
	CLOSE elencoFoto2;
	OPEN elencoFoto;
		LOOP
			FETCH elencoFoto INTO fotoCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
				DELETE FROM galleriafotograficacondivisa.Foto WHERE (CodFoto=fotoCorrente);
		END LOOP;
	CLOSE elencoFoto;
	RETURN NEW;
	END;
$EliminaFotoLibera$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER EliminaFotoLibera BEFORE INSERT ON galleriafotograficacondivisa.Foto
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaFotoLibera();




/*in un sistema più complesso, il controllo di eventuali fotografie private in gallerie condivise viene fatta periodicamente (tipo ogni mese) invece che ad ogni inserimento per rendere il sistema più efficiente*/
CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaFotoPrivataGC() RETURNS TRIGGER AS $EliminaFotoPrivataGC$
DECLARE 
	elencoFoto CURSOR FOR (SELECT CodFoto 
						  FROM galleriafotograficacondivisa.Foto 
						  NATURAL JOIN galleriafotograficacondivisa.Condivisione 
						  WHERE TipoFoto='privato');					  
	fotoCorrente INTEGER;
BEGIN
	OPEN elencoFoto;
		LOOP
			FETCH elencoFoto INTO fotoCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
				DELETE FROM galleriafotograficacondivisa.Condivisione WHERE (CodFoto=fotoCorrente);
		END LOOP;
	CLOSE elencoFoto;
	RETURN NEW;
END;
$EliminaFotoPrivataGC$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER EliminaFotoPrivataGC AFTER INSERT ON galleriafotograficacondivisa.Condivisione
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaFotoPrivataGC();



/*in un sistema più complesso, il controllo di eventuali gallerie condivise senza membri viene fatta periodicamente (tipo ogni mese) invece che ad ogni inserimento per rendere il sistema più efficiente*/
CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.EliminaGalleriaVuota() RETURNS TRIGGER AS $EliminaGalleriaVuota$
DECLARE 
	elencoGallerie CURSOR FOR (SELECT CodGC 
						  FROM galleriafotograficacondivisa.GalleriaCondivisa 
						  NATURAL JOIN galleriafotograficacondivisa.Partecipazione 
						  GROUP BY (CodGC)
						  HAVING COUNT(CodGC)<2);					  
	galleriaCorrente INTEGER;
BEGIN
	OPEN elencoGallerie;
		LOOP
			FETCH elencoGallerie INTO galleriaCorrente;
			IF (NOT FOUND) 
			THEN EXIT;
			END IF;
				DELETE FROM galleriafotograficacondivisa.Condivisione WHERE (CodGC=galleriaCorrente);
				DELETE FROM galleriafotograficacondivisa.Partecipazione WHERE (CodGC=galleriaCorrente);
				DELETE FROM galleriafotograficacondivisa.GalleriaCondivisa WHERE (CodGC=galleriaCorrente);
		END LOOP;
	CLOSE elencoGallerie;
	RETURN NEW;
END;
$EliminaGalleriaVuota$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER EliminaGalleriaVuota AFTER INSERT ON galleriafotograficacondivisa.GalleriaCondivisa
FOR EACH ROW EXECUTE FUNCTION galleriafotograficacondivisa.EliminaGalleriaVuota();



CREATE OR REPLACE FUNCTION galleriafotograficacondivisa.PrivatizzaFoto() RETURNS TRIGGER AS $PrivatizzaFoto$
BEGIN	
	DELETE FROM galleriafotograficacondivisa.Condivisione WHERE (CodFoto=NEW.CodFoto);
	RETURN NEW;
END;
$PrivatizzaFoto$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER PrivatizzaFoto AFTER UPDATE ON galleriafotograficacondivisa.Foto
FOR EACH ROW
WHEN (OLD.TipoFoto='pubblico' AND NEW.TipoFoto='privato')
EXECUTE FUNCTION galleriafotograficacondivisa.PrivatizzaFoto();