import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onehand_launcher/core/models/planner_item.dart';
import 'package:onehand_launcher/core/providers/planner_items_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rapid planner mutations persist the latest state in order', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = PlannerItemsNotifier(prefs);
    final first = PlannerItem(
      id: 'planner-first',
      date: DateTime(2026, 11, 1),
      title: 'First item',
    );
    final second = PlannerItem(
      id: 'planner-second',
      date: DateTime(2026, 11, 2),
      title: 'Second item',
    );

    final writes = [
      notifier.add(first),
      notifier.add(second),
      notifier.remove(first.id),
      notifier.toggleCompleted(second.id),
    ];

    expect(await Future.wait(writes), everyElement(isTrue));
    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.id, second.id);
    expect(notifier.state.single.isCompleted, isTrue);

    final stored = jsonDecode(
      prefs.getString('home_planner_items_v1')!,
    ) as List<dynamic>;
    expect(stored, hasLength(1));
    expect(stored.single['id'], second.id);
    expect(stored.single['isCompleted'], isTrue);

    notifier.dispose();
  });

  test('planner mutations are persisted and can be restored', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = PlannerItemsNotifier(prefs);
    final item = PlannerItem(
      id: 'planner-test-item',
      date: DateTime(2026, 10, 10),
      title: 'Review plans',
    );

    expect(await notifier.add(item), isTrue);
    expect(notifier.state, hasLength(1));

    final storedAfterAdd = jsonDecode(
      prefs.getString('home_planner_items_v1')!,
    ) as List<dynamic>;
    expect(storedAfterAdd, hasLength(1));
    expect(storedAfterAdd.single['title'], 'Review plans');

    expect(await notifier.toggleCompleted(item.id), isTrue);
    expect(notifier.state.single.isCompleted, isTrue);

    final reloaded = PlannerItemsNotifier(prefs);
    expect(reloaded.state.single.isCompleted, isTrue);

    expect(await notifier.remove(item.id), isTrue);
    expect(notifier.state, isEmpty);
    expect(
      jsonDecode(prefs.getString('home_planner_items_v1')!) as List<dynamic>,
      isEmpty,
    );

    notifier.dispose();
    reloaded.dispose();
  });
}
