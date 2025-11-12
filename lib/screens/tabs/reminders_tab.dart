import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:priyanakaenterprises/screens/details/client_detials_screen.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ReminderFilter { overdue, urgent, dueToday, upcoming, all }


class RemindersTab extends StatefulWidget {
  const RemindersTab({super.key});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReminderFilter _selectedFilter = ReminderFilter.overdue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedFilter = ReminderFilter.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _autoUpdateReminderStatus(DocumentSnapshot reminder) async {
    final data = reminder.data() as Map<String, dynamic>;
    final int cardDueDate = data['cardDueDate'] ?? 0;
    final String currentStatus = data['status'] ?? 'pending';
    final Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
    if (cardDueDate == 0) return;

    final now = DateTime.now();
    DateTime lastUpdated = updatedAt?.toDate() ?? now;

    final isNewMonth = (now.year > lastUpdated.year) ||
        (now.year == lastUpdated.year && now.month > lastUpdated.month);

    if (isNewMonth && currentStatus == 'paid') {
      try {
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(reminder.id)
            .update({'status': 'pending', 'updatedAt': FieldValue.serverTimestamp()});
      } catch (e) {
        // Handle error if needed
      }
    }
  }

  int _getDaysUntilDue(int cardDueDate) {
    final now = DateTime.now();
    final today = now.day;
    if (cardDueDate >= today) return cardDueDate - today;
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    return (daysInCurrentMonth - today) + cardDueDate;
  }

  bool _shouldShowReminder(Map<String, dynamic> data) {
    final int cardDueDate = data['cardDueDate'] ?? 0;
    final String status = data['status'] ?? 'pending';
    if (cardDueDate == 0 || status != 'pending') return false;

    final daysUntil = _getDaysUntilDue(cardDueDate);
    final now = DateTime.now();
    final today = now.day;

    switch (_selectedFilter) {
      case ReminderFilter.overdue:
        return cardDueDate < today;
      case ReminderFilter.urgent:
        return daysUntil <= 3 && cardDueDate >= today;
      case ReminderFilter.dueToday:
        return cardDueDate == today;
      case ReminderFilter.upcoming:
        return daysUntil > 3 && daysUntil <= 7;
      case ReminderFilter.all:
        return true;
    }
  }

  Stream<QuerySnapshot> _buildRemindersStream(String distributorId) {
    return FirebaseFirestore.instance
        .collection('reminders')
        .where('distributorId', isEqualTo: distributorId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final distributorId = context.watch<AuthProvider>().distributorId;
    if (distributorId == null) {
      return Scaffold(appBar: AppBar(title: const Text('Reminders')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Reminders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.primary),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              tabs: const [
                Tab(icon: Icon(Icons.error_outline_rounded), text: 'OVERDUE'),
                Tab(icon: Icon(Icons.warning_amber_rounded), text: 'URGENT'),
                Tab(icon: Icon(Icons.today_rounded), text: 'DUE TODAY'),
                Tab(icon: Icon(Icons.calendar_today_rounded), text: 'UPCOMING'),
                Tab(icon: Icon(Icons.list_rounded), text: 'ALL'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildRemindersStream(distributorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _EmptyState(message: 'No reminders found.');

          final allReminders = snapshot.data!.docs;

          for (var reminder in allReminders) {
            _autoUpdateReminderStatus(reminder);
          }

          final filtered = allReminders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _shouldShowReminder(data);
          }).toList();

          filtered.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final daysA = _getDaysUntilDue(dataA['cardDueDate'] ?? 0);
            final daysB = _getDaysUntilDue(dataB['cardDueDate'] ?? 0);
            
            // For overdue, sort by how many days overdue (most overdue first)
            if (_selectedFilter == ReminderFilter.overdue) {
              final dueDateA = dataA['cardDueDate'] ?? 0;
              final dueDateB = dataB['cardDueDate'] ?? 0;
              return dueDateA.compareTo(dueDateB);
            }
            
            return daysA.compareTo(daysB);
          });

          if (filtered.isEmpty) return _EmptyState(message: 'All caught up!', subtitle: 'No ${_selectedFilter.name} reminders.');

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data() as Map<String, dynamic>;
              final daysUntil = _getDaysUntilDue(data['cardDueDate'] ?? 0);
              return AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ReminderCardV2(reminderDoc: doc, daysUntilDue: daysUntil),
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------ Smaller UI Widgets ------------------
class _EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  const _EmptyState({super.key, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 92, color: Colors.grey[400]),
          const SizedBox(height: 18),
          Text(message, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black54)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(color: Colors.black45)),
          ]
        ]),
      ),
    );
  }
}

