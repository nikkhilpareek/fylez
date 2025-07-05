import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'auth_welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Fylez',
      description: 'Your secure, decentralized file storage solution built on blockchain technology.',
      icon: HeroIcons.cloudArrowUp,
      color: Color(0xFF2563EB),
    ),
    OnboardingPage(
      title: 'Secure Storage',
      description: 'Files are encrypted and stored on IPFS with blockchain verification for maximum security.',
      icon: HeroIcons.shieldCheck,
      color: Color(0xFF059669),
    ),
    OnboardingPage(
      title: 'Easy Organization',
      description: 'Create folders, organize files, and manage your digital assets with ease.',
      icon: HeroIcons.folder,
      color: Color(0xFFDC2626),
    ),
    OnboardingPage(
      title: 'Get Started',
      description: 'Start uploading your files and experience the future of decentralized storage.',
      icon: HeroIcons.rocketLaunch,
      color: Color(0xFF7C3AED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header logo for pages other than first
                        if (index != 0) ...[
                          Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        // Icon or Logo
                        if (index == 0) 
                          // Use logo for first page
                          Image.asset(
                            'assets/images/logo.png',
                            height: 270,
                          )
                        else
                          // Use icon container for other pages
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: page.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: HeroIcon(
                                page.icon,
                                size: 60,
                                color: page.color,
                                style: HeroIconStyle.solid,
                              ),
                            ),
                          ),
                        const SizedBox(height: 48),
                        
                        // Title
                        if (index == 0)
                          // Special styling for first page title
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(text: 'Welcome to '),
                                TextSpan(
                                  text: 'Fylez',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Regular title for other pages
                          Text(
                            page.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom section with indicators and buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons
                  Row(
                    children: [
                      // Skip button
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const AuthWelcomeScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Next/Get Started button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const AuthWelcomeScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const HeroIcon(
                              HeroIcons.arrowRight,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final HeroIcons icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
