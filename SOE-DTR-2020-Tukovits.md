
# DTR Vizsga Feladat

## Bevezetés

A tárgy beadandóját egy hozzám és szakdolgozatom is köthető logisztikai feladattal oldottam meg. Adottak a gyártóhelyeink, ahol alapanyagokat gyártunk. Adottak feldolgozóhelyeink, amelyek várják a nyersanyagot.

Feladatunk a legolcsóbb megoldás megtalálása. Ha egy megadott mennyiség felett szállítunk, akkor olcsóbban tudjuk kivitelezni a szállítást.

Készítettem egy kiíratást is, hogy lássuk, mennyit szállítottunk a küszöbérték felett és mennyibe került az adott fuvar.

## Adatok

|Alapanyag| Elérhető mennyiség |
|--|--|
|A1|100|
|A2|250|
|A3|190|
|A4|210|


|Felhasználó|Szükséglet  |
|--|--|
|S1|120|
|S2|140|
|S3|170|
|S4|90|
|S5|110|
|S6|120|





## Halmazok

A modellünk 3 halmazból áll.

    #Halmazok
    #Alapanyag kínálat
    set Alapanyag;
    #Alapanyag szükséglet
    set Szukseglet;
    #Kínálat és szülségletek kapcsolata
    set KeresletKinalat:= setof {a in Alapanyag, s in Szukseglet} (a,s);

Ezekben tároljuk az elérhető és elvárt mennyiségeket, továbbá egy kétdimenziós halmazt, mivel mindegyik Alapanyagot össze kell kapcsolnunk egy Szükséglettel.

## Paraméterek

Több paraméterre lesz szükségem. Az elérhető Alapanyagok mennyisége, a szükséges alapanyagok mennyisége, az ár, egy küszöbszám, az árcsökkentés mértéke, a csökkentett ár, és egy big-M paraméter.

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
    #Big-M paraméter a korlátozáshoz
    param M := sum {a in Alapanyag} Elerheto[a];

## Változók

Változókból is többre van szükség. A szállított mennyiségre, az alapmennyiségre, a többletmennyiségre és hogy szállíthatunk a küszöbérték felett.

    #Változók
    #Szállított mennyiség
    var Szallit{(a,s) in KeresletKinalat}, >=0;
    #Küszöbérték alatti szállítás
    var AlapMennyiseg{(a,s) in KeresletKinalat}, >=0, <=Kuszob;
    #Köszübérték fölötti szállítás
    var TobbletMennyiseg{(a,s) in KeresletKinalat}, >=0;
    #Szállíthatunk-e csökkentett áron
    var KuszobFelett{(a,s) in KeresletKinalat}, binary;

## Korlátozások

Az első három korlátozásban meghatározzuk, hogy ne szállítsunk többet, mint amennyivel rendelkezünk és minimum annyit szállítsunk, mint amire szükségünk van. Továbbá a ténylegesen szállított mennyiséget határozzuk meg.

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

A következő kettőben Big-M korlátozásokat használunk, amiket „ki-be kapcsolgatunk” attól függően, hogy a küszöb alatti vagy feletti mennyiséget kell elszállítanunk.

    #Ha küszöb alatt vagyunk, többletmennyiség = 0
    s.t. KuszobAlattErtek {(a,s) in KeresletKinalat}:
    TobbletMennyiseg[a,s] <= M * KuszobFelett[a,s];
    
    #Ha küszöb felett vagyunk, akkor alapmennyiség = küszöb
    s.t. KuszobFelettErtek {(a,s) in KeresletKinalat}:
    AlapMennyiseg[a,s] >= Kuszob- M * (1 - KuszobFelett[a,s]);

## Célfüggvény

Cél a legolcsóbb megoldást megtalálni, ezért minimum számítást használunk.

    #Célfüggvény
    minimize TeljesKoltseg: sum {(a,s) in KeresletKinalat}
    (AlapMennyiseg[a,s] * Koltseg[a,s] + TobbletMennyiseg[a,s] * CsokkentettAr [a,s]);

## Kiíratás

A kiíratás emberi szem számára is olvasható kimenetet biztosít.

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

# Adatok

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

# Teljes kód

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
    #Big-M paraméter a korlátozáshoz
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
    
    printf "Optimal cost: %g.\n", TeljesKoltseg;
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

# Futtatás után

    Problem:    TB_vizsgafeladat
    Rows:       83
    Columns:    96 (24 integer, 24 binary)
    Non-zeros:  264
    Status:     INTEGER OPTIMAL
    Objective:  TeljesKoltseg = 2625 (MINimum)


    OPTIMAL LP SOLUTION FOUND
    Integer optimization begins...
    Long-step dual simplex will be used
    Gomory's cuts enabled
    MIR cuts enabled
    Cover cuts enabled
    No 0-1 knapsack inequalities detected
    Clique cuts enabled
    Constructing conflict graph...
    No conflicts found
    +    67: mip =     not found yet >=              -inf        (1; 0)
    Cuts on level 0: gmi = 10; mir = 9;
    Cuts on level 11: gmi = 10; mir = 9;
    +   161: >>>>>   2.625000000e+03 >=   2.622490292e+03 < 0.1% (12; 0)
    +   164: mip =   2.625000000e+03 >=     tree is empty   0.0% (0; 23)
    INTEGER OPTIMAL SOLUTION FOUND
    Time used:   0.0 secs
    Memory used: 0.4 Mb (369100 bytes)
    Optimal cost: 2625.
     A1 -ből S1 -be, elviszunk 10=10+0 mennyiséget 50 áron.
     A1 -ből S5 -be, elviszunk 90=90+0 mennyiséget 450 áron.
     A2 -ből S1 -be, elviszunk 110=100+10 mennyiséget 107.5 áron.
     A2 -ből S2 -be, elviszunk 140=100+40 mennyiséget 260 áron.
     A3 -ből S3 -be, elviszunk 170=100+70 mennyiséget 152.5 áron.
     A3 -ből S5 -be, elviszunk 20=20+0 mennyiséget 80 áron.
     A4 -ből S4 -be, elviszunk 90=90+0 mennyiséget 720 áron.
     A4 -ből S6 -be, elviszunk 120=100+20 mennyiséget 805 áron.

