import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/db_scale_connect_info.dart';
import 'package:label_manager/home_page_manager.dart';
import 'package:label_manager/models/scale_output.dart';
import 'package:label_manager/page_home/scale_output_page.dart';

void main() {
  test('legacy serial values include full active setup range', () {
    expect(
      scaleOutputSupportedBaudRates,
      containsAll(<int>[56000, 128000, 256000]),
    );
    expect(scaleOutputIsSupportedDataBit(4), isTrue);
    expect(scaleOutputIsSupportedStopBit(1.5), isTrue);
  });

  test('stop bit 1.5 survives local storage codec', () {
    const info = ScaleConnectInfo(
      portName: 'COM1',
      baudRate: 9600,
      dataBit: 8,
      stopBit: 1.5,
      parityBit: 'none',
      autoPrint: false,
    );
    expect(ScaleConnectInfo.fromMap(info.toMap()).stopBit, 1.5);
  });

  test('CAS stable frame separates state and positive weight', () {
    final reading = scaleOutputParseIncomingReading('ST,GS,+  1.250 kg');
    expect(reading?.state, 'ST');
    expect(reading?.weight, '+1.250kg');
    expect(scaleOutputIsStablePositiveReading(reading!), isTrue);
    expect(
      scaleOutputIsStablePositiveReading(
        scaleOutputParseIncomingReading('US,GS,+  1.250 kg')!,
      ),
      isFalse,
    );
    expect(
      scaleOutputIsStablePositiveReading(
        scaleOutputParseIncomingReading('ST,GS,+  0.000 kg')!,
      ),
      isFalse,
    );
  });

  test('public manager command delegates only while attached', () async {
    final controller = HomePageManagerController();
    final owner = Object();
    var calls = 0;
    controller.attach(
      owner: owner,
      openScaleConnectSettings: () async => calls += 1,
    );
    await controller.openScaleConnectSettings();
    expect(calls, 1);
    controller.detach(owner);
    await controller.openScaleConnectSettings();
    expect(calls, 1);
  });

  testWidgets('dialog applies edited auto print with persisted serial values', (
    tester,
  ) async {
    ScaleConnectInfo? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showScaleConnectSettingsDialog(
                context: context,
                initial: const ScaleConnectInfo(
                  portName: 'COM3',
                  baudRate: 56000,
                  dataBit: 4,
                  stopBit: 1.5,
                  parityBit: 'mark',
                  autoPrint: false,
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('자동발행'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    expect(result?.portName, 'COM3');
    expect(result?.baudRate, 56000);
    expect(result?.dataBit, 4);
    expect(result?.stopBit, 1.5);
    expect(result?.parityBit, 'mark');
    expect(result?.autoPrint, isTrue);
  });
}