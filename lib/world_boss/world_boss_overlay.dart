import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karanda/common/date_time_extension.dart';
import 'package:karanda/common/real_time.dart';
import 'package:karanda/common/server_time.dart';
import 'package:karanda/common/time_of_day_extension.dart';

class WorldBossOverlay extends StatefulWidget {
  const WorldBossOverlay({super.key});

  @override
  State<WorldBossOverlay> createState() => _WorldBossOverlayState();
}

class _WorldBossOverlayState extends State<WorldBossOverlay> {
  DateTime? spawnTime;
  TimeOfDay timeOfDay = TimeOfDay.now();
  String? names;
  ServerTime serverTime = ServerTime();
  double opacity = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler(callback);
  }

  Future<dynamic> callback(MethodCall call, int fromWindowId) async {
    if (call.method == 'next boss') {
      Map data = jsonDecode(call.arguments);
      setState(() {
        spawnTime = DateTime.parse(data["spawnTime"]);
        timeOfDay = TimeOfDay.fromDateTime(spawnTime!);
        names = data["names"];
        opacity = 0.0;
      });
    }
    if (call.method == 'alert') {
      setState(() {
        opacity = 1.0;
      });
      _timer?.cancel();
      _timer = Timer(
        Duration(seconds: 10),
        () {
          setState(() {
            opacity = 0.0;
          });
          _timer = null;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.dragon),
                    title: Text(
                      '월드 보스',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder(
                      stream: serverTime.stream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            spawnTime == null ||
                            names == null) {
                          return Container();
                        }
                        Duration diff =
                            spawnTime!.difference(snapshot.requireData);
                        TextStyle? style =
                            Theme.of(context).textTheme.headlineSmall;
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${timeOfDay.timeWithoutPeriod()} $names',
                                style: style,
                              ),
                              Text(
                                '${diff.inMinutes + 1}분 뒤',
                                style: style,
                              )
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  RealTime realTime = RealTime();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: realTime.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          return Container(
            width: Size.infinite.width,
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: Text(
              snapshot.requireData.format('HH:mm:ss'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        });
  }
}
