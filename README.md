# EClicker

### Hierarchia edukacji

| Poziom        | Semestrów | ECTS/semestr | Łącznie ECTS |
|---------------|-----------|--------------|--------------|
| Licencjat     | 7         | 30           | 210          |
| Magister      | 4         | 40           | 160          |
| Doktorant     | 4         | 60           | 240          |

---

## 2. Matematyka podstawowych mechanik

### 2.1 Kurs wymiany tokenów na ECTS

Kurs rośnie z każdym semestrem według formuły z kodu (`getTokensPerEcts()`):

```
Rate(sem) = 100 * 1,1 ^ (sem − 1)
```

| Semestr | Tokenów za 1 ECTS |
|---------|-------------------|
| 1       | 100               |
| 2       | 110               |
| 3       | 121               |
| 4       | 133               |
| 7       | 177               |
| 11      | 259               |
| 15      | 380               |

Wzrost wykładniczy zapewnia, że wymiana staje się coraz droższa - gracz nie może polegać wyłącznie na tokenach.

### 2.2 Limit wymiany tokenów na ECTS

Wymiana tokenów na ECTS jest **limitowana per semestr** (`maxEctsFromExchangePerSemester`). Limit rośnie o 1 po każdym zdanym semestrze:

```
Limit(sem) = 2 + sem
```

| Semestr | Limit wymiany |
|---------|---------------|
| 1       | 3 ECTS        |
| 2       | 4 ECTS        |
| 5       | 7 ECTS        |
| 10      | 12 ECTS       |
| 15      | 17 ECTS       |

Tokeny **nie są zerowane** przy przejściu semestru - kumulują się i mogą być używane na ulepszenia w kolejnych semestrach. Po prestige zerują się: ECTS, ulepszenia, tokensPerClick (do 0,1) i tokensPerSecond (do 0), ale tapMultiplier oraz tokeny w portfelu pozostają.

### 2.3 Ceny ulepszeń

Cena ulepszenia na poziomie `L` obliczana jest ze wzoru (`getPrice()`):

```
Cena(L) = cenaBazowa × 1,15 × (L + 1)
```

| Ulepszenie              | Cena bazowa | Poz. 0    | Poz. 1    | Poz. 2    | Efekt              | Dostępność  |
|-------------------------|-------------|-----------|-----------|-----------|---------------------|-------------|
| Laptop                  | 25          | 29 tok    | 58 tok    | 86 tok    | +0,1 tok/klik       | Licencjat   |
| Kawa                    | 60          | 69 tok    | 138 tok   | 207 tok   | +0,05 tok/klik      | Licencjat   |
| Znajomy                 | 150         | 173 tok   | 345 tok   | 518 tok   | +0,5 tok/sek        | Licencjat   |
| Korepetytor             | 500         | 575 tok   | 1 150 tok | 1 725 tok | +2,0 tok/sek        | Licencjat   |
| Wczesne zaliczenie †    | 1 200       | 1 380 tok | –         | –         | ×1,1 wszystko       | Licencjat   |
| Artykuł naukowy         | 2 000       | 2 300 tok | 4 600 tok | 6 900 tok | +0,5 tok/klik       | Magister    |
| Praca magisterska       | 2 500       | 2 875 tok | 5 750 tok | 8 625 tok | +5,0 tok/sek        | Magister    |
| Konferencja †           | 5 000       | 5 750 tok | –         | –         | ×1,2 wszystko       | Magister    |
| Laboratorium            | 10 000      | 11 500 tok| 23 000 tok| 34 500 tok| +1,0 tok/klik       | Doktorant   |
| Grant badawczy          | 12 000      | 13 800 tok| 27 600 tok| 41 400 tok| +10,0 tok/sek       | Doktorant   |
| Wydawnictwo †           | 25 000      | 28 750 tok| –         | –         | ×1,3 wszystko       | Doktorant   |

† = jednorazowy zakup - po zakupie przycisk znika z listy. Mnożniki stosowane do tokensPerClick i tokensPerSecond jednocześnie.

### 2.4 System motywacji

