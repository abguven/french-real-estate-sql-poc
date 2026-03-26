-- ===================================================================
-- CRÉATION DE LA VUE ANALYTIQUE PRINCIPALE
-- Cette vue servira de base pour toutes les requêtes d'analyse.
-- ===================================================================
CREATE VIEW V_Transactions_Completes AS
SELECT
    -- Champs de la vente
    v.id_vente,
    v.date_mutation,
    v.valeur_fonciere,
    
    -- Champs du bien
    b.id_bien,
    b.type_local,
    b.total_piece,
    b.surface_carrez,
    b.surface_local,
    
    -- Champs de la commune
    c.code_insee,
    c.nom_commune,
    c.code_departement,
    c.code_postal,
    c.population_total,
    c.nom_region,
    
    -- Colonnes calculées
    CASE
        WHEN b.type_local = 'Maison' AND b.surface_local > 0 THEN b.surface_local
        WHEN b.type_local = 'Appartement' AND b.surface_carrez > 0 THEN b.surface_carrez
        ELSE NULL
    END AS calc_surface,
    
    
    CASE
        WHEN b.type_local = 'Maison' AND b.surface_local > 0 THEN v.valeur_fonciere / b.surface_local
        WHEN b.type_local = 'Appartement' AND b.surface_carrez > 0 THEN v.valeur_fonciere / b.surface_carrez
        ELSE NULL
    END AS calc_prix_m2

FROM
    vente AS v
JOIN
    bien AS b ON v.id_bien = b.id_bien
JOIN
    commune AS c ON b.code_insee = c.code_insee;
GO

--1. Nombre total d’appartements vendus au 1er semestre 2020.
CREATE VIEW ventes_appart_H1_2020 AS
    SELECT 
        date_mutation, type_local, nom_region
    FROM V_Transactions_Completes
    WHERE type_local = 'Appartement'
      AND date_mutation BETWEEN '2020-01-01' AND '2020-06-30'
GO

SELECT Count(*) AS total_apart_vendu_H1
FROM ventes_appart_H1_2020;

--Résultats
--total_apart_vendu_H1
--31378
GO

--2. Le nombre de ventes d’appartement par région pour le 1er semestre 2020.
SELECT nom_region AS nom_de_region, COUNT(*) AS nombre_de_ventes 
	FROM ventes_appart_H1_2020 
	GROUP BY nom_region
	ORDER BY nombre_de_ventes DESC;
GO

--Résultats
/*
|      nom_de_region          | nombre_de_ventes |
|-----------------------------|------------------|
| Ile-de-France               |   13995          |
| Provence-Alpes-Côte d'Azur  |    3649          |
| Auvergne-Rhône-Alpes        |    3253          |
| Nouvelle-Aquitaine          |    1932          |
| Occitanie                   |    1640          |
| Pays de la Loire            |    1357          |
| Hauts-de-France             |    1254          |
| Grand Est                   |     984          |
| Bretagne                    |     983          |
| Normandie                   |     862          |
| Centre-Val de Loire         |     696          |
| Bourgogne-Franche-Comté     |     376          |
| Corse                       |     223          |
| Martinique                  |      94          |
| La Réunion                  |      44          |
| Guyane                      |      34          |
| Guadeloupe                  |       2          |
*/
GO

-- 3. Proportion des ventes d’appartements par le nombre de pièces.
DECLARE @nb_total_ventes_appart INT;

SELECT @nb_total_ventes_appart = COUNT(*)
FROM V_Transactions_Completes 
WHERE type_local = 'Appartement'

SELECT 
	total_piece AS nombre_de_pieces,
	COUNT(*) AS nombre_de_ventes,
	CAST(
		(COUNT(*) * 100.0 / @nb_total_ventes_appart)
		AS DECIMAL(5, 2)
	) AS proportion_en_pourcentage
FROM V_Transactions_Completes
WHERE type_local = 'Appartement'
GROUP BY total_piece
ORDER BY proportion_en_pourcentage DESC;

--Résultats:
/*
| nombre_de_pieces | nombre_de_ventes | proportion_en_pourcentage |
|------------------|------------------|--------------------------|
|        2         |      9783        |         31.18            |
|        3         |      8966        |         28.57            |
|        1         |      6739        |         21.48            |
|        4         |      4460        |         14.21            |
|        5         |      1114        |          3.55            |
|        6         |       204        |          0.65            |
|        7         |        54        |          0.17            |
|        0         |        30        |          0.10            |
|        8         |        17        |          0.05            |
|        9         |         8        |          0.03            |
|       10         |         2        |          0.01            |
|       11         |         1        |          0.00            |
*/
GO


