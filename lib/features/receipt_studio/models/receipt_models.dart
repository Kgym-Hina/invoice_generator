import 'dart:convert';

import 'package:intl/intl.dart';

enum PartyRole { payee, payer }

enum SupportedCurrency {
  cny('CNY', '¥', 'Chinese Yuan'),
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro'),
  gbp('GBP', '£', 'Pound Sterling'),
  jpy('JPY', '¥', 'Japanese Yen'),
  hkd('HKD', 'HK\$', 'Hong Kong Dollar'),
  sgd('SGD', 'S\$', 'Singapore Dollar');

  const SupportedCurrency(this.code, this.symbol, this.label);

  final String code;
  final String symbol;
  final String label;

  static SupportedCurrency fromCode(String code) {
    return SupportedCurrency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => SupportedCurrency.usd,
    );
  }
}

class PartyTemplate {
  const PartyTemplate({
    required this.id,
    required this.role,
    required this.name,
    required this.contact,
    required this.address,
    required this.accountLabel,
    required this.note,
  });

  final String id;
  final PartyRole role;
  final String name;
  final String contact;
  final String address;
  final String accountLabel;
  final String note;

  PartyTemplate copyWith({
    String? id,
    PartyRole? role,
    String? name,
    String? contact,
    String? address,
    String? accountLabel,
    String? note,
  }) {
    return PartyTemplate(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      accountLabel: accountLabel ?? this.accountLabel,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'name': name,
      'contact': contact,
      'address': address,
      'accountLabel': accountLabel,
      'note': note,
    };
  }

  static PartyTemplate fromJson(Map<String, dynamic> json) {
    return PartyTemplate(
      id: json['id'] as String? ?? '',
      role: PartyRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => PartyRole.payee,
      ),
      name: json['name'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      address: json['address'] as String? ?? '',
      accountLabel: json['accountLabel'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class ReceiptDraft {
  const ReceiptDraft({
    required this.receiptNumber,
    required this.issueDate,
    required this.currencyCode,
    required this.payee,
    required this.payer,
    required this.title,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.note,
  });

  final String receiptNumber;
  final DateTime issueDate;
  final String currencyCode;
  final PartyTemplate payee;
  final PartyTemplate payer;
  final String title;
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final String note;

  factory ReceiptDraft.initial() {
    return ReceiptDraft(
      receiptNumber: defaultReceiptNumber(),
      issueDate: DateTime.now(),
      currencyCode: SupportedCurrency.usd.code,
      payee: const PartyTemplate(
        id: '',
        role: PartyRole.payee,
        name: 'Studio Atelier',
        contact: 'billing@studio-atelier.co',
        address: '88 Harbor Lane, San Francisco, CA',
        accountLabel: 'Receiving Account 4386',
        note: 'Thank you for your trust and continued business.',
      ),
      payer: const PartyTemplate(
        id: '',
        role: PartyRole.payer,
        name: 'Northwind Ventures',
        contact: 'finance@northwind.vc',
        address: '21 Market Square, New York, NY',
        accountLabel: 'AP Ref NW-2026',
        note: '',
      ),
      title: 'Design retainer and production support',
      description:
          'Monthly design retainer covering concept development, delivery support, and revisions.',
      quantity: 1,
      unitPrice: 1800,
      taxRate: 0,
      note:
          'Payment due within 7 days. This receipt is system-generated and consistent across devices.',
    );
  }

  ReceiptDraft copyWith({
    String? receiptNumber,
    DateTime? issueDate,
    String? currencyCode,
    PartyTemplate? payee,
    PartyTemplate? payer,
    String? title,
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    String? note,
  }) {
    return ReceiptDraft(
      receiptNumber: receiptNumber ?? this.receiptNumber,
      issueDate: issueDate ?? this.issueDate,
      currencyCode: currencyCode ?? this.currencyCode,
      payee: payee ?? this.payee,
      payer: payer ?? this.payer,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      note: note ?? this.note,
    );
  }

  ReceiptDraft duplicateAsNew() {
    return copyWith(
      receiptNumber: defaultReceiptNumber(),
      issueDate: DateTime.now(),
    );
  }

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'receiptNumber': receiptNumber,
      'issueDate': issueDate.toIso8601String(),
      'currencyCode': currencyCode,
      'payee': payee.toJson(),
      'payer': payer.toJson(),
      'title': title,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'note': note,
    };
  }

  static ReceiptDraft fromJson(Map<String, dynamic> json) {
    return ReceiptDraft(
      receiptNumber: json['receiptNumber'] as String? ?? defaultReceiptNumber(),
      issueDate:
          DateTime.tryParse(json['issueDate'] as String? ?? '') ??
          DateTime.now(),
      currencyCode:
          json['currencyCode'] as String? ?? SupportedCurrency.usd.code,
      payee: PartyTemplate.fromJson(json['payee'] as Map<String, dynamic>),
      payer: PartyTemplate.fromJson(json['payer'] as Map<String, dynamic>),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
    );
  }
}

class SavedReceiptRecord {
  const SavedReceiptRecord({
    required this.id,
    required this.savedAt,
    required this.updatedAt,
    required this.exportPath,
    required this.draft,
  });

  final String id;
  final DateTime savedAt;
  final DateTime updatedAt;
  final String exportPath;
  final ReceiptDraft draft;

  SavedReceiptRecord copyWith({
    String? id,
    DateTime? savedAt,
    DateTime? updatedAt,
    String? exportPath,
    ReceiptDraft? draft,
  }) {
    return SavedReceiptRecord(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exportPath: exportPath ?? this.exportPath,
      draft: draft ?? this.draft,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'savedAt': savedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'exportPath': exportPath,
      'draft': draft.toJson(),
    };
  }

  static SavedReceiptRecord fromJson(Map<String, dynamic> json) {
    return SavedReceiptRecord(
      id: json['id'] as String? ?? '',
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      exportPath: json['exportPath'] as String? ?? '',
      draft: ReceiptDraft.fromJson(json['draft'] as Map<String, dynamic>),
    );
  }
}

class WorkspaceBundle {
  const WorkspaceBundle({
    required this.exportedAt,
    required this.draft,
    required this.templates,
    required this.savedReceipts,
  });

  final DateTime exportedAt;
  final ReceiptDraft draft;
  final List<PartyTemplate> templates;
  final List<SavedReceiptRecord> savedReceipts;

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'exportedAt': exportedAt.toIso8601String(),
      'draft': draft.toJson(),
      'templates': templates.map((item) => item.toJson()).toList(),
      'savedReceipts': savedReceipts.map((item) => item.toJson()).toList(),
    };
  }

  static WorkspaceBundle fromJson(Map<String, dynamic> json) {
    return WorkspaceBundle(
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      draft: ReceiptDraft.fromJson(json['draft'] as Map<String, dynamic>),
      templates: ((json['templates'] as List<dynamic>? ?? const []))
          .map((item) => PartyTemplate.fromJson(item as Map<String, dynamic>))
          .toList(),
      savedReceipts: ((json['savedReceipts'] as List<dynamic>? ?? const []))
          .map(
            (item) => SavedReceiptRecord.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

double parseNumber(String value, {double fallback = 0}) {
  return double.tryParse(value.trim()) ?? fallback;
}

String displayNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String defaultReceiptNumber() {
  final now = DateTime.now();
  return 'RC-${DateFormat('yyyyMMdd-HHmm').format(now)}';
}

String encodeJson(Map<String, dynamic> json) => jsonEncode(json);
