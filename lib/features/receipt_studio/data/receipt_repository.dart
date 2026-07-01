import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt_models.dart';

class ReceiptStudioState {
  const ReceiptStudioState({
    required this.draft,
    required this.templates,
    required this.savedReceipts,
  });

  final ReceiptDraft draft;
  final List<PartyTemplate> templates;
  final List<SavedReceiptRecord> savedReceipts;
}

class ReceiptRepository {
  static const _templatesKey = 'party_templates';
  static const _draftKey = 'receipt_draft';
  static const _savedReceiptsKey = 'saved_receipts';

  Future<ReceiptStudioState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final templates = _readTemplates(preferences);
    final savedReceipts = _readSavedReceipts(preferences);
    final draftRaw = preferences.getString(_draftKey);
    final draft = draftRaw == null
        ? ReceiptDraft.initial()
        : ReceiptDraft.fromJson(jsonDecode(draftRaw) as Map<String, dynamic>);
    return ReceiptStudioState(
      draft: draft,
      templates: templates.isEmpty ? _seedTemplates() : templates,
      savedReceipts: savedReceipts,
    );
  }

  Future<void> saveDraft(ReceiptDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> saveTemplates(List<PartyTemplate> templates) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _templatesKey,
      templates.map((template) => jsonEncode(template.toJson())).toList(),
    );
  }

  Future<void> saveSavedReceipts(List<SavedReceiptRecord> savedReceipts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedReceiptsKey,
      savedReceipts.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> replaceWorkspace(WorkspaceBundle bundle) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_draftKey, jsonEncode(bundle.draft.toJson()));
    await preferences.setStringList(
      _templatesKey,
      bundle.templates.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await preferences.setStringList(
      _savedReceiptsKey,
      bundle.savedReceipts.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  List<PartyTemplate> _readTemplates(SharedPreferences preferences) {
    return (preferences.getStringList(_templatesKey) ?? [])
        .map(
          (item) =>
              PartyTemplate.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  List<SavedReceiptRecord> _readSavedReceipts(SharedPreferences preferences) {
    final items = (preferences.getStringList(_savedReceiptsKey) ?? [])
        .map(
          (item) => SavedReceiptRecord.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  List<PartyTemplate> _seedTemplates() {
    return const [
      PartyTemplate(
        id: 'payee-default',
        role: PartyRole.payee,
        name: 'Studio Atelier',
        contact: 'billing@studio-atelier.co',
        address: '88 Harbor Lane, San Francisco, CA',
        accountLabel: 'Receiving Account 4386',
        note: 'Primary design and consulting entity.',
      ),
      PartyTemplate(
        id: 'payer-default',
        role: PartyRole.payer,
        name: 'Northwind Ventures',
        contact: 'finance@northwind.vc',
        address: '21 Market Square, New York, NY',
        accountLabel: 'AP Ref NW-2026',
        note: 'Preferred payer template for investment clients.',
      ),
    ];
  }
}
