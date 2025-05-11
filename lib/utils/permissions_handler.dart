import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PermissionsHandler {
  /// Request storage permissions with better user feedback
  static Future<bool> requestStoragePermissions(BuildContext context) async {
    // Cache the l10n before any async operations
    final l10n = AppLocalizations.of(context)!;

    // Request permissions
    Map<Permission, PermissionStatus> statuses =
        await [Permission.storage, Permission.manageExternalStorage].request();

    // Check if any permission is granted
    bool granted =
        statuses[Permission.storage] == PermissionStatus.granted ||
        statuses[Permission.manageExternalStorage] == PermissionStatus.granted;

    // If denied, show explanation dialog
    if (!granted) {
      // Using a separate method to avoid context issues
      // Capture context.mounted to check after the async gap
      if (!context.mounted) return false;

      bool shouldOpenSettings = await _showPermissionDialog(context, l10n);

      if (shouldOpenSettings) {
        return openAppSettings();
      }
      return false;
    }

    return true;
  }

  static Future<bool> _showPermissionDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.permissionRequired),
            content: Text(l10n.storagePermissionExplanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.openSettings),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  /// Get human-readable file path and storage location name
  static Future<Map<String, String>> getReadableFilePath(
    String filePath,
  ) async {
    String location = "Internal Storage";
    String displayPath = filePath;

    try {
      // Get common directory paths for comparison
      final appDocDir = await getApplicationDocumentsDirectory();
      final externalDir = await getExternalStorageDirectory();
      final downloadDir = await getDownloadsDirectory();

      if (filePath.startsWith(appDocDir.path)) {
        location = "App Storage";
        displayPath = filePath.replaceFirst(appDocDir.path, '');
      } else if (externalDir != null && filePath.startsWith(externalDir.path)) {
        location = "External Storage";
        displayPath = filePath.replaceFirst(externalDir.path, '');
      } else if (downloadDir != null && filePath.startsWith(downloadDir.path)) {
        location = "Downloads";
        displayPath = filePath.replaceFirst(downloadDir.path, '');
      }

      // Clean up the path
      if (displayPath.startsWith('/')) {
        displayPath = displayPath.substring(1);
      }
    } catch (e) {
      debugPrint('Error determining storage location: $e');
    }

    return {
      'location': location,
      'displayPath': displayPath,
      'fullPath': filePath,
    };
  }

  /// Open the file or share it if direct opening isn't possible
  static Future<void> openFileLocation(
    String filePath,
    BuildContext context,
  ) async {
    // Cache the l10n before any async operations
    final l10n = AppLocalizations.of(context)!;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        // Check if context is still valid after async operation
        if (!context.mounted) return;
        _showErrorDialog(context, l10n.error);
        return;
      }

      // First approach: try to open the file directly
      final uri = Uri.file(filePath);

      // Try opening the file with the default app
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        await launchUrl(uri);
        return;
      }

      // Check if context is still valid after async operations
      if (!context.mounted) return;

      // If direct opening fails, use the share functionality
      await Share.shareXFiles(
        [XFile(filePath)],
        text: l10n.exportShareMessage,
        subject: l10n.exportReportToCSV,
      );
    } catch (e) {
      debugPrint('Error opening file: $e');
      // Check if context is still valid after async operations
      if (!context.mounted) return;
      // Show a dialog explaining the issue
      _showLocationDialog(context, l10n, filePath);
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.error),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(l10n.okButton),
              ),
            ],
          ),
    );
  }

  static void _showLocationDialog(
    BuildContext context,
    AppLocalizations l10n,
    String filePath,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.error),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.exportFailure),
                const SizedBox(height: 12),
                Text(
                  l10n.fileStorageLocation(""),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    filePath,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(filePath)]);
                },
                child: Text(l10n.shareButton),
              ),
            ],
          ),
    );
  }
}
