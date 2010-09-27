program mentalp4;  uses crt;
type
 table_nom_niv=array[1..6]of string;
const
nom_niv:table_nom_niv=(
'"Ramollo du cerveau"',
'"Pas tellement fut‚"',
'"Un peu nul au puissance 4"',
'"Avec quelques notions de puissance 4"',
'"Avec de doux moments d''intelligence (+ de 5min par jour)"',
'"Amateur du P4"');
Lo=80;
Li=49;
Ec=77;
{sauvegarde}
nom_fichier_podium='podium.p4';
nom_fichier_partie='parties.p4';
nom_fichier_param='param.p4';
nom_fichier_analyse='analyse.p4';
max_partie=20;
max_analyse=100;
{puissance de jeu}
nom_ordi='Mental P4';
version='6 niveaux';
nb_niveaux=6;
nb_podium=nb_niveaux*2;
max_non_strat=4;
niveau_force=3;
niveau_lointain=4;
niveau_germe=5;
niveau_embryon=6;
{reglage des records}
marathon=42;
raclee=51;
min_raclee=10;
{min et max possible du jeu : }
max_col=15;
max_lign=12;
max_but=12;
max_nb_case=max_col*max_lign;
min_lign=3;
min_col=3;
min_but=3;
{dimensions du jeu classique : }
class_col=7;
class_lign=6;
class_but=4;
nb_place_podium=5;
type
{sauvegarde}
element_podium=record
                joueur:string[8];
                score:integer;
               end;
podium=record
        place:array[1..nb_place_podium]of element_podium;
        categorie:string[30]
       end;
file_podium=file of podium;
{type du jeu }
une_case=record
      gagnX,gagn0:boolean;
     end;
col=1..max_col;
lign=1..max_lign;
type_but=1..max_but;
ensemble_col=set of col;
ensemble_char=set of char;
table_jeu=record
           Gr:array[col]of array[lign]of char;
           niveau,nb_col,nb_lign,but:integer;
           nom1,nom2:string;
           score1,score2,nul,consecu:integer;
           j1_x:boolean;
          end;
table_info=array[col]of array[lign]of une_case;
file_partie=file of table_jeu;
param=record
       niveau_debloque:1..nb_niveaux;
       derniere_sauv,dernier_niveau:integer;
      end;