--4. Liste des 10 départements où le prix du mètre carré est le plus élevé.
SELECT 
	TOP 10
	code_departement, 
	CAST(AVG(calc_prix_m2) AS DECIMAL(10,2)) AS prix_m2_moyen
FROM V_Transactions_Completes 
WHERE calc_prix_m2 IS NOT NULL
GROUP BY code_departement
ORDER BY prix_m2_moyen DESC

--Résultats
/*
| code_departement | prix_m2_moyen |
|------------------|--------------|
|        75        |   12056.80   |
|        92        |    7235.38   |
|        94        |    5370.06   |
|        06        |    4723.74   |
|        74        |    4672.58   |
|        93        |    4362.91   |
|        78        |    4265.32   |
|        69        |    4075.70   |
|       2A         |    4006.14   |
|        33        |    3785.21   |
*/

GO

--5. Prix moyen du mètre carré d’une maison en Île-de-France.
SELECT nom_region FROM V_Transactions_Completes WHERE nom_region LIKE '%France' GROUP BY nom_region

SELECT CAST( AVG(calc_prix_m2) AS DECIMAL(10,2)) AS prix_moyen_maison_ile_de_france
FROM V_Transactions_Completes 
WHERE 
	type_local = 'Maison' 
	AND nom_region='Ile-de-France'
	AND calc_prix_m2 IS NOT NULL  -- par précaution
GO

--Résultats
/*
| prix_moyen_maison_ile_de_france |
|---------------------------------|
|             3997.71             |
*/
GO

--6. Liste des 10 appartements les plus chers avec la région et le nombre de mètres carrés.
SELECT TOP 10
		valeur_fonciere,
		nom_region AS nom_de_region,
		calc_surface AS surface_en_m2
FROM
    V_Transactions_Completes
WHERE
    type_local = 'Appartement'
    AND valeur_fonciere IS NOT NULL 
ORDER BY
    valeur_fonciere DESC;
GO

--Results
/*
| valeur_fonciere |   nom_de_region   | surface_en_m2 |
|-----------------|-------------------|---------------|
|   9000000.00    | Ile-de-France     |     9.10      |
|   8600000.00    | Ile-de-France     |    64.00      |
|   8577713.00    | Ile-de-France     |    20.55      |
|   7620000.00    | Ile-de-France     |    42.77      |
|   7600000.00    | Ile-de-France     |   253.30      |
|   7535000.00    | Ile-de-France     |   139.90      |
|   7420000.00    | Ile-de-France     |   360.95      |
|   7200000.00    | Ile-de-France     |   595.00      |
|   7050000.00    | Ile-de-France     |   122.56      |
|   6600000.00    | Ile-de-France     |    79.38      |
*/

GO

--7. Taux d’évolution du nombre de ventes entre le premier et le second trimestre de 2020.
DECLARE @nb_total_ventes_q1 INT;
DECLARE @nb_total_ventes_q2 INT;

SELECT @nb_total_ventes_q1 = Count(*) FROM V_Transactions_Completes WHERE date_mutation BETWEEN '2020-01-01' AND '2020-03-31' AND valeur_fonciere IS NOT NULL
SELECT @nb_total_ventes_q2 = Count(*) FROM V_Transactions_Completes WHERE date_mutation BETWEEN '2020-04-01' AND '2020-06-30' AND valeur_fonciere IS NOT NULL

SELECT CAST( ((@nb_total_ventes_q2 - @nb_total_ventes_q1) * 100.0 /  @nb_total_ventes_q1) AS DECIMAL(5,2)) AS taux_evolution_Q2_Q1
GO

--Résultats
/*
| taux_evolution_Q2_Q1 |
|----------------------|
|        3.66          |
*/
GO

--8. Le classement des régions par rapport au prix au mètre carré des appartement de plus de 4 pièces.
SELECT nom_region AS nom_de_region, 
		CAST(
			AVG(calc_prix_m2) AS DECIMAL(10,2)
		)AS prix_moyen_au_m2
FROM V_Transactions_Completes
WHERE 
	type_local='Appartement' 
	AND total_piece > 4 
	AND calc_prix_m2 IS NOT NULL 
GROUP BY nom_region
ORDER BY prix_moyen_au_m2 DESC
GO

--Résultats
/*
|      nom_de_region               | prix_moyen_au_m2 |
|----------------------------------|------------------|
| Ile-de-France                    |        8770.44   |
| La Réunion                       |        3641.81   |
| Provence-Alpes-Côte d'Azur       |        3587.65   |
| Corse                            |        3104.88   |
| Auvergne-Rhône-Alpes             |        2891.38   |
| Nouvelle-Aquitaine               |        2465.48   |
| Bretagne                         |        2412.05   |
| Pays de la Loire                 |        2315.76   |
| Hauts-de-France                  |        2189.93   |
| Occitanie                        |        2097.23   |
| Normandie                        |        2015.77   |
| Grand Est                        |        1540.89   |
| Centre-Val de Loire              |        1453.11   |
| Bourgogne-Franche-Comté          |        1251.19   |
| Martinique                       |         573.48   |
*/
GO

