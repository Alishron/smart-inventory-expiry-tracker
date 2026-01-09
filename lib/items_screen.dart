import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manual_add_item_screen.dart';
import 'scan_add_item_screen.dart';
import 'package:intl/intl.dart';

class ItemsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const ItemsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get itemsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId)
          .collection('items');

  // ✅ SAFE DATE PARSER
  DateTime parseExpiry(dynamic rawExpiry) {
    try {
      if (rawExpiry is Timestamp) return rawExpiry.toDate();
      if (rawExpiry is String) {
        return DateTime.parse(rawExpiry.replaceAll('/', '-'));
      }
    } catch (_) {}
    return DateTime.now();
  }

  // 🗑️ DELETE CONFIRMATION
  void confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await itemsRef.doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ℹ️ ITEM DETAILS BOTTOM SHEET
  void showItemDetails(BuildContext context, QueryDocumentSnapshot item) {
    final expiry = parseExpiry(item['expiryDate']);
    final createdAt =
    (item['createdAt'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _infoRow("Category", categoryName),
            _infoRow("Barcode", item['barcode']),
            _infoRow("Expiry", DateFormat.yMMMd().format(expiry)),
            _infoRow(
              "Created",
              DateFormat.yMMMd().add_jm().format(createdAt),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Delete Item"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(context, item.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
                return Column(
                  children: [
                    // 🧭 Custom AppBar (adaptive)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 📦 Items List (flexible height)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: itemsRef
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                "No items yet",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final item = docs[index];
                              final expiry =
                              parseExpiry(item['expiryDate']);

                              return _glassItemCard(
                                child: ListTile(
                                  title: Text(
                                    item['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Expiry: ${DateFormat.yMMMd().format(expiry)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                  onTap: () =>
                                      showItemDetails(context, item),
                                  onLongPress: () =>
                                      confirmDelete(context, item.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // ➕ Bottom Actions (safe on small screens)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom:
                        MediaQuery.of(context).padding.bottom + 8,
                        top: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon:
                              const Icon(Icons.qr_code_scanner),
                              label: const Text("Scan"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ScanAddItemScreen(
                                          categoryId: categoryId,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text("Manual"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ManualAddItemScreen(
                                          categoryId: categoryId,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Glass Card for Item
  Widget _glassItemCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
