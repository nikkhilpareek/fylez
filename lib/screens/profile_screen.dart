import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'auth_welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Navigate back to auth welcome screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWelcomeScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Profile avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const HeroIcon(
                HeroIcons.user,
                size: 50,
                color: Color(0xFF2563EB),
                style: HeroIconStyle.solid,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // User info
            Text(
              'Welcome to Fylez',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Secure decentralized storage',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            
            const Spacer(),
            
            // Logout button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleLogout(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const HeroIcon(
                            HeroIcons.arrowRightOnRectangle,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                'Sign out of your account',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const HeroIcon(
                          HeroIcons.chevronRight,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
