import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:project_flutter/services/notification_service.dart';

class ScanAddItemScreen extends StatefulWidget {
  final String categoryId;

  const ScanAddItemScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<ScanAddItemScreen> createState() => _ScanAddItemScreenState();
}

class _ScanAddItemScreenState extends State<ScanAddItemScreen> {
  CameraController? _cameraController;
  late BarcodeScanner _barcodeScanner;

  final TextEditingController nameController = TextEditingController();

  bool _isPermissionGranted = false;
  bool _isScanning = true;
  bool _isCameraInitialized = false;

  String? scannedBarcode;
  DateTime? expiryDate;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();
    _requestPermissionAndInit();
  }

  // 🔐 Camera permission
  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _isPermissionGranted = true;
      await _initCamera();
    } else {
      setState(() => _isPermissionGranted = false);
    }
  }

  // 📷 Camera init
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() => _isCameraInitialized = true);

    _startImageStream();
  }

  // 🔄 Scan frames
  void _startImageStream() {
    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isScanning) return;

      final inputImage = _convertCameraImage(image);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        setState(() {
          scannedBarcode = barcodes.first.rawValue;
          _isScanning = false;
        });

        await _cameraController!.stopImageStream();
      }
    });
  }

  // 🔁 Convert camera image
  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }

    final bytes = buffer.done().buffer.asUint8List();
    final imageSize =
    Size(image.width.toDouble(), image.height.toDouble());

    final rotation =
        InputImageRotationValue.fromRawValue(
          _cameraController!.description.sensorOrientation,
        ) ??
            InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // 📅 Pick expiry
  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => expiryDate = picked);
    }
  }

  // 💾 Save item
  Future<void> _saveItem() async {
    if (nameController.text.trim().isEmpty ||
        scannedBarcode == null ||
        expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    try {
      // 1️⃣ Save to Firestore
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

      // 2️⃣ Schedule reminders
      NotificationService.scheduleExpiryReminders(
        itemName: nameController.text.trim(),
        expiryDate: expiryDate!,
      );

      // 3️⃣ Back to items screen
      if (!mounted) return;
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save item")),
      );
    }
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
      body: _isScanning
          ? CameraPreview(_cameraController!)
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Barcode: ${scannedBarcode ?? ""}"),
            const SizedBox(height: 12),

            TextField(
              controller: nameController,
              decoration:
              const InputDecoration(labelText: "Item Name"),
            ),

            const SizedBox(height: 12),
            ListTile(
              title: Text(
                expiryDate == null
                    ? "Select Expiry Date"
                    : DateFormat.yMMMd().format(expiryDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickExpiryDate,
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveItem,
                child: const Text("Save Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
