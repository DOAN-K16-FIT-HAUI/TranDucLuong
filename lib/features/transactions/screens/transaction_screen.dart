import 'package:datn_haui/features/transactions/bloc/transation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/transaction_model.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý giao dịch")),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is TransactionLoaded) {
            return ListView.builder(
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                return ListTile(
                  title: Text(transaction.title),
                  subtitle: Text('${transaction.amount} VND'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      context
                          .read<TransactionBloc>()
                          .add(DeleteTransaction(transaction.id));
                    },
                  ),
                );
              },
            );
          } else if (state is TransactionError) {
            return Center(child: Text(state.message));
          }
          return Center(child: Text("Chưa có giao dịch nào"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thêm giao dịch"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: "Tiêu đề")),
            TextField(controller: amountController, decoration: InputDecoration(labelText: "Số tiền"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              final transaction = TransactionModel(
                id: '',
                title: titleController.text,
                amount: double.parse(amountController.text),
                date: DateTime.now(),
              );
              context.read<TransactionBloc>().add(AddTransaction(transaction));
              Navigator.pop(context);
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }
}
