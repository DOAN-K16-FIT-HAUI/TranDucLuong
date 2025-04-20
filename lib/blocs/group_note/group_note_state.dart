import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:flutter/material.dart';

abstract class GroupNoteState extends Equatable {
  const GroupNoteState();

  @override
  List<Object?> get props => [];
}

class GroupNoteInitial extends GroupNoteState {}

class GroupNoteLoading extends GroupNoteState {
  final bool isSearching;

  const GroupNoteLoading({this.isSearching = false});

  @override
  List<Object?> get props => [isSearching];
}

class GroupNoteLoaded extends GroupNoteState {
  final List<GroupNoteModel> allNotes;
  final List<GroupNoteModel> detailedNotes;
  final List<GroupNoteModel> summaryNotes;
  final String searchQuery;
  final bool isSearching;
  final int selectedTab;

  const GroupNoteLoaded({
    required this.allNotes,
    required this.detailedNotes,
    required this.summaryNotes,
    this.searchQuery = '',
    this.isSearching = false,
    this.selectedTab = 0,
  });

  @override
  List<Object?> get props => [
    allNotes,
    detailedNotes,
    summaryNotes,
    searchQuery,
    isSearching,
    selectedTab,
  ];
}

class GroupNoteDetailsLoaded extends GroupNoteState {
  final String noteId;
  final double totalAmountPaid;
  final double totalIncome;
  final double totalExpense;
  final double remainingAmount;
  final Map<String, double> participantBalances;

  const GroupNoteDetailsLoaded({
    required this.noteId,
    required this.totalAmountPaid,
    required this.totalIncome,
    required this.totalExpense,
    required this.remainingAmount,
    required this.participantBalances,
  });

  @override
  List<Object?> get props => [
    noteId,
    totalAmountPaid,
    totalIncome,
    totalExpense,
    remainingAmount,
    participantBalances,
  ];
}

class GroupNoteError extends GroupNoteState {
  final String Function(BuildContext) message;

  const GroupNoteError(this.message);

  @override
  List<Object?> get props => [message];
}