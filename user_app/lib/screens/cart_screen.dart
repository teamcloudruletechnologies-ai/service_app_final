import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _qty = 1;
  bool _addonPipe = true;
  bool _addonTank = true;

  @override
  Widget build(BuildContext context) {
    final basePrice = 499 * _qty;
    final pipePrice = _addonPipe ? 250 : 0;
    final tankPrice = _addonTank ? 500 : 0;
    final total = basePrice + pipePrice + tankPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Service Item Card (Screen 21 Mockup)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.plumbing_rounded, size: 28, color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Plumbing Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 2),
                                Text('Tap Leakage Fix', style: TextStyle(fontSize: 13, color: Color(0xFF718096))),
                              ],
                            ),
                          ),
                          // Quantity counter (- 1 +)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_qty > 1) setState(() => _qty--);
                                  },
                                  icon: const Icon(Icons.remove, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                                Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                IconButton(
                                  onPressed: () => setState(() => _qty++),
                                  icon: const Icon(Icons.add, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add-on Services Checkboxes (Screen 21 Mockup)
                    const Text('Add-on Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _addonPipe,
                            onChanged: (val) => setState(() => _addonPipe = val ?? false),
                            activeColor: AppTheme.primary,
                            checkColor: const Color(0xFF1A1A1A),
                            title: const Text('Pipe Replacement', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('+ ₹250', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          CheckboxListTile(
                            value: _addonTank,
                            onChanged: (val) => setState(() => _addonTank = val ?? false),
                            activeColor: AppTheme.primary,
                            checkColor: const Color(0xFF1A1A1A),
                            title: const Text('Water Tank Cleaning', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('+ ₹500', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Total & Continue Button (Screen 21 Mockup)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
                      Text('₹$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: const Color(0xFF1A1A1A),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
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
