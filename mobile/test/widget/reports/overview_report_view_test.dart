import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/gen/anglerslog.pb.dart';
import 'package:mobile/pages/date_range_picker_page.dart';
import 'package:mobile/widgets/reports/overview_report_view.dart';
import 'package:mockito/mockito.dart';

import '../../mock_app_manager.dart';
import '../../test_utils.dart';

main() {
  MockAppManager appManager;

  setUp(() {
    appManager = MockAppManager(
      mockCatchManager: true,
      mockClock: true,
      mockCustomComparisonReportManager: true,
      mockSpeciesManager: true,
      mockFishingSpotManager: true,
      mockBaitManager: true,
    );

    when(appManager.mockClock.now())
        .thenReturn(DateTime.fromMillisecondsSinceEpoch(10000));
    when(appManager.mockCatchManager.catchesSortedByTimestamp(any,
      dateRange: anyNamed("dateRange"),
      baitIds: anyNamed("baitIds"),
      fishingSpotIds: anyNamed("fishingSpotIds"),
      speciesIds: anyNamed("speciesIds"),
    )).thenReturn([]);
    when(appManager.mockSpeciesManager.list()).thenReturn([]);
    when(appManager.mockFishingSpotManager.list()).thenReturn([]);
    when(appManager.mockBaitManager.list()).thenReturn([]);
  });

  testWidgets("Picking date updates state", (WidgetTester tester) async {
    await tester.pumpWidget(Testable((_) => OverviewReportView(),
      appManager: appManager,
    ));

    await tapAndSettle(tester, find.text("All dates"));
    await tapAndSettle(tester, find.text("This week"));

    expect(find.text("This week"), findsOneWidget);
  });
}