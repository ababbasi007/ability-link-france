import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/route_direction_style.dart';
import '../services/navigation_session.dart';
import '../theme/app_colors.dart';

/// Bottom overlay for live turn-by-turn navigation.
class NavigationOverlay extends StatelessWidget {
  const NavigationOverlay({
    super.key,
    required this.state,
    required this.onStop,
    this.onRecenter,
    this.onToggleVoice,
    this.onRepeat,
    this.onShareWithCare,
  });

  final NavigationState state;
  final VoidCallback onStop;
  final VoidCallback? onRecenter;
  final ValueChanged<bool>? onToggleVoice;
  final VoidCallback? onRepeat;
  final VoidCallback? onShareWithCare;

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep;
    final next = state.nextStep;
    final style = step == null
        ? null
        : RouteDirectionStyle.forStep(step);
    final nextStyle =
        next == null ? null : RouteDirectionStyle.forStep(next);

    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (style != null)
              Container(height: 6, color: style.color),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.hasArrived
                              ? 'Arrived'
                              : 'Navigating to ${state.destinationName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (onToggleVoice != null)
                        IconButton(
                          tooltip: state.voiceEnabled
                              ? 'Mute voice guidance'
                              : 'Enable voice guidance',
                          onPressed: () =>
                              onToggleVoice!(!state.voiceEnabled),
                          icon: Icon(
                            state.voiceEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 20,
                            color: state.voiceEnabled
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      if (onRepeat != null && state.voiceEnabled)
                        IconButton(
                          tooltip: 'Repeat instruction',
                          onPressed: onRepeat,
                          icon: const Icon(Icons.replay_rounded, size: 20),
                        ),
                      if (onShareWithCare != null)
                        IconButton(
                          tooltip: 'Share route with Care Circle',
                          onPressed: onShareWithCare,
                          icon: const Icon(Icons.ios_share_rounded, size: 20),
                        ),
                      if (onRecenter != null)
                        IconButton(
                          tooltip: 'Recenter map',
                          onPressed: onRecenter,
                          icon: const Icon(
                            Icons.my_location_rounded,
                            size: 20,
                          ),
                        ),
                      TextButton(onPressed: onStop, child: const Text('End')),
                    ],
                  ),
                  if (step != null && style != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: style.color.withValues(alpha: 0.45),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            style.icon,
                            size: 36,
                            color: style.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RouteDirectionChip(style: style),
                              const SizedBox(height: 6),
                              Text(
                                step.instruction,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E1B4B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.hasArrived
                                    ? 'You are near your destination.'
                                    : '${step.distanceLabel} · Step ${state.stepIndex + 1} of ${state.stepCount}'
                                        '${state.voiceEnabled ? ' · Voice on' : ''}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (next != null &&
                      nextStyle != null &&
                      !state.hasArrived) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: nextStyle.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(nextStyle.icon, color: nextStyle.color, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Then: ${next.instruction}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                          RouteDirectionChip(
                            style: nextStyle,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.route != null &&
                      state.route!.steps.length > 1 &&
                      !state.hasArrived) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.route!.steps.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final s = state.route!.steps[i];
                          final st = RouteDirectionStyle.forStep(s);
                          final active = i == state.stepIndex;
                          return Opacity(
                            opacity: i < state.stepIndex ? 0.45 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? st.color.withValues(alpha: 0.18)
                                    : st.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? st.color
                                      : st.color.withValues(alpha: 0.25),
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(st.icon, size: 16, color: st.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: st.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
