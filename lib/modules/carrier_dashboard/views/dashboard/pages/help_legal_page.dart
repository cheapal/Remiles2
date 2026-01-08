import 'dart:io';

import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../core/firebase_service.dart';
import 'chat_screen.dart';

class CarrierHelpLegalPage extends StatelessWidget {
  const CarrierHelpLegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            TopNavigationBar(context),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Help & Legal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionCard(
                    context,
                    'Help Center',
                    Icons.help_outline,
                    'Get answers to frequently asked questions and learn how to use Remiles',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarrierHelpPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    'Terms of Service',
                    Icons.description,
                    'Read our terms and conditions for using Remiles',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarrierTermsOfServicePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    'Privacy Policy',
                    Icons.privacy_tip,
                    'Learn how we collect, use, and protect your personal information',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarrierPrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    'Contact Support',
                    Icons.support_agent,
                    'Get in touch with our support team for assistance',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarrierContactSupportPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.green.shade700,
                size: 28,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// Help Page for Carriers
class CarrierHelpPage extends StatelessWidget {
  const CarrierHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Getting Started',
                [
                  _buildFAQItem(
                    'How do I find and accept loads?',
                    'Go to the "Marketplace" tab to browse available loads. You can filter by location, type, and other criteria. Tap on a load to view details and accept it.',
                  ),
                  _buildFAQItem(
                    'How do I manage my accepted loads?',
                    'Go to the "Manage Loads" tab to see all your accepted loads. You can view details, update status, and manage deliveries from there.',
                  ),
                  _buildFAQItem(
                    'What information do I need to provide?',
                    'You need to provide your vehicle information, driver details, insurance information, and other required documents in your profile.',
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSection(
                'Load Management',
                [
                  _buildFAQItem(
                    'How do I update load status?',
                    'Go to "Manage Loads", select the load, and update its status (Picked Up, In Transit, Delivered) as you progress.',
                  ),
                  _buildFAQItem(
                    'What should I do when I pick up a load?',
                    'Update the load status to "Picked Up" and upload proof of pickup if required. This notifies the shipper that you have the load.',
                  ),
                  _buildFAQItem(
                    'How do I mark a load as delivered?',
                    'When you complete delivery, update the status to "Delivered" and upload proof of delivery documents. The shipper will be notified.',
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSection(
                'Account & Profile',
                [
                  _buildFAQItem(
                    'How do I update my profile information?',
                    'Go to your Profile tab, tap on "Account Details" to edit your company information, contact details, and other profile settings.',
                  ),
                  _buildFAQItem(
                    'How do I manage my documents?',
                    'Navigate to Profile > Documents to upload, view, or update your required documents like insurance, licenses, and certifications.',
                  ),
                  _buildFAQItem(
                    'How do I set my load preferences?',
                    'Go to Profile > Load Preferences to set your preferred load types, routes, and other criteria for load matching.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Terms of Service Page for Carriers (same content as shippers)
class CarrierTermsOfServicePage extends StatelessWidget {
  const CarrierTermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '1. Acceptance of Terms',
                'By accessing and using Remiles, you accept and agree to be bound by the terms and provision of this agreement.',
              ),
              _buildSection(
                '2. Use License',
                'Permission is granted to temporarily use Remiles for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose\n• Attempt to decompile or reverse engineer any software\n• Remove any copyright or other proprietary notations',
              ),
              _buildSection(
                '3. User Accounts',
                'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
              ),
              _buildSection(
                '4. Load Acceptance and Management',
                'As a carrier, you agree to:\n\n• Provide accurate and complete information about your vehicles and capabilities\n• Accept loads only if you can fulfill the requirements\n• Update load status accurately and in a timely manner\n• Complete deliveries as agreed with shippers',
              ),
              _buildSection(
                '5. Prohibited Activities',
                'You agree not to:\n\n• Accept loads you cannot fulfill\n• Provide false or misleading information\n• Use the service for any illegal purpose\n• Interfere with or disrupt the service',
              ),
              _buildSection(
                '6. Limitation of Liability',
                'Remiles shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
              ),
              _buildSection(
                '7. Modifications',
                'We reserve the right to modify these terms at any time. Your continued use of the service after such modifications constitutes acceptance of the updated terms.',
              ),
              _buildSection(
                '8. Contact Information',
                'For questions about these Terms of Service, please contact us through the Contact Support section in the app.',
              ),
              const SizedBox(height: 30),
              Text(
                'Last Updated: ${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Privacy Policy Page for Carriers (same content as shippers)
class CarrierPrivacyPolicyPage extends StatelessWidget {
  const CarrierPrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '1. Information We Collect',
                'We collect information that you provide directly to us, including:\n\n• Account information (name, email, phone number, company details)\n• Vehicle and driver information\n• Load acceptance and delivery data\n• Payment information (processed securely through third-party providers)\n• Usage data and app interactions',
              ),
              _buildSection(
                '2. How We Use Your Information',
                'We use the information we collect to:\n\n• Provide and improve our services\n• Match you with suitable loads\n• Process transactions and payments\n• Communicate with you about loads and account\n• Send you important updates and notifications',
              ),
              _buildSection(
                '3. Information Sharing',
                'We do not sell your personal information. We may share your information only:\n\n• With shippers whose loads you accept (necessary information only)\n• With service providers who assist us in operating our platform\n• When required by law or to protect our rights',
              ),
              _buildSection(
                '4. Data Security',
                'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
              ),
              _buildSection(
                '5. Your Rights',
                'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your account and data\n• Opt-out of certain communications\n• Export your data',
              ),
              _buildSection(
                '6. Contact Us',
                'If you have any questions about this Privacy Policy, please contact us through the Contact Support section in the app.',
              ),
              const SizedBox(height: 30),
              Text(
                'Last Updated: ${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Support Page for Carriers
class CarrierContactSupportPage extends StatelessWidget {
  const CarrierContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contact Support',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get in Touch',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re here to help! Reach out to us through any of the following methods:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              _buildContactCard(
                Icons.email,
                'Email Support',
                'support@remiles.com',
                'Send us an email and we\'ll get back to you within 24 hours',
                () {
                  _openEmailSupport(context);
                },
              ),
              // const SizedBox(height: 16),
              // _buildContactCard(
              //   Icons.phone,
              //   'Phone Support',
              //   '+1 (555) 123-4567',
              //   'Call us Monday-Friday, 9 AM - 5 PM EST',
              //   () {
              //     _openPhoneSupport(context);
              //   },
              // ),
              const SizedBox(height: 16),
              _buildContactCard(
                Icons.chat_bubble_outline,
                'Live Chat',
                'Available in-app',
                'Chat with our support team in real-time',
                () {
                  _openSupportChat(context);
                },
              ),

              const SizedBox(height: 30),
              _buildContactCard(
                Icons.web_outlined,
                'Visit Our Website',
                'www.remileslogistics.ca',
                'Visit our website to learn more about Remiles',
                () {
                  // android ios web
                 
                  launchUrl(Uri.parse('https://www.remileslogistics.ca'));
                }
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    IconData icon,
    String title,
    String contact,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.green.shade700,
                size: 28,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static void _openSupportChat(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to chat with support'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Create or get support conversation
      final conversationId = await FirebaseService.createOrGetSupportConversation(user.uid);
      
      if (context.mounted) {
        // Navigate to support chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              isSupportChat: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open support chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  static Future<void> _openEmailSupport(BuildContext context) async {
    const email =   'info@remileslogistics.com';
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
      );
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open email. Please check if you have an email app installed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  static Future<void> _openPhoneSupport(BuildContext context) async {
    const phoneNumber = '+1 (555) 123-4567';
    try {
      // Remove any non-digit characters except + for international numbers
      final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (cleanedPhone.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid phone number'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedPhone);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone call. Please check if your device supports phone calls.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

