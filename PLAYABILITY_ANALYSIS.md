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
Rate(sem) = 100 × 1,1 ^ (sem − 1)
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

Wzrost wykładniczy zapewnia, że gra staje się trudniejsza w miarę postępu, ale jednocześnie gracz zdobywa silniejsze ulepszenia - zachowany jest balans trudności.

### 2.2 Ceny ulepszeń

Cena ulepszenia na poziomie `L` obliczana jest ze wzoru (`getPrice()`):

```
Cena(L) = cenaBazowa × 1,15 × (L + 1)
```

| Ulepszenie        | Cena bazowa | Poz. 0    | Poz. 1    | Poz. 2    | Efekt          |
|-------------------|-------------|-----------|-----------|-----------|----------------|
| Laptop            | 25          | 29 tok    | 58 tok    | 86 tok    | +0,1 tok/klik  |
| Kawa              | 60          | 69 tok    | 138 tok   | 207 tok   | +0,05 tok/klik |
| Znajomy           | 150         | 173 tok   | 345 tok   | 518 tok   | +0,5 tok/sek   |
| Korepetytor       | 500         | 575 tok   | 1150 tok  | 1725 tok  | +2,0 tok/sek   |
| Wczesne zaliczenie| 1200        | 1380 tok  | -         | -         | ×1,1 wszystko  |
| Praca magisterska | 2500        | 2875 tok  | -         | -         | +5,0 tok/sek   |
| Konferencja       | 5000        | 5750 tok  | -         | -         | ×1,2 wszystko  |
| Grant badawczy    | 12000       | 13800 tok | -         | -         | +10,0 tok/sek  |
| Wydawnictwo       | 25000       | 28750 tok | -         | -         | ×1,3 wszystko  |

### 2.3 System motywacji

```
Motywacja ∈ [10, 100]  (minimum = 10%)
Pasywny spadek: −8% / godzinę = −0,133% / minutę
Spadek przy kliknięciu: −1% za klik
Mnożnik dochodu = motywacja / 100
```

Przy motywacji < 30%: prędkość spadku × 1,5 (zwiększona kara).

**Obliczenie dla aktywnej gry (2 kliknięcia/sek):**

```
0 minut:   motywacja = 100%, mnożnik = 1,00
45 sekund: 90 kliknięć → motywacja ≈ 10%, mnożnik = 0,10
```

Jest to kluczowy mechanizm balansujący: nieograniczone klikanie jest niemożliwe,
gracz musi zarządzać motywacją strategicznie (reklama +20%, kofeina 50 ECTS = +50%).

---

## 3. Obliczenia czasu przechodzenia

### 3.1 Semestr 1 - szczegółowa analiza krok po kroku

**Cel:** 30 ECTS = 30 × 100 = **3 000 tokenów**

Założenia:
- Gracz klika r = **2 razy/sek** podczas aktywnej gry
- Stan początkowy: tokPerClick = 0,1, tokPerSek = 0

**Faza 0** (start): dochód = 0,1 × 2 = **0,2 tok/sek**

```
Laptop ×1 - koszt  29 tok - czas oczekiwania: 29 / 0,2 = 145 sek ≈ 2,4 min
Laptop ×2 - koszt  58 tok - tokPerKlik = 0,2 - 0,4 tok/sek - 145 sek ≈ 2,4 min
Laptop ×3 - koszt  86 tok - tokPerKlik = 0,3 - 0,6 tok/sek - 144 sek ≈ 2,4 min
Kawa ×1 - koszt  69 tok - tokPerKlik = 0,35 - 0,7 tok/sek - 99 sek ≈ 1,6 min
Znajomy ×1 - koszt 173 tok - +0,5 tok/sek - 1,2 tok/sek - 247 sek ≈ 4,1 min
Korepetytor - koszt 575 tok - +2,0 tok/sek - 3,2 tok/sek - 393 sek ≈ 6,5 min
```

**Łączny dochód po zakupach:** 3,2 tok/sek = **192 tok/min**

Wydano na ulepszenia: 29 + 58 + 86 + 69 + 173 + 575 = **990 tok**
Pozostało do zebrania: ok. **2 700 tok**

Przy 192 tok/min: 2700 / 192 = **14 minut**

**Łączny czas Semestru 1: ≈ 20 minut (zakupy) + 14 minut (zbieranie) ≈ 34 minuty aktywnej gry**

---

### 3.2 Mechanika offline (pasywny dochód)

Z kodu (`_calculateOfflineEarnings()`):

```
Limit offline: 8 godzin (28 800 sekund)
Dochód = tokensPerSecond × min(sekundyOffline, 28800)
```

**Przykład:** Gracz kupił Korepetytora (2,0 tok/sek) i zamknął grę na 4 godziny:

```
Dochód offline = 2,0 tok/sek × 14 400 sek = 28 800 tokenów
Przy kursie 110 tok/ECTS - 261 ECTS pasywnie
Cel semestru = 30 ECTS - wykonany 8-krotnie!
```

Oznacza to, że **gra nie wymaga ciągłej obecności** i świetnie sprawdza się
w trybie 2–3 sesji dziennie po 10–15 minut.

---

### 3.3 Battle Pass - obliczenie ukończenia

XP za kliknięcie: +1 XP co 3 kliknięcia (jeśli motywacja > 0)

Łączny XP wymagany do osiągnięcia Poziomu 10:

