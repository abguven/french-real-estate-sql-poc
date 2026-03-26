-- =============================================
-- Table: commune
-- Description: Contient les informations géographiques et démographiques des communes.
-- =============================================
CREATE TABLE commune (
    code_insee VARCHAR(5) NOT NULL,
    code_departement VARCHAR(3) NOT NULL,
    code_commune VARCHAR(3) NOT NULL,
    nom_commune VARCHAR(50) NOT NULL,
    code_postal VARCHAR(5) NULL,
    population_total INT NOT NULL,
    nom_region VARCHAR(30) NOT NULL,
    CONSTRAINT pk_commune PRIMARY KEY (code_insee)
);
GO
  
-- =============================================
-- Table: bien
-- Description: Contient les caractéristiques de chaque bien immobilier.
-- =============================================
CREATE TABLE bien (
    id_bien INT IDENTITY NOT NULL,
    no_voie INT NULL,
    btq VARCHAR(1) NULL,
    voie VARCHAR(50) NOT NULL,
    type_voie VARCHAR(4) NULL,
    total_piece SMALLINT NOT NULL,
    surface_carrez DECIMAL(10,2) NOT NULL,
    surface_local DECIMAL(10,2) NOT NULL,
    type_local VARCHAR(50) NOT NULL,	

	-- Clé étrangère vers la table 'commune'
    -- Le nom et le type doivent correspondre EXACTEMENT à la clé primaire de 'commune'
    code_insee VARCHAR(5) NOT NULL, 	

	CONSTRAINT chk_type_local CHECK (type_local IN ('Maison', 'Appartement')),
    CONSTRAINT pk_bien PRIMARY KEY (id_bien)
);
GO

-- =============================================
-- Table: vente
-- Description: Contient les informations sur les transactions de vente.
-- =============================================
CREATE TABLE vente (
    id_vente INT IDENTITY NOT NULL,
    date_mutation DATETIME NOT NULL,
    
    -- La colonne 'valeur_fonciere' est définie comme NULL-able pour une raison précise.
    -- 1. Modélisation de la réalité : Toutes les mutations immobilières ne sont pas des ventes
    --    (ex: donations, successions, échanges). Forcer une valeur serait incorrect.
    -- 2. Qualité de l'analyse : En utilisant NULL pour les transactions sans prix, on s'assure
    --    que les calculs de moyenne (AVG) ou de somme (SUM) ne seront pas faussés.
    --    Les fonctions d'agrégation de SQL ignorent les NULL, contrairement à une valeur de 0
    --    qui biaiserait les résultats vers le bas.
    valeur_fonciere DECIMAL(15,2) NULL,

    id_bien INT NOT NULL,

    -- La contrainte CHECK s'assure que si une valeur est entrée, elle est strictement positive.
    -- Elle autorise implicitement les valeurs NULL, ce qui correspond à notre besoin.
    CONSTRAINT chk_valeur_fonciere_positive CHECK (valeur_fonciere > 0 OR valeur_fonciere IS NULL),

    -- Définition de la clé primaire
    CONSTRAINT pk_vente PRIMARY KEY (id_vente)
);
GO

-- =============================================
-- Création des relations (clés étrangères)
-- =============================================
ALTER TABLE bien 
ADD CONSTRAINT fk_bien_commune
	FOREIGN KEY (code_insee) REFERENCES commune (code_insee)
	ON DELETE NO ACTION	ON UPDATE NO ACTION;
GO

ALTER TABLE vente ADD CONSTRAINT fk_vente_bien
FOREIGN KEY (id_bien) REFERENCES bien (id_bien)
ON DELETE NO ACTION ON UPDATE NO ACTION;
GO