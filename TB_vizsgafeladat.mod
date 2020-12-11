#Halmazok
#Alapanyag kínálat
set Alapanyag;
#Alapanyag szükséglet
set Szukseglet;
#Kínálat és szülségletek kapcsolata
set KeresletKinalat:= setof {a in Alapanyag, s in Szukseglet} (a,s);

#Paraméterek
#Elérhető alapanyag mennyisége 
param Elerheto{a in Alapanyag}, >=0;
#Minimum alapanyag mennyisége
param Szukseges{s in Szukseglet}, >=0;
#Ár
param Koltseg{(a,s) in KeresletKinalat}, >=0;
#Küszöbindex
param Kuszob>=0;
#Árcsökkentés mértéke
param Kedvezmeny, >0, <=100;
#Csökkentett ár
param CsokkentettAr {(a,s) in KeresletKinalat} := (Koltseg[a,s] * (1 - Kedvezmeny / 100));
# Big-M paraméter a korlátozáshoz
param M := sum {a in Alapanyag} Elerheto[a];

#Változók
#Szállított mennyiség
var Szallit{(a,s) in KeresletKinalat}, >=0;
#Küszöbérték alatti szállítás
var AlapMennyiseg{(a,s) in KeresletKinalat}, >=0, <=Kuszob;
#Köszübérték fölötti szállítás
var TobbletMennyiseg{(a,s) in KeresletKinalat}, >=0;
#Szállíthatunk-e csökkentett áron
var KuszobFelett{(a,s) in KeresletKinalat}, binary;


#Korlátozások
#Ne szállítsunk többet mint ami elérhető
s.t. ElerhetoMennyiseg {a in Alapanyag}:
sum {s in Szukseglet} Szallit[a,s] <= Elerheto[a];

#Legalább annyit szállítsunk, mint ami kell
s.t. SzuksegesMennyiseg {s in Szukseglet}:
sum {a in Alapanyag} Szallit[a,s] >= Szukseges[s];

#Ténylegesen szállított mennyiség
s.t. SzallitottMennyiseg {(a,s) in KeresletKinalat}:
Szallit[a,s] = AlapMennyiseg[a,s] + TobbletMennyiseg[a,s];

#Ha küszöb alatt vagyunk, többletmennyiség = 0
s.t. KuszobAlattErtek {(a,s) in KeresletKinalat}:
TobbletMennyiseg[a,s] <= M * KuszobFelett[a,s];

#Ha küszöb felett vagyunk, akkor alapmennyiség = küszöb
s.t. KuszobFelettErtek {(a,s) in KeresletKinalat}:
AlapMennyiseg[a,s] >= Kuszob- M * (1 - KuszobFelett[a,s]);

#Célfüggvény
minimize TeljesKoltseg: sum {(a,s) in KeresletKinalat}
(AlapMennyiseg[a,s] * Koltseg[a,s] + TobbletMennyiseg[a,s] * CsokkentettAr [a,s]);

#Kiíratás
solve;

printf "Költség: %g.\n", TeljesKoltseg;
for {(a,s) in KeresletKinalat: Szallit[a,s] > 0}
{
printf " %s -ből %s -be, elviszunk %g=%g+%g " &
"mennyiséget %g áron.\n",
a, s, Szallit[a,s], AlapMennyiseg[a,s], TobbletMennyiseg[a,s],
(AlapMennyiseg[a,s] * Koltseg[a,s] + TobbletMennyiseg[a,s] * CsokkentettAr [a,s]);
}

#Adatok
data;

set Alapanyag:=	A1	A2	A3	A4;

set Szukseglet:=	S1	S2	S3	S4	S5	S6;

param Elerheto:=
A1	100
A2	250
A3	190
A4	210
;

param Szukseges:=
S1	120
S2	140
S3	170
S4	90
S5	110
S6 	120
;

param Koltseg:
	S1	S2	S3	S4	S5	S6 :=
A1	5	10	3	9	5	12
A2	1	2	6	1	2	6
A3	6	5	1	6	4	8
A4	9	10	6	8	9	7
;

param Kuszob:= 100;

param Kedvezmeny := 25;

end;
