library default_connector;

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class DefaultConnector {
  static final ConnectorConfig config = ConnectorConfig(
    connector: 'default',
    location: 'us-central1',
    serviceId: 'financemanager',
  );

  final FirebaseDataConnect dataConnect;

  DefaultConnector({required this.dataConnect});

  static final Map<FirebaseDataConnect, DefaultConnector> _instances = {};

  static DefaultConnector getInstance(FirebaseDataConnect dataConnect) {
    return _instances.putIfAbsent(dataConnect, () => DefaultConnector(dataConnect: dataConnect));
  }

  static DefaultConnector get instance {
    return getInstance(FirebaseDataConnect.getInstance(config));
  }

  Future<void> fetchData() async {
    try {
      var response = await dataConnect.getData();
      var data = jsonDecode(response);
      // Process the data as needed
    } catch (e) {
      // Handle any errors
      print('Error fetching data: $e');
    }
  }

  Future<void> sendData(Map<String, dynamic> data) async {
    try {
      var jsonData = jsonEncode(data);
      await dataConnect.sendData(jsonData);
      // Handle successful data send
    } catch (e) {
      // Handle any errors
      print('Error sending data: $e');
    }
  }
}

class ConnectorConfig {
  final String connector;
  final String location;
  final String serviceId;

  ConnectorConfig({
    required this.connector,
    required this.location,
    required this.serviceId,
  });
}

class FirebaseDataConnect {
  final ConnectorConfig config;

  FirebaseDataConnect._(this.config);

  static FirebaseDataConnect getInstance(ConnectorConfig config) {
    return FirebaseDataConnect._(config);
  }

  Future<String> getData() async {
    // Implement data fetching logic
    return '{}';
  }

  Future<void> sendData(String data) async {
    // Implement data sending logic
  }
}