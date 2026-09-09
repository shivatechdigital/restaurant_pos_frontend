import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderStatusStepper extends StatelessWidget {
  final String currentStatus;

  const OrderStatusStepper({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final isCancelled = currentStatus == OrderStatus.cancelled;
    final currentStep = OrderStatus.getStepIndex(currentStatus);

    final steps = [
      _StepData(
        label: 'Placed',
        icon: Icons.receipt_long,
        activeIcon: Icons.check_circle,
      ),
      _StepData(
        label: 'Accepted',
        icon: Icons.pending,
        activeIcon: Icons.check_circle,
      ),
      _StepData(
        label: 'Preparing',
        icon: Icons.hourglass_empty,
        activeIcon: Icons.local_fire_department,
      ),
      _StepData(
        label: 'Ready',
        icon: Icons.hourglass_bottom,
        activeIcon: Icons.restaurant,
      ),
      _StepData(
        label: 'Served',
        icon: Icons.done_outline,
        activeIcon: Icons.done_all,
      ),
    ];

    if (isCancelled) {
      return _buildCancelledView();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          // Stepper Row
          Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              final isUpcoming = index > currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Circle
                    Expanded(
                      child: Column(
                        children: [
                          // Line + Circle
                          Row(
                            children: [
                              // Left line
                              if (index > 0)
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    color: isCompleted || isCurrent
                                        ? const Color(0xFF1B5E20)
                                        : Colors.grey[300],
                                  ),
                                ),
                              // Circle
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: isCurrent ? 40 : 32,
                                height: isCurrent ? 40 : 32,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF1B5E20)
                                      : isCurrent
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey[200],
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF1B5E20)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isCompleted || isCurrent
                                      ? step.activeIcon
                                      : step.icon,
                                  size: isCurrent ? 22 : 16,
                                  color: isUpcoming
                                      ? Colors.grey[400]
                                      : Colors.white,
                                ),
                              ),
                              // Right line
                              if (index < steps.length - 1)
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    color: isCompleted
                                        ? const Color(0xFF1B5E20)
                                        : Colors.grey[300],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Label
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCompleted || isCurrent
                                  ? const Color(0xFF1B5E20)
                                  : Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledView() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.cancel, color: Colors.red, size: 50),
          SizedBox(height: 8),
          Text(
            'Order Cancelled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aapka order cancel ho gaya hai',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  _StepData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