```
Motywacja ∈ [10, 100]  (minimum = 10%)
Pasywny spadek: −8% / godzinę = −0,133% / minutę
Spadek przy kliknięciu: −1% za klik
Mnożnik dochodu = motywacja / 100
```

Przy motywacji < 30%: prędkość pasywnego spadku × 1,5 (zwiększona kara).

**Obliczenie dla aktywnej gry (2 kliknięcia/sek):**

```
0 minut:   motywacja = 100%, mnożnik = 1,00
45 sekund: 90 kliknięć -> motywacja ≈ 10%, mnożnik = 0,10
```

Klikanie przy 0% motywacji nie przynosi tokenów, więc gracz naturalnie robi przerwy. Jest to kluczowy mechanizm balansujący: gracz musi zarządzać motywacją strategicznie (reklama +20%, kofeina 50 ECTS = +50%). Zdarzenia losowe na netto **odnawiają** motywację podczas przerw.

---

## 3. Główna pętla rozgrywki i obliczenia czasu

### 3.1 Dwa źródła ECTS

ECTS można zdobyć na dwa sposoby:

**A) Zdarzenia losowe - główne źródło**

Zdarzenia ECTS-pozytywne (z listy 13 zdarzeń):

| Zdarzenie       | Bonus ECTS |
|-----------------|------------|
| Stypendium      | +50        |
| Łatwy egzamin   | +20        |
| Grupa studyjna  | +15        |
| Pomoc kolegi    | +10        |

Prawdopodobieństwo zdarzenia ECTS-pozytywnego = 4/13 ≈ 30,8%  
Średni bonus: (50 + 20 + 15 + 10) / 4 = **23,75 ECTS** za zdarzenie  
Zdarzenia co 30–90 sek (śr. 60 sek) -> **oczekiwane ECTS z zdarzeń:** 30,8% × 23,75 × 60/min ≈ **7 ECTS/min**

**B) Wymiana tokenów - uzupełnienie**

Ograniczone limitem semestralnym (zob. §2.2). W semestrze 1: 3 ECTS = 300 tokenów.  
Gracz **odrzuca** zdarzenia negatywne, płacąc motywacją zamiast ECTS - strategia optymalna.

### 3.2 Semestr 1 - szczegółowa analiza

**Cel:** 30 ECTS

**Źródło 1 - zdarzenia losowe:**
Oczekiwana liczba zdarzeń do zebrania 30 ECTS:

```
Potrzeba: 30 ECTS
Oczekiwany zysk na zdarzenie: 30,8% × 23,75 = 7,3 ECTS/zdarzenie
Oczekiwane zdarzenia: 30 / 7,3 ≈ 4,1 zdarzenia
Czas: 4,1 × 60 sek ≈ 4,1 minuty (wartość oczekiwana)
```

Jedno zdarzenie „Stypendium" (+50 ECTS) wystarcza na cały semestr; P(przynajmniej 1 ECTS-zdarzenie w 4 losowaniach) = 1 − (9/13)^4 ≈ 77%.

**Źródło 2 - wymiana tokenów (dodatkowe +3 ECTS):**

```
Faza 0 (start): tokPerKlik = 0,1 / tokPerSek = 0 -> dochód = 0,2 tok/sek przy 2 klik/sek

Laptop ×1 – 29 tok   – tokPerKlik = 0,2
Laptop ×2 – 58 tok   – tokPerKlik = 0,3
Kawa ×1   – 69 tok   – tokPerKlik = 0,35 -> 0,7 tok/sek
Znajomy ×1 – 173 tok – +0,5 tok/sek -> łącznie 1,2 tok/sek
```

Wydano na ulepszenia: ~330 tok. Przy 1,2 tok/sek, kolejne 300 tokenów = ~4 minuty.  
-> Limit wymiany 3 ECTS osiągalny w **ok. 4–5 minut**, równolegle z oczekiwaniem na zdarzenia.

**Łączny czas Semestru 1: ~8–15 minut** (zależnie od losowości zdarzeń).

---

### 3.3 Mechanika offline (pasywny dochód)

Z kodu (`_calculateOfflineEarnings()`):

```
Limit offline: 8 godzin (28 800 sekund)
Dochód = tokensPerSecond × min(sekundyOffline, 28800)
```

