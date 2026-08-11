import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class WorkerServiceSkillsScreen extends StatefulWidget {
  const WorkerServiceSkillsScreen({super.key});

  @override
  State<WorkerServiceSkillsScreen> createState() => _WorkerServiceSkillsScreenState();
}

class _WorkerServiceSkillsScreenState extends State<WorkerServiceSkillsScreen> {
  bool _saving = false;

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Home Cleaning',
      'level': 'Expert',
      'icon': Icons.cleaning_services_rounded,
      'badgeColor': const Color(0xFFDCFCE7),
      'textColor': const Color(0xFF15803D),
    },
    {
      'title': 'Plumbing',
      'level': 'Intermediate',
      'icon': Icons.plumbing_rounded,
      'badgeColor': const Color(0xFFFFEDD5),
      'textColor': const Color(0xFFC2410C),
    },
    {
      'title': 'Electrical Work',
      'level': 'Advanced',
      'icon': Icons.electric_bolt_rounded,
      'badgeColor': const Color(0xFFE0E7FF),
      'textColor': const Color(0xFF4338CA),
    },
    {
      'title': 'Appliance Repair',
      'level': 'Basic',
      'icon': Icons.home_repair_service_rounded,
      'badgeColor': const Color(0xFFF3E8FF),
      'textColor': const Color(0xFF6B21A8),
    },
  ];

  final List<String> _skills = [
    'Time Management',
    'Customer Handling',
    'Hard Working',
    'Problem Solving',
  ];

  void _addNewServiceModal() {
    final titleCtrl = TextEditingController();
    String selectedLevel = 'Expert';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add New Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Service Name (e.g. AC Repair)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Skill Level',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Expert', child: Text('Expert')),
                      DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                      DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'Basic', child: Text('Basic')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedLevel = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final name = titleCtrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() {
                        _services.add({
                          'title': name,
                          'level': selectedLevel,
                          'icon': Icons.build_rounded,
                          'badgeColor': const Color(0xFFEFF6FF),
                          'textColor': const Color(0xFF1D4ED8),
                        });
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addSkillModal() {
    final skillCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Skill Tag', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: skillCtrl,
          decoration: const InputDecoration(hintText: 'Enter skill (e.g. Quick Repair)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = skillCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() => _skills.add(text));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.serviceType != null && user!.serviceType!.isNotEmpty) {
      final types = user.serviceType!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (types.isNotEmpty) {
        _services.clear();
        for (var t in types) {
          _services.add({
            'title': t,
            'level': 'Expert',
            'icon': _getIconForService(t),
            'badgeColor': const Color(0xFFDCFCE7),
            'textColor': const Color(0xFF15803D),
          });
        }
      }
    }
  }

  IconData _getIconForService(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electr')) return Icons.electric_bolt_rounded;
    if (lower.contains('appliance') || lower.contains('repair')) return Icons.home_repair_service_rounded;
    return Icons.build_rounded;
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final selectedTitles = _services.map((s) => s['title'] as String).toList();
      final serviceTypeStr = selectedTitles.join(', ');

      final api = context.read<ApiService>();
      await api.updateWorkerProfile(
        serviceType: serviceTypeStr.isNotEmpty ? serviceTypeStr : 'General Service',
      );

      if (mounted) {
        await context.read<AuthProvider>().reloadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Services updated: ${serviceTypeStr.isNotEmpty ? serviceTypeStr : "General Service"} 🛠️'),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Service & Skills',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ─── 1. YOUR SERVICES SECTION (EDITABLE) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_services.length} selected',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ..._services.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item['icon'] as IconData, size: 20, color: const Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'Delete') {
                                setState(() => _services.removeAt(idx));
                              } else {
                                setState(() => item['level'] = val);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'Expert', child: Text('Level: Expert')),
                              const PopupMenuItem(value: 'Advanced', child: Text('Level: Advanced')),
                              const PopupMenuItem(value: 'Intermediate', child: Text('Level: Intermediate')),
                              const PopupMenuItem(value: 'Basic', child: Text('Level: Basic')),
                              const PopupMenuDivider(),
                              const PopupMenuItem(value: 'Delete', child: Text('Delete Service', style: TextStyle(color: Colors.red))),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item['badgeColor'] as Color? ?? const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['level'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: item['textColor'] as Color? ?? const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: _addNewServiceModal,
                    icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF0F172A)),
                    label: const Text(
                      'Add New Service',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── 2. SKILLS SECTION (EDITABLE CHIPS) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSkillModal,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF0F172A)),
                  label: const Text('Add Tag', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 12.5)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _skills.map((skill) {
                return InputChip(
                  label: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  ),
                  deleteIcon: const Icon(Icons.cancel, size: 16, color: Color(0xFF94A3B8)),
                  onDeleted: () {
                    setState(() => _skills.remove(skill));
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ─── 3. SAVE CHANGES BUTTON ───
            ElevatedButton(
              onPressed: _saving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // Black Primary Theme Button
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _saving ? 'Saving...' : 'Save Services & Skills',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
