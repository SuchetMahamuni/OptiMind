import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _secondController = TextEditingController(text: "");
  final _minuteController = TextEditingController(text: "");
  final _hourController = TextEditingController(text: "");
  
  String _priority = 'medium';
  DateTime? _deadline;
  bool _isSaving = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _secondController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          _deadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final success = await Provider.of<TaskProvider>(context, listen: false).addTask(
      _subjectController.text.trim(),
      _priority,
      _deadline,
      int.tryParse((
          (int.tryParse(_secondController.text)??0) +
          (int.tryParse(_minuteController.text)??0) * 60 +
          (int.tryParse(_hourController.text)??0) * 3600).toString()) ?? 60,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task added successfully")),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add task")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create New Task"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, "Task Details"),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _subjectController,
                      label: "Task Information",
                      prefixIcon: Icons.timer_outlined,
                      hint: "e.g. Revise Calculus Chapter 4",
                      validator: (val) => (val == null || val.isEmpty) ? "Please enter a subject" : null,
                    ),
                    const SizedBox(height: 24),
                    _buildPrioritySelector(context),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(context, "Time & Scheduling"),
              AppCard(
                child: Column(
                  children: [
                    _buildDeadlinePicker(context),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child:
                          TextField(
                              controller: _hourController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(hintText: 'HH'),
                          ),
                        ),
                        SizedBox(width: 8,),
                        Expanded(
                          child:
                          TextField(
                            controller: _minuteController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: 'MM'),
                          ),
                        ),
                        SizedBox(width: 8,),
                        Expanded(
                          child:
                          TextField(
                            controller: _secondController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: 'SS'),
                          ),
                        )

                      ]
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              AppButton(
                text: "Add Task",
                isLoading: _isSaving,
                onPressed: _saveTask,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
     return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _priority,
      decoration: InputDecoration(
        labelText: "Priority",
        labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
        prefixIcon: Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items: const [
        DropdownMenuItem(value: 'low', child: Text("Low (Minor focus)")),
        DropdownMenuItem(value: 'medium', child: Text("Medium (Standard)")),
        DropdownMenuItem(value: 'high', child: Text("High (Top Priority)")),
      ],
      onChanged: (val) => setState(() => _priority = val!),
    );
  }

  Widget _buildDeadlinePicker(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickDeadline,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Deadline", style: theme.textTheme.bodySmall),
                  Text(
                    _deadline != null 
                        ? DateFormat('EEEE, MMM d, yyyy @ HH:mm').format(_deadline!) 
                        : "Set a deadline (optional)",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _deadline == null ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
