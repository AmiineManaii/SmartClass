import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import '../../domain/entities/live_participant.dart';

class ParticipantsSheet extends ConsumerWidget {
  const ParticipantsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(liveRoomControllerProvider);
    final controller = ref.read(liveRoomControllerProvider.notifier);
    final isHost = roomState.isHost;

    final allParticipants = <LiveParticipant>[
      if (roomState.localParticipant != null) roomState.localParticipant!,
      ...roomState.remoteParticipants.values,
    ];

    return Container(
      color: const Color(0xFF151B2B),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${context.tr('participants')} (${allParticipants.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (isHost) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.mic_off_rounded, size: 14, color: Colors.orange),
                    label: const Text(
                      'Muter tous',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => controller.muteAll(mute: true),
                  ),
                ],
              ],
            ),
          ),

          // Host Chat Toggle Switch
          if (isHost && roomState.session != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E2638).withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Autoriser le chat des étudiants',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Switch.adaptive(
                    value: roomState.session!.chatEnabled,
                    onChanged: (val) => controller.updateChatSettings(val),
                  ),
                ],
              ),
            ),

          // Participants List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allParticipants.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFF1E2638), height: 1),
              itemBuilder: (context, index) {
                final p = allParticipants[index];
                final isRaised = roomState.raisedHands.contains(p.identity);

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: p.isHost
                        ? const Color(0xFF122675)
                        : const Color(0xFF1E2638),
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.isLocal ? '${p.name} (Vous)' : p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (p.isHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF122675),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Hôte',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRaised) ...[
                        const Icon(Icons.front_hand_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        p.isAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        size: 16,
                        color: p.isAudioMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                      if (isHost && !p.isLocal) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.white70),
                          color: const Color(0xFF1E2638),
                          onSelected: (action) {
                            if (action == 'mute') {
                              controller.muteParticipant(p.identity, mute: true);
                            } else if (action == 'kick') {
                              controller.removeParticipant(p.identity, reason: 'Exclu par l\'enseignant');
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'mute',
                              child: Text('Couper le micro', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            const PopupMenuItem(
                              value: 'kick',
                              child: Text('Exclure de la session', style: TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
