import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker_web/image_picker_web.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/utils.dart';
import '../../models/athlete_model.dart';
import '../../providers/athlete_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/load_more_indicator.dart';

class AthletesListScreen extends StatefulWidget {
  const AthletesListScreen({super.key});
  @override
  State<AthletesListScreen> createState() => _AthletesListScreenState();
}

class _AthletesListScreenState extends State<AthletesListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<AthleteProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AthleteProvider>();
    final auth = context.watch<AuthProvider>();
    final filtered = provider.athletes.where((a) => a.fullName.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Athletes', style: Theme.of(context).textTheme.displaySmall).animate().fadeIn(),
              if (auth.isManager) GradientButton(label: 'Add Athlete', icon: Icons.person_add, onPressed: () => _showForm(context)),
            ]),
            const SizedBox(height: 20),
            AppSearchBar(controller: _searchCtrl, hintText: 'Search athletes...', onChanged: (v) => setState(() => _search = v)),
            const SizedBox(height: 20),
            Expanded(
              child: provider.isLoading
                  ? ShimmerLoader.list()
                  : filtered.isEmpty
                      ? EmptyState(icon: Icons.people_outlined, title: 'No Athletes Found', subtitle: _search.isEmpty ? 'Add your first athlete to get started' : 'No athletes match your search', actionLabel: _search.isEmpty && auth.isManager ? 'Add Athlete' : null, onAction: _search.isEmpty && auth.isManager ? () => _showForm(context) : null)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, i) {
                            if (i == filtered.length) {
                              return LoadMoreIndicator(
                                isLoadingMore: provider.isLoadingMore,
                                hasMore: provider.hasMore && _search.isEmpty,
                                onLoadMore: () => provider.loadMore(),
                              );
                            }
                            final a = filtered[i];
                            return _AthleteCard(athlete: a, canManage: auth.isManager, onEdit: () => _showForm(context, athlete: a), onDelete: () => _confirmDelete(context, a))
                                .animate(delay: Duration(milliseconds: i * 60))
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.05, duration: 400.ms);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {AthleteModel? athlete}) {
    final isEdit = athlete != null;
    final firstCtrl = TextEditingController(text: athlete?.firstName ?? '');
    final lastCtrl = TextEditingController(text: athlete?.lastName ?? '');
    final ageCtrl = TextEditingController(text: athlete != null ? athlete.age.toString() : '');
    final barangayCtrl = TextEditingController(text: athlete?.barangay ?? '');
    final contactCtrl = TextEditingController(text: athlete?.contactNumber ?? '');
    final emailCtrl = TextEditingController(text: athlete?.email ?? '');
    Gender gender = athlete?.gender ?? Gender.male;
    final formKey = GlobalKey<FormState>();

    Uint8List? pickedImageBytes;
    String? existingPhotoUrl = athlete?.photoUrl;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        title: Text(isEdit ? 'Edit Athlete' : 'Add Athlete'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Photo Picker
                GestureDetector(
                  onTap: () async {
                    final bytes = await ImagePickerWeb.getImageAsBytes();
                    if (bytes != null) {
                      setDialogState(() => pickedImageBytes = bytes);
                    }
                  },
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentCyan.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3), width: 2),
                      image: pickedImageBytes != null
                          ? DecorationImage(image: MemoryImage(pickedImageBytes!), fit: BoxFit.cover)
                          : existingPhotoUrl != null
                              ? DecorationImage(image: NetworkImage(existingPhotoUrl), fit: BoxFit.cover)
                              : null,
                    ),
                    child: pickedImageBytes == null && existingPhotoUrl == null
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.camera_alt_outlined, color: AppTheme.accentCyan, size: 22),
                            Text('Photo', style: TextStyle(color: AppTheme.accentCyan, fontSize: 9)),
                          ])
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextFormField(controller: firstCtrl, validator: (v) => AppUtils.validateRequired(v, 'First name'), decoration: const InputDecoration(labelText: 'First Name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: lastCtrl, validator: (v) => AppUtils.validateRequired(v, 'Last name'), decoration: const InputDecoration(labelText: 'Last Name'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) { if (v == null || v.isEmpty) return null; final age = int.tryParse(v); if (age == null || age < 5 || age > 100) return 'Age must be 5–100'; return null; },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<Gender>(initialValue: gender, decoration: const InputDecoration(labelText: 'Gender'), items: Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(), onChanged: (v) => setDialogState(() => gender = v!))),
                ]),
                const SizedBox(height: 12),
                TextFormField(controller: barangayCtrl, decoration: const InputDecoration(labelText: 'Barangay')),
                const SizedBox(height: 12),
                TextFormField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Number')),
                const SizedBox(height: 12),
                TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (optional)')),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: uploading ? null : () async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() => uploading = true);

              final athleteProvider = context.read<AthleteProvider>();
              final rootContext = context;
              String? photoUrl = existingPhotoUrl;

              // Upload photo if picked
              if (pickedImageBytes != null) {
                try {
                  photoUrl = await StorageService().uploadImage(
                    bytes: pickedImageBytes!,
                    path: AppConstants.athletePhotosPath,
                  );
                } catch (e) {
                  if (ctx.mounted) {
                    setDialogState(() => uploading = false);
                    AppUtils.showError(ctx, 'Photo upload failed: $e');
                    return;
                  }
                }
              }


              final data = {
                'firstName': firstCtrl.text.trim(),
                'lastName': lastCtrl.text.trim(),
                'age': int.tryParse(ageCtrl.text) ?? 0,
                'gender': gender.name,
                'barangay': barangayCtrl.text.trim(),
                'contactNumber': contactCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'photoUrl': photoUrl,
              };

              if (isEdit) {
                await athleteProvider.updateAthlete(athlete.id, data);
              } else {
                await athleteProvider.addAthlete(AthleteModel(
                  id: '',
                  firstName: firstCtrl.text.trim(),
                  lastName: lastCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text) ?? 0,
                  gender: gender,
                  barangay: barangayCtrl.text.trim(),
                  contactNumber: contactCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  photoUrl: photoUrl,
                  createdAt: DateTime.now(),
                ));
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (rootContext.mounted) {
                AppUtils.showSuccess(rootContext, isEdit ? 'Athlete updated' : 'Athlete added');
              }
            },
            child: uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      )),
    );
  }

  void _confirmDelete(BuildContext context, AthleteModel a) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Athlete'),
      content: Text('Delete ${a.fullName}? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed), onPressed: () async {
          final athleteProvider = context.read<AthleteProvider>();
          final rootContext = context;
          // Delete photo if exists
          if (a.photoUrl != null) {
            try { await StorageService().deleteImage(a.photoUrl!); } catch (_) {}
          }

          await athleteProvider.deleteAthlete(a.id);
          if (ctx.mounted) {
            Navigator.pop(ctx);
          }
          if (rootContext.mounted) {
            AppUtils.showSuccess(rootContext, 'Athlete deleted');
          }
        }, child: const Text('Delete')),
      ],
    ));
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteModel athlete;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AthleteCard({required this.athlete, required this.canManage, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        AvatarBadge(name: athlete.fullName, imageUrl: athlete.photoUrl, size: 44),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(athlete.fullName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('${athlete.gender.label} • Age ${athlete.age} • ${athlete.barangay}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        if (canManage) IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted), onPressed: onEdit),
        if (canManage) IconButton(icon: const Icon(Icons.delete_outlined, size: 18, color: AppTheme.accentRed), onPressed: onDelete),
      ]),
    );
  }
}
