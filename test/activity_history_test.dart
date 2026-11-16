import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/domain/tracking/activity_history.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/activities/application/activity_history.dart';
import 'package:runwild/features/activities/presentation/activities_screen.dart';
import 'package:runwild/features/auth/application/auth_session.dart';
import 'package:runwild/features/run/application/run_journal.dart';

import 'support.dart';

HistoryItem _item(int id) => (
  id: id,
  startedAt: DateTime(2026, 11, 16, 6),
  meters: 2450.0,
  moving: const Duration(minutes: 20),
  interval: id.isEven,
  synced: id.isEven,
  title: null,
  route: const [
    (latitude: 0.0, longitude: 0.0, segmentStart: true),
    (latitude: 0.01, longitude: 0.02, segmentStart: false),
    (latitude: 0.015, longitude: 0.01, segmentStart: false),
  ],
);

class _Repository implements ActivityHistoryRepository {
  Future<HistoryPage> Function(ActivityHistoryFilter, HistoryCursor?) handler =
      (filter, before) async => (items: [_item(1)], next: null);
  @override
  Future<HistoryPage> load(
    String owner,
    ActivityHistoryFilter filter, {
    HistoryCursor? before,
  }) => handler(filter, before);
}

void main() {
  setUpAll(loadArchivo);

  test(
    'History filters, stable cursor, real routes and account isolation',
    () async {
      final db = RunJournal(NativeDatabase.memory());
      addTearDown(db.close);
      final when = DateTime(2026, 11, 16, 6);
      final ids = <int>[];
      for (var i = 0; i < 25; i++) {
        final id = await db.begin(
          'runner',
          when,
          interval: i.isEven ? defaultIntervalConfig : null,
        );
        ids.add(id);
        await db.checkpoint(
          'runner',
          (
            id: id,
            startedAt: when,
            meters: 100.0,
            moving: const Duration(seconds: 60),
            elapsed: const Duration(seconds: 70),
            points: 2,
          ),
          const [
            (
              GpsSample(
                latitude: 0,
                longitude: 0,
                accuracyMeters: 5,
                capturedAt: Duration.zero,
              ),
              SampleResult.segmentStart,
            ),
            (
              GpsSample(
                latitude: 0.01,
                longitude: 0.01,
                accuracyMeters: 5,
                capturedAt: Duration(seconds: 60),
              ),
              SampleResult.recorded,
            ),
          ],
          finish: true,
        );
      }
      await db.markSynced('runner', ids.last, 'cloud-id');
      await db.begin('runner', when);
      await db.begin('other', when);
      final first = await db.history('runner', ActivityHistoryFilter.all);
      expect(first.items.length, 20);
      expect(first.items.map((item) => item.id), ids.reversed.take(20));
      expect(first.items.first.synced, isTrue);
      expect(first.items.first.route.length, 2);
      expect(first.items.first.route.first.segmentStart, isTrue);
      await db.discardSession('runner', ids.last);
      final second = await db.history(
        'runner',
        ActivityHistoryFilter.all,
        before: first.next,
      );
      expect(second.items.map((item) => item.id), ids.reversed.skip(20));
      expect(second.next, isNull);
      expect(
        (await db.history(
          'runner',
          ActivityHistoryFilter.interval,
        )).items.every((item) => item.interval),
        isTrue,
      );
      expect(
        (await db.history('runner', ActivityHistoryFilter.free)).items.length,
        12,
      );
      expect(
        (await db.history('other', ActivityHistoryFilter.all)).items,
        isEmpty,
      );
      expect(
        (await db.history('signed-out', ActivityHistoryFilter.all)).items,
        isEmpty,
      );
    },
  );

  test('Pace and titles use actual duration and local time', () {
    expect(historyPace(_item(1)), closeTo(1200 / 2.45, 0.001));
    expect(historyTimeOfDay(DateTime(2026, 1, 1, 4)), HistoryTimeOfDay.morning);
    expect(historyTimeOfDay(DateTime(2026, 1, 1, 11)), HistoryTimeOfDay.midday);
    expect(
      historyTimeOfDay(DateTime(2026, 1, 1, 15)),
      HistoryTimeOfDay.afternoon,
    );
    expect(historyTimeOfDay(DateTime(2026, 1, 1, 18)), HistoryTimeOfDay.night);
    expect(historyTimeOfDay(DateTime(2026, 1, 1, 3)), HistoryTimeOfDay.night);
  });

  test(
    'Failed pagination retains content; filter change ignores stale pages',
    () async {
      final repository = _Repository();
      const cursor = (startedMs: 1, id: 1);
      repository.handler = (_, _) async => (items: [_item(1)], next: cursor);
      final container = ProviderContainer(
        overrides: [
          runOwnerProvider.overrideWithValue(() => 'runner'),
          authSessionProvider.overrideWith((ref) => const Stream.empty()),
          activityHistoryRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(activityHistoryProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(activityHistoryProvider.future);
      final controller = container.read(activityHistoryProvider.notifier);
      repository.handler = (_, _) async => throw Exception('disk unavailable');
      await controller.loadMore();
      expect(controller.moreFailed, isTrue);
      expect(
        container.read(activityHistoryProvider).requireValue.items.single.id,
        1,
      );
      final latePage = Completer<HistoryPage>();
      repository.handler = (_, before) => before != null
          ? latePage.future
          : Future.value((items: [_item(2)], next: null));
      final pending = controller.loadMore();
      await controller.refresh(ActivityHistoryFilter.interval);
      latePage.complete((items: [_item(3)], next: null));
      await pending;
      expect(
        container.read(activityHistoryProvider).requireValue.items.single.id,
        2,
      );
    },
  );

  Future<void> pump(
    WidgetTester tester,
    _Repository repository, {
    double scale = 1,
    VoidCallback? start,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runOwnerProvider.overrideWithValue(() => 'runner'),
          authSessionProvider.overrideWith((ref) => const Stream.empty()),
          activityHistoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: componentHost(ActivitiesScreen(onStart: start ?? () {})),
      ),
    );
    await tester.pump();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('History shows actual metrics and reflows at $scale', (
      tester,
    ) async {
      await pump(tester, _Repository(), scale: scale);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('2,45'), findsOneWidget);
      expect(find.text('Lari Pagi'), findsOneWidget);
      expect(
        find.text('Tersimpan di perangkat · belum tersinkron'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (scale == 1) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/activity_history.png'),
        );
      }
      await tester.ensureVisible(find.text('Muat ulang riwayat'));
      await tester.tap(find.text('Muat ulang riwayat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Loading, error, retry, empty and start action', (tester) async {
    final repository = _Repository();
    final pending = Completer<HistoryPage>();
    repository.handler = (_, _) => pending.future;
    var started = false;
    await pump(tester, repository, start: () => started = true);
    expect(find.bySemanticsLabel('Memuat riwayat…'), findsOneWidget);
    pending.completeError(Exception('disk unavailable'));
    await tester.pumpAndSettle();
    expect(
      find.text('Riwayat belum bisa dibaca dari perangkat. Coba muat ulang.'),
      findsOneWidget,
    );
    repository.handler = (_, _) async =>
        (items: const <HistoryItem>[], next: null);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada aktivitas'), findsOneWidget);
    await tester.ensureVisible(find.text('Mulai berlari'));
    await tester.tap(find.text('Mulai berlari'));
    expect(started, isTrue);
  });

  testWidgets('Filter empty state returns to all activities', (tester) async {
    final repository = _Repository();
    repository.handler = (filter, _) async => (
      items: filter == ActivityHistoryFilter.interval
          ? <HistoryItem>[]
          : [_item(1)],
      next: null,
    );
    await pump(tester, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Interval'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada sesi untuk filter ini'), findsOneWidget);
    final all = find.widgetWithText(FilledButton, 'Semua');
    await tester.ensureVisible(all);
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(find.text('Lari Pagi'), findsOneWidget);
  });
}
