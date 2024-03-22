import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karanda/common/custom_scroll_behavior.dart';
import 'package:karanda/common/global_properties.dart';
import 'package:karanda/ship_upgrading/ship_upgrading_data_controller.dart';
import 'package:karanda/ship_upgrading/ship_upgrading_material.dart';
import 'package:karanda/ship_upgrading/ship_upgrading_parts.dart';
import 'package:karanda/ship_upgrading/ship_upgrading_ship.dart';
import 'package:karanda/trade_market/bdo_item_image_widget.dart';
import 'package:karanda/widgets/default_app_bar.dart';
import 'package:karanda/widgets/loading_indicator.dart';
import 'package:karanda/widgets/title_text.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ShipUpgradingPage extends StatefulWidget {
  const ShipUpgradingPage({super.key});

  @override
  State<ShipUpgradingPage> createState() => _ShipUpgradingPageState();
}

class _ShipUpgradingPageState extends State<ShipUpgradingPage> {
  final ShipUpgradingDataController dataController =
      ShipUpgradingDataController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => ready());
  }

  Future<void> ready() async {
    bool result = await dataController.getBaseData();
    if (result) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(FontAwesomeIcons.ship),
                title: TitleText(
                  '선박 증축',
                  bold: true,
                ),
              ),
            ),
            _Head(
                selectedShipStream: dataController.selectedShipData,
                shipData: dataController.ship,
                updateSelected: dataController.updateSelected,
                dataController: dataController),
            _Body(
              dataController: dataController,
              screenWidth: MediaQuery.of(context).size.width,
            ),
            const SizedBox(
              height: 24.0,
            )
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  final ShipUpgradingDataController dataController;
  final Stream<ShipUpgradingShip> selectedShipStream;
  final Map<String, ShipUpgradingShip> shipData;
  final Function(String) updateSelected;

  const _Head(
      {super.key,
      required this.selectedShipStream,
      required this.shipData,
      required this.updateSelected,
      required this.dataController});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: GlobalProperties.widthConstrains,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _ShipTypeSelector(
              selectedShipStream: selectedShipStream,
              shipData: shipData,
              updateSelected: updateSelected,
              dataController: dataController,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _PercentInHeader(stream: dataController.totalPercent),
          ),
        ],
      ),
    );
  }
}

class _ShipTypeSelector extends StatelessWidget {
  final ShipUpgradingDataController dataController;
  final Stream<ShipUpgradingShip> selectedShipStream;
  final Map<String, ShipUpgradingShip> shipData;
  final Function(String) updateSelected;

