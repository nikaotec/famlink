import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  File? _avatarFile;

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Future<void> register() async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String? avatarUrl;
      if (_avatarFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${credential.user!.uid}.jpg');
        await ref.putFile(_avatarFile!);
        avatarUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': credential.user!.email,
        'avatar': avatarUrl ?? '',
      });

      context.go('/map');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: pickAvatar,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null ? const Icon(Icons.add_a_photo) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: register, child: const Text('Cadastrar')),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Já tem conta? Faça login'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
