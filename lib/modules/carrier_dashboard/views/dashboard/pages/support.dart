import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../core/firebase_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light grey background as in the image
      body: SingleChildScrollView(
        child: Column(
          children: [
            TopNavigationBar(context),
            Container(
              color: Colors.white, // Light grey background

              child: Padding(
                padding: const EdgeInsets.all(
                  20.0,
                ), // Padding around the main card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0, bottom: 20),
                      child: Text(
                        'Support',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Top rounded card container
                    Container(
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, //Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ), // Rounded corners for the card
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Introductory text
                          Text(
                            'If you are experiencing any issues, please let us know, We will try to solve them as soon as possible',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Title field
                          const Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide
                                    .none, // No border for the text field
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 15.0,
                              ),
                              hintText: 'Enter a brief title for your issue',
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 30),

                          // Explain the problem field
                          const Text(
                            'Explain the problem',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide
                                    .none, // No border for the text field
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 15.0,
                              ),
                              hintText: 'Please describe your issue in detail...',
                            ),
                            maxLines: 7, // Multi-line input for description
                            minLines: 5,
                          ),
                          const SizedBox(height: 40),

                          // Submit Button
                          Center(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitSupportTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSubmitting 
                                    ? const Color(0xFF2C5E4A).withOpacity(0.7)
                                    : const Color(0xFF2C5E4A), // Dark green color
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 60,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5, // Shadow effect
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== Methods ========
  
  Future<void> _submitSupportTicket() async {
    if (_isSubmitting) return;
    
    // Validate form
    if (!_validateForm()) return;
    
    setState(() => _isSubmitting = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      
      if (user != null) {
        final supportData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'userId': user.uid,
          'userEmail': user.email,
          'userRole': user.role.toString(),
          'status': 'open',
          'priority': 'medium',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        await FirebaseService.saveSupportTicket(
          user.uid,
          supportData,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support ticket submitted successfully! We\'ll get back to you soon.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          
          // Clear form
          _clearForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit support ticket: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter a title for your support request.');
      return false;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please describe your problem in detail.');
      return false;
    }
    
    if (_titleController.text.trim().length < 5) {
      _showAlertDialog(context, 'Please enter a more descriptive title (at least 5 characters).');
      return false;
    }
    
    if (_descriptionController.text.trim().length < 20) {
      _showAlertDialog(context, 'Please provide a more detailed description (at least 20 characters).');
      return false;
    }
    
    return true;
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
