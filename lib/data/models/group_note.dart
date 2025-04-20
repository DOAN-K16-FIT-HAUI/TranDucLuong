import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/transaction.dart';

class GroupNoteModel {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String status;
  final String note;
  final List<String> participants;
  final String creatorId;
  final List<TransactionModel> transactions;

  GroupNoteModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
    required this.note,
    required this.participants,
    required this.creatorId,
    this.transactions = const [],
  });

  factory GroupNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupNoteModel(
      id: doc.id,
      title: data['title'] ?? '',
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      status: data['status'] ?? 'all',
      note: data['note'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      creatorId: data['creator_id'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'amount': amount,
      'status': status,
      'note': note,
      'participants': participants,
      'creator_id': creatorId,
    };
  }

  bool canEdit(String currentUserId) {
    if (participants.isEmpty) {
      return currentUserId == creatorId;
    }
    return currentUserId == creatorId || participants.contains(currentUserId);
  }
}