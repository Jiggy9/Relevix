import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/dataset.dart';
import '../services/file_parser.dart';
import '../services/data_validator.dart';
import 'column_selection_screen.dart';

class _FileEntry {
  final String name;
  final Dataset? dataset;
  final String? error;
  final bool isLoading;

  _FileEntry({
    required this.name,
    this.dataset,
    this.error,
    this.isLoading = false,
  });

  bool get isValid => dataset != null && error == null;
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<_FileEntry> _files = [];
  bool _isPickingFiles = false;

  Future<void> _pickFiles() async {
    if (_isPickingFiles) return;
    setState(() => _isPickingFiles = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isPickingFiles = false);
        return;
      }

      for (final file in result.files) {
        if (file.bytes == null) continue;

        final entry = _FileEntry(name: file.name, isLoading: true);
        setState(() => _files.add(entry));
        final index = _files.length - 1;

        try {
          final dataset = await FileParser.parse(
            bytes: file.bytes!,
            fileName: file.name,
          );

          final validation = DataValidator.validate(dataset);

          if (_files.length > 1) {
            final schemaCheck = DataValidator.validateSchemaMatch(
              _files.firstWhere((f) => f.isValid).dataset!,
              dataset,
            );
            if (!schemaCheck.isValid) {
              setState(() {
                _files[index] = _FileEntry(
                  name: file.name,
                  error: schemaCheck.error,
                );
              });
              continue;
            }
          }

          if (validation.isValid) {
            setState(() {
              _files[index] = _FileEntry(
                name: file.name,
                dataset: dataset,
              );
            });
          } else {
            setState(() {
              _files[index] = _FileEntry(
                name: file.name,
                error: validation.error,
              );
            });
          }
        } catch (e) {
          setState(() {
            _files[index] = _FileEntry(
              name: file.name,
              error: e.toString(),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }

    setState(() => _isPickingFiles = false);
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  List<Dataset> get _validDatasets =>
      _files.where((f) => f.isValid).map((f) => f.dataset!).toList();

  bool get _canProceed => _validDatasets.isNotEmpty;

  void _proceed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ColumnSelectionScreen(datasets: _validDatasets),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(title: const Text('Upload Datasets')),
      body: Column(
        children: [
          Expanded(
            child: _files.isEmpty ? _buildEmptyState() : _buildFileList(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.cardBeige,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                size: 48,
                color: AppTheme.primaryBrown,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No files uploaded yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload CSV or Excel files to begin.\nAll files must share the same column structure.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isPickingFiles ? null : _pickFiles,
              icon: const Icon(Icons.add_rounded),
              label: Text(_isPickingFiles ? 'Loading...' : 'Select Files'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildFileTile(file, index);
      },
    );
  }

  Widget _buildFileTile(_FileEntry file, int index) {
    final isValid = file.isValid;
    final isLoading = file.isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLoading
                ? AppTheme.cardBeige
                : isValid
                    ? AppTheme.successGreen.withAlpha(25)
                    : AppTheme.errorRed.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBrown,
                  ),
                )
              : Icon(
                  isValid
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: isValid
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                ),
        ),
        title: Text(
          file.name,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: file.error != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  file.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorRed,
                        fontSize: 12,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : file.dataset != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${file.dataset!.rowCount} rows · ${file.dataset!.columnCount} columns',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textLight,
                                fontSize: 12,
                              ),
                    ),
                  )
                : null,
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textLight),
          onPressed: () => _removeFile(index),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_files.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _isPickingFiles ? null : _pickFiles,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add More'),
              ),
            if (_files.isEmpty)
              const Spacer(),
            if (_files.isNotEmpty) const Spacer(),
            ElevatedButton(
              onPressed: _canProceed ? _proceed : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_canProceed
                      ? 'Continue (${_validDatasets.length} ${_validDatasets.length == 1 ? "file" : "files"})'
                      : 'Upload files to continue'),
                  if (_canProceed) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
