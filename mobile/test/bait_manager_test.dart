import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_manager.dart';
import 'package:mobile/bait_category_manager.dart';
import 'package:mobile/bait_manager.dart';
import 'package:mobile/catch_manager.dart';
import 'package:mobile/custom_entity_manager.dart';
import 'package:mobile/data_manager.dart';
import 'package:mobile/entity_manager.dart';
import 'package:mobile/model/gen/anglerslog.pb.dart';
import 'package:mobile/utils/protobuf_utils.dart';
import 'package:mockito/mockito.dart';

import 'test_utils.dart';

class MockAppManager extends Mock implements AppManager {}
class MockBaitListener extends Mock implements EntityListener<Bait> {}
class MockCatchManager extends Mock implements CatchManager {}
class MockCustomEntityManager extends Mock implements CustomEntityManager {}
class MockDataManager extends Mock implements DataManager {}

void main() {
  MockAppManager appManager;
  MockCatchManager catchManager;
  MockCustomEntityManager customEntityManager;
  MockDataManager dataManager;
  BaitManager baitManager;
  BaitCategoryManager baitCategoryManager;

  setUp(() {
    appManager = MockAppManager();

    catchManager = MockCatchManager();
    when(appManager.catchManager).thenReturn(catchManager);

    customEntityManager = MockCustomEntityManager();
    when(appManager.customEntityManager).thenReturn(customEntityManager);
    when(customEntityManager.matchesFilter(any, any)).thenReturn(true);

    dataManager = MockDataManager();
    when(appManager.dataManager).thenReturn(dataManager);
    when(dataManager.insertOrUpdateEntity(any, any, any))
        .thenAnswer((_) => Future.value(true));

    baitCategoryManager = BaitCategoryManager(appManager);
    when(appManager.baitCategoryManager).thenReturn(baitCategoryManager);

    baitManager = BaitManager(appManager);
  });

  test("When a bait category is deleted, existing baits are updated", () async {
    when(dataManager.deleteEntity(any, any))
        .thenAnswer((_) => Future.value(true));
    when(dataManager.replaceRows(any, any)).thenAnswer((_) => Future.value());

    MockBaitListener baitListener = MockBaitListener();
    when(baitListener.onDelete).thenReturn((_) { });
    when(baitListener.onAddOrUpdate).thenReturn(() { });
    baitManager.addListener(baitListener);

    // Add a BaitCategory.
    Id baitCategoryId0 = randomId();
    BaitCategory category = BaitCategory()
      ..id = baitCategoryId0
      ..name = "Rapala";
    await baitCategoryManager.addOrUpdate(category);

    // Add a couple Baits that use the new category.
    Id baitId0 = randomId();
    Id baitId1 = randomId();
    await baitManager.addOrUpdate(Bait()
      ..id = baitId0
      ..name = "Test Bait"
      ..baitCategoryId = baitCategoryId0);
    await baitManager.addOrUpdate(Bait()
      ..id = baitId1
      ..name = "Test Bait 2"
      ..baitCategoryId = baitCategoryId0);
    verify(baitListener.onAddOrUpdate).called(2);
    expect(baitManager.entity(baitId0).baitCategoryId, baitCategoryId0);
    expect(baitManager.entity(baitId1).baitCategoryId, baitCategoryId0);

    // Delete the bait category.
    await baitCategoryManager.delete(category.id);

    // Verify listeners are notified and memory cache updated.
    verify(baitListener.onAddOrUpdate).called(1);
    expect(baitManager.entity(baitId0).hasBaitCategoryId(), false);
    expect(baitManager.entity(baitId1).hasBaitCategoryId(), false);
  });

  test("Number of catches", () {
    Id speciesId0 = randomId();

    Id baitId0 = randomId();
    Id baitId1 = randomId();
    Id baitId2 = randomId();

    when(catchManager.list()).thenReturn([
      Catch()
        ..id = randomId()
        ..timestamp = timestampFromMillis(0)
        ..speciesId = speciesId0
        ..baitId = baitId0,
      Catch()
        ..id = randomId()
        ..timestamp = timestampFromMillis(0)
        ..speciesId = speciesId0
        ..baitId = baitId1,
      Catch()
        ..id = randomId()
        ..timestamp = timestampFromMillis(0)
        ..speciesId = speciesId0
        ..baitId = baitId2,
      Catch()
        ..id = randomId()
        ..timestamp = timestampFromMillis(0)
        ..speciesId = speciesId0
        ..baitId = baitId0,
      Catch()
        ..id = randomId()
        ..timestamp = timestampFromMillis(0)
        ..speciesId = speciesId0,
    ]);

    expect(baitManager.numberOfCatches(null), 0);
    expect(baitManager.numberOfCatches(Bait()..id = baitId0), 2);
    expect(baitManager.numberOfCatches(Bait()..id = baitId1), 1);
    expect(baitManager.numberOfCatches(Bait()..id = baitId2), 1);
  });

  test("Format bait name", () async {
    Id baitCategoryId0 = randomId();
    await baitCategoryManager.addOrUpdate(BaitCategory()
      ..id = baitCategoryId0
      ..name = "Test Category");

    expect(baitManager.formatNameWithCategory(null), null);
    expect(baitManager.formatNameWithCategory(Bait()
      ..name = "Test"
      ..baitCategoryId = baitCategoryId0), "Test Category - Test");
    expect(baitManager.formatNameWithCategory(Bait()..name = "Test"), "Test");
  });

  test("Filtering", () async {
    Id baitId0 = randomId();
    Id baitId1 = randomId();

    expect(baitManager.matchesFilter(baitId0, ""), false);

    Bait bait = Bait()
      ..id = baitId1
      ..name = "Rapala";

    await baitManager.addOrUpdate(bait);
    expect(baitManager.matchesFilter(null, ""), false);
    expect(baitManager.matchesFilter(baitId1, ""), true);
    expect(baitManager.matchesFilter(baitId1, null), true);
    expect(baitManager.matchesFilter(baitId1, "Cut Bait"), false);
    expect(baitManager.matchesFilter(baitId1, "RAP"), true);

    // Bait category
    BaitCategory category = BaitCategory()
      ..id = randomId()
      ..name = "Bugger";
    await baitCategoryManager.addOrUpdate(category);
    bait.baitCategoryId = category.id;
    await baitManager.addOrUpdate(bait);
    expect(baitManager.matchesFilter(baitId1, "Bug"), true);

    // Custom entity values
    bait.customEntityValues.add(CustomEntityValue()
      ..customEntityId = randomId()
      ..value = "Test");
    await baitManager.addOrUpdate(bait);
    expect(baitManager.matchesFilter(baitId1, "Test"), true);
  });

  group("duplicate", () {
    test("false if bait does not exist", () {
      expect(baitManager.duplicate(Bait()
        ..id = randomId()
        ..name = "Rapala"), isFalse);
    });

    test("false if bait category IDs differ", () async {
      await baitManager.addOrUpdate(Bait()
        ..id = randomId()
        ..name = "Rapala"
        ..baitCategoryId = randomId());
      expect(baitManager.duplicate(Bait()
        ..id = randomId()
        ..name = "Rapala"
        ..baitCategoryId = randomId()), isFalse);
    });

    test("false if bait category ID is null", () async {
      await baitManager.addOrUpdate(Bait()
        ..id = randomId()
        ..name = "Rapala");
      expect(baitManager.duplicate(Bait()
        ..id = randomId()
        ..name = "Rapala"
        ..baitCategoryId = randomId()), isFalse);
    });

    test("false if names differ", () async {
      await baitManager.addOrUpdate(Bait()
        ..id = randomId()
        ..name = "Rapala");
      expect(baitManager.duplicate(Bait()
        ..id = randomId()
        ..name = "Bugger"), isFalse);
    });

    test("false if custom entity values differ", () async {
      await baitManager.addOrUpdate(Bait()
        ..id = randomId()
        ..name = "Rapala");
      expect(baitManager.duplicate(Bait()
        ..id = randomId()
        ..name = "Bugger"), isFalse);
    });

    test("false if IDs are equal", () async {
      Id id = randomId();
      await baitManager.addOrUpdate(Bait()
        ..id = id
        ..name = "Rapala");
      expect(baitManager.duplicate(Bait()
        ..id = id
        ..name = "Rapala"), isFalse);
    });

    test("true with all properties", () async {
      CustomEntityValue value = CustomEntityValue()
        ..customEntityId = randomId()
        ..value = "10";
      Id categoryId = randomId();

      Bait bait1 = Bait()
        ..id = randomId()
        ..name = "Rapala"
        ..baitCategoryId = categoryId;
      bait1.customEntityValues.add(value);

      Bait bait2 = Bait()
        ..id = randomId()
        ..name = "Rapala"
        ..baitCategoryId = categoryId;
      bait2.customEntityValues.add(
          CustomEntityValue.fromBuffer(value.writeToBuffer()));

      await baitManager.addOrUpdate(bait1);
      expect(baitManager.duplicate(bait2), isTrue);
    });

    test("true with no bait category ID", () async {
      await baitManager.addOrUpdate(Bait()
        ..id = randomId()
        ..name = "Rapala");
      expect(baitManager.duplicate(Bait()
        ..id = randomId()
        ..name = "Rapala"), isTrue);
    });
  });

  group("deleteMessage", () {
    testWidgets("Input", (WidgetTester tester) async {
      expect(() => baitManager.deleteMessage(null, Bait()
        ..id = randomId()
        ..name = "Worm"), throwsAssertionError);

      BuildContext context = await buildContext(tester);
      expect(() => baitManager.deleteMessage(context, null),
          throwsAssertionError);
    });

    testWidgets("Singular", (WidgetTester tester) async {
      Bait bait = Bait()
        ..id = randomId()
        ..name = "Worm";

      when(catchManager.list()).thenReturn([
        Catch()
          ..id = randomId()
          ..timestamp = timestampFromMillis(0)
          ..speciesId = randomId()
          ..baitId = bait.id,
      ]);

      BuildContext context = await buildContext(tester);
      expect(baitManager.deleteMessage(context, bait),
          "Worm is associated with 1 catch; are you sure you want to delete it?"
              " This cannot be undone.");
    });

    testWidgets("Plural zero", (WidgetTester tester) async {
      Bait bait = Bait()
        ..id = randomId()
        ..name = "Worm";

      when(catchManager.list()).thenReturn([]);

      BuildContext context = await buildContext(tester);
      expect(baitManager.deleteMessage(context, bait),
          "Worm is associated with 0 catches; are you sure you want to delete "
              "it? This cannot be undone.");
    });

    testWidgets("Plural none zero", (WidgetTester tester) async {
      Bait bait = Bait()
        ..id = randomId()
        ..name = "Worm";

      when(catchManager.list()).thenReturn([
        Catch()
          ..id = randomId()
          ..timestamp = timestampFromMillis(0)
          ..speciesId = randomId()
          ..baitId = bait.id,
        Catch()
          ..id = randomId()
          ..timestamp = timestampFromMillis(5)
          ..speciesId = randomId()
          ..baitId = bait.id,
      ]);

      BuildContext context = await buildContext(tester);
      expect(baitManager.deleteMessage(context, bait),
          "Worm is associated with 2 catches; are you sure you want to delete "
              "it? This cannot be undone.");
    });

    testWidgets("With bait category", (WidgetTester tester) async {
      BaitCategory category = BaitCategory()
        ..id = randomId()
        ..name = "Live";
      baitCategoryManager.addOrUpdate(category);

      Bait bait = Bait()
        ..id = randomId()
        ..name = "Worm"
        ..baitCategoryId = category.id;
      when(catchManager.list()).thenReturn([
        Catch()
          ..id = randomId()
          ..timestamp = timestampFromMillis(5)
          ..speciesId = randomId()
          ..baitId = bait.id,
      ]);

      BuildContext context = await buildContext(tester);
      expect(baitManager.deleteMessage(context, bait),
          "Worm (Live) is associated with 1 catch; are you sure you want to "
              "delete it? This cannot be undone.");
    });
  });
}