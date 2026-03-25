import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dataset.dart';
import '../services/data_validator.dart';
import '../services/dataset_merger.dart';
import 'main_screen.dart';

class ColumnSelectionScreen extends StatefulWidget {
  final List<Dataset> datasets;

  const ColumnSelectionScreen({super.key, required this.datasets});

  @override
  State<ColumnSelectionScreen> createState() => _ColumnSelectionScreenState();
}

class _ColumnSelectionScreenState extends State<ColumnSelectionScreen> {
  String? _inputColumn;
  String? _outputColumn;
  late List<String> _numericColumns;

  @override
  void initState() {
    super.initState();
    _numericColumns = _getNumericColumns();
    if (_numericColumns.length >= 2) {
      _inputColumn = _numericColumns[0];
      _outputColumn = _numericColumns[1];
    }
  }

  List<String> _getNumericColumns() {
    final reference = widget.datasets.first;
    final validation = DataValidator.validate(reference);
    return validation.numericColumns;
  }

  void _swapColumns() {
    setState(() {
      final temp = _inputColumn;
      _inputColumn = _outputColumn;
      _outputColumn = temp;
    });
  }

  bool get _canProceed =>
      _inputColumn != null &&
      _outputColumn != null &&
      _inputColumn != _outputColumn;

  void _proceed() {
    final merged = DatasetMerger.merge(widget.datasets);
    final cleaned = DatasetMerger.removeInvalidRows(merged);
    final sorted = cleaned.sortedBy(_inputColumn!);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          dataset: sorted,
          inputColumn: _inputColumn!,
          outputColumn: _outputColumn!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(title: const Text('Select Variables')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppTheme.primaryBrown, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.datasets.length} ${widget.datasets.length == 1 ? "file" : "files"} loaded · '
                            '${widget.datasets.fold<int>(0, (sum, d) => sum + d.rowCount)} total rows',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textLight,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Value you have',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _inputColumn,
              onChanged: (val) => setState(() => _inputColumn = val),
              excludeValue: _outputColumn,
            ),

            const SizedBox(height: 16),

            Center(
              child: IconButton(
                onPressed: (_inputColumn != null && _outputColumn != null)
                    ? _swapColumns
                    : null,
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBrown.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: AppTheme.backgroundBeige,
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Value you want',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _outputColumn,
              onChanged: (val) => setState(() => _outputColumn = val),
              excludeValue: _inputColumn,
            ),

            if (_inputColumn == _outputColumn &&
                _inputColumn != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.warningAmber.withAlpha(76),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppTheme.warningAmber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Input and output must be different variables.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.warningAmber,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            ElevatedButton(
              onPressed: _canProceed ? _proceed : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    String? excludeValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentTan.withAlpha(128)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.primaryBrown),
          dropdownColor: AppTheme.surfaceWhite,
          style: Theme.of(context).textTheme.bodyLarge,
          items: _numericColumns.map((col) {
            final isDisabled = col == excludeValue;
            return DropdownMenuItem<String>(
              value: col,
              enabled: !isDisabled,
              child: Text(
                col,
                style: TextStyle(
                  color: isDisabled
                      ? AppTheme.textLight.withAlpha(102)
                      : AppTheme.textDark,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
