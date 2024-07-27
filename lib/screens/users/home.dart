import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aturin/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class Income {
  final int id;
  final String noPembelian;
  final String namaPembeli;
  final double totalPembelian;
  final DateTime createdAt;
  final List<IncomeItem> items;

  Income({
    required this.id,
    required this.noPembelian,
    required this.namaPembeli,
    required this.totalPembelian,
    required this.createdAt,
    required this.items,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      noPembelian: json['no_pembelian'],
      namaPembeli: json['nama_pembeli'],
      totalPembelian: json['total_pembelian'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List<dynamic>)
          .map((item) => IncomeItem.fromJson(item))
          .toList(),
    );
  }
}

class IncomeItem {
  final int id;
  final int jumlahPembelian;
  final double hargaSatuan;
  final double subtotal;
  final double discount;
  final IncomeCategory category;

  IncomeItem({
    required this.id,
    required this.jumlahPembelian,
    required this.hargaSatuan,
    required this.subtotal,
    required this.discount,
    required this.category,
  });

  factory IncomeItem.fromJson(Map<String, dynamic> json) {
    return IncomeItem(
      id: json['id'],
      jumlahPembelian: json['jumlah_pembelian'],
      hargaSatuan: json['harga_satuan'].toDouble(),
      subtotal: json['subtotal'].toDouble(),
      discount: json['discount'].toDouble(),
      category: IncomeCategory.fromJson(json['category']),
    );
  }
}

class IncomeCategory {
  final int id;
  final String namaBarang;
  final int hargaBarang;
  final double discount;

  IncomeCategory({
    required this.id,
    required this.namaBarang,
    required this.hargaBarang,
    required this.discount,
  });

  factory IncomeCategory.fromJson(Map<String, dynamic> json) {
    return IncomeCategory(
      id: json['id'],
      namaBarang: json['nama_barang'],
      hargaBarang: json['harga_barang'],
      discount: json['discount'].toDouble(),
    );
  }
}

class Expense {
  final int id;
  final String deskripsi;
  final double amount;
  final DateTime createdAt;
  final ExpenseCategory category;

  Expense({
    required this.id,
    required this.deskripsi,
    required this.amount,
    required this.createdAt,
    required this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      deskripsi: json['deskripsi'],
      amount: json['amount'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      category: ExpenseCategory.fromJson(json['category']),
    );
  }
}

class ExpenseCategory {
  final int id;
  final String nama;
  final String deskripsi;

