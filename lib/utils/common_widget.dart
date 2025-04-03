import 'package:finance_app/core/app_theme.dart';
import 'package:flutter/material.dart';

class CommonWidgets {
  static Widget buildEmailField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: const TextSpan(
            text: 'Email ',
            style: TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: AppTheme.expenseColor),
              ),
            ],
          ),
        ),
        hintText: 'Nhập email',
        border: const OutlineInputBorder(),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.expenseColor),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.expenseColor),
        ),
        errorStyle: const TextStyle(color: AppTheme.expenseColor),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập email';
        }
        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Email không hợp lệ';
        }
        return null;
      },
    );
  }

  static Widget buildPasswordField(TextEditingController controller, bool isPasswordVisible, VoidCallback toggleVisibility) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: const TextSpan(
            text: 'Mật khẩu ',
            style: TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: AppTheme.expenseColor),
              ),
            ],
          ),
        ),
        hintText: 'Nhập mật khẩu',
        border: const OutlineInputBorder(),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.expenseColor),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.expenseColor),
        ),
        errorStyle: const TextStyle(color: AppTheme.expenseColor),
        suffixIcon: IconButton(
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
      obscureText: !isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập mật khẩu';
        }
        if (value.length < 6) {
          return 'Mật khẩu phải có ít nhất 6 ký tự';
        }
        return null;
      },
    );
  }

  static Widget buildSubmitButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}