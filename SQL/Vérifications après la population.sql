USE LaplaceImmo; 
GO

--VERIFICATION D'INSERTION
SELECT COUNT(*) AS NombreDeLignes FROM commune;
--Résultat: 34991 = 34 991 lignes dans donnees_communes.xlsx ✅

SELECT COUNT(*) AS NombreDeLignes FROM bien;
--Résultat: 34169 = 34 169 lignes dans Valeurs-foncières.xlsx ✅

SELECT COUNT(*) AS NombreDeLignes FROM vente;
--Résultat: 34169 = 34 169 lignes dans Valeurs-foncières.xlsx ✅


--COMPARAISON AVEC LE FICHIER SOURCE

SELECT Count(*) AS nombre_appartement FROM bien WHERE type_local = 'Appartement'
--Résultat: 31 378 = 31 378 transactions d'appartement dans le fichier source ✅

SELECT Count(*) FROM bien WHERE type_local = 'Maison'
--Résultats: 2 791 = 2 791 transactions de maison dans le fichier source ✅

SELECT Count(*) FROM bien WHERE btq IS NULL
--Résultats: 31995 = 31 995 lignes où BTQ est vide dans le fichier source ✅

SELECT Count(*) FROM vente WHERE valeur_fonciere IS NULL
--Résultats: 18 = 18 lignes où la valeur foncière est vide dans le fichier source ✅

SELECT AVG(valeur_fonciere) FROM vente; 
--Résultat: 252 847.124826 = 252 847,1248 la moyenne des VF dans le fichier source ✅

SELECT SUM(valeur_fonciere) FROM vente;
--Résultat: 8 634 982 159.95 = 8 634 982 160 la somme des VF dans le fichier source ✅


--TEST D'INTEGRITE

--Recherce des enregistrement orphélins

SELECT COUNT(*) FROM bien WHERE code_insee NOT IN (SELECT code_insee FROM commune) 
--Résultat : 0 ✅

SELECT COUNT(*) FROM vente WHERE id_bien NOT IN (SELECT id_bien FROM bien)
--Résultat : 0 ✅

--TEST DE COHERENCE

SELECT COUNT(*) FROM bien WHERE surface_carrez <= 0 OR surface_local <= 0;
--Résultat : 0 ✅

-- Dans le fichier excel on a que les valeurs de premier semestre
SELECT MIN(date_mutation) AS DateMin, MAX(date_mutation) AS DateMax FROM vente;
--Résultats
/*
|      DateMin              |            DateMax               |
|---------------------------|----------------------------------|
| 2020-01-02 00:00:00.000   | 2020-06-30 00:00:00.000          |
*/


-- Vérification d'une ligne au hasard 
-- Ligne 12346
-- 2020/02/28	Vente	745000	113		15	BD	4100	GABRIEL PERI	2977	92240	MALAKOFF	92	046		G	134		13	88,06
SELECT v.id_vente, v.date_mutation, v.valeur_fonciere,
	   b.no_voie, b.btq, b.type_voie, b.voie, b.id_bien, b.type_local, b.total_piece, b.surface_carrez,
	   c.code_commune,c.code_insee, c.nom_commune,c.code_postal, c.nom_region
FROM vente AS v
JOIN
    bien AS b ON v.id_bien = b.id_bien
JOIN
    commune AS c ON b.code_insee = c.code_insee
WHERE
    v.id_bien = 12345; 

/*
| id_vente |    date_mutation            | valeur_fonciere | no_voie | btq  | type_voie |        voie        | id_bien |   type_local   | total_piece | surface_carrez | code_commune | code_insee | nom_commune | code_postal |   nom_region   |
|----------|-----------------------------|-----------------|---------|------|-----------|--------------------|---------|---------------|-------------|----------------|--------------|------------|-------------|-------------|---------------|
|  12345   | 2020-02-28 00:00:00.000     |   745000.00     |   113   | NULL |    BD     | GABRIEL PERI       |  12345  | Appartement   |      4      |     88.06      |    046       |   92046    |  Malakoff   |   92240     | Ile-de-France |
*/













