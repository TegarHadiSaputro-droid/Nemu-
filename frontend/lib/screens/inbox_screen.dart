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
//  Notifikasi sistem (statis)
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
    icon: Icons.campaign_rounded,
    iconColor: Color(0xFF0071FF),
    title: 'Promo hari ini!',
    sub: 'Ongkir hemat dan produk segar dari pasar terdekat • 1 jam lalu',
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
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final email = user?.email?.trim().toLowerCase();

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
                  .snapshots(),
              builder: (context, userInboxSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: (email == null || email.isEmpty)
                      ? null
                      : FirebaseFirestore.instance
                          .collection('driver_invitations')
                          .where('driver_email', isEqualTo: email)
                          .snapshots(),
                  builder: (context, driverInvitesSnap) {
                    if (userInboxSnap.connectionState == ConnectionState.waiting &&
                        driverInvitesSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _ibGreen));
                    }

                    final userInboxDocs = userInboxSnap.data?.docs ?? [];
                    final driverInviteDocs = driverInvitesSnap.data?.docs ?? [];

                    // Gabungkan dan deduplikasi notifikasi
                    final items = <_CombinedInboxItem>[];
                    final seenInvitationIds = <String>{};

                    // 1. Tambahkan dari driver_invitations (prioritas tinggi)
                    for (final doc in driverInviteDocs) {
                      final data = doc.data();
                      final invId = (data['invitation_id'] as String?) ?? doc.id;
                      seenInvitationIds.add(invId);
                      seenInvitationIds.add(doc.id);

                      final storeName = (data['seller_store_name'] as String?) ?? 'Penjual';
                      final sellerId = (data['seller_id'] as String?) ?? '';
                      final status = (data['status'] as String?) ?? 'pending';

                      items.add(_CombinedInboxItem(
                        id: doc.id,
                        invitationId: invId,
                        type: 'driver_invite',
                        title: 'Undangan Driver Resmi',
                        message: '$storeName mengundang Anda untuk menjadi Driver resmi.',
                        status: status,
                        storeName: storeName,
                        sellerId: sellerId,
                        driverEmail: (data['driver_email'] as String?) ?? email,
                        isUnread: status == 'pending',
                        createdAt: data['created_at'] ?? data['createdAt'],
                        isDriverInvitationDoc: true,
                        docRef: doc.reference,
                      ));
                    }

                    // 2. Tambahkan dari users/{uid}/inbox
                    for (final doc in userInboxDocs) {
                      final data = doc.data();
                      final invId = (data['invitation_id'] as String?) ?? doc.id;
                      final type = data['type'] as String? ?? '';

                      if (type == 'driver_invite' && (seenInvitationIds.contains(invId) || seenInvitationIds.contains(doc.id))) {
                        // Sudah ditangani lewat driver_invitations
                        continue;
                      }

                      items.add(_CombinedInboxItem(
                        id: doc.id,
                        invitationId: invId,
                        type: type,
                        title: (data['title'] as String?) ?? (type == 'driver_invite' ? 'Undangan Driver' : ''),
                        message: (data['message'] as String?) ?? '',
                        status: (data['status'] as String?) ?? 'pending',
                        storeName: (data['storeName'] as String?) ?? (data['seller_store_name'] as String?) ?? '',
                        sellerId: (data['seller_id'] as String?) ?? (data['fromUid'] as String?) ?? '',
                        driverEmail: (data['driver_email'] as String?) ?? email,
                        isUnread: (data['read'] as bool?) == false,
                        createdAt: data['createdAt'] ?? data['created_at'],
                        isDriverInvitationDoc: false,
                        docRef: doc.reference,
                        proofPhotoUrl: data['proofPhotoUrl'] as String?,
                      ));
                    }

                    // Urutkan berdasarkan waktu descending
                    items.sort((a, b) {
                      final timeA = a.createdAt is Timestamp ? (a.createdAt as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                      final timeB = b.createdAt is Timestamp ? (b.createdAt as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                      return timeB.compareTo(timeA);
                    });

                    if (items.isEmpty && _systemNotifs.isEmpty) {
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
                        if (items.isNotEmpty) ...[
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
                                'Pesan & Undangan',
                                style: _ib(size: 13, weight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...items.map((item) => _InboxTile(item: item)),
                        ],
                        if (items.isNotEmpty && _systemNotifs.isNotEmpty) ...[
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
                );
              },
            ),
    );
  }
}

class _CombinedInboxItem {
  final String id;
  final String invitationId;
  final String type;
  final String title;
  final String message;
  final String status;
  final String storeName;
  final String sellerId;
  final String? driverEmail;
  final bool isUnread;
  final dynamic createdAt;
  final bool isDriverInvitationDoc;
  final DocumentReference docRef;
  final String? proofPhotoUrl;

