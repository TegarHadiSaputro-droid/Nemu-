import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/driver_service.dart';

const Color _ibGreen = Color(0xFF007C3F);
const Color _ibDark = Color(0xFF0F1B11);

TextStyle _ib({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _ibDark,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

// ─────────────────────────────────────────────
//  InboxScreen
//  Dibuka lewat icon amplop di home_screen.dart. Isinya pesan yang
//  dikirim ke users/{uid}/inbox — sekarang baru dipakai buat undangan
//  jadi driver, tapi strukturnya generic (field "type") jadi bisa
//  dipakai buat jenis pesan lain nanti.
// ─────────────────────────────────────────────
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ibDark, size: 20),
        ),
        title: Text('Pesan', style: _ib(size: 18, weight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: uid == null
          ? Center(child: Text('Silakan login dulu', style: _ib(size: 13, color: Colors.black45)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('inbox')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _ibGreen));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Belum ada pesan', style: _ib(size: 13, color: Colors.black45)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) => _InboxTile(doc: docs[i]),
                );
              },
            ),
    );
  }
}

class _InboxTile extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _InboxTile({required this.doc});

  @override
  State<_InboxTile> createState() => _InboxTileState();
}

class _InboxTileState extends State<_InboxTile> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        await DriverService.acceptDriverInvite(widget.doc.id);
      } else {
        await DriverService.declineDriverInvite(widget.doc.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e', style: _ib(size: 12, color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final type = data['type'] as String? ?? '';
    final message = (data['message'] as String?) ?? '';
    final status = (data['status'] as String?) ?? 'pending';
    final isUnread = (data['read'] as bool?) == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? _ibGreen.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUnread ? _ibGreen.withValues(alpha: 0.15) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _ibGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(
                  type == 'driver_invite' ? Icons.local_shipping_rounded : Icons.mail_rounded,
                  color: _ibGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: _ib(size: 12.5, weight: FontWeight.w600))),
            ],
          ),
          if (type == 'driver_invite' && status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _respond(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Tolak', style: _ib(size: 12, weight: FontWeight.bold, color: Colors.black54)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ibGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Terima', style: _ib(size: 12, weight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else if (status != 'pending') ...[
            const SizedBox(height: 6),
            Text(
              status == 'accepted' ? 'Diterima' : 'Ditolak',
              style: _ib(
                size: 11,
                weight: FontWeight.w600,
                color: status == 'accepted' ? _ibGreen : Colors.red.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
