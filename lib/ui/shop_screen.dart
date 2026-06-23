import 'package:flutter/material.dart';
import '../service/purchase_service.dart';
import '../model/game_state.dart';
import '../service/save_service.dart';
import 'achievements_screen.dart';
import 'payment_screen.dart';

class ShopScreen extends StatefulWidget {
  final GameState gameState;

  const ShopScreen({super.key, required this.gameState});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    PurchaseService.setOnPurchaseSuccess((productId) {
      _handlePurchaseSuccess(productId);
    });
  }

  void _handlePurchaseSuccess(String productId) {
    setState(() {
      switch (productId) {
        case PurchaseService.premiumBattlePassId:
          widget.gameState.isPremiumBattlePass = true;
          _showSuccessDialog('👑 Premium Battle Pass activated!');
          break;
        case PurchaseService.motivationBoostId:
          widget.gameState.tokens += 50;
          widget.gameState.motivation =
              (widget.gameState.motivation + 15).clamp(0, 100.0);
          _showSuccessDialog(
              '☕ You received 50 tokens and +15% motivation (max).');
          break;
        case PurchaseService.megaEctsPackId:
          widget.gameState.tokens += 1000;
          _showSuccessDialog(
              '💰 You received 1000 tokens (exchangeable limit).');
          break;
        case PurchaseService.removeAdsId:
          widget.gameState.hasRemovedAds = true;
          _showSuccessDialog('🚫 Ads disabled!');
          break;
        case PurchaseService.skinGoldLaptopId:
          if (!widget.gameState.unlockedSkins
              .contains(PurchaseService.skinGoldLaptopId)) {
            widget.gameState.unlockedSkins
                .add(PurchaseService.skinGoldLaptopId);
          }
          widget.gameState.currentSkin = PurchaseService.skinGoldLaptopId;
          _showSuccessDialog('✨ Unlocked skin: Gold Laptop!');
          break;
        case PurchaseService.skinNeonId:
          if (!widget.gameState.unlockedSkins
              .contains(PurchaseService.skinNeonId)) {
            widget.gameState.unlockedSkins.add(PurchaseService.skinNeonId);
          }
          widget.gameState.currentSkin = PurchaseService.skinNeonId;
          _showSuccessDialog('🌈 Unlocked skin: Neon!');
          break;
        case PurchaseService.skinRetroId:
          if (!widget.gameState.unlockedSkins
              .contains(PurchaseService.skinRetroId)) {
            widget.gameState.unlockedSkins.add(PurchaseService.skinRetroId);
          }
          widget.gameState.currentSkin = PurchaseService.skinRetroId;
          _showSuccessDialog('🕹️ Unlocked skin: Retro!');
          break;
      }
      SaveService.saveGame(widget.gameState);
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a4e),
        title: const Text('Purchase Successful!',
            style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyProduct(String productId, bool isConsumable, String title,
      String description, String emoji, String price) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          productTitle: title,
          productDescription: description,
          price: price,
          emoji: emoji,
          onPaymentSuccess: () {
            _handlePurchaseSuccess(productId);
          },
        ),
      ),
    );
  }

  void _showExchangeDialog() {
    final maxAllowed = widget.gameState.maxEctsFromExchangePerSemester -
        widget.gameState.ectsExchangedThisSemester;
    final rate = widget.gameState.getTokensPerEcts();
    final affordableByTokens = widget.gameState.tokens ~/ rate;
    final allowed =
        (maxAllowed < affordableByTokens) ? maxAllowed : affordableByTokens;

    if (allowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No exchanges available (no tokens or limit reached).')),
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
              'You can exchange up to $allowed ECTS ($rate tokens = 1 ECTS). You have ${widget.gameState.tokens} tokens.',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _performExchange(1);
                Navigator.pop(context);
              },
              child: const Text('Exchange 1 ECTS'),
            ),
            ElevatedButton(
              onPressed: () {
                _performExchange(allowed);
                Navigator.pop(context);
              },
              child: Text('Exchange $allowed ECTS'),
            ),
          ],
        );
      },
    );
  }

  void _performExchange(int ectsToExchange) {
    final remainingLimit = widget.gameState.maxEctsFromExchangePerSemester -
        widget.gameState.ectsExchangedThisSemester;
    final rate = widget.gameState.getTokensPerEcts();
    final affordableByTokens = widget.gameState.tokens ~/ rate;
    final allowedByRequest = ectsToExchange;
    final allowed = [remainingLimit, affordableByTokens, allowedByRequest]
        .reduce((a, b) => a < b ? a : b);

    final cost = allowed * rate;
    if (widget.gameState.tokens < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough tokens.')),
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

    widget.gameState.tokens -= cost;
    widget.gameState.pendingEctsFromExchange += allowed;
    widget.gameState.ectsExchangedThisSemester += allowed;
    SaveService.saveGame(widget.gameState);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Exchanged $allowed ECTS (awarded at the end of the semester).')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Shop'),
        backgroundColor: const Color(0xFF0f3460),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
              children: [
                _buildShopItem(
                  emoji: '👑',
                  title: 'Premium Battle Pass',
                  description: 'Unlock all rewards + x2 boosts',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.premiumBattlePassId),
                  productId: PurchaseService.premiumBattlePassId,
                  isConsumable: false,
                  isPurchased: widget.gameState.isPremiumBattlePass,
                ),
                _buildShopItem(
                  emoji: '☕',
                  title: 'Energy Pack',
                  description:
                      'Gives 50 tokens and restores up to +15% motivation (not 100%).',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.motivationBoostId),
                  productId: PurchaseService.motivationBoostId,
                  isConsumable: true,
                ),
                _buildShopItem(
                  emoji: '💰',
                  title: 'Token Bundle',
                  description:
                      'Get 1000 tokens (can be exchanged with limitations).',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.megaEctsPackId),
                  productId: PurchaseService.megaEctsPackId,
                  isConsumable: true,
                ),
                _buildShopItem(
                  emoji: '🚫',
                  title: 'Remove Ads',
                  description: 'Play without ads forever!',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.removeAdsId),
                  productId: PurchaseService.removeAdsId,
                  isConsumable: false,
                ),
                const SizedBox(height: 12),
                _buildShopItem(
                  emoji: '💻',
                  title: 'Golden Laptop (skin)',
                  description: 'Appearance: golden laptop — cosmetic only.',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.skinGoldLaptopId),
                  productId: PurchaseService.skinGoldLaptopId,
                  isConsumable: false,
                  isPurchased: widget.gameState.unlockedSkins
                      .contains(PurchaseService.skinGoldLaptopId),
                ),
                _buildShopItem(
                  emoji: '🌈',
                  title: 'Neon (skin)',
                  description: 'Neon effect — cosmetic only.',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.skinNeonId),
                  productId: PurchaseService.skinNeonId,
                  isConsumable: false,
                  isPurchased: widget.gameState.unlockedSkins
                      .contains(PurchaseService.skinNeonId),
                ),
                _buildShopItem(
                  emoji: '🕹️',
                  title: 'Retro (skin)',
                  description: 'Retro style — cosmetic only.',
                  price: PurchaseService.getProductPrice(
                      PurchaseService.skinRetroId),
                  productId: PurchaseService.skinRetroId,
                  isConsumable: false,
                  isPurchased: widget.gameState.unlockedSkins
                      .contains(PurchaseService.skinRetroId),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await PurchaseService.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Purchases restored!')),
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Restore Purchases',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showExchangeDialog(),
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  label: const Text('Exchange tokens for ECTS',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AchievementsScreen(gameState: widget.gameState)),
                    );
                  },
                  icon: const Icon(Icons.emoji_events, color: Colors.white),
                  label: const Text('Achievements',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShopItem({
    required String emoji,
    required String title,
    required String description,
    required String price,
    required String productId,
    required bool isConsumable,
    bool isPurchased = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade800,
            Colors.indigo.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPurchased ? Colors.green : Colors.purple.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 50)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (isPurchased)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Purchased',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _buyProduct(
                  productId, isConsumable, title, description, emoji, price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'BUY FOR $price',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
