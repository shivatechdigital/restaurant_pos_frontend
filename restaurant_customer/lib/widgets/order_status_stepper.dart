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
        icon: Icons.receipt_long_rounded,
        activeIcon: Icons.check_circle_rounded,
      ),
      _StepData(
        label: 'Accepted',
        icon: Icons.thumb_up_alt_outlined,
        activeIcon: Icons.check_circle_rounded,
      ),
      _StepData(
        label: 'Preparing',
        icon: Icons.soup_kitchen_outlined,
        activeIcon: Icons.soup_kitchen_rounded,
      ),
      _StepData(
        label: 'Ready',
        icon: Icons.dinner_dining_outlined,
        activeIcon: Icons.dinner_dining_rounded,
      ),
      _StepData(
        label: 'Served',
        icon: Icons.task_alt_rounded,
        activeIcon: Icons.verified_rounded,
      ),
    ];

    if (isCancelled) {
      return _buildCancelledView();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Left connector
                          if (index > 0)
                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: isCompleted || isCurrent
                                      ? const Color(0xFFF45B15)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 4),

                          // Node Circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: isCurrent ? 36 : 30,
                            height: isCurrent ? 36 : 30,
                            decoration: BoxDecoration(
                              gradient: (isCompleted || isCurrent)
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFF7A3D),
                                        Color(0xFFF45B15),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: (isCompleted || isCurrent)
                                  ? null
                                  : const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isCompleted || isCurrent)
                                    ? const Color(0xFFF45B15)
                                    : const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                              boxShadow: isCurrent
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x40F45B15),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : (isCurrent ? step.activeIcon : step.icon),
                                size: isCurrent ? 18 : 14,
                                color: (isCompleted || isCurrent)
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),

                          // Right connector
                          if (index < steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFFF45B15)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 4),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Label
                      Text(
                        step.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : (isCompleted
                                    ? FontWeight.w700
                                    : FontWeight.w500),
                          color: isCurrent
                              ? const Color(0xFFF45B15)
                              : (isCompleted
                                    ? const Color(0xFF1E2022)
                                    : const Color(0xFF9CA3AF)),
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
