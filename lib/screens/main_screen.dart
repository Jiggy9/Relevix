import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dataset.dart';
import '../models/interpolation_result.dart';
import '../services/interpolation_engine.dart';
import '../widgets/chart_widget.dart';
import '../widgets/result_card.dart';

class MainScreen extends StatefulWidget {
  final Dataset dataset;
  final String inputColumn;
  final String outputColumn;

  const MainScreen({
    super.key,
    required this.dataset,
    required this.inputColumn,
    required this.outputColumn,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late InterpolationEngine _engine;
  final TextEditingController _inputController = TextEditingController();
  InterpolationResult? _result;
  String? _errorMessage;
  late String _currentInputColumn;
  late String _currentOutputColumn;

  @override
  void initState() {
    super.initState();
    _currentInputColumn = widget.inputColumn;
    _currentOutputColumn = widget.outputColumn;
    _initEngine();
  }

  void _initEngine() {
    _engine = InterpolationEngine(
      dataset: widget.dataset,
      inputColumn: _currentInputColumn,
      outputColumn: _currentOutputColumn,
    );
  }

  void _swapColumns() {
    setState(() {
      final temp = _currentInputColumn;
      _currentInputColumn = _currentOutputColumn;
      _currentOutputColumn = temp;
      _initEngine();
      _result = null;
      _errorMessage = null;
      _inputController.clear();
    });
  }

  void _compute() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a value.';
        _result = null;
      });
      return;
    }

    final inputValue = double.tryParse(text);
    if (inputValue == null) {
      setState(() {
        _errorMessage = 'Invalid number. Please enter a numeric value.';
        _result = null;
      });
      return;
    }

    try {
      final result = _engine.compute(inputValue);
      setState(() {
        _result = result;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _result = null;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text('Relevix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Swap Input/Output',
            onPressed: _swapColumns,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout();
          }
          return _buildNarrowLayout();
        },
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ChartWidget(
              dataset: widget.dataset,
              xColumn: _currentInputColumn,
              yColumn: _currentOutputColumn,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildCalculatorSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ChartWidget(
              dataset: widget.dataset,
              xColumn: _currentInputColumn,
              yColumn: _currentOutputColumn,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCalculatorSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildColumnChip(
                    'Input', _currentInputColumn, Icons.input_rounded),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.textLight, size: 16),
                const SizedBox(width: 8),
                _buildColumnChip(
                    'Output', _currentOutputColumn, Icons.output_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_engine.minInput != null && _engine.maxInput != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Data range: ${_engine.minInput!.toStringAsFixed(2)} – ${_engine.maxInput!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

        TextField(
          controller: _inputController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Enter $_currentInputColumn value',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: () {
                _inputController.clear();
                setState(() {
                  _result = null;
                  _errorMessage = null;
                });
              },
            ),
          ),
          onSubmitted: (_) => _compute(),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _compute,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calculate_rounded, size: 20),
              SizedBox(width: 8),
              Text('Compute'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.errorRed.withAlpha(76)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.errorRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorRed,
                        ),
                  ),
                ),
              ],
            ),
          ),

        if (_result != null)
          ResultCard(
            result: _result!,
            outputColumn: _currentOutputColumn,
          ),
      ],
    );
  }

  Widget _buildColumnChip(String label, String column, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBeige,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryBrown),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    column,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBrown,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
