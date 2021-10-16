######################################################################

#			STEGANOGRAPHIE

#	        cacher du texte dans une image

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
cheminRep: .asciiz "/adhome/m/ma/martic/Cours/S3/Architecture/PROJET/projet_archi/MARTIC-Marko-WEILER-Philippe/2. MultiBit/"		
###############################################################

messageEntrerFichierIn: .asciiz "Veuillez entrer le nom de l'image en entrée : \n"
messageEntrerChaîne: .asciiz "Veuillez entrer la chaîne à dissimuler : \n"
messageEntrerNbDeBit: .asciiz "Veuillez entrer le nombre de bits codés par octet 1, 2, 4(modification visible) ou 8(change l'image) : \n" 
messageEntrerFichierOut: .asciiz "Veuillez entrer le nom de l'image de sortie : \n"

nomImageIn: .space 2048		# nom de l'image en entrée uniquement (ne doit pas avoir de remontant d'arborescence "../")
nomImageOut: .space 2048	# nom de l'image en sortie uniquement (ne doit pas avoir de remontant d'arborescence "../")
cheminImageIn: .space 2048	# chemin absolu construit à partir du cheminRep et du nomImageIn
cheminImageOut: .space 2048	# chemin absolu construit à partir du cheminRep et du nomImageOut
chaineACoder: .space 2048	# conteneur pour la chaîne qui sera codée dans l'image
buffer: .space 12000000		# contiendra les binaires de l'image


######################
# $s1 taille de l'image
# $s2 adresse début image
# buffer contenu du fichier
######################

.text
.globl __main

__main:

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
li   $v0 13          # system call for open file
la   $a0 cheminImageIn  # input file name
li   $a1 0           # flag for reading
li   $a2 0           # mode is ignored
syscall              # open a file
move $s0 $v0         # save the file descriptor
###############################################################
#  Lecture du fichier source
li   $v0 14        # system call for reading from file
move $a0 $s0       # file descriptor
la   $a1 buffer    # address of buffer from which to read
li   $a2 1500000   # space/8
syscall            # read from file
###############################################################
# Close the file
li   $v0, 16       # system call for close file
move $a0, $s0      # file descriptor to close
syscall            # close file
###############################################################


###############################################################
# Lecture de la taille :
# Dans un fichier BMP, la taille est stockée aux octets [2;5].
lb $t1, 2($a1)
lb $t2, 3($a1)
lb $t3, 4($a1)
lb $t4, 5($a1)
jal Lecture4o 
move $s1 $t0
# Sortie : $s1 taille en octets de l'image
###############################################################
# Lecture de l'adresse du début de l'image
# Dans un fichier BMP, l'adresse du début de l'image est stockée aux octets [10;13]
lb $t1, 10($a1)
lb $t2, 11($a1)
lb $t3, 12($a1)
lb $t4, 13($a1)
jal Lecture4o
add $s2 $t0 $a1
# Sortie : $s2 adresse du début de l'image
###############################################################


###############################################################
# Affiche l'instruction pour entrer la bonne chaîne
la $a0 messageEntrerChaîne
jal afficheChaîne
###############################################################
#
###############################################################
#Lecture du texte a dissimuler
la $a0 chaineACoder	#adresse dans laquelle est enregistrée la chaîne
jal lectureChaîne256
###############################################################

###############################################################
# Affiche l'instruction pour entrer le nombre de bits par octet
la $a0 messageEntrerNbDeBit
jal afficheChaîne
###############################################################
# Lecture de l'entier choisi par l'utilisateur
li $v0 5
syscall
###############################################################
#Création d'un masque dynamique pour 
# Utilisation d'une suite pour determiner la valeur par rapport a la mise a 1 du nombre de bit choisi par l'utilisateur 
move $s7 $v0  	# nombre de bit cacher par octet 
li $t0 0	# initialisation increment suite pour le nettoyage
li $s5 0	# valeur de la suite
debutSuite:		#U(n+1)=Un*2+1
beq $t0 $s7 finSuite
mul $s5 $s5 2
addi $s5 $s5 1
addi $t0 $t0 1		#increment compteur
j debutSuite
finSuite:
###############################################################
#
############################################################################################
# Boucle de modification des octets de l'image de départ
# Entrées :
# 	buffer : binaires du fichier source
# 	s2 : adresse du début de l'image dans le buffer
#	s5 : masque pour la lettre
# Sorties :
# 	buffer : binaires du fichier modifiés
############################################################################################
la $s0 chaineACoder
li $s4 0 # désigne le numéro de la lettre à traîter ([0;n-1], n taille de la chaîne)
li $t2 8 # inverseur de la deuxième boucle (concatène 2 boucles en une)
sub $t2 $t2 $s7
#boucle pour la chaîne de caractères
lettreSuivante:
  add $a0 $s0 $s4	# a0 est l'adresse de la lettre à traîter
  lb $a0 ($a0)		# a0 est la lettre
  andi $a0 $a0 255   	# a0 est la lettre nettoyée
  beq $a0 0 finChaine 	# Si la lettre en cours vaut '\0' on finit l'encodage du fichier
  li $t0 0		# $t0 compteur pour les 8 bits de la lettre qui est en a0, et compteur pour les 8 octets
    bitSuivant:
    bge $t0 8 finLettre	# si on a finit de traiter les 8 bits de la lettre en cours, on passe à la lettreSuivante
     lb $a1 ($s2)	# a1 = octet du buffer que l'on doit changer
     andi $a2 $a1 0xFF	# a2 = octet du buffer nettoyé
     sub $t1 $t2 $t0	# t1 vaut 7 si t0 vaut 0, t1 vaut 5 si t0 vaut 2, t1 vaut 0 si t0 vaut 7   $t0 0 1 2 3 4 5 6 7 $t1 7 6 5 4 3 2 1 0      $t0 0 2 4 6 $t1 6 4 2 0 
     srlv $a3 $a0 $t1	# a3 a le bit de poids faible correspondant au bit à cacher
     
     and $a3 $a3 $s5 	# a3 est nettoyé à l'aide de la suite Un
   
     li $t7 0xFF	# inverseur 
     sub $t7 $t7 $s5	# si $s7 vaut 1 alors $t7 vaut 254 0XFE si $s7 vaut 2 alors $t7 vaut 252 ou 11111100
     and $a1 $a2 $t7	# met les $s7 derniers bits de l'octet à 0 afin de pouvoir ensuite faire un ou logique avec les bits de la lettre
     or $a2 $a3 $a1	# change la valeur des $s7 bit de poid faible en la valeur des $s7 premier bit de la lettre  
     
     
     sb $a2 ($s2)	# a2 (lettre modifiée) est sauvegardée à l'adresse de la lettre de départ
     addi $s2 $s2 1	# on passe à l'octet suivant du buffer
     add $t0 $t0 $s7	# on passe au $s 7ieme bit suivant de la lettre en cours
     j bitSuivant
      finLettre:
   add $s4 $s4 1	# on traîte la lettre suivante
j lettreSuivante
finChaine:
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
# Write to just opened file
li   $v0, 15       # system call for write to file
move $a0, $s6      # file descriptor
la   $a1, buffer   # address of buffer from which to write
la   $a2, ($s1)    # hardcoded buffer length
syscall            # write to file
###############################################################
# Close the file
li   $v0, 16       # system call for close file
move $a0, $s6      # file descriptor to close
syscall            # close file
###############################################################

#######
j Exit#
#######

##########
Exit:	 #
li $v0 10#    # appel système 10: fin du programme
syscall	 #
##########

###############################################################
###############################################################
## 			FONCTIONS			     ##
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
