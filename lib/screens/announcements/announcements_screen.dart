import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/enums.dart';
import '../../core/utils.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/other_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_button.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().markAnnouncementsSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Announcements', style: Theme.of(context).textTheme.displaySmall).animate().fadeIn(),
          if (auth.isManager) GradientButton(label: 'New Announcement', icon: Icons.add, onPressed: () => _showForm(context)),
        ]),
        const SizedBox(height: 20),
        Expanded(child: provider.announcements.isEmpty
            ? const EmptyState(icon: Icons.campaign_outlined, title: 'No Announcements', subtitle: 'Create announcements to keep everyone informed')
            : ListView.builder(itemCount: provider.announcements.length, itemBuilder: (_, i) {
                final a = provider.announcements[i];
                final priorityColor = a.priority == AnnouncementPriority.urgent ? AppTheme.accentRed : a.priority == AnnouncementPriority.high ? AppTheme.accentOrange : AppTheme.accentCyan;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(AppTheme.radiusLg), border: Border.all(color: AppTheme.border), boxShadow: a.priority == AnnouncementPriority.urgent ? [BoxShadow(color: AppTheme.accentRed.withValues(alpha: 0.1), blurRadius: 12)] : null),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 4, height: 32, decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(a.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Text(a.priority.label, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w600))),
                      if (auth.isManager) IconButton(icon: const Icon(Icons.delete_outlined, size: 18, color: AppTheme.accentRed), onPressed: () async { await context.read<AnnouncementProvider>().deleteAnnouncement(a.id); }),
                    ]),
                    const SizedBox(height: 12),
                    Text(a.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 12),
                    Text('${a.authorName ?? 'Unknown'} • ${AppUtils.timeAgo(a.createdAt)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ]),
                ).animate(delay: Duration(milliseconds: i * 80)).fadeIn(duration: 400.ms);
              })),
      ])),
    );
  }

  void _showForm(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    AnnouncementPriority priority = AnnouncementPriority.normal;
    final auth = context.read<AuthProvider>();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: const Text('New Announcement'),
      content: SizedBox(width: 500, child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: titleCtrl, validator: (v) => AppUtils.validateRequired(v, 'Title'), decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 12),
        DropdownButtonFormField<AnnouncementPriority>(initialValue: priority, decoration: const InputDecoration(labelText: 'Priority'), items: AnnouncementPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(), onChanged: (v) => setDialogState(() => priority = v!)),
        const SizedBox(height: 12),
        TextFormField(controller: bodyCtrl, maxLines: 5, validator: (v) => AppUtils.validateRequired(v, 'Content'), decoration: const InputDecoration(labelText: 'Content', alignLabelWithHint: true)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          await context.read<AnnouncementProvider>().addAnnouncement(AnnouncementModel(id: '', title: titleCtrl.text.trim(), body: bodyCtrl.text.trim(), authorId: auth.user!.uid, authorName: auth.user!.displayName, priority: priority, createdAt: DateTime.now()));
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) AppUtils.showSuccess(context, 'Announcement posted');
        }, child: const Text('Post')),
      ],
    )));
  }
}
