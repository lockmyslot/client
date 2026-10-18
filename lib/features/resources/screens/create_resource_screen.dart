import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/resources_repository.dart';
import '../providers/resources_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/loading_overlay.dart';

class CreateResourceScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateResourceScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateResourceScreen> createState() =>
      _CreateResourceScreenState();
}

class _CreateResourceScreenState extends ConsumerState<CreateResourceScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '60');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Resource name is required');
      return;
    }

    final capacity = int.tryParse(_capacityController.text) ?? 1;
    final duration = int.tryParse(_durationController.text) ?? 60;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(resourcesRepositoryProvider);
      await repo.createResource(
        widget.groupId,
        name: name,
        description: _descController.text.trim(),
        capacity: capacity,
        slotDurationMinutes: duration,
      );
      ref.invalidate(groupResourcesProvider(widget.groupId));

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar.large(
              title: Text('Add Resource'),
              pinned: true,
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Entrance(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('New Resource').h3(),
                          const SizedBox(height: 4),
                          const Text(
                            'Define a bookable resource like a room, court, or equipment.',
                          ).muted().small(),
                          const SizedBox(height: 24),
                          const Text('Resource Name').small().semiBold(),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Conference Room A, Court 1',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Description (Optional)')
                              .small()
                              .semiBold(),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              hintText: 'Brief details about availability',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Capacity').small().semiBold(),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _capacityController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '1',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Slot Duration (m)')
                                        .small()
                                        .semiBold(),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _durationController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '60',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ).small(),
                          ],
                          const SizedBox(height: 24),
                          PrimaryButton(
                            onPressed: _handleCreate,
                            child: const Text('Create Resource'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
