import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../config/app_config.dart';
import 'pdf_helper.dart';

class PdfTablaPreciosBuilder {
  static Future<void> generateAndDownload({
    required List<Categoria> categorias,
    required List<Producto> productos,
    required Map<int, List<PrecioTarifa>> tarifasPorProducto,
    Function(String)? onSave,
  }) async {
    await PdfHelper.loadLogo();
    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => PdfHelper.buildHeader(
          title: 'Tabla de Precios',
          subtitle: 'Fecha: $fecha',
        ),
        footer: (context) => PdfHelper.buildFooter(),
        build: (context) =>
            _buildContent(categorias, productos, tarifasPorProducto),
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'tabla_precios_${AppConfig.brandName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (onSave != null) {
      onSave(fileName);
    }
  }

  static List<pw.Widget> _buildContent(
    List<Categoria> categorias,
    List<Producto> productos,
    Map<int, List<PrecioTarifa>> tarifasPorProducto,
  ) {
    final widgets = <pw.Widget>[];

    for (final categoria in categorias) {
      final productosCategoria = productos
          .where((p) => p.categoriaId == categoria.id)
          .toList();
      if (productosCategoria.isEmpty) continue;

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfHelper.primaryLight,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Text('📁 ', style: const pw.TextStyle(fontSize: 14)),
              pw.Text(
                categoria.nombre.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfHelper.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );

      for (final producto in productosCategoria) {
        widgets.add(
          _buildProductoCard(producto, tarifasPorProducto[producto.id] ?? []),
        );
      }
    }

    return widgets;
  }

  static pw.Widget _buildProductoCard(
    Producto producto,
    List<PrecioTarifa> tarifas,
  ) {
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
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200),
              ),
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

  static pw.Widget _buildTablaPrecios(
    double precioBase,
    List<PrecioTarifa> tarifas,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfHelper.primaryLight),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Rango de cantidad',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfHelper.primaryColor,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Precio c/u',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfHelper.primaryColor,
                ),
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
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Text(
                      'BASE',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfHelper.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '\$${precioBase.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ...tarifas.where((t) => t.cantidadMin > 1).map((tarifa) {
          final descuento = precioBase > 0
              ? ((precioBase - tarifa.precioUnitario) / precioBase * 100)
                    .round()
              : 0;

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Row(
                  children: [
                    pw.Text(
                      tarifa.rangoCantidad,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (descuento > 0) ...[
                      pw.SizedBox(width: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          '-$descuento%',
                          style: const pw.TextStyle(
                            fontSize: 6,
                            color: PdfColors.green700,
                          ),
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

  static pw.Widget _buildResumen(
    double precioBase,
    int cantidad,
    List<PrecioTarifa> tarifas,
  ) {
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
        color: PdfHelper.primaryLight,
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
                style: pw.TextStyle(fontSize: 9, color: PdfHelper.primaryColor),
              ),
              pw.Text(
                'Precio por unidad: \$${precioAplicable.toStringAsFixed(2)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
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
              color: PdfHelper.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