  const _ShipTypeSelector(
      {super.key,
      required this.selectedShipStream,
      required this.shipData,
      required this.updateSelected,
      required this.dataController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: dataController.selectedShipData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 15.0,
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            DropdownMenu<String>(
              initialSelection: snapshot.data?.nameEN,
              dropdownMenuEntries: shipData.keys
                  .map<DropdownMenuEntry<String>>(
                    (e) => DropdownMenuEntry(
                      value: shipData[e]!.nameEN,
                      label: shipData[e]!.nameKR,
                    ),
                  )
                  .toList(),
              onSelected: (String? value) {
                if (value != null) {
                  updateSelected(value);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _PercentInHeader extends StatelessWidget {
  final Stream<double> stream;

  const _PercentInHeader({super.key, required this.stream});

  MaterialColor getColor(double percent) {
    if (percent < 0.25) {
      return Colors.red;
    } else if (percent < 0.5) {
      return Colors.orange;
    } else if (percent < 0.75) {
      return Colors.yellow;
    } else if (percent < 1) {
      return Colors.green;
    }
    return Colors.blue;
  }

  double getPercent(List<ShipUpgradingMaterial> dataList) {
    double need = 0;
    double stock = 0;
    for (ShipUpgradingMaterial data in dataList) {
      need += data.neededPoint;
      stock += data.stockPoint;
    }
    if (need <= 0) {
      return 0;
    }
    return stock / need;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 15.0,
          );
        }
        //double percent = getPercent(snapshot.data!.values.toList());
        return Flex(
          direction: Axis.horizontal,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: LinearPercentIndicator(
                animation: true,
                animationDuration: 500,
                percent: snapshot.data!,
                barRadius: const Radius.circular(4.0),
                progressColor: getColor(snapshot.data!),
                animateFromLastPercent: true,
              ),
            ),
            const SizedBox(
              width: 4,
            ),
            Text(
              "${(snapshot.data! * 100).toStringAsFixed(2)}%",
            ),
          ],
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ShipUpgradingDataController dataController;
  final double screenWidth;

  const _Body(
      {super.key, required this.dataController, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: GlobalProperties.widthConstrains - 48,
          child: StreamBuilder(
            stream: dataController.selectedShipData,
            builder: (context, selected) {
              return StreamBuilder(
                stream: dataController.parts,
                builder: (context, parts) {
                  return StreamBuilder(
                    stream: dataController.materials,
                    builder: (context, materials) {
                      if (!materials.hasData ||
                          !selected.hasData ||
                          !parts.hasData) {
                        return const LoadingIndicator();
                      }
                      return Column(
                        children: selected.data!.parts
                            .map<_PartsCard>((e) => _PartsCard(
                                  parts: parts.data![e]!,
                                  materials: materials.data!,
                                  screenWidth: screenWidth,
                                  onInputChanged:
                                      dataController.updateUserStock,
                                  setFinished: dataController.setFinished,
                                ))
                            .toList(),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PartsCard extends StatelessWidget {
  final double screenWidth;
  final ShipUpgradingParts parts;
  final Map<String, ShipUpgradingMaterial> materials;
  final Function(String, int) onInputChanged;
  final Function(String) setFinished;

  const _PartsCard(
      {super.key,
      required this.parts,
      required this.screenWidth,
      required this.materials,
      required this.onInputChanged,
      required this.setFinished});

  int getDDay(int need, int stock, int reward) {
    need = need - stock;
    if (need <= 0) return 0;
    return (need / reward).ceil();
  }

  MaterialColor getColor(double percent) {
    if (percent < 0.25) {
      return Colors.red;
    } else if (percent < 0.5) {
      return Colors.orange;
    } else if (percent < 0.75) {
      return Colors.yellow;
    } else if (percent < 1) {
      return Colors.green;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    double percent = 0;
    if (!parts.finished) {
      double totalNeed = 0;
      double totalStock = 0;
      for (String key in parts.materials.keys) {
        int num = materials[key]!.obtain.reward > 0
            ? materials[key]!.obtain.reward
            : materials[key]!.obtain.trade;

        totalNeed += parts.materials[key]!.need / num;

        if (materials[key]!.userStock > parts.materials[key]!.need) {
          totalStock += parts.materials[key]!.need / num;
        } else {
          totalStock += materials[key]!.userStock / num;
        }
      }
      percent = totalStock / totalNeed;
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
        child: Column(
          children: [
            ListTile(
              leading: BdoItemImageWidget(
                code: parts.code.toString(),
                grade: parts.grade,
                size: 46,
              ),
              title: Text(parts.nameKR),
              trailing: parts.type != ShipParts.license
                  ? OutlinedButton.icon(
                      onPressed: () => setFinished(parts.code.toString()),
                      clipBehavior: Clip.hardEdge,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('제작 완료'),
                      style: OutlinedButton.styleFrom(
                          //foregroundColor: Colors.grey.shade700,
                          foregroundColor: parts.finished
                              ? Colors.green.shade400
                              : Colors.grey.shade700,
                          side: BorderSide(
                              color: parts.finished
                                  ? Colors.green.shade400
                                  : Colors.grey.shade700),
                          animationDuration: const Duration(milliseconds: 650)),
                    )
                  : null,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: LinearPercentIndicator(
                animation: true,
                animationDuration: 500,
                percent: percent,
                barRadius: const Radius.circular(4.0),
                progressColor: getColor(percent),
                backgroundColor: Colors.grey.shade700.withOpacity(0.6),
                animateFromLastPercent: true,
                lineHeight: 1.8,
              ),
            ),
            Table(
              border: TableBorder(
                  horizontalInside: BorderSide(
                      color: Colors.grey.shade700.withOpacity(0.0), width: 0.6),
                  verticalInside: BorderSide(
                      color: Colors.grey.shade700.withOpacity(0.0),
                      width: 0.6)),
              columnWidths: const <int, TableColumnWidth>{
                0: FixedColumnWidth(58),
                1: FixedColumnWidth(180),
                2: FixedColumnWidth(450),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(80),
                5: FixedColumnWidth(110),
                6: FixedColumnWidth(80),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              defaultColumnWidth: const FixedColumnWidth(80),
              children: parts.materials.keys
                  .map<TableRow>(
                    (e) => _MaterialItem(
                      material: materials[e]!,
                      need: parts.materials[e]!.need,
                      finished: parts.finished,
                      onInputChanged: onInputChanged,
                      totalDays: parts.materials[e]!.days,
                    ).toTableRow(),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialItem {
  final ShipUpgradingMaterial material;
  final int need;
  final int totalDays;
  final bool finished;
  final Function(String, int) onInputChanged;

  _MaterialItem(
      {required this.material,
      required this.need,
      required this.finished,
      required this.onInputChanged,
      required this.totalDays});

  int getDDay(int need, int stock, int reward) {
    need = need - stock;
    if (need <= 0) return 0;
    return (need / reward).ceil();
  }

  TableRow toTableRow() {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(6.0),
        child: BdoItemImageWidget(
          code: material.code.toString(),
          grade: 0,
          size: 44,
        ),
      ),
      Text(material.nameKR.replaceAll('(', '\n('), textAlign: TextAlign.center),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(material.obtain.nameWithNpc),
            Text(
              material.obtain.detailWithReward,
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: material.controller,
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^(\d{0,3})')),
          ],
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.all(0),
          ),
          textAlign: TextAlign.center,
          onChanged: (String value) {
            int parsed = int.tryParse(value) ?? 0;
            onInputChanged(material.code.toString(), parsed);
          },
        ),
      ),
      Text(
        '${need.toString()}개',
        textAlign: TextAlign.center,
      ),
      Text(
        finished || material.obtain.reward <= 0
            ? '-'
            : '${getDDay(need, material.userStock, material.obtain.reward)}일 / $totalDays일',
        textAlign: TextAlign.center,
      ),
      Text(
        finished
            ? '-'
            : '${(material.userStock / need * 100).toStringAsFixed(2)}%',
        textAlign: TextAlign.center,
      ),
    ]);
  }
}
