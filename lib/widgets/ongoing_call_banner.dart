import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/call_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';

class OngoingCallBanner extends StatelessWidget {
  final VoidCallback onTap;

  const OngoingCallBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        if (!call.shouldShowCallBanner) {
          return const SizedBox.shrink();
        }

        final top = MediaQuery.paddingOf(context).top + 8;

        return Positioned(
          top: top,
          left: 12,
          right: 12,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.26),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ongoing voice chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              call.formattedDuration,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.1,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'End call',
                        onPressed: () async {
                          if (call.callDuration.inSeconds > 0) {
                            AnalyticsService().logCallEnded(
                              durationSeconds: call.callDuration.inSeconds,
                              callType: 'voice',
                            );
                          }
                          await call.endCall();
                        },
                        icon: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
