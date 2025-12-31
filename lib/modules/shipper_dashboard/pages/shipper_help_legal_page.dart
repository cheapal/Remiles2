import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';

class ShipperHelpLegalPage extends StatelessWidget {
  const ShipperHelpLegalPage({super.key});

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
                          builder: (context) => const ShipperHelpPage(),
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
                          builder: (context) => const ShipperTermsOfServicePage(),
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
                          builder: (context) => const ShipperPrivacyPolicyPage(),
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
                          builder: (context) => const ShipperContactSupportPage(),
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

// Help Page
class ShipperHelpPage extends StatelessWidget {
  const ShipperHelpPage({super.key});

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
                    'How do I post a load?',
                    'To post a load, go to the "Manage Loads" tab and tap the "Post a New Load" button. Fill in the required details including pickup and delivery locations, dates, and load specifications.',
                  ),
                  _buildFAQItem(
                    'How do I edit or delete a load?',
                    'Go to "Manage Loads" and find the load you want to modify. Tap the edit button (for active loads) or use the options menu to edit or delete the load.',
                  ),
                  _buildFAQItem(
                    'What information do I need to post a load?',
                    'You need to provide pickup and delivery locations, dates and times, load specifications (weight, dimensions, type), and any special requirements or documents.',
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSection(
                'Subscriptions & Plans',
                [
                  _buildFAQItem(
                    'What subscription plans are available?',
                    'We offer three plans: Starter Bundle (\$99/month), Pro Bundle (\$249/month), and Enterprise Bundle (\$449/month). Each plan includes different load posting limits and boost credits.',
                  ),
                  _buildFAQItem(
                    'How do I upgrade or change my plan?',
                    'Go to "Boost My Page" in your profile, select the plan you want, and tap "Upgrade" or "Save Plan". Your new plan will be activated immediately.',
                  ),
                  _buildFAQItem(
                    'What are boost credits?',
                    'Boost credits allow you to promote your loads to get more visibility and faster matches with carriers.',
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSection(
                'Managing Loads',
                [
                  _buildFAQItem(
                    'How do I track my loads?',
                    'Go to "Manage Loads" to see all your posted loads. You can filter by status (Active, In Transit, Completed, Cancelled) and view detailed information for each load.',
                  ),
                  _buildFAQItem(
                    'Can I cancel a load after posting?',
                    'Yes, you can cancel a load from the "Manage Loads" section. However, cancellation policies may apply depending on the load status.',
                  ),
                  _buildFAQItem(
                    'How do I mark a load as booked?',
                    'When a carrier accepts your load, you can mark it as booked from the load details page. This will change the status to "Booked".',
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
                    'How do I add payment methods?',
                    'Navigate to Profile > Payment Method to add or update your payment information for subscription billing.',
                  ),
                  _buildFAQItem(
                    'How do I change my password?',
                    'Go to Profile > Settings to change your password and manage other account security settings.',
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

// Terms of Service Page
class ShipperTermsOfServicePage extends StatelessWidget {
  const ShipperTermsOfServicePage({super.key});

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
                '4. Load Posting and Management',
                'As a shipper, you agree to:\n\n• Provide accurate and complete information when posting loads\n• Ensure all loads comply with applicable laws and regulations\n• Honor all commitments made to carriers\n• Update load status in a timely manner',
              ),
              _buildSection(
                '5. Subscription Plans',
                'Subscription fees are charged monthly in advance. You may cancel your subscription at any time, but no refunds will be provided for the current billing period.',
              ),
              _buildSection(
                '6. Payment Terms',
                'All subscription fees must be paid in advance. We reserve the right to suspend or terminate your account for non-payment.',
              ),
              _buildSection(
                '7. Prohibited Activities',
                'You agree not to:\n\n• Post false or misleading information\n• Use the service for any illegal purpose\n• Interfere with or disrupt the service\n• Attempt to gain unauthorized access to any portion of the service',
              ),
              _buildSection(
                '8. Limitation of Liability',
                'Remiles shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
              ),
              _buildSection(
                '9. Modifications',
                'We reserve the right to modify these terms at any time. Your continued use of the service after such modifications constitutes acceptance of the updated terms.',
              ),
              _buildSection(
                '10. Contact Information',
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

// Privacy Policy Page
class ShipperPrivacyPolicyPage extends StatelessWidget {
  const ShipperPrivacyPolicyPage({super.key});

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
                'We collect information that you provide directly to us, including:\n\n• Account information (name, email, phone number, company details)\n• Load information (pickup/delivery locations, dates, specifications)\n• Payment information (processed securely through third-party providers)\n• Usage data and app interactions',
              ),
              _buildSection(
                '2. How We Use Your Information',
                'We use the information we collect to:\n\n• Provide and improve our services\n• Process transactions and manage subscriptions\n• Communicate with you about your account and loads\n• Send you important updates and notifications\n• Analyze usage patterns to enhance user experience',
              ),
              _buildSection(
                '3. Information Sharing',
                'We do not sell your personal information. We may share your information only:\n\n• With carriers who accept your loads (necessary load information only)\n• With service providers who assist us in operating our platform\n• When required by law or to protect our rights\n• In connection with a business transfer or merger',
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
                '6. Cookies and Tracking',
                'We use cookies and similar tracking technologies to track activity on our service and hold certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
              ),
              _buildSection(
                '7. Third-Party Services',
                'Our service may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties.',
              ),
              _buildSection(
                '8. Children\'s Privacy',
                'Our service is not intended for individuals under the age of 18. We do not knowingly collect personal information from children.',
              ),
              _buildSection(
                '9. Changes to Privacy Policy',
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
              ),
              _buildSection(
                '10. Contact Us',
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

// Contact Support Page
class ShipperContactSupportPage extends StatelessWidget {
  const ShipperContactSupportPage({super.key});

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
                context,
                Icons.email,
                'Email Support',
                'info@remileslogistics.com',
                'Send us an email and we\'ll get back to you within 24 hours',
                () {
                  _openEmailSupport(context);
                },
              ),
              // const SizedBox(height: 16),
              // _buildContactCard(
              //   context,
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
                context,
                Icons.chat_bubble_outline,
                'Live Chat',
                'Available in-app',
                'Chat with our support team in real-time',
                () {
                  _openSupportChat(context);
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildFAQCard(
                'How quickly will I receive a response?',
                'We typically respond to all inquiries within 24 hours during business days.',
              ),
              const SizedBox(height: 12),
              _buildFAQCard(
                'What information should I include in my support request?',
                'Please include your account email, a description of the issue, and any relevant screenshots or error messages.',
              ),
              const SizedBox(height: 12),
              _buildFAQCard(
                'Can I get help with technical issues?',
                'Yes! Our support team can help with technical issues, account problems, billing questions, and general app usage.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
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

  Widget _buildFAQCard(String question, String answer) {
    return Container(
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
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
      
      // Show loading indicator
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (context) => const Center(
      //     child: CircularProgressIndicator(),
      //   ),
      // );
      
      // Create or get support conversation
      final conversationId = await FirebaseService.createOrGetSupportConversation(user.uid);
      
      if (context.mounted) {
        //Navigator.of(context).pop(); // Close loading dialog
        
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
        Navigator.of(context).pop(); // Close loading dialog if still open
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
    const email = 'info@remileslogistics.com';
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

