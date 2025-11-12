import 'dart:math';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';


class AddClientScreen extends StatefulWidget {
  final DocumentSnapshot? clientDoc;
  const AddClientScreen({super.key, this.clientDoc});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePicker = ImagePicker();
  final _uuid = const Uuid();
  late final Cloudinary _cloudinary;

  XFile? _panImageXFile;
  XFile? _aadhaarFrontXFile;
  XFile? _aadhaarBackXFile;

  String? _existingPanImageUrl;
  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;

  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _creditCards = [];

  bool _isLoading = false;

  @override
  void initState() {
    _cloudinary = Cloudinary.full(
      apiKey: "845752139265393",
      apiSecret: 'ux1r8z8tbYNqJ1hhnrlMCiIR43Y',
      cloudName: 'djyny0qqn',
    );

    super.initState();
    if (widget.clientDoc != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.clientDoc!.data() as Map<String, dynamic>;
    _existingPanImageUrl = data['panImageUrl'];

    final aadhaarImages = data['aadhaarImages'] as List<dynamic>?;
    if (aadhaarImages != null) {
      _existingAadhaarFrontUrl = aadhaarImages
          .firstWhere((img) => img['side'] == 'front', orElse: () => null)?['url'];
      _existingAadhaarBackUrl = aadhaarImages
          .firstWhere((img) => img['side'] == 'back', orElse: () => null)?['url'];
    }

    if (data['bankAccounts'] != null) {
      _bankAccounts = List<Map<String, dynamic>>.from(data['bankAccounts']);
    }
    if (data['creditCards'] != null) {
      _creditCards = List<Map<String, dynamic>>.from(data['creditCards']);
    }

    setState(() {});
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 70);
    return pickedFile;
  }

  void _showImagePicker(Function(XFile) onImageSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Photo Library'), onTap: () async {
              final file = await _pickImage(ImageSource.gallery);
              if (file != null) onImageSelected(file);
              Navigator.of(context).pop();
            }),
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () async {
              final file = await _pickImage(ImageSource.camera);
              if (file != null) onImageSelected(file);
              Navigator.of(context).pop();
            }),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadFile(XFile file, String publicId) async {
    final fileBytes = await file.readAsBytes();
    final response = await _cloudinary.uploadResource(
      CloudinaryUploadResource(fileBytes: fileBytes, resourceType: CloudinaryResourceType.image),
    );

    if (response.isSuccessful && response.secureUrl != null) {
      return response.secureUrl!;
    } else {
      throw Exception('Cloudinary upload failed: ${response.error}');
    }
  }

