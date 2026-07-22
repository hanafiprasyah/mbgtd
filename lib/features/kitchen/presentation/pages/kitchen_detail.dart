import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_event.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_state.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tracks failed delete-confirmation attempts per kitchen and enforces a
/// 24-hour lockout after 3 wrong attempts. Stored locally on-device via
/// SharedPreferences (per-device, not synced across users/devices).
class _KitchenDeleteGuard {
  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(days: 1);

  static Future<int> getAttempts(String kitchenId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('kitchen_delete_attempts_$kitchenId') ?? 0;
  }

  static Future<void> setAttempts(String kitchenId, int attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kitchen_delete_attempts_$kitchenId', attempts);
  }

  static Future<DateTime?> getLockUntil(String kitchenId) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('kitchen_delete_lock_until_$kitchenId');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<void> lock(String kitchenId) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(lockDuration);
    await prefs.setInt(
      'kitchen_delete_lock_until_$kitchenId',
      until.millisecondsSinceEpoch,
    );
  }

  static Future<void> reset(String kitchenId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kitchen_delete_attempts_$kitchenId');
    await prefs.remove('kitchen_delete_lock_until_$kitchenId');
  }
}

class KitchenDetailScreen extends StatelessWidget {
  final String id;
  const KitchenDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KitchenBloc()..add(LoadKitchenDetail(id)),
      child: const _KitchenDetailView(),
    );
  }
}

class _KitchenDetailView extends StatelessWidget {
  const _KitchenDetailView();

  Future<void> _copyHeadId(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    GlobalScaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Head ID copied to clipboard.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _launchWhatsApp(BuildContext context, String rawNumber) async {
    var digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    // Normalize Indonesian local format (0812...) to international (62812...)
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }

    final uri = Uri.parse('https://wa.me/$digits');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      GlobalScaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    KitchenModel kitchen,
  ) async {
    final lockUntil = await _KitchenDeleteGuard.getLockUntil(kitchen.id);

    if (lockUntil != null && DateTime.now().isBefore(lockUntil)) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: Icon(
            Icons.lock_clock_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 32,
          ),
          title: const Text('Delete Locked'),
          content: Text(
            'Too many failed attempts. Please try again after '
            '${DateFormat('MMM d, y • HH:mm').format(lockUntil)}.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteConfirmationDialog(kitchen: kitchen),
    );

    if (confirmed == true && context.mounted) {
      context.read<KitchenBloc>().add(DeleteKitchen(kitchen.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<KitchenBloc, KitchenState>(
        listener: (context, state) {
          if (state is KitchenError) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          if (state is KitchenOperationSuccess) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 1),
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Kitchen Detail'),
                centerTitle: false,
                scrolledUnderElevation: 0,
                pinned: true,
              ),
              if (state is KitchenDetailLoading ||
                  state is KitchenInitial ||
                  state is KitchenOperationInProgress)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is KitchenError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: state.message),
                )
              else if (state is KitchenDetailLoaded)
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList.list(
                    children: [
                      _KitchenHeaderCard(kitchen: state.kitchen),
                      const SizedBox(height: AppSpacing.md),
                      _KitchenInfoCard(
                        kitchen: state.kitchen,
                        onCopyHeadId: () =>
                            _copyHeadId(context, state.kitchen.idKetua),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.kitchen.ketuaWaNumb != null &&
                          state.kitchen.ketuaWaNumb!.trim().isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _launchWhatsApp(
                              context,
                              state.kitchen.ketuaWaNumb!,
                            ),
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text('Contact via WhatsApp'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/kitchen-edit',
                              arguments: state.kitchen,
                            );
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Kitchen'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, state.kitchen),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: Text(
                            'Delete Kitchen',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _KitchenHeaderCard extends StatelessWidget {
  final KitchenModel kitchen;
  const _KitchenHeaderCard({required this.kitchen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = kitchen.name.isNotEmpty
        ? kitchen.name.characters.first.toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kitchen.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Head: ${kitchen.ketua}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        kitchen.id,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
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

class _KitchenInfoCard extends StatelessWidget {
  final KitchenModel kitchen;
  final VoidCallback onCopyHeadId;
  const _KitchenInfoCard({required this.kitchen, required this.onCopyHeadId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _infoTile(
            context,
            icon: Icons.badge_outlined,
            label: 'Head ID',
            value: kitchen.idKetua,
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy Head ID',
              onPressed: onCopyHeadId,
            ),
          ),
          if (kitchen.ketuaWaNumb != null &&
              kitchen.ketuaWaNumb!.trim().isNotEmpty) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            _infoTile(
              context,
              icon: Icons.chat_outlined,
              label: 'WhatsApp Number',
              value: kitchen.ketuaWaNumb!,
            ),
          ],
          Divider(height: 1, color: colorScheme.outlineVariant),
          _infoTile(
            context,
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: kitchen.address,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog requiring the user to re-type the kitchen's Doc ID to confirm
/// deletion. Tracks wrong attempts and triggers a 24-hour lock after 3.
class _DeleteConfirmationDialog extends StatefulWidget {
  final KitchenModel kitchen;
  const _DeleteConfirmationDialog({required this.kitchen});

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  int _attempts = 0;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final attempts = await _KitchenDeleteGuard.getAttempts(widget.kitchen.id);
    if (!mounted) return;
    setState(() {
      _attempts = attempts;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final input = _controller.text.trim();

    if (input == widget.kitchen.id) {
      await _KitchenDeleteGuard.reset(widget.kitchen.id);
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    setState(() => _submitting = true);

    final newAttempts = _attempts + 1;

    if (newAttempts >= _KitchenDeleteGuard.maxAttempts) {
      await _KitchenDeleteGuard.lock(widget.kitchen.id);
      await _KitchenDeleteGuard.reset(widget.kitchen.id);
      if (!mounted) return;
      Navigator.pop(context, false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: Icon(
            Icons.lock_clock_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 32,
          ),
          title: const Text('Delete Locked'),
          content: const Text(
            'You entered the wrong Doc ID 3 times. Deletion is now '
            'locked for 24 hours.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await _KitchenDeleteGuard.setAttempts(widget.kitchen.id, newAttempts);
    if (!mounted) return;
    setState(() {
      _attempts = newAttempts;
      _submitting = false;
      _errorText =
          'Doc ID does not match. '
          '${_KitchenDeleteGuard.maxAttempts - newAttempts} attempt(s) left.';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = _KitchenDeleteGuard.maxAttempts - _attempts;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 32,
      ),
      title: const Text('Delete Kitchen'),
      content: _loading
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone. Type the Doc ID '
                  '"${widget.kitchen.id}" below to confirm deletion.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Doc ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _handleConfirm(),
                ),
                const SizedBox(height: 8),
                Text(
                  '$remaining attempt(s) left before a 24-hour lock.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_loading || _submitting) ? null : _handleConfirm,
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
