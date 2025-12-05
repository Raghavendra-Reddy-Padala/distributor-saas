import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:priyanakaenterprises/screens/add_bill_screen.dart';
import 'package:priyanakaenterprises/screens/forms/add_client_screen.dart';
import 'package:priyanakaenterprises/screens/profile_screen.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:priyanakaenterprises/widgets/stat_card.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final distributorId = authProvider.distributorId;
    final distributorName = authProvider.distributorName ?? 'Distributor';

    // FINANCE THEME COLORS
    final Color bgColor = Colors.blueGrey[50]!; // Corporate Background

    if (distributorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final clientFormLink = 'https://formsapp-five.vercel.app/form/$distributorId';

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          DashboardAppBar(distributorName: distributorName),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatArea(distributorId: distributorId, constraints: constraints),
                      const SizedBox(height: 24), // Tighter spacing
                      QuickActionsArea(clientFormLink: clientFormLink, constraints: constraints),
                      const SizedBox(height: 24),
                      RecentActivityArea(distributorId: distributorId, constraints: constraints),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardAppBar extends StatelessWidget {
  final String distributorName;
  const DashboardAppBar({super.key, required this.distributorName});

  @override
  Widget build(BuildContext context) {
    // Uses the Navy Primary from Main Theme
    final primaryColor = Theme.of(context).primaryColor; 

    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                const Color(0xFF002171), // Darker shade of Navy
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business, color: Colors.white70, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            distributorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            // Gold Icon for Settings implies importance
            icon: const Icon(Icons.settings, color: Color(0xFFFFA000)), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------ Stats Area ------------------
class StatArea extends StatelessWidget {
  final String distributorId;
  final BoxConstraints constraints;

  const StatArea({super.key, required this.distributorId, required this.constraints});

  @override
  Widget build(BuildContext context) {
    final isTablet = constraints.maxWidth > 600;
    final spacing = isTablet ? 16.0 : 12.0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bills').where('distributorId', isEqualTo: distributorId).snapshots(),
      builder: (context, billSnapshot) {
        double totalIncome = 0;
        
        if (billSnapshot.hasData) {
          for (var doc in billSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final interestAmount = (data['interestAmount'] as num?)?.toDouble() ?? 0.0;
            final status = data['status'] as String?;

            if (status == 'paid') {
              totalIncome += interestAmount;
            }
          }
        }

        final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

        return Row(
          children: [
            Expanded(child: TotalClientsCard(distributorId: distributorId, constraints: constraints)),
            SizedBox(width: spacing),
            Expanded(
              child: StatCard(
                title: 'Total Income',
                value: currencyFormatter.format(totalIncome),
                icon: Icons.account_balance_wallet,
                // Using Dark Green for Money (Financial standard)
                color: const Color(0xFF1B5E20), 
                constraints: constraints,
              ),
            ),
          ],
        );
      },
    );
  }
}

class TotalClientsCard extends StatelessWidget {
  final String distributorId;
  final BoxConstraints constraints;

  const TotalClientsCard({super.key, required this.distributorId, required this.constraints});

  @override
  Widget build(BuildContext context) {
    final clientStream = FirebaseFirestore.instance.collection('clients').where('distributorId', isEqualTo: distributorId).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: clientStream,
      builder: (context, snapshot) {
        final count = snapshot.data?.size ?? 0;
        return StatCard(
          title: 'Total Clients',
          value: count.toString(),
          icon: Icons.groups_3,
          // Using Navy Blue for Client Base
          color: const Color(0xFF0D47A1), 
          constraints: constraints,
        );
      },
    );
  }
}

// ------------------ Quick Actions ------------------
class QuickActionsArea extends StatelessWidget {
  final String clientFormLink;
  final BoxConstraints constraints;

  const QuickActionsArea({super.key, required this.clientFormLink, required this.constraints});

  @override
  Widget build(BuildContext context) {
    final isTablet = constraints.maxWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Gold Bar indicator
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFFFA000), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Quick Actions', style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 16),
        isTablet
            ? Row(
                children: [
                  Expanded(child: ActionButton.share(link: clientFormLink)),
                  const SizedBox(width: 12),
                  Expanded(child: ActionButton.addClient()),
                ],
              )
            : Column(
                children: [
                  ActionButton.share(link: clientFormLink),
                  const SizedBox(height: 12),
                  ActionButton.addClient(),
                ],
              ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onPressed;

  const ActionButton._({
    super.key, 
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onPressed,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
  });

  factory ActionButton.share({required String link}) {
    return ActionButton._(
      icon: Icons.share,
      label: 'Share Form Link',
      // Navy Blue for Admin tasks
      color: const Color(0xFF0D47A1), 
      onPressed: () {
        Clipboard.setData(ClipboardData(text: link));
      },
    );
  }

  factory ActionButton.addClient() {
    return ActionButton._(
      icon: Icons.person_add,
      label: 'Add New Client',
      // Gold for Growth/Sales tasks (High Visibility)
      color: const Color(0xFFFFA000), 
      textColor: const Color(0xFF0D47A1), // Navy text on Gold
      iconColor: const Color(0xFF0D47A1),
      onPressed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    VoidCallback finalOnPressed = onPressed;
    if (label == 'Add New Client') {
      finalOnPressed = () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen()));
      };
    }

    return Material(
      elevation: 2,
      // Sharper corners (8) for professional look
      borderRadius: BorderRadius.circular(8), 
      color: color,
      child: InkWell(
        onTap: finalOnPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                label, 
                style: TextStyle(
                  color: textColor, 
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 0.5
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ Recent Activity ------------------
class RecentActivityArea extends StatelessWidget {
  final String distributorId;
  final BoxConstraints constraints;

  const RecentActivityArea({super.key, required this.distributorId, required this.constraints});

  @override
  Widget build(BuildContext context) {
    final isTablet = constraints.maxWidth > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFFFA000), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Recent Activity', style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 16),
        RemindersDueTodayWidget(distributorId: distributorId),
        const SizedBox(height: 16),
        GatewayStatsWidget(distributorId: distributorId),
        const SizedBox(height: 16),
        RecentBillsWidget(distributorId: distributorId),
      ],
    );
  }
}

// ------------------ Gateway Stats Widget ------------------
class GatewayStatsWidget extends StatelessWidget {
  final String distributorId;
  const GatewayStatsWidget({super.key, required this.distributorId});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('bills')
        .where('distributorId', isEqualTo: distributorId)
        .where('status', isEqualTo: 'paid')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        Map<String, int> gatewayCounts = {'plg': 0, 'slg': 0, 'pay': 0, 'nter': 0};
        Map<String, String> gatewayNames = {'plg': 'PLG', 'slg': 'SLG', 'pay': 'PAY', 'nter': 'NTER'};
        
        // Professional Palette for Chart items
        Map<String, Color> gatewayColors = {
          'plg': const Color(0xFF1565C0), // Blue 800
          'slg': const Color(0xFF2E7D32), // Green 800
          'pay': const Color(0xFFEF6C00), // Orange 800
          'nter': const Color(0xFF6A1B9A), // Purple 800 (Darker)
        };

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final gateway = data['selectedGateway'] as String?;
          if (gateway != null && gatewayCounts.containsKey(gateway)) {
            gatewayCounts[gateway] = gatewayCounts[gateway]! + 1;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // Sharp corners
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Gold Icon
                    const Icon(Icons.pie_chart, color: Color(0xFFFFA000), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Gateway Stats',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: gatewayCounts.length,
                  itemBuilder: (context, index) {
                    final gatewayKey = gatewayCounts.keys.elementAt(index);
                    final count = gatewayCounts[gatewayKey]!;
                    final color = gatewayColors[gatewayKey]!;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.3)),
                        // Left border accent
                        boxShadow: [
                          BoxShadow(color: color, offset: const Offset(-4, 0), blurRadius: 0) 
                        ]
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(gatewayNames[gatewayKey]!, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
                          Text(count.toString(), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RecentBillsWidget extends StatelessWidget {
  final String distributorId;
  const RecentBillsWidget({super.key, required this.distributorId});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('bills').where('distributorId', isEqualTo: distributorId).orderBy('createdAt', descending: true).limit(5).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(message: 'No recent bills', icon: Icons.receipt_long);
        }

        final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF0D47A1), size: 24),
                    const SizedBox(width: 8),
                    Text('Latest Transactions', style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final amount = (data['interestAmount'] as num?)?.toDouble() ?? 0.0;
                    final currency = currencyFormatter.format(amount);
                    final status = data['status'] ?? 'No Status';
                    final isPaid = status == 'paid';

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green[50] : Colors.amber[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isPaid ? Icons.check : Icons.access_time,
                            size: 18,
                            color: isPaid ? Colors.green[800] : Colors.amber[900],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['clientName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(data['bankName'] ?? 'Bank', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey[900])),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green[800] : Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------ Reminders ------------------
class RemindersDueTodayWidget extends StatelessWidget {
  final String distributorId;
  const RemindersDueTodayWidget({super.key, required this.distributorId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDay = now.day;
    final stream = FirebaseFirestore.instance.collection('reminders').where('distributorId', isEqualTo: distributorId).where('status', isEqualTo: 'pending').where('cardDueDate', isEqualTo: todayDay).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            // Dark Red for High Priority/Urgent
            color: const Color(0xFFB71C1C), 
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Urgent: Due Today (${todayDay}${_getDaySuffix(todayDay)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['clientName'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('📱 ${data['clientMobile'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[100]!),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text('COLLECT', style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateWidget({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}