**Przykład:** Gracz kupił Korepetytora (2,0 tok/sek) i zamknął grę na 4 godziny:

```
Dochód offline = 2,0 tok/sek × 14 400 sek = 28 800 tokenów
```

Tokeny przechodzą do portfela i mogą być użyte na ulepszenia lub wymianę w kolejnym semestrze.  
Oznacza to, że **gra nie wymaga ciągłej obecności** i świetnie sprawdza się w trybie 2–3 sesji dziennie po 10–15 minut.

---

### 3.4 Battle Pass - obliczenie ukończenia

XP za kliknięcie: +1 XP co 3 kliknięcia (jeśli motywacja > 0)

Łączny XP wymagany do osiągnięcia Poziomu 10:

```
XP_total = Σ(n × 50) dla n = 1..10 = 50 × 55 = 2 750 XP
Wymagana liczba kliknięć: 2 750 × 3 = 8 250 kliknięć
Przy 2 kliknięciach/sek: 8 250 / 2 = 4 125 sek ≈ 1 godz. 9 min
```

**Battle Pass Poziom 10 osiągalny w ~1 godzinę 9 minut aktywnego klikania** (2–3 sesje).

---

### 3.5 Zbiorcza tabela czasu przechodzenia

| Etap          | Semestrów | ECTS/sem | Aktywna gra (min/sem) | Łącznie aktywnie |
|---------------|-----------|----------|-----------------------|------------------|
| Licencjat     | 7         | 30       | Sem1: 10-15, Sem2-7: ~10 | ~70-90 min    |
| Magister      | 4         | 40       | ~12-18 min            | ~50-70 min       |
| Doktorant     | 4         | 60       | ~15-25 min            | ~60-100 min      |
| **Razem**     | **15**    | **610**  | -                     | **~3-4,5 godz.** |

**Łączny aktywny czas gry: ≈ 3-4,5 godziny**  
**Czas kalendarzowy przy graniu 20–30 min/dzień: ~1,5-2 tygodnie** - idealny cykl dla gry mobilnej.

---

## 4. System stopniowego wzrostu trudności (krzywa trudności)

### 4.1 Rosnący limit wymiany i carryover tokenów

Po każdym zdanym semestrze (`_performPrestige()`):

```
maxEctsFromExchangePerSemester += 1   (startuje od 3)
```

| Semestr | Limit wymiany/semestr | Łączny limit od początku |
|---------|-----------------------|--------------------------|
| 1       | 3 ECTS                | 3                        |
| 5       | 7 ECTS                | 25                       |
| 10      | 12 ECTS               | 75                       |
| 15      | 17 ECTS               | 150                      |

Wzrost liniowy sprawia, że tokeny stają się coraz ważniejsze w późniejszych etapach gry, kiedy kursy wymiany są wysokie i zdarzenia nie wystarczają do pokrycia rosnących wymagań ECTS. Jednocześnie tokeny z portfela **nie są zerowane** - nagromadzony przez semestr pasywny dochód offline przekłada się bezpośrednio na liczbę zakupionych ulepszeń w kolejnym semestrze.

### 4.2 tapMultiplier - kumulatywny bonus

Co 3 medale (zdane semestry): tapMultiplier * 1,01  
Przy przejściu na wyższy poziom edukacji: tapMultiplier * 1,10

```
Po 7 semestrach Licencjatu + przejście na Magistra:
- 7 medali -> 2 bonusy x1,01 -> x1,0201
- 1 awans -> ×1,10
- Łącznie: tapMultiplier ≈ 1,122

Po 15 semestrach + 3 awansach:
- 5 bonusów x1,01 -> x1,0510
- 3 awanse x1,10^3 = x1,331
- Łącznie: tapMultiplier ≈ 1,399 -> prawie +40% do dochodu
```

tapMultiplier mnożony jest przez tokensPerClick, tapMultiplier i clickBoostMultiplier łącznie - trwały postęp mimo resetu ulepszeń.

---

## 5. Zdarzenia losowe - analiza balansu

Zdarzenia generowane są co 30–90 sekund (średnio co **60 sekund**).

