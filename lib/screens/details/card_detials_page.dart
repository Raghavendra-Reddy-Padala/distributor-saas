import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priyanakaenterprises/screens/add_bill_screen.dart';

class CreditCardsPage extends StatelessWidget {
  final Map<String, dynamic> clientData;
  const CreditCardsPage({super.key, required this.clientData});

  @override
  Widget build(BuildContext context) {
    final cards = (clientData['creditCards'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    final totalLimit = cards.fold<double>(
      0,
      (sum, card) => sum + ((card['cardLimit'] as num?)?.toDouble() ?? 0),
    );

    final formattedTotalLimit = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(totalLimit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Cards', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  child: Row(
    children: [
      Expanded(
        child: _CompactStatItem(
          icon: Icons.credit_card,
          label: 'Total Cards',
          value: '${cards.length}',
          isAmount: false,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _CompactStatItem(
          icon: Icons.account_balance_wallet,
          label: 'Total Limit',
          value: formattedTotalLimit,
          isAmount: true, // <--- respects the amount sizing now
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
          ),
        ),
      ),
    ],
  ),
),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Your Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cards.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cards list
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No credit cards found',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CreditCardItem(cardData: cards[index],
                          clientData: clientData, // pass the whole client data map
      clientId: clientData['id']?.toString() ?? clientData['clientId']?.toString() ?? '',
      clientName: clientData['name']?.toString() ?? clientData['clientName']?.toString() ?? 'Client',
      cardIndex: index,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  final bool isAmount;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: isAmount ? 18 : 16, // larger when amount
      fontWeight: isAmount ? FontWeight.w900 : FontWeight.w800,
      letterSpacing: isAmount ? 0.6 : 0.3,
    );

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: valueStyle,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.85)),
        ],
      ),
    );
  }
}

class CreditCardItem extends StatefulWidget {
  final Map<String, dynamic> cardData;
   final Map<String, dynamic> clientData; // new
  final String clientId;                  // new
  final String clientName;                // new
  final int cardIndex;      
  const CreditCardItem({super.key, required this.cardData,
   required this.clientData,
    required this.clientId,
    required this.clientName,
    required this.cardIndex,
  });

  @override
  State<CreditCardItem> createState() => _CreditCardItemState();
}

class _CreditCardItemState extends State<CreditCardItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFront) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  LinearGradient _getCardGradient(String? bankName) {
    final bank = (bankName ?? '').toLowerCase();
    if (bank.contains('hdfc')) {
      return const LinearGradient(
        colors: [Color(0xFF004C8F), Color(0xFF0066B2), Color(0xFF0A63A6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('icici')) {
      return const LinearGradient(
        colors: [Color(0xFFB34700), Color(0xFFEF6C00), Color(0xFFFF8C42)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('axis')) {
      return const LinearGradient(
        colors: [Color(0xFF7B0F2E), Color(0xFFA41C44), Color(0xFFC92752)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('sbi')) {
      return const LinearGradient(
        colors: [Color(0xFF0B3A78), Color(0xFF134A96), Color(0xFF1E5BB8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('kotak')) {
      return const LinearGradient(
        colors: [Color(0xFF9F1D22), Color(0xFFD22B2B), Color(0xFFE63946)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('citibank') || bank.contains('citi')) {
      return const LinearGradient(
        colors: [Color(0xFF003A70), Color(0xFF004F8C), Color(0xFF0066B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF1F2937), Color(0xFF334155), Color(0xFF475569)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

 

  @override
  Widget build(BuildContext context) {
    final cardData = widget.cardData;
    final bankName = (cardData['bankName'] as String?) ?? 'Bank';
    final cardNumber = (cardData['cardNumber'] as String?) ?? '';
    final holder = (cardData['cardHolderName'] as String?) ?? '—';
    final expiry = (cardData['expiryDate'] as String?) ?? 'MM/YY';
    final cvv = (cardData['cvv'] as String?) ?? '•••';
    final limitValue = (cardData['cardLimit'] as num?)?.toDouble() ?? 0;
    final limit = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(limitValue);
    final billDate = (cardData['billGenerationDate'] != null)
        ? cardData['billGenerationDate'].toString()
        : '-';
    final dueDate = (cardData['cardDueDate'] != null)
        ? cardData['cardDueDate'].toString()
        : '-';

    final gradient = _getCardGradient(bankName);
    const cardHeight = 200.0;
    const cardRadius = 16.0;

    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final value = _anim.value;
          // angle ranges from 0 -> pi
          final angle = value * math.pi;
          final isFrontVisible = angle <= math.pi / 2;

          // rotate the whole card for perspective
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: SizedBox(
              height: cardHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  child: Container(
                    // KEEP the same outer decoration for both sides so color doesn't "jump"
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    padding: const EdgeInsets.all(0),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        // FRONT
                        // We use Opacity + IgnorePointer to make sure only visible side is interactive.
                        Opacity(
                          opacity: isFrontVisible ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !isFrontVisible,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: _buildFrontContent(bankName, cardNumber, holder, expiry, cvv),
                            ),
                          ),
                        ),

                        // BACK
                        // We rotate the back by pi so it reads correctly when the card is rotated.
                        // When not visible, make it invisible but keep it in layout to avoid size jumps.
                        Opacity(
                          opacity: isFrontVisible ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: isFrontVisible,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child:
                                  // Keep same padding & look as front; inner content uses white text to match front
                                  Padding(
                                padding: const EdgeInsets.all(20),
                                child: _buildBackContent(cardRadius, limit, billDate, dueDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontContent(String bankName, String cardNumber, String holder, String expiry,
      String cvv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Bank name and chip
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                bankName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 50,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.amber[600],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Spacer(),

        // Card number
        Text(
          cardNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 20),

        // Bottom row: Holder, Expiry, CVV
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holder.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EXPIRES',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expiry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'CVV',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cvv,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Simplified back: SAME gradient + same font/color style as front.
  // Shows credit limit, bill date, due date and Pay Bill button.
  Widget _buildBackContent(double radius, String limit, String billDate, String dueDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Limit',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                limit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill Date',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day $billDate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day $dueDate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
Spacer(),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              final selectedCard = {
        'bankName': widget.cardData['bankName'],
        'cardNumber': widget.cardData['cardNumber'],
        'cardHolderName': widget.cardData['cardHolderName'],
        'cardLimit': widget.cardData['cardLimit'],
        'cardType': widget.cardData['cardType'],
        'billGenerationDate': widget.cardData['billGenerationDate'],
        'cardDueDate': widget.cardData['cardDueDate'],
        // include other fields your AddBillScreen expects
      };

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddBillScreen(
            clientId: widget.clientId,
            clientName: widget.clientName,
            clientData: widget.clientData,
            selectedCard: selectedCard,
            cardIndex: widget.cardIndex,
          ),
        ),
      );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 18),
                SizedBox(width: 8),
                Text(
                  'Pay Bill',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
