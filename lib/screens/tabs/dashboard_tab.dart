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

    if (distributorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final clientFormLink = 'https://formsapp-five.vercel.app/form/$distributorId';

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                      const SizedBox(height: 32),
                      QuickActionsArea(clientFormLink: clientFormLink, constraints: constraints),
                      const SizedBox(height: 32),
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
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
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
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distributorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
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
        double pendingAmount = 0;
        double paidAmount = 0;

        if (billSnapshot.hasData) {
          for (var doc in billSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final interestAmount = (data['interestAmount'] as num?)?.toDouble() ?? 0.0;
            final status = data['status'] as String?;

            // Total income is sum of all interest amounts (paid bills)
            if (status == 'paid') {
              totalIncome += interestAmount;
              paidAmount += interestAmount;
            } else if (status == 'pending' || status == 'unpaid' || status == 'partial') {
              pendingAmount += interestAmount;
            }
          }
        }

        final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: TotalClientsCard(distributorId: distributorId, constraints: constraints)),
                SizedBox(width: spacing),
                Expanded(
                  child: StatCard(
                    title: 'Total Income',
                    value: currencyFormatter.format(totalIncome),
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF10B981),
                    constraints: constraints,
                  ),
                ),
              ],
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return StatCard(
            title: 'Total Clients',
            value: '...',
            icon: Icons.people_rounded,
            color: const Color(0xFF3B82F6),
            constraints: constraints,
          );
        }
        final count = snapshot.data?.size ?? 0;
        return StatCard(
          title: 'Total Clients',
          value: count.toString(),
          icon: Icons.people_rounded,
          color: const Color(0xFF3B82F6),
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
            Container(width: 4, height: 24, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        const SizedBox(height: 20),
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
  final VoidCallback onPressed;

  const ActionButton._({super.key, required this.icon, required this.label, required this.color, required this.onPressed});

  factory ActionButton.share({required String link}) {
    return ActionButton._(
      icon: Icons.share_rounded,
      label: 'Share Form Link',
      color: const Color(0xFF3B82F6),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: link)).then((_) {
          // Fluttertoast.showToast(msg: "Client form link copied!");
        });
      },
    );
  }

  factory ActionButton.addClient() {
    return ActionButton._(
      icon: Icons.person_add_alt_1_rounded,
      label: 'Add Client',
      color: const Color(0xFF10B981),
      onPressed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    VoidCallback finalOnPressed = onPressed;
    if (label == 'Add Client') {
      finalOnPressed = () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen()));
      };
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: finalOnPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
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
            Container(width: 4, height: 24, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        const SizedBox(height: 20),
        RemindersDueTodayWidget(distributorId: distributorId),
        const SizedBox(height: 16),
        GatewayStatsWidget(distributorId: distributorId),
        const SizedBox(height: 16),
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              Expanded(child: RecentBillsWidget(distributorId: distributorId)),
            ],
          )
        else
          Column(
            children: [
              const SizedBox(height: 16),
              RecentBillsWidget(distributorId: distributorId),
            ],
          ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Count payments by gateway
        Map<String, int> gatewayCounts = {
          'plg': 0,
          'slg': 0,
          'pay': 0,
          'nter': 0,
        };

        Map<String, String> gatewayNames = {
          'plg': 'PLG',
          'slg': 'SLG',
          'pay': 'PAY',
          'nter': 'NTER',
        };

        Map<String, Color> gatewayColors = {
          'plg': const Color(0xFF3B82F6),
          'slg': const Color(0xFF10B981),
          'pay': const Color(0xFFF59E0B),
          'nter': const Color(0xFF8B5CF6),
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF6366F1),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Gateway Payment Stats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: gatewayCounts.length,
                  itemBuilder: (context, index) {
                    final gatewayKey = gatewayCounts.keys.elementAt(index);
                    final count = gatewayCounts[gatewayKey]!;
                    final name = gatewayNames[gatewayKey]!;
                    final color = gatewayColors[gatewayKey]!;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'payment${count != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
          return EmptyStateWidget(message: 'No recent bills', icon: Icons.receipt_long_outlined);
        }

        final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24)),
                    const SizedBox(width: 12),
                    Text('Latest Bills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final amount = (data['interestAmount'] as num?)?.toDouble() ?? 0.0;
                    final currency = currencyFormatter.format(amount);
                    final status = data['status'] ?? 'No Status';
                    final isPaid = status == 'paid';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: isPaid ? [const Color(0xFF10B981), const Color(0xFF059669)] : [const Color(0xFFF59E0B), const Color(0xFFD97706)]), borderRadius: BorderRadius.circular(12)),
                            child: Icon(isPaid ? Icons.check_circle_rounded : Icons.pending_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['clientName'] ?? 'Unknown Client', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: isPaid ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontWeight: FontWeight.w600, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                          Text(currency, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Reminders Due Today (${todayDay}${_getDaySuffix(todayDay)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.credit_card, color: Color(0xFFEF4444), size: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['clientName'] ?? 'Unknown Client', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('${data['bankName'] ?? 'Unknown Bank'} •••• ${data['lastFourDigits'] ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                Text('📱 ${data['clientMobile'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)), child: const Text('DUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
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
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ------------------ Empty State ------------------
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateWidget({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(icon, size: 48, color: Colors.grey[400])),
              const SizedBox(height: 16),
              Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

