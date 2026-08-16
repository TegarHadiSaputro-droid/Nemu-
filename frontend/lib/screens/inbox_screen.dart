import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/driver_service.dart';
import 'package:frontend/screens/login_screen.dart';

const Color _ibGreen = Color(0xFF007C3F);
const Color _ibDark = Color(0xFF0F1B11);

TextStyle _ib({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _ibDark,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

// ─────────────────────────────────────────────
//  Notifikasi sistem (statis)
//  Dulu tinggal di home_screen.dart sebagai _NotificationSheet (bottom
//  sheet terpisah dari InboxScreen). Sekarang digabung ke sini supaya
//  cuma ada SATU pintu masuk "Pesan & Notifikasi" -- lebih gampang
//  ditemukan user, nggak bikin bingung ada 2 kotak pesan beda tempat.
//
//  Sengaja dikosongin -- akun baru belum punya notifikasi sistem apa pun.
//  Kalau nanti notifikasi sistem beneran datang dari Firestore/backend,
//  tinggal isi list ini dari hasil query, struktur tile-nya nggak perlu
//  berubah.
// ─────────────────────────────────────────────
class _SystemNotifItem {
  final IconData icon;
  final Color iconColor;
  final String title, sub;
  final bool isUnread;
  const _SystemNotifItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.isUnread,
  });
}

const List<_SystemNotifItem> _systemNotifs = [];

// ─────────────────────────────────────────────
//  InboxScreen
//  Dibuka lewat icon amplop di home_screen.dart. Isinya pesan yang
//  dikirim ke users/{uid}/inbox — sekarang baru dipakai buat undangan
//  jadi driver, tapi strukturnya generic (field "type") jadi bisa
//  dipakai buat jenis pesan lain nanti.
// ─────────────────────────────────────────────
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  /// Jumlah notifikasi sistem yang belum dibaca -- dipakai home_screen.dart
  /// buat badge angka merah di tombol lonceng, supaya badge-nya
  /// mencerminkan TOTAL (pesan Firestore + notifikasi sistem), bukan cuma
  /// salah satunya.
  static int get systemUnreadCount => _systemNotifs.where((n) => n.isUnread).length;

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
        title: Text('Pesan & Notifikasi', style: _ib(size: 18, weight: FontWeight.bold)),
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
                if (docs.isEmpty && _systemNotifs.isEmpty) {
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

                // Digabung jadi satu list: pesan dari Firestore (undangan
                // driver, dll) di atas karena lebih actionable/real-time,
                // notifikasi sistem (statis) di bawahnya dengan pemisah.
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...docs.map((doc) => _InboxTile(doc: doc)),
                    if (docs.isNotEmpty && _systemNotifs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Notifikasi', style: _ib(size: 11, color: Colors.black38)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    ..._systemNotifs.map((n) => _SystemNotifTile(item: n)),
                  ],
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

        // acceptDriverInvite() sudah signOut() user di dalamnya. Di sini
        // kita bersihkan seluruh stack navigasi dan arahkan ke LoginScreen
        // supaya user login ulang sebagai Driver -- juga mencegah user
        // "back" ke InboxScreen/HomeScreen lama yang sesinya sudah mati.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil jadi Driver! Silakan login ulang.'),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 800));
        }
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return; // widget sudah dilepas dari stack, jangan lanjut ke finally
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

// ─────────────────────────────────────────────
//  _SystemNotifTile — tile notifikasi sistem (statis, bukan dari inbox
//  Firestore). Sengaja dibuat mirip _InboxTile di atas biar visualnya
//  konsisten walau sumber datanya beda. Tetap disimpan walau
//  _systemNotifs kosong, biar gampang dipakai lagi begitu ada sumber
//  data notifikasi sistem beneran.
// ─────────────────────────────────────────────
class _SystemNotifTile extends StatelessWidget {
  final _SystemNotifItem item;
  const _SystemNotifTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isUnread ? _ibGreen.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isUnread ? _ibGreen.withValues(alpha: 0.15) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: _ib(size: 12.5, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(item.sub, style: _ib(size: 11, color: Colors.black54)),
              ],
            ),
          ),
          if (item.isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4, left: 6),
              decoration: const BoxDecoration(color: _ibGreen, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}