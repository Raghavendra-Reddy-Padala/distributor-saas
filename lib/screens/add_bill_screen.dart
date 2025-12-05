import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:priyanakaenterprises/uitls/formatcard.dart';
import 'package:priyanakaenterprises/widgets/copytext.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AddBillScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final Map<String, dynamic> clientData;
  final Map<String, dynamic> selectedCard;
  final int cardIndex;

  const AddBillScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.clientData,
    required this.selectedCard,
    required this.cardIndex,
  });

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  bool _isLoading = false;

  List<TextEditingController> billPaymentControllers = [];
  List<TextEditingController> withdrawalControllers = [];
  final TextEditingController baseBillPaymentController = TextEditingController();
  final TextEditingController baseWithdrawalController = TextEditingController();

  String selectedGateway = 'plg';
  final double gatewayRate = 1.9;
  double clientRate = 2.3;

  final List<Map<String, dynamic>> gateways = [
    {'name': 'PLG', 'value': 'plg'},
    {'name': 'SLG', 'value': 'slg'},
    {'name': 'PAY', 'value': 'pay'},
    {'name': 'NTER', 'value': 'nter'},
  ];

  @override
  void initState() {
    super.initState();
    baseBillPaymentController.addListener(_recalculate);
    baseWithdrawalController.addListener(_recalculate);
    
    for (int i = 0; i < 5; i++) {
      billPaymentControllers.add(TextEditingController());
      withdrawalControllers.add(TextEditingController());
    }
    for (var controller in billPaymentControllers) {
      controller.addListener(_recalculate);
    }
    for (var controller in withdrawalControllers) {
      controller.addListener(_recalculate);
    }
  }

  @override
  void dispose() {
    baseBillPaymentController.dispose();
    baseWithdrawalController.dispose();
    for (var controller in billPaymentControllers) {
      controller.dispose();
    }
    for (var controller in withdrawalControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _recalculate() {
    setState(() {});
  }

  double get baseBillPayment => double.tryParse(baseBillPaymentController.text) ?? 0.0;
  double get baseWithdrawal => double.tryParse(baseWithdrawalController.text) ?? 0.0;

  double get totalBillPayment {
    return billPaymentControllers.fold(0.0, (sum, controller) {
      return sum + (double.tryParse(controller.text) ?? 0.0);
    });
  }

  double get totalWithdrawal {
    return withdrawalControllers.fold(0.0, (sum, controller) {
      return sum + (double.tryParse(controller.text) ?? 0.0);
    });
  }

  double get balance => totalBillPayment - totalWithdrawal;
  double get profitMargin => clientRate - gatewayRate;
  double get balanceBillPayment => baseBillPayment - totalBillPayment;
  double get balanceWithdrawal => baseWithdrawal - totalWithdrawal;
  double get interestAmount => baseBillPayment * (clientRate / 100);
  double get finalAmountForClient => baseBillPayment + interestAmount;

  void _addRow() {
    setState(() {
      final billController = TextEditingController();
      final withdrawalController = TextEditingController();
      billController.addListener(_recalculate);
      withdrawalController.addListener(_recalculate);
      billPaymentControllers.add(billController);
      withdrawalControllers.add(withdrawalController);
    });
  }

  void _removeRow(int index) {
    if (billPaymentControllers.length > 1) {
      setState(() {
        billPaymentControllers[index].dispose();
        withdrawalControllers[index].dispose();
        billPaymentControllers.removeAt(index);
        withdrawalControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveBill() async {
    if (baseBillPayment == 0) {
toastification.show(
  context: context,
  type: ToastificationType.error, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('please enter some amount to save the bill.'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);      return;
    }

    setState(() => _isLoading = true);

    try {
      final distributorId = context.read<AuthProvider>().distributorId;
      if (distributorId == null) {
        throw Exception('Distributor ID not found.');
      }

      final billPayments = billPaymentControllers
          .map((c) => double.tryParse(c.text) ?? 0.0)
          .where((v) => v > 0)
          .toList();

      final withdrawals = withdrawalControllers
          .map((c) => double.tryParse(c.text) ?? 0.0)
          .where((v) => v > 0)
          .toList();

      final billData = {
        'clientId': widget.clientId,
        'clientName': widget.clientName,
        'distributorId': distributorId,
        'selectedCard': widget.selectedCard,
        'baseBillPayment': baseBillPayment,
        'baseWithdrawal': baseWithdrawal,
        'billPayments': billPayments,
        'withdrawals': withdrawals,
        'totalBillPayment': totalBillPayment,
        'totalWithdrawal': totalWithdrawal,
        'balanceBillPayment': balanceBillPayment,
        'balanceWithdrawal': balanceWithdrawal,
        'selectedGateway': selectedGateway,
        'gatewayRate': gatewayRate,
        'clientRate': clientRate,
        'profitMargin': profitMargin,
        'interestAmount': interestAmount,
        'finalAmountForClient': finalAmountForClient,
        'status': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bills').add(billData);

     toastification.show(
  context: context,
  type: ToastificationType.success, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('Bill saved successfully!'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Fluttertoast.showToast(
      //   msg: 'Error: ${e.toString()}',
      //   backgroundColor: Colors.red,
      // );
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<Uint8List> _generatePdfInvoice() async {
  final pdf = pw.Document();
  
  final formatCurrency = (double amount) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  ).format(amount);

  // Load fonts
  final font = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  pw.ImageProvider? qrImage;
  try {
    // Load QR code and logo images
    final ByteData qrData = await rootBundle.load('assets/qr.jpg');
    final Uint8List qrBytes = qrData.buffer.asUint8List();
    qrImage = pw.MemoryImage(qrBytes);
  } catch (e) {
    print('QR not found: $e');
  }
  
  pw.ImageProvider? logoImage;
  try {
    final ByteData logoData = await rootBundle.load('assets/logo.jpg');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    logoImage = pw.MemoryImage(logoBytes);
  } catch (e) {
    print('Logo not found: $e');
  }

  // Get non-zero transactions
  final billPayments = <Map<String, dynamic>>[];
  final withdrawals = <Map<String, dynamic>>[];
  
  for (int i = 0; i < billPaymentControllers.length; i++) {
    final billAmount = double.tryParse(billPaymentControllers[i].text) ?? 0.0;
    final withdrawalAmount = double.tryParse(withdrawalControllers[i].text) ?? 0.0;
    
    if (billAmount > 0 || withdrawalAmount > 0) {
      billPayments.add({
        'index': i + 2,
        'amount': billAmount,
      });
      withdrawals.add({
        'index': i + 2,
        'amount': withdrawalAmount,
      });
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          // Header with Logo
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 50,
                        width: 150,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          
          // Client & Card Info Section
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColors.grey100,
                  PdfColors.white,
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColors.grey600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        widget.clientName,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        widget.clientData['mobile'] ?? '',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex('#667eea'),
                        PdfColor.fromHex('#764ba2'),
                      ],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                    borderRadius: pw.BorderRadius.circular(12),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColor.fromHex('#667eea').shade(0.4),
                        blurRadius: 15,
                        offset: const PdfPoint(0, 5),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        widget.selectedCard['bankName']?.toString().toUpperCase() ?? 'BANK',
                        style: pw.TextStyle(
                          font: fontBold,
                          color: PdfColors.white,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        '**** **** **** ${widget.selectedCard['cardNumber']?.toString().substring(widget.selectedCard['cardNumber'].toString().length - 4) ?? '****'}',
                        style: pw.TextStyle(
                          font: fontBold,
                          color: PdfColors.white,
                          fontSize: 16,
                          letterSpacing: 2.0,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        widget.selectedCard['cardHolderName']?.toString().toUpperCase() ?? 'CARD HOLDER',
                        style: pw.TextStyle(
                          font: font,
                          color: PdfColors.white,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Transactions Section Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#667eea').shade(0.1),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              'TRANSACTION DETAILS',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#667eea'),
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // Transactions Table
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(8),
                bottomRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Column(
              children: [
                // Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          'TYPE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.grey800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'BILL PAYMENT',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'WITHDRAWAL',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Base Amount Row
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E0F7FA'),
                    border: const pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          'Base Amount',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          formatCurrency(baseBillPayment),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          formatCurrency(baseWithdrawal),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Split Transactions
                ...List.generate(
                  billPayments.length,
                  (index) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: pw.BoxDecoration(
                      color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                      border: const pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey200),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 80,
                          child: pw.Text(
                            'Split ${index + 1}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            billPayments[index]['amount'] > 0 
                                ? formatCurrency(billPayments[index]['amount'])
                                : '-',
                            style: pw.TextStyle(
                              font: billPayments[index]['amount'] > 0 ? fontBold : font,
                              fontSize: 11,
                              color: billPayments[index]['amount'] > 0 
                                  ? PdfColors.black 
                                  : PdfColors.grey400,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            withdrawals[index]['amount'] > 0 
                                ? formatCurrency(withdrawals[index]['amount'])
                                : '-',
                            style: pw.TextStyle(
                              font: withdrawals[index]['amount'] > 0 ? fontBold : font,
                              fontSize: 11,
                              color: withdrawals[index]['amount'] > 0 
                                  ? PdfColors.black 
                                  : PdfColors.grey400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Total Row
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColors.orange50,
                        PdfColors.orange100,
                      ],
                    ),
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(8),
                      bottomRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(width: 80),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'TOTAL: ',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Text(
                              formatCurrency(totalBillPayment),
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.orange900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'TOTAL: ',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Text(
                              formatCurrency(totalWithdrawal),
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.orange900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Bill Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColors.grey50,
                  PdfColors.white,
                ],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL SUMMARY',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#667eea'),
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 16),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Your Amount',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      formatCurrency(baseBillPayment),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Service Charge (${clientRate.toStringAsFixed(2)}%)',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      formatCurrency(interestAmount),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 2, color: PdfColors.grey400),
                pw.SizedBox(height: 16),
                
                pw.Container(
              
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL AMOUNT TO PAY',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text(
                        formatCurrency(interestAmount),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#667eea'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Payment QR Code Section
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYMENT INSTRUCTIONS',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#667eea'),
                          letterSpacing: 1.0,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        '• Scan the QR code to make instant payment',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '• Payment should be made within 48 hours',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '• Keep the transaction ID for reference',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '• Contact us for any payment queries',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#667eea'),
                      width: 3,
                    ),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColor.fromHex('#667eea').shade(0.2),
                        blurRadius: 10,
                        offset: const PdfPoint(0, 4),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      if(qrImage != null)
                        pw.Container(
                          height: 120,
                          width: 120,
                          child: pw.Image(qrImage, fit: pw.BoxFit.contain),
                        ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Scan to Pay',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColor.fromHex('#667eea'),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Footer
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 2),
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: PdfColor.fromHex('#667eea'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'For any queries, please contact our support team',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    ),
  );

  return pdf.save();
} 
 Future<void> _generateAndShareInvoice() async {
  if (totalBillPayment == 0 && baseBillPayment == 0) {
toastification.show(
  context: context,
  type: ToastificationType.error, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('Please enter some amount to generate invoice.'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);    return;
  }

  setState(() => _isLoading = true);

  try {
    // Generate PDF
    final pdfBytes = await _generatePdfInvoice();
    
    final clientMobile = widget.clientData['mobile']?.toString() ?? '';
    final formattedAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 2,
    ).format(interestAmount);

    final plainMessage = 'Hi ${widget.clientName},\n\nYour payment invoice is ready.\nAmount to Pay: $formattedAmount\n\nPlease find the invoice attached.';

    // For mobile: Share PDF directly
    if (clientMobile.isNotEmpty) {
      final message = Uri.encodeComponent(plainMessage);
      final whatsappUrl = 'https://wa.me/91$clientMobile?text=$message';
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
    
    // Share PDF using printing package (works on both mobile and web)
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'invoice_${widget.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
   toastification.show(
  type: ToastificationType.success, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('invoice generated successfully!'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);
  } catch (e, st) {
   toastification.show(
  context: context,
  type: ToastificationType.error, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('Error: ${e.toString()}'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveBill,
            tooltip: 'Save Bill',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientInfoCard(),
                  const SizedBox(height: 16),
                  _buildCardDetailsCard(),
                  const SizedBox(height: 16),
                  _buildTransactionsCard(),
                  const SizedBox(height: 16),
                  _buildGatewayCard(),
                  const SizedBox(height: 16),
                  _buildCalculationsCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildClientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.clientName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.clientData['mobile'] ?? 'No mobile',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildCardDetailsCard() {
  final card = widget.selectedCard;
  final cardNumber = card['cardNumber'] ?? '';
  final paymentHistory = card['paymentHistory'] as List<dynamic>? ?? [];
  
  // Get most recent payment
  Map<String, dynamic>? recentPayment;
  if (paymentHistory.isNotEmpty) {
    recentPayment = paymentHistory.last as Map<String, dynamic>;
  }

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Card',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card['cardType'] ?? 'Credit Card',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bank Name
          CopyableText(
          text:   card['bankName'] ?? 'Unknown Bank',
          style:   const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Card Number
          CopyableText(
         text:CardFormatters.formatNumber( cardNumber ,),
          style:   const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card Holder & Limit Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                   text:    card['cardHolderName'] ?? 'N/A',
                    style:   const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'LIMIT',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  CopyableText(
                  text:   NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 0,
                    ).format(card['cardLimit'] ?? 0),
                 style:    const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Expiry, CVV, Mobile & Due Date Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VALID THRU',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                  text:     card['expiryDate'] ?? 'N/A',
                  style:     const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CVV',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                    text:   card['cvv'] ?? 'N/A',
                  style:     const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DUE DATE',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                   text:    card['cardDueDate'] ?? 'N/A',
                    style:   const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'MOBILE',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                    text:   card['cardHolderMobile'] ?? 'N/A',
                    style:   const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (recentPayment != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white30, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAST PAYMENT',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                    text:   '${recentPayment['month']} ${recentPayment['year']}',
                    style:   const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    CopyableText(
                     text:  NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ).format(recentPayment['amount'] ?? 0),
                     style:  const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}






 Widget _buildTransactionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addRow,
                  tooltip: 'Add Row',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            'Bill Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Withdrawal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  
                  // Row 8: Base Amount (highlighted in cyan like Excel)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.3), // Cyan like Excel
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            'R0',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: baseBillPaymentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              hintText: 'Base Amount',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: baseWithdrawalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              hintText: 'Base Amount',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  
                  // Row 9: Balance (Base - Total) - Formula result
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                      
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Bal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_IN',
                                    symbol: '₹',
                                    decimalDigits: 0,
                                  ).format(balanceBillPayment),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: balanceBillPayment >= 0 ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Bal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_IN',
                                    symbol: '₹',
                                    decimalDigits: 0,
                                  ).format(balanceWithdrawal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: balanceWithdrawal >= 0 ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  
                  // Rows 10-21: Transaction Rows
                  ...List.generate(
                    billPaymentControllers.length,
                    (index) => _buildTransactionRow(index),
                  ),
                  
                  // Row 22: Total (Sum of all transactions)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_IN',
                                    symbol: '₹',
                                    decimalDigits: 0,
                                  ).format(totalBillPayment),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_IN',
                                    symbol: '₹',
                                    decimalDigits: 0,
                                  ).format(totalWithdrawal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
   Widget _buildTransactionRow(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'R${2 + index}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            child: TextField(
              controller: billPaymentControllers[index],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: withdrawalControllers[index],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _removeRow(index),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildGatewayCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gateway & Charges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGateway,
              decoration: const InputDecoration(
                labelText: 'Select Gateway',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              items: gateways.map((gateway) {
                return DropdownMenuItem<String>(
                  value: gateway['value'],
                  child: Text(gateway['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGateway = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: gatewayRate.toString(),
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Gateway Rate (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: clientRate.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Client Rate (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    onChanged: (value) {
                      setState(() {
                        clientRate = double.tryParse(value) ?? 2.3;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Profit Margin:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${profitMargin.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  
   Widget _buildCalculationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Base Amount',
              NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 2,
              ).format(baseBillPayment),
              false,
            ),
            const Divider(),
            _buildSummaryRow(
              'Service Charge (${clientRate.toStringAsFixed(2)}%)',
              NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 2,
              ).format(interestAmount),
              false,
            ),
            const Divider(thickness: 2),
            _buildSummaryRow(
              'Total Amount for Client',
              NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 2,
              ).format(finalAmountForClient),
              true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Gateway Cost',
                    '${(baseBillPayment * gatewayRate / 100).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Your Profit',
                    '${(baseBillPayment * profitMargin / 100).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 20 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '₹$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateAndShareInvoice,
            icon: const Icon(Icons.share),
            label: const Text(
              'Generate & Share Invoice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _saveBill,
            icon: const Icon(Icons.save),
            label: const Text(
              'Save Bill',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
