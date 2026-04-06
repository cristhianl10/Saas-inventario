import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class BackupService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> generateBackup() async {
    final timestamp = DateTime.now().toIso8601String();

    final categorias = await _apiService.getCategorias();
    final productos = await _apiService.getProductos();
    final proveedores = await _apiService.getProveedores();
    final clientes = await _apiService.getClientes();
    final ventas = await _apiService.getVentas();

    final combos = await _getCombos();
    final tarifas = await _getTarifas();
    final ordenes = await _getOrdenes();
    final historialCompras = await _getHistorialCompras();

    return {
      'version': '1.0',
      'timestamp': timestamp,
      'exportedAt': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'data': {
        'categorias': categorias.map((c) => c.toJson()).toList(),
        'productos': productos.map((p) => p.toJson()).toList(),
        'proveedores': proveedores.map((p) => p.toJson()).toList(),
        'clientes': clientes.map((c) => c.toJson()).toList(),
        'ventas': ventas.map((v) => v.toJson()).toList(),
        'combos': combos,
        'tarifas': tarifas,
        'purchaseOrders': ordenes,
        'purchaseHistory': historialCompras,
      },
      'summary': {
        'categorias': categorias.length,
        'productos': productos.length,
        'proveedores': proveedores.length,
        'clientes': clientes.length,
        'ventas': ventas.length,
      },
    };
  }

  Future<List<Map<String, dynamic>>> _getCombos() async {
    try {
      final response = await _apiService.getCombos();
      return response.map((p) => p.toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getTarifas() async {
    try {
      final response = await _apiService.getTarifasPorProducto(0);
      return response.map((t) => t.toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getOrdenes() async {
    try {
      final response = await _apiService.getPurchaseOrders();
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getHistorialCompras() async {
    try {
      final response = await _apiService.getPurchaseHistory();
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<String> saveBackupToFile() async {
    final backup = await generateBackup();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
    final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'stockflow_backup_$dateStr.json';

    if (kIsWeb) {
      return jsonString;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);
      return file.path;
    }
  }

  Map<String, dynamic>? validateBackup(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      if (!data.containsKey('version') || !data.containsKey('data')) {
        return null;
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<BackupSummary> getBackupSummary(Map<String, dynamic> backup) async {
    final summary = backup['summary'] as Map<String, dynamic>?;
    return BackupSummary(
      categorias: summary?['categorias'] ?? 0,
      productos: summary?['productos'] ?? 0,
      proveedores: summary?['proveedores'] ?? 0,
      clientes: summary?['clientes'] ?? 0,
      ventas: summary?['ventas'] ?? 0,
    );
  }
}

class BackupSummary {
  final int categorias;
  final int productos;
  final int proveedores;
  final int clientes;
  final int ventas;

  BackupSummary({
    required this.categorias,
    required this.productos,
    required this.proveedores,
    required this.clientes,
    required this.ventas,
  });

  int get total => categorias + productos + proveedores + clientes + ventas;
}
