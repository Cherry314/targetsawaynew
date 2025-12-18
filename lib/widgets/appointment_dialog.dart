// lib/widgets/appointment_dialog.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment_entry.dart';
import '../services/notification_service.dart';

class AppointmentDialog extends StatefulWidget {
  final DateTime selectedDate;
  final AppointmentEntry? appointment; // null for new, existing for edit

  const AppointmentDialog({
    super.key,
    required this.selectedDate,
    this.appointment,
  });

  @override
  State<AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDateTime;
  late TimeOfDay _selectedTime;
  bool _notifyOneDay = false;
  bool _notifyOneWeek = false;

  @override
  void initState() {
    super.initState();

    if (widget.appointment != null) {
      // Edit mode - populate with existing data
      _titleController.text = widget.appointment!.title;
      _descriptionController.text = widget.appointment!.description;
      _selectedDateTime = widget.appointment!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment!.dateTime);
      _notifyOneDay = widget.appointment!.notifyOneDay;
      _notifyOneWeek = widget.appointment!.notifyOneWeek;
    } else {
      // New appointment mode
      _selectedDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        9,
        0,
      );
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    final appointmentsBox = Hive.box<AppointmentEntry>('appointments');
    final notificationService = NotificationService();

    try {
      if (widget.appointment != null) {
        // Edit existing appointment

        // Cancel old notifications
        await notificationService.cancelNotifications(
          oneDayNotificationId: widget.appointment!.oneDayNotificationId,
          oneWeekNotificationId: widget.appointment!.oneWeekNotificationId,
        );

        // Update appointment
        widget.appointment!.title = _titleController.text.trim();
        widget.appointment!.description = _descriptionController.text.trim();
        widget.appointment!.dateTime = _selectedDateTime;
        widget.appointment!.notifyOneDay = _notifyOneDay;
        widget.appointment!.notifyOneWeek = _notifyOneWeek;

        // Schedule new notifications
        final notificationIds = await notificationService
            .scheduleAppointmentNotifications(
          appointment: widget.appointment!,
        );

        widget.appointment!.oneDayNotificationId = notificationIds['oneDay'];
        widget.appointment!.oneWeekNotificationId = notificationIds['oneWeek'];

        await widget.appointment!.save();
      } else {
        // Create new appointment
        final newAppointment = AppointmentEntry(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dateTime: _selectedDateTime,
          notifyOneDay: _notifyOneDay,
          notifyOneWeek: _notifyOneWeek,
        );

        // Schedule notifications
        final notificationIds = await notificationService
            .scheduleAppointmentNotifications(
          appointment: newAppointment,
        );

        newAppointment.oneDayNotificationId = notificationIds['oneDay'];
        newAppointment.oneWeekNotificationId = notificationIds['oneWeek'];

        await appointmentsBox.add(newAppointment);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving appointment: $e')),
        );
      }
    }
  }

  Future<void> _deleteAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Appointment'),
            content: const Text(
                'Are you sure you want to delete this appointment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true && widget.appointment != null) {
      final notificationService = NotificationService();

      // Cancel notifications
      await notificationService.cancelNotifications(
        oneDayNotificationId: widget.appointment!.oneDayNotificationId,
        oneWeekNotificationId: widget.appointment!.oneWeekNotificationId,
      );

      // Delete from database
      await widget.appointment!.delete();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appointment != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Appointment' : 'New Appointment'),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Range Practice',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Additional details',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Date selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_selectedDateTime.day}/${_selectedDateTime
                        .month}/${_selectedDateTime.year}',
                  ),
                  onTap: _selectDate,
                ),

                // Time selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  onTap: _selectTime,
                ),

                const Divider(),

                // Notification options
                const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('1 Day Before'),
                  value: _notifyOneDay,
                  onChanged: (value) {
                    setState(() {
                      _notifyOneDay = value ?? false;
                    });
                  },
                ),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('1 Week Before'),
                  value: _notifyOneWeek,
                  onChanged: (value) {
                    setState(() {
                      _notifyOneWeek = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: _deleteAppointment,
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAppointment,
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
