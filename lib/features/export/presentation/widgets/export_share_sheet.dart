import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/features/export/domain/export_state.dart';
import 'package:visiobook_mobile/features/export/presentation/providers/export_provider.dart';

class ExportShareSheet extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ExportShareSheet({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  /// Show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String projectId,
    required String projectTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ExportShareSheet(projectId: projectId, projectTitle: projectTitle),
    );
  }

  @override
  State<ExportShareSheet> createState() => _ExportShareSheetState();
}

class _ExportShareSheetState extends State<ExportShareSheet> {
  bool _linkCopied = false;
  Timer? _linkCopiedTimer;

  @override
  void dispose() {
    _linkCopiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Consumer<ExportProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Exporter & Partager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.neutral200),
                // Download section
                _buildDownloadSection(provider),
                const Divider(height: 1, color: AppColors.neutral200),
                // Share link section
                _buildShareLinkSection(provider),
                const Divider(height: 1, color: AppColors.neutral200),
                // Native share section
                _buildNativeShareSection(provider),
                // Bottom safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDownloadSection(ExportProvider provider) {
    final downloadState = provider.downloadState;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(LucideIcons.download, size: 22, color: AppColors.neutral900),
              const SizedBox(width: 12),
              const Text(
                'Télécharger la vidéo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quality selector
          Row(
            children: [
              _buildQualityChip(provider, '480p'),
              const SizedBox(width: 8),
              _buildQualityChip(provider, '720p'),
              const SizedBox(width: 8),
              _buildQualityChip(provider, '1080p'),
            ],
          ),
          const SizedBox(height: 16),
          // Action / status area
          if (downloadState == ExportDownloadState.idle)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.startDownload(
                  widget.projectId,
                  provider.selectedQuality,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neutral900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Télécharger',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (downloadState == ExportDownloadState.downloading)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: provider.downloadProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.neutral900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(provider.downloadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            )
          else if (downloadState == ExportDownloadState.completed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Téléchargé !',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            )
          else if (downloadState == ExportDownloadState.failed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    provider.downloadError ?? 'Erreur de téléchargement',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQualityChip(ExportProvider provider, String quality) {
    final isSelected = provider.selectedQuality.label == quality;

    return ChoiceChip(
      label: Text(quality),
      selected: isSelected,
      onSelected: (_) => provider.setQuality(quality),
      selectedColor: AppColors.neutral900,
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.neutral900,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.neutral900 : AppColors.neutral300,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildShareLinkSection(ExportProvider provider) {
    return InkWell(
      onTap: _linkCopied
          ? null
          : () async {
              await provider.generateAndCopyShareLink(widget.projectId);
              if (!mounted) return;
              setState(() {
                _linkCopied = true;
              });
              _linkCopiedTimer?.cancel();
              _linkCopiedTimer = Timer(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _linkCopied = false;
                  });
                }
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(
              _linkCopied ? LucideIcons.checkCircle : LucideIcons.link,
              size: 22,
              color: _linkCopied ? AppColors.success : AppColors.neutral900,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _linkCopied ? 'Lien copié !' : 'Copier le lien de partage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _linkCopied ? AppColors.success : AppColors.neutral900,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeShareSection(ExportProvider provider) {
    return InkWell(
      onTap: () => provider.shareNative(widget.projectId, widget.projectTitle),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(LucideIcons.share2, size: 22, color: AppColors.neutral900),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Partager via...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
