import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SimplePendulumScreen extends StatefulWidget {
  const SimplePendulumScreen({super.key});

  @override
  State<SimplePendulumScreen> createState() => _SimplePendulumScreenState();
}

class _SimplePendulumScreenState extends State<SimplePendulumScreen> {
  // Data model: Length (m), Time for N oscillations (s), N oscillations
  final List<Map<String, double>> _dataPoints = [];
  
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _nController = TextEditingController(text: '10');

  double? _calculatedGravity;
  double? _rSquared;

  void _addDataPoint() {
    final double? length = double.tryParse(_lengthController.text);
    final double? time = double.tryParse(_timeController.text);
    final double? n = double.tryParse(_nController.text);

    if (length != null && time != null && n != null && n > 0) {
      setState(() {
        _dataPoints.add({
          'L': length, // Length in meters (assuming user enters meters, or we can convert)
          't': time,   // Total time
          'N': n,      // Number of oscillations
          'T': time / n, // Period
          'T2': pow(time / n, 2).toDouble(), // Period squared
        });
        _lengthController.clear();
        _timeController.clear();
        _calculateRegression();
      });
    }
  }

  void _calculateRegression() {
    if (_dataPoints.length < 2) return;

    // Linear Regression: T^2 = (4*pi^2 / g) * L
    // y = m * x
    // y = T^2, x = L
    // m = 4*pi^2 / g  => g = 4*pi^2 / m

    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    int n = _dataPoints.length;

    for (var point in _dataPoints) {
      double x = point['L']!;
      double y = point['T2']!;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    // Slope m (assuming intercept is 0 for ideal pendulum, but standard regression includes b)
    // Using standard linear regression y = mx + b
    double m = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    // double b = (sumY - m * sumX) / n;

    setState(() {
      // g = 4 * pi^2 / m
      _calculatedGravity = (4 * pow(pi, 2)) / m;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Péndulo Simple'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingrese los datos experimentales:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lengthController,
                    decoration: const InputDecoration(
                      labelText: 'Longitud L (m)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Tiempo t (s)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nController,
                    decoration: const InputDecoration(
                      labelText: 'Oscilaciones N',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addDataPoint,
              child: const Text('Agregar Dato'),
            ),
            const Divider(height: 30),
            
            if (_dataPoints.isNotEmpty) ...[
              const Text(
                'Tabla de Datos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('L (m)')),
                    DataColumn(label: Text('t (s)')),
                    DataColumn(label: Text('T (s)')),
                    DataColumn(label: Text('T² (s²)')),
                    DataColumn(label: Text('Acción')),
                  ],
                  rows: _dataPoints.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Map<String, double> data = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(data['L']!.toStringAsFixed(3))),
                      DataCell(Text(data['t']!.toStringAsFixed(2))),
                      DataCell(Text(data['T']!.toStringAsFixed(3))),
                      DataCell(Text(data['T2']!.toStringAsFixed(3))),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _dataPoints.removeAt(idx);
                            _calculateRegression();
                          });
                        },
                      )),
                    ]);
                  }).toList(),
                ),
              ),
              const Divider(height: 30),
            ],

            if (_calculatedGravity != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Resultados del Análisis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Gravedad Experimental (g): ${_calculatedGravity!.toStringAsFixed(3)} m/s²',
                        style: const TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                      const Text(
                        '(Calculado mediante regresión lineal de T² vs L)',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gráfica T² vs L:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1)),
                          reservedSize: 30,
                        ),
                        axisNameWidget: const Text('Longitud L (m)'),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1)),
                          reservedSize: 40,
                        ),
                        axisNameWidget: const Text('Periodo² T² (s²)'),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      // Data Points
                      LineChartBarData(
                        spots: _dataPoints
                            .map((p) => FlSpot(p['L']!, p['T2']!))
                            .toList(),
                        isCurved: false,
                        color: Colors.blue,
                        barWidth: 0,
                        dotData: const FlDotData(show: true),
                      ),
                      // Regression Line (Simplified visual)
                      if (_dataPoints.length >= 2)
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 0),
                            FlSpot(
                              _dataPoints.map((e) => e['L']!).reduce(max),
                              _dataPoints.map((e) => e['L']!).reduce(max) * (4 * pow(pi, 2) / _calculatedGravity!),
                            ),
                          ],
                          isCurved: false,
                          color: Colors.red.withOpacity(0.5),
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Resumen Generado:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SelectableText(
                  'En esta práctica de laboratorio se estudió el comportamiento del péndulo simple. '
                  'Se midió el periodo de oscilación (T) para diferentes longitudes (L) del péndulo. '
                  'Al graficar T² en función de L, se obtuvo una relación lineal, lo cual confirma la teoría '
                  'de que el periodo al cuadrado es proporcional a la longitud. '
                  'A partir de la pendiente de la gráfica, se calculó el valor experimental de la gravedad, '
                  'obteniendo g = ${_calculatedGravity!.toStringAsFixed(3)} m/s². '
                  'Este valor se puede comparar con el valor teórico (9.8 m/s²) para determinar el error porcentual.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
