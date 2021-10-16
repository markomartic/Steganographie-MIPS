######################################################################

#			STEGANOGRAPHIE

#	        décoder du texte caché dans une image

######################################################################

#          	Programmé par Martic Marko et Weiler Philippe

######################################################################

#	Implentation de la stéganographie, en assembleur MIPS

#       Exécuté par un IDE léger : MARS

#

# 	Paramètres à ABSOLUMENT prendre en compte :

# 	   - il faut modifier cheminRep selon les indication à l.31

######################################################################

.data  
###############################################################
# 		A MODIFIER SUR CHAQUE PC		
###############################################################
# Ici doit figurer le chemin absolu vers le répertoire
# qui contient l'image avec "/" à la fin
cheminRep: .asciiz "/adhome/m/ma/martic/Cours/S3/Architecture/PROJET/projet_archi/MARTIC-Marko-WEILER-Philippe/3. Fichier/"		
###############################################################


messageEntrerFichierIn: .asciiz "Veuillez entrer le nom de l'image dans laquelle est dissimulée la chaîne : \n"
messageEntrerFichierOut: .asciiz "Veuillez entrer le nom de l'image de sortie : \n"

nomImageIn: .space 2048		# nom de l'image en entrée uniquement (ne doit pas avoir de remontant d'arborescence "../")
nomImageOut: .space 2048	# nom de l'image en sortie uniquement (ne doit pas avoir de remontant d'arborescence "../")
cheminImageIn: .space 2048	# chemin absolu construit à partir du cheminRep et du nomImageIn
cheminImageOut: .space 2048	# chemin absolu construit à partir du cheminRep et du nomImageOut
chaineDecodee: .space 2048	# contiendra la chaine décodé
buffer: .space 1200000	# contiendra les binaires de l'image



######################
# $s2 adresse début image
# buffer contenu du fichier
######################

.text
.globl __start

__start:


###############################################################
# Affiche l'instruction pour entrer la bonne chaîne
la $a0 messageEntrerFichierIn
jal afficheChaîne
###############################################################
#
###############################################################
#Lecture du nom de l'image en entrée
la $a0 nomImageIn	#adresse dans laquelle est enregistrée la chaîne
jal lectureChaîne256
###############################################################
#
###############################################################
# Concaténation entre cheminRep et nomImageIn
# formant ensemble le chemin absolu du fichier à charger
la $s4 cheminImageIn
la $s5 cheminRep
la $s6 nomImageIn
jal ConcatWNom
# Sortie : cheminImage
###############################################################

###############################################################
# Ouverture du fichier source
li   $v0 13            # system call for open file
la   $a0 cheminImageIn # input file name
li   $a1 0             # flag for reading
li   $a2 0             # mode is ignored
syscall                # open a file
move $s0 $v0           # save the file descriptor
###############################################################
#  Lecture du fichier source
li   $v0 14        # system call for reading from file
move $a0 $s0       # file descriptor
la   $a1 buffer    # address of buffer from which to read
li   $a2 150000   # space/8
syscall            # read from file
###############################################################
# Close the file
li   $v0, 16       # system call for close file
move $a0, $s0      # file descriptor to close
syscall            # close file	
###############################################################

###############################################################
# Lecture de l'adresse du début de l'image
# Dans un fichier BMP, l'adresse du début d' l'image est stockée aux octets [10;13]
lb $t1, 10($a1)
lb $t2, 11($a1)
lb $t3, 12($a1)
lb $t4, 13($a1)
jal Lecture4o
add $s2 $t0 $a1
# Sortie : $s2 adresse du début de l'image
###############################################################



############################################################################################
#Décodage
#Entrées :
# 	- buffer de l'image
#Sorties :
#	- chaineDecodee
############################################################################################
la $s0 chaineDecodee 	# $s0 est l'adresse où enregistrer la chaine décodée
li $s4 0		# désigne le numero de la lettre en cours de décodage
li $t1 0
li $t3 7		# shift des bits à effectuer à gauche avant addition au caractère en cours
#Debut octet par octet du texte à décoder
lettreSuivanteADecoder:
  move $t4 $s4		# déplace $s4 dans $t4 afin de tester la derniere lettre décodée
  beq $s4 $zero test	# test pour réduire $s4 afin de tester la derniere lettre décodée
    sub $t4 $s4 1	# reduit $s4 
  test:
  add $a0 $s0 $t4	# a0 est l'adresse de la lettre traîtée
  lb $a0 ($a0)		# a0 est la lettre 
  andi $a0 $a0 255	# a0 est la lettre nettoyée
  beq $a0 0x0000000a finChaine	# si la lettre traîtée precedemment vaut 0x0000000a donc '\n' on finit le décodage du fichier
  li $t0 0		# $t0 compteur pour les 8 bits de la lettre qui est en a0, et compteur pour les 8 octets
  li $a2 0		# initialisation de l'octet où sera stocké le caractère en cours
   debutoctet:		# début du traitement d'une lettre
    beq $t0 8 finoctet	# test si on a finit la lettre
      lb $a0 ($s2)	# $a0 octet du buffer traîté
      andi $a0 $a0 0x00000001	# $a0 = le bit de poids faible de l'octet
      sub $t1 $t3 $t0	# calcul dynamique du décalage à appliquer à la commande suivante
      sllv $a0 $a0 $t1	# décalage du bit au poids qui lui correspond
      add $a2 $a2 $a0	# ajout du bit traîté et stockage dans $a2
      add $t0 $t0 1	# incrément du compteur de poids
      addi $s2 $s2 1	# incrément du buffer 
  j debutoctet		