Future<String> _generateClientId() async {
  try {
    final clientsRef = FirebaseFirestore.instance.collection('clients');
    final querySnapshot = await clientsRef
        .orderBy('clientId', descending: true)
        .limit(1)
        .get();
    
    int nextNumber = 1;
    if (querySnapshot.docs.isNotEmpty) {
      final lastId = querySnapshot.docs.first.data()['clientId'] as String;
      final lastNumber = int.tryParse(lastId.replaceAll('CST-', '')) ?? 0;
      nextNumber = lastNumber + 1;
    }
    
    return 'CST-${nextNumber.toString().padLeft(2, '0')}';
  } catch (error) {
    debugPrint('Error generating client ID: $error');
    // Fallback to random 4-digit number if query fails
    return 'CST-${1000 + Random().nextInt(9000)}';
  }
}
Future<void> _submitForm() async {
  if (!_formKey.currentState!.saveAndValidate()) {
    Fluttertoast.showToast(msg: 'Please correct the highlighted fields');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final distributorId = context.read<AuthProvider>().distributorId;
    if (distributorId == null) throw Exception('Distributor ID not found');
    final formData = _formKey.currentState!.value;    
  final clientId = widget.clientDoc?.id ?? await _generateClientId();
    
    String? panImageUrl = _existingPanImageUrl;
    String? aadhaarFrontUrl = _existingAadhaarFrontUrl;
    String? aadhaarBackUrl = _existingAadhaarBackUrl;

    if (_panImageXFile != null) {
      panImageUrl = await _uploadFile(_panImageXFile!, '${clientId}_pan_${_uuid.v4()}');
    }
    if (_aadhaarFrontXFile != null) {
      aadhaarFrontUrl = await _uploadFile(_aadhaarFrontXFile!, '${clientId}_aadhaar_front_${_uuid.v4()}');
    }
    if (_aadhaarBackXFile != null) {
      aadhaarBackUrl = await _uploadFile(_aadhaarBackXFile!, '${clientId}_aadhaar_back_${_uuid.v4()}');
    }

    final Map<String, dynamic> clientData = {
      'name': formData['name'],
      'mobile': formData['mobile'],
      'email': formData['email'] ?? '',
      'address': formData['address'] ?? '',
      'panImageUrl': panImageUrl ?? '',
      'aadhaarImages': [
        if (aadhaarFrontUrl != null) {'side': 'front', 'url': aadhaarFrontUrl},
        if (aadhaarBackUrl != null) {'side': 'back', 'url': aadhaarBackUrl},
      ],
      'bankAccounts': _bankAccounts,
      'creditCards': _creditCards,
      'distributorId': distributorId,
    };

    final batch = FirebaseFirestore.instance.batch();
    final clientRef = FirebaseFirestore.instance.collection('clients').doc(clientId);

    if (widget.clientDoc != null) {
      batch.update(clientRef, clientData);
      
      final oldReminders = await FirebaseFirestore.instance
          .collection('reminders')
          .where('clientId', isEqualTo: clientId)
          .get();
      
      for (var doc in oldReminders.docs) {
        batch.delete(doc.reference);
      }
    } else {
      clientData['clientId'] = clientId;
      clientData['source'] = 'distributor_app';
      clientData['submittedAt'] = FieldValue.serverTimestamp();
      batch.set(clientRef, clientData);
    }

    final distributorDoc = await FirebaseFirestore.instance
        .collection('distributors')
        .doc(distributorId)
        .get();
    final distributorName = distributorDoc.data()?['name'] ?? 'Unknown Distributor';

    for (int i = 0; i < _creditCards.length; i++) {
      final card = _creditCards[i];
      
      final reminderData = {
        'clientId': clientId,
        'clientName': formData['name'],
        'clientMobile': formData['mobile'],
        'distributorId': distributorId,
        'distributorName': distributorName,
        'cardIndex': i,
        'bankName': card['bankName'] ?? '',
        'cardHolderName': card['cardHolderName'] ?? '',
        'cardHolderMobile': card['cardHolderMobile'] ?? '',
        'cardnumber': card['cardNumber'] ?? '',
        'billGenerationDate': int.tryParse(card['billGenerationDate']?.toString() ?? '0') ?? 0,
        'cardDueDate': int.tryParse(card['cardDueDate']?.toString() ?? '0') ?? 0,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final reminderRef = FirebaseFirestore.instance.collection('reminders').doc();
      batch.set(reminderRef, reminderData);
    }

    // Commit all changes atomically
    await batch.commit();

    Fluttertoast.showToast(
      msg: widget.clientDoc != null 
          ? 'Client updated successfully' 
          : 'Client created successfully with ${_creditCards.length} reminders',
      backgroundColor: Colors.green,
    );

    if (mounted) Navigator.of(context).pop();
  } catch (e) {
    Fluttertoast.showToast(
      msg: 'Error: ${e.toString()}',
      backgroundColor: Colors.red,
      toastLength: Toast.LENGTH_LONG,
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.clientDoc != null;
    final initialData = isEditMode ? widget.clientDoc!.data() as Map<String, dynamic> : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Client' : 'Add New Client'),
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.save_rounded), onPressed: _submitForm, tooltip: 'Save Client'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FormBuilder(
              key: _formKey,
              initialValue: initialData,
              child: ListView(padding: const EdgeInsets.all(16.0), children: [
                SectionCard(title: 'Personal Information', child: _buildPersonalFields()),
                const SizedBox(height: 16),
                SectionCard(title: 'Documents', child: _buildDocumentsSection()),
                const SizedBox(height: 16),
                SectionCard(title: 'Bank Accounts', child: _buildBankAccountsEditor(context)),
                const SizedBox(height: 16),
                SectionCard(title: 'Credit Cards', child: _buildCreditCardsEditor(context)),
                const SizedBox(height: 24),
                ElevatedButton.icon(onPressed: _submitForm, icon: const Icon(Icons.save), label: const Text('Save')),
                const SizedBox(height: 40),
              ]),
            ),
    );
  }

  // ---------------- UI pieces ----------------
  Widget _buildPersonalFields() {
    return Column(children: [
      FormBuilderTextField(name: 'name', decoration: const InputDecoration(labelText: 'Full Name'), validator: FormBuilderValidators.compose([FormBuilderValidators.required()])),
      const SizedBox(height: 12),
      FormBuilderTextField(name: 'mobile', decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone, validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(),
        FormBuilderValidators.numeric(),
        FormBuilderValidators.minLength(10),
        FormBuilderValidators.maxLength(10),
      ])),
      const SizedBox(height: 12),
      FormBuilderTextField(name: 'email', decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: FormBuilderValidators.email()),
      const SizedBox(height: 12),
      FormBuilderTextField(name: 'address', decoration: const InputDecoration(labelText: 'Address (Optional)'), maxLines: 3),
    ]);
  }

  Widget _buildDocumentsSection() {
    return Column(children: [
      _buildImagePicker(context: context, label: 'PAN Card', imageXFile: _panImageXFile, existingUrl: _existingPanImageUrl, onTap: () => _showImagePicker((file) => setState(() => _panImageXFile = file))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildImagePicker(context: context, label: 'Aadhaar Front', imageXFile: _aadhaarFrontXFile, existingUrl: _existingAadhaarFrontUrl, onTap: () => _showImagePicker((file) => setState(() => _aadhaarFrontXFile = file)))),
        const SizedBox(width: 12),
        Expanded(child: _buildImagePicker(context: context, label: 'Aadhaar Back', imageXFile: _aadhaarBackXFile, existingUrl: _existingAadhaarBackUrl, onTap: () => _showImagePicker((file) => setState(() => _aadhaarBackXFile = file))))
      ])
    ]);
  }

  Widget _buildImagePicker({required BuildContext context, required String label, XFile? imageXFile, String? existingUrl, required VoidCallback onTap}) {
    Widget imageWidget;
    if (imageXFile != null) {
      imageWidget = Image.network(imageXFile.path, fit: BoxFit.cover, errorBuilder: (context, error, stack) => const Icon(Icons.error, color: Colors.red));
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      imageWidget = Image.network(existingUrl, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stack) => const Icon(Icons.error, color: Colors.red));
    } else {
      imageWidget = const Icon(Icons.add_a_photo, size: 40, color: Colors.grey);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Stack(alignment: Alignment.center, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: double.infinity, height: double.infinity, child: imageWidget)),
          Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))), child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)))),
        ]),
      ),
    );
  }

  // ---------------- Bank Accounts Editor ----------------
  Widget _buildBankAccountsEditor(BuildContext context) {
    return Column(children: [
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _showBankAccountDialog(context), icon: const Icon(Icons.add_circle), label: const Text('Add Bank'))),
      const SizedBox(height: 8),
      if (_bankAccounts.isEmpty) const Text('No bank accounts added.'),
      ..._bankAccounts.asMap().entries.map((e) {
        final idx = e.key;
        final acc = e.value;
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(acc['bankName'] ?? 'Unknown Bank'), subtitle: Text(acc['accountNumber'] ?? ''), trailing: Wrap(spacing: 8, children: [IconButton(icon: const Icon(Icons.edit), onPressed: () => _showBankAccountDialog(context, index: idx)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _bankAccounts.removeAt(idx)))])));
      }).toList()
    ]);
  }

  void _showBankAccountDialog(BuildContext context, {int? index}) {
    final isEditing = index != null;
    final formKey = GlobalKey<FormBuilderState>();
    final initial = isEditing ? _bankAccounts[index!] : <String, dynamic>{};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Bank Account' : 'Add Bank Account'),
          content: FormBuilder(key: formKey, initialValue: initial, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            FormBuilderTextField(name: 'accountHolderName', decoration: const InputDecoration(labelText: 'Account Holder Name'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'accountNumber', decoration: const InputDecoration(labelText: 'Account Number'), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.minLength(6), FormBuilderValidators.maxLength(24)])),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'bankName', decoration: const InputDecoration(labelText: 'Bank Name'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 8),
FormBuilderTextField(
  name: 'ifscCode',
  decoration: const InputDecoration(labelText: 'IFSC Code'),
  validator: FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'IFSC Code is required'),
    FormBuilderValidators.match(
      RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$'),
      errorText: 'Invalid IFSC format',
    ),
  ]),
),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'branch', decoration: const InputDecoration(labelText: 'Branch (Optional)')),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'mobile', decoration: const InputDecoration(labelText: 'Registered Mobile'), keyboardType: TextInputType.phone, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.minLength(10), FormBuilderValidators.maxLength(10)])),
            const SizedBox(height: 8),
          
          ]))),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () {
            if (formKey.currentState!.saveAndValidate()) {
              final val = Map<String, dynamic>.from(formKey.currentState!.value);
              // Ensure numeric conversion
              val['withdrawalRatePercent'] = num.tryParse(val['withdrawalRatePercent']?.toString() ?? '0') ?? 0;
              val['billPaymentRatePercent'] = num.tryParse(val['billPaymentRatePercent']?.toString() ?? '0') ?? 0;
              setState(() {
                if (isEditing) _bankAccounts[index!] = val; else _bankAccounts.add(val);
              });
              Navigator.of(dialogContext).pop();
            }
          }, child: const Text('Save'))],
        );
      },
    );
  }

  // ---------------- Credit Cards Editor ----------------
  Widget _buildCreditCardsEditor(BuildContext context) {
    return Column(children: [
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _showCreditCardDialog(context), icon: const Icon(Icons.add_circle), label: const Text('Add Card'))),
      const SizedBox(height: 8),
      if (_creditCards.isEmpty) const Text('No credit cards added.'),
      ..._creditCards.asMap().entries.map((e) {
        final idx = e.key;
        final c = e.value;
        final last4 = ((c['cardNumber'] as String?)?.length ?? 0) > 4 ? (c['cardNumber'] as String).substring((c['cardNumber'] as String).length - 4) : '****';
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(c['bankName'] ?? 'Unknown Bank'), subtitle: Text('... $last4'), trailing: Wrap(spacing: 8, children: [IconButton(icon: const Icon(Icons.edit), onPressed: () => _showCreditCardDialog(context, index: idx)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _creditCards.removeAt(idx)))])));
      }).toList()
    ]);
  }

  void _showCreditCardDialog(BuildContext context, {int? index}) {
    final isEditing = index != null;
    final formKey = GlobalKey<FormBuilderState>();
final initial = isEditing 
    ? Map<String, dynamic>.from(_creditCards[index!]).map((key, value) {
        // Convert numeric fields to strings
        if (value is num && (key == 'withdrawalRatePercent' || 
            key == 'billPaymentRatePercent' || 
            key == 'cardLimit' ||
            key == 'billGenerationDate' ||
            key == 'cardDueDate')) {
          return MapEntry(key, value.toString());
        }
        return MapEntry(key, value);
      })
    : <String, dynamic>{};
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Card' : 'Add Credit Card'),
          content: FormBuilder(key: formKey, initialValue: initial, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            FormBuilderTextField(name: 'cardNumber', decoration: const InputDecoration(labelText: 'Card Number (16 digits)'), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.minLength(16), FormBuilderValidators.maxLength(16)])),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: FormBuilderTextField(name: 'expiryDate', decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'), ),),
 const SizedBox(width: 12),
  Expanded(child: FormBuilderTextField(name: 'cvv', decoration: const InputDecoration(labelText: 'CVV'), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.minLength(3), FormBuilderValidators.maxLength(4)]
  ))
  )
  ]),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'cardHolderName', decoration: const InputDecoration(labelText: 'Cardholder Name'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'bankName', decoration: const InputDecoration(labelText: 'Bank Name'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'cardLimit', decoration: const InputDecoration(labelText: 'Card Limit (₹)'), keyboardType: TextInputType.number, valueTransformer: (val) => num.tryParse(val ?? '0') ?? 0),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'cardType', decoration: const InputDecoration(labelText: 'Card Type (e.g., Visa)'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'cardHolderMobile', decoration: const InputDecoration(labelText: 'Card Mobile'), keyboardType: TextInputType.phone, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.minLength(10), FormBuilderValidators.maxLength(10)])),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: FormBuilderTextField(name: 'billGenerationDate', decoration: const InputDecoration(labelText: 'Bill Date (BD)'), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.min(1), FormBuilderValidators.max(31)]))),
             const SizedBox(width: 12), Expanded(child: FormBuilderTextField(name: 'cardDueDate', decoration: const InputDecoration(labelText: 'Due Date (DD)'), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.min(1), FormBuilderValidators.max(31)])))]),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'withdrawalRatePercent', decoration: const InputDecoration(labelText: 'Withdrawal Rate (%)'), keyboardType: TextInputType.number, initialValue: (initial['withdrawalRatePercent']?.toString()), validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.min(0), FormBuilderValidators.max(100)])),
            const SizedBox(height: 8),
            FormBuilderTextField(name: 'billPaymentRatePercent', decoration: const InputDecoration(labelText: 'Bill Payment Rate (%)'), keyboardType: TextInputType.number, initialValue: (initial['billPaymentRatePercent']?.toString()), validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric(), FormBuilderValidators.min(0), FormBuilderValidators.max(100)])),
          ]))),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () {
            if (formKey.currentState!.saveAndValidate()) {
              final val = Map<String, dynamic>.from(formKey.currentState!.value);
              val['cardLimit'] = num.tryParse(val['cardLimit']?.toString() ?? '0') ?? 0;
              val['withdrawalRatePercent'] = num.tryParse(val['withdrawalRatePercent']?.toString() ?? '0') ?? 0;
              val['billPaymentRatePercent'] = num.tryParse(val['billPaymentRatePercent']?.toString() ?? '0') ?? 0;
              setState(() {
                if (isEditing) _creditCards[index!] = val; else _creditCards.add(val);
              });
              Navigator.of(dialogContext).pop();
            }
          }, child: const Text('Save'))],
        );
      },
    );
  }
}




// ----------------- Small Reusable Widgets -----------------
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
