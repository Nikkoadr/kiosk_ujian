import 'package:flutter/material.dart';
import 'webview_screen.dart';

class InputUrlScreen extends StatefulWidget {
  const InputUrlScreen({super.key});

  @override
  State<InputUrlScreen> createState() => _InputUrlScreenState();
}

class _InputUrlScreenState extends State<InputUrlScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String url = _urlController.text.trim();
      
      // Automatically add https:// if the scheme is missing
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      // Final validation to ensure it's a valid URL before navigating
      if (Uri.tryParse(url)?.isAbsolute ?? false) {
         if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
        );
      } else {
        // Show an error if the final URL is still invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format URL tidak valid.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masukan URL Ujian')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masukan URL Ujian Online',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL Ujian',
                  hintText: 'contoh-ujian.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URL tidak boleh kosong';
                  }
                  // Basic check, the main logic is in _submit
                  if (value.contains(' ')) {
                    return 'URL tidak boleh mengandung spasi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Buka Ujian'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
