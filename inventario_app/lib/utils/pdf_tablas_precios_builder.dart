import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../config/app_theme.dart';

class PdfTablaPreciosBuilder {
  static Future<void> generateAndDownload({
    required List<Categoria> categorias,
    required List<Producto> productos,
    required Map<int, List<PrecioTarifa>> tarifasPorProducto,
    Function(String)? onSave,
  }) async {
    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(fecha),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildContent(categorias, productos, tarifasPorProducto),
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'tabla_precios_sublirium_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (onSave != null) {
      onSave(fileName);
    }
  }

  static pw.Widget _buildHeader(String fecha) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.cyan, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SUBLIRIUM',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.cyan700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Tabla de Precios',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.normal,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Fecha de descarga',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
              pw.Text(
                fecha,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado por Sublirium App',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildContent(
    List<Categoria> categorias,
    List<Producto> productos,
    Map<int, List<PrecioTarifa>> tarifasPorProducto,
  ) {
    final widgets = <pw.Widget>[];

    for (final categoria in categorias) {
      final productosCategoria = productos.where((p) => p.categoriaId == categoria.id).toList();
      if (productosCategoria.isEmpty) continue;

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.cyan100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                '📁 ',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                categoria.nombre.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.cyan800,
                ),
              ),
            ],
          ),
        ),
      );

      for (final producto in productosCategoria) {
        widgets.add(_buildProductoCard(producto, tarifasPorProducto[producto.id] ?? []));
      }
    }

    return widgets;
  }

  static pw.Widget _buildProductoCard(Producto producto, List<PrecioTarifa> tarifas) {
    final precioBase = producto.precio ?? 0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  producto.nombre,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (producto.descripcion != null)
                  pw.Text(
                    producto.descripcion!,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          _buildTablaPrecios(precioBase, tarifas),
          pw.SizedBox(height: 8),
          _buildResumen(precioBase, producto.cantidad, tarifas),
        ],
      ),
    );
  }

  static pw.Widget _buildTablaPrecios(double precioBase, List<PrecioTarifa> tarifas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.cyan50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Cantidad',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Precio c/u',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Row(
                children: [
                  pw.Text('1', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(width: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Text('BASE', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '\$${precioBase.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...tarifas.where((t) => t.cantidadMin > 1).map((tarifa) {
          final descuento = precioBase > 0 
              ? ((precioBase - tarifa.precioUnitario) / precioBase * 100).round() 
              : 0;
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Row(
                  children: [
                    pw.Text(tarifa.rangoCantidad, style: const pw.TextStyle(fontSize: 10)),
                    if (descuento > 0) ...[
                      pw.SizedBox(width: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          '-$descuento%',
                          style: const pw.TextStyle(fontSize: 6, color: PdfColors.green700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '\$${tarifa.precioUnitario.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildResumen(double precioBase, int cantidad, List<PrecioTarifa> tarifas) {
    double? precioAplicable;
    
    for (final tarifa in tarifas.where((t) => t.cantidadMin > 1).toList()) {
      if (tarifa.cantidadMin <= cantidad) {
        precioAplicable = tarifa.precioUnitario;
      }
    }
    
    precioAplicable ??= precioBase;
    final total = precioAplicable * cantidad;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.cyan50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Resumen (Stock: $cantidad unidades)',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.cyan700),
              ),
              pw.Text(
                'Precio por unidad: \$${precioAplicable.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Text(
            'VALOR TOTAL',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            '\$${total.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.cyan700,
            ),
          ),
        ],
      ),
    );
  }
}