```
XP_total = Σ(n × 50) dla n = 1..10 = 50 × (1 + 2 + ... + 10) = 50 × 55 = 2 750 XP
Wymagana liczba kliknięć: 2750 × 3 = 8 250 kliknięć
Przy 2 kliknięciach/sek: 8250 / 2 = 4 125 sek = 68,75 min ≈ 1 godz. 9 min
```

**Battle Pass Poziom 10 osiągalny w ~1 godzinę 9 minut aktywnego klikania** (2–3 sesje).

---

### 3.4 Zbiorcza tabela czasu przechodzenia

| Etap          | Semestrów | Cel ECTS | Aktywna gra (min/sem) | Łącznie aktywnie |
|---------------|-----------|----------|-----------------------|------------------|
| Licencjat     | 7         | 30       | Sem1: 34, Sem2–7: ~15 | ~124 min         |
| Magister      | 4         | 40       | ~20 min               | ~80 min          |
| Doktorant     | 4         | 60       | ~25 min               | ~100 min         |
| **Razem**     | **15**    | **610**  | -                     | **~304 min**     |

**Łączny aktywny czas gry: ≈ 5–6 godzin**
**Czas kalendarzowy przy graniu 20–30 min/dzień: ~2 tygodnie** - idealny cykl dla gry mobilnej.

---

## 4. System stopniowego wzrostu trudności (krzywa trudności)

### 4.1 Bonus prestige do kliknięć ECTS

Po każdym zaliczeniu semestru (`_performPrestige()`):

```
ectsPerKlik = 0,1 × (1 + prestigePoints × 0,1)
```

| Prestige | ectsPerKlik |
|----------|-------------|
| 0        | 0,10        |
| 5        | 0,15        |
| 10       | 0,20        |
| 15       | 0,25        |

Wzrost liniowy - gracz odczuwa postęp po każdym semestrze.

### 4.2 tapMultiplier - kumulatywny bonus

Co 3 medale: tapMultiplier × 1,01
Przy przejściu na wyższy poziom edukacji: tapMultiplier × 1,10

```
Po 7 semestrach Licencjatu + przejście na Magistra:
- 7 medali - 2 bonusy po ×1,01 → ×1,0201
- 1 awans - × 1,10
- Łącznie: tapMultiplier ≈ 1,0201 × 1,10 ≈ 1,122

Po 15 semestrach + 3 awansach:
- 5 bonusów po × 1,01 → ×1,0510
- 3 awanse - ×1,10³ = ×1,331
- Łącznie: tapMultiplier ≈ 1,399 - prawie +40% do dochodu
```

---

## 5. Zdarzenia losowe - analiza balansu

Zdarzenia generowane są co 30–90 sekund (średnio co **60 sekund**).

Spośród 13 zdarzeń:
- **5 negatywnych** (utrata ECTS/motywacji)
- **6 pozytywnych** (bonus ECTS/motywacji)
- **2 neutralne** (wybór gracza)

**Oczekiwany bilans motywacji ze zdarzeń losowych w ciągu godziny:**

```
Negatywne: (−20 −10 −15 −5) / 4 = −12,5% śr. na zdarzenie
Pozytywne: (+15 +8 +5 +10) / 4 = +9,5% śr. na zdarzenie

60 min / 1 min za zdarzenie = 60 zdarzeń/godz.
Bilans: 60 × (6/13 × 9,5% − 5/13 × 12,5%) ≈ 60 × (4,38% − 4,81%) ≈ −26% / godz.
```

Łącznie z pasywnym spadkiem (−8%/godz.) presja na motywację wynosi ~−34%/godz.,
co zmusza gracza do aktywnego zarządzania motywacją raz na ~2–3 godziny — balans zachowany.

---

## 6. Wnioski końcowe

### Kryteria grywalności

| Kryterium                          | Obliczenie                             | Wynik    |
|------------------------------------|----------------------------------------|----------|
| Pierwszy znaczący wynik            | ≤ 34 min (1 semestr)                   | ✅       |
| Postęp offline                     | do 28 800 sek / sesja                  | ✅       |
| Battle Pass (cel dodatkowy)        | ≈ 70 min aktywnego klikania            | ✅       |
| Pełne przejście (bez trybu endless)| ≈ 5–6 godz. aktywnie / ~2 tyg. kalend. | ✅       |
| Balans trudności                   | Wzrost liniowy + multiplikatywny       | ✅       |
| Ograniczenie monotonii             | Motywacja + zdarzenia (co 60 sek)      | ✅       |
| Powtarzalność                      | Prestige + tryb endless Profesor       | ✅       |

### Formuła cyklu rozgrywki

```
Cykl gry EClicker:
  t₁ = 34 min (Semestr 1 — nauka mechanik)
  t₂₋₇ ≈ 15 min × 6 = 90 min (Licencjat)
  t₈₋₁₁ ≈ 20 min × 4 = 80 min (Magister)
  t₁₂₋₁₅ ≈ 25 min × 4 = 100 min (Doktorant)

  Σ czasu aktywnego ≈ 304 min ≈ 5,1 godziny
  Σ postępu pasywnego ≈ 10–14 dni
```

**Wniosek:** EClicker matematycznie spełnia standardy grywalności mobilnych gier idle.
Gra zapewnia poczucie postępu już w pierwszych 5–10 minutach, utrzymuje długoterminową
motywację poprzez system poziomów edukacji i Battle Pass, a mechanika offline sprawia,
że gra jest dostępna dla każdego harmonogramu gracza.
