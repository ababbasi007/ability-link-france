import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/billing.dart';
import '../../services/background_task.dart';
import '../../services/billing_service.dart';
import '../../theme/app_colors.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _billing = BillingService();

  @override
  void initState() {
    super.initState();
    runInBackground(_billing.ensureSeeded(), 'seed billing plans');
  }

  @override
  Widget build(BuildContext context) {
    final body = _BillingBody(billing: _billing);
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Billing & plans',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: body,
    );
  }
}

class _BillingBody extends StatelessWidget {
  const _BillingBody({required this.billing});

  final BillingService billing;

  Future<void> _addMethod(BuildContext context) async {
    final brand = TextEditingController(text: 'Visa');
    final last4 = TextEditingController();
    final label = TextEditingController();
    var kind = 'card';
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add payment method',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sandbox only — last 4 digits, never a full card number.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: kind,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(
                          value: 'wallet',
                          child: Text('Wallet'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => kind = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: brand,
                      decoration: const InputDecoration(
                        labelText: 'Brand (Visa, Mastercard, Wallet…)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: last4,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Last 4 digits',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: label,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Save method'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (ok != true) return;
      await billing.addMethod(
        brand: brand.text,
        last4: last4.text,
        kind: kind,
        label: label.text,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      brand.dispose();
      last4.dispose();
      label.dispose();
    }
  }

  Future<void> _showReceipt(BuildContext context, Invoice inv) async {
    final text = inv.receiptText();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Receipt ${inv.receiptNumber}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Receipt copied')));
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _refund(BuildContext context, Invoice inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund this charge?'),
        content: Text(
          'Sandbox refund of ${inv.amountLabel} for ${inv.description}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await billing.refundInvoice(inv.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Refunded (sandbox)')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BillingSubscription?>(
      stream: billing.watchMySubscription(),
      builder: (context, subSnap) {
        return StreamBuilder<List<BillingPlan>>(
          stream: billing.watchPlans(),
          builder: (context, planSnap) {
            return StreamBuilder<List<Invoice>>(
              stream: billing.watchMyInvoices(),
              builder: (context, invSnap) {
                return StreamBuilder<List<SavedPaymentMethod>>(
                  stream: billing.watchMethods(),
                  builder: (context, methodSnap) {
                    final sub = subSnap.data;
                    final plans = planSnap.data ?? const <BillingPlan>[];
                    final invoices = invSnap.data ?? const <Invoice>[];
                    final methods =
                        methodSnap.data ?? const <SavedPaymentMethod>[];
                    final due = invoices
                        .where((i) => i.status == 'due')
                        .toList();
                    final paid = invoices
                        .where((i) => i.status == 'paid')
                        .length;
                    final refunded = invoices
                        .where((i) => i.status == 'refunded')
                        .length;
                    final leadFees = invoices
                        .where((i) => i.type == 'lead_fee')
                        .fold<int>(0, (s, i) => s + i.amountCents);
                    final commissions = invoices
                        .where((i) => i.type == 'commission')
                        .fold<int>(0, (s, i) => s + i.amountCents);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        Text(
                          sub != null && sub.isActive
                              ? '${sub.planName} · active'
                              : 'No paid plan yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (sub != null)
                          Text(
                            'Renews ${sub.periodEnd.toLocal().toString().split(' ').first}'
                            '${sub.isActive ? '' : ' · canceled'}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Sandbox gateway only — we never collect full card numbers. Charges use the default method last 4.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Kpi(label: 'Due', value: '${due.length}'),
                            _Kpi(label: 'Paid', value: '$paid'),
                            _Kpi(label: 'Refunds', value: '$refunded'),
                            _Kpi(
                              label: 'Fees',
                              value:
                                  '\$${((leadFees + commissions) / 100).toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                        if (sub != null && sub.isActive) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => billing.cancelSubscription(sub.id),
                            child: const Text('Cancel subscription'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Payment methods',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _addMethod(context),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        if (methods.isEmpty)
                          Text(
                            'A sandbox Visa ••4242 is created on first visit.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          for (final m in methods)
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  m.kind == 'wallet'
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.credit_card,
                                  color: AppColors.primary,
                                ),
                                title: Text(m.displayLabel),
                                subtitle: Text(
                                  m.isDefault
                                      ? 'Default · sandbox'
                                      : 'Tap to set default',
                                ),
                                onTap: () => billing.setDefaultMethod(m.id),
                                trailing: IconButton(
                                  tooltip: 'Remove payment method',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => billing.deleteMethod(m.id),
                                ),
                              ),
                            ),
                        const SizedBox(height: 8),
                        Text(
                          'SaaS plans',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final p in plans)
                          Card(
                            child: ListTile(
                              title: Text('${p.name} · ${p.priceLabel}'),
                              subtitle: Text(
                                '${p.summary}\n${p.features.join(' · ')}',
                              ),
                              isThreeLine: true,
                              trailing: TextButton(
                                onPressed: () async {
                                  await billing.subscribe(p);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${p.name} selected. Pay the invoice below.',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Choose'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Invoices & receipts',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (invoices.isEmpty)
                          Text(
                            'No invoices yet. Book assistance, telehealth, rehab, or hire a caregiver with Pay now.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          for (final inv in invoices)
                            Card(
                              child: ListTile(
                                title: Text('${inv.amountLabel} · ${inv.type}'),
                                subtitle: Text(
                                  '${inv.description}\n${inv.status}'
                                  '${inv.last4.isEmpty ? '' : ' · ••${inv.last4}'}'
                                  '\n${inv.receiptNumber}',
                                ),
                                isThreeLine: true,
                                trailing: inv.status == 'due'
                                    ? TextButton(
                                        onPressed: () =>
                                            billing.payInvoice(inv.id),
                                        child: const Text('Pay'),
                                      )
                                    : PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'receipt') {
                                            _showReceipt(context, inv);
                                          }
                                          if (v == 'refund') {
                                            _refund(context, inv);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'receipt',
                                            child: Text('View receipt'),
                                          ),
                                          if (inv.status == 'paid')
                                            const PopupMenuItem(
                                              value: 'refund',
                                              child: Text('Refund'),
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
