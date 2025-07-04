import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: HeroIcon(
              HeroIcons.informationCircle,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('How Fylez Works'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoCard(
              'Blockchain Storage',
              'Files are securely stored on the blockchain, ensuring permanent access and immutable storage.',
              HeroIcons.shieldCheck,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Unique Hash',
              'Each file gets a unique blockchain hash for verification and integrity checking.',
              HeroIcons.fingerPrint,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Decentralized',
              'No single point of failure. Files are distributed across the blockchain network.',
              HeroIcons.globeAlt,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Secure Access',
              'Only you have access to your files through your secure blockchain wallet.',
              HeroIcons.lockClosed,
              Colors.orange,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String description, HeroIcons icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HeroIcon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
