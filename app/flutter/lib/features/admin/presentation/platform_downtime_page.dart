import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_dashboard_providers.dart';

class PlatformDowntimePage extends ConsumerStatefulWidget {
  const PlatformDowntimePage({super.key});

  @override
  ConsumerState<PlatformDowntimePage> createState() => _PlatformDowntimePageState();
}

class _PlatformDowntimePageState extends ConsumerState<PlatformDowntimePage> {
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  String _start = '21:00';
  String _end = '08:00';
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(adminApiClientProvider).getPlatformDowntime();
      if (!mounted) return;
      setState(() {
        _enabled = data['enabled'] == true;
        _start = data['startTime']?.toString() ?? '21:00';
        _end = data['endTime']?.toString() ?? '08:00';
        _messageController.text = data['message']?.toString() ?? '';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load downtime settings: $error')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminApiClientProvider).updatePlatformDowntime(
        enabled: _enabled,
        startTime: _start,
        endTime: _end,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downtime settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save downtime settings: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final source = start ? _start : _end;
    final parts = source.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? (start ? 21 : 8),
      minute: int.tryParse(parts.last) ?? 0,
    );
    final selected = await showTimePicker(context: context, initialTime: initial);
    if (selected == null || !mounted) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend downtime')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('Enable downtime'),
                    subtitle: const Text(
                      'Users can still sign in. Super Admin can always change this setting.',
                    ),
                    value: _enabled,
                    onChanged: _saving ? null : (value) => setState(() => _enabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Downtime starts'),
                        subtitle: Text(_start),
                        trailing: const Icon(Icons.schedule_rounded),
                        onTap: _saving ? null : () => _pickTime(start: true),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Downtime ends'),
                        subtitle: Text(_end),
                        trailing: const Icon(Icons.schedule_rounded),
                        onTap: _saving ? null : () => _pickTime(start: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Downtime message',
                    hintText: 'Optional message shown to users',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The setting is stored in Firestore and is not embedded into the app build. '
                  'Login and this configuration endpoint remain available while downtime is active.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save settings'),
                ),
              ],
            ),
    );
  }
}
