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
//  Masih statis/mock (belum dari backend) -- kalau nanti notifikasi
//  sistem sudah beneran datang dari Firestore/backend, tinggal ganti
//  list ini jadi hasil query, struktur tile-nya nggak perlu berubah.
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

const List<_SystemNotifItem> _systemNotifs = [
  _SystemNotifItem(
    icon: Icons.local_shipping_rounded,
    iconColor: Color(0xFFFF7B00),
    title: 'Pesanan dikirim!',
    sub: 'Pak Budi sedang mengantar pesananmu • 2 mnt lalu',
    isUnread: true,
  ),
  _SystemNotifItem(
    icon: Icons.check_circle_rounded,
    iconColor: Color(0xFF007C3F),
    title: 'Pesanan dikonfirmasi',
    sub: 'Lapak Sari menerima pesananmu • 15 mnt lalu',
    isUnread: true,
  ),
  _SystemNotifItem(
    icon: Icons.campaign_rounded,
    iconColor: Color(0xFF0071FF),
    title: 'Promo hari ini!',
    sub: 'Ongkir flat Rp2.000 untuk semua pesanan • 1 jam lalu',
    isUnread: false,
  ),
  _SystemNotifItem(
    icon: Icons.star_rounded,
    iconColor: Color(0xFFF5A623),
    title: 'Beri ulasan',
    sub: 'Bagaimana pesananmu kemarin? Beri bintang yuk! • 1 hari lalu',
    isUnread: false,
  ),
];

// ─────────────────────────────────────────────
//  InboxScreen
// ─────────────────────────────────────────────
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

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

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (docs.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _ibGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pesan & Update Pesanan',
                            style: _ib(size: 13, weight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...docs.map((doc) => _InboxTile(doc: doc)),
                    ],
                    if (docs.isNotEmpty && _systemNotifs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Notifikasi Lainnya', style: _ib(size: 11, color: Colors.black38)),
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
        return;
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

  void _markAsRead() {
    final isUnread = (widget.doc.data()['read'] as bool?) == false;
    if (isUnread) {
      widget.doc.reference.update({'read': true}).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final type = data['type'] as String? ?? '';
    final title = (data['title'] as String?) ?? '';
    final message = (data['message'] as String?) ?? '';
    final status = (data['status'] as String?) ?? 'pending';
    final isUnread = (data['read'] as bool?) == false;
    final createdAt = data['createdAt'] ?? data['created_at'];

    String timeLabel = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) {
        timeLabel = 'Baru saja';
      } else if (diff.inHours < 1) {
        timeLabel = '${diff.inMinutes} mnt lalu';
      } else if (diff.inDays < 1) {
        timeLabel = '${diff.inHours} jam lalu';
      } else {
        timeLabel = '${dt.day}/${dt.month}/${dt.year}';
      }
    }

    IconData icon;
    Color iconColor;
    Color bgColor;

    if (type == 'order_accepted') {
      icon = Icons.check_circle_rounded;
      iconColor = _ibGreen;
      bgColor = _ibGreen.withOpacity(0.12);
    } else if (type == 'order_rejected') {
      icon = Icons.cancel_rounded;
      iconColor = Colors.redAccent;
      bgColor = Colors.redAccent.withOpacity(0.12);
    } else if (type == 'order_update') {
      icon = Icons.local_shipping_rounded;
      iconColor = const Color(0xFFFF7B00);
      bgColor = const Color(0xFFFF7B00).withOpacity(0.12);
    } else if (type == 'driver_invite') {
      icon = Icons.local_shipping_rounded;
      iconColor = _ibGreen;
      bgColor = _ibGreen.withOpacity(0.12);
    } else {
      icon = Icons.notifications_rounded;
      iconColor = _ibGreen;
      bgColor = _ibGreen.withOpacity(0.12);
    }

    return GestureDetector(
      onTap: _markAsRead,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? _ibGreen.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? _ibGreen.withOpacity(0.25) : Colors.grey.shade200,
            width: isUnread ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: _ib(size: 13, weight: FontWeight.bold),
                              ),
                            ),
                            if (timeLabel.isNotEmpty)
                              Text(
                                timeLabel,
                                style: _ib(size: 10, color: Colors.black38),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        message,
                        style: _ib(
                          size: 12,
                          color: title.isNotEmpty ? Colors.black87 : _ibDark,
                          weight: title.isNotEmpty ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      if (title.isEmpty && timeLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(timeLabel, style: _ib(size: 10, color: Colors.black38)),
                      ],
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4, left: 6),
                    decoration: const BoxDecoration(color: _ibGreen, shape: BoxShape.circle),
                  ),
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
            ] else if (type == 'driver_invite' && status != 'pending') ...[
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _SystemNotifTile — tile notifikasi sistem (statis, bukan dari inbox
//  Firestore). Sengaja dibuat mirip _InboxTile di atas biar visualnya
//  konsisten walau sumber datanya beda.
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
        color: item.isUnread ? _ibGreen.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isUnread ? _ibGreen.withOpacity(0.15) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.iconColor.withOpacity(0.12),
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