import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/events_provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/models/diabetes_event.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Add Event Screen
/// Matches the design from reference images
/// 
/// TODO: [PLACEHOLDER] Add form validation
/// TODO: [PLACEHOLDER] Add date/time picker
/// TODO: [PLACEHOLDER] Save events to Firebase
class AddEventScreen extends StatelessWidget {
  const AddEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with drag handle
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Dodaj zdarzenie',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Profile avatar placeholder
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            
            // Event Types List
            Expanded(
              child: ListView(
                children: EventType.values.map((type) {
                  return _EventTypeItem(
                    type: type,
                    onTap: () => _showEventForm(context, type),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventForm(BuildContext context, EventType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EventFormSheet(eventType: type),
    );
  }
}

class _EventTypeItem extends StatelessWidget {
  final EventType type;
  final VoidCallback onTap;

  const _EventTypeItem({
    required this.type,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case EventType.bloodGlucose:
        return Icons.bloodtype_outlined;
      case EventType.insulin:
        return Icons.medication_outlined;
      case EventType.meal:
        return Icons.restaurant_outlined;
      case EventType.activity:
        return Icons.directions_run;
      case EventType.fastingGlucose:
        return Icons.wb_sunny_outlined;
      case EventType.note:
        return Icons.edit_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getIcon(), color: AppTheme.textSecondary),
      ),
      title: Text(
        type.label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        type.description,
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.secondaryColor, width: 2),
        ),
        child: const Icon(
          Icons.add,
          color: AppTheme.secondaryColor,
          size: 20,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _EventFormSheet extends StatefulWidget {
  final EventType eventType;

  const _EventFormSheet({required this.eventType});

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.eventType.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Value input based on event type
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _getValueLabel(),
                  suffixText: _getValueUnit(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać wartość';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notatka (opcjonalnie)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text('Zapisz'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getValueLabel() {
    switch (widget.eventType) {
      case EventType.bloodGlucose:
      case EventType.fastingGlucose:
        return 'Poziom glukozy';
      case EventType.insulin:
        return 'Dawka insuliny';
      case EventType.meal:
        return 'Węglowodany';
      case EventType.activity:
        return 'Czas trwania';
      case EventType.note:
        return 'Treść notatki';
    }
  }

  String _getValueUnit() {
    switch (widget.eventType) {
      case EventType.bloodGlucose:
      case EventType.fastingGlucose:
        return 'mg/dL';
      case EventType.insulin:
        return 'jednostki';
      case EventType.meal:
        return 'g';
      case EventType.activity:
        return 'min';
      case EventType.note:
        return '';
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final events = context.read<EventsProvider>();
      
      // TODO: [PLACEHOLDER] Proper data structure based on event type
      final event = DiabetesEvent(
        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
        patientId: auth.currentUser?.id ?? 'unknown',
        type: widget.eventType,
        timestamp: DateTime.now(),
        data: {'value': double.tryParse(_valueController.text) ?? 0},
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      events.addEvent(event);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zdarzenie zapisane')),
      );
    }
  }
}
