import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/fishing_spot_manager.dart';
import 'package:mobile/i18n/strings.dart';
import 'package:mobile/log.dart';
import 'package:mobile/model/fishing_spot.dart';
import 'package:mobile/pages/save_fishing_spot_page.dart';
import 'package:mobile/res/dimen.dart';
import 'package:mobile/res/style.dart';
import 'package:mobile/utils/dialog_utils.dart';
import 'package:mobile/utils/page_utils.dart';
import 'package:mobile/utils/string_utils.dart';
import 'package:mobile/widgets/button.dart';
import 'package:mobile/widgets/list_item.dart';
import 'package:mobile/widgets/page.dart';
import 'package:mobile/widgets/styled_bottom_sheet.dart';
import 'package:mobile/widgets/text.dart';
import 'package:mobile/widgets/widget.dart';
import 'package:quiver/strings.dart';
import 'package:uuid/uuid.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Log _log = Log("MapPage");

  final BitmapDescriptor _activeMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  final BitmapDescriptor _nonActiveMarkerIcon = BitmapDescriptor.defaultMarker;

  Completer<GoogleMapController> _mapController = Completer();

  Set<Marker> _fishingSpotMarkers = Set();
  Marker _activeMarker;

  FishingSpot _activeFishingSpot;

  // Used to display old data during dismiss animations and during async
  // database calls.
  FishingSpot _lastActiveFishingSpot;
  bool _waitingForFuture = false;
  bool _waitingForDismissal = false;

  // Cache future so we don't make redundant database calls.
  Future<FishingSpot> _activeFishingSpotFuture = Future.value(null);

  bool get _hasActiveMarker => _activeMarker != null;
  bool get _hasActiveFishingSpot => _activeFishingSpot != null;
  bool get _hasLastActiveFishingSpot => _lastActiveFishingSpot != null;

  @override
  Widget build(BuildContext context) => Page(
    child: FishingSpotsBuilder(
      onUpdate: (List<FishingSpot> fishingSpots) {
        _log.d("Reloading fishing spots...");

        _fishingSpotMarkers.clear();
        fishingSpots.forEach((f) =>
            _fishingSpotMarkers.add(_createFishingSpotMarker(f)));

        // Reset the active marker and fishing spot, if there was one.
        if (_activeMarker != null) {
          FishingSpot activeFishingSpot = fishingSpots.firstWhere(
            (FishingSpot fishingSpot) =>
                fishingSpot.latLng == _activeMarker.position,
            orElse: () => null,
          );
          if (activeFishingSpot != null) {
            _activeFishingSpotFuture = Future.value(activeFishingSpot);
          }

          Marker newMarker = _fishingSpotMarkers.firstWhere(
            (m) => m.position == _activeMarker.position,
            orElse: () => null,
          );
          _activeMarker = _copyMarker(newMarker, _activeMarkerIcon);
        }
      },
      builder: (BuildContext context) => Stack(
        children: <Widget>[
          _buildMap(),
          FutureBuilder<FishingSpot>(
            future: _activeFishingSpotFuture,
            builder: (BuildContext context, AsyncSnapshot<FishingSpot> snapshot)
            {
              if (snapshot.connectionState == ConnectionState.none
                  || snapshot.connectionState == ConnectionState.done)
              {
                _activeFishingSpot = snapshot.data;
                if (_activeFishingSpot != null) {
                  _lastActiveFishingSpot = _activeFishingSpot;
                }
                _waitingForFuture = false;
              } else {
                _waitingForFuture = true;
              }

              return Stack(
                children: <Widget>[
                  _buildSearchBar(),
                  _buildBottomSheet(),
                ],
              );
            },
          ),
        ],
      )
    ),
  );

  Widget _buildMap() {
    Set<Marker> markers = Set.of(_fishingSpotMarkers);
    if (_hasActiveMarker) {
      markers.add(_activeMarker);
    }

    // TODO: Move Google logo when better solution is available.
    // https://github.com/flutter/flutter/issues/39610
    return GoogleMap(
      markers: markers,
      initialCameraPosition: CameraPosition(
        target: LatLng(37.42796133580664, -122.085749655962),
        zoom: 10,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController.complete(controller);
      },
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      // TODO: Try onLongPress again when Google Maps updated.
      // Log presses weren't being triggered first time.
      onTap: (LatLng latLng) {
        setState(() {
          _setActiveMarker(_createDroppedPinMarker(latLng));
          _activeFishingSpotFuture = Future.value(null);
          _updateCamera(latLng);
        });
      },
    );
  }

  Widget _buildSearchBar() {
    final cornerRadius = 10.0;

    String name;
    if (_hasActiveMarker && _hasLastActiveFishingSpot && _waitingForFuture) {
      // Active fishing spot is being updated.
      name = _lastActiveFishingSpot.name;
    } else if (_hasActiveMarker && _hasActiveFishingSpot) {
      name = _activeFishingSpot.name;
    } else if (_hasActiveMarker) {
      name = Strings.of(context).mapPageDroppedPin;
    }

    Widget text;
    if (isNotEmpty(name)) {
      text = Flexible(
        child: LabelText(
          text: name,
        ),
      );
    } else {
      text = DisabledLabelText(Strings.of(context).mapPageSearchHint);
    }

    // Wrap AppBar in Positioned Widget to prevent it from taking up the entire
    // screen, which happens when using inside a Stack.
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: boxShadowSmallBottom,
            borderRadius: BorderRadius.all(Radius.circular(cornerRadius)),
          ),
          // Wrap InkWell in a Material widget so the fill animation is shown
          // on top of the parent Container widget.
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                FishingSpot result = await showSearch(
                  context: context,
                  delegate: _SearchDelegate(),
                );
                // Only reset selection if a new selection was made.
                if (result != null) {
                  setState(() {
                    _setActiveMarker(_findMarker(result.id));
                    _activeFishingSpotFuture = Future.value(result);
                    _updateCamera(result.latLng);
                  });
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  top: paddingMedium,
                  bottom: paddingMedium,
                  left: paddingDefault,
                  right: paddingDefault,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    text,
                    Visibility(
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      visible: isNotEmpty(name),
                      child: MinimumIconButton(
                        icon: Icons.clear,
                        onTap: () {
                          setState(() {
                            _waitingForDismissal = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  /// Material [BottomSheet] widget doesn't work here because it animates from
  /// the bottom of the screen. We want this bottom sheet to animate from the
  /// bottom of the map.
  Widget _buildBottomSheet() {
    if (!_hasActiveMarker && !_waitingForDismissal) {
      // Use empty container here instead of Empty() so the search bar size is
      // set correctly.
      return Container();
    }

    bool editing = true;
    if (!_hasActiveFishingSpot && _hasActiveMarker) {
      // Dropped pin case.
      _lastActiveFishingSpot = FishingSpot(
        lat: _activeMarker.position.latitude,
        lng: _activeMarker.position.longitude,
      );
      editing = false;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: StyledBottomSheet(
        visible: _hasActiveMarker && !_waitingForDismissal,
        onDismissed: () {
          setState(() {
            _setActiveMarker(null);
            _waitingForDismissal = false;
            _activeFishingSpotFuture = Future.value(null);
          });
        },
        child: _FishingSpotBottomSheet(
          fishingSpot: _lastActiveFishingSpot ?? FishingSpot(lat: 0, lng: 0),
          editing: editing,
        ),
      ),
    );
  }

  Marker _createFishingSpotMarker(FishingSpot fishingSpot) {
    if (fishingSpot == null) {
      return null;
    }
    return _createMarker(fishingSpot.latLng, id: fishingSpot.id);
  }

  Marker _createDroppedPinMarker(LatLng latLng) {
    // All dropped pins become active, and shouldn't be tappable.
    return _createMarker(
      latLng,
      tappable: false,
      icon: _activeMarkerIcon,
    );
  }

  Marker _createMarker(LatLng latLng, {
    String id,
    BitmapDescriptor icon,
    bool tappable = true,
  }) {
    MarkerId markerId = MarkerId(id ?? Uuid().v1().toString());
    return Marker(
      markerId: markerId,
      position: latLng,
      onTap: !tappable ? null : () {
        setState(() {
          _setActiveMarker(_fishingSpotMarkers
              .firstWhere((Marker marker) => marker.markerId == markerId));
          _activeFishingSpotFuture = FishingSpotManager.of(context)
              .fetch(id: _activeMarker.markerId.value);
        });
      },
      icon: icon,
    );
  }

  void _updateCamera(LatLng latLng) {
    // Animate the new marker to the middle of the map.
    _mapController.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

  void _setActiveMarker(Marker newActiveMarker) {
    // A marker's icon property is readonly, so we rebuild the current active
    // marker to give it a default icon, then remove and add it to the
    // fishing spot markers.
    //
    // This only applies if the active marker belongs to an existing fishing
    // spot. A dropped pin is removed from the map when updating the active
    // marker.
    if (_hasActiveMarker) {
      Marker activeMarker = _findMarker(_activeMarker.markerId.value);
      if (activeMarker != null) {
        if (_fishingSpotMarkers.remove(activeMarker)) {
          _fishingSpotMarkers.add(_copyMarker(activeMarker,
              _nonActiveMarkerIcon));
        } else {
          _log.e("Error removing marker");
        }
      }
    }

    _activeMarker = _copyMarker(newActiveMarker, _activeMarkerIcon);
  }

  Marker _copyMarker(Marker marker, BitmapDescriptor icon) {
    if (marker == null) {
      return null;
    }

    return Marker(
      markerId: marker.markerId,
      position: marker.position,
      onTap: marker.onTap,
      icon: icon,
    );
  }

  Marker _findMarker(String id) {
    return _fishingSpotMarkers.firstWhere(
      (Marker marker) => marker.markerId.value == id,
      orElse: () => null,
    );
  }
}

/// A widget that shows details of a selected fishing spot.
class _FishingSpotBottomSheet extends StatelessWidget {
  final double _chipHeight = 45;

  final FishingSpot fishingSpot;
  final bool editing;

  _FishingSpotBottomSheet({
    @required this.fishingSpot,
    this.editing = false,
  }) : assert(fishingSpot != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildName(context),
        Padding(
          padding: insetsHorizontalDefault,
          child: SecondaryText(formatLatLng(
            context: context,
            lat: fishingSpot.lat,
            lng: fishingSpot.lng,
          )),
        ),
        _buildChips(context),
      ],
    );
  }

  Widget _buildName(BuildContext context) {
    String name;
    if (isEmpty(fishingSpot.name)) {
      // A new pin was dropped.
      name = Strings.of(context).mapPageDroppedPin;
    } else if (isNotEmpty(fishingSpot.name)) {
      // Fishing spot exists, and has a name.
      name = fishingSpot.name;
    }

    return isEmpty(name) ? Empty() : Padding(
      padding: insetsHorizontalDefault,
      child: Text(
        name,
        style: styleHeading,
      ),
    );
  }

  Widget _buildChips(BuildContext context) => Container(
    height: _chipHeight,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: paddingDefault,
            right: paddingWidgetSmall,
          ),
          child: ChipButton(
            label: editing
                ? Strings.of(context).edit : Strings.of(context).save,
            icon: editing ? Icons.edit : Icons.save,
            onPressed: () {
              push(
                context,
                SaveFishingSpotPage(
                  oldFishingSpot: fishingSpot,
                ),
                fullscreenDialog: true,
              );
            },
          ),
        ),
        editing ? Padding(
          padding: insetsRightWidgetSmall,
          child: ChipButton(
            label: Strings.of(context).delete,
            icon: Icons.delete,
            onPressed: () {
              showDeleteDialog(
                context: context,
                title: Strings.of(context).delete,
                description: format(Strings.of(context)
                    .mapPageDeleteFishingSpot, [fishingSpot.name]),
                onDelete: () {
                  FishingSpotManager.of(context).remove(fishingSpot);
                },
              );
            },
          ),
        ) : Empty(),
        editing ? Padding(
          padding: insetsRightWidgetSmall,
          child: ChipButton(
            label: Strings.of(context).mapPageAddCatch,
            icon: Icons.add,
            onPressed: () {},
          ),
        ) : Empty(),
        Padding(
          padding: insetsRightDefault,
          child: ChipButton(
            label: Strings.of(context).directions,
            icon: Icons.directions,
            onPressed: () {},
          ),
        ),
      ],
    ),
  );
}

class _SearchDelegate extends SearchDelegate<FishingSpot> {
  List<FishingSpot> _fishingSpots = [];

  @override
  List<Widget> buildActions(BuildContext context) {
    return null;
  }

  @override
  Widget buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListView(
      children: <Widget>[
        // TODO: Query database
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FishingSpotsBuilder(
      onUpdate: (List<FishingSpot> fishingSpots) {
        _fishingSpots = fishingSpots ?? [];
      },
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: _fishingSpots.length,
          itemBuilder: (BuildContext context, int index) {
            FishingSpot fishingSpot = _fishingSpots[index];

            Widget title = Empty();
            if (isNotEmpty(fishingSpot.name)) {
              title = Text(fishingSpot.name);
            } else {
              title = Text(formatLatLng(
                context: context,
                lat: fishingSpot.lat,
                lng: fishingSpot.lng,
              ));
            }

            return ListItem(
              title: title,
              onTap: () => close(context, fishingSpot),
            );
          },
        );
      }
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }
}