import 'package:flutter/material.dart';
import 'package:optimind/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> updateData;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.updateData,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final latestVersion = updateData['latest_version'] ?? '';
    final mandatory = updateData['mandatory'] ?? false;
    final releaseNotes = List<String>.from(updateData['release_notes'] ?? []);

    return PopScope(
      canPop: !mandatory,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.system_update_alt_rounded,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Update Available',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Version $latestVersion is available.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),

              const SizedBox(height: 20),

              Text(
                "What's New",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),

              const SizedBox(height: 10),

              ...releaseNotes.map(
                    (note) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text("• "),
                      Expanded(
                        child: Text(note),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!mandatory)
            TextButton(
              onPressed: onLater,
              child: const Text("Later"),
            ),

          Consumer<AuthProvider>(
            builder: (context, provider, _) {

              if (provider.isDownloading) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value:
                      provider.downloadProgress,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${(provider.downloadProgress * 100).toStringAsFixed(0)}%",
                    ),
                  ],
                );
              }

              return ElevatedButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.download),
                label: const Text("Update"),
              );
            },
          )
        ],
      ),
    );
  }
}