  ExpenseCategory({
    required this.id,
    required this.nama,
    required this.deskripsi,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeContent();
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchData();
  }

  Future<Map<String, dynamic>> fetchData() async {
    print('Fetching data...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    print('UserId in HomeContent: $userId');

    if (userId == null) {
      throw Exception('User ID is null');
    }

    try {
      final incomesResponse = await http.get(
        Uri.parse('${dotenv.env['BACKEND_URL']}/incomes/user/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      final expensesResponse = await http.get(
        Uri.parse('${dotenv.env['BACKEND_URL']}/expense/user/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (incomesResponse.statusCode == 200 &&
          expensesResponse.statusCode == 200) {
        final List<dynamic> incomesData = json.decode(incomesResponse.body);
        final List<dynamic> expensesData = json.decode(expensesResponse.body);

        final List<Income> incomes =
            incomesData.map((income) => Income.fromJson(income)).toList();
        final List<Expense> expenses =
            expensesData.map((expense) => Expense.fromJson(expense)).toList();

        final double totalIncome =
            incomes.fold(0.0, (sum, income) => sum + income.totalPembelian);
        final double totalExpense =
            expenses.fold(0.0, (sum, expense) => sum + expense.amount);

        final incomeSpots =
            getSpots(incomes, (income) => income.totalPembelian);
        final expenseSpots = getSpots(expenses, (expense) => expense.amount);

        final incomeCategoryTotals = getCategoryTotals(
          incomes,
          (income) => income.items.first.category.namaBarang,
          (income) => income.totalPembelian,
        );
        final expenseCategoryTotals = getCategoryTotals(
          expenses,
          (expense) => expense.category.nama,
          (expense) => expense.amount,
        );

        final Set<String> categorySet =
            Set<String>.from(incomeCategoryTotals.keys)
              ..addAll(expenseCategoryTotals.keys);
        final List<String> categories = categorySet.toList();

        final incomeTotals = categories
            .map((category) => incomeCategoryTotals[category] ?? 0.0)
            .toList();
        final expenseTotals = categories
            .map((category) => expenseCategoryTotals[category] ?? 0.0)
            .toList();

        final maxAmount = [
          ...incomeTotals,
          ...expenseTotals,
        ].reduce((max, value) => value > max ? value : max);

        return {
          'incomes': incomes,
          'expenses': expenses,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
          'incomeSpots': incomeSpots,
          'expenseSpots': expenseSpots,
          'categories': categories,
          'incomeTotals': incomeTotals,
          'expenseTotals': expenseTotals,
          'maxAmount': maxAmount,
        };
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAllData() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final incomesResponse = await http.get(
      Uri.parse('${dotenv.env['BACKEND_URL']}/incomes/user/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    final expensesResponse = await http.get(
      Uri.parse('${dotenv.env['BACKEND_URL']}/expense/user/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (incomesResponse.statusCode == 200 &&
        expensesResponse.statusCode == 200) {
      final List<dynamic> incomesData = json.decode(incomesResponse.body);
      final List<dynamic> expensesData = json.decode(expensesResponse.body);

      return {
        'incomes':
            incomesData.map((income) => Income.fromJson(income)).toList(),
        'expenses':
            expensesData.map((expense) => Expense.fromJson(expense)).toList(),
      };
    } else {
      throw Exception('Failed to fetch all data for report');
    }
  }

  List<FlSpot> getSpots(List<dynamic> data, double Function(dynamic) getValue) {
    final Map<DateTime, double> dailyData = {};

    for (var item in data) {
      final date = DateTime(
          item.createdAt.year, item.createdAt.month, item.createdAt.day);
      dailyData[date] = (dailyData[date] ?? 0) + getValue(item);
    }

    return dailyData.entries
        .map((entry) =>
            FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  Map<String, double> getCategoryTotals(List<dynamic> data,
      String Function(dynamic) getCategory, double Function(dynamic) getValue) {
    final Map<String, double> totals = {};

    for (var item in data) {
      final category = getCategory(item);
      totals[category] = (totals[category] ?? 0) + getValue(item);
    }

    return totals;
  }

  List<FlSpot> getIncomeSpots(List<Income> incomes) {
    final Map<DateTime, double> dailyIncomes = {};

    for (var income in incomes) {
      final date = DateTime(
          income.createdAt.year, income.createdAt.month, income.createdAt.day);
      dailyIncomes[date] = (dailyIncomes[date] ?? 0) + income.totalPembelian;
    }

    return dailyIncomes.entries
        .map((entry) =>
            FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> getExpenseSpots(List<Expense> expenses) {
    final Map<DateTime, double> dailyExpenses = {};

    for (var expense in expenses) {
      final date = DateTime(expense.createdAt.year, expense.createdAt.month,
          expense.createdAt.day);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0) + expense.amount;
    }

    return dailyExpenses.entries
        .map((entry) =>
            FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  Future<void> exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow(['ID', 'Nama Pembeli', 'Total Pembelian', 'Tanggal']);

    final data = await fetchAllData();
    final List<Income> incomes = data['incomes'];
    final List<Expense> expenses = data['expenses'];

    for (var income in incomes) {
      sheet.appendRow([
        income.id,
        income.namaPembeli,
        income.totalPembelian,
        DateFormat('yyyy-MM-dd').format(income.createdAt),
      ]);
    }

    for (var expense in expenses) {
      sheet.appendRow([
        expense.id,
        expense.deskripsi,
        expense.amount,
        DateFormat('yyyy-MM-dd').format(expense.createdAt),
      ]);
    }

    final directory = await getExternalStorageDirectory();
    final path = '${directory?.path}/Financial_Report.xlsx';
    final file = File(path);
    await file.writeAsBytes(await excel.save() ?? []);

    await OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Belanja'),
      //   //   actions: [
      //   //     IconButton(
      //   //       icon: Icon(Icons.file_download),
      //   //       onPressed: exportToExcel,
      //   //     ),
      //   //   ],
      // ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          final List<Income> incomes = data['incomes'];
          final List<Expense> expenses = data['expenses'];
          final double totalIncome = data['totalIncome'];
          final double totalExpense = data['totalExpense'];
          final List<FlSpot> incomeSpots = data['incomeSpots'];
          final List<FlSpot> expenseSpots = data['expenseSpots'];
          final List<String> categories = data['categories'];
          final List<double> incomeTotals = data['incomeTotals'];
          final List<double> expenseTotals = data['expenseTotals'];
          final double maxAmount = data['maxAmount'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: exportToExcel,
                    child: Text('Download Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildChart(
                    'Income vs Expense Trend',
                    LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: SideTitles(showTitles: true),
                          bottomTitles: SideTitles(
                            showTitles: true,
                            getTitles: (value) {
                              final DateTime date =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      value.toInt());
                              return DateFormat('MMM d').format(date);
                            },
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            colors: [Colors.green],
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                                show: true,
                                colors: [Colors.green.withOpacity(0.3)]),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            colors: [Colors.red],
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                                show: true,
                                colors: [Colors.red.withOpacity(0.3)]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildChart(
                    'Income vs Expense Overview',
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: totalIncome,
                            title: 'Income',
                            radius: 50,
                            titleStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: totalExpense,
                            title: 'Expense',
                            radius: 50,
                            titleStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildChart(
                    'Category Comparison',
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxAmount,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: SideTitles(
                            showTitles: true,
                            getTitles: (double value) {
                              return categories[value.toInt()];
                            },
                            rotateAngle: 45,
                          ),
                          leftTitles: SideTitles(showTitles: true),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(categories.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                y: incomeTotals[index],
                                colors: [Colors.green],
                                width: 16,
                              ),
                              BarChartRodData(
                                y: expenseTotals[index],
                                colors: [Colors.red],
                                width: 16,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTransactionDetails(totalIncome, totalExpense),
                  SizedBox(height: 16),
                  _buildTransactionList('Recent Incomes', incomes),
                  SizedBox(height: 16),
                  _buildTransactionList('Recent Expenses', expenses),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(String title, Widget chart) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(double totalIncome, double totalExpense) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Total Income', totalIncome),
            _buildDetailRow('Total Expense', totalExpense),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Text(
            'Rp ${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String title, List<dynamic> transactions) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 3 ? 3 : transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(
                    transaction is Income
                        ? transaction.namaPembeli
                        : transaction.deskripsi,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(transaction.createdAt),
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    'Rp ${NumberFormat('#,###').format(transaction is Income ? transaction.totalPembelian : transaction.amount)}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
