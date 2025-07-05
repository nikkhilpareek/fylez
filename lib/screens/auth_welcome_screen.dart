import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Logo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Welcome text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  children: [
                    const TextSpan(text: 'Welcome to '),
                    TextSpan(
                      text: 'Fylez',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Your secure, decentralized file storage solution. Join thousands of users protecting their digital assets.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Features list
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: HeroIcons.shieldCheck,
                      title: 'Secure & Encrypted',
                      description: 'Your files are protected with blockchain technology',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: HeroIcons.cloudArrowUp,
                      title: 'Decentralized Storage',
                      description: 'Built on IPFS for maximum reliability',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: HeroIcons.devicePhoneMobile,
                      title: 'Access Anywhere',
                      description: 'Your files, available on all your devices',
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        HeroIcon(
                          HeroIcons.arrowRight,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required HeroIcons icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: HeroIcon(
            icon,
            size: 20,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
