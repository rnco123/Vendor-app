import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../shared/app_log.dart';
import '../shared/network_check.dart';
import 'vendor_payment_option_screen.dart';
import 'vendor_ui.dart';

class _VendorDoc {
  final String key;
  final String title;
  final bool required;
  String? url;
  String? name;
  bool uploading = false;

  _VendorDoc(this.key, this.title, {this.required = false});
}

class VendorDocumentsScreen extends StatefulWidget {
  const VendorDocumentsScreen({super.key});

  @override
  State<VendorDocumentsScreen> createState() => _VendorDocumentsScreenState();
}

class _VendorDocumentsScreenState extends State<VendorDocumentsScreen> {
  final _docs = [
    _VendorDoc('cnic', 'CNIC (front & back)', required: true),
    _VendorDoc('ntn', 'Business registration / NTN certificate'),
  ];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('vendors').doc(uid).get();
      final docs = snap.data()?['documents'];
      if (docs is! Map || !mounted) return;
      setState(() {
        for (final d in _docs) {
          d.url = docs['${d.key}_url'] as String?;
          d.name = docs['${d.key}_name'] as String?;
        }
      });
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_documents_screen.dart:load', e, st);
    }
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _upload(_VendorDoc doc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (picked == null || !mounted) return;
    if (!await hasInternet()) {
      if (mounted) showVendorSnack(context, offlineMessage);
      return;
    }
    final dot = picked.name.lastIndexOf('.');
    final ext =
        dot == -1 ? 'jpg' : picked.name.substring(dot + 1).toLowerCase();
    setState(() => doc.uploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref('vendor_documents/$uid/${doc.key}.$ext');
      final bytes = await picked.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentType(ext)),
      );
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('vendors').doc(uid).set({
        'documents': {
          '${doc.key}_url': url,
          '${doc.key}_name': picked.name,
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        doc.url = url;
        doc.name = picked.name;
      });
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_documents_screen.dart:upload', e, st);
      if (mounted) {
        final msg = e.toString().toLowerCase();
        showVendorSnack(
          context,
          msg.contains('unauthorized') || msg.contains('permission')
              ? 'Upload blocked by Storage rules for vendor_documents.'
              : 'Could not upload the file. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => doc.uploading = false);
    }
  }

  Future<void> _continue() async {
    final missing = _docs.where((d) => d.required && d.url == null);
    if (missing.isNotEmpty) {
      showVendorSnack(context, 'Please upload your ${missing.first.title}.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(uid).set({
        'profile_step': 'documents_complete',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VendorPaymentOptionScreen()),
      );
    } catch (e, st) {
      AppLog.caught('lib/vendor/vendor_documents_screen.dart:continue', e, st);
      if (mounted) {
        showVendorSnack(context, 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _card(_VendorDoc doc) {
    final done = doc.url != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.primary.withAlpha(40)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              done ? Icons.check : Icons.description_outlined,
              color: done ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: doc.title,
                    children: [
                      if (doc.required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                    ],
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  done ? '${doc.name ?? 'File'} · Uploaded' : 'JPG, PNG or PDF',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: done ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _uploadPill(doc, done),
        ],
      ),
    );
  }

  Widget _uploadPill(_VendorDoc doc, bool done) {
    return GestureDetector(
      onTap: doc.uploading || _saving ? null : () => _upload(doc),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: done ? AppColors.divider : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: doc.uploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    size: 16,
                    color: done ? AppColors.textSecondary : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    done ? 'Re-upload' : 'Upload',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: done ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: vendorSetupAppBar(context, 'Profile Setup'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  const VendorSetupHeading(
                    title: 'Documents',
                    subtitle:
                        'Upload documents so PoolX can verify your business.',
                  ),
                  const SizedBox(height: 24),
                  for (final d in _docs) ...[
                    _card(d),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: VendorPrimaryButton(
                label: 'Continue',
                loading: _saving,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
