import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'session_service.dart';

/// FinTrack AI — Bank Statement Import Service
/// Handles uploading a PDF bank statement to the backend for AI parsing,
/// and confirming the import by bulk-inserting reviewed transactions.
class StatementImportService {
  final SessionService _session = SessionService();

  /// Upload a PDF bank statement for AI parsing.
  /// Returns a list of extracted transactions plus page count metadata.
  ///
  /// [pdfBytes]    — raw bytes of the selected PDF file
  /// [filename]    — original file name (e.g. 'HDFC_Statement_Sep2026.pdf')
  /// [onProgress]  — optional callback(0.0–1.0) for upload progress
  Future<StatementParseResult> uploadStatement({
    required Uint8List pdfBytes,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    final baseUrl = await ApiConfig.getActiveBaseUrl();
    final uri = Uri.parse('$baseUrl/statement/upload');
    final token = _session.token;

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'statement',
          pdfBytes,
          filename: filename,
        ),
      );

    onProgress?.call(0.05);

    final streamedResponse = await request.send();
    onProgress?.call(0.15);

    final response = await http.Response.fromStream(streamedResponse);
    onProgress?.call(1.0);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to parse statement (${response.statusCode})');
    }

    final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
    final rawList = data['transactions'] as List<dynamic>;

    return StatementParseResult(
      transactions: rawList
          .map((e) => StatementTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      numPages: (data['numPages'] as num?)?.toInt() ?? 1,
      totalFound: (data['totalFound'] as num?)?.toInt() ?? rawList.length,
      filename: data['filename'] as String? ?? filename,
    );
  }

  /// Confirm and bulk-insert the user-reviewed transaction list.
  Future<StatementConfirmResult> confirmImport(
    List<StatementTransaction> transactions,
  ) async {
    final baseUrl = await ApiConfig.getActiveBaseUrl();
    final uri = Uri.parse('$baseUrl/statement/confirm');
    final token = _session.token;

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final body = jsonEncode({
      'transactions': transactions.map((t) => t.toJson()).toList(),
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final bd = jsonDecode(response.body);
      throw Exception(bd['message'] ?? 'Import confirmation failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
    return StatementConfirmResult(
      imported: (data['imported'] as num).toInt(),
      importBatchId: data['importBatchId'] as String,
    );
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class StatementParseResult {
  final List<StatementTransaction> transactions;
  final int numPages;
  final int totalFound;
  final String filename;

  const StatementParseResult({
    required this.transactions,
    required this.numPages,
    required this.totalFound,
    required this.filename,
  });
}

class StatementConfirmResult {
  final int imported;
  final String importBatchId;

  const StatementConfirmResult({
    required this.imported,
    required this.importBatchId,
  });
}

class StatementTransaction {
  final String title;
  final String description;
  final double amount;
  String type; // 'income' | 'expense'
  String category;
  final String paidVia;
  final String date;
  final String source;
  final bool isReimbursable;
  final String note;

  StatementTransaction({
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.paidVia,
    required this.date,
    this.source = 'statement',
    this.isReimbursable = false,
    this.note = '',
  });

  factory StatementTransaction.fromJson(Map<String, dynamic> json) {
    return StatementTransaction(
      title: (json['title'] as String?) ?? (json['merchant'] as String?) ?? 'Bank Transaction',
      description: (json['description'] as String?) ?? '',
      amount: ((json['amount'] as num?) ?? 0).toDouble().abs(),
      type: (json['type'] as String?) == 'income' ? 'income' : 'expense',
      category: (json['category'] as String?) ?? 'Others',
      paidVia: (json['paymentMethod'] as String?) ?? (json['paidVia'] as String?) ?? 'Others',
      date: (json['date'] as String?) ?? DateTime.now().toIso8601String().split('T')[0],
      source: 'statement',
      isReimbursable: (json['isReimbursable'] as bool?) ?? false,
      note: (json['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
        'paidVia': paidVia,
        'date': date,
        'source': source,
        'isReimbursable': isReimbursable,
        'note': note,
      };

  StatementTransaction copyWith({String? category, String? type}) {
    return StatementTransaction(
      title: title,
      description: description,
      amount: amount,
      type: type ?? this.type,
      category: category ?? this.category,
      paidVia: paidVia,
      date: date,
      source: source,
      isReimbursable: isReimbursable,
      note: note,
    );
  }
}
