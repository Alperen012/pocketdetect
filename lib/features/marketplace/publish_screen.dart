import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/marketplace_service.dart';
import '../../core/services/model_validator.dart';
import '../../core/theme/app_colors.dart';

/// Screen for publishing a new AI model to the marketplace.
class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0.0');
  final _descriptionController = TextEditingController();

  String? _modelFilePath;
  String? _thumbnailPath;
  String _licenseType = 'MIT';
  final List<String> _selectedTags = [];
  int? _fileSizeBytes;
  bool _isPublishing = false;
  String? _publishError;

  static const _licenseOptions = [
    'MIT',
    'Apache-2.0',
    'GPL-3.0',
    'BSD-3-Clause',
    'CC-BY-4.0',
    'CC-BY-NC-4.0',
    'Custom',
  ];

  static const _availableTags = [
    'detection',
    'segmentation',
    'classification',
    'pose',
    'obb',
    'yolo',
    'custom',
    'lightweight',
    'high-accuracy',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Publish Model',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model file picker
              _sectionLabel('Model File (.tflite) *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickModelFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _modelFilePath != null
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _modelFilePath != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        size: 36,
                        color: _modelFilePath != null
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _modelFilePath != null
                            ? _modelFilePath!.split(Platform.pathSeparator).last
                            : 'Tap to select .tflite file',
                        style: TextStyle(
                          color: _modelFilePath != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_fileSizeBytes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatSize(_fileSizeBytes!),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _sectionLabel('Model Name *'),
              const SizedBox(height: 8),
              _textField(
                controller: _nameController,
                hint: 'e.g. YOLOv8n Custom Detector',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Version
              _sectionLabel('Version *'),
              const SizedBox(height: 8),
              _textField(
                controller: _versionController,
                hint: '1.0.0',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Version is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _sectionLabel('Description *'),
              const SizedBox(height: 8),
              _textField(
                controller: _descriptionController,
                hint: 'Describe your model, what it detects, accuracy, etc.',
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Thumbnail
              _sectionLabel('Thumbnail (optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    image: _thumbnailPath != null
                        ? DecorationImage(
                            image: FileImage(File(_thumbnailPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _thumbnailPath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_rounded,
                              color: AppColors.textSecondary,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add image',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // License
              _sectionLabel('License *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _licenseType,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: _licenseOptions
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _licenseType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tags
              _sectionLabel('Tags'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // Error message
              if (_publishError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _publishError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Publish button
              GestureDetector(
                onTap: _isPublishing ? null : _publish,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isPublishing ? AppColors.border : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isPublishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Publish Model',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ─── File pickers ──────────────────────────────────────────

  Future<void> _pickModelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    if (!path.endsWith('.tflite')) {
      setState(() => _publishError = 'Only .tflite files are supported');
      return;
    }

    // Validate the model file
    final validation = await ModelValidator.validate(path);
    if (!validation.isValid) {
      setState(
        () => _publishError = 'Invalid model: ${validation.errorCode?.name}',
      );
      return;
    }

    final file = File(path);
    final size = await file.length();

    setState(() {
      _modelFilePath = path;
      _fileSizeBytes = size;
      _publishError = null;
    });
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _thumbnailPath = path);
  }

  // ─── Publish ───────────────────────────────────────────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modelFilePath == null) {
      setState(() => _publishError = 'Please select a model file');
      return;
    }

    setState(() {
      _isPublishing = true;
      _publishError = null;
    });

    final svc = context.read<MarketplaceService>();
    final error = await svc.publishModel(
      name: _nameController.text.trim(),
      version: _versionController.text.trim(),
      description: _descriptionController.text.trim(),
      filePath: _modelFilePath!,
      fileSizeBytes: _fileSizeBytes!,
      licenseType: _licenseType,
      tags: _selectedTags,
      thumbnailPath: _thumbnailPath,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isPublishing = false;
        _publishError = error;
      });
    } else {
      // Success — pop and refresh
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Model published successfully!'),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
