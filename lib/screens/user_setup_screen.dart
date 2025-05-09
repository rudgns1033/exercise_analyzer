import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/loading_indicator.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _ageCtl = TextEditingController();
  bool _beginner = true;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: prov.isLoading
            ? const LoadingIndicator()
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _heightCtl,
                decoration: const InputDecoration(labelText: '키 (cm)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightCtl,
                decoration: const InputDecoration(labelText: '체중 (kg)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageCtl,
                decoration: const InputDecoration(labelText: '나이'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('초보자 여부'),
                value: _beginner,
                onChanged: (v) => setState(() => _beginner = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('등록'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final user = User(
                      height: int.parse(_heightCtl.text),
                      weight: int.parse(_weightCtl.text),
                      age: int.parse(_ageCtl.text),
                      beginner: _beginner,
                    );
                    prov.registerUser(user).then((_) {
                      if (prov.user != null) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
