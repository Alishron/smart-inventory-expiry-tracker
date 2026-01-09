import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class ManualAddItemScreen extends StatefulWidget {
  final String categoryId;
  const ManualAddItemScreen({super.key, required this.categoryId});

  @override
  State<ManualAddItemScreen> createState() => _ManualAddItemScreenState();
}

class _ManualAddItemScreenState extends State<ManualAddItemScreen> {
  final nameController = TextEditingController();
  DateTime? expiryDate;
  bool loading = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => expiryDate = picked);
  }

  Future<void> saveItem() async {
    if (nameController.text.trim().isEmpty || expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields required")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(widget.categoryId)
          .collection('items')
          .add({
        'name': nameController.text.trim(),
        'barcode': 'MANUAL',
        'expiryDate': Timestamp.fromDate(expiryDate!),
        'createdAt': Timestamp.now(),
      });

      // 🔔 Fire-and-forget notification
      NotificationService.scheduleExpiryReminders(
        itemName: nameController.text.trim(),
        expiryDate: expiryDate!,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add item")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 🌈 Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1D2671),
                  Color(0xFFC33764),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              constraints:
                              const BoxConstraints(maxWidth: 420),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border:
                                Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Add Item",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Enter item details manually",
                                    style:
                                    TextStyle(color: Colors.white70),
                                  ),

                                  const SizedBox(height: 30),

                                  _inputField(
                                    controller: nameController,
                                    hint: "Item Name",
                                    icon: Icons.inventory,
                                  ),

                                  const SizedBox(height: 16),

                                  ListTile(
                                    onTap: pickDate,
                                    tileColor:
                                    Colors.white.withOpacity(0.15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(16),
                                    ),
                                    leading: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                    ),
                                    title: Text(
                                      expiryDate == null
                                          ? "Select Expiry Date"
                                          : DateFormat.yMMMd()
                                          .format(expiryDate!),
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                      loading ? null : saveItem,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: loading
                                          ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                          : const Text(
                                        "Save Item",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Reusable Input Field
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
