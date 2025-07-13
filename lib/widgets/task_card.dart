import 'package:flutter/material.dart';
import '../models/task.dart';
import '../main.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: ADHDConstants.smallSpacing),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ADHDConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(ADHDConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: ADHDConstants.smallSpacing),
              _buildDescription(),
              const SizedBox(height: ADHDConstants.smallSpacing),
              _buildMetadata(),
              if (showActions) ...[
                const SizedBox(height: ADHDConstants.spacing),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Priority indicator
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: ADHDAppTheme.getPriorityColor(task.priority.toString().split('.').last),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: ADHDConstants.smallSpacing),
        
        // Task content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: ADHDConstants.subtitleSize,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildCategoryChip(),
                  const SizedBox(width: ADHDConstants.smallSpacing),
                  _buildPriorityChip(),
                ],
              ),
            ],
          ),
        ),
        
        // Status indicator
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildDescription() {
    if (task.description.isEmpty || task.description == task.title) {
      return const SizedBox.shrink();
    }
    
    return Text(
      task.description,
      style: const TextStyle(
        fontSize: ADHDConstants.bodySize,
        color: ADHDAppTheme.secondaryText,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        // Energy level
        Icon(
          Icons.battery_charging_full,
          size: 16,
          color: _getEnergyColor(task.energyLevel),
        ),
        const SizedBox(width: 4),
        Text(
          '${task.energyLevel}/5',
          style: const TextStyle(
            fontSize: ADHDConstants.captionSize,
            color: ADHDAppTheme.secondaryText,
          ),
        ),
        
        const SizedBox(width: ADHDConstants.spacing),
        
        // Estimated time
        const Icon(
          Icons.schedule,
          size: 16,
          color: ADHDAppTheme.secondaryText,
        ),
        const SizedBox(width: 4),
        Text(
          '${task.estimatedMinutes}m',
          style: const TextStyle(
            fontSize: ADHDConstants.captionSize,
            color: ADHDAppTheme.secondaryText,
          ),
        ),
        
        const SizedBox(width: ADHDConstants.spacing),
        
        // Dopamine score
        Icon(
          Icons.psychology,
          size: 16,
          color: ADHDAppTheme.getMotivationColor(task.dopamineScore),
        ),
        const SizedBox(width: 4),
        Text(
          '${(task.dopamineScore * 100).toInt()}%',
          style: const TextStyle(
            fontSize: ADHDConstants.captionSize,
            color: ADHDAppTheme.secondaryText,
          ),
        ),
        
        const Spacer(),
        
        // Due date
        if (task.dueDate != null) _buildDueDate(),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ADHDAppTheme.getCategoryColor(task.category.toString().split('.').last).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ADHDAppTheme.getCategoryColor(task.category.toString().split('.').last).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.category.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            task.category.displayName,
            style: TextStyle(
              fontSize: ADHDConstants.captionSize,
              fontWeight: FontWeight.w500,
              color: ADHDAppTheme.getCategoryColor(task.category.toString().split('.').last),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ADHDAppTheme.getPriorityColor(task.priority.toString().split('.').last).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ADHDAppTheme.getPriorityColor(task.priority.toString().split('.').last).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.priority.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            task.priority.displayName,
            style: TextStyle(
              fontSize: ADHDConstants.captionSize,
              fontWeight: FontWeight.w500,
              color: ADHDAppTheme.getPriorityColor(task.priority.toString().split('.').last),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    IconData statusIcon;
    
    switch (task.status) {
      case TaskStatus.completed:
        statusColor = ADHDAppTheme.accentGreen;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        statusColor = ADHDAppTheme.primaryBlue;
        statusIcon = Icons.play_circle;
        break;
      case TaskStatus.paused:
        statusColor = ADHDAppTheme.warningOrange;
        statusIcon = Icons.pause_circle;
        break;
      case TaskStatus.cancelled:
        statusColor = ADHDAppTheme.neutralGray;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = ADHDAppTheme.neutralGray;
        statusIcon = Icons.radio_button_unchecked;
    }
    
    return Icon(
      statusIcon,
      color: statusColor,
      size: 24,
    );
  }

  Widget _buildDueDate() {
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final isOverdue = dueDate.isBefore(now);
    final isDueToday = dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day;
    
    Color textColor;
    if (isOverdue) {
      textColor = ADHDAppTheme.errorRed;
    } else if (isDueToday) {
      textColor = ADHDAppTheme.warningOrange;
    } else {
      textColor = ADHDAppTheme.secondaryText;
    }
    
    String dueDateText;
    if (isDueToday) {
      dueDateText = 'Today';
    } else if (isOverdue) {
      final daysDiff = now.difference(dueDate).inDays;
      dueDateText = '$daysDiff days overdue';
    } else {
      final daysDiff = dueDate.difference(now).inDays;
      if (daysDiff == 1) {
        dueDateText = 'Tomorrow';
      } else if (daysDiff < 7) {
        dueDateText = '$daysDiff days';
      } else {
        dueDateText = '${dueDate.month}/${dueDate.day}';
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          dueDateText,
          style: TextStyle(
            fontSize: ADHDConstants.captionSize,
            color: textColor,
            fontWeight: isOverdue || isDueToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (task.status == TaskStatus.pending) ...[
          TextButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Complete'),
            style: TextButton.styleFrom(
              foregroundColor: ADHDAppTheme.accentGreen,
            ),
          ),
          const SizedBox(width: ADHDConstants.smallSpacing),
        ],
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit'),
          style: TextButton.styleFrom(
            foregroundColor: ADHDAppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: ADHDConstants.smallSpacing),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('Delete'),
          style: TextButton.styleFrom(
            foregroundColor: ADHDAppTheme.errorRed,
          ),
        ),
      ],
    );
  }

  Color _getEnergyColor(int energyLevel) {
    switch (energyLevel) {
      case 1:
        return ADHDAppTheme.errorRed;
      case 2:
        return ADHDAppTheme.warningOrange;
      case 3:
        return ADHDAppTheme.achievementGold;
      case 4:
        return ADHDAppTheme.motivationGreen;
      case 5:
        return ADHDAppTheme.accentGreen;
      default:
        return ADHDAppTheme.neutralGray;
    }
  }
}