Spośród 13 zdarzeń:
- **4 negatywne** (utrata motywacji/ECTS)
- **7 pozytywnych** (bonus ECTS/motywacji)
- **2 neutralne** (wybór gracza: ECTS za motywację)

**Bilans ECTS ze zdarzeń losowych:**

```
ECTS-pozytywne: scholarship(+50), easy_exam(+20), study_group(+15), friend_help(+10)
Avg = 23,75 ECTS  |  P = 4/13 = 30,8%

ECTS-kosztowne: kolokwium(−10), laptop(−15), party(−15), extra_project(−20)
-> gracz optymalnie ODRZUCA, płacąc motywacją zamiast ECTS

Netto ECTS/godz. = 60 * 30,8% * 23,75 ≈ +439 ECTS/godz. (wartość oczekiwana)
```

**Bilans motywacji ze zdarzeń losowych (przy 0 kliknięciach):**

```
Negatywne (4/13): śr. -12,5%/zdarzenie
Pozytywne z motywacją (4/13): good_grade(+15), coffee_break(+8), lucky_day(+5), easy_exam(+10) -> śr. +9,5%
Neutralne (2/13): party(+25), extra_project(+5) -> śr. +15%

Bilans/godz. = 60 * [4/13*(−12,5%) + 4/13*(+9,5%) + 2/13*(+15%)]
             = 60 * [−3,85% + 2,92% + 2,31%]
             = 60 * 1,38% ≈ +83%/godz.
```

Łącznie z pasywnym spadkiem (-8%/godz.) motywacja **rośnie netto podczas bezczynności** (+75%/godz.), co wymusza cykl: klikanie (szybki dochód tokenów) -> przerwa (regeneracja motywacji przez zdarzenia) -> klikanie.

---

## 6. Wnioski końcowe

### Kryteria grywalności

| Kryterium                          | Obliczenie                                    |
|------------------------------------|-----------------------------------------------|
| Pierwszy znaczący wynik            | ≤ 15 min (1 semestr)                          |
| Postęp offline                     | do 28 800 sek / sesja                         |
| Battle Pass (cel dodatkowy)        | ≈ 70 min aktywnego klikania                   |
| Pełne przejście (bez endless)      | ≈ 3–4,5 godz. aktywnie / ~2 tyg. kalend.     |
| Balans trudności                   | Kursy wymiany rosnące wykładniczo + limit lin. |
| Ograniczenie monotonii             | Motywacja + zdarzenia (co 60 sek)             |
| Powtarzalność                      | Prestige + tryb endless Profesor              |

### Formuła cyklu rozgrywki

```
Cykl gry EClicker:
  t₁     ≈ 10–15 min   (Semestr 1 - nauka mechanik)
  t₂₋₇  ≈ 10 min * 6  = 60 min   (Licencjat)
  t₈₋₁₁ ≈ 15 min * 4  = 60 min   (Magister)
  t₁₂₋₁₅≈ 20 min * 4  = 80 min   (Doktorant)

  Σ czasu aktywnego ≈ 210 min ≈ 3,5 godziny
  Σ postępu pasywnego ≈ 10-14 dni
```

### Spójność systemu ekonomicznego

Gra opiera się na trzech nakładających się ekonomiach:

1. **Ekonomia tokenów** - klikanie -> tokeny -> ulepszenia -> więcej tokenów/sek (offline),
2. **Ekonomia ECTS** - zdarzenia losowe + limitowana wymiana tokenów -> zaliczenie semestru,
3. **Ekonomia motywacji** - ogranicza intensywność klikania, wymusza sesyjność.

Każda ekonomia ogranicza pozostałe, eliminując możliwość prostego "farm and win" - gracz musi balansować między klikaniem, zakupem ulepszeń i zarządzaniem motywacją.

**Wniosek:** EClicker matematycznie spełnia standardy grywalności mobilnych gier idle.  
Gra zapewnia poczucie postępu już w pierwszych 5–10 minutach, utrzymuje długoterminową  
motywację poprzez system poziomów edukacji i Battle Pass, a mechanika offline sprawia,  
że gra jest dostępna dla każdego harmonogramu gracza.
