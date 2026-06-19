// lib/screens/fac_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/fac_entry.dart';
import '../services/auth_service.dart';

class FacTab extends StatefulWidget {
  final Color primaryColor;

  const FacTab({super.key, required this.primaryColor});

  @override
  State<FacTab> createState() => _FacTabState();
}

class _FacTabState extends State<FacTab> {
  late Box<FacEntry> _facBox;
  final AuthService _authService = AuthService();
  bool _isSecurityLoading = true;
  bool _isAppProtected = false;

  @override
  void initState() {
    super.initState();
    _facBox = Hive.box<FacEntry>('fac');
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final hasPasscode = await _authService.hasPasscode();
    final hasBiometric = await _authService.isBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _isAppProtected = hasPasscode || hasBiometric;
      _isSecurityLoading = false;
    });
  }

  Future<void> _addOrEditFac({FacEntry? entry}) async {
    await _loadSecurityState();
    if (!_isAppProtected) {
      _showSecurityRequiredMessage();
      return;
    }

    if (!mounted) return;

    final certificateController = TextEditingController(
      text: entry?.certificateNumber ?? '',
    );
    DateTime? validFrom = entry?.validFrom;
    DateTime? validTo = entry?.validTo;
    final firearms = entry?.firearms
            .map(
              (item) => FacFirearmAllowance(
                calibre: item.calibre,
                type: item.type,
                action: item.action,
                qty: item.qty,
              ),
            )
            .toList() ??
        <FacFirearmAllowance>[];
    final ammunition = entry?.ammunition
            .map(
              (item) => FacAmmunitionAllowance(
                calibre: item.calibre,
                quantity: item.quantity,
              ),
            )
            .toList() ??
        <FacAmmunitionAllowance>[];
    final firearmsOwned = entry?.firearmsOwned
            .map(
              (item) => FacFirearmOwned(
                calibre: item.calibre,
                makersName: item.makersName,
                type: item.type,
                action: item.action,
                identification: item.identification,
              ),
            )
            .toList() ??
        <FacFirearmOwned>[];

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            entry == null ? 'Enter FAC Details' : 'Edit FAC Details',
            style: TextStyle(color: primaryColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(certificateController, 'Certificate number'),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    label: 'Valid from',
                    value: validFrom,
                    primaryColor: primaryColor,
                    onChanged: (date) => setDialogState(() => validFrom = date),
                  ),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    label: 'Valid to',
                    value: validTo,
                    primaryColor: primaryColor,
                    onChanged: (date) => setDialogState(() => validTo = date),
                  ),
                  const SizedBox(height: 16),
                  _buildFirearmsSection(
                    firearms,
                    primaryColor,
                    setDialogState,
                  ),
                  const SizedBox(height: 16),
                  _buildAmmunitionSection(
                    ammunition,
                    primaryColor,
                    setDialogState,
                  ),
                  const SizedBox(height: 16),
                  _buildFirearmsOwnedSection(
                    firearmsOwned,
                    primaryColor,
                    setDialogState,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newEntry = FacEntry(
                  id: entry?.id ?? 'fac_details',
                  certificateNumber: _blankToNull(certificateController.text),
                  validFrom: validFrom,
                  validTo: validTo,
                  firearms: firearms,
                  ammunition: ammunition,
                  firearmsOwned: firearmsOwned,
                );

                _facBox.put(newEntry.id, newEntry);
                Navigator.pop(dialogContext);
                setState(() {});
              },
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirearmsSection(
    List<FacFirearmAllowance> firearms,
    Color primaryColor,
    StateSetter setDialogState,
  ) {
    return _buildRepeatingSection(
      title: 'Firearms',
      emptyText: 'No firearms listed',
      primaryColor: primaryColor,
      itemCount: firearms.length,
      onAdd: () => setDialogState(() => firearms.add(FacFirearmAllowance())),
      itemBuilder: (index) {
        final item = firearms[index];
        return _buildEntryCard(
          primaryColor: primaryColor,
          title: 'Firearm ${index + 1}',
          onDelete: () => setDialogState(() => firearms.removeAt(index)),
          children: [
            _buildTextFieldWithInitialValue(
              item.calibre,
              'Calibre',
              (value) => item.calibre = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildTextFieldWithInitialValue(
              item.type,
              'Type',
              (value) => item.type = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildTextFieldWithInitialValue(
              item.action,
              'Action',
              (value) => item.action = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildNumberFieldWithInitialValue(
              item.qty,
              'Qty',
              (value) => item.qty = _parseNullableInt(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmmunitionSection(
    List<FacAmmunitionAllowance> ammunition,
    Color primaryColor,
    StateSetter setDialogState,
  ) {
    return _buildRepeatingSection(
      title: 'Ammunition',
      emptyText: 'No ammunition listed',
      primaryColor: primaryColor,
      itemCount: ammunition.length,
      onAdd: () => setDialogState(() => ammunition.add(FacAmmunitionAllowance())),
      itemBuilder: (index) {
        final item = ammunition[index];
        return _buildEntryCard(
          primaryColor: primaryColor,
          title: 'Ammunition ${index + 1}',
          onDelete: () => setDialogState(() => ammunition.removeAt(index)),
          children: [
            _buildTextFieldWithInitialValue(
              item.calibre,
              'Calibre',
              (value) => item.calibre = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildNumberFieldWithInitialValue(
              item.quantity,
              'Quantity',
              (value) => item.quantity = _parseNullableInt(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFirearmsOwnedSection(
    List<FacFirearmOwned> firearmsOwned,
    Color primaryColor,
    StateSetter setDialogState,
  ) {
    return _buildRepeatingSection(
      title: 'Firearms Owned',
      emptyText: 'No firearms owned listed',
      primaryColor: primaryColor,
      itemCount: firearmsOwned.length,
      onAdd: () => setDialogState(() => firearmsOwned.add(FacFirearmOwned())),
      itemBuilder: (index) {
        final item = firearmsOwned[index];
        return _buildEntryCard(
          primaryColor: primaryColor,
          title: 'Owned firearm ${index + 1}',
          onDelete: () => setDialogState(() => firearmsOwned.removeAt(index)),
          children: [
            _buildTextFieldWithInitialValue(
              item.calibre,
              'Calibre',
              (value) => item.calibre = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildTextFieldWithInitialValue(
              item.makersName,
              "Maker's Name",
              (value) => item.makersName = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildTextFieldWithInitialValue(
              item.type,
              'Type',
              (value) => item.type = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildTextFieldWithInitialValue(
              item.action,
              'Action',
              (value) => item.action = _blankToNull(value),
            ),
            const SizedBox(height: 8),
            _buildTextFieldWithInitialValue(
              item.identification,
              'Identification',
              (value) => item.identification = _blankToNull(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRepeatingSection({
    required String title,
    required String emptyText,
    required Color primaryColor,
    required int itemCount,
    required VoidCallback onAdd,
    required Widget Function(int index) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
        if (itemCount == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyText,
              style: TextStyle(color: primaryColor.withOpacity(0.7)),
            ),
          ),
        ...List.generate(itemCount, itemBuilder),
      ],
    );
  }

  Widget _buildEntryCard({
    required Color primaryColor,
    required String title,
    required VoidCallback onDelete,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return TextField(
      controller: controller,
      style: TextStyle(color: primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: bgColor.withAlpha((0.05 * 255).round()),
      ),
    );
  }

  Widget _buildTextFieldWithInitialValue(
    String? initialValue,
    String label,
    ValueChanged<String> onChanged, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return TextFormField(
      initialValue: initialValue ?? '',
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: bgColor.withAlpha((0.05 * 255).round()),
      ),
    );
  }

  Widget _buildNumberFieldWithInitialValue(
    int? initialValue,
    String label,
    ValueChanged<String> onChanged,
  ) {
    return _buildTextFieldWithInitialValue(
      initialValue?.toString(),
      label,
      onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  void _showSecurityRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Set up a passcode or biometric security before entering FAC details.',
        ),
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _parseNullableInt(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatNullableText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not set';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final facEntries = _facBox.values.toList();
    final fac = facEntries.isEmpty ? null : facEntries.first;

    return Container(
      color: bgColor,
      child: _isSecurityLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isAppProtected) ...[
                    _buildNotice(primaryColor),
                    const SizedBox(height: 16),
                  ],
                  if (fac == null)
                    _buildEmptyState(primaryColor)
                  else
                    _buildFacDetails(fac, primaryColor),
                ],
              ),
            ),
    );
  }

  Widget _buildNotice(Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You must protect this app with a password or biometric security before entering any FAC details. NOTE: these details are only stored locally on your device for security.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          Icon(Icons.description_outlined, size: 64, color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'No FAC found',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isAppProtected ? () => _addOrEditFac() : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: primaryColor,
              backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
            ),
            child: const Text('Enter FAC details'),
          ),
          if (!_isAppProtected) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/security_setup')
                  .then((_) => _loadSecurityState()),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              child: const Text('Set up app security'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFacDetails(FacEntry fac, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDetailCard(
          title: 'Certificate',
          primaryColor: primaryColor,
          children: [
            _buildDetailRow(
              'Certificate number',
              _formatNullableText(fac.certificateNumber),
            ),
            _buildDetailRow('Valid from', _formatDate(fac.validFrom)),
            _buildDetailRow('Valid to', _formatDate(fac.validTo)),
          ],
        ),
        const SizedBox(height: 12),
        _buildListDetailCard(
          title: 'Firearms',
          primaryColor: primaryColor,
          isEmpty: fac.firearms.isEmpty,
          emptyText: 'No firearms listed',
          children: fac.firearms
              .map(
                (item) => _buildDetailSubCard([
                  _buildDetailRow('Calibre', _formatNullableText(item.calibre)),
                  _buildDetailRow('Type', _formatNullableText(item.type)),
                  _buildDetailRow('Action', _formatNullableText(item.action)),
                  _buildDetailRow('Qty', item.qty?.toString() ?? 'Not set'),
                ]),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _buildListDetailCard(
          title: 'Ammunition',
          primaryColor: primaryColor,
          isEmpty: fac.ammunition.isEmpty,
          emptyText: 'No ammunition listed',
          children: fac.ammunition
              .map(
                (item) => _buildDetailSubCard([
                  _buildDetailRow('Calibre', _formatNullableText(item.calibre)),
                  _buildDetailRow(
                    'Quantity',
                    item.quantity?.toString() ?? 'Not set',
                  ),
                ]),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _buildListDetailCard(
          title: 'Firearms Owned',
          primaryColor: primaryColor,
          isEmpty: fac.firearmsOwned.isEmpty,
          emptyText: 'No firearms owned listed',
          children: fac.firearmsOwned
              .map(
                (item) => _buildDetailSubCard([
                  _buildDetailRow('Calibre', _formatNullableText(item.calibre)),
                  _buildDetailRow(
                    "Maker's Name",
                    _formatNullableText(item.makersName),
                  ),
                  _buildDetailRow('Type', _formatNullableText(item.type)),
                  _buildDetailRow('Action', _formatNullableText(item.action)),
                  _buildDetailRow(
                    'Identification',
                    _formatNullableText(item.identification),
                  ),
                ]),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isAppProtected ? () => _addOrEditFac(entry: fac) : null,
          icon: const Icon(Icons.edit),
          label: const Text('Edit FAC details'),
          style: ElevatedButton.styleFrom(
            foregroundColor: primaryColor,
            backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
          ),
        ),
        if (!_isAppProtected)
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/security_setup')
                .then((_) => _loadSecurityState()),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Set up app security'),
          ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required Color primaryColor,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListDetailCard({
    required String title,
    required Color primaryColor,
    required bool isEmpty,
    required String emptyText,
    required List<Widget> children,
  }) {
    return _buildDetailCard(
      title: title,
      primaryColor: primaryColor,
      children: isEmpty
          ? [Text(emptyText, style: TextStyle(color: primaryColor))]
          : children,
    );
  }

  Widget _buildDetailSubCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Color primaryColor;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final displayValue = value == null
        ? ''
        : '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/'
            '${value!.year}';

    return TextField(
      readOnly: true,
      controller: TextEditingController(text: displayValue),
      style: TextStyle(color: primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: bgColor.withAlpha((0.05 * 255).round()),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear),
                color: primaryColor,
              ),
            Icon(Icons.calendar_today, color: primaryColor),
            const SizedBox(width: 12),
          ],
        ),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