--9. Liste des communes ayant eu au moins 50 ventes au 1er trimestre
SELECT	nom_commune, 
		code_insee,-- Pour éviter l'ambiguité des communes homonymes
		COUNT(*) AS nombre_de_ventes_Q1
FROM V_Transactions_Completes 
WHERE date_mutation BETWEEN '2020-01-01' AND '2020-03-31'
GROUP BY nom_commune,code_insee
HAVING COUNT(*) >= 50
ORDER BY nombre_de_ventes_Q1 DESC
GO

-- Résultats :
-- | nom_commune					| code_insee | nombre_de_ventes_Q1 |
-- |----------------------------	|------------|---------------------|
-- | Paris 17e Arrondissement		| 75117      | 228                 |
-- | Paris 15e Arrondissement		| 75115      | 215                 |
-- | Paris 18e Arrondissement		| 75118      | 209                 |
-- | Nice							| 06088      | 173                 |
-- | Paris 11e Arrondissement		| 75111      | 169                 |
-- | Paris 16e Arrondissement		| 75116      | 165                 |
-- | Bordeaux						| 33063      | 157                 |
-- | Paris 14e Arrondissement		| 75114      | 146                 |
-- | Paris 20e Arrondissement		| 75120      | 127                 |
-- | Nantes							| 44109      | 119                 |
-- | Paris 19e Arrondissement		| 75119      | 116                 |
-- | Paris 12e Arrondissement		| 75112      | 110                 |
-- | Paris 10e Arrondissement		| 75110      | 109                 |
-- | Paris 9e Arrondissement		| 75109      | 106                 |
-- | Grenoble						| 38185      | 106                 |
-- | Boulogne-Billancourt			| 92012      | 99                  |
-- | Paris 13e Arrondissement		| 75113      | 94                  |
-- | Paris 7e Arrondissement		| 75107      | 87                  |
-- | Paris 6e Arrondissement		| 75106      | 86                  |
-- | Marseille 8e Arrondissement	| 13208      | 81                  |
-- | Asnières-sur-Seine				| 92004      | 81                  |
-- | Courbevoie						| 92026      | 80                  |
-- | Paris 5e Arrondissement		| 75105      | 79                  |
-- | Paris 3e Arrondissement		| 75103      | 79                  |
-- | Toulouse						| 31555      | 78                  |
-- | Antibes						| 06004      | 77                  |
-- | Marseille 4e Arrondissement	| 13204      | 72                  |
-- | Marseille 1er Arrondissement	| 13201      | 71                  |
-- | Rueil-Malmaison				| 92063      | 68                  |
-- | Vincennes						| 94080      | 68                  |
-- | Lille							| 59350      | 67                  |
-- | Marseille 9e Arrondissement	| 13209      | 66                  |
-- | Montreuil						| 93048      | 65                  |
-- | Angers							| 49007      | 64                  |
-- | Nîmes							| 30189      | 63                  |
-- | La Ciotat						| 13028      | 62                  |
-- | Sète							| 34301      | 62                  |
-- | Paris 8e Arrondissement		| 75108      | 62                  |
-- | Rennes							| 35238      | 61                  |
-- | Paris 2e Arrondissement		| 75102      | 61                  |
-- | Paris 4e Arrondissement		| 75104      | 60                  |
-- | Levallois-Perret				| 92044      | 59                  |
-- | Toulon							| 83137      | 59                  |
-- | Saint-Maur-des-Fossés			| 94068      | 56                  |
-- | Versailles						| 78646      | 54                  |
-- | Ajaccio						| 2A004      | 54                  |
-- | Puteaux						| 92062      | 53                  |
-- | Issy-les-Moulineaux			| 92040      | 50                  |
GO


--10. Différence en pourcentage du prix au mètre carré entre un appartement de 2 pièces et un appartement de 3 pièces.
SELECT 
	CAST([2] AS DECIMAL(10,2)) AS prix_moyen_2_pieces,
	CAST([3] AS DECIMAL(10,2)) AS prix_moyen_3_pieces, 
	CAST((([3]-[2])*100 / [2]) AS DECIMAL(10,2)) AS difference_pourcentage
