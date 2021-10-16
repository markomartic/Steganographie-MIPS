# Git du projet d'Architecture des Ordinateurs avril 2019 à l'Univ. de Strasbourg

## Pré-requis :

- Compilateur MARS

## Get quickly Started :
1. Télécharger le projet
2. Ouvrir avec MARS les fichiers encap.s et decap.s des dossiers Base, MultiBit et Fichier et suivre les instructions des codes sources

## Pour plus d'infos
Pour avoir plus d'informations veuillez lire le rapport.pdf

## Intro
Dans le cadre de l’unité d’enseignement Architecture des Ordinateurs en deuxième année de Licence d’Informatique à l’Université de Strasbourg, nous devons réaliser en binôme un projet en assembleur MIPS. Le but est d’implanter le système de la dissimulation d’informations par stéganographie.

Stéganographie

- Dossier 1.Base :
Se trouvent les programmes permettant d'accomplir ce qui est demandé au départ sans bonus
1.bmp est le fichier image de départ
2.bmp est le fichier où la chaîne "Vive les canards !" est dissimulée.

- Dossier 2.Multibit
Se trouvent les mêmes programmes que dans Base, mais avec l'ajout du bonus permettant de cacher plusieurs bits dans un octet.
Encodage : Fonctionnel avec un nombre de bits par octet multiple de 2
Décodage : Fonctionnel.
1.bmp est le fichier image de départ
2.bmp est le fichier où la chaîne "Vive les canards !" est dissimulée, avec 8 bits par octet (ce qui change complètement l'image)

- Dossier 3.Fichier
Se trouvent les mêmes programmes que dans Base, mais avec l'ajout du bonus permettant de cacher un fichier entier.
Encodage : Marche.
Décodage : Marche moins bien :
	- pb : il y a un fichier de sortie, c'est le bon, mais à la fin du fichier un certain nombre de "\o" se rajoutent
	- solution : fixer la taille du fichier de sortie, en incorporant la taille dans l'image par exemple.
1.bmp : entrée image
1.txt : entrée fichier txt
2.bmp : image dans laquelle le 1.txt est codé
2.txt : fichier txt extrait de l'image 2.bmp
