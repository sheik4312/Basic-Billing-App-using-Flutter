import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BorrowForm extends StatefulWidget {
  @override
  _BorrowFormState createState() => _BorrowFormState();
}

class _BorrowFormState extends State<BorrowForm> {
  final TextEditingController sellerNameController = TextEditingController();
  final TextEditingController billNoController = TextEditingController();
  final TextEditingController billAmountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> saveBorrowData() async {
    String sellerName = sellerNameController.text.trim();
    String billNo = billNoController.text.trim();
    String billAmount = billAmountController.text.trim();
    String date = dateController.text.trim();

    if (sellerName.isEmpty ||
        billNo.isEmpty ||
        billAmount.isEmpty ||
        date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Reference to the seller document
    DocumentReference sellerRef =
        FirebaseFirestore.instance.collection('sellers').doc(sellerName);

    // Check if the seller document exists
    DocumentSnapshot sellerDoc = await sellerRef.get();
    if (!sellerDoc.exists) {
      // Create a new document with the seller's name if it doesn't exist
      await sellerRef.set({'Name': sellerName});
    }

    // Upload image if available
    String? imageUrl;
    if (_imageFile != null) {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot taskSnapshot = await uploadTask;
      imageUrl = await taskSnapshot.ref.getDownloadURL();
    }

    // Add the bill data to the subcollection 'borrow'
    await sellerRef.collection('borrow').add({
      'Billno': billNo,
      'BillAmount': billAmount,
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl, // Save the image URL
    });

    // Clear the fields after saving
    sellerNameController.clear();
    billNoController.clear();
    billAmountController.clear();
    dateController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text =
            "${pickedDate.toLocal()}".split(' ')[0]; // Format the date
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Borrow Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                color: Colors.grey[200],
                width: double.infinity,
                height: 150,
                child: _imageFile == null
                    ? Center(child: Text('Tap to pick an image'))
                    : Image.file(_imageFile!),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: sellerNameController,
              decoration: const InputDecoration(labelText: 'Seller Name'),
            ),
            TextFormField(
              controller: billNoController,
              decoration: const InputDecoration(labelText: 'Bill No'),
            ),
            TextFormField(
              controller: billAmountController,
              decoration: const InputDecoration(labelText: 'Bill Amount'),
            ),
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Bill Date'),
              readOnly: true, // Prevents user from manually typing
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveBorrowData,
              child: const Text('Save Data'),
            ),
          ],
        ),
      ),
    );
  }
}
