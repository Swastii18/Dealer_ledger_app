import 'package:flutter/material.dart';
import '../models/dealer_model.dart';
import '../theme/app_theme.dart';

class DealerCard extends StatelessWidget {
  final DealerModel dealer;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DealerCard({
    super.key,
    required this.dealer,
    required this.balance,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = balance > 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  dealer.name.isNotEmpty
                      ? dealer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dealer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (dealer.phone.isNotEmpty)
                      Text(dealer.phone,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDue ? AppTheme.debitColor : AppTheme.creditColor,
                    ),
                  ),
                  Text(isDue ? 'Due' : 'Settled',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              isDue ? AppTheme.debitColor : AppTheme.creditColor)),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
