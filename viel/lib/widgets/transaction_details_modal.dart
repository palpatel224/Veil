import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:flutter/services.dart';

class TransactionDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> tx) {
    final colorIndex = tx['color_index'] as int? ?? 0;
    final avatarColors = [AppColors.primaryAccent, Colors.purpleAccent, Colors.white24];
    final txColor = avatarColors[colorIndex % avatarColors.length];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: txColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_horiz, color: txColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                tx['title'] ?? 'Transaction',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tx['amount'] ?? '0.00',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              
              _buildDetailRow('Status', 'Completed', color: Colors.green),
              _buildDivider(),
              _buildDetailRow('Date', tx['date'] ?? 'Unknown'),
              _buildDivider(),
              _buildDetailRow('Network', tx['subtitle'] ?? 'Unknown'),
              _buildDivider(),
              
              if (tx['tx_hash'] != null && tx['tx_hash'].toString().isNotEmpty)
                _buildTxHashRow(context, tx['tx_hash'].toString()),
                
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mutedGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildDetailRow(String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _buildTxHashRow(BuildContext context, String hash) {
    final truncated = (hash.length > 12) 
        ? '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}'
        : hash;
        
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tx Hash', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: hash));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction hash copied'),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(bottom: 112, left: 24, right: 24),
                )
              );
            },
            child: Row(
              children: [
                Text(truncated, style: const TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.copy, size: 14, color: AppColors.primaryAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDivider() {
    return Divider(color: AppColors.mutedGrey.withValues(alpha: 0.2), height: 1);
  }
}