finoctet:
add $a0 $s4 $s0		# on traîte le caractère suivant de la chaîne	
sb  $a2 ($a0)		# sauvegarde du caractère dans la chaîne
add $s4 $s4 1		# incrément dans la chaîne à décoder
j lettreSuivanteADecoder
finChaine:

add $a0 $s4 $s0		# déplacement dans la chaîne au caractère suivant			
sb  $zero ($a0)		# mise à zéro du dernier caractère sinon il vaut "\n"
la $a0 chaineDecodee	# ouverture de la chaîne pour lecture
jal afficheChaîne	# affichage de la chaîne décodée
############################################################################################




###############################################################
# Affiche l'instruction pour entrer la bonne chaîne
la $a0 messageEntrerFichierOut
jal afficheChaîne
###############################################################

###############################################################
# Lecture du nom de fichier de sortie
la $a0 nomImageOut	#adresse dans laquelle est enregistrée la chaîne
jal lectureChaîne256
###############################################################
#
###############################################################
# Concaténation 
la $s4 cheminImageOut
la $s5 cheminRep
la $s6 nomImageOut
jal ConcatWNom
###############################################################

###############################################################
# Open (for writing) a file that does not exist
li   $v0, 13       # system call for open file
la   $a0, cheminImageOut  # output file name
li   $a1, 1        # Open for writing (flags are 0: read, 1: write)
li   $a2, 0        # mode is ignored
syscall            # open a file (file descriptor returned in $v0)
move $s6, $v0      # save the file descriptor
###############################################################
# Write to just opened file							#
li   $v0, 15       # system call for write to file				#
move $a0, $s6      # file descriptor 					#
la   $a1, chaineDecodee   # address of buffer from which to write		#
li   $a2, 4096    # hardcoded buffer length				#
syscall            # write to file						#
###############################################################
# Close the file								#
li   $v0, 16       # system call for close file				#
move $a0, $s6      # file descriptor to close					#
syscall            # close file						#
###############################################################
















######
j Exit#
######

Exit:
li $v0 10     # appel système 10: fin du programme
syscall

###############################################################
###############################################################
## 			FONCTIONS
###############################################################
###############################################################


Lecture4o:
###############################################################
# Lecture4o:
# Permet de lire 4 octets dans en les remettant dans l'ordre
# à partir des binaires du programme.
# Permet de pallier aux problèmes du little endian.
#
# Entrées :
#	$t1 adresse de l'octet qui apparaît en premier
#	$t2 ---------------------------- deuxième
# 	$t3 ---------------------------- troisième
# 	$t4 ---------------------------- quatrième
#
# Sorties :
#	$t0 somme des 4 entrées à la bonne puissance
###############################################################
# Nettoyage car il arrive qu'on ait des octets qui valent
# 0xffffffXX au lieu de 0x000000XX
andi $t1, $t1, 0xFF
andi $t2, $t2, 0xFF
andi $t3, $t3, 0xFF
andi $t4, $t4, 0xFF
###############################################################
# Différents décalages pour différents octets
#décalage de t5
mul $t4 $t4 16777216 	#16^6
#décalage de t6
mul $t3 $t3 65536	#16^4
#décalage de t7
mul $t2 $t2 256		#16^2
###############################################################
# On additionne tout
move $t0 $t1
add $t0 $t0 $t2
add $t0 $t0 $t3
add $t0 $t0 $t4
jr $ra
###############################################################
# fin du calcul, t0 = somme dans le bon ordre
###############################################################

ConcatWNom:
###############################################################
# ConcatWNom:
# Permet de concaténer deux chaînes
# 
# Entrées :
#	$s4 chaîne concaténée 
#	$s5 chaîne se plaçant en premier
#	$s6 chaîne se plaçant en dernier
# Sorties :
#	$s4 chaîne concaténée
###############################################################
 copyFirstString:  
   lb $t0, ($s5)                  # load un caractère
   beq $t0, 0x0, copySecondString # si on a fini de traîter la 1ère chaîne on va traîter la deuxième
   sb $t0, ($s4)                  # sinon on stock le caractère suivant
   addi $s5, $s5, 1               # s5 pointe vers le suivant caractère
   addi $s4, $s4, 1               # pareil pour s4
   j copyFirstString 
 copySecondString:  
   lb $t0, ($s6)                  # load caractère à l'adresse
   beq $t0, 0xA, endd		  # si on a fini de traîter la 2ème chaîne
   sb $t0, ($s4)                  # sinon on load le caractère
   addi $s6, $s6, 1               # s6 pointe vers le caractère suivant
   addi $s4, $s4, 1               # pareil pour s4
   j copySecondString
   endd:
   sb $zero ($s4)
jr $ra
###############################################################
# fin de la procédure
###############################################################

lectureChaîne256:
###############################################################
# Lit une chaîne de 256 caractères
###############################################################
li $a1 256	#taille de la chaîne
li $v0 8	#code pour lire un string
syscall
jr $ra
###############################################################

afficheChaîne:
###############################################################
# Affiche une chaîne de caractères
###############################################################
li $v0 4
syscall
jr $ra
###############################################################