  _CombinedInboxItem({
    required this.id,
    required this.invitationId,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.storeName,
    required this.sellerId,
    required this.driverEmail,
    required this.isUnread,
    required this.createdAt,
    required this.isDriverInvitationDoc,
    required this.docRef,
    this.proofPhotoUrl,
  });
}

class _InboxTile extends StatefulWidget {
  final _CombinedInboxItem item;
  const _InboxTile({required this.item});

  @override
  State<_InboxTile> createState() => _InboxTileState();
}

class _InboxTileState extends State<_InboxTile> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        await DriverService.acceptDriverInvite(
          widget.item.id,
          sellerId: widget.item.sellerId,
          driverInvitationDocId: widget.item.invitationId,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selamat! Akun Anda kini aktif sebagai Driver.',
              style: _ib(size: 12, color: Colors.white, weight: FontWeight.bold),
            ),
            backgroundColor: _ibGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );

        // Tutup InboxScreen agar user langsung melihat HomeScreen3 yang sudah dirender real-time
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        await DriverService.declineDriverInvite(
          widget.item.id,
          driverInvitationDocId: widget.item.invitationId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Undangan driver ditolak.', style: _ib(size: 12, color: Colors.white)),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e', style: _ib(size: 12, color: Colors.white)),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _markAsRead() {
    if (widget.item.isUnread && !widget.item.isDriverInvitationDoc) {
      widget.item.docRef.update({'read': true}).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final type = item.type;
    final title = item.title;
    final message = item.message;
    final status = item.status;
    final isUnread = item.isUnread;
    final createdAt = item.createdAt;

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
    } else if (type == 'order_delivered') {
      icon = Icons.done_all_rounded;
      iconColor = _ibGreen;
      bgColor = _ibGreen.withOpacity(0.12);
    } else if (type == 'order_update') {
      icon = Icons.local_shipping_rounded;
      iconColor = const Color(0xFFFF7B00);
      bgColor = const Color(0xFFFF7B00).withOpacity(0.12);
    } else if (type == 'driver_invite') {
      icon = Icons.two_wheeler_rounded;
      iconColor = _ibGreen;
      bgColor = _ibGreen.withOpacity(0.12);
    } else {
      icon = Icons.notifications_rounded;
      iconColor = _ibGreen;
      bgColor = _ibGreen.withOpacity(0.12);
    }

    final isPendingInvite = type == 'driver_invite' && status == 'pending';

    return GestureDetector(
      onTap: _markAsRead,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPendingInvite
              ? _ibGreen.withOpacity(0.04)
              : (isUnread ? _ibGreen.withOpacity(0.03) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPendingInvite
                ? _ibGreen.withOpacity(0.35)
                : (isUnread ? _ibGreen.withOpacity(0.2) : Colors.grey.shade200),
            width: isPendingInvite ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.isNotEmpty ? title : 'Pemberitahuan',
                              style: _ib(size: 13.5, weight: FontWeight.bold),
                            ),
                          ),
                          if (timeLabel.isNotEmpty)
                            Text(
                              timeLabel,
                              style: _ib(size: 10.5, color: Colors.black38),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: _ib(
                          size: 12.5,
                          color: isPendingInvite ? Colors.black87 : Colors.black54,
                          weight: isPendingInvite ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnread && !isPendingInvite)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4, left: 6),
                    decoration: const BoxDecoration(color: _ibGreen, shape: BoxShape.circle),
                  ),
              ],
            ),
            if (isPendingInvite) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _respond(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Tolak', style: _ib(size: 12, weight: FontWeight.bold, color: Colors.red.shade600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : () => _respond(true),
                      icon: _busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Terima Undangan',
                        style: _ib(size: 12, weight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ibGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (type == 'driver_invite' && status != 'pending') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (status == 'accepted' ? _ibGreen : Colors.red.shade600).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'accepted' ? '✓ Undangan Diterima' : '✕ Undangan Ditolak',
                  style: _ib(
                    size: 11,
                    weight: FontWeight.bold,
                    color: status == 'accepted' ? _ibGreen : Colors.red.shade600,
                  ),
                ),
              ),
            ] else if (type == 'order_delivered') ...[
              // Tampilkan foto bukti pengiriman jika ada
              if (item.proofPhotoUrl != null && item.proofPhotoUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.proofPhotoUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '📷 Foto bukti pengiriman oleh driver',
                  style: _ib(size: 10.5, color: Colors.black45),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _ibGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✅ Pesanan selesai diantarkan',
                  style: _ib(size: 11, weight: FontWeight.bold, color: _ibGreen),
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
//  _SystemNotifTile
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