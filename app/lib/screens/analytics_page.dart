import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/models/transaction.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedTab = 'Total'; // 'Total', 'Income', or 'Expense'
  String _selectedPeriod = 'Week'; // 'Week', 'Month', 'Year'
  int? _selectedBankFilter; // null for 'All', or bankId

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final allTransactions = provider.allTransactions;
        final bankSummaries = provider.bankSummaries;
        
        // Filter transactions based on selected tab
        final filteredTransactions = allTransactions.where((t) {
          if (_selectedTab == 'Total') {
            return true; // Show all transactions
          } else if (_selectedTab == 'Income') {
            return t.type == 'CREDIT';
          } else {
            return t.type == 'DEBIT';
          }
        }).toList();
        
        // Calculate totals for the selected type
        final selectedTotal = filteredTransactions
            .fold(0.0, (sum, t) => sum + t.amount);
        
        // Calculate income and expense totals for display
        final income = allTransactions
            .where((t) => t.type == 'CREDIT')
            .fold(0.0, (sum, t) => sum + t.amount);
        final expenses = allTransactions
            .where((t) => t.type == 'DEBIT')
            .fold(0.0, (sum, t) => sum + t.amount);

        // Get chart data based on selected period and filtered transactions
        final chartData = _getChartData(filteredTransactions, _selectedPeriod, _selectedBankFilter);
        final maxValue = chartData.isEmpty 
            ? 5000.0 
            : chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Statistics Title
                    Center(
                      child: Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Income/Expense Tabs
                    _buildTabSelector(),
                    const SizedBox(height: 24),

                    // Summary Section - show selected type's total
                    _buildSummarySection(income, expenses, selectedTotal, filteredTransactions.length),
                    const SizedBox(height: 24),

                    // Time Period Dropdown
                    _buildTimePeriodSelector(),
                    const SizedBox(height: 24),

                    // Chart
                    _buildChart(chartData, maxValue),
                    const SizedBox(height: 32),

                    // Balance Section - filtered by selected type
                    _buildBalanceSection(bankSummaries, filteredTransactions),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Total', _selectedTab == 'Total'),
          ),
          Expanded(
            child: _buildTabButton('Income', _selectedTab == 'Income'),
          ),
          Expanded(
            child: _buildTabButton('Expense', _selectedTab == 'Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(double income, double expenses, double selectedTotal, int transactionCount) {
    if (_selectedTab == 'Total') {
      return Column(
        children: [
          _buildSummaryRow(
            'Income',
            income,
            Colors.blue,
            isSelected: false,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Expenses',
            expenses,
            Colors.white,
            isSelected: false,
          ),
        ],
      );
    } else {
      // Show only the selected type
      return _buildSummaryRow(
        _selectedTab,
        selectedTotal,
        _selectedTab == 'Income' ? Colors.blue : Colors.white,
        isSelected: true,
      );
    }
  }

  Widget _buildSummaryRow(String label, double amount, Color indicatorColor, {bool isSelected = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          'ETB ${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Week', 'Month', 'Year'].map((period) {
                  return ListTile(
                    title: Text(period),
                    onTap: () {
                      setState(() => _selectedPeriod = period);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedPeriod,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<ChartDataPoint> data, double maxValue) {
    if (data.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Find the highest point and current day
    int highestIndex = 0;
    double highestValue = 0;
    for (int i = 0; i < data.length; i++) {
      if (data[i].value > highestValue) {
        highestValue = data[i].value;
        highestIndex = i;
      }
    }

    // Find current day index based on actual current date
    int currentDayIndex = _getCurrentDayIndex(data);

    return Stack(
      children: [
        Container(
          height: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final isCurrentDay = index == currentDayIndex;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                        child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrentDay
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data[index].label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.w500,
                            color: isCurrentDay
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxValue / 5,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'ETB ${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isHighlighted = index == highestIndex || index == currentDayIndex;
                  return FlDotCirclePainter(
                    radius: isHighlighted ? 7 : 0,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: isHighlighted ? 4 : 0,
                    strokeColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  Theme.of(context).colorScheme.surfaceVariant,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((spotIndex) {
                final spot = barData.spots[spotIndex];
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2,
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 8,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 3,
                        strokeColor: Theme.of(context).scaffoldBackgroundColor,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
            ),
          ),
        ),
        // Value badge for highlighted point
        if (data.isNotEmpty && highestIndex < data.length)
          Positioned(
            left: 20 + (highestIndex / (data.length - 1).clamp(1, double.infinity)) * (MediaQuery.of(context).size.width - 120),
            top: 20 + (1 - (highestValue / maxValue)) * 280 - 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_selectedTab == 'Income' ? '+' : _selectedTab == 'Expense' ? '-' : ''}ETB ${_formatCurrency(highestValue)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceSection(List bankSummaries, List<Transaction> filteredTransactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Balance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Filter Tabs
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All', _selectedBankFilter == null),
              const SizedBox(width: 8),
              ...bankSummaries.map((bank) {
                final bankInfo = AppConstants.banks.firstWhere(
                  (b) => b.id == bank.bankId,
                  orElse: () => AppConstants.banks.first,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    bankInfo.shortName,
                    _selectedBankFilter == bank.bankId,
                    onTap: () => setState(() => _selectedBankFilter = bank.bankId),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bank Cards - show filtered totals
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: bankSummaries.map((bank) {
              final bankInfo = AppConstants.banks.firstWhere(
                (b) => b.id == bank.bankId,
                orElse: () => AppConstants.banks.first,
              );
              // Calculate total for this bank based on selected type
              final bankTotal = filteredTransactions
                  .where((t) => t.bankId == bank.bankId)
                  .fold(0.0, (sum, t) => sum + t.amount);
              return _buildBankCard(bankInfo.shortName, bankTotal);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selectedBankFilter = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankCard(String title, double value) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'ETB ${_formatCurrency(value)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  List<ChartDataPoint> _getChartData(
    List<Transaction> transactions,
    String period,
    int? bankFilter,
  ) {
    // Filter by bank if selected (transactions are already filtered by type)
    var filteredTransactions = transactions;
    if (bankFilter != null) {
      filteredTransactions = transactions.where((t) => t.bankId == bankFilter).toList();
    }

    if (period == 'Week') {
      return _getWeeklyData(filteredTransactions);
    } else if (period == 'Month') {
      return _getMonthlyData(filteredTransactions);
    } else {
      return _getYearlyData(filteredTransactions);
    }
  }

  List<ChartDataPoint> _getWeeklyData(List<Transaction> transactions) {
    final now = DateTime.now();
    // Get the start of the week (Saturday, as per the design)
    // Find the most recent Saturday
    int daysSinceSaturday = (now.weekday + 1) % 7; // Convert to Saturday-based week
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceSaturday));
    final days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    
    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayTransactions = transactions.where((t) {
        if (t.time == null) return false;
        try {
          final transactionDate = DateTime.parse(t.time!);
          return transactionDate.year == date.year &&
              transactionDate.month == date.month &&
              transactionDate.day == date.day;
        } catch (e) {
          return false;
        }
      }).toList();
      
      final total = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      return ChartDataPoint(
        label: days[index],
        value: total,
        date: date,
      );
    });
  }

  List<ChartDataPoint> _getMonthlyData(List<Transaction> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weeksInMonth = ((now.difference(monthStart).inDays) / 7).ceil();
    
    return List.generate(weeksInMonth.clamp(1, 4), (index) {
      final weekStart = monthStart.add(Duration(days: index * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekTransactions = transactions.where((t) {
        if (t.time == null) return false;
        try {
          final transactionDate = DateTime.parse(t.time!);
          return transactionDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              transactionDate.isBefore(weekEnd.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
      
      final total = weekTransactions.fold(0.0, (sum, t) => sum + t.amount);
      return ChartDataPoint(
        label: 'W${index + 1}',
        value: total,
        date: weekStart,
      );
    });
  }

  List<ChartDataPoint> _getYearlyData(List<Transaction> transactions) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return List.generate(12, (index) {
      final monthTransactions = transactions.where((t) {
        if (t.time == null) return false;
        try {
          final transactionDate = DateTime.parse(t.time!);
          return transactionDate.year == now.year && transactionDate.month == index + 1;
        } catch (e) {
          return false;
        }
      }).toList();
      
      final total = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);
      return ChartDataPoint(
        label: months[index],
        value: total,
        date: DateTime(now.year, index + 1, 1),
      );
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  int _getCurrentDayIndex(List<ChartDataPoint> data) {
    final now = DateTime.now();
    
    if (_selectedPeriod == 'Week') {
      // Find the index that matches today's date
      for (int i = 0; i < data.length; i++) {
        if (data[i].date != null) {
          final dataDate = data[i].date!;
          if (dataDate.year == now.year &&
              dataDate.month == now.month &&
              dataDate.day == now.day) {
            return i;
          }
        }
      }
      // Fallback: return today's weekday index (0-6, where 0 is Saturday)
      int daysSinceSaturday = (now.weekday + 1) % 7;
      return daysSinceSaturday.clamp(0, data.length - 1);
    } else if (_selectedPeriod == 'Month') {
      // Find current week index
      final monthStart = DateTime(now.year, now.month, 1);
      final weekNumber = ((now.difference(monthStart).inDays) / 7).floor();
      return weekNumber.clamp(0, data.length - 1);
    } else {
      // For year view, return current month index
      return (now.month - 1).clamp(0, data.length - 1);
    }
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;

  ChartDataPoint({required this.label, required this.value, this.date});
}
