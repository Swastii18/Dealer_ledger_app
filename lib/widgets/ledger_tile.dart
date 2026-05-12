import 'package:flutter/material.dart';
import '../models/ledger_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class LedgerTile extends StatelessWidget {
  final LedgerModel entry;
  final VoidCallback onDelete;

  const LedgerTile({super.key, required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDebit = entry.debit > 0;
    final amount = isDebit ? entry.debit : entry.credit;
    final color = isDebit ? AppTheme.debitColor : AppTheme.creditColor;
    final icon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isDebit ? 'Bill' : entry.paymentType.toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.billNo.isNotEmpty ? 'Bill #${entry.billNo}' : label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Text(
              '${isDebit ? '+' : '-'}${fmtAmount(amount)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(entry.date,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (entry.remarks.isNotEmpty) ...[
              const Text(' · ', style: TextStyle(color: Colors.grey)),
              Expanded(
                child: Text(entry.remarks,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
            const Spacer(),
            Text('Bal: ${fmtAmount(entry.runningTotal)}',
                style: TextStyle(
                    fontSize: 11,
                    color: entry.runningTotal > 0
                        ? AppTheme.debitColor
                        : AppTheme.creditColor)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
