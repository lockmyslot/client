import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/booking_details_form.dart';
import '../../resources/providers/resources_provider.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;

  const AvailabilityScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
  });

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(resourceDetailProvider((groupId: widget.groupId, resourceId: widget.resourceId)));

    return Scaffold(
      appBar: AppBar(
        title: resourceAsync.when(
          data: (res) => Text('Book ${res.name}'),
          loading: () => const Text('Book Resource'),
          error: (_, __) => const Text('Book Resource'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BookingDetailsForm(
        groupId: widget.groupId,
        resourceId: widget.resourceId,
      ),
    );
  }
}