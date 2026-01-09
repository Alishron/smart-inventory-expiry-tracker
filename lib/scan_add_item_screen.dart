import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class ScanAddItemScreen extends StatefulWidget {
  final String categoryId;
  const ScanAddItemScreen({super.key, required this.categoryId});

  @override
  State<ScanAddItemScreen> createState() => _ScanAddItemScreenState();
}

class _ScanAddItemScreenState extends State<ScanAddItemScreen> {
  CameraController? _cameraController;
  late BarcodeScanner _barcodeScanner;

  final TextEditingController nameController = TextEditingController();

  bool _isPermissionGranted = false;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  String? scannedBarcode;
  DateTime? expiryDate;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    _isPermissionGranted = true;

    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _scanBarcode() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        setState(() => scannedBarcode = barcodes.first.rawValue);
      } else {
        _showSnack("No barcode detected");
      }
    } catch (_) {
      _showSnack("Scan failed");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => expiryDate = picked);
  }

  Future<void> _saveItem() async {
    if (nameController.text.isEmpty ||
        scannedBarcode == null ||
        expiryDate == null) {
      _showSnack("All fields required");
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc(widget.categoryId)
        .collection('items')
        .add({
      'name': nameController.text.trim(),
      'barcode': scannedBarcode,
      'expiryDate': Timestamp.fromDate(expiryDate!),
      'createdAt': Timestamp.now(),
    });

    NotificationService.scheduleExpiryReminders(
      itemName: nameController.text.trim(),
      expiryDate: expiryDate!,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    nameController.dispose();
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return const Scaffold(
        body: Center(child: Text("Camera permission required")),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Item")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints:
                BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📷 Responsive Camera Preview
                    AspectRatio(
                      aspectRatio:
                      _cameraController!.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CameraPreview(_cameraController!),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Barcode"),
                      onPressed: _scanBarcode,
                    ),

                    if (scannedBarcode != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        "Barcode: $scannedBarcode",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration:
                      const InputDecoration(labelText: "Item Name"),
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        expiryDate == null
                            ? "Select Expiry Date"
                            : DateFormat.yMMMd().format(expiryDate!),
                      ),
                      trailing:
                      const Icon(Icons.calendar_today),
                      onTap: _pickExpiryDate,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _saveItem,
                      child: const Text("Save Item"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
