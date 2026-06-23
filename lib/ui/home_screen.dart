import 'package:flutter/material.dart';
import 'package:game_cool/ui/shop_screen.dart';
import 'package:game_cool/ui/upgrade_screen.dart';
import 'dart:async';
import '../model/game_state.dart';
import '../model/upgrade.dart';
import '../model/random_event.dart';
import '../model/education_level.dart';
import '../model/daily_deal.dart';
import '../service/save_service.dart';
import 'achievements_screen.dart';
import '../service/motivation_service.dart';
import '../service/event_service.dart';
import '../service/ad_service.dart';
import '../widgets/study_room.dart';
import '../widgets/motivation_bar.dart';
import '../widgets/upgrade_card.dart';
import '../widgets/event_popup.dart';
import '../utils/formatters.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late GameState gameState;
  Timer? autoClickTimer;
  Timer? saveTimer;
  bool isLoading = true;
  DateTime? appPausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadGameState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      appPausedTime = DateTime.now();
      SaveService.saveGame(gameState);
    } else if (state == AppLifecycleState.resumed) {
      if (appPausedTime != null) {
        _calculateOfflineEarnings();
      }
    }
  }

  void _calculateOfflineEarnings() {
    if (appPausedTime == null) return;

    final now = DateTime.now();
    final secondsOffline = now.difference(appPausedTime!).inSeconds;

    if (secondsOffline > 0 && gameState.tokensPerSecond > 0) {
      final cappedSeconds = secondsOffline > 28800 ? 28800 : secondsOffline;
      final offlineTokens = gameState.tokensPerSecond * cappedSeconds;

      setState(() {
        gameState.addTokens(offlineTokens);
      });

      SaveService.saveGame(gameState);

      _showOfflineEarningsPopup(offlineTokens, cappedSeconds);
    }

    appPausedTime = null;
  }

  void _showOfflineEarningsPopup(double earned, int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a4e),
        title: const Row(
          children: [
            Text('💰 ', style: TextStyle(fontSize: 40)),
            Text('Welcome back!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'During your absence, you earned:',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '+${Formatters.formatNumber(earned)} tokens',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Offline Time: ${hours}h ${minutes}m',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  Future<void> loadGameState() async {
    gameState = await SaveService.loadGame();

    if (gameState.lastMotivationUpdate
        .isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      appPausedTime = gameState.lastMotivationUpdate;
      _calculateOfflineEarnings();
    }

    setState(() {
      isLoading = false;
    });
    startAutoClick();
    startAutoSave();
    startMotivationDecay();
    startEventGeneration();
  }

  void startAutoClick() {
    autoClickTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (gameState.tokensPerSecond > 0) {
        setState(() {
          final motivationMultiplier =
              MotivationService.getMotivationMultiplier(gameState.motivation);
          gameState.addTokens(
              gameState.tokensPerSecond * 0.1 * motivationMultiplier);
        });
      }
    });
  }

  void startAutoSave() {
    saveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      SaveService.saveGame(gameState);
    });
  }

  void startMotivationDecay() {
    MotivationService.startMotivationDecay(gameState, (updatedState) {
      setState(() {
        gameState = updatedState;
      });
      SaveService.saveGame(gameState);
    });
  }

  void startEventGeneration() {
    EventService.startEventGeneration(gameState, (event) {
      _showEventPopup(event);
    });
  }

  void onEctsClick() {
    debugPrint(
        'onEctsClick called - tokens before: ${gameState.tokens} frac=${gameState.tokensFraction.toStringAsFixed(2)}');
    setState(() {
      final motivationMultiplier =
          MotivationService.getMotivationMultiplier(gameState.motivation);

      double clickBoost = 1.0;
      if (gameState.boostedClicksRemaining > 0) {
        clickBoost = gameState.clickBoostMultiplier;
        gameState.boostedClicksRemaining--;
      }

      final gained = gameState.tokensPerClick *
          motivationMultiplier *
          gameState.tapMultiplier *
          clickBoost;
      gameState.addTokens(gained);
      gameState.totalClicks++;

      gameState.motivation = (gameState.motivation - 1.0).clamp(0, 100.0);

      if (gameState.motivation > 0 && gameState.totalClicks % 3 == 0) {
        gameState.battlePassXP += 1;
        _checkBattlePassLevelUp();
      }

      debugPrint(
          'onEctsClick done - tokens after: ${gameState.tokens} frac=${gameState.tokensFraction.toStringAsFixed(2)} gained: ${gained.toStringAsFixed(2)}');
    });
  }

  void _checkBattlePassLevelUp() {
    final requiredXP = (gameState.battlePassLevel + 1) * 50;
    if (gameState.battlePassXP >= requiredXP &&
        gameState.battlePassLevel < 10) {
      setState(() {
        gameState.battlePassLevel++;
        _showBattlePassReward();
      });
    }
  }

  void _showBattlePassReward() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Battle Pass Level ${gameState.battlePassLevel} Unlocked!'),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void buyUpgrade(Upgrade upgrade) {
    final currentLevel = gameState.upgrades[upgrade.id] ?? 0;
    final price = upgrade.getPrice(currentLevel);

    final int cost = price.round();
    if (gameState.tokens >= cost) {
      setState(() {
        gameState.tokens -= cost;
        gameState.upgrades[upgrade.id] = currentLevel + 1;

        switch (upgrade.type) {
          case UpgradeType.clickBoost:
            if (upgrade.id == 'laptop') {
              gameState.tokensPerClick += 0.1;
            } else if (upgrade.id == 'coffee') {
              gameState.tokensPerClick += 0.05;
            } else if (upgrade.id == 'scientificArticle') {
              gameState.tokensPerClick += 0.5;
            } else if (upgrade.id == 'laboratory') {
              gameState.tokensPerClick += 1.0;
            }
            break;
          case UpgradeType.autoClick:
            if (upgrade.id == 'friend') {
              gameState.tokensPerSecond += 0.5;
            } else if (upgrade.id == 'tutor') {
              gameState.tokensPerSecond += 2.0;
            } else if (upgrade.id == 'dissertation') {
              gameState.tokensPerSecond += 5.0;
            } else if (upgrade.id == 'grant') {
              gameState.tokensPerSecond += 10.0;
            }
            break;
          case UpgradeType.multiplier:
            gameState.tokensPerClick *= 1.1;
            gameState.tokensPerSecond *= 1.1;
            break;
        }
      });
      SaveService.saveGame(gameState);
    }
  }

  void prestige() {
    final requiredEcts = gameState.getRequiredEcts();

    if (gameState.ects >= requiredEcts) {
      final currentLevel = EducationLevel.getById(gameState.educationLevel);
      final isLastSemester =
          gameState.educationSemester >= (currentLevel?.totalSemesters ?? 7);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a4e),
          title: Text(
            isLastSemester ? '${_getNextLevelTitle()}?' : 'Next Semester?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            isLastSemester
                ? 'Congratulations! You completed ${gameState.educationLevel}!\n\nProceed to ${EducationLevel.getNextLevel(gameState.educationLevel)}?\n\n+1 Prestige Point\n+10% permanent bonus\n\nNew upgrades unlocked!'
                : 'Do you want to proceed to the next semester?\n\n+1 Prestige Point\n+5% permanent bonus\n\nBUT: you will lose all ECTS and upgrades!',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, I will wait',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _performPrestige(isLastSemester);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                  isLastSemester ? 'LEVEL UP!' : 'YES! Pass the semester!'),
            ),
          ],
        ),
      );
    }
  }

  void _performPrestige(bool levelUp) {
    final previousSemester = gameState.semester;
    setState(() {
      if (levelUp) {
        gameState.educationLevel =
            EducationLevel.getNextLevel(gameState.educationLevel);
        gameState.educationSemester = 1;
        gameState.semester++;
      } else {
        gameState.educationSemester++;
        gameState.semester++;
      }

      final medalId = '${gameState.educationLevel}_sem$previousSemester';
      gameState.medals.add(medalId);

      if (gameState.medals.length % 3 == 0) {
        gameState.tapMultiplier *= 1.01;
      }

      if (levelUp) {
        gameState.trophies++;
        gameState.tapMultiplier *= 1.10;
      }

      gameState.prestigePoints++;
      final pending = gameState.pendingEctsFromExchange;
      gameState.ects = pending.toDouble();
      if (pending > 0) {
        gameState.totalEctsEarned += pending;
        gameState.pendingEctsFromExchange = 0;
      }
      gameState.ectsPerClick = 0.1 * (1 + gameState.prestigePoints * 0.1);
      gameState.ectsPerSecond = 0;
      gameState.upgrades = Map.fromIterable(
        gameState.upgrades.keys,
        value: (_) => 0,
      );

      gameState.ectsExchangedThisSemester = 0;
      gameState.maxEctsFromExchangePerSemester += 1;

      gameState.motivation = (gameState.motivation + 20).clamp(0, 100.0);
    });
    SaveService.saveGame(gameState);
  }

  String _getNextLevelTitle() {
    final nextLevel = EducationLevel.getNextLevel(gameState.educationLevel);
    return EducationLevel.getById(nextLevel)?.name ?? 'Next Level';
  }

  void _showEventPopup(RandomEvent event) {
    final canAfford = gameState.ects >= event.ectsCost;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EventPopup(
        event: event,
        canAfford: canAfford,
        onAccept: () {
          EventService.applyEvent(event, gameState);
          setState(() {});
          SaveService.saveGame(gameState);
          Navigator.pop(context);
        },
        onDecline: () {
          if (event.type == EventType.negative && event.motivationChange < 0) {
            gameState.motivation =
                (gameState.motivation + event.motivationChange).clamp(0, 100);
          }
          setState(() {});
          Navigator.pop(context);
        },
      ),
    );
  }

  void _boostMotivation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a4e),
        title: const Text('Boost Motivation',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Choose a way to restore motivation:\n\n'
          '1. Watch an ad → +20% motivation\n'
          '2. Buy "Caffeine Pack" (50 ECTS) → +50% motivation',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: AdService.isAdReady()
                ? () async {
                    Navigator.pop(context);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final success = await AdService.showRewardedAd();

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (success) {
                      MotivationService.restoreMotivation(gameState, 20);
                      setState(() {});
                      SaveService.saveGame(gameState);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('+20% Motivation!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Ad not available. Try again in a moment.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Ad'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
          ElevatedButton.icon(
            onPressed: gameState.ects >= 50
                ? () {
                    setState(() {
                      gameState.ects -= 50;
                      MotivationService.restoreMotivation(gameState, 50);
                    });
                    SaveService.saveGame(gameState);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('+50% Motivation!')),
                    );
                  }
                : null,
            icon: const Icon(Icons.shopping_bag),
            label: const Text('50 ECTS'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showExchangeDialogHome() {
    final rate = gameState.getTokensPerEcts();
    final affordableByTokens = gameState.tokens ~/ rate;
    final allowed = affordableByTokens;

    if (allowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No exchanges available (no tokens).')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a4e),
          title: const Text('Exchange tokens for ECTS',
              style: TextStyle(color: Colors.white)),
          content: Text(
              'You can exchange up to $allowed ECTS ($rate tokens = 1 ECTS). You have ${gameState.tokens} tokens.',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _performExchangeHome(1);
                Navigator.pop(context);
              },
              child: const Text('Exchange 1 ECTS'),
            ),
            ElevatedButton(
              onPressed: () {
                _performExchangeHome(allowed);
                Navigator.pop(context);
              },
              child: Text('Exchange $allowed ECTS'),
            ),
          ],
        );
      },
    );
  }

  void _performExchangeHome(int ectsToExchange) {
    final rate = gameState.getTokensPerEcts();
    final affordableByTokens = gameState.tokens ~/ rate;
    final allowedByRequest = ectsToExchange;
    final allowed =
        [affordableByTokens, allowedByRequest].reduce((a, b) => a < b ? a : b);

    final cost = allowed * rate;
    if (gameState.tokens < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have enough tokens.')),
      );
      return;
    }
    if (allowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Exchange limit reached for the semester.')),
      );
      return;
    }

    setState(() {
      gameState.tokens -= cost;
      gameState.pendingEctsFromExchange += allowed;
      gameState.ectsExchangedThisSemester += allowed;
    });
    SaveService.saveGame(gameState);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Exchanged $allowed ECTS (awarded at the end of the semester).')),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    autoClickTimer?.cancel();
    saveTimer?.cancel();
    MotivationService.stopMotivationDecay();
    EventService.stopEventGeneration();
    SaveService.saveGame(gameState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EClicker'),
        backgroundColor: const Color(0xFF0f3460),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'Shop',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopScreen(gameState: gameState),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Achievements',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AchievementsScreen(gameState: gameState),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatsScreen(gameState: gameState),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Upgrades',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpgradesScreen(
                    gameState: gameState,
                    onUpgradeBuy: buyUpgrade,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Column(
            children: [
              _buildStatsCard(),
              const SizedBox(height: 20),
              MotivationBar(
                motivation: gameState.motivation,
                onBoostTap: _boostMotivation,
              ),
              const SizedBox(height: 20),
              StudyRoom(
                gameState: gameState,
                onTap: onEctsClick,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showExchangeDialogHome,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change tokens to ECTS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 20),
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildBattlePassProgress(),
              const SizedBox(height: 20),
              _buildDailyDealBanner(),
              const SizedBox(height: 20),
              _buildQuickUpgrades(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.purple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tokens Balance',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  Text(
                    '${gameState.tokens}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ECTS: ${Formatters.formatEcts(gameState.ects)}    Tap x${gameState.tapMultiplier.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    gameState.educationLevel,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Sem ${gameState.educationSemester}/${gameState.getTotalSemestersForLevel()}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text('Prestige: ${gameState.prestigePoints}',
                      style: const TextStyle(color: Colors.amber)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('Per Click',
                  Formatters.formatPerClick(gameState.tokensPerClick)),
              _statItem('Per Second',
                  Formatters.formatPerSecond(gameState.tokensPerSecond)),
              _statItem(
                  'Total',
                  Formatters.formatNumber(
                      gameState.totalEctsEarned.toDouble())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProgressBar() {
    final requiredEcts = gameState.getRequiredEcts();
    double progress = (gameState.ects / requiredEcts).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress to pass the semester',
                style: TextStyle(color: Colors.white)),
            Text('${Formatters.formatEcts(gameState.ects)}/$requiredEcts ECTS',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Container(
              height: 20,
              alignment: Alignment.center,
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (gameState.ects >= requiredEcts)
          ElevatedButton.icon(
            onPressed: prestige,
            icon: const Icon(Icons.school),
            label: Text(
              gameState.educationSemester >=
                      gameState.getTotalSemestersForLevel()
                  ? 'FINISH ${gameState.educationLevel.toUpperCase()}!'
                  : 'PASS THE SEMESTER AND MOVE ON!',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
      ],
    );
  }

  Widget _buildBattlePassProgress() {
    final requiredXP = (gameState.battlePassLevel + 1) * 50;
    final progress = (gameState.battlePassXP / requiredXP).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.pink.shade900],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Battle Pass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${gameState.battlePassLevel}/10',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              if (!gameState.isPremiumBattlePass)
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF2a2a4e),
                        title: const Text('Premium Battle Pass',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Unlock exclusive rewards!\n\n'
                          '- x2 rewards\n'
                          '- Unique skins\n'
                          '- Permanent boosts\n\n'
                          'Price: \$4.99',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                gameState.isPremiumBattlePass = true;
                              });
                              SaveService.saveGame(gameState);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple),
                            child: const Text('Buy!'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 15,
          ),
          const SizedBox(height: 5),
          Text(
            '${gameState.battlePassXP}/$requiredXP XP',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDealBanner() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (gameState.lastDailyDealCheck == null ||
        gameState.lastDailyDealCheck!.isBefore(today)) {
      gameState.hasPurchasedDailyDeal = false;
      gameState.lastDailyDealCheck = now;
      SaveService.saveGame(gameState);
    }

    if (gameState.hasPurchasedDailyDeal) {
      return const SizedBox.shrink();
    }

    final deal = DailyDeal.generateDailyDeal(now.day);

    return GestureDetector(
      onTap: () => _showDailyDealPopup(deal),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.red.shade700],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              deal.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'DAILY DEAL',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          deal.getTimeRemainingString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    deal.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${deal.discountPercent}% OFF - ${deal.description}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyDealPopup(DailyDeal deal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a4e),
        title: Row(
          children: [
            Text(deal.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAILY DEAL',
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                  Text(
                    deal.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              deal.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${deal.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 20,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '\$${deal.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'SAVE ${deal.discountPercent}%!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.orange, size: 16),
                const SizedBox(width: 5),
                Text(
                  'Expires in: ${deal.getTimeRemainingString()}',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                gameState.hasPurchasedDailyDeal = true;
              });
              SaveService.saveGame(gameState);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deal purchased! (demo - no real payment)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text(
              'BUY NOW!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUpgrades() {
    final availableUpgrades =
        Upgrade.getUpgradesForLevel(gameState.educationLevel);
    final quickUpgrades = availableUpgrades.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Buy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpgradesScreen(
                      gameState: gameState,
                      onUpgradeBuy: buyUpgrade,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
              child: const Text('See more →'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...quickUpgrades.map((upgrade) {
          return UpgradeCard(
            upgrade: upgrade,
            currentLevel: gameState.upgrades[upgrade.id] ?? 0,
            currentCurrency: gameState.tokens.toDouble(),
            onBuy: () => buyUpgrade(upgrade),
          );
        }),
      ],
    );
  }
}
