import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app.dart';
import '../data/receipt_repository.dart';
import '../models/receipt_models.dart';
import '../services/receipt_pdf_service.dart';

class ReceiptStudioPage extends StatefulWidget {
  const ReceiptStudioPage({super.key, required this.section});

  final AppSection section;

  @override
  State<ReceiptStudioPage> createState() => _ReceiptStudioPageState();
}

class _ReceiptStudioPageState extends State<ReceiptStudioPage> {
  final _repository = ReceiptRepository();
  final _pdfService = ReceiptPdfService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _receiptNumberController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _noteController;

  late final TextEditingController _payeeNameController;
  late final TextEditingController _payeeContactController;
  late final TextEditingController _payeeAddressController;
  late final TextEditingController _payeeAccountController;
  late final TextEditingController _payeeNoteController;

  late final TextEditingController _payerNameController;
  late final TextEditingController _payerContactController;
  late final TextEditingController _payerAddressController;
  late final TextEditingController _payerAccountController;
  late final TextEditingController _payerNoteController;

  ReceiptDraft _draft = ReceiptDraft.initial();
  List<PartyTemplate> _templates = const [];
  List<SavedReceiptRecord> _savedReceipts = const [];
  bool _loading = true;
  bool _busy = false;
  String? _activeReceiptId;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadState();
  }

  @override
  void dispose() {
    for (final controller in [
      _receiptNumberController,
      _titleController,
      _descriptionController,
      _quantityController,
      _unitPriceController,
      _taxRateController,
      _noteController,
      _payeeNameController,
      _payeeContactController,
      _payeeAddressController,
      _payeeAccountController,
      _payeeNoteController,
      _payerNameController,
      _payerContactController,
      _payerAddressController,
      _payerAccountController,
      _payerNoteController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    _receiptNumberController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _taxRateController = TextEditingController();
    _noteController = TextEditingController();

    _payeeNameController = TextEditingController();
    _payeeContactController = TextEditingController();
    _payeeAddressController = TextEditingController();
    _payeeAccountController = TextEditingController();
    _payeeNoteController = TextEditingController();

    _payerNameController = TextEditingController();
    _payerContactController = TextEditingController();
    _payerAddressController = TextEditingController();
    _payerAccountController = TextEditingController();
    _payerNoteController = TextEditingController();
  }

  Future<void> _loadState() async {
    final state = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _templates = state.templates;
      _savedReceipts = state.savedReceipts;
      _draft = state.draft;
      _loading = false;
    });
    _syncControllers();
  }

  void _syncControllers() {
    _receiptNumberController.text = _draft.receiptNumber;
    _titleController.text = _draft.title;
    _descriptionController.text = _draft.description;
    _quantityController.text = displayNumber(_draft.quantity);
    _unitPriceController.text = displayNumber(_draft.unitPrice);
    _taxRateController.text = displayNumber(_draft.taxRate);
    _noteController.text = _draft.note;

    _payeeNameController.text = _draft.payee.name;
    _payeeContactController.text = _draft.payee.contact;
    _payeeAddressController.text = _draft.payee.address;
    _payeeAccountController.text = _draft.payee.accountLabel;
    _payeeNoteController.text = _draft.payee.note;

    _payerNameController.text = _draft.payer.name;
    _payerContactController.text = _draft.payer.contact;
    _payerAddressController.text = _draft.payer.address;
    _payerAccountController.text = _draft.payer.accountLabel;
    _payerNoteController.text = _draft.payer.note;
  }

  SupportedCurrency get _currency =>
      SupportedCurrency.fromCode(_draft.currencyCode);

  NumberFormat get _moneyFormat => NumberFormat.currency(
    locale: 'en_US',
    name: _currency.code,
    symbol: '${_currency.symbol} ',
    decimalDigits: _currency == SupportedCurrency.jpy ? 0 : 2,
  );

  Future<void> _persistDraft() {
    return _repository.saveDraft(_draft);
  }

  Future<void> _persistSavedReceipts() {
    return _repository.saveSavedReceipts(_savedReceipts);
  }

  void _refreshDraftFromControllers() {
    _draft = _draft.copyWith(
      receiptNumber: _receiptNumberController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: parseNumber(_quantityController.text, fallback: 1),
      unitPrice: parseNumber(_unitPriceController.text),
      taxRate: parseNumber(_taxRateController.text),
      note: _noteController.text.trim(),
      payee: _draft.payee.copyWith(
        name: _payeeNameController.text.trim(),
        contact: _payeeContactController.text.trim(),
        address: _payeeAddressController.text.trim(),
        accountLabel: _payeeAccountController.text.trim(),
        note: _payeeNoteController.text.trim(),
      ),
      payer: _draft.payer.copyWith(
        name: _payerNameController.text.trim(),
        contact: _payerContactController.text.trim(),
        address: _payerAddressController.text.trim(),
        accountLabel: _payerAccountController.text.trim(),
        note: _payerNoteController.text.trim(),
      ),
    );
  }

  Future<void> _saveCurrentPartyTemplate(PartyRole role) async {
    _refreshDraftFromControllers();
    final party = role == PartyRole.payee ? _draft.payee : _draft.payer;
    final id = party.id.isEmpty
        ? '${role.name}-${DateTime.now().millisecondsSinceEpoch}'
        : party.id;
    final template = party.copyWith(id: id, role: role);
    final updated = [..._templates.where((item) => item.id != id), template]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      _templates = updated;
      if (role == PartyRole.payee) {
        _draft = _draft.copyWith(payee: template);
      } else {
        _draft = _draft.copyWith(payer: template);
      }
    });
    await _repository.saveTemplates(updated);
    await _persistDraft();
    _showMessage('${role == PartyRole.payee ? 'Payee' : 'Payer'} template saved');
  }

  Future<void> _applyTemplate(PartyTemplate template) async {
    setState(() {
      if (template.role == PartyRole.payee) {
        _draft = _draft.copyWith(payee: template);
      } else {
        _draft = _draft.copyWith(payer: template);
      }
    });
    _syncControllers();
    await _persistDraft();
  }

  Future<void> _deleteTemplate(PartyTemplate template) async {
    final updated = _templates.where((item) => item.id != template.id).toList();
    setState(() {
      _templates = updated;
      if (_draft.payee.id == template.id) {
        _draft = _draft.copyWith(payee: _draft.payee.copyWith(id: ''));
      }
      if (_draft.payer.id == template.id) {
        _draft = _draft.copyWith(payer: _draft.payer.copyWith(id: ''));
      }
    });
    await _repository.saveTemplates(updated);
    await _persistDraft();
  }

  Future<void> _previewPdf() async {
    if (!_validateAndStore()) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(title: const Text('PDF Preview')),
            body: PdfPreview(
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              build: (_) => _pdfService.buildPdf(_draft),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveReceiptToLibrary({
    String? exportPath,
    bool announce = true,
  }) async {
    _refreshDraftFromControllers();
    final now = DateTime.now();
    final recordId =
        _activeReceiptId ?? 'receipt-${now.microsecondsSinceEpoch}';
    SavedReceiptRecord record;
    final existingIndex = _savedReceipts.indexWhere(
      (item) => item.id == recordId,
    );

    if (existingIndex >= 0) {
      final existing = _savedReceipts[existingIndex];
      record = existing.copyWith(
        updatedAt: now,
        exportPath: exportPath ?? existing.exportPath,
        draft: _draft,
      );
    } else {
      record = SavedReceiptRecord(
        id: recordId,
        savedAt: now,
        updatedAt: now,
        exportPath: exportPath ?? '',
        draft: _draft,
      );
    }

    final updated = [
      ..._savedReceipts.where((item) => item.id != record.id),
      record,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() {
      _activeReceiptId = record.id;
      _savedReceipts = updated;
    });
    await _persistSavedReceipts();
    await _persistDraft();
    if (announce) {
      _showMessage('Receipt saved to the app library');
    }
  }

  Future<void> _saveCurrentReceipt() async {
    if (!_validateAndStore()) {
      return;
    }
    await _saveReceiptToLibrary();
  }

  Future<void> _exportPdf() async {
    if (!_validateAndStore()) {
      return;
    }
    try {
      final fileName =
          '${_draft.receiptNumber.isEmpty ? 'receipt' : _draft.receiptNumber}.pdf';

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final directoryPath = await getDirectoryPath(
          confirmButtonText: 'Choose export folder',
        );
        if (directoryPath == null) {
          return;
        }
        setState(() {
          _busy = true;
        });
        final bytes = await _pdfService.buildPdf(_draft);
        final file = File('$directoryPath/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await _saveReceiptToLibrary(exportPath: file.path, announce: false);
        _showMessage('PDF saved to ${file.path}');
        return;
      }

      if (_supportsSaveLocation) {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'PDF', extensions: ['pdf']),
          ],
        );
        if (location == null) {
          return;
        }
        setState(() {
          _busy = true;
        });
        final bytes = await _pdfService.buildPdf(_draft);
        final file = File(location.path);
        await file.writeAsBytes(bytes, flush: true);
        await _saveReceiptToLibrary(exportPath: file.path, announce: false);
        _showMessage('PDF saved to ${file.path}');
        return;
      }

      setState(() {
        _busy = true;
      });
      final bytes = await _pdfService.buildPdf(_draft);
      final tempFile = await _writeTempFile(fileName, bytes);
      await _saveReceiptToLibrary(exportPath: tempFile.path, announce: false);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          title: 'Export Receipt PDF',
          text: 'You can save it to Files or the browser downloads folder.',
        ),
      );
    } catch (error) {
      _showMessage('Export failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<FileSaveLocation?> _trySaveLocation({
    required String suggestedName,
    required List<String> extensions,
    required String label,
  }) async {
    try {
      return await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [XTypeGroup(label: label, extensions: extensions)],
      );
    } catch (_) {
      return null;
    }
  }

  bool get _supportsSaveLocation {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Future<File> _writeTempFile(String fileName, List<int> bytes) async {
    final directory = await getTemporaryDirectory();
    final sanitizedName = fileName.replaceAll('/', '-');
    final file = File('${directory.path}/$sanitizedName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _exportWorkspaceSnapshot() async {
    _refreshDraftFromControllers();
    await _persistDraft();
    final bundle = WorkspaceBundle(
      exportedAt: DateTime.now(),
      draft: _draft,
      templates: _templates,
      savedReceipts: _savedReceipts,
    );
    final fileName =
        'receipt-studio-workspace-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.json';
    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(bundle.toJson());
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final directoryPath = await getDirectoryPath(
        confirmButtonText: 'Choose workspace export folder',
      );
      if (directoryPath == null) {
        return;
      }
      final file = File('$directoryPath/$fileName');
      await file.writeAsString(jsonText, flush: true);
      _showMessage('Workspace exported to ${file.path}');
      return;
    }
    if (_supportsSaveLocation) {
      final location = await _trySaveLocation(
        suggestedName: fileName,
        extensions: const ['json'],
        label: 'Workspace JSON',
      );
      if (location == null) {
        _showMessage('No export location selected. You can choose iCloud Drive in the file picker.');
        return;
      }
      final file = File(location.path);
      await file.writeAsString(jsonText, flush: true);
      _showMessage('Workspace exported to ${file.path}');
      return;
    }
    final tempFile = await _writeTempFile(fileName, utf8.encode(jsonText));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        title: 'Export Workspace',
        text: 'Import it later on another device or browser.',
      ),
    );
  }

  Future<void> _importWorkspaceSnapshot() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Workspace JSON', extensions: ['json']),
        ],
      );
      if (file == null) {
        return;
      }
      final content = await File(file.path).readAsString();
      final bundle = WorkspaceBundle.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      await _repository.replaceWorkspace(bundle);
      setState(() {
        _draft = bundle.draft;
        _templates = [
          ...bundle.templates,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _savedReceipts = [...bundle.savedReceipts]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _activeReceiptId = null;
      });
      _syncControllers();
      _showMessage('Workspace imported and templates plus receipts synced');
    } catch (error) {
      _showMessage('Import failed: $error');
    }
  }

  Future<void> _loadSavedReceipt(SavedReceiptRecord record) async {
    setState(() {
      _activeReceiptId = record.id;
      _draft = record.draft;
    });
    _syncControllers();
    await _persistDraft();
    _showMessage('Loaded receipt record and ready for editing');
  }

  Future<void> _duplicateSavedReceipt(SavedReceiptRecord record) async {
    setState(() {
      _activeReceiptId = null;
      _draft = record.draft.duplicateAsNew();
    });
    _syncControllers();
    await _persistDraft();
    _showMessage('Created a new receipt from history');
  }

  Future<void> _deleteSavedReceipt(SavedReceiptRecord record) async {
    setState(() {
      _savedReceipts = _savedReceipts
          .where((item) => item.id != record.id)
          .toList();
      if (_activeReceiptId == record.id) {
        _activeReceiptId = null;
      }
    });
    await _persistSavedReceipts();
  }

  Future<void> _startFreshReceipt() async {
    setState(() {
      _activeReceiptId = null;
      _draft = ReceiptDraft.initial();
    });
    _syncControllers();
    await _persistDraft();
  }

  bool _validateAndStore() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return false;
    }
    _refreshDraftFromControllers();
    _persistDraft();
    setState(() {});
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summaryCards = [
      _SummaryMetric(
        label: 'Subtotal',
        value: _moneyFormat.format(_draft.subtotal),
      ),
      _SummaryMetric(
        label: 'Tax',
        value: _moneyFormat.format(_draft.taxAmount),
      ),
      _SummaryMetric(
        label: 'Total',
        value: _moneyFormat.format(_draft.total),
        emphasized: true,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCFCFD), Color(0xFFF4F4F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 1180;
              return Row(
                children: [
                  if (desktop)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 0, 24),
                      child: _buildSidebar(),
                    ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 20 : 16,
                          desktop ? 24 : 16,
                          desktop ? 24 : 16,
                          desktop ? 24 : 16,
                        ),
                        child: _buildSectionContent(summaryCards, desktop),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(
    List<_SummaryMetric> summaryCards,
    bool desktop,
  ) {
    final section = widget.section;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!desktop) ...[
                _buildTopTabs(),
                const SizedBox(height: 16),
              ],
              _buildPageIntro(section),
              const SizedBox(height: 18),
              if (section == AppSection.workspace) ...[
                _buildHeroCard(),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 1120;
                    final details = _buildDetailsPanel();
                    final preview = _buildPreviewPanel(summaryCards);
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 8, child: details),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: preview),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        details,
                        const SizedBox(height: 18),
                        preview,
                      ],
                    );
                  },
                ),
              ] else if (section == AppSection.vault) ...[
                _buildVaultScreen(),
              ] else if (section == AppSection.templates) ...[
                _buildTemplatesScreen(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    final currentPath = GoRouterState.of(context).uri.path;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Receipt Studio',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Desktop-first invoice workspace for polished receipt generation.',
            style: TextStyle(color: Color(0xFF71717A), height: 1.45),
          ),
          const SizedBox(height: 24),
          ...AppSection.values.map((section) {
            final selected = currentPath == section.path;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.go(section.path),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF18181B)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF18181B)
                          : const Color(0xFFE4E4E7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        section.icon,
                        color: selected ? Colors.white : const Color(0xFF27272A),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              section.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white70
                                    : const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppSection.values.map((section) {
          final selected = widget.section == section;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(section.title),
              selected: selected,
              onSelected: (_) => context.go(section.path),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageIntro(AppSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(section.icon, color: const Color(0xFF18181B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(section.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receipt Studio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Shape polished receipts, save drafts, and export PDFs from a workspace designed for desktop productivity.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _saveCurrentReceipt,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF18181B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(CupertinoIcons.tray_arrow_down),
                label: const Text('Save to App'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _previewPdf,
                style: _heroOutlineStyle(),
                icon: const Icon(CupertinoIcons.doc_richtext),
                label: const Text('Preview PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _exportPdf,
                style: _heroOutlineStyle(),
                icon: const Icon(CupertinoIcons.arrow_down_doc),
                label: Text(_busy ? 'Working...' : 'Save and Export PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _startFreshReceipt,
                style: _heroOutlineStyle(),
                icon: const Icon(CupertinoIcons.add_circled),
                label: const Text('New Receipt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _heroOutlineStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF52525B)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  Widget _buildDetailsPanel() {
    return Column(
      children: [
        _sectionCard(
          title: 'Receipt Details',
          subtitle: 'Core details, pricing, and currency setup',
          child: Column(
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _fieldBox(
                    width: 240,
                    child: TextFormField(
                      controller: _receiptNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Number',
                      ),
                      validator: _requiredValidator,
                      onChanged: (_) => _debouncedDraftUpdate(),
                    ),
                  ),
                  _fieldBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _draft.currencyCode,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: SupportedCurrency.values
                          .map(
                            (currency) => DropdownMenuItem<String>(
                              value: currency.code,
                              child: Text(
                                '${currency.code} · ${currency.symbol}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(currencyCode: value);
                        });
                        _persistDraft();
                      },
                    ),
                  ),
                  _fieldBox(
                    width: 220,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Issue Date',
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_draft.issueDate),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Receipt Title'),
                validator: _requiredValidator,
                onChanged: (_) => _debouncedDraftUpdate(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _requiredValidator,
                onChanged: (_) => _debouncedDraftUpdate(),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _fieldBox(
                    width: 160,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: _numberValidator,
                      onChanged: (_) => _debouncedDraftUpdate(),
                    ),
                  ),
                  _fieldBox(
                    width: 180,
                    child: TextFormField(
                      controller: _unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                      ),
                      validator: _numberValidator,
                      onChanged: (_) => _debouncedDraftUpdate(),
                    ),
                  ),
                  _fieldBox(
                    width: 160,
                    child: TextFormField(
                      controller: _taxRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate %',
                      ),
                      validator: _numberValidator,
                      onChanged: (_) => _debouncedDraftUpdate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
                onChanged: (_) => _debouncedDraftUpdate(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _partySection(
          role: PartyRole.payee,
          title: 'Payee Template',
          subtitle: 'Save payee details for fast reuse',
          nameController: _payeeNameController,
          contactController: _payeeContactController,
          addressController: _payeeAddressController,
          accountController: _payeeAccountController,
          noteController: _payeeNoteController,
        ),
        const SizedBox(height: 18),
        _partySection(
          role: PartyRole.payer,
          title: 'Payer Template',
          subtitle: 'Save payer details for different clients and organizations',
          nameController: _payerNameController,
          contactController: _payerContactController,
          addressController: _payerAddressController,
          accountController: _payerAccountController,
          noteController: _payerNoteController,
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(List<_SummaryMetric> summaryCards) {
    return Column(
      children: [
        _sectionCard(
          title: 'Amount Snapshot',
          subtitle: 'Live totals and pre-export preview',
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: summaryCards.map(_metricTile).toList(),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF5EE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE6D5C5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _draft.title.isEmpty ? 'Receipt Preview' : _draft.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _previewLine('Receipt No.', _draft.receiptNumber),
                    _previewLine(
                      'Currency',
                      '${_currency.code} · ${_currency.label}',
                    ),
                    _previewLine('Payee', _draft.payee.name),
                    _previewLine('Payer', _draft.payer.name),
                    _previewLine(
                      'Issue Date',
                      DateFormat('yyyy-MM-dd').format(_draft.issueDate),
                    ),
                    const Divider(height: 28, color: Color(0xFFD9C5B2)),
                    Text(
                      _draft.description,
                      style: const TextStyle(
                        height: 1.5,
                        color: Color(0xFF6B5448),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          const Text(
                            'Total Due',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _moneyFormat.format(_draft.total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
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
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Receipt Vault',
          subtitle: 'Saved receipts you can reopen, duplicate, or export again',
          child: _buildVaultBody(),
        ),
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Template Library',
          subtitle: 'Reusable payee and payer records',
          child: _buildTemplateLibraryBody(),
        ),
      ],
    );
  }

  Widget _buildVaultScreen() {
    return _sectionCard(
      title: 'Workspace Snapshots',
      subtitle: 'Import and export saved workspace data',
      child: _buildVaultBody(),
    );
  }

  Widget _buildTemplatesScreen() {
    return Column(
      children: [
        _sectionCard(
          title: 'Template Library',
          subtitle: 'Manage reusable payee and payer templates',
          child: _buildTemplateLibraryBody(),
        ),
      ],
    );
  }

  Widget _buildVaultBody() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _importWorkspaceSnapshot,
              icon: const Icon(CupertinoIcons.arrow_down_doc_fill),
              label: const Text('Import Workspace'),
            ),
            OutlinedButton.icon(
              onPressed: _exportWorkspaceSnapshot,
              icon: const Icon(CupertinoIcons.arrow_up_doc_fill),
              label: const Text('Export Workspace'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_savedReceipts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No saved receipts yet. Use Save to App or Export PDF to create one.',
            ),
          )
        else
          ..._savedReceipts.map(_savedReceiptTile),
      ],
    );
  }

  Widget _buildTemplateLibraryBody() {
    return Column(
      children: [
        _templateGroup(PartyRole.payee),
        const SizedBox(height: 12),
        _templateGroup(PartyRole.payer),
      ],
    );
  }


  Widget _partySection({
    required PartyRole role,
    required String title,
    required String subtitle,
    required TextEditingController nameController,
    required TextEditingController contactController,
    required TextEditingController addressController,
    required TextEditingController accountController,
    required TextEditingController noteController,
  }) {
    return _sectionCard(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: _requiredValidator,
            onChanged: (_) => _debouncedDraftUpdate(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: contactController,
            decoration: const InputDecoration(labelText: 'Contact'),
            validator: _requiredValidator,
            onChanged: (_) => _debouncedDraftUpdate(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Address'),
            validator: _requiredValidator,
            onChanged: (_) => _debouncedDraftUpdate(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: accountController,
            decoration: const InputDecoration(labelText: 'Account / Reference'),
            onChanged: (_) => _debouncedDraftUpdate(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Template Note'),
            onChanged: (_) => _debouncedDraftUpdate(),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _saveCurrentPartyTemplate(role),
              icon: const Icon(CupertinoIcons.bookmark),
              label: const Text('Save as Template'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedReceiptTile(SavedReceiptRecord record) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D5C5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(record.draft.title),
        subtitle: Text(
          [
            record.draft.receiptNumber,
            record.draft.payer.name,
            'Updated ${formatter.format(record.updatedAt)}',
            if (record.exportPath.isNotEmpty) 'Exported',
          ].join(' · '),
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: 'Continue editing',
              onPressed: () => _loadSavedReceipt(record),
              icon: const Icon(CupertinoIcons.pencil),
            ),
            IconButton(
              tooltip: 'Duplicate',
              onPressed: () => _duplicateSavedReceipt(record),
              icon: const Icon(CupertinoIcons.doc_on_doc),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _deleteSavedReceipt(record),
              icon: const Icon(CupertinoIcons.delete),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateGroup(PartyRole role) {
    final items = _templates
        .where((template) => template.role == role)
        .toList();
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Text('${role == PartyRole.payee ? 'Payee' : 'Payer'} template is empty'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role == PartyRole.payee ? 'Payee Templates' : 'Payer Templates',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (template) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6D5C5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              title: Text(template.name),
              subtitle: Text(
                [
                  template.contact,
                  template.accountLabel,
                ].where((text) => text.isNotEmpty).join(' · '),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Apply template',
                    onPressed: () => _applyTemplate(template),
                    icon: const Icon(CupertinoIcons.arrow_down_doc),
                  ),
                  IconButton(
                    tooltip: 'Delete template',
                    onPressed: () => _deleteTemplate(template),
                    icon: const Icon(CupertinoIcons.delete),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(height: 1.45, color: Color(0xFF71717A)),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _fieldBox({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Widget _metricTile(_SummaryMetric metric) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: metric.emphasized ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: metric.emphasized
              ? const Color(0xFF18181B)
              : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: TextStyle(
              color: metric.emphasized
                  ? Colors.white70
                  : const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: metric.emphasized ? Colors.white : const Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF71717A)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF18181B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _draft.issueDate,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(issueDate: picked);
    });
    await _persistDraft();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  void _debouncedDraftUpdate() {
    _refreshDraftFromControllers();
    _persistDraft();
    setState(() {});
  }
}

class _SummaryMetric {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;
}
