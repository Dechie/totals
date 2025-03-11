import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/main.dart';
import 'package:totals/utils/text_utils.dart';

class BanksSummaryList extends StatefulWidget {
  final List<BankSummary> banks;

  BanksSummaryList({required this.banks});

  @override
  State<BanksSummaryList> createState() => _BanksSummaryListState();
}

class _BanksSummaryListState extends State<BanksSummaryList> {
  int? isExpanded;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Add Expanded to give ListView a defined size
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.banks.length,
        itemBuilder: (context, index) {
          final bank = widget.banks[index];
          return Column(
            children: [
              GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded == null) {
                        isExpanded = bank.bankId;
                      } else if (isExpanded == bank.bankId) {
                        isExpanded = null;
                      } else {
                        isExpanded = bank.bankId;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                AppConstants.banks
                                    .firstWhere(
                                        (element) => element.id == bank.bankId)
                                    .image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        AppConstants.banks
                                            .firstWhere((element) =>
                                                element.id == bank.bankId)
                                            .name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Icon(
                                        isExpanded == bank.bankId
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      )
                                    ]),
                                Text(
                                  bank.accountCount.toString() + ' accounts',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                    (formatNumberWithComma(bank.totalBalance)) +
                                        " ETB",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      isExpanded == bank.bankId
                          ? Column(
                              children: [
                                const SizedBox(
                                  height: 15,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween, // Centers horizontally
                                  children: [
                                    Text(
                                      "Total Credit",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                        "${formatNumberWithComma(bank.totalCredit).toString()} ETB",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Debit",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                        "${formatNumberWithComma(bank.totalDebit).toString()} ETB",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        )),
                                  ],
                                ),
                              ],
                            )
                          : Container()
                    ]),
                  )),
              const SizedBox(
                height: 13,
              )
            ],
          );
        },
      ),
    );
  }
}
