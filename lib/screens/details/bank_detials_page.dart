import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BankAccountsPage extends StatelessWidget {
  final Map<String, dynamic> clientData;
  const BankAccountsPage({super.key, required this.clientData});

  @override
  Widget build(BuildContext context) {
    final accounts = (clientData['bankAccounts'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top stats card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Accounts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${accounts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Active Banks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${accounts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Accounts list
          Expanded(
            child: accounts.isEmpty
                ? const Center(child: Text('No bank accounts found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      return BankAccountItem(accountData: accounts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class BankAccountItem extends StatelessWidget {
  final Map<String, dynamic> accountData;
  const BankAccountItem({super.key, required this.accountData});

  Color _getBankColor(String? bankName) {
    final bank = bankName?.toLowerCase() ?? '';
    if (bank.contains('hdfc')) return const Color(0xFF004C8F);
    if (bank.contains('icici')) return const Color(0xFFB34700);
    if (bank.contains('axis')) return const Color(0xFFA41C44);
    if (bank.contains('sbi')) return const Color(0xFF134A96);
    if (bank.contains('kotak')) return const Color(0xFF9F1D22);
    if (bank.contains('rbl')) return Colors.grey[800]!;
    if (bank.contains('citibank') || bank.contains('citi')) return const Color(0xFF003A70);
    if (bank.contains('idfc')) return const Color(0xFF870E3B);
    if (bank.contains('au small')) return Colors.grey[900]!;
    return Colors.teal[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final bankName = accountData['bankName'] ?? 'Unknown Bank';
    final accountNumber = accountData['accountNumber'] ?? 'XXXXXXXXXXXX';
    final accountHolder = accountData['accountHolderName'] ?? '';
    final ifscCode = accountData['ifscCode'] ?? '';
    final branch = accountData['branch'] ?? '';
    final mobile = accountData['mobile'] ?? '';

    final bankColor = _getBankColor(bankName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bankColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Account card visual
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bank logo placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.account_balance,
                          color: bankColor,
                          size: 28,
                        ),
                      ),
                    ),
                    // Three dots menu
                   
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  bankName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Savings Account',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  accountNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCOUNT HOLDER',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accountHolder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IFSC CODE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ifscCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Account details section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailItem(
                      icon: Icons.location_city,
                      label: 'Branch',
                      value: branch.isNotEmpty ? branch : 'N/A',
                    ),
                    _DetailItem(
                      icon: Icons.phone,
                      label: 'Mobile',
                      value: mobile.isNotEmpty ? mobile : 'N/A',
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}