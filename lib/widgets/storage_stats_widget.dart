import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:heroicons/heroicons.dart';
import '../models/file_item.dart';
import 'file_card.dart' show kImageFileColor, kDocumentFileColor, kVideoFileColor, kAudioFileColor;

class StorageStatsWidget extends StatelessWidget {
  final List<FileItem> files;
  final double maxStorageMB;
  final bool showDetailedStats;

  const StorageStatsWidget({
    super.key,
    required this.files,
    this.maxStorageMB = 200.0, // 200MB limit
    this.showDetailedStats = true, // Show pie chart and detailed breakdown by default
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final usedMB = stats['totalSize']! / (1024 * 1024);
    final usedPercentage = (usedMB / maxStorageMB * 100).clamp(0.0, 100.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HeroIcon(
                  HeroIcons.chartPie,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Storage Usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${usedPercentage.toStringAsFixed(1)}% used',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Storage bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  if (usedPercentage > 0)
                    Expanded(
                      flex: usedPercentage.round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getUsageColor(usedPercentage),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  if (usedPercentage < 100)
                    Expanded(
                      flex: (100 - usedPercentage).round(),
                      child: const SizedBox(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${usedMB.toStringAsFixed(2)} MB used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${maxStorageMB.toStringAsFixed(0)} MB total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            
            // Show total file count
            // if (files.isNotEmpty) ...[
            //   const SizedBox(height: 12),
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text(
            //         '${files.length} file${files.length == 1 ? '' : 's'}',
            //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //       Text(
            //         _formatSize(stats['totalSize']!),
            //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ],
            //   ),
            // ],
            
            // Show detailed stats with pie chart only if requested
            if (showDetailedStats && files.isNotEmpty) ...[
              const SizedBox(height: 20),
              // File type breakdown
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: _getPieChartSections(stats),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Images', stats['imageCount']!, stats['imageSize']!, kImageFileColor),
                        _buildLegendItem('Documents', stats['documentCount']!, stats['documentSize']!, kDocumentFileColor),
                        _buildLegendItem('Videos', stats['videoCount']!, stats['videoSize']!, kVideoFileColor),
                        _buildLegendItem('Audio', stats['audioCount']!, stats['audioSize']!, kAudioFileColor),
                        _buildLegendItem('Others', stats['otherCount']!, stats['otherSize']!, Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int size, Color color) {
    if (count == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label ($count)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            _formatSize(size),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  Map<String, int> _calculateStats() {
    int imageCount = 0, documentCount = 0, videoCount = 0, audioCount = 0, otherCount = 0;
    int imageSize = 0, documentSize = 0, videoSize = 0, audioSize = 0, otherSize = 0;
    int totalSize = 0;

    for (final file in files) {
      totalSize += file.size;
      
      if (file.isImage) {
        imageCount++;
        imageSize += file.size;
      } else if (file.isDocument) {
        documentCount++;
        documentSize += file.size;
      } else if (file.isVideo) {
        videoCount++;
        videoSize += file.size;
      } else if (file.isAudio) {
        audioCount++;
        audioSize += file.size;
      } else {
        otherCount++;
        otherSize += file.size;
      }
    }

    return {
      'imageCount': imageCount,
      'documentCount': documentCount,
      'videoCount': videoCount,
      'audioCount': audioCount,
      'otherCount': otherCount,
      'imageSize': imageSize,
      'documentSize': documentSize,
      'videoSize': videoSize,
      'audioSize': audioSize,
      'otherSize': otherSize,
      'totalSize': totalSize,
    };
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, int> stats) {
    final sections = <PieChartSectionData>[];
    final total = stats['totalSize']!;
    
    if (total == 0) return sections;

    final data = [
      {'label': 'Images', 'size': stats['imageSize']!, 'color': kImageFileColor},
      {'label': 'Documents', 'size': stats['documentSize']!, 'color': kDocumentFileColor},
      {'label': 'Videos', 'size': stats['videoSize']!, 'color': kVideoFileColor},
      {'label': 'Audio', 'size': stats['audioSize']!, 'color': kAudioFileColor},
      {'label': 'Others', 'size': stats['otherSize']!, 'color': Colors.grey},
    ];

    for (final item in data) {
      final size = item['size'] as int;
      if (size > 0) {
        final percentage = (size / total * 100);
        sections.add(
          PieChartSectionData(
            color: item['color'] as Color,
            value: percentage,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 40,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
