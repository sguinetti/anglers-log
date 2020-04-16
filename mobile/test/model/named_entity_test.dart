import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/entity.dart';
import 'package:mobile/model/named_entity.dart';
import 'package:mobile/model/property.dart';

void main() {
  test("Null property input", () {
    var entity = NamedEntity.fromMap({ "id" : "ID1" });
    expect(entity.id, "ID1");

    entity = NamedEntity();
    expect(entity.id, isNotNull);
  });

  test("Entity equality", () {
    var entity1 = NamedEntity(properties: [
      Property<int>(key: "numberOfLegs", value: 4),
      Property<bool>(key: "hasTail", value: true),
    ], id: "ID1", name: "dog");

    var entity2 = NamedEntity(properties: [
      Property<int>(key: "numberOfLegs", value: 4),
      Property<bool>(key: "hasTail", value: true),
    ], id: "ID1", name: "dog");

    expect(entity1, entity2);
    expect(entity1.hashCode, entity2.hashCode);

    var entity3 = NamedEntity(properties: [
      Property<int>(key: "numberOfLegs", value: 5),
      Property<bool>(key: "hasTail", value: true),
    ], id: "ID1", name: "dog");

    expect(entity1 == entity3, false);
    expect(entity1.hashCode == entity3.hashCode, false);

    var set = HashSet();
    set.add(entity1);
    expect(set.length, 1);
    set.add(entity2);
    expect(set.length, 1);
    set.add(entity3);
    expect(set.length, 2);
  });

  test("Entity mapping", () {
    var entity1 = NamedEntity(properties: [
      Property<int>(key: "numberOfLegs", value: 4),
      Property<bool>(key: "hasTail", value: true),
    ], name: "dog");

    var map = entity1.toMap();
    expect(map["numberOfLegs"], 4);
    expect(map["hasTail"], true);
    expect(map["name"], "dog");

    map = {
      "id" : "testId",
      "name" : "dog",
    };
    var entity2 = NamedEntity.fromMap(map, properties: []);
    expect(entity2.id, "testId");
    expect(entity2.name, "dog");

    map = {};
    expect(() => NamedEntity.fromMap(map, properties: []),
        throwsAssertionError);
  });
}