class ReminderCardV2 extends StatelessWidget {
  final DocumentSnapshot reminderDoc;
  final int daysUntilDue;
  const ReminderCardV2({super.key, required this.reminderDoc, required this.daysUntilDue});

  Map<String, dynamic> get data => reminderDoc.data() as Map<String, dynamic>;
  String get clientName => data['clientName'] ?? 'Unknown Client';
  String get clientMobile => data['clientMobile'] ?? '';
  
  String get bankName => data['bankName'] ?? 'Bank';
    String get shortBankName => bankName.split(' ').first;


  String get cardnumber {
    final number = data['cardnumber'] as String?;
    if (number != null && number.length >= 4) return number.substring(number.length - 4);
    return '****';
  }

  int get cardDueDate => data['cardDueDate'] ?? 0;
  String get clientId => data['clientId'] ?? '';

  bool get _isOverdue {
    final now = DateTime.now();
    return cardDueDate < now.day;
  }

  Color _urgencyColor() {
    if (_isOverdue) return Colors.red.shade800;
    if (daysUntilDue <= 0) return Colors.red.shade600;
    if (daysUntilDue <= 3) return Colors.orange.shade700;
    return Colors.blue.shade700;
  }

  String _urgencyText() {
    if (_isOverdue) {
      final now = DateTime.now();
      final daysOverdue = now.day - cardDueDate;
      return 'OVERDUE ($daysOverdue ${daysOverdue == 1 ? 'DAY' : 'DAYS'})';
    }
    if (daysUntilDue <= 0) return 'DUE TODAY';
    if (daysUntilDue == 1) return 'DUE TOMORROW';
    return 'DUE IN $daysUntilDue DAYS';
  }


  Future<void> _callNumber(String number) async {
    if (number.isEmpty) {
      Fluttertoast.showToast(msg: 'No number available');
      return;
    }
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _markAsPaid(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark ${shortBankName} ••••$cardnumber for $clientName as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('reminders').doc(reminderDoc.id).update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Marked as paid', backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor();
    final urgencyText = _urgencyText();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: _isOverdue ? 8 : 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (clientId.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => ClientDetailsScreen(clientId: clientId)));
          }
        },
        child: Column(children: [
          // Header
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(colors: [urgencyColor.withOpacity(0.12), Colors.white]),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.credit_card, color: urgencyColor),
                const SizedBox(width: 10),
                Text('$shortBankName ••••$cardnumber', style: TextStyle(fontWeight: FontWeight.bold, color: urgencyColor)),
              ]),
              Chip(label: Text(urgencyText, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: urgencyColor)
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: urgencyColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(clientName.isNotEmpty ? clientName[0].toUpperCase() : '?', style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold, fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(clientName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.phone, size: 14, color: Colors.grey[600]), const SizedBox(width: 6), Text(clientMobile.isNotEmpty ? clientMobile : 'No mobile', style: TextStyle(color: Colors.grey[700]))]),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]), const SizedBox(width: 6), Text('Due: ${cardDueDate}${_getDaySuffix(cardDueDate)}', style: TextStyle(color: Colors.grey[700]))]),
                ]),
              ),
              // Actions
              Column(children: [
                IconButton(icon: const Icon(Icons.call), color: urgencyColor, onPressed: () => _callNumber(clientMobile)),
                const SizedBox(height: 4),
                ElevatedButton.icon(onPressed: () => _markAsPaid(context), icon: const Icon(Icons.check), label: const Text('Paid'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green),)
              ])
            ]),
          )
        ]),
      ),
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