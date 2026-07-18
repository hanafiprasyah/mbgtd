import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';

Widget buildInfoCard(List<Widget> children) {
  return Card(
    elevation: AppElevation.low,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(children: children),
    ),
  );
}

Widget buildInfoItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget buildBankInfoItem(BuildContext context, String bank, String noRek) {
  String getBankAsset(String bank) {
    switch (bank.toUpperCase()) {
      case 'BCA':
        return 'assets/bca.png';

      case 'BNI':
        return 'assets/bni.png';

      case 'BRI':
        return 'assets/bri.png';

      case 'MANDIRI':
        return 'assets/mandiri.png';

      case 'CIMB':
        return 'assets/cimb.png';

      case 'OCBC NISP':
        return 'assets/ocbc_nisp.png';

      case 'MAYBANK':
        return 'assets/maybank.png';

      default:
        return 'assets/default_bank.png';
    }
  }

  String assetPath = getBankAsset(bank);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bank Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            assetPath,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Logo not found: $assetPath');
              return Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.account_balance, size: 20),
              );
            },
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Bank + Account Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bank.isEmpty ? 'Unregistered' : bank,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                noRek.isEmpty ? 'Unknown' : noRek,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),

        // Copy Button
        IconButton(
          onPressed: noRek.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: noRek));
                  GlobalScaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Account number copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    ),
  );
}
