import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../database/db_helper.dart';
import '../providers/app_provider.dart';

class PeopleManagerScreen extends StatefulWidget {
  const PeopleManagerScreen({super.key});

  @override
  State<PeopleManagerScreen> createState() => _PeopleManagerScreenState();
}

class _PeopleManagerScreenState extends State<PeopleManagerScreen> {
  List<Map<String, dynamic>> _people = [];
  final TextEditingController _nameController = TextEditingController();
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    final patientId = context.read<AppProvider>().selectedPatientId;
    final people = await DBHelper.getPeople(patientId: patientId);

    if (!mounted) return;

    setState(() => _people = people);
  }

  Future<void> _addPerson() async {
    if (_nameController.text.trim().isEmpty || _selectedImagePath == null) {
      return;
    }

    await DBHelper.addPerson(
      _nameController.text.trim(),
      _selectedImagePath!,
      patientId: context.read<AppProvider>().selectedPatientId,
    );

    _nameController.clear();

    setState(() => _selectedImagePath = null);

    await _loadPeople();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deletePerson(int id) async {
    await DBHelper.deletePerson(id);
    await _loadPeople();
  }

  void _showAddDialog(BuildContext context) {
    final isTR = context.read<AppProvider>().language == 'TR';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isTR ? 'Kişi Ekle' : 'Add Person',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 400,
                    maxHeight: 400,
                    imageQuality: 80,
                  );

                  if (image != null) {
                    setDialogState(() => _selectedImagePath = image.path);
                    setState(() => _selectedImagePath = image.path);
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFFBA7517),
                      width: 2,
                    ),
                  ),
                  child: _selectedImagePath != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.file(
                      File(_selectedImagePath!),
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: Color(0xFFBA7517),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTR ? 'Fotoğraf' : 'Photo',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFBA7517),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: isTR ? 'İsim girin' : 'Enter name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFBA7517),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                setState(() => _selectedImagePath = null);
                Navigator.pop(context);
              },
              child: Text(isTR ? 'İptal' : 'Cancel'),
            ),
            TextButton(
              onPressed: _addPerson,
              child: Text(
                isTR ? 'Ekle' : 'Add',
                style: const TextStyle(color: Color(0xFFBA7517)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTR = context.watch<AppProvider>().language == 'TR';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Kişi Yönetimi' : 'People Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: _people.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👤', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              isTR ? 'Henüz kişi eklenmedi' : 'No people added yet',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isTR
                  ? 'Sağ üstteki + butonuna tıklayın'
                  : 'Tap the + button at the top right',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _people.length,
        itemBuilder: (context, index) {
          final person = _people[index];

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.file(
                        File(person['imagePath']),
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      person['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _deletePerson(person['id']),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}