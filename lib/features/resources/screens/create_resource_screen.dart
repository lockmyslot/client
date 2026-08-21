import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/resources_repository.dart';
import '../providers/resources_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/loading_overlay.dart';

class CreateResourceScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateResourceScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<CreateResourceScreen> createState() => _CreateResourceScreenState();
}

class _CreateResourceScreenState extends ConsumerState<CreateResourceScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController(text: '1');
  final _slotDurationController = TextEditingController(text: '60');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 1;
    final slotDurationMinutes = int.tryParse(_slotDurationController.text.trim()) ?? 60;

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a resource name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(resourcesRepositoryProvider);
      final newResource = await repo.createResource(
        widget.groupId,
        name: name,
        description: description.isNotEmpty ? description : null,
        capacity: capacity,
        slotDurationMinutes: slotDurationMinutes,
      );

      ref.invalidate(groupResourcesProvider(widget.groupId));

      if (mounted) {
        context.go('/groups/${widget.groupId}/resources/${newResource.id}');
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
      appBar: AppBar(
        title: const Text('Add Resource'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('New Resource').h3(),
                    const SizedBox(height: 4),
                    const Text('Define a bookable resource like a room, court, or equipment.')
                        .muted()
                        .small(),
                    const SizedBox(height: 24),
                    const Text('Resource Name').small().semiBold(),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Washing Machine 1, Conference Room A',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Description (optional)').small().semiBold(),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Located on 2nd floor, includes whiteboard',
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
                                decoration: const InputDecoration(hintText: '1'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Slot Duration (min)').small().semiBold(),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _slotDurationController,
                                decoration: const InputDecoration(hintText: '60'),
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
                      child: const Text('Save Resource'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
