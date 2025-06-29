import 'package:flutter/material.dart';

class ConfigurationDialog extends StatelessWidget {
  const ConfigurationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup Required'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To use all features, please configure:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('1. Firebase Project'),
            Text('   • Go to Firebase Console'),
            Text('   • Create a new project'),
            Text('   • Update firebase_options.dart'),
            SizedBox(height: 12),
            Text('2. Google Sign-In (Optional)'),
            Text('   • Create OAuth credentials'),
            Text('   • Update web/index.html'),
            SizedBox(height: 12),
            Text('3. Facebook Login (Optional)'),
            Text('   • Create Facebook App'),
            Text('   • Configure OAuth settings'),
            SizedBox(height: 16),
            Text(
              'For now, you can test the UI and Email/Password auth (once Firebase is configured).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // You could open the setup guide here
          },
          child: const Text('View Setup Guide'),
        ),
      ],
    );
  }
}

// Helper function to show the configuration dialog
void showConfigurationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ConfigurationDialog(),
  );
}
