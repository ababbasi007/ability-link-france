import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/city_pack.dart';
import '../../services/tile_cache_service.dart';
import '../../theme/app_colors.dart';

class TileCacheScreen extends StatefulWidget {
  const TileCacheScreen({super.key});

  @override
  State<TileCacheScreen> createState() => _TileCacheScreenState();
}

class _TileCacheScreenState extends State<TileCacheScreen> {
  final _service = TileCacheService.instance;
  final _progress = <String, TileDownloadProgress>{};
  final _downloaded = <String, bool>{};
  final _sizesMb = <String, double>{};
  final _subs = <String, StreamSubscription<TileDownloadProgress>>{};

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    for (final pack in cityPacks) {
      final done = await _service.isDownloaded(pack);
      final mb = await _service.sizeOnDiskMb(pack.id);
      if (mounted) {
        setState(() {
          _downloaded[pack.id] = done;
          _sizesMb[pack.id] = mb;
        });
      }
    }
  }

  void _startDownload(CityPack pack) {
    _subs[pack.id]?.cancel();
    final stream = _service.download(pack);
    _subs[pack.id] = stream.listen(
      (prog) {
        if (mounted) {
          setState(() => _progress[pack.id] = prog);
          if (prog.finished) {
            _refreshStatus();
          }
        }
      },
      onDone: () {
        if (mounted) _refreshStatus();
      },
    );
  }

  void _cancelDownload(CityPack pack) {
    _service.cancelDownload(pack.id);
    _subs[pack.id]?.cancel();
    _subs.remove(pack.id);
    if (mounted) setState(() => _progress.remove(pack.id));
  }

  Future<void> _delete(CityPack pack) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${pack.name}"?'),
        content: const Text(
          'The tiles will be removed from this device. You can re-download them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deletePackDir(pack.id);
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offline city packs',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Download a city pack to browse the Ability Map without an internet connection.',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          for (final pack in cityPacks) _PackCard(
            pack: pack,
            isDownloaded: _downloaded[pack.id] ?? false,
            sizeMb: _sizesMb[pack.id] ?? 0,
            progress: _progress[pack.id],
            onDownload: () => _startDownload(pack),
            onCancel: () => _cancelDownload(pack),
            onDelete: () => _delete(pack),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.isDownloaded,
    required this.sizeMb,
    required this.progress,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final CityPack pack;
  final bool isDownloaded;
  final double sizeMb;
  final TileDownloadProgress? progress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final prog = progress;
    final isActive = prog != null && !prog.finished;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pack.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isDownloaded
                            ? '${sizeMb.toStringAsFixed(1)} MB on device'
                            : 'Est. ${pack.estimateSizeMb} · ${pack.estimateTileCount()} tiles',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDownloaded && !isActive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Delete pack',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                      ),
                    ],
                  )
                else if (!isActive)
                  IconButton(
                    tooltip: 'Download',
                    icon: const Icon(Icons.download_rounded),
                    color: AppColors.primary,
                    onPressed: onDownload,
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: prog.fraction,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${prog.done} / ${prog.total} tiles'
                      '${prog.failed > 0 ? ' · ${prog.failed} failed' : ''}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