file_param=file of param;
{Conventions et nomenclatures :
*on code le jeu dans un tableau a deux dimensions appele grille.
      on commence de gauche a droite(i:les colonnes)
      et de bas en haut(j:les lignes)
*On utilise une table d'information qui a une dimension de plus
que la grille de jeu. Chaque case contient 2 infos, gagnx et gagn0
qui sont deux boolean.
Ils sont a 'true' si cette case est gagnante pour ce pion
a 'false' sinon.
*Un coup du jeu est en fait un nombre compri entre 1 et nb_col
 Au vu des regles de gravite en vigueur dans le jeu de puissance 4,
 il est inutile de preciser la ligne.
*On utilise Deux caracteres pour le jeu : 'X' et '0'
*On choisit d'appeler 'germes' les puissances (But-1)
*On choisit d'appeler 'Coups bidons' un coup qui permet a l'adversaire
en jouant juste au dessus de gagner ou un coup qui ne bloque
pas un puissance(But-1) pret a se faire au coup d'apres.
*On choisit d'appeler 'Semi bidons' les coups qui gachent la possibilite
de garder un puissance(But-1)a soi sur la grille.
(Ex vous jouez 3 l'adversaire rejou 3 et bloque un puissance (But-1))
*On choisit d'appeler Strategie forcee une serie de coups qui force
l'adversaire a bloquer des puissances But jusqu'a la victoire.
*On choisit d'appeler Coup lointains deux puissances (But-1)
dont les cases manquantes sont situees juste l'une au dessus de l'autre
ainsi l'adversaire en bloquant le premier nous permet de remplir le 2eme
et de l'emporter.
*les X ont toujours le trait
 Celui qui possede les X sera tire* a chaque partie
 au sort pour varier le commencant}
var
{sauvegarde}
fichier_podium:file_podium;
le_podium:array[1..nb_podium]of podium;
fichier_partie,fichier_analyse:file_partie;
la_partie:array[1..max_partie]of table_jeu;
fichier_param:file_param;
param_jeu:param;
nom_analyse:array[1..max_analyse]of string;
Prems:ensemble_col;{Ensemble des cols du 1er cp de l'ordi}
niveau_ordi:integer;
grille,sauvegarde1:table_jeu;
info:table_info;
nb_case,nb_trait:integer;
recherche,step:real;
tutoriel,bequille:boolean;
{la grille de jeu est une variable globale (de type matrice)
accessible depuis toutes les procedures du programme.}
procedure page;
var
 i,j:integer;
begin
 clrscr;
 for i:=1 to Lo do write('X');
 for i:=1 to (Li-2)
 do begin
     write('X');
     for j:=1 to (Lo-2) do write(' ');
     write('X');
    end;
 for i:=1 to Lo do write('X');
end;

function Pum(nb:integer):integer;
{on lui rentre pour le podium 1 ou 2
depend du niveau de l'ordi
si 1 alors pum=niveau_ordi Šme nombre impair
si 2 idem avec pair}
begin
 if nb=1 then Pum:=(niveau_ordi*2-1)
         else Pum:=(niveau_ordi*2);
end;

function jeu_class:boolean;
begin
with grille do
 jeu_class:=(nb_col=class_col)and(nb_lign=class_lign)and(but=class_but);
end;

function fichierExiste (nom:string):boolean;
var
 fic:file;
begin
 assign(fic,nom);
 {$I-}reset(fic){$I+};
 if (IOResult=0)
  then begin
        close(fic);
        fichierexiste:=true;
       end
  else fichierExiste:=false;
end;

function le_plus_grand(a,b:integer):integer;
{retourne 1 si le plus grand de a et b est a, 2 si c'est b, et 0 si a=b}
begin
 if a>b then le_plus_grand:=1
        else if a<b then le_plus_grand:=2
                    else le_plus_grand:=0;
end;

function cycle(a,borne,i:integer):integer;
{on compte de 1 … borne et on recommence … 1.}
begin
 if (i=1) then if (a<borne) then cycle:=a+1
                            else cycle:=1
          else if (a>1) then cycle:=a-1
                        else cycle:=borne;
end;

function quijou:char;
{permet de determiner en fonction des coups deja joues le joueur
qui a le trait}
var
nbX,nb0:integer;
i:col;
j:lign;
pion:char;
begin
nbX:=0;
nb0:=0;
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
        pion:=grille.Gr[i][j];
        case pion of
        'X':inc(nbX);
        '0':inc(nb0);
        end;
    end;
if nb0<nbX then quijou:='0'
           else quijou:='X';
end;

function autre(c:char):char;
{fonction qui retourne le signe-pion contraire de celui qu'on lui envoit}
begin
case c of
'X':autre:='0';
'0':autre:='X';
else autre:=' ';
end;
end;

function card(E:ensemble_col):integer;
{fonction qui calcule le Cardinal d'un ensemble de col}
var
i:integer;
alpha:col;
begin
i:=0;
for alpha:=1 to grille.nb_col do if (alpha in E) then inc(i);
card:=i;
end;

function nb_0_joue:integer;
{fonction qui compte dans la grille le nombre de pions '0' joues}
{on prefere utiliser deux fonctions sans arguments, une pour 0, une pour X
pour alleger l'ecriture des appels}
var
nb_case_prise:integer;
i:col;
j:lign;
begin
nb_case_prise:=0;
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do if (grille.Gr[i][j]='0') then inc(nb_case_prise);
nb_0_joue:=nb_case_prise;
end;

function nb_X_joue:integer;
{fonction qui compte dans la grille le nombre de pions 'X' joues}
var
nb_case_prise:integer;
i:col;
j:lign;
begin
nb_case_prise:=0;
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do if (grille.Gr[i][j]='X') then inc(nb_case_prise);
nb_X_joue:=nb_case_prise;
end;

function nb_coup_joue:integer;
{et on fait le total}
begin
nb_coup_joue:=nb_0_joue+nb_X_joue;
end;

function pions_valid:boolean;
{Lorsqu'on a places des pions dans le desordre dans la procedure
de pas a pas et qu'on demande a l'ordi de jouer, il faut verifier
que le nombre de 'X' est coherent a celui de '0'
(1 pion de difference au maximum)}
begin
pions_valid:=( (nb_0_joue<=nb_x_joue ) and(nb_0_joue+1>=nb_x_joue) );
end;

function vacante(i:col;j:lign):boolean;
{permet de voir si une case de la grille est vacante c'est a dire
non-occupee par un pion}
begin
vacante:=((grille.Gr[i][j]<>'X')and(grille.Gr[i][j]<>'0'));
end;

function prem_case_libre(coup:col):integer;
{retourne le numero de ligne de la premiere case libre de la colonne coup
retourne grille.nb_lign+1 si la colonne est totalement remplie}
var
ji:integer;
begin
ji:=1;
while ((ji<grille.nb_lign+1) and (grille.Gr[coup][ji]<>' ')) do inc(ji);
prem_case_libre:=ji;
end;

function touche_pion(i:col;j:lign;qui:char):integer;
{cette fonction renvoit le nombre de pions de nature 'qui'
qui touchent la case(i,j) de la grille2 passee en parametre}
type
ent=1..7;
Ens=set of ent;
une_coo=record
            x,y:integer;
        end;
var
boo:array[ent] of boolean;
tot,cas:integer;
E1:Ens;
p:ent;
coo:array[ent]of une_coo;
{ Le X designe le pion en question, on numerote ses voisins comme suit :
            6 7
            4X5
            123

on range dans le tableau coo, les coordonn‚es des voisins
en fonction de X(i,j)  }
begin

coo[1].x:=i-1; coo[1].y:=j-1;
coo[2].x:=i;   coo[2].y:=j-1;
coo[3].x:=i+1; coo[3].y:=j-1;
coo[4].x:=i-1; coo[4].y:=j;
coo[5].x:=i+1; coo[5].y:=j;
coo[6].x:=i-1; coo[6].y:=j+1;
coo[7].x:=i+1; coo[7].y:=j+1;

E1:=[];
for p:=1 to 7
{on place dans E1, les voisins a verifier, s'ils ne sortent pas de la grille}
do if ((coo[p].x>=1) and (coo[p].x<=grille.nb_col) and (coo[p].y>=1) and (coo[p].y<=grille.nb_lign)) then E1:=E1+[p];

for p:=1 to 7 do boo[p]:=false;
for p:=1 to 7 do if (p in E1) then boo[p]:=(grille.Gr[coo[p].x][coo[p].y]=qui);

tot:=0;
for p:=1 to 7 do if boo[p] then inc(tot);
touche_pion:=tot;
end;

procedure mis_a_zero_grille;
{cette fonction enleve tous les pions de la grille de jeu}
var
i:col;
j:lign;
begin
for i:=1 to max_col
do for j:=1 to max_lign do grille.Gr[i][j]:=' ';
end;

procedure maj(var nom1:string);
var
 c1:char;
 i:integer;
 nom_maj:string;
begin
 c1:=nom1[1];
 if (c1 in ['a'..'z']) then c1:=chr(ord(c1)-32);
 nom_maj:=c1;
 for i:=2 to length(nom1) do
 begin
  c1:=nom1[i];
  if (c1 in ['A'..'Z']) then c1:=chr(ord(c1)+32);
  nom_maj:=nom_maj+c1;
 end;
nom1:=nom_maj;
end;

procedure centre(nb:integer;chaine:string);
var
 i,av,ap,l:integer;
begin
 l:=length(chaine);
 av:=(nb-l) div 2;
 ap:=(nb-l)-av;
 for i:=1 to av do write(' ');
 write(chaine);
 for i:=1 to ap do write(' ');
end;

procedure decale(g:integer;chaine:string);
var
 i:integer;
begin
 for i:=1 to g do write(' ');
 writeln(chaine);
end;


procedure gotomil;
var
 i:integer;
begin
 for i:=1 to (Ec div 2) do write(' ');
end;

procedure bordure_cadre(c:integer);
var
 i,av_c:integer;
begin
 av_c:=(Ec-c) div 2;
 for i:=1 to av_c+1 do write(' ');
 for i:=1 to c-2 do write('-');
{ for i:=1 to Ec-(av_c+1+c-2) do write('X');}
 writeln;
end;

procedure cadre_gauche(c:integer;chaine:string);
const
 marge_interieur=2;
var
 i,av_c,ap_ch,l:integer;
begin
 l:=length(chaine);
 av_c:=(Ec-c) div 2;
 ap_ch:=c-2-marge_interieur-l;
 for i:=1 to av_c do write(' ');
 write('I');
 for i:=1 to marge_interieur do write(' ');
 write(chaine);
 for i:=1 to ap_ch do write(' ');
 writeln('I');
end;

procedure cadre_milieu(c:integer;chaine:string);
var
 i,av_c,av_ch,ap_ch,l:integer;
begin
 l:=length(chaine);
 av_c:=(Ec-c) div 2;
 av_ch:=(c-2-l) div 2;
 ap_ch:=c-2-av_ch-l;
 for i:=1 to av_c do write(' ');
 write('I');
 for i:=1 to av_ch do write(' ');
 write(chaine);
 for i:=1 to ap_ch do write(' ');
 writeln('I');
end;

procedure sleep;
var
a:char;
begin
 centre(Ec,'Appuyer une touche pour continuer...');
 writeln;
 gotomil;
 repeat until keypressed;
 a:=readkey;
 writeln;
end;

procedure vide_clavier;
var
 c:char;
begin
 while keypressed do c:=readkey;
end;

procedure clavier(var rep1:char);
var
 rep:char;
begin
 repeat until keypressed;
 rep:=readkey;
 if (rep='&') then rep:='1';
  if (rep='‚') then rep:='2';
  if (rep='"') then rep:='3';
  if (rep='''') then rep:='4';
  if (rep='(') then rep:='5';
  if (rep='-') then rep:='6';
  if (rep='Š') then rep:='7';
  if (rep='_') then rep:='8';
  if (rep='‡') then rep:='9';
  if (rep='…') then rep:='0';
  if (rep in ['a'..'z']) then rep:=chr(ord(rep)-32);
 rep1:=rep;
 if (rep1<>#13) then write(rep1);
end;

procedure readln_maj_nb(var chaine:string);
var
 cara:char;
begin
chaine:='';
repeat
 clavier(cara);
 if (cara<>#13) and (cara<>#8) then chaine:=chaine+cara;
 if not(cara in ['0'..'9'])and(cara<>#8) then cara:=#13;
 if cara=#8
 then begin
       write(' ');
       write(cara);
       chaine:=copy(chaine,1,length(chaine)-1);
      end;
until cara=#13;
writeln;
end;

procedure mis_a_zero_sauvegarde;
{cette fonction enleve tous les pions de la grille de sauvegarde}
var
i:col;
j:lign;
begin
for i:=1 to max_col
do for j:=1 to max_lign do sauvegarde1.Gr[i][j]:=' ';
end;

procedure mis_a_zero_info;
{remet tous les infos a 'false'}
var
i:col;
j:lign;
begin
for i:=1 to max_col
do for j:=1 to max_lign
   do with info[i][j]
      do begin
           gagnX:=false;
           gagn0:=false;
         end;
end;

procedure magic_inter(var E1,E2,E3,P:ensemble_col);
{fonction qui retourne l'ensemble-intersection par priorite
de 3 ensembles de col :
Si on veut en faire l'utilisation pour 2 ensembles,
mettre [] pour E3.
Cette procedure est la cle de l'algorithme de ce
programme fait par selection de coups par priorite
et par affinage d'ensemble de coups restreints peu a peu par
des criteres de plus en plus precis}
begin
P:=E1;
if (E1*E2<>[])then P:=E1*E2;
if (P*E3<>[]) then P:=P*E3;
end;

procedure writeln_Ens_char(var E:ensemble_char);
{Affiche entre accolade, les cara de E qui sont entre 0 et z dans l'ascii}
var
i:char;
n:integer;
begin
    n:=0;
    write('{');
    for i:='0' to 'z'
    do begin
        if (i in E)
        then begin
              if (n>0) then write(',');
              write('''',i,'''');inc(n);
             end;
       end;
    writeln('}');
end;

procedure centre_Ens_col(largeur:integer;var E:ensemble_col);
{Affiche entre accolades les col de E qui sont entre 1 et grille.nb_col}
var
i:col;
n,cardE,long,av,ap,ind:integer;
begin
    cardE:=card(E);
    long:=2+cardE;
    if (cardE<>0) then long:=long+(cardE-1);
     {2accolade,cardE nombre d'un cara(grille.nb_col<10)et les virgules}
    av:=(largeur-long)div 2;
    ap:=(largeur-long)-av;
    for ind:=1 to av do write(' ');
    n:=0;
    write('{');
    for i:=1 to grille.nb_col
    do begin
        if (i in E)
        then begin
              if (n>0) then write(',');
              write(i);inc(n);
             end;
       end;
    write('}');
    for ind:=1 to ap do write(' ');
end;

procedure demande_nom(nom_demande:string;var nom_donne:string);
{procedure qui demande son nom a l'utilisateur
Ne considere que les 8 premiers caractŠres de la reponse}
var
reponse:string;
begin
 repeat
 write(' ',nom_demande,', entrez votre nom (max 8 caracteres) : ');
 readln(reponse);
 nom_donne:=copy(reponse,1,8);
 until (nom_donne<>'');
 maj(nom_donne);
end;

procedure affiche_podium(pod1:podium);
const
 gauc=6;
var
 ch0,ch1,ch2:string;
 i,j:integer;
begin
with pod1
do begin
    writeln;
    centre(Ec,'PODIUM DES MEILLEURS SCORES');
    writeln;
    writeln;
    centre(Ec,'Categorie : '+categorie);
    writeln;
    writeln;
    writeln;
    for j:=1 to gauc do write(' ');
    writeln('      ----------------------------------------------------');
    for j:=1 to gauc do write(' ');
    writeln('     I  Place  I     Nom du joueur    I       Score       I');
    for j:=1 to gauc do write(' ');
    writeln('      ---------------------------------------------------- ');
    for j:=1 to gauc do write(' ');
    writeln('      ---------------------------------------------------- ');
    for i:=1 to nb_place_podium
    do begin
        str(i,ch0);
        ch1:=place[i].joueur;
        str(place[i].score,ch2);
        for j:=1 to gauc do write(' ');
        write  ('     I');centre(9,ch0);write('I');
        centre(22,ch1);write('I');centre(19,ch2);writeln('I');
        for j:=1 to gauc do write(' ');
        writeln('      ----------------------------------------------------');
       end;
    end;
end;

procedure entre_podium(var pod1:podium;score1:integer;nom:string);
label fini;
var
 i,j:integer;
 ch1:string;
begin
 clrscr;
 affiche_podium(pod1);
 writeln;
 str(score1,ch1);
 centre(Ec,nom+', votre Nouveau score : '+ch1+' --> VOUS ENTREZ SUR LE PODIUM  !');
 with pod1
 do begin
     for i:=1 to nb_place_podium
     do begin
         if (score1>place[i].score)
         then begin
               for j:=nb_place_podium downto (i+1) do place[j]:=place[j-1];
               place[i].joueur:=nom;
               place[i].score:=score1;
               goto fini;
              end;
        end;
    end;
fini:
centre(Ec,'Appuyer sur entree pour voir le nouveau classement.');
gotomil;readln;
clrscr;
affiche_podium(pod1);
writeln;
end;

procedure initialise_podium(var pod1:podium);
var
 i:integer;
 ch0:string[4];
begin
with pod1
do begin
    for i:=1 to nb_place_podium
    do begin
        str(i,ch0);
        place[i].joueur:='JOUEUR '+ch0;
        place[i].score:=0;
       end;
   end;
end;

procedure cree_fichier_podium;
var
 nom1:podium;
 ch0:string;
 n:integer;
begin
 assign(fichier_podium,nom_fichier_podium);
 rewrite(fichier_podium);
 for n:=1 to nb_niveaux
 do begin
 str(n,ch0);
 initialise_podium(nom1);
 nom1.categorie:='MARATHON DU P4, Niveau '+ch0;
 write(fichier_podium,nom1);
 nom1.categorie:='COUPE PRUDENCE, Niveau '+ch0;
 write(fichier_podium,nom1);
    end;
 close(fichier_podium);
end;

procedure cree_fichier_partie;
var
 partie1:table_jeu;
 n:integer;
begin
 mis_a_zero_grille;
 partie1:=grille;
 with partie1
 do begin
    niveau:=1;
     nom1:='';
     nom2:='';
     score1:=0;
     score2:=0;
     nul:=0;
     consecu:=0;
     nb_col:=class_col;
     nb_lign:=class_lign;
     but:=class_but;
    end;
 assign(fichier_partie,nom_fichier_partie);
 rewrite(fichier_partie);
 for n:=1 to max_partie do write(fichier_partie,partie1);
 close(fichier_partie);
end;

procedure cree_fichier_analyse;
var
 partie1:table_jeu;
 n:integer;
begin
 mis_a_zero_grille;
 partie1:=grille;
 with partie1
 do begin
    niveau:=1;
     nom1:='';
     nom2:='';
     score1:=0;
     score2:=0;
     nul:=0;
     consecu:=0;
     nb_col:=class_col;
     nb_lign:=class_lign;
    end;
 assign(fichier_analyse,nom_fichier_analyse);
 rewrite(fichier_analyse);
 for n:=1 to max_analyse do write(fichier_analyse,partie1);
 close(fichier_analyse);
end;


procedure cree_fichier_param;
var
 param1:param;
begin
 assign(fichier_param,nom_fichier_param);
 rewrite(fichier_param);
 with param1
 do begin
      niveau_debloque:=6;
      derniere_sauv:=0;
      dernier_niveau:=1;
    end;
 write(fichier_param,param1);
 close(fichier_param);
end;

procedure lecture_podium;
var
 n:integer;
begin
{meilleurs scores}
 if not(fichierExiste(nom_fichier_podium))
 then cree_fichier_podium;
 assign(fichier_podium,nom_fichier_podium);
 reset(fichier_podium);
 for n:=1 to nb_podium do read(fichier_podium,le_podium[n]);
 close(fichier_podium);
end;

procedure lecture_partie;
var
 n:integer;
begin
{partie sauvegard‚es}
 if not(fichierExiste(nom_fichier_partie))
 then cree_fichier_partie;
 assign(fichier_partie,nom_fichier_partie);
 reset(fichier_partie);
 for n:=1 to max_partie do read(fichier_partie,la_partie[n]);
 close(fichier_partie);
end;

procedure lecture_analyse;
var
 analyse1:table_jeu;
 n:integer;
begin
{partie sauvegard‚es}
 if not(fichierExiste(nom_fichier_analyse))
 then cree_fichier_analyse;
 assign(fichier_analyse,nom_fichier_analyse);
 reset(fichier_analyse);
 for n:=1 to max_analyse
 do begin
     read(fichier_analyse,analyse1);
     nom_analyse[n]:=analyse1.nom1;
    end;
 close(fichier_analyse);
end;

procedure lecture_param;
begin
 if not(fichierExiste(nom_fichier_param))
 then cree_fichier_param;
 assign(fichier_param,nom_fichier_param);
 reset(fichier_param);
 read(fichier_param,param_jeu);
 close(fichier_param);
end;

procedure ecriture_podium;
var
 n:integer;
begin
{meilleurs scores}
 assign(fichier_podium,nom_fichier_podium);
 rewrite(fichier_podium);
 for n:=1 to nb_podium do write(fichier_podium,le_podium[n]);
 close(fichier_podium);
end;

procedure ecriture_partie;
var
 n:integer;
begin
{partie sauvegard‚es}
 assign(fichier_partie,nom_fichier_partie);
 reset(fichier_partie);
 for n:=1 to max_partie do write(fichier_partie,la_partie[n]);
 close(fichier_partie);
end;

procedure ecriture_param;
begin
 param_jeu.dernier_niveau:=niveau_ordi;
 assign(fichier_param,nom_fichier_param);
 reset(fichier_param);
 write(fichier_param,param_jeu);
 close(fichier_param);
end;

procedure garde_fou_char(var Ens:ensemble_char;var rep:char);
{procedure qui sert a eviter que l'utilisateur tape
un resultat inatendu au clavier lors de la saisi d'un caractere}
begin
repeat
 clavier(rep);writeln;
 if not (rep in Ens)
 then begin
       write('               Reponses possibles : ');
       writeln_Ens_char(Ens);
       writeln;
       centre(Ec,'Entrez une reponse correcte : ');
       writeln;
       writeln;
       gotomil;
      end;
until rep in Ens;
end;

procedure garde_fou_nb(inf,sup:integer;var rep:integer);
{procedure qui sert a eviter que l'utilisateur tape
un resultat inatendu au clavier lors de la saisi d'un nombre}
var
reponse,ch1,ch2:string;
code,entree:integer;
inborne:boolean;
begin
  write(' (de ',inf,' … ',sup,' ) : ');
repeat
 repeat
  readln_maj_nb(reponse);
  val(reponse,entree,code);
  str(inf,ch1);
  str(sup,ch2);
  if (code<>0)
  then write('       Vous devez entrez un nombre compris entre '+ch1+' et '+ch2+' : ');
 until code=0;
 rep:=entree;
 inborne:=((rep>=inf)and(rep<=sup));
 if (not inborne)
 then write('        Ce nombre doit etre compris entre ',inf,' et ',sup,' : ');
until (inborne);
end;

procedure selectionner_analyse(cara:char;var selection:integer);
var
 i,prem,der:integer;
 esp,ch1,ch2:string;
 c1:char;
begin
 selection:=1;
 esp:=' ---> ';
 repeat
  clrscr;
  writeln;
  case cara of
  'S':begin
       ch1:='sauver';
       ch2:='SAUVER';
      end;
  'C':begin
       ch1:='charger';
       ch2:='CHARGER';
      end;
  'A':begin
       ch1:='charger';
       ch2:='CHARGER';
      end;
  end;
  centre(Ec,ch2+' UNE GRILLE D''ANALYSE');
  writeln;
  writeln;
  writeln;
  writeln;
  writeln;
  if (selection<10)
  then begin
        prem:=1;
        der:=20;
       end
  else if (selection <max_analyse-10)
       then begin
             prem:=selection-9;
             der:=selection+10;
            end
       else begin
             prem:=max_analyse-19;
             der:=max_analyse;
            end;
  for i:=prem to der
  do begin
      if (i=selection)
      then begin
            writeln;
            write(esp)
           end
      else write('   ');
      write(i:3);write('  ',nom_analyse[i]);
      if (nom_analyse[i]='')
      then writeln('Grille d''analyse vide')
      else writeln;
      if (i=selection) then writeln;
     end;
  writeln;
  writeln;
  writeln;
  writeln;
  writeln;
  writeln;
  centre(Ec,'QUITTER sans '+ch1+' : ''Q''');
  writeln;
  writeln;
  centre(Ec,'D‚placez le curseur avec espace et backspace');
  writeln;
  centre(Ec,'Appuyer sur entree pour '+ch1);
  writeln;
  writeln;
  gotomil;
  clavier(c1);
  if (c1='Q')
  then begin
        selection:=0;
        c1:=#13;
       end;
  if c1=#8 then selection:=cycle(selection,max_analyse,-1)
            else if (c1<>#13) then selection:=cycle(selection,max_analyse,1);
 until c1=#13;

end;


procedure selectionner_partie(cara:char;var selection:integer);
var
 i:integer;
 esp,ch1,ch2:string;
 c1:char;
begin
 selection:=1;
 esp:=' ---> ';
 repeat
  clrscr;
  writeln;
  case cara of
  'S':begin
       ch1:='sauver';
       ch2:='SAUVER';
      end;
  'C':begin
       ch1:='charger';
       ch2:='CHARGER';
      end;
  'A':begin
       ch1:='charger';
       ch2:='MODE PAS A PAS : CHARGER';
      end;
  end;
  centre(Ec,ch2+' UNE PARTIE');
  writeln;
  writeln;
  writeln;
  writeln;
  writeln;
  for i:=1 to max_partie
  do with la_partie[i]
  do begin
      if (i=selection)
      then begin
            writeln;
            write(esp)
           end
      else write('   ');
      write(i:2);write(' - ( ',nom1,' ) VS ( ',nom2);
      if nom2=nom_ordi then write(' Niveau ',niveau);
      writeln(' )  Score :  ',score1,' / ',score2);
      if (i=selection) then writeln;
     end;
  writeln;
  writeln;
  writeln;
  writeln;
  writeln;
  writeln;
  centre(Ec,'QUITTER sans '+ch1+' : ''Q''');

  writeln;
  centre(Ec,'D‚placez le curseur avec espace et backspace');
  centre(Ec,'Appuyer sur entree pour '+ch1);
  writeln;
  writeln;
  gotomil;
  clavier(c1);
  if (c1='Q')
  then begin
        selection:=0;
        c1:=#13;
       end;
  if c1=#8 then selection:=cycle(selection,max_partie,-1)
            else if (c1<>#13) then selection:=cycle(selection,max_partie,1);
 until c1=#13;

end;

procedure sauvegarde_partie;
var
 selection:integer;
 ens:ensemble_char;
 rep:char;
begin
rep:='O';
 repeat
  selectionner_partie('S',selection);
  if (la_partie[selection].nom1<>'')and (selection<>0)
  then begin
   writeln;
   centre(Ec,'Cette sauvegarde contient deja une partie.');
   writeln;
   centre(Ec,'Voulez-vous la remplacer par votre partie ? : ');
   writeln;
   writeln;
   gotomil;
   Ens:=['O','N'];
   garde_fou_char(Ens,rep);
  end;
 until (rep='O')or (selection=0);
if (selection<>0)
then begin
      la_partie[selection]:=grille;
      param_jeu.derniere_sauv:=selection;
     end;
end;

procedure mis_a_jour_analyse(selection:integer;nom:string);
var
 i:integer;
 analyse1:table_jeu;
begin
 assign(fichier_analyse,nom_fichier_analyse);
 reset(fichier_analyse);
 for i:=1 to selection-1
 do read(fichier_analyse,analyse1);
 analyse1:=grille;
 analyse1.nom1:=nom;
 nom_analyse[selection]:=nom;
 write(fichier_analyse,analyse1);
 close(fichier_analyse);
end;

procedure charger_analyse(selection:integer);
var
 i:integer;
 analyse1:table_jeu;
begin
 assign(fichier_analyse,nom_fichier_analyse);
 reset(fichier_analyse);
 for i:=1 to selection
 do read(fichier_analyse,analyse1);
 grille:=analyse1;
 close(fichier_analyse);
end;

procedure sauvegarde_analyse;
var
 selection:integer;
 nom_donne:string;
 ens:ensemble_char;
 rep:char;
begin
rep:='O';
 repeat
  selectionner_analyse('S',selection);
  if (nom_analyse[selection]<>'')and (selection<>0)
  then begin
   writeln;
   centre(Ec,'Cette sauvegarde contient deja une grille.');
   writeln;
   centre(Ec,'Voulez-vous la remplacer par votre grille ?');
   writeln;
   writeln;
   gotomil;
   Ens:=['O','N'];
   garde_fou_char(Ens,rep);
  end;
 until (rep='O')or (selection=0);
if (selection<>0)
then begin
      repeat
       writeln;
       writeln(' Entrez une description (70 caractŠres max) pour votre sauvegarde :');
       writeln;
       readln(nom_donne);
      until length(nom_donne)<70;
      mis_a_jour_analyse(selection,nom_donne);
     end;
end;

procedure definit_Prems;
{Prems est l'ensemble des coups que peut jouer l'ordi s'il commence.
On le fait dans la zone du milieu de la grille.}
var
 cc:col;
 pr,nb:integer;
begin
  Prems:=[];
  nb:=((grille.nb_col+1) div 2)+1;
  pr:=(grille.nb_col-nb)div 2;
  for cc:=(1+pr) to (1+nb) do Prems:=Prems+[cc]
end;

procedure choix_niveau(var niv_choisi:integer);
{procedure qui permet de modifier le niveau du jeu de l'ordi
Plus le niveau est grand, plus il y a d'affinages parmi l'ensemble
des coups posibles}
var
Ens:ensemble_char;
cara:char;
ch0,ch1:string;
code,i,niv:integer;
begin
niv:=param_jeu.niveau_debloque;
bordure_cadre(68);
cadre_milieu(68,'');
cadre_milieu(68,'Choix du Niveau de l''Ordinateur Mental P4 :');
cadre_milieu(68,'');
if param_jeu.niveau_debloque<nb_niveaux
then begin
 cadre_milieu(68,'');
 str(nb_niveaux,ch0);
 cadre_gauche(68,nom_ordi+' possede '+ch0+' niveaux de difficult‚.');
 cadre_gauche(68,'Vous pourrez par la suite jouer avec tous les niveaux.');
 cadre_gauche(68,'Vous devez pour cela debloquer chaque niveau en');
 str(marathon,ch0);
 str(raclee,ch1);
 cadre_gauche(68,'gagnant "un marathon du p4" ('+ch0+' partie minimum)');
 cadre_gauche(68,'avec un score min de '+ch1+' % au niveau le plus fort.');
 cadre_gauche(68,'');
 cadre_gauche(68,'Ci-dessous les niveaux debloques :');
end;
cadre_milieu(68,'');
cadre_milieu(68,'Trouver un niveau adapt‚ : vous etes plutot du genre...');
cadre_milieu(68,'');
for i:=1 to niv
do begin
    str(i,ch1);
    cadre_gauche(68,'['+ch1+'] '+nom_niv[i]);
   end;
cadre_milieu(68,'');
bordure_cadre(68);
writeln;
Ens:=[];
for i:=1 to niv do
begin
 str(i,ch0);
 Ens:=Ens+[ch0[1]];
end;
centre(Ec,'Entrez le niveau souhaite (par ordre croissant de difficulte)');
writeln;
writeln;
gotomil;
garde_fou_char(Ens,cara);
val(cara,niv_choisi,code);
writeln;
writeln;
writeln;
str(niv_choisi,ch0);
centre(Ec,'Mental P4 Niveau '+ch0+' est pret A VOUS AFFRONTER  !!!');
writeln;
writeln;
sleep;
end;

procedure dimensions_defaut;
{procedure qui donne au jeu ses dimensions classiques}
begin
grille.nb_col:=class_col;
grille.nb_lign:=class_lign;
grille.but:=class_but;
nb_case:=grille.nb_col*grille.nb_lign;
niveau_ordi:=param_jeu.dernier_niveau;
definit_Prems;
mis_a_zero_sauvegarde;
end;

procedure modifit_taille_grille;
{procedure qui permet de modifier la taille de la grille de jeu
ainsi que le but a atteindre ex puissance 6 au lieu de 4}
var
Ens:ensemble_char;
cara:char;
code,min,ni:integer;
begin
 clrscr;
 centre(Ec,'TAILLE DE LA GRILLE DE JEU');
 writeln;
 writeln;
 writeln;
 centre(Ec,'Entrez les valeurs desirees pour');
 writeln;
 writeln;
 write('     -Le nombre de colonnes : ');
 garde_fou_nb(min_col,max_col,ni);
 grille.nb_col:=ni;
 write('       -Le nombre de lignes : ');
 garde_fou_nb(min_lign,max_lign,ni);
 grille.nb_lign:=ni;

 if grille.nb_col>=grille.nb_lign then min:=grille.nb_lign else min:=grille.nb_col;
 write('        -Le but a atteindre : ');
 garde_fou_nb(min_but,min,ni);
 grille.but:=ni;
 writeln;
 nb_case:=grille.nb_col*grille.nb_lign;
 mis_a_zero_grille;
 definit_Prems;
end;

{la procedure suivante sert a detecter 1 victoire ds la grille
methode utilisee : a partir de chaque pion 'X' ou '0' de la grille,
on part dans le sens du vecteur (i,j)-->(i+vois_i,j+vois_j)
et on compte combien de pas on a fait avant de rencontrer
un pion etranger ou une case vide.
On utilise 4 directions, on donne les valeurs(vois_i, vois_j) suivantes:
(on rappelle que les colonnes et lignes sont num‚rot‚es de gauche … droite
et de bas en haut)
-verticale de bas en haut (+0,+1)
-horizontale de gauche a droite (+1,+0)
-diagonale de bas en haut et de gauche a droite (+1,+1)
-diagonale de haut en bas et de gauche a droite (+1,-1)

Si on a fait 'But' pas dans une des direction,
c'est qu'il y a une victoire dans la grille.}

procedure succ(cara:char;var rep:boolean;vois_i,vois_j:integer);
label sort_boucle1;
var
decompte,i2,j2:integer;
i:col;
j:lign;

begin
rep:=false;
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
     decompte:=0;
     i2:=i;
     j2:=j;
     {on verifie que P(i2,j2) est dans la grille, puis s'il contient un bon cara}
  while ((i2>0)and(i2<grille.nb_col+1)and(j2>0)and(j2<grille.nb_lign+1)and(grille.Gr[i2][j2]=cara) )
     do begin
         i2:=i2+vois_i;
         j2:=j2+vois_j;
         inc(decompte);
        end;
    if decompte>=grille.but then begin rep:=true; goto sort_boucle1 end;
   end;
sort_boucle1:
end;


procedure evalu(var car:char);
{Procedure qui evalu l'etat de la grille
en donnant une valeur a car dans ['X','0','N','I'] :
gagnee par 'X', '0' , Nulle, Inachavee}
label fin;
var
rep:boolean;
c1:char;
car_pion:array[1..2] of char;
tab_couple:array[1..4] of record vois_i,vois_j:integer;end;
indice1,indice2:integer;
begin
{Rappel des verifications a effectuer
       (0,1);(1,0);(1,1);(1,-1)
On verifie d'abord pour X, ensuite pour 0
DŠs qu'une victoire est decel‚e, on arrete les tests}
car_pion[1]:='X';
car_pion[2]:='0';
with tab_couple[1] do begin vois_i:=0;vois_j:=1; end;
with tab_couple[2] do begin vois_i:=1;vois_j:=0; end;
with tab_couple[3] do begin vois_i:=1;vois_j:=1; end;
with tab_couple[4] do begin vois_i:=1;vois_j:=-1; end;

for indice1:=1 to 2 do for indice2:=1 to 4 do with tab_couple[indice2] do
begin
 c1:=car_pion[indice1];
 succ(c1,rep,vois_i,vois_j);
 if rep=true then begin car:=c1; goto fin; end;
end;
{si on se retrouve ici, c'est qu'on a aucune victoire.
il reste partie nulle ou inachev‚e}
if nb_coup_joue=nb_case then car:='N' else car:='I';
fin:
end;

procedure succ_pot_seul(var total:integer;cara:char;vois_i,vois_j,case_i,case_j:integer);
label sort_boucle1;
var
c2:char;
lign1:lign;
decompte,i2,j2:integer;
i:col;
j:lign;
contient_case:boolean;

begin
total:=0;
c2:=autre(cara);
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
     decompte:=0;
     contient_case:=false;
     i2:=i;
     j2:=j;
     {on verifie que P(i2,j2) est dans la grille, puis s'il contient
     pas de pion ennemi.}
  while ((decompte<grille.but)and(i2>0)and(i2<grille.nb_col+1)and(j2>0)and(j2<grille.nb_lign+1)and(grille.Gr[i2][j2]<>c2) )
     do begin
         if ((i2=case_i)and(j2=case_j)) then contient_case:=true;
         i2:=i2+vois_i;
         j2:=j2+vois_j;
         inc(decompte);
        end;
    if ((decompte>=grille.but)and contient_case)
    then inc(total);
   end;
end;

procedure potentiel_seul(var tot:integer;cara:char;col1:col);
{Procedure qui compte combien de but de cara potentiels
qui contienne au moins 1 pion cara peuvent faire parti
de la grille}
var
tab_couple:array[1..4] of record vois_i,vois_j:integer;end;
indice1,tot2,case_i,case_j:integer;
begin
case_i:=col1;
case_j:=prem_case_libre(col1);
{Rappel des verifications a effectuer
       (0,1);(1,0);(1,1);(1,-1)
On verifie d'abord pour X, ensuite pour 0
DŠs qu'une victoire est decel‚e, on arrete les tests}
with tab_couple[1] do begin vois_i:=0;vois_j:=1; end;
with tab_couple[2] do begin vois_i:=1;vois_j:=0; end;
with tab_couple[3] do begin vois_i:=1;vois_j:=1; end;
with tab_couple[4] do begin vois_i:=1;vois_j:=-1; end;

tot:=0;
for indice1:=2 to 4 do with tab_couple[indice1] do
{c'est mieux de ne pas compter les verticaux qui sont bloquables direct}
 begin
  succ_pot_seul(tot2,cara,vois_i,vois_j,case_i,case_j);
  tot:=tot+tot2;
 end;
end;

procedure potentiel_non_zero(cara:char;var E0:ensemble_col);
var
 col1:col;
 tot:integer;
begin
 E0:=[];
 for col1:=1 to grille.nb_col
 do begin
     potentiel_seul(tot,cara,col1);
     if (tot<>0) then E0:=E0+[col1];
    end;
end;

procedure succ_pot_total(var total:integer;cara:char;vois_i,vois_j:integer);
label sort_boucle1;
var
c2:char;
lign1:lign;
decompte,i2,j2:integer;
i:col;
j:lign;
contient_cara:boolean;

begin
total:=0;
c2:=autre(cara);
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
     decompte:=0;
     contient_cara:=false;
     i2:=i;
     j2:=j;
     {on verifie que P(i2,j2) est dans la grille, puis s'il contient
     pas de pion ennemi.}
  while ((decompte<grille.but)and(i2>0)and(i2<grille.nb_col+1)and(j2>0)and(j2<grille.nb_lign+1)and(grille.Gr[i2][j2]<>c2) )
     do begin
         if (grille.Gr[i2,j2]=cara) then contient_cara:=true;
         i2:=i2+vois_i;
         j2:=j2+vois_j;
         inc(decompte);
        end;
    if ((decompte>=grille.but)and contient_cara)
    then inc(total);
   end;
end;

procedure potentiel_total(var tot:integer;cara:char);
{Procedure qui compte combien de but de cara potentiels
qui contienne au moins 1 pion cara peuvent faire parti
de la grille}
var
tab_couple:array[1..4] of record vois_i,vois_j:integer;end;
indice1,tot2:integer;
begin
{Rappel des verifications a effectuer
       (0,1);(1,0);(1,1);(1,-1)
On verifie d'abord pour X, ensuite pour 0
DŠs qu'une victoire est decel‚e, on arrete les tests}
with tab_couple[1] do begin vois_i:=0;vois_j:=1; end;
with tab_couple[2] do begin vois_i:=1;vois_j:=0; end;
with tab_couple[3] do begin vois_i:=1;vois_j:=1; end;
with tab_couple[4] do begin vois_i:=1;vois_j:=-1; end;

tot:=0;
for indice1:=2 to 4 do with tab_couple[indice1] do
{mieux sans les verticaux !}
 begin
  succ_pot_total(tot2,cara,vois_i,vois_j);
  tot:=tot+tot2;
 end;
end;

{OPA:todo}
procedure succ_emb(var total:integer;cara:char;vois_i,vois_j:integer);
var
c2:char;
lign1:lign;
decompte,decompte_qui,vide_dessous,i2,j2:integer;
i:col;
j:lign;

begin
total:=0;
c2:=autre(cara);
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
     decompte_qui:=0;
     decompte:=0;
     vide_dessous:=0;
     i2:=i;
     j2:=j;
     {on verifie que P(i2,j2) est dans la grille, puis s'il contient
     pas de pion ennemi.}
  while ((decompte<grille.but)and(i2>0)and(i2<grille.nb_col+1)and(j2>0)and(j2<grille.nb_lign+1)and(grille.Gr[i2][j2]<>c2) )
     do begin
         if (j2>1)and(grille.Gr[i2,j2-1]=' ') then inc(vide_dessous);
         if (grille.Gr[i2,j2]=cara) then inc(decompte_qui);
         inc(decompte);
         i2:=i2+vois_i;
         j2:=j2+vois_j;
        end;
    if ((decompte=grille.but)and (decompte_qui=grille.but-2) and (vide_dessous=2))
    then inc(total);
   end;
end;

{OPA:todo}
procedure tot_emb(var tot:integer;cara:char);
{Procedure qui compte combien de embr de font parti de la grille}
var
tab_couple:array[1..4] of record vois_i,vois_j:integer;end;
indice1,tot2:integer;
begin
{Rappel des verifications a effectuer
       (0,1);(1,0);(1,1);(1,-1) }
with tab_couple[1] do begin vois_i:=0;vois_j:=1; end;
with tab_couple[2] do begin vois_i:=1;vois_j:=0; end;
with tab_couple[3] do begin vois_i:=1;vois_j:=1; end;
with tab_couple[4] do begin vois_i:=1;vois_j:=-1; end;

tot:=0;
for indice1:=2 to 4 do with tab_couple[indice1] do
{rien ne sert ici de verifier les veticaux qui n'auront pas le vide_dessous}
 begin
  succ_emb(tot2,cara,vois_i,vois_j);
  tot:=tot+tot2;
 end;
end;


procedure tire_coup(var E:ensemble_col; var le_coup:col);
{procedure qui tire au sort un coup de l'ensemble E
On utilise cette procedure a la fin des affinages de
l'ensemble des coups possibles si il en reste plusieurs}
var
cardinal,n,i:integer;
alpha:col;
begin
{1 calculer le card}
cardinal:=card(E);
{2 tirer au sort un entier n de [1..card]}
randomize;
n:=trunc(random*cardinal)+1;
{3 selectionner l'element numero n}
alpha:=1;
i:=0;
while ((alpha<grille.nb_col+1)and (i<>n))
do begin
    if (alpha in E) then inc(i);
    if (i=n) then le_coup:=alpha;
    inc(alpha);
   end;
end;

procedure coup_valid(coup:col;var resultat:boolean);
{procedure qui permet de savoir si un coup est valide
c'est a dire si la colonne de ce coup n'est pas
deja remplie de pions}
var
j:integer;
begin
j:=prem_case_libre(coup);
if j<grille.nb_lign+1 then resultat:=true else resultat:=false;
end;


procedure coup_poss(var Ensemble:ensemble_col);
{forme l'ensemble des coups physiquement possible dans la grille
c'est a dire qu'il n'y aucun affinage ds cette procedure
c'est simplement l'ensemble des coups valides}
var
i:col;
poss:boolean;
begin

Ensemble:=[];
for i:=1 to grille.nb_col
do begin
    coup_valid(i,poss);
    if poss then Ensemble:=Ensemble + [i];
   end;

end;

procedure ajoute(car:char;coup:col);
{procedure qui ajoute un pion 'car' dans la colonne 'coup'
en accord avec la gravite.
en principe les protections de validite du coup sont en amont
de cette procedure et le else(BUG) n'est jamais cense devoir servir}
var
j:integer;
begin
j:=prem_case_libre(coup);
if vacante(coup,j) then grille.Gr[coup][j]:=car
                         else begin
                              writeln('BUG !!!!!!!!!!!');readln;
                              end;
end;

procedure enleve(coup:col);
{enleve le pion le plus haut dans la colonne Coup}
var
j:integer;
begin
j:=prem_case_libre(coup);
if j>1 then grille.Gr[coup][j-1]:=' ';
end;

{les procedures pose et leve n'obeissent pas au regle de la gravite}
procedure pose(car:char;i:col;j:lign);
{met un pion 'car' dans la case(i,j)}
begin
grille.Gr[i][j]:=car;
end;

procedure leve(i:col;j:lign);
{enleve le pion de la case(i,j)}
begin
grille.Gr[i][j]:=' ';
end;


procedure inc_analyse;
{procedure qui sert a l'affichage de la barre d'analyse
lorsque l'ordi reflechit et prend du temps pour jouer.
Cette procedure n'a pas d'utilite pour le jeu lui meme
mais offre le confort de voir que la bete n'est pas plantee
mais que l'utilisateur lui donne juste un peu de fil a retordre}
begin
recherche:=recherche+step;
while ((recherche-nb_trait)>(100/78)) do begin inc(nb_trait);write('-');end;
end;

procedure mis_a_jour_info;
{met a jour les infos concernant les cases vides uniquement.
les cases pleines seront = (false,false)}
label fin3;
var
i:col;
j:lign;
resul:char;

begin
mis_a_zero_info;    {= tout a false}
evalu(resul);
if ((resul='X') or (resul='0'))then goto fin3;
{ainsi les infos reste a false et cela evite des conclusions bizarres
dans gagne en un dans le cas de l'envoi d'une grille gagnante}

for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
    if (grille.Gr[i][j]=' ')
    then begin
           pose('X',i,j);
           evalu(resul);
           leve(i,j);
           if resul='X' then info[i][j].gagnx:=true;

           pose('0',i,j);
           evalu(resul);
           leve(i,j);
           if resul='0' then info[i][j].gagn0:=true;

         end;
    end;
fin3:
end;

{OPA:IAMinMax.max}
procedure coup_max_pot(E:ensemble_col;var Ens_max:ensemble_col);
{donne parmi les coups de E les coups qui laissent le plus de potentiel}
var
 essai:col;
 c:char;
 max,tot1:integer;
 a:array[col] of integer;
begin
c:=quijou;
max:=0;
Ens_max:=[];
for essai:=1 to grille.nb_col
do if (essai in E)
then begin
      ajoute(c,essai);
      potentiel_total(tot1,c);
      enleve(essai);
      a[essai]:=tot1;
      if (a[essai]>max) then max:=a[essai];
     end;
{une fois tous parcouru, min vaut inf a[n]
on selectionne tous les n tel que a[n]=min}
for essai:=1 to grille.nb_col
do if (essai in E)
then begin
      if (a[essai]=max) then Ens_max:=Ens_max+[essai];
     end;
end;

{OPA:IAMinMax.min}
procedure coup_insecticide(E:ensemble_col;var Ens_min:ensemble_col);
{donne parmi les coups de E les coups qui laissent le moins de potentiel
a l'autre}
var
 essai:col;
 c1,c2:char;
 min,tot1:integer;
 a:array[col] of integer;
begin
c1:=quijou;
c2:=autre(c1);
min:=1000;
Ens_min:=[];
for essai:=1 to grille.nb_col
do if (essai in E)
then begin
      ajoute(c1,essai);
      potentiel_total(tot1,c2);
      enleve(essai);
      a[essai]:=tot1;
      if (a[essai]<min) then min:=a[essai];
     end;
{une fois tous parcouru, min vaut inf a[n]
on selectionne tous les n tel que a[n]=min}
for essai:=1 to grille.nb_col
do if (essai in E)
then begin
      if (a[essai]=min) then Ens_min:=Ens_min+[essai];
     end;
end;

{OPA:IAWinning.compute_winning_hint}
procedure compte_cases_gagnantes(var qui:char;var tot_pair,tot_impair:integer);
{procedure qui compte combien de cases ont la propriete suivante :
remplie par un pion 'qui', la grille est gagnee par 'qui'
on compte en tout combien il y a de case d'attente. S'il y a un nombre
pair de case d'attente, c'est pair, sinin impair.}
var
i:col;
j:lign;
est_gagnante:boolean;
begin
mis_a_jour_info;
tot_pair:=0;
tot_impair:=0;
for i:=1 to grille.nb_col
do for j:=1 to grille.nb_lign
do begin
{a partir du niveau niveau_germe, seules les germes en l'air sont retenues comme germes
et celle dont le dessous n'est pas gagnant pour l'autre !}
 if (niveau_ordi<niveau_germe)
 then est_gagnante:=
 (grille.Gr[i][j]=' ')and
 ( ((qui='X')and(info[i][j].gagnx=true)) or ((qui='0')and(info[i][j].gagn0=true)))
 else est_gagnante:=
 (j>1)and(grille.Gr[i][j]=' ')and(grille.Gr[i][j-1]=' ')and
 ( ((qui='X')and(info[i][j].gagnx=true)and(info[i][j-1].gagn0=false))
 or((qui='0')and(info[i][j].gagn0=true)and(info[i][j-1].gagnX=false)));
 if est_gagnante
      then begin
            if ((j mod 2)=0)
            then inc(tot_pair)
            else inc(tot_impair);
           end;
    end;
end;

procedure coup_germe(parite:integer;var Ens4:ensemble_col);
{procedure recherchant les coups qui vont etre a l'origine d'une germe.
on ne garde pas les germes qui se bloquent tout de suite.au niveau germe.
donc on verifie si la case sous la case gagnante est vide.
d'autre part : si on est germe juste au dessu d'une germe ennemi,
ce n'est pas une vrai germe.
il faut donc v‚ifier aussi si la case du dessous est non gagnante pour ennemi.
Methode utilisee :
On calcul le total des cases_gagnantes(voir procedure compte_cases_gagnantes)
avant et apres le coup analyse dans les possibilite de germe.
Si un coup est a l'orgine d'une germe, le total aura augmente entre temps.}
var
i:col;
tot_pair1,tot_impair1,tot_pair2,tot_impair2:integer;
qui:char;
poss,ens_pair,ens_impair:ensemble_col;

begin
qui:=quijou;
coup_poss(poss);
Ens4:=[];
compte_cases_gagnantes(qui,tot_pair1,tot_impair1);
  for i:=1 to grille.nb_col do if (i in poss)
  then begin
        ajoute(qui,i);
        compte_cases_gagnantes(qui,tot_pair2,tot_impair2);
        enleve(i);
        if ( ((tot_pair1<tot_pair2)    and (parite=0))
        or   ((tot_impair1<tot_impair2)and (parite=1)) ) then Ens4:=Ens4+[i]
       end;

end;

{OPA:IAGerm}
{Warning:unused computation there 2 * coup_germ, switch parity}
procedure coup_non_germe(parite:integer;var non_gege:ensemble_col);
{procedure qui forme l'ensemble des coups qui ne permettent pas
a l'adversaire de former une germe au coup d'apres.
Si cet ensemble est vide, elle forme alors l'ensemble des
coups qui donne la possibilite a l'autre joueur de former le
moins de germes possibles}
var
col1:col;
ch1,ch2:char;
free,non_bidon,gege_pair,gege_impair:ensemble_col;
begin
ch1:=quijou;
cH2:=autre(ch1);
coup_poss(free);
Non_gege:=[];
for col1:=1 to grille.nb_col do if (col1 in free)
then begin
        if (not tutoriel) then inc_analyse;
        ajoute(ch1,col1);
        coup_germe(0,gege_pair);
        coup_germe(1,gege_impair);
        enleve(col1);
        if (  ( (gege_pair=[])  and(parite=0) )
        or    ( (gege_impair=[])and(parite=1) )  )
        then Non_gege:=Non_gege+[col1];
     end;
end;

procedure coup_embryon(E:ensemble_col;var Emb:ensemble_col);
{procedure recherchant les coups qui vont etre a l'origine d'un maximum
d''embryon.
Methode utilisee :
On calcul le total tot_emb
avant et apres le coup analyse dans les possibilites.
Si un coup est a l'orgine d'une emb, le total aura augmente entre temps.
on selectionne ensuite les max}
var
i:col;
tot1,tot2,max:integer;
a:array[col]of integer;
qui:char;

begin
 Emb:=[];
 max:=-30;
 qui:=quijou;
 tot_emb(tot1,qui);
  for i:=1 to grille.nb_col do if (i in E)
  then begin
        ajoute(qui,i);
        tot_emb(tot2,qui);
        enleve(i);
        a[i]:=tot2-tot1;
        if a[i]>0 then Emb:=Emb+[i];
        if a[i]>max then max:=a[i];
       end;
  {version max embryon
  if max>0 then
  for i:=1 to grille.nb_col do if (i in E)
  then begin
        if a[i]=max then Emb:=Emb+[i]
       end;          }
end;

procedure coup_max_conjoint(var qui:char;var E3:ensemble_col;var Ens_max:ensemble_col);
{procedure qui determine dans un ensemble de coup ceux qui font tomber
le pion 'qui' dans une case qui en touche un maximum d'autres
Cela permet de ne pas jouer ses pions 'isoles'}
var
essai2:col;
la_lign2:lign;
max:integer;
a:array[col] of integer;
begin
max:=0;
Ens_max:=[];
for essai2:=1 to grille.nb_col
do if (essai2 in E3)
then begin
    la_lign2:=prem_case_libre(essai2);
    a[essai2]:=touche_pion(essai2,la_lign2,qui);
    if (a[essai2]>max) then max:=a[essai2];
   end
else a[essai2]:=0;
{une fois tous parcouru, max vaut sup a[n]
on selectionne tous les n tel que a[n]=max
et on tire au sort}
for essai2:=1 to grille.nb_col do if (essai2 in E3)
then begin
      if (a[essai2]=max) then Ens_max:=Ens_max+[essai2];
     end;
end;

procedure gagne_en_un(var qui:char; var place:integer);
{Procedure qui retourne le numero du coup a jouer si la victoire
peut etre immediate. elle retourne 0 dans le cas contraire}
label sort_boucle5;
var
essai_jeu:col;
libre:ensemble_col;
gagne:boolean;
resul:char;

begin
coup_poss(libre);
gagne:=false;
for essai_jeu:=1 to grille.nb_col do if (essai_jeu in libre) then
  begin
    ajoute(qui,essai_jeu);
    evalu(resul);
    enleve(essai_jeu);
    gagne:=(resul=qui);
    if gagne then goto sort_boucle5;
  end;
sort_boucle5:
if gagne then place:=essai_jeu else place:=0;
end;

procedure coup_non_bidon(var non_Bibi:ensemble_col);
{procedure qui forme l'ensemble des coups qui ne sont pas
des 'coups bidons' (voir nomenclature)}
var
col1:col;
place5:integer;
ch1,ch2:char;
free:ensemble_col;
begin
ch1:=quijou;
cH2:=autre(ch1);
coup_poss(free);
Non_bibi:=[];
for col1:=1 to grille.nb_col do if (col1 in free)
then begin
        ajoute(ch1,col1);
        gagne_en_un(ch2,place5);
        enleve(col1);
        if (place5=0) then Non_bibi:=Non_bibi+[col1];
     end;
end;

{OPA:TODO}
procedure coup_non_semi_bidon(parite:integer;var non_semi_Bibi:ensemble_col);
{procedure qui forme l'ensemble des coups qui ne sont pas
des 'coups semi-bidons' (voir nomenclature)
non_semi_bibi_pair est l'ensemble des coups qui ne gache pas de pair
il faut juste attirer l''attention sur le fait que pour joueur 0,
qu'un nombre pair d'impair est gagnant et qu'il ne faut pas le gacher}
var
col1:col;
pair_dimpair:boolean;
la_lign:lign;
resul5:char;
ch1,ch2:char;
free:ensemble_col;
tot_pair,tot_impair:integer;
begin
ch1:=quijou;
cH2:=autre(ch1);
pair_dimpair:=false;
if (ch1='0')
then begin
      compte_cases_gagnantes(ch1,tot_pair,tot_impair);
      pair_dimpair:=(tot_impair mod 2=0)
     end;
coup_poss(free);
Non_semi_bibi:=[];
for col1:=1 to grille.nb_col do if (col1 in free)
then begin
        la_lign:=prem_case_libre(col1);
        if la_lign<grille.nb_lign
        then begin
              pose(ch1,col1,la_lign+1);
              evalu(resul5);
              leve(col1,la_lign+1);
              if (resul5<>ch1)
              then Non_semi_bibi:=Non_semi_bibi+[col1]
              else if (((la_lign+1)mod 2<>parite )and not(pair_dimpair))
                   then Non_semi_bibi:=Non_semi_bibi+[col1];
            end
        else Non_semi_bibi:=Non_semi_bibi+[col1];
     end;
end;

procedure contient_lointain(car:char; var rep7:boolean;var col7:col);
{procedure qui permet de savoir si la grille contient un coup lointain
pour le joueur 'car'. Elle retourne true ou false et le numero
de la colonne ou est le coup lointain si true.
problemes lies aux coups lointains : ils sont annules si l'adversaire
peut gagner dans la meme colonne en dessous de la deuxieme case du lointain}
label sort_petite_boucle1,sort_petite_boucle2,
sort_grande_boucle,saute;
var
i:col;
j,j2:lign;
contient,annule,total:boolean;
begin
 mis_a_jour_info;

 case car of
 'X':
 for i:=1 to grille.nb_col do
  for j:=1 to (grille.nb_lign-1)
  do if (info[i][j].gagnx)
    then begin
          contient:=(info[i][j+1].gagnx);
          annule:=false;
          for j2:=1 to j{verifier que l'autre ne peut gagner
          jusqu'a la premier des 2 lign : j}
              do begin
                  annule:=( info[i][j2].gagn0);
                  if annule then goto sort_petite_boucle1;
                 end;
          sort_petite_boucle1:
          total:=(contient and (not(annule)) );
          if total then goto sort_grande_boucle;
         end;


 '0':
 for i:=1 to grille.nb_col do
  for j:=1 to (grille.nb_lign-1)
  do if (info[i][j].gagn0)
    then begin
          contient:=(info[i][j+1].gagn0);
          annule:=false;
          for j2:=1 to j{verifier que l'autre ne peut gagner
          jusqu'a la premier des 2 lign : j}
              do begin
                  annule:=( info[i][j2].gagnX);
                  if annule then goto sort_petite_boucle2;
                 end;
          sort_petite_boucle2:
          total:=(contient and (not(annule)) );
          if total then goto sort_grande_boucle;
         end;

 end;{du case of}

rep7:=false;
goto saute;

sort_grande_boucle:
rep7:=total;
col7:=i;
saute:
end;

procedure coup_lointain(var Loin:ensemble_col);
{trouve le coup s'il existe a jouer pour faire un coup lointain.
Si la grille en contient deja un, alors il fait jouer en dessous
lointain=[case ou il faut jouer pour s'en rapprocher]}
label termine8;
var
resul:boolean;
col8,ci:col;
qui:char;
poss:ensemble_col;

begin
Loin:=[];
qui:=quijou;
coup_poss(poss);
contient_lointain(qui,resul,col8);
if resul then begin Loin:=[col8];goto termine8;end;

for ci:=1 to grille.nb_col do if (ci in poss)
then begin
       ajoute(qui,ci);
       contient_lointain(qui,resul,col8);
       enleve(ci);
       if resul then Loin:=Loin+[ci];
     end;

termine8:
end;

procedure coup_non_lointain(var non_loin:ensemble_col);
{forme l'ensemble des coups qui ne permettent pas a l'adversaire de
faire un coup lointain au coup d'apres}
var
col1:col;
ch1,ch2:char;
free,loin:ensemble_col;
begin
ch1:=quijou;
cH2:=autre(ch1);
coup_poss(free);
Non_loin:=[];
for col1:=1 to grille.nb_col do if (col1 in free)
then begin
        if (not tutoriel) then inc_analyse;
        ajoute(ch1,col1);
        coup_lointain(loin);
        enleve(col1);
        if (loin=[]) then Non_loin:=Non_loin+[col1];
     end;
end;



procedure coup_force(var qui:char;var place4:integer);
{Procedure de recherche de strategie forcee(voir nomenclature)
Grace aux possibilites des procedures recursives en langage pascal,
on peut trouver des strategies forcees aussi longues en nombres de coups
que l'on veut. L'ordi annalyse s'il peut forcer le coup de l'adversaire
en faisant un puissance (But-1), une fois celui-la bloque, l'ordi a de
nouveau le trait, il se repose la meme question avec la nouvelle grille
(virtuelle car les coups n'ont pas ete joues dans la vrai partie)
si il peut encore forcer un coup il le fait etc...
Au bout d'un moment soit
*il ne peut plus forcer de coup :
  auquel cas on ne parle pas de strategie forcee
*il gagne : il a trouver une stategie forcee place4
*il peut faire un coup lointain  (reserve au niveau 5)}
label sort_boucle9;
var
loin1:ensemble_col;
post_1,colx:col;
qui2:char;
resul2,resul3:integer ;
save_grille:table_jeu;
E1,non_bidon,tres_loin,non_bidon_post1:ensemble_col;

begin
qui2:=autre(qui);
{si x peut faire un coup force alors just apres qu'il ai joue,
gagne_en_un(X) vrai et qd 0 joue, X peut jouer fatal ou gagnant}
place4:=0;
save_grille:=grille;
coup_poss(E1);
coup_non_bidon(non_bidon);
for post_1:=1 to grille.nb_col  {on le fait jouer dans chaque case Non_bidon}
do if (post_1 in non_bidon)
then begin
    ajoute(qui,post_1);
    gagne_en_un(qui,resul2);
    coup_non_bidon(non_bidon_post1);
    if ((resul2<>0) or (card(non_bidon_post1)=1))
    {un coup peut etre force par rejet de toute les autres cases}
    then begin
    if (resul2=0) then begin
                        tire_coup(non_bidon_post1,colx);
                        resul2:=colx;
                       end;
    ajoute(qui2,resul2);
    {la possibilite de creer une strategie forcee a l'origine
    d'un coup lointain est reservee au niveau 5. Pour masquer l'effet
    de l'analyse on affecte [] a tres_loin si niveau_ordi<>5}
    tres_loin:=[];
    if niveau_ordi>=niveau_lointain then coup_lointain(tres_loin);
    gagne_en_un(qui,resul3);
    if ((resul3<>0)or(card(tres_loin)<>0)) then begin place4:=post_1;goto sort_boucle9;end;

    coup_force(qui,resul3);
    {ici est l'appel recursif de la procedure a elle-meme
    mais la grille n'est plus la meme : on y a ajoute(qui2,resul2)}
    if (resul3<>0) then begin place4:=post_1;goto sort_boucle9;end;
    enleve(resul2);

          end;
    {l'analyse finie, on recommence avec une autre case de jeu}
    enleve(post_1);

    end;
sort_boucle9:
grille:=save_grille;
end;

procedure coup_non_force(var non_fofo:ensemble_col);
{procedure qui forme l'ensemble des coups qui ne permettent pas
a l'adversaire de faire une strategie forcee au coup d'apres}
var
col1:col;
place7:integer;
ch1,ch2:char;
free,non_bidon:ensemble_col;
begin
ch1:=quijou;
cH2:=autre(ch1);
coup_poss(free);
coup_non_bidon(non_bidon);
Non_fofo:=[];
for col1:=1 to grille.nb_col do if (col1 in non_bidon)
then begin
        if (not tutoriel) then inc_analyse;
        ajoute(ch1,col1);
        coup_force(ch2,place7);
        enleve(col1);
        if (place7=0) then Non_fofo:=Non_fofo+[col1];
     end;
end;

procedure  coup_stratege(var Er,strat:ensemble_col);
{il est possible qu'en jouant un certain coup, l'adversaire
se retrouve dans une des situations suivantes :
*suicide : non_force=[] il ne peut plus empecher une strategie forcee
*complexe:non_lointain=[] il ne peut plus empecher un coup lointain
*plus tordue:non_lointain*non_force=[]
Cette procedure recherche de tel coups qui conduisent
donc a une victoire certaine}
var
post1,post2:col;
c,c2:char;
non_force,non_bibi,non_lointain,Er2:ensemble_col;
save_grille:table_jeu;
begin
c:=quijou;
c2:=autre(c);
save_grille:=grille;
strat:=[];
for post1:=1 to grille.nb_col do if post1 in Er
then begin
    ajoute(c,post1);
     coup_non_force(non_force);
     if (non_force<>[]) then coup_non_lointain(non_lointain);
     Er2:=non_lointain*non_force;
     enleve(post1);
     if (Er2=[]) then strat:=strat+[post1];
     end;


grille:=save_grille;
end;

procedure coup_non_stratege(le_coup:col;var non_strat:boolean);
{cette procedure permait de verifier qu'un coup joue evite que
l'adversaire ne fasse un coup strategique. L'analyse est beaucoup
trop longue pour v‚rifier tous les coups poss. Mieux vaut un
programme moin fort et plus rapide. Donc on ne verifie que les
coups retenus en fin de priorite dans les cas ou il n'y en a pas trop
voir pour ca la constante max_non_strat.}
var
ch1,ch2:char;
free,strat,Er,non_force,non_lointain:ensemble_col;
begin
ch1:=quijou;
cH2:=autre(ch1);
coup_poss(free);
ajoute(ch1,le_coup);
coup_non_force(non_force);
coup_non_lointain(non_lointain);
Er:=non_force*non_lointain;
coup_stratege(Er,strat);
enleve(le_coup);
if (strat=[]) then non_strat:=true
              else non_strat:=false;
end;

procedure affichage_barre_analyse(nb_analyse:integer);
begin
 step:=78/nb_analyse;
 recherche:=0;
 nb_trait:=0;
 writeln('Analyse en cours : ');
 writeln('0%                25%                50%                75%               100%');
end;


procedure trouve_coup(var le_coup:col);
{procedure qui va choisir le coup joue par l'ordi
si la sitution n'est pas triviale (bloque ou gagne), on utilise
tous les ensembles formes par les procedures ci-dessus
Ces ensembles sont classes par priorites
On les appelle les Ei avec i croissant quand l'importance de la priorite
decroit.
On forme ensuite l'ensemble suivant :
(E1 inter E2) ou si c'est vide on conserve E1
ensuite, on decale les Ei : E(i+1) devient Ei et on reitere.
C'est la qu'intervient le niveau de l'ordi
plus il est regle faible, moins il considere de priorites et d'ensembles

Cette procedure est la plus longue du programme
c'est le coeur du jeu}

label termine,suicide_cache;
const
vide:ensemble_col=[];
var
coup_garde,col1:col;
est_non_strat:boolean;
c,c2:char;
place,nb_analyse,tot1,tot2:integer;
Libre,non_force,les_choix1,les_choix2,non_bidon,non_semi_bidon_pair,non_semi_bidon_impair,
non_semi_bien,non_semi_moy,affinage,germe_pair,germe_impair,non_germe_bien,non_germe_moy,
lointain,non_lointain,Nre,Nre2,strat,non_strat,Er1,bonne_germe,moy_germe,
retenus,non_zero,embryon,max_pot,insecticide,max_conjoint,affinage1:ensemble_col;

begin
{np est le numero de la priorite qui a permi de jouer}
c:=quijou;
c2:=autre(c);
{fonctionne a l'ordre de priorite. Des qu'une priorite est remplie,
le travail est fini d'ou le goto termine apres chaque priorite}
if tutoriel
then begin
      writeln('Analyse de la grille pour les ',c,' : ');
      writeln;
     end;
{Est-ce que l'ordi peut gagner ?}
gagne_en_un(c,place);
if (place<>0)
then begin
      if tutoriel then writeln(c,' gagne immediatement : ',place);
      le_coup:=place;
      goto termine;
     end;

{Est-ce que l'ordi doit bloquer ?}
gagne_en_un(c2,place);
if (place<>0)
then begin
      if tutoriel then writeln(c,' bloque ', c2,' en : ',place);
      le_coup:=place;
      goto termine;
     end;


{L'ordi peut t'il faire une stategie forcee ? }
if niveau_ordi>=niveau_force then
begin
 coup_force(c,place);
 if (place<>0)
 then begin
       if tutoriel then writeln(c,' fait une strategie forcee : ',place);
       le_coup:=place;
       goto termine;
      end;
end;


{a partir d'ici,on va partir de l'ensemble des coups poss
et affiner la selection au fur et a mesures selon le niveau }
coup_poss(libre);
coup_non_bidon(non_bidon);
coup_non_semi_bidon(0,non_semi_bidon_pair);
coup_non_semi_bidon(1,non_semi_bidon_impair);

{affichage de l'etat de recherche
 ici on calcul le nombre d'analyse, information necessaire pour un bon
 fonctionnement de la barre d'analyse
 le nombre d'analyse est le nombre d'appel de la procedure inc_analyse
 lors de l'analyse
 ces appels sont places dans certaine procedure, de fa‡on reguliere environ}
 if (niveau_ordi>=4)
 then nb_analyse:=card(libre)*2+card(non_bidon)*(card(non_bidon)+card(libre)+1)
 else nb_analyse:=card(libre)*2+card(non_bidon);
 if not(tutoriel) then affichage_barre_analyse(nb_analyse);
{fin de l'affichage}

{l'ordi peut-il empecher l'adversaire de realiser une strategie forcee ?}
if (niveau_ordi>=niveau_force)
then begin
      coup_non_force(non_force);
     end
else begin
      non_force:=[];
     end;
{recherche des coups lointains.}
if (niveau_ordi>=niveau_lointain)
then begin
      coup_lointain(lointain);
      coup_non_lointain(non_lointain);
      Er1:=non_force*non_lointain;
      coup_stratege(Er1,strat);
     end
else begin
       lointain:=[];
       non_lointain:=[];
       strat:=[];
     end;
{ANALYSE DES GERMES}
coup_germe(0,germe_pair);
coup_germe(1,germe_impair);
if c='X'
then begin
      coup_non_germe(0,non_germe_bien);
      coup_non_germe(1,non_germe_moy);
     end
else begin
      coup_non_germe(0,non_germe_moy);
      coup_non_germe(1,non_germe_bien);
     end;
if (c='X')
then begin
      non_semi_bien:=non_semi_bidon_impair;
      non_semi_moy:=non_semi_bidon_pair;
      bonne_germe:=germe_impair;
      moy_germe:=germe_pair;
     end
else begin
      non_semi_bien:=non_semi_bidon_pair;
      non_semi_moy:=non_semi_bidon_impair;
      bonne_germe:=germe_pair;
      moy_germe:=germe_impair;
     end;
if niveau_ordi >1 then potentiel_non_zero(c,non_zero) else non_zero:=[];
Nre2:=(non_germe_bien)*(non_germe_moy);
if (niveau_ordi<niveau_germe)
then begin
      non_germe_bien:=Nre2;
      non_germe_moy:=[];
      {il ne fait pas la difference pour germe et semi-bidon}
      moy_germe:=moy_germe+bonne_germe;
      bonne_germe:=[];
      non_semi_bien:=non_semi_moy+non_semi_bien;
      non_semi_moy:=vide;
     end;
if niveau_ordi<3
then begin
      non_germe_bien:=[];
      non_germe_moy:=[];
      moy_germe:=[];
      moy_germe:=[];
      bonne_germe:=[];
      non_semi_bien:=[];
      non_semi_moy:=[];
     end;
{ici, toutes les analyses des niveaux 1-4 sont finies,
on remplie la barre d'analyse si ce n'est pas le cas}
if not(tutoriel)
then begin
      while (nb_trait<78) do begin inc(nb_trait);write('-');end;
      writeln;
     end;

{interpretation des ensembles formes}
magic_inter(libre,non_bidon,non_force,affinage);
magic_inter(affinage,non_lointain,non_semi_bien,Nre);
{en effet, on est en train de faire des plans sur
la comete, ce serait dommage de gacher un but-1 deja fait}
affinage:=Nre;
magic_inter(affinage,lointain,strat,Nre);
affinage:=Nre;
magic_inter(affinage,non_semi_moy,bonne_germe,Nre);
affinage:=Nre;
magic_inter(affinage,moy_germe,non_germe_bien,Nre);
affinage:=Nre;
magic_inter(affinage,non_zero,non_germe_moy,Nre);
retenus:=Nre;
affinage1:=retenus;
if niveau_ordi<niveau_embryon
then begin
      {jouer conjoint a ses propres pions : }
      coup_max_conjoint(c,retenus,les_choix1);
      {jouer conjoint des pions de l'adversaire : }
      coup_max_conjoint(c2,les_choix1,les_choix2);
      magic_inter(retenus,les_choix1,les_choix2,Nre);
      max_conjoint:=Nre;
      affinage:=max_conjoint;
      embryon:=[];
      max_pot:=[];
      insecticide:=[];
     end
else begin
      {un embryon peutnetre seulement dans un non zero
      si npas d'embryon,
      on regarde dans les coups non potentiel zero les max pot
      si non_zero=vide alors max_pot est vide.
      on prend alors insecticide}
      coup_embryon(retenus,embryon);
      magic_inter(retenus,embryon,non_zero,retenus);
      coup_max_pot(retenus,max_pot);
      coup_insecticide(retenus,insecticide);
      magic_inter(retenus,max_pot,insecticide,affinage);
     end;
tire_coup(affinage,le_coup);

{affichage des ensembles si tutoriel}
if tutoriel then
begin
 centre(18,'Libres');centre(18,'Non suicidaires');
 centre(18,'Non gach. pair');centre(18,'Non gach. impair');
 writeln;
 centre_Ens_col(18,libre);centre_Ens_col(18,non_bidon);
 centre_Ens_col(18,non_semi_bidon_pair);centre_Ens_col(18,non_semi_bidon_impair);
 writeln;writeln;

 centre(18,'Non gach. import');centre(18,'Non gach. autres');
 centre(18,'Germantes paires');centre(18,'Germantes impaires');
 writeln;
 centre_Ens_col(18,non_semi_bien);centre_Ens_col(18,non_semi_moy);
 centre_Ens_col(18,germe_pair);centre_Ens_col(18,germe_impair);
 writeln;writeln;

 centre(18,'Germes bon germes');centre(18,'Germes moy germes');
 centre(18,'Bonnes De-germes');centre(18,'Moy De-germes');
 writeln;
 centre_Ens_col(18,bonne_germe);centre_Ens_col(18,moy_germe);
 centre_Ens_col(18,non_germe_bien);centre_Ens_col(18,non_germe_moy);
 writeln;writeln;

 centre(18,'Contr stra-forcee');centre(18,'Strategiques');
 centre(18,'Contr cp-lointain');centre(18,'Coup lointain');
 writeln;
 centre_Ens_col(18,non_force);centre_Ens_col(18,strat);
 centre_Ens_col(18,non_lointain);centre_Ens_col(18,lointain);
 writeln;writeln;

 centre(18,'Non zero Pot');centre(18,'Premier affinage');
 centre(18,'Max_conjoints');
 writeln;
 centre_Ens_col(18,non_zero);centre_Ens_col(18,affinage1);
 centre_Ens_col(18,max_conjoint);
 writeln;writeln;

 centre(18,'Embryons');centre(18,'Max pot');
 centre(18,'Insecticide');centre(18,'Coup final');
 writeln;
 centre_Ens_col(18,embryon);centre_ens_col(18,max_pot);
 centre_ens_col(18,insecticide);Nre:=[le_coup];centre_ens_col(18,Nre);
 writeln;writeln;
end;

termine:
end;

procedure genere_un_coup;
{rempli la grille avec un coup de la procedure trouve coup}
var
coup_genere:col;
poss:ensemble_col;
begin
{pour varier les debuts, on le fait jouer au hasard le premier coup
entre les coups de l'ensemble Prems}
if nb_coup_joue=0
 then tire_coup(Prems,coup_genere)
 else trouve_coup(coup_genere);

coup_poss(poss);
{protection nutile, a enlever a terme
le test se trouvant auusi dans la procedure trouve_coup}
if coup_genere in poss then ajoute(quijou,coup_genere)
                      else begin writeln('Bug');readln;end;
{partie_en_cours[nb_coup_joue(grille)]:=coup_genere; }
end;

procedure dessine_special;
{procedure graphique des grilles qui ne sont pas de dimensions classique}
var
i:col;
j:lign;
marge:string;
nb_espace,a:integer;
n:1..max_nb_case+1;
st:array[lign]of string[80];
st0:string[80];
Num:string[1];
begin
for i:=1 to grille.nb_col do st[i]:='';
nb_espace:=(80-(grille.nb_col*3)) div 2;
marge:='';
for a:=1 to nb_espace do marge:=marge+' ';
st0:=marge;

for i:=1 to grille.nb_col
do begin
   str(i mod 10,Num);
   st0:=st0+Num+'  ';
   end;
writeln(st0);
writeln;

for j:=grille.nb_lign downto 1
do begin
    st[j]:=marge;
    for i:=1 to grille.nb_col do if grille.Gr[i][j]=' ' then st[j]:=st[j]+'.'+'  '
                                             else  st[j]:=st[j]+grille.Gr[i][j]+'  ';
    writeln(st[j]);
    writeln;
   end;
writeln(st0);
end;

procedure dessine_grille(cara:char);
{procedure graphique de la grille classique}
label fin_dessine;
var
nomx,nom0,ch1,ch2:string;
qui1:char;
i:col;
j:lign;
multi:boolean;
rest_m,a_battre:integer;
n:1..max_nb_case+1;
c:array[1..max_nb_case]of char;
non_bibi2:ensemble_col;
begin
 multi:=not(grille.nom2=nom_ordi);
 if cara='P' then multi:=false;
 if (cara<>'P'){ on est pas en pas a pas.}
 then begin
       if grille.j1_x
       then begin nomx:=grille.nom1; nom0:=grille.nom2;end
       else begin nomx:=grille.nom2; nom0:=grille.nom1;end;
       a_battre:=le_podium[Pum(2)].place[nb_place_podium].score;
       rest_m:=marathon-(grille.score1+grille.score2+grille.nul);
       if multi
       then centre(Ec,'MODE MULTIJOUEUR')
       else centre(Ec,'MODE ORDI VS JOUEUR');
       writeln;
       writeln;
       writeln(' Nombres de Victoires :');
       writeln;
       write(' ',grille.nom1:9); write(' : ');writeln(grille.score1:2);
       write(' ',grille.nom2:9); write(' : ');writeln(grille.score2:2);
       writeln;
       writeln(' Nombres de parties nulles : ',grille.nul);
       writeln;
       if not(multi)
       then begin
       writeln(' Parties restantes pour le Marathon : ',rest_m);
       write(' Nombres de victoires Consecutives  : ');write(grille.consecu);writeln(' ( min a battre : ',a_battre,' )');
       writeln;
       end;
       centre(Ec,'-----------------');
       writeln;
       writeln;
       centre(Ec,'Tirage au sort : '+nomx+' joue avec les X');
 end;
  writeln;
  str(grille.but,ch1);
  str(niveau_ordi,ch2);
  if not multi
  then centre(Ec,'But : Aligner '+ch1+' pions.    Niveau de l''ordi : '+ch2)
  else centre(Ec,'But : Aligner '+ch1+' pions.    ');

  writeln;
  writeln;
  if ((grille.nb_col<>class_col)or(grille.nb_lign<>class_lign))
  then begin
        dessine_special;
        goto fin_dessine;
       end;
  n:=1;
  for i:=1 to grille.nb_col
  do for j:=1 to grille.nb_lign
  do begin c[n]:=grille.Gr[i][j];inc(n); end;

  writeln(' Col :      1       2       3       4       5       6       7');
  writeln;
  writeln('         _______ _______ _______ _______ _______ _______ _______');
  writeln('        I       I       I       I       I       I       I       I');
  write('        I   ',c[6],'   I   ',c[12],'   I   ',c[18],'   I   ',c[24]);
  writeln('   I   ',c[30],'   I   ',c[36],'   I   ',c[42],'   I   N''oubliez');
  writeln('        I_______I_______I_______I_______I_______I_______I_______I');
  writeln('        I       I       I       I       I       I       I       I');
  write('        I   ',c[5],'   I   ',c[11],'   I   ',c[17],'   I   ',c[23]);
  writeln('   I   ',c[29],'   I   ',c[35],'   I   ',c[41],'   I    pas la');
  writeln('        I_______I_______I_______I_______I_______I_______I_______I');
  writeln('        I       I       I       I       I       I       I       I');
  write('        I   ',c[4],'   I   ',c[10],'   I   ',c[16],'   I   ',c[22]);
  writeln('   I   ',c[28],'   I   ',c[34],'   I   ',c[40],'   I    gravite');
  writeln('        I_______I_______I_______I_______I_______I_______I_______I');
  writeln('        I       I       I       I       I       I       I       I');
  write('        I   ',c[3],'   I   ',c[9],'   I   ',c[15],'   I   ',c[21]);
  writeln('   I   ',c[27],'   I   ',c[33],'   I   ',c[39],'   I       I');
  writeln('        I_______I_______I_______I_______I_______I_______I_______I       I');
  writeln('        I       I       I       I       I       I       I       I       I');
  write('        I   ',c[2],'   I   ',c[8],'   I   ',c[14],'   I   ',c[20]);
  writeln('   I   ',c[26],'   I   ',c[32],'   I   ',c[38],'   I      \_/');
  writeln('        I_______I_______I_______I_______I_______I_______I_______I');
  writeln('        I       I       I       I       I       I       I       I');
  write('        I   ',c[1],'   I   ',c[7],'   I   ',c[13],'   I   ',c[19]);
  writeln('   I   ',c[25],'   I   ',c[31],'   I   ',c[37],'   I');
  writeln('        I_______I_______I_______I_______I_______I_______I_______I');
  fin_dessine:
  for i:=1 to 2 do writeln;
  if cara<>'P' then
  begin
   qui1:=quijou;
   if qui1='X'
   then write('      JOUEUR X (',nomx,') ')
   else write('      JOUEUR 0 (',nom0,') ');
   if not(((qui1='X')and (nomx=nom_ordi))
   or ((qui1='0')and (nom0=nom_ordi)))
   then begin
         write('(Bequille ''B'') --->  ');
         if bequille
         then begin
               coup_non_bidon(non_bibi2);
               centre_Ens_col(0,non_bibi2);writeln;
              end
         else begin
               writeln('Non activ‚e');
              end;
        end;
   for i:=1 to 2 do writeln;
  end;
end;

procedure garde_fou_col(var Ens:ensemble_col;var rep:col;var tape_Q:boolean);
{procedure qui sert a eviter que l'utilisateur tape
un resultat inatendu au clavier lors de la saisi d'une colonne de jeu}
label termine5;
var
reponse:string;
cara:char;
code,coup:integer;
begin
repeat
 repeat
  if grille.nb_col<10
  then begin
        clavier(cara);writeln;
        reponse:=cara;
       end
  else readln_maj_nb(reponse);
  if reponse='B' then
  begin
   bequille:=not bequille;
   clrscr;
   dessine_grille('N');
  end;
  if reponse='S'
  then begin
        sauvegarde_partie;
        clrscr;
        dessine_grille('N');
       end;
  if reponse='G' then
  begin
    sauvegarde_analyse;
    clrscr;
    dessine_grille('N');
  end;
  tape_Q:=(reponse='Q');
  if tape_Q then goto termine5;
  val(reponse,coup,code);
  if (code<>0)
  then begin
        centre(Ec,'Vous devez maintenant entrez une colonne');
        writeln;
        writeln;
        gotomil;
       end;
 until code=0;
 rep:=coup;
 if not (rep in Ens)
 then begin
       write('            Reponses possibles : ');
       centre_Ens_col(0,Ens);writeln;
       centre(Ec,'Entrez une reponse correcte');
       writeln;
       writeln;
       gotomil;
      end;
until rep in Ens;
termine5:
end;

procedure readln_col(var veux_quitte:boolean);
{procedure qui traite la saisie du coup du joueur}
var
reponse,ch:string;
coup_lu:col;
col_libre:boolean;
code:integer;
Poss,non_bibi2:ensemble_col;
Poss_cara:ensemble_char;
begin
 veux_quitte:=false;
 coup_poss(Poss);
 centre(Ec,'Vous pouvez sauver cette grille (''G'') et la retrouver en pas_a_pas');
 writeln;
 centre(Ec,'Entrez une colonne (ou ''Q'' pour quitter, ''S'' pour sauver la partie)');
 writeln;
 gotomil;
 garde_fou_col(Poss,coup_lu,veux_quitte);
 if (not veux_quitte) then ajoute(quijou,coup_lu);
 {partie_en_cours[nb_coup_joue(grille)]:=coup_lu; }
end;


procedure pas_a_pas;
{procedure Qui permet une utilisation plus libre du programme}
label nouvelle_partie;
var
reponse:string;
booboo:boolean;
rep,resultat:char;
Ens_Rep:ensemble_char;
Ens_col,poss:ensemble_col;
la_col:col;
selection,tot1,tot2:integer;

begin
tutoriel:=true;
nouvelle_partie:
mis_a_zero_grille;

repeat
clrscr;
centre(Ec,'MODE PAS A PAS : "Mais comment ‡a marche ???"');
writeln;
writeln;
writeln;
dessine_grille('P');
writeln('           Nombre de X : ',nb_X_joue,'                Nombre de 0 : ',nb_0_joue);
tot_emb(tot1,'X');
tot_emb(tot2,'0');
writeln('             Embryon X : ',tot1,'                  Embryon 0 : ',tot2);
potentiel_total(tot1,'X');
potentiel_total(tot2,'0');
writeln('  Potentiel total de X : ',tot1,'       Potentiel total de 0 : ',tot2);
coup_poss(poss);
evalu(resultat);
if (resultat<>'I')
then begin
      writeln;
      centre(Ec,'FIN DE LA PARTIE');
      sleep;
      goto nouvelle_partie;
     end;
 writeln;
 centre(Ec,'Vous desirez :');
 writeln;
 writeln;
 writeln('     [G] Une Nouvelle Grille             [X] Ajouter un ''X''');
 writeln('     [E] Enlever un pion                 [0] Ajouter un ''0''');
 writeln('     [J] Voir le coup de l''ordi          [N] Modifier le Niveau de l''ordi');
 writeln('     [C] Charger une partie sauvegardee  [S] Sauver cette grille d''analyse');
 writeln('     [A] Charger une grille d''analyse    [Q] Quitter ce mode');
 writeln;
 writeln;
 writeln;
 Ens_rep:=['A','G','N','X','0','E','J','C','Q','S'];
 centre(Ec,'Entrez votre choix : ');
 writeln;
 writeln;
 gotomil;
 garde_fou_char(Ens_rep,rep);
 writeln;
 case rep of
 'N':choix_niveau(niveau_ordi);
 'G':goto nouvelle_partie;
 'X':
     begin
     clrscr;
     dessine_grille('P');
     writeln;
     writeln;
     centre(Ec,'        AJOUT D''UN ''X''');
     writeln;
     writeln;
     centre(Ec,'Entrez une colonne :');
     writeln;
     writeln;
     gotomil;
     garde_fou_col(poss,la_col,booboo);
     ajoute('X',la_col);
     end;
 '0':
     begin
     clrscr;
     dessine_grille('P');
     writeln;
     writeln;
     centre(Ec,'        AJOUT D''UN ''0''');
     writeln;
     writeln;
     centre(Ec,'Entrez une colonne :');
     writeln;
     writeln;
     gotomil;
     garde_fou_col(poss,la_col,booboo);
     ajoute('0',la_col);
     end;
 'E':
     begin
     clrscr;
     dessine_grille('P');
     writeln;
     writeln;
     centre(Ec,'        RETRAIT D''UN PION');
     writeln;
     Ens_col:=[1..grille.nb_col];
     writeln;
     writeln;
     centre(Ec,'Entrez une colonne :');
     writeln;
     writeln;
     gotomil;
     garde_fou_col(Ens_col,la_col,booboo);
     enleve(la_col);
     end;
 'J':
     begin
        if pions_valid
        then begin
        clrscr;
        genere_un_coup;
        dessine_grille('P');
        centre(Ec,'Fin du coup.');writeln;
        sleep;
             end
        else begin
              centre(Ec,'Le nb de X doit etre >de 1 ou egal au nombre de 0 ! ');
              writeln;
              writeln;
              sleep;
             end;
     end;
 'C':
     begin
       selectionner_partie('A',selection);
       if selection<>0
       then begin
             grille:=la_partie[selection];
             niveau_ordi:=grille.niveau;
            end;
     end;
 'A':
     begin
       selectionner_analyse('C',selection);
       if selection<>0 then charger_analyse(selection);
     end;
 'S':sauvegarde_analyse;
 end; {du case of}

until rep='Q';
end;

procedure resume_partie(nom1:string;j1:integer;nom2:string;j2,nul:integer);
{procedure qui totalise les victoires apres
une rencontre de plusieurs parties}
const
 nes=50;
var
 esp1,esp2,gagnant,ch1,ch2,ap1,ap2:string;
 i,n1,n2,tot_partie,points:integer;
begin
clrscr;
tot_partie:=j1+j2+nul;
writeln;
centre(Ec,'RESUME DE LA PARTIE');
writeln;
writeln;
writeln;
writeln;
str(tot_partie,ch1);
str(nul,ch2);
bordure_cadre(50);
cadre_gauche(50,'');
cadre_gauche(50,'  Nombres de parties jouees          : '+ch1);
cadre_gauche(50,'  Parties Nulles                     : '+ch2);
cadre_gauche(50,'');
str(j1,ch1);
str(j2,ch2);
ap1:='';
ap2:='';
for i:=1 to 10-length(nom1) do ap1:=ap1+' ';
for i:=1 to 10-length(nom2) do ap2:=ap2+' ';
cadre_gauche(50,'  Nombre de Victoires pour '+nom1+ap1+': '+ch1);
cadre_gauche(50,'  Nombre de Victoires pour '+nom2+ap2+': '+ch2);
cadre_gauche(50,'');
bordure_cadre(50);
writeln;

if (j1+j2<>0)
then begin
      n1:=trunc(j1/(j1+j2)*100);
      n2:=trunc(j2/(j1+j2)*100);
     end
else begin
      n1:=0;
      n2:=0;
     end;


case le_plus_grand(j1,j2) of
  0:begin
     centre(Ec,'PARTIE NULLE...');
     points:=50;
    end;
  1:begin
     gagnant:=nom1;
     points:=n1;
    end;
  2:begin
     gagnant:=nom2;
     points:=n2;
    end;
end;
str(points,ch1);
if (points<>50) then
centre(Ec,gagnant+' remporte cette partie, avec '+ch1+' % de victoires !');
writeln;
 if ((tot_partie>=min_raclee)and (points>=raclee))
 then begin
       writeln;
       centre(Ec,'QUELLE RACLEE !!!!');
       writeln;
       writeln;
      end;

if jeu_class
then begin{les records}

 if ((tot_partie>=marathon)and (nom2=nom_ordi))
 then begin
       writeln;
       bordure_cadre(60);
       cadre_milieu(60,'');
       cadre_milieu(60,'MARATHON DU P4');
       cadre_milieu(60,'');
       str(tot_partie,ch1);
       cadre_milieu(60,'Vous avez jou‚ un total de '+ch1+' parties.');
       cadre_milieu(60,'C''est donc un Marathon du p4 que vous venez de realiser !');
       cadre_milieu(60,'');
       if (gagnant=nom_ordi)
       then begin
             cadre_milieu(60,'Malheuresement vous avez PERDU ce Marathon....');
             cadre_milieu(60,'Vous n''entrez donc pas sur le podium.');
             cadre_milieu(60,'');
             bordure_cadre(60);
            end
       else if (points>le_podium[Pum(1)].place[nb_place_podium].score)
                {meilleur que le dernier}
            then begin
                  cadre_milieu(60,'Votre score constitue un record digne du podium !');
                  cadre_milieu(60,'');
                  bordure_cadre(60);
                  sleep;
                  entre_podium(le_podium[Pum(1)],points,nom1);
                 end
            else begin
                  cadre_milieu(60,'Votre score n''est malheuresement PAS SUFFISANT');
                  cadre_milieu(60,'pour meriter une place sur le podium. ');
                  cadre_milieu(60,'');
                  bordure_cadre(60);
                 end;
       if (param_jeu.niveau_debloque=niveau_ordi)
       and(param_jeu.niveau_debloque<nb_niveaux)
       and(points>=raclee)
       and(gagnant<>nom_ordi)
       then begin
             inc(param_jeu.niveau_debloque);
             niveau_ordi:=param_jeu.niveau_debloque;
             writeln;
             bordure_cadre(60);
             cadre_milieu(60,'');
             cadre_milieu(60,'NOUVEAU NIVEAU !!!!');
             cadre_milieu(60,'');
             str(niveau_ordi,ch1);
             cadre_milieu(60,'Vous debloquez '+nom_ordi+' Niveau '+ch1+' : ');
             cadre_milieu(60,'');
             cadre_milieu(60,nom_niv[niveau_ordi]);
             cadre_milieu(60,'');
             cadre_milieu(60,'Bonne chance pour votre prochain marathon !');
             cadre_milieu(60,'');
             bordure_cadre(60);
            end;

      end;


end;{des recompenses records}
writeln;
sleep;
writeln;
end;

procedure coupe_prudence;
var
 ch1:string;

begin
 str(grille.consecu,ch1);
 writeln;
 bordure_cadre(54);
 cadre_milieu(54,'');
 cadre_milieu(54,'COUPE-PRUDENCE');
 cadre_milieu(54,'');
 cadre_milieu(54,'Vous avez gagn‚ '+ch1+' partie consecutives.');
 cadre_milieu(54,'Cela constitue un nouveau record Coupe-Prudence !');
 cadre_milieu(54,'');
 bordure_cadre(54);
 sleep;
 entre_podium(le_podium[Pum(2)],grille.consecu,grille.nom1);
 grille.consecu:=0;
end;

procedure multijoueur(grille_ini:table_jeu);
{procedure de jeu en multijoueur (2 utilisateurs)}
label debut1;
var
joueur1_x,quitte:boolean;
car:char;
gagnant,rest_m:integer;
rep:string;
begin
grille:=grille_ini;
niveau_ordi:=grille.niveau;

debut1:
quitte:=false;
if (nb_coup_joue=0)
then begin
 if trunc(random*2)=0 then joueur1_x:=true else joueur1_x:=false;
 {tire au sort qui commence}
     end
else begin
      joueur1_x:=grille.j1_x;
     end;

grille.j1_x:=joueur1_x;
car:='I';
rest_m:=marathon-(grille.score1+grille.score2+grille.nul);

repeat
 clrscr;
 dessine_grille('M');
 evalu(car);

 if car='I' then readln_col(quitte);
until ((car<>'I')or quitte) ;

if not(quitte)
then begin
{partie comptation des victoires}
{definit le gagnant}
{write('qui a gagne ? ''X'' ou ''0'' : ');readln(car);}
 case car of
 'X':begin if joueur1_x then gagnant:=1 else gagnant:=2 end;
 '0':begin if joueur1_x then gagnant:=2 else gagnant:=1 end;
 'N':gagnant:=0;
 end;

 case gagnant of
 0:begin
    inc(grille.nul);
    centre(Ec,'Partie Nulle !')
   end;
 1:begin
    inc(grille.score1);
    centre(Ec,grille.nom1+' a gagne !');
   end;
 2:begin
    inc(grille.score2);
    centre(Ec,grille.nom2+' a gagne !');
   end;
 end;

 sleep;
 goto debut1;

end;

resume_partie(grille.nom1,grille.score1,grille.nom2,grille.score2,grille.nul);
end;

procedure affronte_ordi(var grille_ini:table_jeu);
{Procedure de jeu contre l'ordi
le joueur 2 est l''ordi}
label debut2;
var
joueur1_x,quitte,x_jou:boolean;
car:char;
gagnant:integer;
rep:string;
begin
tutoriel:=false;
{le joueur 2 est l'ordi}
randomize;
grille:=grille_ini;
niveau_ordi:=grille.niveau;

debut2:
quitte:=false;
if (nb_coup_joue=0)
then begin
 if trunc(random*2)=0 then joueur1_x:=true else joueur1_x:=false;
 {tire au sort qui commence}
     end
else begin
      joueur1_x:=grille.j1_x;
     end;

grille.j1_x:=joueur1_x;
car:='I';
repeat
 clrscr;
 dessine_grille('A');
 evalu(car);
 vide_clavier;
 if car='I'
 then begin
       x_jou:=((nb_coup_joue mod 2)=0);
       if ((x_jou)=joueur1_x)
       then readln_col(quitte) else genere_un_coup;
     end;


until ((car<>'I')or quitte) ;

if not(quitte){c'est que la partie est finie}
then begin
 case car of
 'X':begin if joueur1_x then gagnant:=1 else gagnant:=2 end;
 '0':begin if joueur1_x then gagnant:=2 else gagnant:=1 end;
 'N':gagnant:=0;
 end;
 case gagnant of
 1:begin
    inc(grille.consecu);
    inc(grille.score1);
    centre(Ec,grille.nom1+' a gagne !');
   end;
 2:begin
    inc(grille.score2);
    centre(Ec,nom_ordi+' a gagne !');
   end;
 0:begin
    inc(grille.nul);
    centre(Ec,'Partie Nulle !')
   end;
 end;


 if ((gagnant<>1) and (grille.consecu>le_podium[Pum(2)].place[nb_place_podium].score)and jeu_class)
 then coupe_prudence;
 sleep;
 mis_a_zero_grille;
 goto debut2;
end;

if ((grille.consecu>le_podium[Pum(2)].place[nb_place_podium].score)and jeu_class)
then begin coupe_prudence;sleep;end;
resume_partie(grille.nom1,grille.score1,nom_ordi,grille.score2,grille.nul);
end;

procedure voir_podium;
label debut;
var
 c1,rep2:char;
 Ens2:ensemble_char;
 i:integer;
begin
 i:=1;
 repeat
  debut:
  clrscr;
  affiche_podium(le_podium[i]);
  writeln;
  centre(Ec,'Pour faire defiler les podiums : Appuyer sur BackSpace et Espace ');
  writeln;
  centre(Ec,'Appuyer sur ''E'' pour effacer ce podium.');
  writeln;
  centre(Ec,'Appuyer sur ''Q'' pour revenir au menu general');
  writeln;
  gotomil;
  clavier(c1);
  writeln;
  if (c1='E')
  then begin
   centre(Ec,'Supprimer tous les scores de ce podium enregistr‚s ?');
   writeln;
   Ens2:=['O','N'];
   gotomil;
   garde_fou_char(ens2,rep2);
   if (rep2='O')
   then initialise_podium(le_podium[i]);
   goto debut;
  end;
  if c1=#8 then i:=cycle(i,nb_podium,-1)
            else i:=cycle(i,nb_podium,1)
 until c1='Q';
end;

procedure charger_partie;
var
 selection:integer;
begin
 selectionner_partie('C',selection);
 if (selection<>0)and (la_partie[selection].nom1<>'')
 then begin
       if la_partie[selection].nom2=nom_ordi
       then affronte_ordi(la_partie[selection])
       else multijoueur(la_partie[selection]);
      end;
end;

procedure menu;
{procedure du menu d'entree (ecran initial)}
label relance;
var
Ens,Ens2:ensemble_char;
tout_debut:boolean;
sel:integer;
rep,rep2:char;
nom_joueur1,nom_joueur2,ch1,ch2:string;
grille_ini:table_jeu;
begin
tout_debut:=true;
relance:
clrscr;
writeln;
writeln;
writeln;
bordure_cadre(44);
cadre_milieu(44,'MENTAL PUISSANCE 4');
cadre_milieu(44,'');
cadre_gauche(44,'Version du programme : '+version);
cadre_gauche(44,'Conception : Mathieu Barbin');
cadre_gauche(44,'');
cadre_gauche(44,'Choix du mode :');
cadre_gauche(44,'');
cadre_gauche(44,'[1] Mode Affronte L''Ordi');
cadre_gauche(44,'[2] Mode Multijoueur');
cadre_gauche(44,'[3] Mode Pas a Pas');
cadre_gauche(44,'[M] Voir les meilleurs scores');
cadre_gauche(44,'[C] Continuer une partie enregistr‚e');
cadre_gauche(44,'[D] Modifier les dimensions du jeu');
cadre_gauche(44,'[Q] Quitter Mental Puissance 4');
cadre_gauche(44,'');
bordure_cadre(44);
writeln;
str(grille.nb_col,ch1);
str(grille.nb_lign,ch2);
bordure_cadre(60);
cadre_gauche(60,'Taille de la grille     : '+ch1+' colonnes, '+ch2+' lignes.');
str(param_jeu.niveau_debloque,ch1);
cadre_gauche(60,'Dernier niveau debloqu‚ : '+ch1);
cadre_gauche(60,'');
bordure_cadre(60);
writeln;
writeln;

if (param_jeu.derniere_sauv<>0)and tout_debut
then begin
      centre(Ec,'Voulez-vous continuer la derniere partie sauvegard‚e ? : ');
      writeln;
      writeln;
      gotomil;
      Ens:=['O','N'];
      garde_fou_char(Ens,rep);
      tout_debut:=false;
      if (rep='O')
      then affronte_ordi(la_partie[param_jeu.derniere_sauv]);
      goto relance;
     end;

Ens:=['1','2','3','M','C','D','Q'];
centre(Ec,'Entrez votre choix : ');writeln;
writeln;
writeln;
gotomil;
garde_fou_char(Ens,rep);

case rep of
'D':modifit_taille_grille;
'1':
 begin
 clrscr;
 centre(Ec,'NOUVELLE PARTIE');
 writeln;
 writeln;
 demande_nom('JOUEUR',nom_joueur1);
 {appellle ffronte ordi
 (var grille_ini:table_jeu;debut_partie:boolean;nom_joueur1:string;joueur1,joueur2,nul,consecu:integer); }
 mis_a_zero_grille;
 grille_ini:=grille;
 with grille_ini
 do begin
     nom1:=nom_joueur1;
     nom2:=nom_ordi;
     score1:=0;score2:=0;nul:=0;consecu:=0;
     if (grille.nb_col>=10)
 then begin
       writeln;
       bordure_cadre(68);
       cadre_gauche(68,'');
       cadre_gauche(68,'Pour jouer dans une grille de cette dimension, il est conseille');
       cadre_gauche(68,'de ne pas depasser le niveau 3 afin d''ecourter l''attente entre');
       cadre_gauche(68,'les coups de l''Ordi, le temps d''analyse augmentant');
       cadre_gauche(68,'considerablement avec le niveau et la taille de la grille.');
       cadre_gauche(68,'');
       bordure_cadre(68);
     end;
     writeln;
     choix_niveau(grille_ini.niveau);
    end;
 affronte_ordi(grille_ini);
 end;

'2':
 begin
  writeln;
  demande_nom('JOUEUR 1',nom_joueur1);
  writeln;
  repeat
  demande_nom('JOUEUR 2',nom_joueur2);
  if nom_joueur1=nom_joueur2
  then begin
        writeln;
        writeln('             Ce nom est deja pris par le joueur 1 !');
        writeln;
       end;
  until (nom_joueur2<>nom_joueur1);
  mis_a_zero_grille;
  grille_ini:=grille;
  with grille_ini
  do begin
      nom1:=nom_joueur1;
      nom2:=nom_joueur2;
      score1:=0;score2:=0;nul:=0;
      niveau:=1;
     end;
  multijoueur(grille_ini);
 end;

'3':pas_a_pas;

'M':voir_podium;
'C':charger_partie;

end;{du case of}

if (rep<>'Q') then  goto relance;
end;

{et enfin le begin end global :}
begin
{page;}
window(2,2,Lo-1,Li-1);
lecture_podium;
lecture_partie;
lecture_param;
lecture_analyse;
dimensions_defaut;
menu;
ecriture_podium;
ecriture_partie;
ecriture_param;
end.