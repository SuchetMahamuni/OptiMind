import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late TextEditingController _secondController;
  DateTime? _deadline;

  late String _selectedPriority;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.task.subject,
    );

    _hourController = TextEditingController(
      text: (widget.task.estimatedTime.toInt()/3600).toInt().toString(),
    );

    _minuteController = TextEditingController(
      text: (widget.task.estimatedTime.toInt()/60).remainder(60).toInt().toString(),
    );

    _secondController = TextEditingController(
      text: widget.task.estimatedTime.toInt().remainder(60).toInt().toString(),
    );

    _selectedPriority = widget.task.priority;
    _deadline = widget.task.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
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

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task title cannot be empty"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = {
        "subject": _titleController.text.trim(),
        "priority": _selectedPriority,
        "estimated_time": int.tryParse((
            (int.tryParse(_secondController.text)??0) +
            (int.tryParse(_minuteController.text)??0) * 60 +
            (int.tryParse(_hourController.text) ?? 0) * 3600).toString()) ?? 0,
        "deadline": _deadline?.toIso8601String(),
      };

      await Provider.of<TaskProvider>(context, listen: false).updateTask(widget.task.id, updatedTask);
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task updated successfully"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update task: $e"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPriorityChip(String priority) {
    return ChoiceChip(
      label: Text(priority),
      selected: _selectedPriority == priority,
      onSelected: (_) {
        setState(() {
          _selectedPriority = priority;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Task"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Task Subject",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // TextField(
            //   controller: _descriptionController,
            //   maxLines: 4,
            //   decoration: const InputDecoration(
            //     labelText: "Description",
            //     border: OutlineInputBorder(),
            //   ),
            // ),

            const SizedBox(height: 16),

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
                ),
              ]
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Priority",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: [
                _buildPriorityChip("Low"),
                _buildPriorityChip("Medium"),
                _buildPriorityChip("High"),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                  "Save Changes",
                ),
              ),
            ),
          ],
        ),
      ),
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