FROM(
	SELECT total_piece, AVG(calc_prix_m2) AS prix_moyen_m2
	FROM V_Transactions_Completes
	WHERE type_local='Appartement'
		AND total_piece IN (2,3)
		AND calc_prix_m2 IS NOT NULL
	GROUP BY total_piece
)as PrixMoyenParPiece
PIVOT(
	SUM(prix_moyen_m2)
	FOR total_piece IN ([3],[2])
)as ResultatPivote;


-- Résultats :
/*
| prix_moyen_2_pieces | prix_moyen_3_pieces | difference_pourcentage |
|---------------------|---------------------|-----------------------|
|       4908.57       |       4299.88       |        -12.40         |
*/
GO

--11. Les moyennes de valeurs foncières pour le top 3 des communes des départements 6, 13, 33, 59 et 69.
SELECT code_departement, nom_commune, valeur_fonciere_moyenne FROM (
	SELECT 
		code_departement,
		nom_commune,
		CAST(
			AVG(valeur_fonciere) AS DECIMAL(10,2)
			) 
			AS valeur_fonciere_moyenne,
		ROW_NUMBER() OVER (PARTITION BY code_departement ORDER BY AVG(valeur_fonciere) DESC) AS rang
	FROM V_Transactions_Completes
	WHERE 
		code_departement in ('06', '13', '33', '59', '69')
		AND valeur_fonciere IS NOT NULL
	GROUP BY code_departement, nom_commune

	)AS classement
WHERE classement.rang <= 3;
GO

--Results:
/*
| code_departement |        nom_commune          | valeur_fonciere_moyenne |
|------------------|----------------------------|-------------------------|
|        06        | Saint-Jean-Cap-Ferrat      |       968750.00         |
|        06        | Eze                        |       655000.00         |
|        06        | Mouans-Sartoux             |       476898.10         |
|        13        | Gignac-la-Nerthe           |       330000.00         |
|        13        | Saint-Savournin            |       314425.00         |
|        13        | Cassis                     |       313416.88         |
|        33        | Lège-Cap-Ferret            |       549500.64         |
|        33        | Vayres                     |       335000.00         |
|        33        | Arcachon                   |       307435.93         |
|        59        | Bersée                     |       433202.00         |
|        59        | Cysoing                    |       408550.00         |
|        59        | Halluin                    |       322250.00         |
|        69        | Ville-sur-Jarnioux         |       485300.00         |
|        69        | Lyon 2e Arrondissement     |       455217.27         |
|        69        | Lyon 6e Arrondissement     |       426968.25         |
*/
GO


--12. Les 20 communes avec le plus de transactions pour 1000 habitants pour les communes qui dépassent les 10 000 habitants.
SELECT	TOP 20
		code_insee ,nom_commune,
		COUNT(*) AS nmbre_de_transactions, 
		CAST( COUNT(*) / (population_total / 1000.0) AS DECIMAL(5,2)) AS transactions_par_1000_habitants
FROM V_Transactions_Completes
WHERE 
	population_total > 10000
	AND valeur_fonciere IS NOT NULL -- Que les transactions monétisées
GROUP BY code_insee, nom_commune,  population_total
ORDER BY transactions_par_1000_habitants DESC;

-- Results:
/*
| code_insee |         nom_commune          | nmbre_de_transactions | transactions_par_1000_habitants |
|------------|-----------------------------|----------------------|-------------------------------|
|   75102    | Paris 2e Arrondissement     |         127          |            5.84               |
|   75101    | Paris 1er Arrondissement    |          78          |            4.86               |
|   75103    | Paris 3e Arrondissement     |         161          |            4.69               |
|   33009    | Arcachon                    |          55          |            4.62               |
|   44055    | La Baule-Escoublac          |          77          |            4.58               |
|   75104    | Paris 4e Arrondissement     |         119          |            4.05               |
|   06104    | Roquebrune-Cap-Martin       |          52          |            3.99               |
|   75108    | Paris 8e Arrondissement     |         139          |            3.83               |
|   83123    | Sanary-sur-Mer              |          60          |            3.50               |
|   83071    | La Londe-les-Maures         |          37          |            3.43               |
|   75109    | Paris 9e Arrondissement     |         208          |            3.43               |
|   75106    | Paris 6e Arrondissement     |         139          |            3.38               |
|   83112    | Saint-Cyr-sur-Mer           |          37          |            3.16               |
|   60141    | Chantilly                   |          35          |            3.13               |
|   94067    | Saint-Mandé                 |          69          |            3.06               |
|   44132    | Pornichet                   |          35          |            3.06               |
|   75110    | Paris 10e Arrondissement    |         264          |            3.04               |
|   06083    | Menton                      |          91          |            2.94               |
|   85226    | Saint-Hilaire-de-Riez       |          33          |            2.87               |
|   94080    | Vincennes                   |         141          |            2.81               |
*/
GO